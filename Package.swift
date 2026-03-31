// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GentleRemoteStrings",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "GentleRemoteStrings",
            targets: ["GentleRemoteStrings"]
        )
    ],
    targets: [
        .target(
            name: "GentleRemoteStrings"
        ),
        .testTarget(
            name: "GentleRemoteStringsTests",
            dependencies: ["GentleRemoteStrings"],
            resources: [.copy("Fixtures")]
        )
    ]
)
