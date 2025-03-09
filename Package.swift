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
        // Shaft playground app
        .executable(name: "Playground", targets: ["Playground"]),

        // The Shaft framework, is platform-independent and requires a backend
        // to run.
        .library(name: "Shaft", targets: ["Shaft"]),

        // The helper library for setting up the default backend and renderer.
        .library(name: "ShaftSetup", targets: ["ShaftSetup"]),

        // Code highlighting library for Shaft
        .library(name: "ShaftCodeHighlight", targets: ["ShaftCodeHighlight"]),

        // The SDL3 backend for Shaft
        .library(name: "ShaftSDL3", targets: ["ShaftSDL3"]),

        // The Skia renderer for Shaft
        .library(name: "ShaftSkia", targets: ["ShaftSkia"]),

        // Companion tool for downloading Skia binaries. Will be removed in the
        // future when BuilderPlugin is more mature.
        .plugin(name: "CSkiaSetupPlugin", targets: ["CSkiaSetupPlugin"]),

        // (experimental) Tool to build application bundles
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
            url: "https://github.com/ShaftUI/swift-collections",
            .upToNextMinor(from: "1.3.0")
        ),
        .package(
            url: "https://github.com/gregcotten/ZIPFoundationModern",
            .upToNextMajor(from: "0.0.1")
        ),
        .package(
            url: "https://github.com/ShaftUI/Splash",
            branch: "master"
        ),
        .package(url: "https://github.com/ShaftUI/SwiftReload.git", branch: "main"),

    ],

    targets: [
        .executableTarget(
            name: "Playground",
            dependencies: [
                "CSkia",
                "SwiftMath",
                "Shaft",
                "ShaftSetup",
                "ShaftCodeHighlight",
                "SwiftReload",
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .unsafeFlags(["-Xfrontend", "-enable-private-imports"]),
                .unsafeFlags(["-Xfrontend", "-enable-implicit-dynamic"]),
            ],
            linkerSettings: [
                .unsafeFlags(
                    ["-Xlinker", "--export-dynamic"],
                    .when(platforms: [.linux, .android])
                )
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
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-enable-private-imports"]),
                .unsafeFlags(["-Xfrontend", "-enable-implicit-dynamic"]),
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
                "Rainbow",
                "SwiftSDL3",
                .product(name: "Collections", package: "swift-collections"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        .target(
            name: "ShaftSetup",
            dependencies: [
                "Shaft",
                .target(
                    name: "ShaftSkia",
                    condition: .when(platforms: [.linux, .windows, .macOS])
                ),
                .target(
                    name: "ShaftSDL3",
                    condition: .when(platforms: [.linux, .windows, .macOS])
                ),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        .target(
            name: "ShaftSDL3",
            dependencies: [
                "SwiftSDL3",
                "SwiftMath",
                "Shaft",
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),

        .target(
            name: "ShaftSkia",
            dependencies: [
                "CSkia",
                "CSkiaResource",
                "SwiftMath",
                "Shaft",
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
