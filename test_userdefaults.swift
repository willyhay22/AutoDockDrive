import Foundation

if let defaults = UserDefaults(suiteName: "com.apple.dock") {
    if let others = defaults.array(forKey: "persistent-others") {
        print("Found \(others.count) items in persistent-others")
    } else {
        print("persistent-others not found")
    }
}
