import AppKit
import Combine
import FuzzyCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = Settings.shared
    private var statusItem: NSStatusItem!
    private var languages: [Language] = []
    private var timer: Timer?
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        reloadLanguages()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.autosaveName = "FuzzyClockSi"
        statusItem.menu = buildMenu()

        // Re-render whenever a preference changes (next runloop pass, after the value is stored).
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.update() }
            .store(in: &cancellables)

        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(update), name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(update),
                                               name: .NSSystemClockDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(update),
                                               name: .NSSystemTimeZoneDidChange, object: nil)

        update()
        scheduleTimer()
    }

    // MARK: - Rendering

    private var clock: FuzzyClock {
        let lang = languages.first { $0.id == settings.language }
            ?? languages.first { $0.id == "English" }
            ?? Language(id: "English", table: [:])
        var clock = FuzzyClock(language: lang)
        clock.uppercase = settings.uppercase
        clock.prefixWithDay = settings.prefixWithDay
        clock.fiveMinuteSteps = settings.fiveMinuteSteps
        return clock
    }

    func currentText(at date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let minuteOfDay = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        if let special = settings.specials.first(where: { $0.contains(minuteOfDay: minuteOfDay) }) {
            return settings.uppercase ? special.text.uppercased() : special.text
        }
        return clock.string(for: date)
    }

    /// For `--print`: same text as the menu bar, without starting the UI.
    func currentTextForPrint(at date: Date) -> String {
        reloadLanguages()
        return currentText(at: date)
    }

    @objc private func update() {
        guard let button = statusItem?.button else { return }
        var attrs: [NSAttributedString.Key: Any] = [:]
        if settings.useCustomFont, let font = NSFont(name: settings.fontName, size: settings.fontSize) {
            attrs[.font] = font
        } else {
            attrs[.font] = NSFont.menuBarFont(ofSize: 0)
        }
        if settings.useCustomColor { attrs[.foregroundColor] = settings.customColor }
        if settings.drawShadow {
            let shadow = NSShadow()
            shadow.shadowOffset = NSSize(width: 0, height: -1)
            shadow.shadowBlurRadius = 2
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
            attrs[.shadow] = shadow
        }
        button.attributedTitle = NSAttributedString(string: currentText(), attributes: attrs)
    }

    /// Fires on each minute boundary; tolerance keeps wakeups cheap.
    private func scheduleTimer() {
        let now = Date()
        let nextMinute = Calendar.current.nextDate(after: now, matching: DateComponents(second: 0),
                                                   matchingPolicy: .nextTime) ?? now.addingTimeInterval(60)
        let t = Timer(fire: nextMinute, interval: 60, repeats: true) { [weak self] _ in self?.update() }
        t.tolerance = 1
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Fuzzy Clock Si", action: #selector(NSApplication.terminate(_:)),
                     keyEquivalent: "q")
        return menu
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let names = Dictionary(uniqueKeysWithValues: languages.map { ($0.id, $0.displayName) })
            let view = SettingsView(languages: names) { [weak self] in self?.importLanguages() }
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = "Fuzzy Clock Si"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Languages

    private func reloadLanguages() {
        var dirs: [URL] = []
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("Languages") { dirs.append(bundled) }
        dirs.append(LanguageStore.userDirectory)
        languages = LanguageStore.load(from: dirs)
    }

    /// Copies the language folders out of an installed FuzzyTime.app for personal use.
    private func importLanguages() {
        let source = URL(fileURLWithPath: "/Applications/FuzzyTime.app/Contents/Resources")
        let dest = LanguageStore.userDirectory
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: dest, withIntermediateDirectories: true)
            for url in try fm.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
            where url.pathExtension == "lproj" || url.lastPathComponent == "LocalizationNames.strings" {
                guard url.pathExtension != "lproj"
                        || fm.fileExists(atPath: url.appendingPathComponent("Localizable.strings").path) else { continue }
                let target = dest.appendingPathComponent(url.lastPathComponent)
                try? fm.removeItem(at: target)
                try fm.copyItem(at: url, to: target)
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
            return
        }
        reloadLanguages()
        settingsWindow?.close()
        settingsWindow = nil
        openSettings()
    }
}
