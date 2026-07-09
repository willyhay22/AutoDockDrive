import Foundation
import os.log

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
        
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
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
