import AppKit

let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.wihay.AutoDockDrive")
print(runningApps.count)
