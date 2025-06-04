import Foundation
import PackagePlugin

struct RunCommandInput: Codable {
    /// The command to run
    let command: String
    /// Optional arguments for the command
    let arguments: [String]?
    /// Optional working directory (defaults to package directory)
    let workingDirectory: String?
    /// Optional environment variables to set
    let environment: [String: String]?
    /// Whether to continue on failure (defaults to false)
    let continueOnFailure: Bool?
}

func executeRunCommandStep(_ input: RunCommandInput, context: StepContext) {
    print("Starting run command step: \(input.command)")

    let workingDir = input.workingDirectory ?? context.package.directory.string
    let args = input.arguments ?? []
    let continueOnFailure = input.continueOnFailure ?? false

    print("Running: \(input.command) \(args.joined(separator: " "))")
    print("Working directory: \(workingDir)")

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [input.command] + args
    process.currentDirectoryURL = URL(fileURLWithPath: workingDir)

    // Set up environment
    var processEnvironment = ProcessInfo.processInfo.environment
    if let environment = input.environment {
        for (key, value) in environment {
            processEnvironment[key] = value
        }
    }
    process.environment = processEnvironment

    // Capture output
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    do {
        try process.run()
        process.waitUntilExit()

        // Read output
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
            print("Output:")
            print(output)
        }

        if let error = String(data: errorData, encoding: .utf8), !error.isEmpty {
            print("Error output:")
            print(error)
        }

        if process.terminationStatus != 0 {
            print("Command failed with exit code: \(process.terminationStatus)")
            if !continueOnFailure {
                exit(Int32(process.terminationStatus))
            }
        } else {
            print("Command completed successfully")
        }

    } catch {
        print("Failed to run command: \(error)")
        if !continueOnFailure {
            exit(1)
        }
    }
}
