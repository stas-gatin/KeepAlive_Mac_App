// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KeepAlive",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "KeepAlive", targets: ["KeepAlive"])
    ],
    targets: [
        .executableTarget(
            name: "KeepAlive",
            path: ".",
            exclude: ["README.md", "Package.swift"],
            sources: [
                "KeepAliveApp.swift",
                "KeepAliveManager.swift",
                "MenuView.swift",
                "ShellExecutor.swift"
            ]
        )
    ]
)
