import CSkia
import Foundation
import Shaft

public class SkiaFontCollection: FontCollection {
    public init() {
        loadICU()
    }

    internal var collection = sk_fontcollection_new()

    public func makeTypefaceFrom(_ data: Data) -> any Typeface {
        let typeface = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            let data = ptr.bindMemory(to: UInt8.self)
            return sk_typeface_create_from_data(collection, data.baseAddress, data.count)
        }
        return SkiaTypeface(typeface)
    }

    public func findTypeface(_ family: [String], style: FontStyle, weight: FontWeight)
        -> [any Typeface]
    {
        var families = skstring_vector_new()
        for family in family {
            families.push_back(SkString(family))
        }

        let typefaces = sk_fontcollection_find_typefaces(
            self.collection,
            families,
            toSkiaFontStyle(fontStyle: style, fontWeight: weight)
        )

        return typefaces.map { SkiaTypeface($0) }
    }

    public func findTypefaceFor(_ codepoint: UInt32) -> (any Typeface)? {
        let typeface = sk_fontcollection_default_fallback(
            self.collection,
            SkUnichar(codepoint),
            SkFontStyle(),
            SkString()
        )
        if typeface.__convertToBool() == false {
            return nil
        }
        return SkiaTypeface(typeface)
    }
}

public class SkiaTypeface: Typeface {
    init(_ typeface: SkTypeface_sp) {
        self.typeface = typeface
    }

    var typeface: SkTypeface_sp

    public func getGlyphIDs(_ text: String) -> [GlyphID?] {
        let chars = text.unicodeScalars.map { SkUnichar($0.value) }
        let glyphs = sk_typeface_get_glyphs(&self.typeface, chars, chars.count)
        return glyphs.map { $0 == 0 ? nil : $0 }
    }

    public func getGlyphID(_ codePoint: UInt32) -> GlyphID? {
        let id = sk_typeface_get_glyph(&self.typeface, SkUnichar(codePoint))
        return id == 0 ? nil : id
    }

    public var glyphCount: Int {
        return Int(sk_typeface_count_glyphs(&self.typeface))
    }

    public func createFont(_ size: Float) -> any Font {
        let font = sk_font_new(&typeface, size)
        return SkiaFont(font)
    }

    public var familyName: String {
        var skString = SkString()
        sk_typeface_get_family_name(&self.typeface, &skString)
        var cString: UnsafePointer<CChar>?
        skstring_c_str(skString, &cString)
        return String(cString: cString!)
    }
}

extension SkiaTypeface: CustomStringConvertible {
    public var description: String {
        return "SkiaTypeface(\(familyName))"
    }
}

public class SkiaFont: Font {
    init(_ font: SkFont) {
        self.skFont = font
    }

    var skFont: SkFont

    public var size: Float {
        return sk_font_get_size(&skFont)
    }
}

public class SkiaTextBlob: TextBlob {
    public required init(_ glyphs: [GlyphID], positions: [Offset], font: any Font) {
        assert(glyphs.count == positions.count, "The number of glyphs and positions must be equal.")
        let font = font as! SkiaFont
        let glyphs = glyphs.map { SkGlyphID($0) }
        let positions = positions.map { SkPoint(fX: $0.dx, fY: $0.dy) }
        self.skTextBlob = sk_text_blob_make_from_glyphs(
            glyphs,
            positions,
            glyphs.count,
            font.skFont
        )
    }

    var skTextBlob: SkTextBlob_sp
}
