import Foundation
import PackagePlugin

@main
struct CSkiaSetupPlugin: CommandPlugin {

    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        print("Setting up Skia")

        let tool = try context.tool(named: "CSkiaSetup")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool.path.string)
        process.arguments = [context.package.directory.string]

        // let the process inherit stdout and stderr
        // process.standardOutput = FileHandle.standardOutput
        // process.standardError = FileHandle.standardError

        try process.run()
    }
}
