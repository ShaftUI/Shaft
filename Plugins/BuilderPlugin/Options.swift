import PackagePlugin

/// Options for the builder plugin command
struct BuilderOptions {
    var targetName: String

    var configuration: BuilderConfiguration
}

enum BuilderConfiguration: String {
    case debug

    case release
}

func extractOptions(from arguments: [String]) -> BuilderOptions {
    var extractor = ArgumentExtractor(arguments)

    guard let targetName = extractor.remainingArguments.first else {
        printAndExit("Target name not provided")
    }

    let configurationString = extractor.extractOption(named: "--configuration").last ?? "debug"
    guard let configuration = BuilderConfiguration(rawValue: configurationString) else {
        printAndExit("Invalid configuration: \(configurationString)")
    }

    return BuilderOptions(targetName: targetName, configuration: configuration)
}
