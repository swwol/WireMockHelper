// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireMockHelper",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(
            name: "WireMockXCTest",
            targets: ["WireMockXCTest"]),
        .library(name: "WireMockHelper", targets: ["WireMockHelper"])
    ],
    targets: [
        .target(name: "WireMockXCTest"),
        .target(name: "WireMockHelper"),
    ]
)
