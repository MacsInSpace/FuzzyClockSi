import XCTest
@testable import FuzzyCore

final class FuzzyClockTests: XCTestCase {
    let english = Language(id: "English", table: [
        "%@ o'clock": "%@ o’clock", "one o'clock": "one", "midnight": "Midnight",
        "one": "one", "two": "two", "ten": "ten", "eleven": "eleven", "twelve": "twelve",
        "ten to %@": "ten to %@", "ten to ref": "next",
        "quarter past %@": "quarter past %@", "quarter past ref": "current",
        "half past %@": "half past %@", "half past ref": "current",
        "nearly %@": "nearly %@", "nearly ref": "next",
        "shortly after %@": "shortly after %@", "shortly after ref": "current",
        "Monday": "mon",
    ])

    let german = Language(id: "German", table: [
        "%@ o'clock": "%@ Uhr", "one o'clock": "ein", "one": "eins", "two": "zwei", "three": "drei",
        "half past %@": "halb %@", "half past ref": "next",
        "twentyfive past %@": "fünf vor halb %@", "twentyfive past ref": "next",
    ])

    func testMatchesOriginalObservation() {
        // Observed from FuzzyTime.app at 10:48.
        XCTAssertEqual(FuzzyClock(language: english).string(hour: 10, minute: 48), "ten to eleven")
    }

    func testBuckets() {
        let c = FuzzyClock(language: english)
        XCTAssertEqual(c.string(hour: 1, minute: 0), "one o’clock")
        XCTAssertEqual(c.string(hour: 1, minute: 2), "shortly after one")
        XCTAssertEqual(c.string(hour: 2, minute: 13), "quarter past two")
        XCTAssertEqual(c.string(hour: 2, minute: 32), "half past two")
        XCTAssertEqual(c.string(hour: 1, minute: 59), "nearly two")
        XCTAssertEqual(c.string(hour: 23, minute: 59), "nearly twelve")
        XCTAssertEqual(c.string(hour: 0, minute: 0), "Midnight")
    }

    func testFiveMinuteSteps() {
        var c = FuzzyClock(language: english)
        c.fiveMinuteSteps = true
        XCTAssertEqual(c.string(hour: 1, minute: 0), "one o’clock")
        XCTAssertEqual(c.string(hour: 1, minute: 2), "one o’clock")
        XCTAssertEqual(c.string(hour: 0, minute: 58), "one o’clock")
        XCTAssertEqual(c.string(hour: 23, minute: 59), "Midnight")
        XCTAssertEqual(c.string(hour: 10, minute: 48), "ten to eleven")
        for m in 0..<60 {
            let p = Phrase.forMinute(m, fiveMinuteSteps: true).phrase
            XCTAssert(p != .shortlyAfter && p != .nearly, "minute \(m)")
        }
    }

    func testEveryMinuteHasAPhrase() {
        for m in 0..<60 { _ = Phrase.forMinute(m) }
    }

    func testGermanNextHourRefs() {
        let c = FuzzyClock(language: german)
        XCTAssertEqual(c.string(hour: 2, minute: 30), "halb drei")
        XCTAssertEqual(c.string(hour: 2, minute: 25), "fünf vor halb drei")
        XCTAssertEqual(c.string(hour: 1, minute: 0), "ein Uhr")
    }

    func testDayAndUppercase() {
        var c = FuzzyClock(language: english)
        c.prefixWithDay = true
        c.uppercase = true
        XCTAssertEqual(c.string(hour: 10, minute: 48, weekday: 2), "MON TEN TO ELEVEN")
    }
}
