import Foundation

/// Start-at-login via a per-user LaunchAgent (`~/Library/LaunchAgents/local.fuzzyclocksi.plist`),
/// managed with `launchctl bootstrap` / `bootout` rather than the legacy `load` / `unload`.
enum LoginAgent {
    static let label = "local.fuzzyclocksi"

    static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var domain: String { "gui/\(getuid())" }

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    /// Writes the plist and bootstraps it into the GUI domain. Because launchd starts the job
    /// immediately (RunAtLoad), the new copy sees this one running and quits (see main.swift).
    static func install() throws {
        guard let exe = Bundle.main.executablePath else { return }
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [exe],
            "RunAtLoad": true,
            "KeepAlive": false,
            "ProcessType": "Interactive",
            "LimitLoadToSessionType": "Aqua",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try FileManager.default.createDirectory(at: plistURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: plistURL, options: .atomic)
        launchctl("bootout", "\(domain)/\(label)")   // drop any stale copy first; failure is fine
        launchctl("bootstrap", domain, plistURL.path)
    }

    /// Removes the plist. The job is only booted out if launchd didn't start *this* process,
    /// since `bootout` kills the job's process and would quit the app mid-click.
    static func uninstall() throws {
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
        if ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"] != label {
            launchctl("bootout", "\(domain)/\(label)")
        }
    }

    @discardableResult
    private static func launchctl(_ args: String...) -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = args
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return -1 }
        p.waitUntilExit()
        return p.terminationStatus
    }
}
