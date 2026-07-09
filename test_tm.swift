import Foundation

func getTimeMachineMountPoints() -> Set<String> {
    let task = Process()
    task.launchPath = "/usr/bin/tmutil"
    task.arguments = ["destinationinfo", "-X"]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    
    var mountPoints = Set<String>()
    
    if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
       let destinations = plist["Destinations"] as? [[String: Any]] {
        for dest in destinations {
            if let mp = dest["MountPoint"] as? String {
                mountPoints.insert(mp)
            }
        }
    }
    return mountPoints
}

print(getTimeMachineMountPoints())
