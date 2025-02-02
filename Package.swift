// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "Shaft",

    platforms: [
        .macOS(.v14),
        .iOS(.v13),
        .tvOS(.v13),
    ],

    products: [
        .executable(name: "Playground", targets: ["Playground"]),
        .library(name: "Shaft", targets: ["Shaft"]),
        .plugin(name: "CSkiaSetupPlugin", targets: ["CSkiaSetupPlugin"]),
        .plugin(name: "BuilderPlugin", targets: ["BuilderPlugin"]),
    ],

    dependencies: [
        .package(
            url: "https://github.com/ShaftUI/SwiftMath",
            .upToNextMajor(from: "3.3.2")
        ),
        .package(
            url: "https://github.com/ShaftUI/SwiftSDL3",
            // .upToNextMinor(from: "0.0.4")
            branch: "main"
        ),
        .package(
            url: "https://github.com/onevcat/Rainbow",
            .upToNextMajor(from: "4.0.0")
        ),
        .package(
            url: "https://github.com/apple/swift-collections",
            // .upToNextMinor(from: "1.1.0")
            branch: "main"
        ),
        .package(
            url: "https://github.com/gregcotten/ZIPFoundationModern",
            .upToNextMajor(from: "0.0.1")
        ),
        .package(
            url: "https://github.com/ShaftUI/Splash",
            branch: "master"
        ),
    ],

    targets: [
        .executableTarget(
            name: "Playground",
            dependencies: [
                "CSkia",
                "SwiftMath",
                "Shaft",
                "ShaftCodeHighlight",
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),

        .target(
            name: "CSkia",
            sources: [
                "utils.cpp"
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .define("SK_FONTMGR_FONTCONFIG_AVAILABLE", .when(platforms: [.linux]))
            ],
            linkerSettings: [
                .linkedLibrary("d3d12", .when(platforms: [.windows])),
                .linkedLibrary("d3dcompiler", .when(platforms: [.windows])),
                .linkedLibrary("openGL32", .when(platforms: [.windows])),
                .linkedLibrary("stdc++", .when(platforms: [.windows])),
                .linkedLibrary("dxgi", .when(platforms: [.windows])),

                .linkedFramework("CoreGraphics", .when(platforms: [.macOS])),
                .linkedFramework("CoreText", .when(platforms: [.macOS])),
                .linkedFramework("CoreFoundation", .when(platforms: [.macOS])),
                .linkedFramework("Metal", .when(platforms: [.macOS])),

                .linkedLibrary("fontconfig", .when(platforms: [.linux])),
                .linkedLibrary("freetype", .when(platforms: [.linux])),
                .linkedLibrary("GL", .when(platforms: [.linux])),
                .linkedLibrary("GLX", .when(platforms: [.linux])),
                .linkedLibrary("wayland-client", .when(platforms: [.linux])),

                .unsafeFlags(["-L.shaft/skia"]),
            ]
        ),

        .target(
            name: "CSkiaResource",
            resources: [
                .copy("icudtl.dat")
            ]
        ),

        .plugin(
            name: "CSkiaSetupPlugin",
            capability: .command(
                intent: .custom(verb: "setup-skia", description: "Download prebuilt Skia binaries"),
                permissions: [
                    .allowNetworkConnections(
                        scope: .all(),
                        reason: "To download the Skia binaries"
                    ),
                    .writeToPackageDirectory(reason: "To extract the Skia binaries"),
                ]
            ),
            dependencies: [
                "CSkiaSetup"
            ]
        ),

        .plugin(
            name: "BuilderPlugin",
            capability: .command(
                intent: .custom(verb: "build", description: "Build application bundle"),
                permissions: [
                    .allowNetworkConnections(
                        scope: .all(),
                        reason: "To retrieve additional resources"
                    ),
                    .writeToPackageDirectory(reason: "To read configuration files"),
                ]
            )
        ),

        .executableTarget(
            name: "CSkiaSetup",
            dependencies: [
                .product(name: "ZIPFoundation", package: "zipfoundationmodern")
            ]
        ),

        .target(
            name: "Shaft",
            dependencies: [
                "SwiftMath",
                "CSkia",
                "CSkiaResource",
                "Rainbow",
                "SwiftSDL3",
                .product(name: "Collections", package: "swift-collections"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        .target(
            name: "ShaftCodeHighlight",
            dependencies: [
                "Splash",
                "Shaft",
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        .testTarget(
            name: "ShaftTests",
            dependencies: ["Shaft"],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
    ],
    cxxLanguageStandard: .cxx17
)
