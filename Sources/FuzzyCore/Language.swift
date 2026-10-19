import Foundation

/// A fuzzy-time language, loaded from a `<Name>.lproj/Localizable.strings` file.
///
/// The file format is the same one FuzzyTime used, so its 60+ language folders can be
/// dropped in unchanged. Each phrase has a template plus a "ref" entry saying which
/// hour it names:
///
///     "quarter to %@"   = "viertel vor %@";
///     "quarter to ref"  = "next";          // 2:45 -> "viertel vor drei"
///     "half past %@"    = "halb %@";
///     "half past ref"   = "next";          // 2:30 -> "halb drei"
public struct Language: Sendable {
    public let id: String
    public let displayName: String
    let table: [String: String]

    public init(id: String, displayName: String? = nil, table: [String: String]) {
        self.id = id
        self.displayName = displayName ?? id.replacingOccurrences(of: "_", with: " ")
        self.table = table
    }

    /// Loads a language from an `.lproj` directory (text or binary `.strings` both work).
    public init?(lprojURL: URL, displayName: String? = nil) {
        let file = lprojURL.appendingPathComponent("Localizable.strings")
        guard let dict = NSDictionary(contentsOf: file) as? [String: String] else { return nil }
        self.init(id: lprojURL.deletingPathExtension().lastPathComponent,
                  displayName: displayName, table: dict)
    }

    /// Looks up a key, falling back to the key itself (as `NSLocalizedString` does).
    public func string(_ key: String) -> String {
        table[key] ?? key
    }

    func refersToNextHour(_ phrase: Phrase) -> Bool {
        guard let refKey = phrase.refKey else { return false }
        if let ref = table[refKey] { return ref == "next" }
        return phrase.defaultRefIsNext
    }
}
