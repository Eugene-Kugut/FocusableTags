// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FocusableTags",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FocusableTags",
            targets: ["FocusableTags"]
        )
    ],
    targets: [
        .target(
            name: "FocusableTags",
            path: "Sources/FocusableTags"
        )
    ]
)
