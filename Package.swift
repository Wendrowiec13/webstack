// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WebStack",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "WebStack", targets: ["WebStack"]),
    ],
    targets: [
        .executableTarget(
            name: "WebStack",
            path: "Sources/WebStack",
            resources: [
                .process("WindowControls.xcassets")
            ],
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("WebKit"),
            ]
        )
    ]
)
