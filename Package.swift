// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "URLImage",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "URLImage",
            targets: ["URLImage"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "URLImage",
            dependencies: [ "RemoteContentView", "DownloadManager", "ImageDecoder", "FileIndex" ]),

        .target(
            name: "RemoteContentView"),
        .target(
            name: "ImageDecoder",
            dependencies: []),
        .target(
            name: "FileIndex",
            dependencies: [ "PlainDatabase" ]),
        .target(
            name: "PlainDatabase",
            dependencies: []),
        .target(
            name: "DownloadManager",
            dependencies: []),

        .testTarget(
            name: "ImageDecoderTests",
            dependencies: ["ImageDecoder"],
            resources: [ .copy("Resources/TestImages.json"),
                         .copy("Resources/lenna.jpg"),
                         .copy("Resources/lenna.png"),
                         .copy("Resources/sea_animation.heics"),
                         .copy("Resources/gif-loop-count.gif"),
                         .copy("Resources/quicksort.gif")
            ]),
        .testTarget(
            name: "FileIndexTests",
            dependencies: ["FileIndex"]),
        .testTarget(
            name: "PlainDatabaseTests",
            dependencies: ["PlainDatabase"]),
        .testTarget(
            name: "URLImageTests",
            dependencies: ["URLImage"]),
    ]
)
