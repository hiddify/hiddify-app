// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HiddifyMtlsSmoke",
    platforms: [.iOS(.v15)],
    products: [],
    targets: [
        .binaryTarget(
            name: "HiddifyCore",
            path: "../../ios/Frameworks/HiddifyCore.xcframework"
        ),
        .testTarget(
            name: "HiddifyMtlsSmokeTests",
            dependencies: ["HiddifyCore"],
            path: "Tests/HiddifyMtlsSmokeTests",
            resources: [.copy("Fixtures")],
            linkerSettings: [
                .linkedLibrary("resolv"),
            ]
        ),
    ]
)
