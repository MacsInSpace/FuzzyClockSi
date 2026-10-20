import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    let languages: [String: String]   // id -> display name
    let onImport: () -> Void

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "clock") }
            looks.tabItem { Label("Color & Font", systemImage: "textformat") }
            SpecialsView().tabItem { Label("Specials", systemImage: "star") }
            AboutView().tabItem { Label("About", systemImage: "info.circle") }
        }
        .padding(20)
        .frame(width: 460, height: 340)
    }

    private var general: some View {
        Form {
            Picker("Language", selection: $settings.language) {
                ForEach(languages.sorted { $0.value < $1.value }, id: \.key) { id, name in
                    Text(name).tag(id)
                }
            }
            Button("Import languages from FuzzyTime.app…", action: onImport)
            Picker("Fuzziness", selection: $settings.fiveMinuteSteps) {
                Text("Fuzzy \u{2014} 5-minute steps (\u{201C}five past one\u{201D})").tag(true)
                Text("Fuzzier \u{2014} adds \u{201C}shortly after\u{201D} / \u{201C}nearly\u{201D}").tag(false)
            }
            Toggle("Uppercase", isOn: $settings.uppercase)
            Toggle("Show day in menu bar", isOn: $settings.prefixWithDay)
            LaunchAtLoginToggle()
        }
    }

    private var looks: some View {
        Form {
            Toggle("Draw text with shadow", isOn: $settings.drawShadow)
            Toggle("Custom text color", isOn: $settings.useCustomColor)
            ColorPicker("Text color", selection: Binding(
                get: { Color(nsColor: settings.customColor) },
                set: { settings.customColor = NSColor($0) }), supportsOpacity: false)
                .disabled(!settings.useCustomColor)
            Toggle("Custom font", isOn: $settings.useCustomFont)
            Picker("Font", selection: $settings.fontName) {
                ForEach(NSFontManager.shared.availableFontFamilies, id: \.self) { Text($0).tag($0) }
            }
            .disabled(!settings.useCustomFont)
            Stepper("Size: \(Int(settings.fontSize)) pt", value: $settings.fontSize, in: 9...18)
                .disabled(!settings.useCustomFont)
        }
    }
}

private struct LaunchAtLoginToggle: View {
    @State private var enabled = LoginAgent.isInstalled

    var body: some View {
        Toggle("Start at login", isOn: Binding(get: { enabled }, set: { on in
            do {
                if on { try LoginAgent.install() } else { try LoginAgent.uninstall() }
            } catch {
                NSLog("Start at login: \(error)")
            }
            enabled = LoginAgent.isInstalled
        }))
    }
}

private struct AboutView: View {
    private static let projectURL = URL(string: "https://github.com/MacsInSpace/FuzzyClockSi")!

    private var version: String {
        let info = Bundle.main.infoDictionary
        guard let short = info?["CFBundleShortVersionString"] as? String else { return "development build" }
        let build = info?["CFBundleVersion"] as? String
        return build.map { "\(short) (\($0))" } ?? short
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 64, height: 64)
            Text("Fuzzy Clock Si").font(.title2.bold())
            Text("Version \(version)").foregroundStyle(.secondary).textSelection(.enabled)
            Link("github.com/MacsInSpace/FuzzyClockSi", destination: Self.projectURL)
            Divider().padding(.vertical, 4)
            VStack(alignment: .leading, spacing: 6) {
                Text("Acknowledgements").font(.headline)
                Text("Inspired by the original **FuzzyClock** by Guido Neitzer.")
                Text("A clean-room replacement for **FuzzyTime** by Marcus Olovsson, whose language files can be imported for personal use.")
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct SpecialsView: View {
    @ObservedObject var settings = Settings.shared
    @State private var selection: Special.ID?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Show custom text between two times (hh:mm, end exclusive).")
                .font(.callout).foregroundStyle(.secondary)
            Table(settings.specials, selection: $selection) {
                TableColumn("Start") { s in field(s, \.start) }.width(60)
                TableColumn("End") { s in field(s, \.end) }.width(60)
                TableColumn("Text") { s in field(s, \.text) }
            }
            HStack {
                Button("Add") { settings.specials.append(Special()) }
                Button("Remove") { settings.specials.removeAll { $0.id == selection } }
                    .disabled(selection == nil)
            }
        }
    }

    private func field(_ special: Special, _ key: WritableKeyPath<Special, String>) -> some View {
        TextField("", text: Binding(
            get: { special[keyPath: key] },
            set: { value in
                var all = settings.specials
                if let i = all.firstIndex(where: { $0.id == special.id }) {
                    all[i][keyPath: key] = value
                    settings.specials = all
                }
            }))
    }
}
