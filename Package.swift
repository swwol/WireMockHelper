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
      .package(url: "https://github.com/httpswift/swifter.git", .upToNextMajor(from: "1.5.0"))
    ],
    targets: [
        .target(
          name: "WireMockXCTest",
          dependencies: [.product(name: "Swifter", package: "Swifter")]
        ),
        .target(name: "WireMockHelper"),
        .testTarget(name: "WireMockHelperTests")
    ]
)
