import Cocoa

class AboutWindowController: NSWindowController {
    
    init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 160),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = "About AutoDockDrive"
        window.center()
        
        super.init(window: window)
        
        let contentView = NSView()
        
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .centerX
        container.spacing = 8
        container.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        // App Icon
        let iconView = NSImageView()
        iconView.image = NSApplication.shared.applicationIconImage ?? NSImage(named: NSImage.applicationIconName)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.widthAnchor.constraint(equalToConstant: 64).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        container.addArrangedSubview(iconView)
        
        // Spacer
        container.setCustomSpacing(15, after: iconView)
        
        // App Name
        let nameLabel = NSTextField(labelWithString: "AutoDockDrive")
        nameLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        container.addArrangedSubview(nameLabel)
        
        // Version
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let versionLabel = NSTextField(labelWithString: "Version \(versionString)")
        versionLabel.font = NSFont.systemFont(ofSize: 11)
        versionLabel.textColor = .secondaryLabelColor
        container.addArrangedSubview(versionLabel)
        
        // Copyright
        let copyrightLabel = NSTextField(labelWithString: "© 2026 wihay. All rights reserved.")
        copyrightLabel.font = NSFont.systemFont(ofSize: 10)
        copyrightLabel.textColor = .tertiaryLabelColor
        container.addArrangedSubview(copyrightLabel)
        
        window.contentView = contentView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
