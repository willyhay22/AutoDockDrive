import Foundation
import AppKit

/// Manages modifications to the macOS Dock.
class DockManager {
    static let shared = DockManager()
    
    private let dockPlistURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Preferences/com.apple.dock.plist")
    
    private init() {}
    
    /// Synchronizes the Dock with the provided list of currently mounted external drives.
    /// - Parameter expectedDriveURLs: The file URLs of the drives that should be in the Dock.
    func synchronizeDock(with expectedDriveURLs: [URL]) {
        guard !SettingsManager.shared.isPaused else {
            Logger.shared.info("Dock management is paused. Skipping synchronization.")
            return
        }
        
        Logger.shared.debug("Synchronizing Dock with expected drives: \(expectedDriveURLs.map { $0.path })")
        
        guard var plist = readDockPlist() else {
            Logger.shared.error("Could not read Dock plist.")
            return
        }
        
        var persistentOthers = plist["persistent-others"] as? [[String: Any]] ?? []
        var changesMade = false
        
        // 1. Remove drives that are NO LONGER in the expected list
        var itemsToRemove: [Int] = []
        for (index, item) in persistentOthers.enumerated() {
            guard isDirectoryTile(item), let url = getURL(from: item) else { continue }
            
            // Check if this URL is under /Volumes (meaning it's a managed external drive)
            // But we only want to remove it if it's NOT in expectedDriveURLs.
            // Also, make sure we only auto-remove drives we think we are managing (those in /Volumes).
            if isExternalDrivePath(url.path) {
                if !expectedDriveURLs.contains(where: { $0.standardizedFileURL == url.standardizedFileURL }) {
                    itemsToRemove.append(index)
                    Logger.shared.info("Will remove disconnected drive from Dock: \(url.path)")
                }
            }
        }
        
        for index in itemsToRemove.reversed() {
            persistentOthers.remove(at: index)
            changesMade = true
        }
        
        // 2. Add drives that ARE in the expected list but NOT in the Dock
        for expectedURL in expectedDriveURLs {
            let alreadyExists = persistentOthers.contains { item in
                guard isDirectoryTile(item), let url = getURL(from: item) else { return false }
                return url.standardizedFileURL == expectedURL.standardizedFileURL
            }
            
            if !alreadyExists {
                let newTile = createDirectoryTile(for: expectedURL)
                persistentOthers.append(newTile)
                changesMade = true
                Logger.shared.info("Will add connected drive to Dock: \(expectedURL.path)")
            }
        }
        
        if changesMade {
            plist["persistent-others"] = persistentOthers
            if writeDockPlist(plist) {
                restartDock()
            }
        } else {
            Logger.shared.debug("No Dock changes required.")
        }
    }
    
    // MARK: - Private Helpers
    
    private func readDockPlist() -> [String: Any]? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".plist")
        
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["export", "com.apple.dock", tempURL.path]
        task.launch()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            Logger.shared.error("Failed to export dock preferences.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: tempURL)
            let plist = try PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String: Any]
            try? FileManager.default.removeItem(at: tempURL)
            return plist
        } catch {
            Logger.shared.error("Error reading exported Dock plist: \(error)")
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }
    }
    
    private func writeDockPlist(_ plist: [String: Any]) -> Bool {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".plist")
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: tempURL)
            
            let task = Process()
            task.launchPath = "/usr/bin/defaults"
            task.arguments = ["import", "com.apple.dock", tempURL.path]
            task.launch()
            task.waitUntilExit()
            
            try? FileManager.default.removeItem(at: tempURL)
            
            if task.terminationStatus == 0 {
                Logger.shared.debug("Successfully wrote com.apple.dock via defaults import")
                return true
            } else {
                Logger.shared.error("Failed to import dock preferences.")
                return false
            }
        } catch {
            Logger.shared.error("Error writing temporary Dock plist: \(error)")
            return false
        }
    }
    
    private func restartDock() {
        Logger.shared.info("Restarting Dock to apply changes...")
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["Dock"]
        task.launch()
        task.waitUntilExit()
    }
    
    private func isDirectoryTile(_ item: [String: Any]) -> Bool {
        return item["tile-type"] as? String == "directory-tile"
    }
    
    private func getURL(from item: [String: Any]) -> URL? {
        guard let tileData = item["tile-data"] as? [String: Any],
              let fileData = tileData["file-data"] as? [String: Any],
              let urlString = fileData["_CFURLString"] as? String else {
            return nil
        }
        
        let type = fileData["_CFURLStringType"] as? Int ?? 0
        if type == 15 {
            return URL(string: urlString)
        } else if type == 0 {
            return URL(fileURLWithPath: urlString)
        }
        return URL(string: urlString)
    }
    
    private func createDirectoryTile(for url: URL) -> [String: Any] {
        let guid = UInt32(truncatingIfNeeded: url.absoluteString.hashValue)
        let name = url.lastPathComponent
        
        return [
            "GUID": Int(guid),
            "tile-type": "directory-tile",
            "tile-data": [
                "file-data": [
                    "_CFURLString": url.absoluteString,
                    "_CFURLStringType": 15
                ],
                "file-label": name,
                "file-type": 2, // 2 = directory
                "showas": SettingsManager.shared.dockShowAs,
                "displayas": SettingsManager.shared.dockDisplayAs,
                "arrangement": SettingsManager.shared.dockSortBy
            ]
        ]
    }
    
    private func isExternalDrivePath(_ path: String) -> Bool {
        // macOS mounts external drives under /Volumes/
        // We ensure we don't accidentally remove standard folders (like Downloads)
        // Note: The root drive / is not under /Volumes typically, but sometimes it is aliased.
        // We will assume any path starting with /Volumes/ and not just /Volumes/Macintosh HD is an external drive.
        return path.hasPrefix("/Volumes/") && path != "/Volumes/Macintosh HD"
    }
}
