import Cocoa
import ServiceManagement

class WelcomeWindowController: NSWindowController {
    
    private var launchAtLoginCheckbox: NSButton!
    private var dontShowAgainCheckbox: NSButton!
    
    private var sortByPopup: NSPopUpButton!
    private var displayAsPopup: NSPopUpButton!
    private var viewAsPopup: NSPopUpButton!
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to AutoDockDrive"
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        
        super.init(window: window)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let window = self.window else { return }
        
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .centerX
        container.spacing = 20
        container.edgeInsets = NSEdgeInsets(top: 40, left: 30, bottom: 30, right: 30)
        
        // Icon
        let iconImageView = NSImageView()
        iconImageView.image = NSImage(named: NSImage.applicationIconName)
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.addConstraint(iconImageView.widthAnchor.constraint(equalToConstant: 100))
        iconImageView.addConstraint(iconImageView.heightAnchor.constraint(equalToConstant: 100))
        container.addArrangedSubview(iconImageView)
        
        // Welcome Title
        let titleLabel = NSTextField(labelWithString: "Welcome to AutoDockDrive")
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        container.addArrangedSubview(titleLabel)
        
        // Subtitle
        let subtitleLabel = NSTextField(labelWithString: "Automatically keep your external drives in the Dock while they're connected.")
        subtitleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.alignment = .center
        subtitleLabel.preferredMaxLayoutWidth = 380
        subtitleLabel.lineBreakMode = .byWordWrapping
        container.addArrangedSubview(subtitleLabel)
        
        // Description
        let descLabel = NSTextField(labelWithString: "AutoDockDrive runs quietly in the background and automatically adds supported external drives to your Dock when they're connected, then removes them again when they're disconnected.")
        descLabel.font = NSFont.systemFont(ofSize: 13)
        descLabel.textColor = .labelColor
        descLabel.alignment = .center
        descLabel.preferredMaxLayoutWidth = 380
        descLabel.lineBreakMode = .byWordWrapping
        container.addArrangedSubview(descLabel)
        
        // Divider
        let divider1 = NSBox()
        divider1.boxType = .separator
        container.addArrangedSubview(divider1)
        divider1.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -60).isActive = true
        
        // Setup Section
        let setupLabel = NSTextField(labelWithString: "Before you get started")
        setupLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        container.addArrangedSubview(setupLabel)
        
        // Launch at login checkbox
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch AutoDockDrive automatically when you log in", target: nil, action: nil)
        launchAtLoginCheckbox.state = SettingsManager.shared.startsAtLogin ? .on : .off
        container.addArrangedSubview(launchAtLoginCheckbox)
        
        // Default Appearance Label
        let appearanceLabel = NSTextField(labelWithString: "Appearance for New Drives:")
        appearanceLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        container.addArrangedSubview(appearanceLabel)
        
        let appearanceStack = NSStackView()
        appearanceStack.orientation = .horizontal
        appearanceStack.spacing = 20
        appearanceStack.alignment = .centerY
        
        // Sort By
        let sortStack = createLabeledPopup(label: "Sort by:", items: ["Name", "Date Added", "Date Modified", "Date Created", "Kind"], defaultIndex: 2)
        sortByPopup = sortStack.views[1] as? NSPopUpButton
        appearanceStack.addArrangedSubview(sortStack)
        
        // Display As
        let displayStack = createLabeledPopup(label: "Display as:", items: ["Stack", "Folder"], defaultIndex: 1)
        displayAsPopup = displayStack.views[1] as? NSPopUpButton
        appearanceStack.addArrangedSubview(displayStack)
        
        // View As
        let viewStack = createLabeledPopup(label: "View content as:", items: ["Automatic", "Fan", "Grid", "List"], defaultIndex: 3)
        viewAsPopup = viewStack.views[1] as? NSPopUpButton
        appearanceStack.addArrangedSubview(viewStack)
        
        container.addArrangedSubview(appearanceStack)
        
        // Divider
        let divider2 = NSBox()
        divider2.boxType = .separator
        container.addArrangedSubview(divider2)
        divider2.widthAnchor.constraint(equalTo: container.widthAnchor, constant: -60).isActive = true
        
        // Connected Drives Note
        let connectedDrives = VolumeMonitor.shared.getConnectedDrives()
        if !connectedDrives.isEmpty {
            let count = connectedDrives.count
            let driveString = count == 1 ? "1 connected drive" : "\(count) connected drives"
            let noteLabel = NSTextField(labelWithString: "We'll automatically add \(driveString) to your Dock when setup is complete.")
            noteLabel.font = NSFont.systemFont(ofSize: 12)
            noteLabel.textColor = .secondaryLabelColor
            noteLabel.alignment = .center
            container.addArrangedSubview(noteLabel)
        }
        
        // Don't show again checkbox
        dontShowAgainCheckbox = NSButton(checkboxWithTitle: "Don't show this welcome screen again", target: nil, action: nil)
        dontShowAgainCheckbox.state = .on
        dontShowAgainCheckbox.font = NSFont.systemFont(ofSize: 11)
        container.addArrangedSubview(dontShowAgainCheckbox)
        
        // Buttons
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 15
        
        let learnMoreBtn = NSButton(title: "Learn More…", target: self, action: #selector(learnMoreClicked))
        learnMoreBtn.bezelStyle = .rounded
        
        let getStartedBtn = NSButton(title: "Get Started", target: self, action: #selector(getStartedClicked))
        getStartedBtn.bezelStyle = .rounded
        getStartedBtn.keyEquivalent = "\r"
        getStartedBtn.controlSize = .large
        getStartedBtn.contentTintColor = .controlAccentColor
        
        buttonStack.addArrangedSubview(learnMoreBtn)
        buttonStack.addArrangedSubview(getStartedBtn)
        
        container.addArrangedSubview(buttonStack)
        
        window.contentView = container
    }
    
    private func createLabeledPopup(label: String, items: [String], defaultIndex: Int) -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 5
        stack.alignment = .leading
        
        let titleLabel = NSTextField(labelWithString: label)
        titleLabel.font = NSFont.systemFont(ofSize: 12)
        titleLabel.textColor = .secondaryLabelColor
        
        let popup = NSPopUpButton()
        popup.addItems(withTitles: items)
        popup.selectItem(at: defaultIndex)
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(popup)
        
        return stack
    }
    
    @objc private func learnMoreClicked() {
        if let url = URL(string: "https://github.com/willyhay22/AutoDockDrive") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func getStartedClicked() {
        let settings = SettingsManager.shared
        
        // Save Dock Appearance Settings
        let sortMap = [1, 2, 3, 4, 5]
        let displayMap = [0, 1]
        let showMap = [0, 1, 2, 3]
        
        settings.dockSortBy = sortMap[sortByPopup.indexOfSelectedItem]
        settings.dockDisplayAs = displayMap[displayAsPopup.indexOfSelectedItem]
        settings.dockShowAs = showMap[viewAsPopup.indexOfSelectedItem]
        
        // Handle Launch at Login
        if launchAtLoginCheckbox.state == .on && !settings.startsAtLogin {
            settings.toggleStartAtLogin()
        } else if launchAtLoginCheckbox.state == .off && settings.startsAtLogin {
            settings.toggleStartAtLogin()
        }
        
        // Handle Don't show again
        settings.hasSeenWelcomeScreen = (dontShowAgainCheckbox.state == .on)
        
        // Start monitoring (this triggers the initial sync)
        VolumeMonitor.shared.startMonitoring()
        
        self.close()
    }
}
