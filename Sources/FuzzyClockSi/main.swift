import AppKit
import FuzzyCore

// `FuzzyClockSi --print [HH:MM]` prints the fuzzy time and exits (handy for scripts/tests).
let args = CommandLine.arguments
if let i = args.firstIndex(of: "--print") {
    let delegate = AppDelegate()
    if i + 1 < args.count {
        let parts = args[i + 1].split(separator: ":").compactMap { Int($0) }
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = parts.first; c.minute = parts.count > 1 ? parts[1] : 0
        print(delegate.currentTextForPrint(at: Calendar.current.date(from: c) ?? Date()))
    } else {
        print(delegate.currentTextForPrint(at: Date()))
    }
    exit(0)
}

// Single instance: a second copy (e.g. launchd bootstrapping the login agent) just quits.
let me = ProcessInfo.processInfo.processIdentifier
if let id = Bundle.main.bundleIdentifier,
   NSRunningApplication.runningApplications(withBundleIdentifier: id).contains(where: { $0.processIdentifier != me }) {
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
app.run()
