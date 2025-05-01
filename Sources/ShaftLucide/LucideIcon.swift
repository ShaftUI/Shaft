import Foundation
import Shaft

// {
//   "a-arrow-down": {
//     "encodedCode": "\\e58a",
//     "prefix": "icon",
//     "className": "icon-a-arrow-down",
//     "unicode": "&#58762;"
//   },
//...
// }
private typealias IconsData = [String: IconData]

/// A structure representing the metadata for a Lucide icon.
///
/// This structure contains the necessary information to render a Lucide icon,
/// including its encoded code point, prefix, class name, and Unicode
/// representation.
private struct IconData: Codable {
    /// The encoded code point of the icon in the format "\eXXX".
    public let encodedCode: String

    /// The prefix used for the icon, typically "icon".
    public let prefix: String

    /// The CSS class name for the icon, typically in the format "icon-name".
    public let className: String

    /// The Unicode representation of the icon in HTML entity format, e.g., "&#58762;".
    public let unicode: String

    /// Converts the encoded code point to a Unicode scalar.
    ///
    /// This method parses the hexadecimal code point from the `encodedCode` property
    /// and returns the corresponding Unicode scalar.
    ///
    /// - Returns: The Unicode scalar representation of the icon.
    public func getCharacter() -> UnicodeScalar {
        // Parse the unicode value which is in the format "&#XXXXX;"
        let unicodeString = unicode.dropFirst(2).dropLast(1)  // Remove "&#" and ";"
        let codePoint = Int(unicodeString, radix: 10)!
        return UnicodeScalar(codePoint)!
    }
}

/// The loaded icon data from the Lucide JSON resource file.
/// This is lazily initialized when first accessed.
private var iconData: IconsData = loadIcons()

/// Loads and parses icon data from a JSON byte array.
private func loadIcons() -> IconsData {
    let fontData = Data(PackageResources.lucide_woff2)
    let typeface = backend.renderer.fontCollection.makeTypefaceFrom(fontData)
    mark(typeface.familyName)
    mark(typeface.glyphCount)

    backend.renderer.fontCollection.registerTypeface(typeface)
    mark(backend.renderer.fontCollection.findTypeface(["lucide"], style: .normal, weight: .normal))

    let jsonData = Data(PackageResources.lucide_json)
    let decoder = JSONDecoder()
    return try! decoder.decode(IconsData.self, from: jsonData)
}

/// Retrieves the metadata for a specific icon by name.
private func getIconData(name: String) -> IconData? {
    return iconData[name]
}

/// A widget that displays a Lucide icon.
///
/// Example usage:
/// ```swift
/// LucideIcon("heart", size: 24.0, color: .red)
/// ```
///
/// You can find all available icon names using the `LucideIcon.allIcons`
/// property.
public class LucideIcon: StatelessWidget {
    /// A sorted list of all available icon names.
    public static let allIcons: [String] = iconData.keys.sorted()

    /// Creates a new Lucide icon widget.
    public init(_ name: String, size: Float = 14.0, weight: Float? = nil, color: Color? = nil) {
        self.name = name
        self.size = size
        self.weight = weight
        self.color = color
    }

    /// The name of the icon to display.
    public let name: String

    /// The size of the icon in logical pixels.
    public let size: Float?

    /// The weight of the icon. Currently not used.
    public let weight: Float?

    /// The color to apply to the icon. If nil, the current text color will be used.
    public let color: Color?

    public func build(context: BuildContext) -> Widget {
        guard let iconData = getIconData(name: name) else {
            return Text("Icon '\(name)' not found")
        }

        let effectiveColor = color ?? DefaultTextStyle.of(context).style.color

        let textStyle = TextStyle(
            color: effectiveColor,
            fontFamily: "lucide",
            fontSize: size,
        )

        var result: Widget = RichText(
            text: TextSpan(
                text: String(iconData.getCharacter()),
                style: textStyle
            ),
            textDirection: .ltr,
            overflow: .visible
        )

        if let size {
            result = SizedBox(
                width: size,
                height: size
            ) {
                result
            }
        }

        return result
    }
}
