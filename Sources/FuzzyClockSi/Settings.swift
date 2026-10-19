import AppKit
import SwiftUI

/// A time window whose text replaces the fuzzy time, e.g. 12:00–13:00 "lunch!".
struct Special: Codable, Identifiable, Hashable {
    var id = UUID()
    var start = "12:00"   // hh:mm, inclusive
    var end = "13:00"     // hh:mm, exclusive; may wrap past midnight
    var text = "lunch"

    func contains(minuteOfDay m: Int) -> Bool {
        guard let s = Self.minutes(start), let e = Self.minutes(end) else { return false }
        return s <= e ? (m >= s && m < e) : (m >= s || m < e)
    }

    static func minutes(_ hhmm: String) -> Int? {
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, (0..<24).contains(parts[0]), (0..<60).contains(parts[1]) else { return nil }
        return parts[0] * 60 + parts[1]
    }
}

/// All user preferences, persisted in UserDefaults and observed by the menu bar item.
final class Settings: ObservableObject {
    static let shared = Settings()

    @AppStorage("language") var language = "English"
    @AppStorage("uppercase") var uppercase = false
    @AppStorage("prefixWithDay") var prefixWithDay = false
    @AppStorage("fiveMinuteSteps") var fiveMinuteSteps = false
    @AppStorage("drawShadow") var drawShadow = false
    @AppStorage("useCustomColor") var useCustomColor = false
    @AppStorage("customColor") var customColorHex = "#FFFFFF"
    @AppStorage("useCustomFont") var useCustomFont = false
    @AppStorage("fontName") var fontName = "Helvetica Neue"
    @AppStorage("fontSize") var fontSize = 13.0
    @AppStorage("specials") private var specialsData = Data()

    var specials: [Special] {
        get { (try? JSONDecoder().decode([Special].self, from: specialsData)) ?? [] }
        set {
            specialsData = (try? JSONEncoder().encode(newValue)) ?? Data()
            objectWillChange.send()
        }
    }

    var customColor: NSColor {
        get { NSColor(hex: customColorHex) ?? .labelColor }
        set { customColorHex = newValue.hexString }
    }
}

extension NSColor {
    convenience init?(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
                  blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }

    var hexString: String {
        guard let c = usingColorSpace(.sRGB) else { return "#FFFFFF" }
        return String(format: "#%02X%02X%02X", Int(round(c.redComponent * 255)),
                      Int(round(c.greenComponent * 255)), Int(round(c.blueComponent * 255)))
    }
}
