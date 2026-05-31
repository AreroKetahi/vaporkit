// swift-tools-version: 6.3

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "vaporkit",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13),
        .watchOS(.v6), .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "VaporKit",
            targets: ["VaporKit"]
        ),
        .executable(
            name: "VaporKitClient",
            targets: ["VaporKitClient"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            from: "603.0.0-latest"
        ),
        .package(
            url: "https://github.com/vapor/vapor.git",
            from: "4.121.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-macro-testing.git",
            from: "0.6.5"
        ),
    ],
    targets: [
        .macro(
            name: "VaporKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),

        .target(
            name: "VaporKit",
            dependencies: [
                "VaporKitMacros",
                .product(name: "Vapor", package: "vapor"),
            ],
            swiftSettings: [
                .strictMemorySafety()
            ]
        ),

        .executableTarget(
            name: "VaporKitClient",
            dependencies: ["VaporKit"]
        ),

        .testTarget(
            name: "VaporKitTests",
            dependencies: [
                "VaporKit",
                "VaporKitMacros",
                .product(
                    name: "SwiftSyntaxMacrosTestSupport",
                    package: "swift-syntax"
                ),
                .product(name: "MacroTesting", package: "swift-macro-testing"),
            ]
        ),
        
        .testTarget(
            name: "VaporKitIntegrationTests",
            dependencies: [
                "VaporKit",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "VaporTesting", package: "vapor"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
