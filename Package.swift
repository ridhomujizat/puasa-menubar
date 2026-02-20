// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PuasaMenubar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "PuasaMenubar",
            targets: ["PuasaMenubar"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "PuasaMenubar",
            dependencies: [],
            path: "PuasaMenubar",
            exclude: ["Assets.xcassets", "PuasaMenubar.entitlements", "Info.plist"],
            sources: [
                "PuasaMenubarApp.swift",
                "ContentView.swift",
                "Models/PrayerTimesModel.swift",
                "Services/APIService.swift",
                "Services/LocationManager.swift",
                "Services/PrayerTimesViewModel.swift",
                "Utils/Colors.swift",
                "Views/MenuBarExtra.swift",
                "Views/PrayerTimeRow.swift",
                "Views/PrayerTimesView.swift"
            ]
        ),
    ]
)
