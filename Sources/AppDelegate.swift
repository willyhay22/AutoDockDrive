import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    
    private var pauseMenuItem: NSMenuItem!
    private var drivesMenu: NSMenu!
    private var drivesMenuItem: NSMenuItem!
    
    private var preferencesWindowController: PreferencesWindowController?
    private var aboutWindowController: AboutWindowController?
    private var welcomeWindowController: WelcomeWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "com.wihay.AutoDockDrive")
        if runningApps.count > 1 {
            Logger.shared.error("Another instance of AutoDockDrive is already running. Terminating.")
            NSApp.terminate(nil)
            return
        }
        
        Logger.shared.info("AutoDockDrive is launching...")
        
        setupMenuBar()
        
        if SettingsManager.shared.hasSeenWelcomeScreen {
            VolumeMonitor.shared.startMonitoring()
            Logger.shared.info("AutoDockDrive successfully launched in background.")
        } else {
            Logger.shared.info("First launch detected. Showing Welcome screen.")
            showWelcomeScreen()
        }
    }

    func showWelcomeScreen() {
        if welcomeWindowController == nil {
            welcomeWindowController = WelcomeWindowController()
        }
        welcomeWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        Logger.shared.info("AutoDockDrive is terminating...")
        VolumeMonitor.shared.stopMonitoring()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "externaldrive.fill.badge.plus", accessibilityDescription: "AutoDockDrive")
            } else {
                button.title = "ADD"
            }
        }
        
        menu = NSMenu()
        menu.delegate = self
        
        let titleItem = NSMenuItem(title: "AutoDockDrive", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        pauseMenuItem = NSMenuItem(title: "Pause Automatic Dock Management", action: #selector(togglePause), keyEquivalent: "")
        pauseMenuItem.target = self
        menu.addItem(pauseMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        drivesMenuItem = NSMenuItem(title: "Connected Managed Drives", action: nil, keyEquivalent: "")
        drivesMenu = NSMenu()
        drivesMenuItem.submenu = drivesMenu
        menu.addItem(drivesMenuItem)
        
        let refreshItem = NSMenuItem(title: "Refresh / Resynchronize Dock", action: #selector(forceRefresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let logItem = NSMenuItem(title: "Open Log File", action: #selector(openLogFile), keyEquivalent: "l")
        logItem.target = self
        menu.addItem(logItem)
        
        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(showPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        let aboutItem = NSMenuItem(title: "About AutoDockDrive", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitMenuItem = NSMenuItem(title: "Quit AutoDockDrive", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitMenuItem)
        
        statusItem.menu = menu
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        let isPaused = SettingsManager.shared.isPaused
        pauseMenuItem.title = isPaused ? "Resume Automatic Dock Management" : "Pause Automatic Dock Management"
        
        // Populate Connected Drives
        drivesMenu.removeAllItems()
        let drives = VolumeMonitor.shared.currentExternalDrives
        if drives.isEmpty {
            let emptyItem = NSMenuItem(title: "No Drives Connected", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            drivesMenu.addItem(emptyItem)
        } else {
            for drive in drives {
                let driveName = drive.lastPathComponent
                let item = NSMenuItem(title: driveName, action: #selector(openDrive(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = drive
                if #available(macOS 11.0, *) {
                    item.image = NSImage(systemSymbolName: "externaldrive", accessibilityDescription: driveName)
                }
                drivesMenu.addItem(item)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func togglePause() {
        SettingsManager.shared.isPaused.toggle()
        if !SettingsManager.shared.isPaused {
            VolumeMonitor.shared.stopMonitoring()
            VolumeMonitor.shared.startMonitoring()
        }
    }
    
    @objc private func forceRefresh() {
        VolumeMonitor.shared.stopMonitoring()
        VolumeMonitor.shared.startMonitoring()
    }
    
    @objc private func openDrive(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }
    
    @objc private func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func showAbout() {
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController()
        }
        aboutWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func openLogFile() {
        let logURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/AutoDockDrive.log")
        if FileManager.default.fileExists(atPath: logURL.path) {
            NSWorkspace.shared.open(logURL)
        }
    }
}
