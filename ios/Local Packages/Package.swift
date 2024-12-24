// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
     name: "Hiddify Packages",
     platforms: [
        // Minimum platform version
         .iOS(.v13)
     ],
     products: [
         .library(
             name: "HiddifyCore",
             targets: ["HiddifyCore"]),
     ],
     dependencies: [
         // No dependencies
     ],
     targets: [
        .binaryTarget(
            name: "HiddifyCore",
            path: "../Frameworks/HiddifyCore.xcframework"
        )
     ]
 )
