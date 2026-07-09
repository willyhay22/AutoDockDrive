import Foundation
import ServiceManagement

/// Manages application preferences and login item registration.
class SettingsManager {
    static let shared = SettingsManager()
    
    private let userDefaults = UserDefaults.standard
    private let pauseKey = "isManagementPaused"
    private let dockSortByKey = "dockSortBy"
    private let dockDisplayAsKey = "dockDisplayAs"
    private let dockShowAsKey = "dockShowAs"
    private let hasSeenWelcomeScreenKey = "hasSeenWelcomeScreen"
    private let automaticallyCheckForUpdatesKey = "automaticallyCheckForUpdates"
    
    private init() {
        // Register default defaults
        // Sort by: 3 (Date Modified)
        // Display as: 1 (Folder)
        // View content as: 3 (List)
        userDefaults.register(defaults: [
            hasSeenWelcomeScreenKey: false,
            pauseKey: false,
            dockSortByKey: 3,
            dockDisplayAsKey: 1,
            dockShowAsKey: 3,
            automaticallyCheckForUpdatesKey: true
        ])
    }
    
    /// Whether the user has seen the first-launch welcome screen.
    var hasSeenWelcomeScreen: Bool {
        get { userDefaults.bool(forKey: hasSeenWelcomeScreenKey) }
        set { userDefaults.set(newValue, forKey: hasSeenWelcomeScreenKey) }
    }
    
    var automaticallyCheckForUpdates: Bool {
        get { userDefaults.object(forKey: automaticallyCheckForUpdatesKey) as? Bool ?? true }
        set { userDefaults.set(newValue, forKey: automaticallyCheckForUpdatesKey) }
    }
    
    /// Whether automatic Dock management is temporarily paused.
    var isPaused: Bool {
        get { userDefaults.bool(forKey: pauseKey) }
        set {
            userDefaults.set(newValue, forKey: pauseKey)
            Logger.shared.info("Dock management paused state changed to: \(newValue)")
        }
    }
    
    /// Dock Sort By (1=Name, 2=DateAdded, 3=DateModified, 4=DateCreated, 5=Kind)
    var dockSortBy: Int {
        get { userDefaults.integer(forKey: dockSortByKey) }
        set { userDefaults.set(newValue, forKey: dockSortByKey) }
    }
    
    /// Dock Display As (0=Stack, 1=Folder)
    var dockDisplayAs: Int {
        get { userDefaults.integer(forKey: dockDisplayAsKey) }
        set { userDefaults.set(newValue, forKey: dockDisplayAsKey) }
    }
    
    /// Dock Show As (0=Auto, 1=Fan, 2=Grid, 3=List)
    var dockShowAs: Int {
        get { userDefaults.integer(forKey: dockShowAsKey) }
        set { userDefaults.set(newValue, forKey: dockShowAsKey) }
    }
    
    /// Check if the app is registered to start at login.
    var startsAtLogin: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return false
        }
    }
    
    /// Toggles the start at login preference.
    func toggleStartAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    Logger.shared.info("Unregistered start at login.")
                } else {
                    try SMAppService.mainApp.register()
                    Logger.shared.info("Registered start at login.")
                }
            } catch {
                Logger.shared.error("Failed to toggle login item: \(error)")
            }
        } else {
            Logger.shared.error("Login item management requires macOS 13.0 or newer.")
        }
    }
}
