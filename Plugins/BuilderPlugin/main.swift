import Foundation
import PackagePlugin

@main
struct BuilderPlugin: CommandPlugin {

    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        let options = extractOptions(from: arguments)

        let buildSpec = loadBuildSpec(directory: context.package.directory)
        guard let buildSpec else {
            print("No Build.json found in \(context.package.directory). Skipped.")
            return
        }

        let context = StepContext(
            package: context.package,
            packageManager: self.packageManager,
            configuration: options.configuration
        )

        for step in buildSpec.steps {
            print("Executing step: \(step)")

            switch step {
            case .macOSBundle(let input):
                executeMacOSBundleStep(input, context: context)
            case .copy(let input):
                executeCopyStep(input, context: context)
            case .runCommand(let input):
                executeRunCommandStep(input, context: context)
            }
        }
    }
}

/// Try read the Build.json file in the package directory
func loadBuildSpec(directory: Path) -> BuildSpec? {
    let path = directory.appending(subpath: "Build.json").string

    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
        return nil
    }

    let decoder = JSONDecoder()
    return try! decoder.decode(BuildSpec.self, from: data)
}

struct StepContext {
    let package: Package
    let packageManager: PackageManager
    let configuration: BuilderConfiguration
}

extension StepContext {
    func findProduct(_ productName: String) -> Product? {
        return package.products.first { $0.name == productName }
    }
}
