// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "IdentityKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "IdentityKit",
            targets: ["IdentityKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/bsurrey/GlassIconKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "IdentityKit",
            dependencies: ["GlassIconKit"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "IdentityKitTests",
            dependencies: ["IdentityKit"]
        )
    ],
    swiftLanguageModes: [.v6]
)
