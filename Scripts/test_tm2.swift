import Foundation

func isTimeMachineVolume(url: URL) -> Bool {
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

let url = URL(fileURLWithPath: "/Volumes/Time Machine")
print("Is Time Machine: \(isTimeMachineVolume(url: url))")
