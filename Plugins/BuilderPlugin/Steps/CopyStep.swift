import Foundation
import PackagePlugin

struct CopyInput: Codable {
    /// The source path of the item to copy.
    let source: String
    /// The destination path to copy the item to.
    let destination: String
}

func executeCopyStep(_ input: CopyInput, context: StepContext) {
    print("Starting copy step: \(input.source) -> \(input.destination)")

    let sourcePath = input.source
    let destinationPath = input.destination

    // Ensure the source exists
    guard FileManager.default.fileExists(atPath: sourcePath) else {
        print("Source item not found at \(sourcePath). Cannot copy.")
        exit(1)
    }

    // Ensure the destination directory exists
    let destinationURL = URL(fileURLWithPath: destinationPath)
    let destinationDirectoryURL = destinationURL.deletingLastPathComponent()
    do {
        try FileManager.default.createDirectory(
            at: destinationDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        print("Ensured destination directory exists at \(destinationDirectoryURL.path)")
    } catch {
        print("Failed to create destination directory \(destinationDirectoryURL.path): \(error)")
        exit(1)
    }

    print("Copying item from \(sourcePath) to \(destinationPath)")
    copyFile(from: sourcePath, to: destinationPath)

    // /* MODIFIED: Removed dSYM copying logic as the build step is removed.
    //    If dSYM needs to be copied, it should be specified as a separate copy step. */

    print("Copy step completed for \(sourcePath).")
}

private func copyFile(from source: String, to destination: String) {
    let sourceURL = URL(fileURLWithPath: source)
    let destinationURL = URL(fileURLWithPath: destination)

    // Check if source is a directory (like .dSYM)
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: source, isDirectory: &isDir), isDir.boolValue {
        print("Source \(source) is a directory.")
        // If destination exists, remove it first whether it's a file or directory
        if FileManager.default.fileExists(atPath: destination) {
            print("Removing existing item at destination \(destination)")
            do {
                try FileManager.default.removeItem(at: destinationURL)
            } catch {
                print("Failed to remove existing item at \(destination): \(error)")
                // Decide if this is fatal or not, for now we exit
                exit(1)
            }
        }
        print("Copying directory from \(source) to \(destination)")
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            print("Error copying directory \(source) to \(destination): \(error)")
            exit(1)
        }
    } else {
        // Source is a file
        if FileManager.default.fileExists(atPath: destination) {
            print("Removing existing file at destination \(destination)")
            do {
                try FileManager.default.removeItem(at: destinationURL)
            } catch {
                print("Failed to remove existing file at \(destination): \(error)")
                // Decide if this is fatal or not, for now we exit
                exit(1)
            }
        }
        print("Copying file from \(source) to \(destination)")
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            print("Error copying file \(source) to \(destination): \(error)")
            exit(1)
        }
    }
}
