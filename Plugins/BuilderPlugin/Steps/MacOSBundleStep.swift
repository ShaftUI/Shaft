import Foundation
import PackagePlugin

struct MacOSBundleInput: Codable {
    let name: String
    let identifier: String
    let version: String
    let product: String
    let output: String
    let additionalInfoPlistEntries: [String: String]?
}

func executeMacOSBundleStep(_ input: MacOSBundleInput, context: StepContext) {
    // Ensure the product exists in the package
    guard let product = context.findProduct(input.product) else {
        print("Product \(input.product) not found. Valid products are:")
        for product in context.package.products {
            print("  - \(product.name)")
        }
        exit(1)
    }

    print("Building \(product.name) in \(context.configuration.rawValue) mode")

    var buildParameters = PackageManager.BuildParameters(echoLogs: true)
    buildParameters.otherLinkerFlags = ["-L.shaft/skia"]

    let buildResult = try! context.packageManager.build(
        .product(input.product),
        parameters: buildParameters
    )

    if !buildResult.succeeded {
        print("Build failed. See logs above for details.")
        exit(1)
    }

    guard let mainArtifect = buildResult.builtArtifacts.first else {
        print("No built artifacts found. Cannot create bundle.")
        exit(1)
    }
    print("Main artifact: \(mainArtifect.path.string)")

    if mainArtifect.kind != .executable {
        print("Main artifact is \(mainArtifect.kind). Cannot create bundle.")
        exit(1)
    }

    print("Creating bundle with input: \(input)")
    createBundle(from: mainArtifect, input: input, configuration: context.configuration)
}

private func createBundle(
    from artifect: PackageManager.BuildResult.BuiltArtifact,
    input: MacOSBundleInput,
    configuration: BuilderConfiguration
) {
    let outputDirectory = URL(fileURLWithPath: input.output)

    print("Creating bundle at \(outputDirectory)")

    let structure = AppleBundleStructure(
        at: outputDirectory,
        platform: .macOS,
        appName: input.name
    )

    try! structure.ensureDirectoriesExist()

    /// Copy the main executable
    copyFile(from: artifect.path.string, to: structure.mainExecutable.path)

    /// Copy .dSYM file in debug mode
    if configuration == .debug {
        copyFile(from: artifect.path.string + ".dSYM", to: structure.mainExecutableDSYM.path)
    }

    // Create the Info.plist dictionary
    var infoPlistDict: [String: Any] = [
        "CFBundleExecutable": input.product,
        "CFBundleIdentifier": input.identifier,
        "CFBundleName": input.name,
        "CFBundleVersion": input.version,
    ]

    // Merge additional entries
    if let additionalEntries = input.additionalInfoPlistEntries {
        infoPlistDict.merge(additionalEntries) { _, new in new }  // Keep the new value in case of key collision
    }

    // Serialize the dictionary to XML data
    do {
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: infoPlistDict,
            format: .xml,
            options: 0
        )
        // Write the data to the Info.plist file
        try plistData.write(to: structure.infoPlistFile)
    } catch {
        print("Error serializing or writing Info.plist: \(error)")
        // Decide how to handle the error, e.g., exit(1)
        exit(1)
    }

    print("Bundle created at \(outputDirectory)")
}

private func copyFile(from source: String, to destination: String) {
    if FileManager.default.fileExists(atPath: destination) {
        print("Removing existing file at \(destination)")
        try! FileManager.default.removeItem(atPath: destination)
    }
    print("Copying \(source) to \(destination)")
    try! FileManager.default.copyItem(atPath: source, toPath: destination)
}
