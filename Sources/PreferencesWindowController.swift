import Cocoa

class PreferencesWindowController: NSWindowController {
    
    init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 280),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = "AutoDockDrive Preferences"
        window.center()
        
        super.init(window: window)
        
        let contentView = NSView()
        
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 20
        container.edgeInsets = NSEdgeInsets(top: 25, left: 30, bottom: 25, right: 30)
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        // Start at Login Checkbox
        let loginCheckbox = NSButton(checkboxWithTitle: "Start AutoDockDrive automatically at login", target: self, action: #selector(loginCheckboxToggled(_:)))
        loginCheckbox.state = SettingsManager.shared.startsAtLogin ? .on : .off
        container.addArrangedSubview(loginCheckbox)
        
        // Auto Updates Checkbox
        let updatesCheckbox = NSButton(checkboxWithTitle: "Automatically check for updates on launch", target: self, action: #selector(updatesCheckboxToggled(_:)))
        updatesCheckbox.state = SettingsManager.shared.automaticallyCheckForUpdates ? .on : .off
        container.addArrangedSubview(updatesCheckbox)
        
        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        container.addArrangedSubview(separator)
        separator.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -60).isActive = true
        
        // Dock Appearance Label
        let appearanceLabel = NSTextField(labelWithString: "Default Dock Appearance for New Drives:")
        appearanceLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        container.addArrangedSubview(appearanceLabel)
        
        let formStack = NSStackView()
        formStack.orientation = .vertical
        formStack.spacing = 15
        formStack.alignment = .trailing
        
        // Sort By
        let sortStack = createFormRow(label: "Sort by:", items: ["Name", "Date Added", "Date Modified", "Date Created", "Kind"], defaultIndex: max(0, SettingsManager.shared.dockSortBy - 1), action: #selector(sortChanged(_:)))
        formStack.addArrangedSubview(sortStack)
        
        // Display As
        let displayStack = createFormRow(label: "Display as:", items: ["Stack", "Folder"], defaultIndex: min(1, max(0, SettingsManager.shared.dockDisplayAs)), action: #selector(displayChanged(_:)))
        formStack.addArrangedSubview(displayStack)
        
        // View Content As
        let viewStack = createFormRow(label: "View content as:", items: ["Automatic", "Fan", "Grid", "List"], defaultIndex: min(3, max(0, SettingsManager.shared.dockShowAs)), action: #selector(viewContentChanged(_:)))
        formStack.addArrangedSubview(viewStack)
        
        container.addArrangedSubview(formStack)
        formStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20).isActive = true
        
        window.contentView = contentView
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
        popup.widthAnchor.constraint(equalToConstant: 180).isActive = true
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(popup)
        
        return stack
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func loginCheckboxToggled(_ sender: NSButton) {
        SettingsManager.shared.toggleStartAtLogin()
    }
    
    @objc private func updatesCheckboxToggled(_ sender: NSButton) {
        SettingsManager.shared.automaticallyCheckForUpdates = (sender.state == .on)
    }
    
    @objc private func sortChanged(_ sender: NSPopUpButton) {
        // Index 0 -> 1, 1 -> 2, etc.
        SettingsManager.shared.dockSortBy = sender.indexOfSelectedItem + 1
    }
    
    @objc private func displayChanged(_ sender: NSPopUpButton) {
        SettingsManager.shared.dockDisplayAs = sender.indexOfSelectedItem
    }
    
    @objc private func viewContentChanged(_ sender: NSPopUpButton) {
        SettingsManager.shared.dockShowAs = sender.indexOfSelectedItem
    }
}
