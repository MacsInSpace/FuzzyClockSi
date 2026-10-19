// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "FuzzyClockSi",
    platforms: [.macOS(.v13)],
    targets: [
        // Pure, testable logic: minute bucketing + language-file phrase lookup.
        .target(name: "FuzzyCore"),
        // The menu bar app itself (AppKit + a small SwiftUI settings window).
        .executableTarget(name: "FuzzyClockSi", dependencies: ["FuzzyCore"]),
        .testTarget(name: "FuzzyCoreTests", dependencies: ["FuzzyCore"]),
    ]
)
