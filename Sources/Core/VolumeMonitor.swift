import Foundation
import AppKit
import DiskArbitration

/// Monitors the system for mounted and unmounted volumes.
class VolumeMonitor {
    static let shared = VolumeMonitor()
    
    /// Currently managed external drives
    private(set) var currentExternalDrives: [URL] = []
    
    private let workspace = NSWorkspace.shared
    private var daSession: DASession?
    
    private init() {
        daSession = DASessionCreate(kCFAllocatorDefault)
        if daSession == nil {
            Logger.shared.error("Failed to create persistent DASession in VolumeMonitor")
        }
    }
    
    /// Starts monitoring for volume changes and performs an initial synchronization.
    func startMonitoring() {
        Logger.shared.info("Starting VolumeMonitor...")
        
        // Register for NSWorkspace notifications
        workspace.notificationCenter.addObserver(self, selector: #selector(handleVolumeMounted(_:)), name: NSWorkspace.didMountNotification, object: nil)
        workspace.notificationCenter.addObserver(self, selector: #selector(handleVolumeUnmounted(_:)), name: NSWorkspace.didUnmountNotification, object: nil)
        
        // Register for DiskArbitration callbacks to catch physical yanks
        if let session = daSession {
            let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            DARegisterDiskAppearedCallback(session, nil, diskAppearedCallback, context)
            DARegisterDiskDisappearedCallback(session, nil, diskDisappearedCallback, context)
            DASessionScheduleWithRunLoop(session, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        }
        
        // Initial sync
        refreshAndSynchronize()
    }
    
    /// Stops monitoring.
    func stopMonitoring() {
        Logger.shared.info("Stopping VolumeMonitor...")
        workspace.notificationCenter.removeObserver(self)
        
        if let session = daSession {
            let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            let cbAppeared = unsafeBitCast(diskAppearedCallback as DADiskAppearedCallback, to: UnsafeMutableRawPointer.self)
            let cbDisappeared = unsafeBitCast(diskDisappearedCallback as DADiskDisappearedCallback, to: UnsafeMutableRawPointer.self)
            DAUnregisterCallback(session, cbAppeared, context)
            DAUnregisterCallback(session, cbDisappeared, context)
            DASessionUnscheduleFromRunLoop(session, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        }
    }
    
    @objc private func handleVolumeMounted(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let volumeURL = userInfo[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
        Logger.shared.info("Volume mounted: \(volumeURL.path)")
        refreshAndSynchronize()
    }
    
    @objc private func handleVolumeUnmounted(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let volumeURL = userInfo[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
        Logger.shared.info("Volume unmounted: \(volumeURL.path)")
        refreshAndSynchronize()
    }
    
    /// Refreshes the list of currently mounted external drives and triggers a Dock sync if enabled.
    func refreshAndSynchronize() {
        let currentExternalDrives = getConnectedDrives()
        
        self.currentExternalDrives = currentExternalDrives
        Logger.shared.debug("Currently connected managed drives: \(currentExternalDrives.map { $0.path })")
        
        if SettingsManager.shared.automaticallyManageDock {
            DockManager.shared.synchronizeDock(with: currentExternalDrives)
        } else {
            Logger.shared.debug("Drive Detection is disabled in settings. Skipping Dock sync.")
        }
    }
    
    /// Returns the currently connected and supported external drives without synchronizing the Dock.
    func getConnectedDrives() -> [URL] {
        let mountedVolumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeIsInternalKey, .volumeIsRemovableKey, .volumeIsEjectableKey, .volumeUUIDStringKey], options: [.skipHiddenVolumes]) ?? []
        
        var connectedDrives: [URL] = []
        let excludedUUIDs = SettingsManager.shared.excludedDrives.keys
        let ignoreTM = SettingsManager.shared.ignoreTimeMachine
        let ignoreDMG = SettingsManager.shared.ignoreDiskImages
        
        for volumeURL in mountedVolumes {
            do {
                let resourceValues = try volumeURL.resourceValues(forKeys: [.volumeIsInternalKey, .volumeIsRemovableKey, .volumeIsEjectableKey, .volumeUUIDStringKey])
                
                let isInternal = resourceValues.volumeIsInternal ?? true
                let isRemovable = resourceValues.volumeIsRemovable ?? false
                let isEjectable = resourceValues.volumeIsEjectable ?? false
                let uuid = resourceValues.volumeUUIDString ?? ""
                
                if !isInternal || isRemovable || isEjectable {
                    if volumeURL.path.hasPrefix("/Volumes/") {
                        if excludedUUIDs.contains(uuid) {
                            Logger.shared.debug("Ignoring Excluded volume: \(volumeURL.path) (UUID: \(uuid))")
                        }
                        else if ignoreDMG && isDiskImage(url: volumeURL) {
                            Logger.shared.debug("Ignoring Disk Image volume: \(volumeURL.path)")
                        } 
                        else if ignoreTM && isTimeMachineVolume(url: volumeURL) {
                            Logger.shared.debug("Ignoring Time Machine volume: \(volumeURL.path)")
                        } 
                        else {
                            connectedDrives.append(volumeURL)
                        }
                    }
                }
            } catch {
                Logger.shared.error("Failed to get resource values for volume \(volumeURL.path): \(error)")
            }
        }
        
        return connectedDrives
    }
    
    /// Uses DiskArbitration to determine if the volume is a mounted Disk Image
    private func isDiskImage(url: URL) -> Bool {
        guard let session = daSession else { return false }
        guard let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL) else { 
            Logger.shared.error("Failed to create DADisk for \(url.path)")
            return false 
        }
        guard let desc = DADiskCopyDescription(disk) as? [String: Any] else { 
            Logger.shared.error("Failed to get DADiskDescription for \(url.path)")
            return false 
        }
        
        if let protocolStr = desc["DADeviceProtocol"] as? String, protocolStr == "Virtual Interface" {
            return true
        }
        
        if let modelStr = desc["DADeviceModel"] as? String, modelStr == "Disk Image" {
            return true
        }
        
        return false
    }
    
    /// Checks if a volume is a Time Machine backup volume
    private func isTimeMachineVolume(url: URL) -> Bool {
        let tmMarker = url.appendingPathComponent(".com.apple.timemachine.donotpresent")
        let backupsDB = url.appendingPathComponent("Backups.backupdb")
        let tmMarker2 = url.appendingPathComponent(".com.apple.TimeMachine.LocalSnapshots")
        let apfsBackup = url.appendingPathComponent(".com.apple.TimeMachine.supported")
        let apfsManifest = url.appendingPathComponent("backup_manifest.plist")

        let fm = FileManager.default
        if fm.fileExists(atPath: tmMarker.path) || 
           fm.fileExists(atPath: backupsDB.path) ||
           fm.fileExists(atPath: apfsBackup.path) ||
           fm.fileExists(atPath: apfsManifest.path) ||
           (fm.fileExists(atPath: tmMarker2.path) && url.path != "/") {
            return true
        }
        
        return false
    }
}

// C-compatible callbacks for DiskArbitration
private func diskAppearedCallback(disk: DADisk, context: UnsafeMutableRawPointer?) {
    guard let context = context else { return }
    let monitor = Unmanaged<VolumeMonitor>.fromOpaque(context).takeUnretainedValue()
    DispatchQueue.main.async { monitor.refreshAndSynchronize() }
}

private func diskDisappearedCallback(disk: DADisk, context: UnsafeMutableRawPointer?) {
    guard let context = context else { return }
    let monitor = Unmanaged<VolumeMonitor>.fromOpaque(context).takeUnretainedValue()
    DispatchQueue.main.async { monitor.refreshAndSynchronize() }
}
