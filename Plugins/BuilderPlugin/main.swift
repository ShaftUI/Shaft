import Foundation
import PackagePlugin

@main
struct BuilderPlugin: CommandPlugin {

    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        let options = extractOptions(from: arguments)
        let targetName = options.targetName

        // Ensure the product exists in the package
        guard let target = findTarget(targetName, in: context.package) else {
            print("Target \(targetName) not found. Valid targets are:")
            for target in context.package.targets {
                print("  - \(target.name)")
            }
            return
        }

        print("Building \(target.name) in \(options.configuration.rawValue) mode")

        var buildParameters = PackagePlugin.PackageManager.BuildParameters(echoLogs: true)
        buildParameters.otherLinkerFlags = ["-L.shaft/skia"]

        let buildResult = try self.packageManager.build(
            .target(targetName),
            parameters: buildParameters
        )

        if !buildResult.succeeded {
            print("Build failed. See logs above for details.")
            return
        }

        guard let mainArtifect = buildResult.builtArtifacts.first else {
            print("No built artifacts found. Skipping bundle creation.")
            return
        }

        if mainArtifect.kind != .executable {
            print("Main artifact is \(mainArtifect.kind). Skipping bundle creation.")
            return
        }

        let buildSpec = findBuildSpec(in: target)
        guard let appSpec = buildSpec?.app else {
            print("No app spec found for \(target.name). Skipping bundle creation.")
            return
        }

        print("Creating bundle with app spec: \(appSpec)")
        createBundle(from: mainArtifect, appSpec: appSpec)
    }
}

/// Find a target with the given name in the package
func findTarget(_ targetName: String, in package: Package) -> Target? {
    return package.targets.first { $0.name == targetName }
}

/// Try read the Build.json file in the target directory
func findBuildSpec(in target: Target) -> BuildSpec? {
    let path = target.directory.appending(subpath: "Build.json").string

    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
        return nil
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(BuildSpec.self, from: data)
    } catch {
        print("Error decoding BuildSpec: \(error)")
        return nil
    }
}

func createBundle(from artifect: PackageManager.BuildResult.BuiltArtifact, appSpec: AppSpec) {
    let outputDirectory = URL(fileURLWithPath: artifect.path.string)
        .deletingLastPathComponent()
        .appendingPathComponent("\(appSpec.product).app")

    print("Creating bundle at \(outputDirectory)")

    let structure = AppleBundleStructure(
        at: outputDirectory,
        platform: .macOS,
        appName: appSpec.product
    )

    try! structure.ensureDirectoriesExist()

    // Copy the main executable to the bundle
    if FileManager.default.fileExists(atPath: structure.mainExecutable.path) {
        print("Removing existing executable at \(structure.mainExecutable.path)")
        try! FileManager.default.removeItem(at: structure.mainExecutable)
    }
    try! FileManager.default.copyItem(
        at: URL(fileURLWithPath: artifect.path.string),
        to: structure.mainExecutable
    )

    // Write the Info.plist
    let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleExecutable</key>
            <string>\(appSpec.product)</string>
            <key>CFBundleIdentifier</key>
            <string>\(appSpec.identifier)</string>
            <key>CFBundleName</key>
            <string>\(appSpec.name)</string>
            <key>CFBundleVersion</key>
            <string>\(appSpec.version)</string>
        </dict>
        </plist>
        """

    try! infoPlist.write(to: structure.infoPlistFile, atomically: true, encoding: .utf8)

    print("Bundle created at \(outputDirectory)")
}
