import Foundation
import os.log
import AppKit

/// A centralized logger that writes to both the console (via `os_log`) and a log file in `~/Library/Logs/AutoDockDrive.log`.
class Logger {
    static let shared = Logger()
    
    private let logFileURL: URL
    private let fileHandle: FileHandle?
    private let dateFormatter: DateFormatter
    
    /// Enable this to log very verbose output.
    var isDebugEnabled: Bool = true
    
    private init() {
        let logDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs")
        
        do {
            if !FileManager.default.fileExists(atPath: logDirectory.path) {
                try FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            print("Failed to create log directory: \(error)")
        }
        
        logFileURL = logDirectory.appendingPathComponent("AutoDockDrive.log")
        
        if let attrs = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
           let fileSize = attrs[.size] as? UInt64, fileSize > 1_000_000 { // 1MB
            let rotatedURL = logDirectory.appendingPathComponent("AutoDockDrive_old.log")
            try? FileManager.default.removeItem(at: rotatedURL)
            try? FileManager.default.moveItem(at: logFileURL, to: rotatedURL)
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        } else if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
        
        do {
            fileHandle = try FileHandle(forWritingTo: logFileURL)
            fileHandle?.seekToEndOfFile()
        } catch {
            print("Failed to open log file for writing: \(error)")
            fileHandle = nil
        }
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    func exportDiagnostics() {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let diagURL = desktop.appendingPathComponent("AutoDockDrive_Diagnostics_\(Int(Date().timeIntervalSince1970)).txt")
        
        var diagText = "=== AutoDockDrive Diagnostics ===\n"
        diagText += "Date: \(dateFormatter.string(from: Date()))\n"
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        diagText += "App Version: \(version)\n"
        
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        diagText += "macOS Version: \(osVersion)\n"
        
        #if arch(x86_64)
        diagText += "Architecture: Intel (x86_64)\n"
        #elseif arch(arm64)
        diagText += "Architecture: Apple Silicon (arm64)\n"
        #else
        diagText += "Architecture: Unknown\n"
        #endif
        
        diagText += "\n--- Preferences ---\n"
        if let prefs = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "com.willyhay22.AutoDockDrive") {
            for (key, value) in prefs {
                diagText += "\(key): \(value)\n"
            }
        }
        
        diagText += "\n--- Recent Logs ---\n"
        if let logData = try? Data(contentsOf: logFileURL),
           let logStr = String(data: logData, encoding: .utf8) {
            let lines = logStr.components(separatedBy: .newlines)
            let tail = lines.suffix(100).joined(separator: "\n")
            diagText += tail
        }
        
        do {
            try diagText.write(to: diagURL, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([diagURL])
        } catch {
            self.error("Failed to export diagnostics: \(error)")
        }
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    /// Logs an informational message.
    func info(_ message: String) {
        log(message, level: "INFO")
    }
    
    /// Logs an error message.
    func error(_ message: String) {
        log(message, level: "ERROR")
    }
    
    /// Logs a debug message if debug mode is enabled.
    func debug(_ message: String) {
        if isDebugEnabled {
            log(message, level: "DEBUG")
        }
    }
    
    private func log(_ message: String, level: String) {
        let timestamp = dateFormatter.string(from: Date())
        let formattedMessage = "[\(timestamp)] [\(level)] \(message)\n"
        
        // Print to console
        print(formattedMessage, terminator: "")
        
        // Also log via os_log for Console.app integration
        let osLogType: OSLogType
        switch level {
        case "ERROR": osLogType = .error
        case "DEBUG": osLogType = .debug
        default: osLogType = .info
        }
        os_log("%{public}@", type: osLogType, message)
        
        // Write to log file
        if let data = formattedMessage.data(using: .utf8) {
            fileHandle?.write(data)
            // macOS file system might not sync immediately, but good enough for general logging
        }
    }
}
