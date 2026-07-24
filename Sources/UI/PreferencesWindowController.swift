import Cocoa

class PreferencesWindowController: NSWindowController {
    
    init() {
        // Create a window without a hardcoded size. It will resize based on the tab content.
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 550, height: 400),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered,
                              defer: false)
        window.title = "Preferences"
        window.center()
        
        super.init(window: window)
        
        let tabViewController = NSTabViewController()
        tabViewController.tabStyle = .toolbar

        
        let generalVC = GeneralPreferencesViewController()
        let generalItem = NSTabViewItem(viewController: generalVC)
        generalItem.label = "General"
        if #available(macOS 11.0, *) { generalItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil) }
        
        let dockVC = DockPreferencesViewController()
        let dockItem = NSTabViewItem(viewController: dockVC)
        dockItem.label = "Dock"
        if #available(macOS 11.0, *) { dockItem.image = NSImage(systemSymbolName: "dock.rectangle", accessibilityDescription: nil) }
        
        let filtersVC = FiltersPreferencesViewController()
        let filtersItem = NSTabViewItem(viewController: filtersVC)
        filtersItem.label = "Filters"
        if #available(macOS 11.0, *) { filtersItem.image = NSImage(systemSymbolName: "line.horizontal.3.decrease.circle", accessibilityDescription: nil) }
        
        let excludedVC = ExcludedDrivesViewController()
        let excludedItem = NSTabViewItem(viewController: excludedVC)
        excludedItem.label = "Excluded Drives"
        if #available(macOS 11.0, *) { excludedItem.image = NSImage(systemSymbolName: "externaldrive.fill.badge.minus", accessibilityDescription: nil) }
        
        let advancedVC = AdvancedPreferencesViewController()
        let advancedItem = NSTabViewItem(viewController: advancedVC)
        advancedItem.label = "Advanced"
        if #available(macOS 11.0, *) { advancedItem.image = NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: nil) }
        
        let aboutVC = AboutPreferencesViewController()
        let aboutItem = NSTabViewItem(viewController: aboutVC)
        aboutItem.label = "About"
        if #available(macOS 11.0, *) { aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil) }
        
        tabViewController.addTabViewItem(generalItem)
        tabViewController.addTabViewItem(dockItem)
        tabViewController.addTabViewItem(filtersItem)
        tabViewController.addTabViewItem(excludedItem)
        tabViewController.addTabViewItem(advancedItem)
        tabViewController.addTabViewItem(aboutItem)
        
        window.contentViewController = tabViewController
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - General
class GeneralPreferencesViewController: NSViewController {
    override func loadView() {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 16
        container.edgeInsets = NSEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
        
        let loginCheckbox = NSButton(checkboxWithTitle: "Start AutoDockDrive automatically at login", target: self, action: #selector(loginCheckboxToggled(_:)))
        loginCheckbox.state = SettingsManager.shared.startsAtLogin ? .on : .off
        container.addArrangedSubview(loginCheckbox)
        
        let manageDockCheckbox = NSButton(checkboxWithTitle: "Enable automatic drive detection", target: self, action: #selector(manageDockToggled(_:)))
        manageDockCheckbox.state = SettingsManager.shared.automaticallyManageDock ? .on : .off
        container.addArrangedSubview(manageDockCheckbox)
        
        let updatesCheckbox = NSButton(checkboxWithTitle: "Automatically check for updates on launch", target: self, action: #selector(updatesCheckboxToggled(_:)))
        updatesCheckbox.state = SettingsManager.shared.automaticallyCheckForUpdates ? .on : .off
        container.addArrangedSubview(updatesCheckbox)
        
        container.widthAnchor.constraint(equalToConstant: 550).isActive = true
        self.view = container
    }
    
    @objc private func loginCheckboxToggled(_ sender: NSButton) {
        SettingsManager.shared.toggleStartAtLogin()
    }
    @objc private func manageDockToggled(_ sender: NSButton) {
        SettingsManager.shared.automaticallyManageDock = (sender.state == .on)
    }
    @objc private func updatesCheckboxToggled(_ sender: NSButton) {
        SettingsManager.shared.automaticallyCheckForUpdates = (sender.state == .on)
    }
}

// MARK: - Dock
class DockPreferencesViewController: NSViewController {
    override func loadView() {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 20
        container.edgeInsets = NSEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
        
        let appearanceLabel = NSTextField(labelWithString: "Appearance for New Drives:")
        appearanceLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        container.addArrangedSubview(appearanceLabel)
        
        let formStack = NSStackView()
        formStack.orientation = .vertical
        formStack.spacing = 15
        formStack.alignment = .trailing
        
        let sortStack = createFormRow(label: "Sort by:", items: ["Name", "Date Added", "Date Modified", "Date Created", "Kind"], defaultIndex: max(0, SettingsManager.shared.dockSortBy - 1), action: #selector(sortChanged(_:)))
        formStack.addArrangedSubview(sortStack)
        
        let displayStack = createFormRow(label: "Display as:", items: ["Stack", "Folder"], defaultIndex: min(1, max(0, SettingsManager.shared.dockDisplayAs)), action: #selector(displayChanged(_:)))
        formStack.addArrangedSubview(displayStack)
        
        let viewStack = createFormRow(label: "View content as:", items: ["Automatic", "Fan", "Grid", "List"], defaultIndex: min(3, max(0, SettingsManager.shared.dockShowAs)), action: #selector(viewContentChanged(_:)))
        formStack.addArrangedSubview(viewStack)
        
        container.addArrangedSubview(formStack)
        formStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20).isActive = true
        
        container.widthAnchor.constraint(equalToConstant: 550).isActive = true
        self.view = container
    }
    
    private func createFormRow(label: String, items: [String], defaultIndex: Int, action: Selector) -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.alignment = .centerY
        
        let titleLabel = NSTextField(labelWithString: label)
        titleLabel.font = NSFont.systemFont(ofSize: 13)
        titleLabel.alignment = .right
        titleLabel.widthAnchor.constraint(equalToConstant: 120).isActive = true
        
        let popup = NSPopUpButton()
        popup.addItems(withTitles: items)
        popup.selectItem(at: defaultIndex)
        popup.target = self
        popup.action = action
        popup.widthAnchor.constraint(equalToConstant: 150).isActive = true
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(popup)
        return stack
    }
    
    @objc private func sortChanged(_ sender: NSPopUpButton) { SettingsManager.shared.dockSortBy = sender.indexOfSelectedItem + 1 }
    @objc private func displayChanged(_ sender: NSPopUpButton) { SettingsManager.shared.dockDisplayAs = sender.indexOfSelectedItem }
    @objc private func viewContentChanged(_ sender: NSPopUpButton) { SettingsManager.shared.dockShowAs = sender.indexOfSelectedItem }
}

// MARK: - Filters
class FiltersPreferencesViewController: NSViewController {
    override func loadView() {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 16
        container.edgeInsets = NSEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
        
        let infoLabel = NSTextField(labelWithString: "Select the types of drives that should never be added to the Dock.")
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.isBordered = false
        infoLabel.isEditable = false
        infoLabel.preferredMaxLayoutWidth = 340
        container.addArrangedSubview(infoLabel)
        
        let tmCheckbox = NSButton(checkboxWithTitle: "Ignore Time Machine drives", target: self, action: #selector(tmCheckboxToggled(_:)))
        tmCheckbox.state = SettingsManager.shared.ignoreTimeMachine ? .on : .off
        container.addArrangedSubview(tmCheckbox)
        
        let dmgCheckbox = NSButton(checkboxWithTitle: "Ignore Disk Images (.dmg)", target: self, action: #selector(dmgCheckboxToggled(_:)))
        dmgCheckbox.state = SettingsManager.shared.ignoreDiskImages ? .on : .off
        container.addArrangedSubview(dmgCheckbox)
        
        container.widthAnchor.constraint(equalToConstant: 550).isActive = true
        self.view = container
    }
    
    @objc private func tmCheckboxToggled(_ sender: NSButton) {
        SettingsManager.shared.ignoreTimeMachine = (sender.state == .on)
    }
    @objc private func dmgCheckboxToggled(_ sender: NSButton) {
        SettingsManager.shared.ignoreDiskImages = (sender.state == .on)
    }
}

// MARK: - Excluded Drives
class ExcludedDrivesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private var tableView: NSTableView!
    private var drives: [(uuid: String, name: String)] = []
    
    override func loadView() {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let infoLabel = NSTextField(labelWithString: "Drives in this list will never be added to the Dock.")
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.isBordered = false
        infoLabel.isEditable = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(infoLabel)
        
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView = NSTableView()
        if #available(macOS 11.0, *) {
            tableView.style = .inset
        }
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        
        let column1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        column1.width = 400
        tableView.addTableColumn(column1)
        
        let column2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("StatusColumn"))
        column2.width = 100
        tableView.addTableColumn(column2)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsEmptySelection = false
        tableView.allowsMultipleSelection = false
        
        scrollView.documentView = tableView
        container.addSubview(scrollView)
        
        let removeButton = NSButton(title: "Remove Exclude", target: self, action: #selector(removeSelected))
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(removeButton)
        
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 550),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 280),
            
            infoLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            
            scrollView.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: removeButton.topAnchor, constant: -10),
            
            removeButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            removeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
        ])
        
        self.view = container
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        reloadDrives()
    }
    
    private func reloadDrives() {
        drives = SettingsManager.shared.excludedDrives.map { ($0.key, $0.value) }.sorted { $0.name < $1.name }
        tableView.reloadData()
    }
    
    @objc private func removeSelected() {
        let row = tableView.selectedRow
        guard row >= 0 && row < drives.count else { return }
        let drive = drives[row]
        SettingsManager.shared.unexcludeDrive(uuid: drive.uuid)
        reloadDrives()
        VolumeMonitor.shared.refreshAndSynchronize()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int { return drives.count }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let drive = drives[row]
        let cellID = NSUserInterfaceItemIdentifier("Cell")
        var cell = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTextField
        if cell == nil {
            cell = NSTextField(labelWithString: "")
            cell?.identifier = cellID
            cell?.isBordered = false
            cell?.isEditable = false
            cell?.drawsBackground = false
        }
        
        if tableColumn?.identifier.rawValue == "NameColumn" {
            cell?.stringValue = drive.name
            cell?.textColor = .labelColor
        } else if tableColumn?.identifier.rawValue == "StatusColumn" {
            let isConnected = VolumeMonitor.shared.getConnectedDrives().contains {
                (try? $0.resourceValues(forKeys: [.volumeUUIDStringKey]))?.volumeUUIDString == drive.uuid
            }
            cell?.stringValue = isConnected ? "Connected" : "Disconnected"
            cell?.textColor = isConnected ? .systemGreen : .secondaryLabelColor
        }
        
        return cell
    }
}

// MARK: - Advanced
class AdvancedPreferencesViewController: NSViewController {
    override func loadView() {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 16
        container.edgeInsets = NSEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
        
        let infoLabel = NSTextField(labelWithString: "Developer and troubleshooting tools.")
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.isBordered = false
        infoLabel.isEditable = false
        container.addArrangedSubview(infoLabel)
        
        let logsButton = NSButton(title: "Open Logs Folder", target: self, action: #selector(openLogsFolder))
        container.addArrangedSubview(logsButton)
        
        let exportButton = NSButton(title: "Export Diagnostics...", target: self, action: #selector(exportDiagnostics))
        container.addArrangedSubview(exportButton)
        
        container.widthAnchor.constraint(equalToConstant: 550).isActive = true
        self.view = container
    }
    
    @objc private func openLogsFolder() {
        let logDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs")
        NSWorkspace.shared.open(logDir)
    }
    
    @objc private func exportDiagnostics() {
        Logger.shared.exportDiagnostics()
    }
}

// MARK: - About
class AboutPreferencesViewController: NSViewController {
    override func loadView() {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .centerX
        container.spacing = 12
        container.edgeInsets = NSEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
        
        let iconView = NSImageView()
        iconView.image = NSApplication.shared.applicationIconImage ?? NSImage(named: NSImage.applicationIconName)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.widthAnchor.constraint(equalToConstant: 72).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 72).isActive = true
        container.addArrangedSubview(iconView)
        
        let nameLabel = NSTextField(labelWithString: "AutoDockDrive")
        nameLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        nameLabel.isBordered = false
        nameLabel.isEditable = false
        container.addArrangedSubview(nameLabel)
        
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let versionLabel = NSTextField(labelWithString: "Version \(versionString)")
        versionLabel.font = NSFont.systemFont(ofSize: 12)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.isBordered = false
        versionLabel.isEditable = false
        container.addArrangedSubview(versionLabel)
        
        container.setCustomSpacing(20, after: versionLabel)
        
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 10
        
        let githubButton = NSButton(title: "GitHub", target: self, action: #selector(openGitHub))
        let updatesButton = NSButton(title: "Check for Updates", target: self, action: #selector(checkUpdates))
        
        buttonStack.addArrangedSubview(githubButton)
        buttonStack.addArrangedSubview(updatesButton)
        container.addArrangedSubview(buttonStack)
        
        container.setCustomSpacing(20, after: buttonStack)
        
        let copyrightLabel = NSTextField(labelWithString: "© 2026 willyhay22. Released under the MIT License.")
        copyrightLabel.font = NSFont.systemFont(ofSize: 11)
        copyrightLabel.textColor = .tertiaryLabelColor
        copyrightLabel.isBordered = false
        copyrightLabel.isEditable = false
        container.addArrangedSubview(copyrightLabel)
        
        container.widthAnchor.constraint(equalToConstant: 550).isActive = true
        self.view = container
    }
    
    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/willyhay22/AutoDockDrive") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func checkUpdates() {
        // Assume UpdateManager has a shared instance
        // Calling it via Notification or directly if UpdateManager is imported
        // Wait, we need to make sure UpdateManager is accessible. It was in AppDelegate.
        // I will trigger an update check via a notification or direct call.
        NotificationCenter.default.post(name: Notification.Name("CheckForUpdates"), object: nil)
    }
}
