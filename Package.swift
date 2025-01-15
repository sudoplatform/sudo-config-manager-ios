// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "SudoConfigManager",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "SudoConfigManager",
            targets: ["SudoConfigManager"]),
    ],
    dependencies: [
        .package(url: "https://github.com/aws-amplify/aws-sdk-ios-spm", exact: "2.36.7"),
        .package(url: "https://github.com/sudoplatform/sudo-logging-ios", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "SudoConfigManager", 
            dependencies: [
                .product(name: "AWSCore", package: "aws-sdk-ios-spm"),
                .product(name: "AWSS3", package: "aws-sdk-ios-spm"),
                .product(name: "SudoLogging", package: "sudo-logging-ios")
            ],
            path: "SudoConfigManager"
        )
    ]
)
