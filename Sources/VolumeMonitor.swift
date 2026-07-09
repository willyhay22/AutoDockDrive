import Foundation
import AppKit
import DiskArbitration

/// Monitors the system for mounted and unmounted volumes.
class VolumeMonitor {
    static let shared = VolumeMonitor()
    
    /// Currently managed external drives
    private(set) var currentExternalDrives: [URL] = []
    
    private let workspace = NSWorkspace.shared
    
    private init() {}
    
    /// Starts monitoring for volume changes and performs an initial synchronization.
    func startMonitoring() {
        Logger.shared.info("Starting VolumeMonitor...")
        
        // Register for notifications
        workspace.notificationCenter.addObserver(self, selector: #selector(handleVolumeMounted(_:)), name: NSWorkspace.didMountNotification, object: nil)
        workspace.notificationCenter.addObserver(self, selector: #selector(handleVolumeUnmounted(_:)), name: NSWorkspace.didUnmountNotification, object: nil)
        
        // Initial sync
        refreshAndSynchronize()
    }
    
    /// Stops monitoring.
    func stopMonitoring() {
        Logger.shared.info("Stopping VolumeMonitor...")
        workspace.notificationCenter.removeObserver(self)
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
    
    /// Refreshes the list of currently mounted external drives and triggers a Dock sync.
    private func refreshAndSynchronize() {
        let currentExternalDrives = getConnectedDrives()
        
        self.currentExternalDrives = currentExternalDrives
        Logger.shared.debug("Currently connected external drives: \(currentExternalDrives.map { $0.path })")
        
        DockManager.shared.synchronizeDock(with: currentExternalDrives)
    }
    
    /// Returns the currently connected and supported external drives without synchronizing the Dock.
    func getConnectedDrives() -> [URL] {
        let mountedVolumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeIsInternalKey, .volumeIsRemovableKey, .volumeIsEjectableKey], options: [.skipHiddenVolumes]) ?? []
        
        var connectedDrives: [URL] = []
        
        for volumeURL in mountedVolumes {
            do {
                let resourceValues = try volumeURL.resourceValues(forKeys: [.volumeIsInternalKey, .volumeIsRemovableKey, .volumeIsEjectableKey])
                
                let isInternal = resourceValues.volumeIsInternal ?? true
                let isRemovable = resourceValues.volumeIsRemovable ?? false
                let isEjectable = resourceValues.volumeIsEjectable ?? false
                
                if !isInternal || isRemovable || isEjectable {
                    if volumeURL.path.hasPrefix("/Volumes/") {
                        if isDiskImage(url: volumeURL) {
                            Logger.shared.debug("Ignoring Disk Image volume: \(volumeURL.path)")
                        } 
                        else if isTimeMachineVolume(url: volumeURL) {
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
        guard let session = DASessionCreate(kCFAllocatorDefault) else { 
            Logger.shared.error("Failed to create DASession")
            return false 
        }
        guard let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL) else { 
            Logger.shared.error("Failed to create DADisk for \(url.path)")
            return false 
        }
        guard let desc = DADiskCopyDescription(disk) as? [String: Any] else { 
            Logger.shared.error("Failed to get DADiskDescription for \(url.path)")
            return false 
        }
        
        Logger.shared.debug("DADiskDescription for \(url.path): Protocol=\(desc["DADeviceProtocol"] ?? "nil"), Model=\(desc["DADeviceModel"] ?? "nil")")
        
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
