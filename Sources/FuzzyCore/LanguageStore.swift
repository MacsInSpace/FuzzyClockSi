import Foundation

/// Finds every `*.lproj/Localizable.strings` language in a set of directories.
/// Later directories win, so user-imported languages can override bundled ones.
public enum LanguageStore {
    /// `~/Library/Application Support/FuzzyClockSi/Languages`
    public static var userDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FuzzyClockSi/Languages", isDirectory: true)
    }

    public static func load(from directories: [URL]) -> [Language] {
        var byID: [String: Language] = [:]
        let fm = FileManager.default
        for dir in directories {
            // Optional display names, e.g. "Berndeutsch" = "Bärndütsch";
            let names = NSDictionary(contentsOf: dir.appendingPathComponent("LocalizationNames.strings"))
                as? [String: String] ?? [:]
            guard let entries = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for url in entries where url.pathExtension == "lproj" {
                let id = url.deletingPathExtension().lastPathComponent
                if let lang = Language(lprojURL: url, displayName: names[id] ?? byID[id]?.displayName) {
                    byID[id] = lang
                }
            }
        }
        return byID.values.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
