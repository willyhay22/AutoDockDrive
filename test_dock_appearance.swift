import Foundation

func writeDockPlist(_ plist: [String: Any]) {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".plist")
    let data = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    try! data.write(to: tempURL)
    
    let task = Process()
    task.launchPath = "/usr/bin/defaults"
    task.arguments = ["import", "com.apple.dock", tempURL.path]
    task.launch()
    task.waitUntilExit()
}

func readDockPlist() -> [String: Any]? {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".plist")
    let task = Process()
    task.launchPath = "/usr/bin/defaults"
    task.arguments = ["export", "com.apple.dock", tempURL.path]
    task.launch()
    task.waitUntilExit()
    
    let data = try! Data(contentsOf: tempURL)
    return try! PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String: Any]
}

func restartDock() {
    let task = Process()
    task.launchPath = "/usr/bin/killall"
    task.arguments = ["Dock"]
    task.launch()
    task.waitUntilExit()
    Thread.sleep(forTimeInterval: 2.0)
}

func testSettings(arrangement: Int, displayas: Int, showas: Int) {
    var plist = readDockPlist()!
    var others = plist["persistent-others"] as? [[String: Any]] ?? []
    
    let url = URL(fileURLWithPath: "/Users/wihay/Downloads")
    
    let item: [String: Any] = [
        "tile-type": "directory-tile",
        "tile-data": [
            "file-data": [
                "_CFURLString": url.absoluteString,
                "_CFURLStringType": 15
            ],
            "file-type": 2,
            "showas": showas,
            "displayas": displayas,
            "arrangement": arrangement
        ]
    ]
    
    // add it
    others.append(item)
    plist["persistent-others"] = others
    writeDockPlist(plist)
    restartDock()
    
    // read back
    let newPlist = readDockPlist()!
    let newOthers = newPlist["persistent-others"] as? [[String: Any]] ?? []
    let last = newOthers.last!
    let tileData = last["tile-data"] as! [String: Any]
    
    print("Expected: a:\(arrangement) d:\(displayas) s:\(showas) -> Actual: a:\(tileData["arrangement"]!) d:\(tileData["displayas"]!) s:\(tileData["showas"]!)")
    
    // cleanup
    var cleanPlist = readDockPlist()!
    var cleanOthers = cleanPlist["persistent-others"] as? [[String: Any]] ?? []
    cleanOthers.removeLast()
    cleanPlist["persistent-others"] = cleanOthers
    writeDockPlist(cleanPlist)
    restartDock()
}

// Test combinations
print("Testing permutations...")
testSettings(arrangement: 1, displayas: 0, showas: 0) // Name, Stack, Auto
testSettings(arrangement: 3, displayas: 1, showas: 3) // Mod, Folder, List
testSettings(arrangement: 5, displayas: 1, showas: 2) // Kind, Folder, Grid
testSettings(arrangement: 99, displayas: 99, showas: 99) // Invalid bounds

