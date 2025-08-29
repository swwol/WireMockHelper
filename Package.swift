// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireMockHelper",
    platforms: [.macOS(.v13), .iOS(.v15)],
    products: [
        .library(
            name: "WireMockXCTest",
            targets: ["WireMockXCTest"]),
        .library(name: "WireMockHelper", targets: ["WireMockHelper"])
    ],
    dependencies: [
      .package(url: "https://github.com/swhitty/FlyingFox.git", .upToNextMajor(from: "0.24.1"))
    ],
    targets: [
        .target(
          name: "WireMockXCTest",
          dependencies: [.product(name: "FlyingFox", package: "FlyingFox")]
        ),
        .target(name: "WireMockHelper"),
        .testTarget(name: "WireMockHelperTests", dependencies: ["FlyingFox"])
    ]
)
