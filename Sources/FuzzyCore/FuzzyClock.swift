import Foundation

/// The phrase buckets a time can fall into, keyed exactly as in FuzzyTime's strings files.
public enum Phrase: String, CaseIterable, Sendable {
    case oClock = "%@ o'clock"
    case shortlyAfter = "shortly after %@"
    case fivePast = "five past %@"
    case tenPast = "ten past %@"
    case quarterPast = "quarter past %@"
    case twentyPast = "twenty past %@"
    case twentyfivePast = "twentyfive past %@"
    case halfPast = "half past %@"
    case twentyfiveTo = "twentyfive to %@"
    case twentyTo = "twenty to %@"
    case quarterTo = "quarter to %@"
    case tenTo = "ten to %@"
    case fiveTo = "five to %@"
    case nearly = "nearly %@"

    /// e.g. "quarter to ref". `%@ o'clock` has no ref key and always names the nearest hour.
    var refKey: String? {
        self == .oClock ? nil : rawValue.replacingOccurrences(of: "%@", with: "ref")
    }

    /// English semantics, used if a language file omits the ref key.
    var defaultRefIsNext: Bool {
        switch self {
        case .twentyfiveTo, .twentyTo, .quarterTo, .tenTo, .fiveTo, .nearly: return true
        default: return false
        }
    }

    /// Which phrase a given minute (0–59) maps to.
    ///
    /// Minutes round to the nearest five (so :48 is "ten to", matching FuzzyTime). Within the
    /// top-of-the-hour bucket, exactly :00 is "o'clock", :01–:02 "shortly after", :58–:59
    /// "nearly". Tweak here if comparison against the original shows a different split.
    ///
    /// With `fiveMinuteSteps`, there is no "shortly after"/"nearly": :58–:02 is just "o'clock"
    /// (of the nearest hour), as in the original Fuzzy Clock's 5-minute option.
    public static func forMinute(_ minute: Int, fiveMinuteSteps: Bool = false) -> (phrase: Phrase, hourOffset: Int) {
        let bucket = (minute + 2) / 5   // 0...12
        if !fiveMinuteSteps {
            switch minute {
            case 0: return (.oClock, 0)
            case 1...2: return (.shortlyAfter, 0)
            case 58...59: return (.nearly, 1)
            default: break
            }
        }
        if bucket == 12 { return (.oClock, 1) }
        let phrases: [Phrase] = [.oClock, .fivePast, .tenPast, .quarterPast, .twentyPast,
                                 .twentyfivePast, .halfPast, .twentyfiveTo, .twentyTo,
                                 .quarterTo, .tenTo, .fiveTo]
        return (phrases[bucket], 0)
    }
}

public struct FuzzyClock: Sendable {
    public var language: Language
    public var uppercase = false
    public var prefixWithDay = false
    public var fiveMinuteSteps = false

    public init(language: Language) {
        self.language = language
    }

    static let hourKeys = ["twelve", "one", "two", "three", "four", "five", "six",
                           "seven", "eight", "nine", "ten", "eleven"]
    static let dayKeys = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    public func string(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.hour, .minute, .weekday], from: date)
        return string(hour: c.hour ?? 0, minute: c.minute ?? 0, weekday: c.weekday ?? 1)
    }

    /// - Parameters: hour 0–23, minute 0–59, weekday 1 (Sunday) – 7 (Saturday).
    public func string(hour: Int, minute: Int, weekday: Int = 1) -> String {
        let (phrase, offset) = Phrase.forMinute(minute, fiveMinuteSteps: fiveMinuteSteps)
        let next = offset > 0 || language.refersToNextHour(phrase)
        let targetHour = (hour + (next ? 1 : 0)) % 24

        var text: String
        if phrase == .oClock && targetHour == 0 && language.table["midnight"] != nil {
            text = language.string("midnight")
        } else {
            let hourKey = Self.hourKeys[targetHour % 12]
            // Some languages inflect "one" before "o'clock" (German "ein Uhr" vs "eins").
            let hourWord = (phrase == .oClock && hourKey == "one")
                ? language.string("one o'clock")
                : language.string(hourKey)
            text = language.string(phrase.rawValue).replacingOccurrences(of: "%@", with: hourWord)
        }

        if prefixWithDay {
            text = language.string(Self.dayKeys[(weekday - 1) % 7]) + " " + text
        }
        return uppercase ? text.uppercased() : text
    }
}
