// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SudoConfigManager",
    platforms: [
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "SudoConfigManager",
            targets: ["SudoConfigManager"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/sudoplatform/sudo-logging-ios", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "SudoConfigManager", 
            dependencies: [
                .product(name: "SudoLogging", package: "sudo-logging-ios")
            ],
            path: "SudoConfigManager",
            swiftSettings: [.swiftLanguageMode(.v5)],
        ),
    ]
)
