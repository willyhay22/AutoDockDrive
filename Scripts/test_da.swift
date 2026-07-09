import Foundation
import DiskArbitration

guard let session = DASessionCreate(kCFAllocatorDefault) else { exit(1) }

let keys: [URLResourceKey] = [.volumeIsInternalKey, .volumeIsRemovableKey]
guard let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: []) else { exit(1) }

for vol in volumes {
    guard vol.path.hasPrefix("/Volumes/") else { continue }
    print("Volume: \(vol.path)")
    
    guard let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, vol as CFURL) else { continue }
    if let desc = DADiskCopyDescription(disk) as? [String: Any] {
        print(desc)
    }
}
