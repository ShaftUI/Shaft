import PackagePlugin

/// Options for the builder plugin command
struct BuilderOptions {
    // var targetName: String

    var configuration: BuilderConfiguration
    var configFile: String
}

enum BuilderConfiguration: String {
    case debug

    case release
}

func extractOptions(from arguments: [String]) -> BuilderOptions {
    var extractor = ArgumentExtractor(arguments)

    // guard let targetName = extractor.remainingArguments.first else {
    //     printAndExit("Target name not provided")
    // }

    let configurationString = extractor.extractOption(named: "mode").last ?? "release"
    guard let configuration = BuilderConfiguration(rawValue: configurationString) else {
        printAndExit("Invalid configuration: \(configurationString)")
    }

    let configName = extractor.extractOption(named: "config").last
    let configFile =
        if let configName = configName {
            "Build.\(configName).json"
        } else {
            "Build.json"
        }

    return BuilderOptions(
        // targetName: targetName,
        configuration: configuration,
        configFile: configFile
    )
}
