import Foundation

func printAndExit(_ message: String, _ exitCode: Int32 = 1) -> Never {
    print(message)
    exit(exitCode)
}
