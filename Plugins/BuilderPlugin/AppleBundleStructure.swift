import Foundation

/// foo.app/
///     Contents/
///         Info.plist
///         MacOS/
///             foo
///         Resources/
///             foo.icns
///         Libraries/
///             libfoo.dylib
///         Frameworks/
///             Foo.framework
struct AppleBundleStructure {
    let contentsDirectory: URL
    let resourcesDirectory: URL
    let librariesDirectory: URL
    let frameworksDirectory: URL
    let executableDirectory: URL
    let infoPlistFile: URL
    let appIconFile: URL
    let mainExecutable: URL
    let mainExecutableDSYM: URL

    init(at bundleDirectory: URL, platform: ApplePlatform, appName: String) {
        switch platform {
        case .macOS:
            contentsDirectory = bundleDirectory.appendingPathComponent("Contents")
            executableDirectory = contentsDirectory.appendingPathComponent("MacOS")
            resourcesDirectory = contentsDirectory.appendingPathComponent("Resources")
            frameworksDirectory = contentsDirectory.appendingPathComponent("Frameworks")
        case .iOS, .tvOS, .visionOS, .watchOS:
            contentsDirectory = bundleDirectory
            executableDirectory = contentsDirectory
            resourcesDirectory = contentsDirectory
            frameworksDirectory = contentsDirectory
        }

        librariesDirectory = contentsDirectory.appendingPathComponent("Libraries")
        infoPlistFile = contentsDirectory.appendingPathComponent("Info.plist")
        appIconFile = resourcesDirectory.appendingPathComponent("AppIcon.icns")

        mainExecutable = executableDirectory.appendingPathComponent(appName)
        mainExecutableDSYM = mainExecutable.appendingPathExtension("dSYM")
    }

    func ensureDirectoriesExist() throws {
        for directory in [
            contentsDirectory,
            executableDirectory,
            resourcesDirectory,
            librariesDirectory,
            frameworksDirectory,
        ] {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
