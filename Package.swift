// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NaturalScrollSwitcher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "NaturalScrollSwitcher", targets: ["NaturalScrollSwitcher"]),
        .executable(name: "NaturalScrollSelfTest", targets: ["NaturalScrollSelfTest"])
    ],
    targets: [
        .target(name: "NaturalScrollCore"),
        .executableTarget(
            name: "NaturalScrollSwitcher",
            dependencies: ["NaturalScrollCore"]
        ),
        .executableTarget(
            name: "NaturalScrollSelfTest",
            dependencies: ["NaturalScrollCore"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
