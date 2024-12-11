import Foundation
import ZIPFoundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

#if arch(arm64)
    let arch = "arm64"
#elseif arch(x86_64)
    var arch = "x64"
#else
    var arch = "x86"
#endif

#if os(Windows)
    var os = "windows"
#elseif os(macOS)
    let os = "macos"
#elseif os(Linux)
    var os = "linux"
#elseif os(Android)
    var os = "android"
#endif

// Version of Skia to download
let version = "m126-6bfb13368b"

// Repository to download Skia from. On Windows, we use ShaftUI's fork, which
// has /MD flags set. On Linux, we use ShaftUI' fork, which removes the
// -D_GLIBCXX_USE_CXX11_ABI=0 flag.
let repo =
    os == "windows" || os == "linux"
    ? "https://github.com/ShaftUI/skia-pack"
    : "https://github.com/JetBrains/skia-pack"

// The first argument is expected to be the absolute path to the package
// directory
let packageDirectory = URL(fileURLWithPath: CommandLine.arguments[1])

// Download Skia pack from GitHub release artifacts
let skiaPackURL = URL(
    string: "\(repo)/releases/download/\(version)/Skia-\(version)-\(os)-Release-\(arch).zip"
)!
print("Downloading \(skiaPackURL)")
let (data, _) = try await URLSession.shared.data(from: skiaPackURL)

// Extract out/Release-<os>-<arch> to .shaft/skia
let zip = try? Archive(data: data, accessMode: .read)
guard let zip else {
    print("Failed to extract Skia pack")
    exit(1)
}
let sourceDirectory = "out/Release-\(os)-\(arch)"
let destinationURL = packageDirectory.appending(path: ".shaft/skia")
for entry in zip {
    if entry.path.hasPrefix(sourceDirectory) {
        let filename: String = entry.path.replacingOccurrences(of: sourceDirectory, with: "")
        let fileDestination = destinationURL.appendingPathComponent(filename)
        print("Extracting \(filename) to \(fileDestination.path)")
        _ = try zip.extract(entry, to: fileDestination)
    }
}
