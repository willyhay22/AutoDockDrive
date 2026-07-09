import Foundation

let keys: [URLResourceKey] = [
    .volumeIsInternalKey,
    .volumeIsRemovableKey,
    .volumeIsEjectableKey,
    .volumeIsLocalKey,
    .volumeIsAutomountedKey,
    .volumeIsRootFileSystemKey
]

guard let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: []) else { exit(1) }

for vol in volumes {
    print("Volume: \(vol.path)")
    if let values = try? vol.resourceValues(forKeys: Set(keys)) {
        print("  isInternal: \(values.volumeIsInternal ?? false)")
        print("  isRemovable: \(values.volumeIsRemovable ?? false)")
        print("  isEjectable: \(values.volumeIsEjectable ?? false)")
        print("  isLocal: \(values.volumeIsLocal ?? false)")
        print("  isAutomounted: \(values.volumeIsAutomounted ?? false)")
        print("  isRoot: \(values.volumeIsRootFileSystem ?? false)")
    }
}
