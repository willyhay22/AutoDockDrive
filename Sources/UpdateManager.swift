import Cocoa
import Foundation

class UpdateManager {
    static let shared = UpdateManager()
    
    private let repoURL = "https://api.github.com/repos/willyhay22/AutoDockDrive/releases/latest"
    
    private init() {}
    
    struct Release: Codable {
        let tag_name: String
        let html_url: String
        let body: String?
    }
    
    func checkForUpdates(silent: Bool) {
        guard let url = URL(string: repoURL) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                if !silent {
                    self.showAlert(title: "Update Check Failed", message: "Could not connect to GitHub to check for updates. Please check your internet connection.", isUpdate: false, url: nil)
                }
                return
            }
            
            do {
                let release = try JSONDecoder().decode(Release.self, from: data)
                let remoteVersion = release.tag_name.replacingOccurrences(of: "v", with: "")
                
                let localVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                
                if self.isNewerVersion(local: localVersion, remote: remoteVersion) {
                    let notes = release.body ?? "A new version of AutoDockDrive is available!"
                    let message = "\(notes)\n\nTo update, click 'Download Update', download the new .dmg file from GitHub, and drag the app into your Applications folder."
                    self.showAlert(title: "Update Available (\(remoteVersion))", message: message, isUpdate: true, url: URL(string: release.html_url))
                } else if !silent {
                    self.showAlert(title: "Up to Date", message: "You are running the latest version of AutoDockDrive (\(localVersion)).", isUpdate: false, url: nil)
                }
                
            } catch {
                if !silent {
                    self.showAlert(title: "Update Check Failed", message: "Failed to parse update information from GitHub.", isUpdate: false, url: nil)
                }
            }
        }
        
        task.resume()
    }
    
    private func isNewerVersion(local: String, remote: String) -> Bool {
        return local.compare(remote, options: .numeric) == .orderedAscending
    }
    
    private func showAlert(title: String, message: String, isUpdate: Bool, url: URL?) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            
            if isUpdate {
                alert.addButton(withTitle: "Download Update")
                alert.addButton(withTitle: "Cancel")
            } else {
                alert.addButton(withTitle: "OK")
            }
            
            let response = alert.runModal()
            if isUpdate && response == .alertFirstButtonReturn, let updateURL = url {
                NSWorkspace.shared.open(updateURL)
            }
        }
    }
}
