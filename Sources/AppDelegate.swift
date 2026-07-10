import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    
    private var drivesMenu: NSMenu!
    private var drivesMenuItem: NSMenuItem!
    
    private var preferencesWindowController: PreferencesWindowController?
    private var welcomeWindowController: WelcomeWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "com.willyhay22.AutoDockDrive")
        if runningApps.count > 1 {
            Logger.shared.error("Another instance of AutoDockDrive is already running. Terminating.")
            NSApp.terminate(nil)
            return
        }
        
        Logger.shared.info("AutoDockDrive is launching...")
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkUpdates), name: Notification.Name("CheckForUpdates"), object: nil)
        
        setupMenuBar()
        
        if SettingsManager.shared.hasSeenWelcomeScreen {
            VolumeMonitor.shared.startMonitoring()
            Logger.shared.info("AutoDockDrive successfully launched in background.")
            if SettingsManager.shared.automaticallyCheckForUpdates {
                UpdateManager.shared.checkForUpdates(silent: true)
            }
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
        
        drivesMenuItem = NSMenuItem(title: "Connected Drives", action: nil, keyEquivalent: "")
        drivesMenu = NSMenu()
        drivesMenuItem.submenu = drivesMenu
        menu.addItem(drivesMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let prefsItem = NSMenuItem(title: "Preferences…", action: #selector(showPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        let updatesItem = NSMenuItem(title: "Check for Updates…", action: #selector(checkUpdates), keyEquivalent: "")
        updatesItem.target = self
        menu.addItem(updatesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitMenuItem = NSMenuItem(title: "Quit AutoDockDrive", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitMenuItem)
        
        statusItem.menu = menu
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
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
                
                let item = NSMenuItem(title: driveName, action: nil, keyEquivalent: "")
                if #available(macOS 11.0, *) {
                    item.image = NSImage(systemSymbolName: "externaldrive", accessibilityDescription: driveName)
                }
                
                let submenu = NSMenu()
                
                let openItem = NSMenuItem(title: "Open", action: #selector(openDrive(_:)), keyEquivalent: "")
                openItem.target = self
                openItem.representedObject = drive
                submenu.addItem(openItem)
                
                let revealItem = NSMenuItem(title: "Reveal in Finder", action: #selector(revealDrive(_:)), keyEquivalent: "")
                revealItem.target = self
                revealItem.representedObject = drive
                submenu.addItem(revealItem)
                
                let copyPathItem = NSMenuItem(title: "Copy Path", action: #selector(copyDrivePath(_:)), keyEquivalent: "")
                copyPathItem.target = self
                copyPathItem.representedObject = drive
                submenu.addItem(copyPathItem)
                
                submenu.addItem(NSMenuItem.separator())
                
                let excludeItem = NSMenuItem(title: "Exclude from AutoDockDrive", action: #selector(excludeDrive(_:)), keyEquivalent: "")
                excludeItem.target = self
                excludeItem.representedObject = drive
                submenu.addItem(excludeItem)
                
                submenu.addItem(NSMenuItem.separator())
                
                let ejectItem = NSMenuItem(title: "Eject", action: #selector(ejectDrive(_:)), keyEquivalent: "")
                ejectItem.target = self
                ejectItem.representedObject = drive
                submenu.addItem(ejectItem)
                
                item.submenu = submenu
                drivesMenu.addItem(item)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func openDrive(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }
    
    @objc private func revealDrive(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    @objc private func copyDrivePath(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.path, forType: .string)
    }
    
    @objc private func excludeDrive(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        do {
            let resourceValues = try url.resourceValues(forKeys: [.volumeUUIDStringKey])
            if let uuid = resourceValues.volumeUUIDString {
                SettingsManager.shared.excludeDrive(uuid: uuid, name: url.lastPathComponent)
                VolumeMonitor.shared.refreshAndSynchronize()
            }
        } catch {
            Logger.shared.error("Failed to get UUID for exclusion: \(error)")
        }
    }
    
    @objc private func ejectDrive(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        
        do {
            try NSWorkspace.shared.unmountAndEjectDevice(at: url)
            Logger.shared.info("Successfully ejected \(url.path)")
        } catch {
            Logger.shared.error("Failed to eject \(url.path): \(error)")
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Failed to Eject"
                alert.informativeText = "Could not eject \(url.lastPathComponent).\n\n\(error.localizedDescription)"
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }
    
    @objc private func checkUpdates() {
        UpdateManager.shared.checkForUpdates(silent: false)
    }
    
    @objc private func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
