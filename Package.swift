// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Dropfiles",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "dropfiles",
            targets: ["Dropfiles"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Dropfiles",
            path: "Sources"
        ),
        .testTarget(
            name: "DropfilesTests",
            dependencies: ["Dropfiles"],
            path: "Tests"
        )
    ]
)
