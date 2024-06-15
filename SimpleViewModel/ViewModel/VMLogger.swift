/// Copyright ⓒ 2024 Bithead LLC. All rights reserved.

import Foundation

public enum VMLogLevel: Int, Comparable {
    case info
    case warning
    case error

    public static func < (a: VMLogLevel, b: VMLogLevel) -> Bool {
        return a.rawValue < b.rawValue
    }
}

var log = VMLogger(
    name: "VMLogger",
    format: "%name %filename:%line %level - %message",
    level: .info
)

public class VMLogger {
    /// Sets internal logger log level
    public static func setLogLevel(_ level: VMLogLevel) {
        log.level = level
    }

    /// Sets internal logger format
    public static func setFormat(_ format: String) {
        log.format = format
    }

    private(set) var name: String
    private(set) var format: String
    private(set) var level: VMLogLevel

    public init(name: String, format: String, level: VMLogLevel) {
        self.name = name
        self.format = format
        self.level = level
    }

    public func i(_ message: String, file: String = #file, line: Int = #line) {
        guard level <= .info else {
            return
        }
        print(formatMessage(message, level: "INFO", file: file, line: line))
    }

    public func w(_ message: String, file: String = #file, line: Int = #line) {
        guard level <= .warning else {
            return
        }
        print(formatMessage(message, level: "WARN", file: file, line: line))
    }

    public func e(_ message: String, file: String = #file, line: Int = #line) {
        guard level <= .error else {
            return
        }
        print(formatMessage(message, level: "ERROR", file: file, line: line))
    }

    private func formatMessage(_ message: String, level: String, file: String, line: Int) -> String {
        format
            .replacingOccurrences(of: "%name", with: name)
            // Display file name only
            .replacingOccurrences(of: "%filename", with: URL(string: file)?.lastPathComponent ?? "")
            // Displays full path to file
            .replacingOccurrences(of: "%file", with: file)
            .replacingOccurrences(of: "%line", with: String(line))
            .replacingOccurrences(of: "%level", with: level)
            .replacingOccurrences(of: "%message", with: message)
    }
}
