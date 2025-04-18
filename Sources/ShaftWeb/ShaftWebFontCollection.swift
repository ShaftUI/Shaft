import Foundation
import Shaft

public class ShaftWebFontCollection: Shaft.FontCollection {
    static let shared = ShaftWebFontCollection()

    public func makeTypefaceFrom(_ data: Data) -> any Typeface {
        shouldImplement()
    }

    public func findTypeface(_ family: [String], style: FontStyle, weight: FontWeight)
        -> [any Typeface]
    {
        shouldImplement()
    }

    public func findTypefaceFor(_ codepoint: UInt32) -> (any Typeface)? {
        nil
    }

}
