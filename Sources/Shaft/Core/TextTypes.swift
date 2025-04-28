// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// The measurements of a character (or a sequence of visually connected
/// characters) within a paragraph.
public struct GlyphInfo {
    /// Creates a [GlyphInfo] with the specified values.
    public init(
        graphemeClusterLayoutBounds: Rect,
        graphemeClusterCodeUnitRange: TextRange,
        writingDirection: TextDirection
    ) {
        self.graphemeClusterLayoutBounds = graphemeClusterLayoutBounds
        self.graphemeClusterCodeUnitRange = graphemeClusterCodeUnitRange
        self.writingDirection = writingDirection
    }

    public init(
        left: Float,
        top: Float,
        right: Float,
        bottom: Float,
        graphemeStart: TextIndex,
        graphemeEnd: TextIndex,
        isLTR: Bool
    ) {
        self.graphemeClusterLayoutBounds = Rect(
            left: left,
            top: top,
            right: right,
            bottom: bottom
        )
        self.graphemeClusterCodeUnitRange = TextRange(start: graphemeStart, end: graphemeEnd)
        self.writingDirection = isLTR ? .ltr : .rtl
    }

    /// The layout bounding rect of the associated character, in the paragraph's
    /// coordinates.
    ///
    /// This is **not** a tight bounding box that encloses the character's outline.
    /// The vertical extent reported is derived from the font metrics (instead of
    /// glyph metrics), and the horizontal extent is the horizontal advance of the
    /// character.
    public let graphemeClusterLayoutBounds: Rect

    /// The UTF-16 range of the associated character in the text.
    public let graphemeClusterCodeUnitRange: TextRange

    /// The writing direction within the [GlyphInfo].
    public let writingDirection: TextDirection
}

/// Whether to use the italic type variation of glyphs in the font.
///
/// Some modern fonts allow this to be selected in a more fine-grained manner.
/// See [FontVariation.italic] for details.
///
/// Italic type is distinct from slanted glyphs. To control the slant of a
/// glyph, consider the [FontVariation.slant] font feature.
public enum FontStyle {
    /// Use the upright ("Roman") glyphs.
    case normal

    /// Use glyphs that have a more pronounced angle and typically a cursive style
    /// ("italic type").
    case italic
}

/// The thickness of the glyphs used to draw the text.
///
/// Fonts are typically weighted on a 9-point scale, which, for historical
/// reasons, uses the names 100 to 900. In Flutter, these are named `w100` to
/// `w900` and have the following conventional meanings:
///
///  * [w100]: Thin, the thinnest font weight.
///
///  * [w200]: Extra light.
///
///  * [w300]: Light.
///
///  * [w400]: Normal. The constant [FontWeight.normal] is an alias for this value.
///
///  * [w500]: Medium.
///
///  * [w600]: Semi-bold.
///
///  * [w700]: Bold. The constant [FontWeight.bold] is an alias for this value.
///
///  * [w800]: Extra-bold.
///
///  * [w900]: Black, the thickest font weight.
///
/// For example, the font named "Roboto Medium" is typically exposed as a font
/// with the name "Roboto" and the weight [FontWeight.w500].
///
/// Some modern fonts allow the weight to be adjusted in arbitrary increments.
/// See [FontVariation.weight] for details.
public struct FontWeight: Equatable {
    private init(_ index: Int, _ value: Int) {
        self.index = index
        self.value = value
    }

    /// The encoded integer value of this font weight.
    public let index: Int

    /// The thickness value of this font weight.
    public let value: Int

    /// Thin, the least thick.
    public static let w100 = Self(0, 100)

    /// Extra-light.
    public static let w200 = Self(1, 200)

    /// Light.
    public static let w300 = Self(2, 300)

    /// Normal / regular / plain.
    public static let w400 = Self(3, 400)

    /// Medium.
    public static let w500 = Self(4, 500)

    /// Semi-bold.
    public static let w600 = Self(5, 600)

    /// Bold.
    public static let w700 = Self(6, 700)

    /// Extra-bold.
    public static let w800 = Self(7, 800)

    /// Black, the most thick.
    public static let w900 = Self(8, 900)

    /// The default font weight.
    public static let normal = w400

    /// A commonly used font weight that is heavier than normal.
    public static let bold = w700

    /// Linearly interpolates between two font weights.
    ///
    /// Rather than using fractional weights, the interpolation rounds to the
    /// nearest weight.
    ///
    /// For a smoother animation of font weight, consider using
    /// [FontVariation.weight] if the font in question supports it.
    ///
    /// If both `a` and `b` are null, then this method will return null. Otherwise,
    /// any null values for `a` or `b` are interpreted as equivalent to [normal]
    /// (also known as [w400]).
    ///
    /// The `t` argument represents position on the timeline, with 0.0 meaning
    /// that the interpolation has not started, returning `a` (or something
    /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
    /// returning `b` (or something equivalent to `b`), and values in between
    /// meaning that the interpolation is at the relevant point on the timeline
    /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
    /// 1.0, so negative values and values greater than 1.0 are valid (and can
    /// easily be generated by curves such as [Curves.elasticInOut]). The result
    /// is clamped to the range [w100]–[w900].
    ///
    /// Values for `t` are usually obtained from an [Animation<double>], such as
    /// an [AnimationController].
    // static func lerp(_ a: FontWeight?, b: FontWeight?, t: Float) -> FontWeight? {
    //     if a == nil && b == nil {
    //         return nil
    //     }
    //     return values[_lerpInt((a ?? normal).index, (b ?? normal).index, t).round().clamp(0, 8)]
    // }

}

extension FontWeight: CustomStringConvertible {
    public var description: String {
        return "FontWeight.\(value)"
    }
}

// MARK: - Text

/// An opaque object that determines the size, position, and rendering of text.
///
/// Corresponds to `TextStyle` in Skia.
public class SpanStyle {
    public init(
        color: Color? = nil,
        decoration: TextDecoration? = nil,
        decorationColor: Color? = nil,
        decorationStyle: TextDecorationStyle? = nil,
        decorationThickness: Float? = nil,
        fontWeight: FontWeight? = nil,
        fontStyle: FontStyle? = nil,
        textBaseline: TextBaseline? = nil,
        fontFamilies: [String]? = nil,
        fontSize: Float? = nil,
        letterSpacing: Float? = nil,
        wordSpacing: Float? = nil,
        height: Float? = nil,
        leadingDistribution: TextLeadingDistribution? = nil,
        background: Paint? = nil,
        foreground: Paint? = nil,
        shadows: [Shadow]? = nil
    ) {
        self.color = color
        self.decoration = decoration
        self.decorationColor = decorationColor
        self.decorationStyle = decorationStyle
        self.decorationThickness = decorationThickness
        self.fontWeight = fontWeight
        self.fontStyle = fontStyle
        self.textBaseline = textBaseline
        self.fontFamilies = fontFamilies
        self.fontSize = fontSize
        self.letterSpacing = letterSpacing
        self.wordSpacing = wordSpacing
        self.height = height
        self.leadingDistribution = leadingDistribution
        self.background = background
        self.foreground = foreground
        self.shadows = shadows
    }

    public var color: Color?
    public var decoration: TextDecoration?
    public var decorationColor: Color?
    public var decorationStyle: TextDecorationStyle?
    public var decorationThickness: Float?
    public var fontWeight: FontWeight?
    public var fontStyle: FontStyle?
    public var textBaseline: TextBaseline?
    public var fontFamilies: [String]?
    public var fontSize: Float?
    public var letterSpacing: Float?
    public var wordSpacing: Float?
    public var height: Float?
    public var leadingDistribution: TextLeadingDistribution?
    // public var locale: Locale?
    public var background: Paint?
    public var foreground: Paint?
    public var shadows: [Shadow]?
    // public var fontFeatures: [FontFeature]?
    // public var fontVariations: [FontVariation]?
}

/// A way to disambiguate a [TextPosition] when its offset could match two
/// different locations in the rendered string.
///
/// For example, at an offset where the rendered text wraps, there are two
/// visual positions that the offset could represent: one prior to the line
/// break (at the end of the first line) and one after the line break (at the
/// start of the second line). A text affinity disambiguates between these two
/// cases.
///
/// This affects only line breaks caused by wrapping, not explicit newline
/// characters. For newline characters, the position is fully specified by the
/// offset alone, and there is no ambiguity.
///
/// [TextAffinity] also affects bidirectional text at the interface between LTR
/// and RTL text. Consider the following string, where the lowercase letters
/// will be displayed as LTR and the uppercase letters RTL: "helloHELLO".  When
/// rendered, the string would appear visually as "helloOLLEH".  An offset of 5
/// would be ambiguous without a corresponding [TextAffinity].  Looking at the
/// string in code, the offset represents the position just after the "o" and
/// just before the "H".  When rendered, this offset could be either in the
/// middle of the string to the right of the "o" or at the end of the string to
/// the right of the "H".
public enum TextAffinity {
    /// The position has affinity for the upstream side of the text position, i.e.
    /// in the direction of the beginning of the string.
    ///
    /// In the example of an offset at the place where text is wrapping, upstream
    /// indicates the end of the first line.
    ///
    /// In the bidirectional text example "helloHELLO", an offset of 5 with
    /// [TextAffinity] upstream would appear in the middle of the rendered text,
    /// just to the right of the "o". See the definition of [TextAffinity] for the
    /// full example.
    case upstream

    /// The position has affinity for the downstream side of the text position,
    /// i.e. in the direction of the end of the string.
    ///
    /// In the example of an offset at the place where text is wrapping,
    /// downstream indicates the beginning of the second line.
    ///
    /// In the bidirectional text example "helloHELLO", an offset of 5 with
    /// [TextAffinity] downstream would appear at the end of the rendered text,
    /// just to the right of the "H". See the definition of [TextAffinity] for the
    /// full example.
    case downstream
}

/// Whether and how to align text horizontally.
// The order of this enum must match the order of the values in RenderStyleConstants.h's ETextAlign.
public enum TextAlign {
    /// Align the text on the left edge of the container.
    case left

    /// Align the text on the right edge of the container.
    case right

    /// Align the text in the center of the container.
    case center

    /// Stretch lines of text that end with a soft line break to fill the width of
    /// the container.
    ///
    /// Lines that end with hard line breaks are aligned towards the [start] edge.
    case justify

    /// Align the text on the leading edge of the container.
    ///
    /// For left-to-right text ([TextDirection.ltr]), this is the left edge.
    ///
    /// For right-to-left text ([TextDirection.rtl]), this is the right edge.
    case start

    /// Align the text on the trailing edge of the container.
    ///
    /// For left-to-right text ([TextDirection.ltr]), this is the right edge.
    ///
    /// For right-to-left text ([TextDirection.rtl]), this is the left edge.
    case end
}

/// A horizontal line used for aligning text.
public enum TextBaseline {
    /// The horizontal line used to align the bottom of glyphs for alphabetic characters.
    case alphabetic

    /// The horizontal line used to align ideographic characters.
    case ideographic
}

/// A linear decoration to draw near the text.
public struct TextDecoration: OptionSet {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public var rawValue: Int

    /// Do not draw a decoration
    public static let none = Self([])

    /// Draw a line underneath each line of text
    public static let underline = Self(rawValue: 0x1)

    /// Draw a line above each line of text
    public static let overline = Self(rawValue: 0x2)

    /// Draw a line through each line of text
    public static let lineThrough = Self(rawValue: 0x4)
}

/// The style in which to draw a text decoration
public enum TextDecorationStyle {
    /// Draw a solid line
    case solid

    /// Draw two lines
    case double

    /// Draw a dotted line
    case dotted

    /// Draw a dashed line
    case dashed

    /// Draw a sinusoidal line
    case wavy
}

/// A direction in which text flows.
///
/// Some languages are written from the left to the right (for example, English,
/// Tamil, or Chinese), while others are written from the right to the left (for
/// example Aramaic, Hebrew, or Urdu). Some are also written in a mixture, for
/// example Arabic is mostly written right-to-left, with numerals written
/// left-to-right.
///
/// The text direction must be provided to APIs that render text or lay out
/// boxes horizontally, so that they can determine which direction to start in:
/// either right-to-left, [TextDirection.rtl]; or left-to-right,
/// [TextDirection.ltr].
public enum TextDirection {
    /// The text flows from right to left (e.g. Arabic, Hebrew).
    case rtl

    /// The text flows from left to right (e.g., English, French).
    case ltr
}

/// Defines how to apply [TextStyle.height] over and under text.
///
/// [TextHeightBehavior.applyHeightToFirstAscent] and
/// [TextHeightBehavior.applyHeightToLastDescent] represent whether the
/// [TextStyle.height] modifier will be applied to the corresponding metric. By
/// default both properties are true, and [TextStyle.height] is applied as
/// normal. When set to false, the font's default ascent will be used.
///
/// [TextHeightBehavior.leadingDistribution] determines how the
/// leading is distributed over and under text. This
/// property applies before [TextHeightBehavior.applyHeightToFirstAscent] and
/// [TextHeightBehavior.applyHeightToLastDescent].
public struct TextHeightBehavior: Equatable {
    /// Creates a new TextHeightBehavior object.
    ///
    /// All properties default to true (height modifications applied as normal).
    public init(
        applyHeightToFirstAscent: Bool = true,
        applyHeightToLastDescent: Bool = true,
        leadingDistribution: TextLeadingDistribution = .proportional
    ) {
        self.applyHeightToFirstAscent = applyHeightToFirstAscent
        self.applyHeightToLastDescent = applyHeightToLastDescent
        self.leadingDistribution = leadingDistribution
    }

    /// Whether to apply the [TextStyle.height] modifier to the ascent of the first
    /// line in the paragraph.
    ///
    /// When true, the [TextStyle.height] modifier will be applied to the ascent
    /// of the first line. When false, the font's default ascent will be used and
    /// the [TextStyle.height] will have no effect on the ascent of the first line.
    ///
    /// This property only has effect if a non-null [TextStyle.height] is specified.
    ///
    /// Defaults to true (height modifications applied as normal).
    public var applyHeightToFirstAscent: Bool = true

    /// Whether to apply the [TextStyle.height] modifier to the descent of the last
    /// line in the paragraph.
    ///
    /// When true, the [TextStyle.height] modifier will be applied to the descent
    /// of the last line. When false, the font's default descent will be used and
    /// the [TextStyle.height] will have no effect on the descent of the last line.
    ///
    /// This property only has effect if a non-null [TextStyle.height] is specified.
    ///
    /// Defaults to true (height modifications applied as normal).
    public var applyHeightToLastDescent: Bool = true

    /// How the ["leading"](https://en.wikipedia.org/wiki/Leading) is distributed
    /// over and under the text.
    ///
    /// Does not affect layout when [TextStyle.height] is not specified. The
    /// leading can become negative, for example, when [TextLeadingDistribution.even]
    /// is used with a [TextStyle.height] much smaller than 1.0.
    ///
    /// Defaults to [TextLeadingDistribution.proportional],
    public var leadingDistribution: TextLeadingDistribution
}

/// How the "leading" is distributed over and under the text.
///
/// Does not affect layout when [TextStyle.height] is not specified. The leading
/// can become negative, for example, when [TextLeadingDistribution.even] is
/// used with a [TextStyle.height] much smaller than 1.0.
public enum TextLeadingDistribution {
    /// Distributes the [leading](https://en.wikipedia.org/wiki/Leading)
    /// of the text proportionally above and below the text, to the font's
    /// ascent/descent ratio.
    ///
    /// The leading of a text run is defined as
    /// `TextStyle.height * TextStyle.fontSize - TextStyle.fontSize`. When
    /// [TextStyle.height] is not set, the text run uses the leading specified by
    /// the font instead.
    case proportional

    /// Distributes the ["leading"](https://en.wikipedia.org/wiki/Leading)
    /// of the text evenly above and below the text (i.e. evenly above the
    /// font's ascender and below the descender).
    ///
    /// The leading can become negative when [TextStyle.height] is smaller than
    /// 1.0.
    ///
    /// This is the default strategy used by CSS, known as
    /// ["half-leading"](https://www.w3.org/TR/css-inline-3/#half-leading).
    case even
}

/// A position in a string of text, represented by a UTF-16 offset.
///
/// Although Swift natively uses UTF-8 as the internal representation of text
/// with built-in support for extended grapheme cluster, most underlying
/// rendering library and system APIs still use UTF-16. Therefore, UTF-16
/// offsets are used to represent text positions in the framework, with some
/// helpful utilities to convert between UTF-16 and ``String.Index``.
public struct TextIndex: Equatable {
    public init(utf16Offset: Int) {
        self.utf16Offset = utf16Offset
    }

    /// Creates a new TextIndex from existing String.Index.
    public init(from: String.Index, in s: any StringProtocol) {
        self.utf16Offset = from.utf16Offset(in: s)
    }

    /// The UTF-16 offset of the position.
    public var utf16Offset: Int
}

extension TextIndex {
    public static var zero: TextIndex { TextIndex(utf16Offset: 0) }

    public static var one: TextIndex { TextIndex(utf16Offset: 1) }
}

extension TextIndex: Comparable {
    public static func < (lhs: TextIndex, rhs: TextIndex) -> Bool {
        return lhs.utf16Offset < rhs.utf16Offset
    }

    public static func <= (lhs: TextIndex, rhs: TextIndex) -> Bool {
        return lhs.utf16Offset <= rhs.utf16Offset
    }

    public static func == (lhs: TextIndex, rhs: TextIndex) -> Bool {
        return lhs.utf16Offset == rhs.utf16Offset
    }

    public static func > (lhs: TextIndex, rhs: TextIndex) -> Bool {
        return lhs.utf16Offset > rhs.utf16Offset
    }

    public static func >= (lhs: TextIndex, rhs: TextIndex) -> Bool {
        return lhs.utf16Offset >= rhs.utf16Offset
    }

    /// Creates a TextRange from this TextIndex to another TextIndex.
    public static func ..< (lhs: TextIndex, rhs: TextIndex) -> TextRange {
        return TextRange(start: lhs, end: rhs)
    }

}

extension TextIndex {
    public static func + (lhs: TextIndex, rhs: TextIndex) -> TextIndex {
        return .init(utf16Offset: lhs.utf16Offset + rhs.utf16Offset)
    }

    public static func - (lhs: TextIndex, rhs: TextIndex) -> TextIndex {
        return .init(utf16Offset: lhs.utf16Offset - rhs.utf16Offset)
    }
}

extension TextIndex {
    /// Converts this TextIndex to a String.Index.
    public func index(in text: String) -> String.UTF16View.Index {
        return text.utf16.index(text.utf16.startIndex, offsetBy: utf16Offset)
    }

    /// Get the utf16 code unit at this TextIndex.
    public func codeUnit(in text: String) -> UInt16 {
        return text.utf16[index(in: text)]
    }

    /// Gets the code point at this TextIndex.
    public func codePoint(in text: String) -> Int {
        return Int(text.unicodeScalars[index(in: text)].value)
    }

    /// Gets the character at this TextIndex.
    public func character(in text: String) -> Character {
        return text[index(in: text)]
    }
}

extension TextIndex: Strideable {
    public func advanced(by n: Int) -> TextIndex {
        return .init(utf16Offset: utf16Offset + n)
    }

    public func distance(to other: TextIndex) -> Int {
        return other.utf16Offset - utf16Offset
    }
}

/// A position in a string of text.
///
/// A TextPosition can be used to describe a caret position in between
/// characters. The [offset] points to the position between `offset - 1` and
/// `offset` characters of the string, and the [affinity] is used to describe
/// which character this position affiliates with.
///
/// One use case is when rendered text is forced to wrap. In this case, the offset
/// where the wrap occurs could visually appear either at the end of the first
/// line or the beginning of the second line. The second way is with
/// bidirectional text.  An offset at the interface between two different text
/// directions could have one of two locations in the rendered text.
///
/// See the documentation for [TextAffinity] for more information on how
/// TextAffinity disambiguates situations like these.
public struct TextPosition: Equatable {
    public init(offset: TextIndex, affinity: TextAffinity = .downstream) {
        self.offset = offset
        self.affinity = affinity
    }

    /// The index of the character that immediately follows the position in the
    /// string representation of the text.
    ///
    /// For example, given the string `'Hello'`, offset 0 represents the cursor
    /// being before the `H`, while offset 5 represents the cursor being just
    /// after the `o`.
    public var offset: TextIndex

    /// Disambiguates cases where the position in the string given by [offset]
    /// could represent two different visual positions in the rendered text. For
    /// example, this can happen when text is forced to wrap, or when one string
    /// of text is rendered with multiple text directions.
    ///
    /// See the documentation for [TextAffinity] for more information on how
    /// TextAffinity disambiguates situations like these.
    public var affinity: TextAffinity
}

/// A range of characters in a string of text.
public struct TextRange: Equatable {
    /// Creates a text range.
    ///
    /// The [start] and [end] arguments must not be null. Both the [start] and
    /// [end] must either be greater than or equal to zero or both exactly -1.
    ///
    /// The text included in the range includes the character at [start], but not
    /// the one at [end].
    ///
    /// Instead of creating an empty text range, consider using the [empty]
    /// constant.
    public init(start: TextIndex, end: TextIndex) {
        assert(end >= start, "The end of a range cannot precede the start.")
        self.start = start
        self.end = end
    }

    /// A text range that starts and ends at offset.
    ///
    /// The [offset] argument must be non-null and greater than or equal to -1.
    public static func collapsed(_ offset: TextIndex) -> Self {
        return Self(start: offset, end: offset)
    }

    public static var empty: Self {
        return .collapsed(.zero)
    }

    /// The index of the first character in the range.
    ///
    /// If [start] and [end] are both -1, the text range is empty.
    public var start: TextIndex

    /// The next index after the characters in this range.
    ///
    /// If [start] and [end] are both -1, the text range is empty.
    public var end: TextIndex

    /// Whether this range represents a valid position in the text.
    public var isValid: Bool {
        return start >= .zero && end >= .zero
    }

    /// Whether this range is empty (but still potentially placed inside the
    /// text).
    public var isCollapsed: Bool {
        return start == end
    }

    /// Whether the start of this range precedes the end.
    public var isNormalized: Bool {
        return end >= start
    }

    /// The text before this range.
    public func textBefore(_ text: String) -> String {
        assert(isNormalized)
        let endIndex = start.index(in: text)
        return String(text[..<endIndex])
    }

    /// The text after this range.
    public func textAfter(_ text: String) -> String {
        assert(isNormalized)
        let startIndex = end.index(in: text)
        return String(text[startIndex...])
    }

    /// The text inside this range.
    public func textInside(_ text: String) -> String {
        assert(isNormalized)
        let startIndex = start.index(in: text)
        let endIndex = end.index(in: text)
        return String(text[startIndex..<endIndex])
    }
}

// MARK: - Paragraph

public struct TextBox {
    /// Creates an object that describes a box containing text.
    public init(left: Float, top: Float, right: Float, bottom: Float, direction: TextDirection) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
        self.direction = direction
    }

    /// The left edge of the text box, irrespective of direction.
    ///
    /// To get the leading edge (which may depend on the [direction]), consider [start].
    public let left: Float

    /// The top edge of the text box.
    public let top: Float

    /// The right edge of the text box, irrespective of direction.
    ///
    /// To get the trailing edge (which may depend on the [direction]), consider [end].
    public let right: Float

    /// The bottom edge of the text box.
    public let bottom: Float

    /// The direction in which text inside this box flows.
    public let direction: TextDirection

    /// Returns a rect of the same size as this box.
    public func toRect() -> Rect {
        return Rect(left: left, top: top, right: right, bottom: bottom)
    }

    /// The [left] edge of the box for left-to-right text; the [right] edge of the box for right-to-left text.
    ///
    /// See also:
    ///
    ///  * [direction], which specifies the text direction.
    public var start: Float {
        return (direction == .ltr) ? left : right
    }

    /// The [right] edge of the box for left-to-right text; the [left] edge of the box for right-to-left text.
    ///
    /// See also:
    ///
    ///  * [direction], which specifies the text direction.
    public var end: Float {
        return (direction == .ltr) ? right : left
    }
}

/// Defines the strut, which sets the minimum height a line can be
/// relative to the baseline.
///
/// Strut applies to all lines in the paragraph. Strut is a feature that
/// allows minimum line heights to be set. The effect is as if a zero
/// width space was included at the beginning of each line in the
/// paragraph. This imaginary space is 'shaped' according the properties
/// defined in this class. Flutter's strut is based on
/// [typesetting strut](https://en.wikipedia.org/wiki/Strut_(typesetting))
/// and CSS's [line-height](https://www.w3.org/TR/CSS2/visudet.html#line-height).
///
/// No lines may be shorter than the strut. The ascent and descent of the
/// strut are calculated, and any laid out text that has a shorter ascent or
/// descent than the strut's ascent or descent will take the ascent and
/// descent of the strut. Text with ascents or descents larger than the
/// strut's ascent or descent will layout as normal and extend past the strut.
///
/// Strut is defined independently from any text content or [TextStyle]s.
public struct StrutStyle: Equatable {
    /// The name of the font to use when calculating the strut (e.g., Roboto).
    /// If the font is defined in a package, this will be prefixed with
    /// 'packages/package_name/' (e.g. 'packages/cool_fonts/Roboto'). The
    /// prefixing is done by the constructor when the `package` argument is
    /// provided.
    ///
    /// The value provided in [fontFamily] will act as the preferred/first font
    /// family that will be searched for, followed in order by the font families
    /// in [fontFamilyFallback]. If all font families are exhausted and no match
    /// was found, the default platform font family will be used instead. Unlike
    /// [TextStyle.fontFamilyFallback], the font does not need to contain the
    /// desired glyphs to match.
    public var fontFamilies: [String]?

    /// The size of text (in logical pixels) to use when obtaining metrics from
    /// the font.
    ///
    /// The [fontSize] is used to get the base set of metrics that are then used
    /// to calculated the metrics of strut. The height and leading are expressed
    /// as a multiple of [fontSize].
    ///
    /// The default fontSize is 14 logical pixels.
    public var fontSize: Float?

    /// The typeface variant to use when calculating the strut (e.g., italics).
    ///
    /// The default fontStyle is [FontStyle.normal].
    public var fontStyle: FontStyle?

    /// The minimum height of the strut, as a multiple of [fontSize].
    ///
    /// When [height] is omitted or null, then the strut's height will be the
    /// sum of the strut's font-defined ascent, its font-defined descent, and
    /// its [leading]. The font's combined ascent and descent may be taller or
    /// shorter than the [fontSize].
    ///
    /// When [height] is provided, the line's EM-square ascent and descent
    /// (which sums to [fontSize]) will be scaled by [height] to achieve a final
    /// strut height of `fontSize * height + fontSize * leading` logical pixels.
    /// The following diagram illustrates the differences between the font
    /// metrics defined height and the EM-square height:
    ///
    /// ![Text height
    /// diagram](https://flutter.github.io/assets-for-api-docs/assets/painting/text_height_diagram.png)
    ///
    /// The ratio of ascent:descent with [height] specified is the same as the
    /// font metrics defined ascent:descent ratio when [height] is null or
    /// omitted.
    ///
    /// See [TextStyle.height], which works in a similar manner.
    ///
    /// The default height is null.
    public var height: Float?

    /// The additional leading to apply to the strut as a multiple of
    /// [fontSize], independent of [height] and [leadingDistribution].
    ///
    /// Leading is additional spacing between lines. Half of the leading is
    /// added to the top and the other half to the bottom of the line. This
    /// differs from [height] since the spacing is always equally distributed
    /// above and below the baseline, regardless of [leadingDistribution].
    ///
    /// The default leading is null, which will use the font-specified leading.
    public var leading: Float?

    /// Whether the strut height should be forced.
    ///
    /// When true, all lines will be laid out with the height of the strut. All
    /// line and run-specific metrics will be ignored/overridden and only strut
    /// metrics will be used instead. This property guarantees uniform line
    /// spacing, however text in adjacent lines may overlap.
    ///
    /// This property should be enabled with caution as it bypasses a large
    /// portion of the vertical layout system.
    ///
    /// This is equivalent to setting [TextStyle.height] to zero for all
    /// [TextStyle]s in the paragraph. Since the height of each line is
    /// calculated as a max of the metrics of each run of text, zero height
    /// [TextStyle]s cause the minimums defined by strut to always manifest,
    /// resulting in all lines having the height of the strut.
    ///
    /// The default is false.
    public var forceHeight: Bool?

    // var enabled: Bool
    // var heightOverride: Bool
    // var halfLeading: Bool
}

/// An object that determines the configuration used by [ParagraphBuilder] to
/// position lines within a [Paragraph] of text.
public struct ParagraphStyle {
    public init(
        textAlign: TextAlign? = nil,
        textDirection: TextDirection? = nil,
        defaultSpanStyle: SpanStyle? = nil,
        strutStyle: StrutStyle? = nil,
        maxLines: Int? = nil,
        ellipsis: String? = nil,
        height: Float? = nil,
        textHeightBehavior: TextHeightBehavior? = nil
    ) {
        self.strutStyle = strutStyle
        self.defaultSpanStyle = defaultSpanStyle
        self.textAlign = textAlign
        self.textDirection = textDirection
        self.maxLines = maxLines
        self.ellipsis = ellipsis
        self.height = height
        self.textHeightBehavior = textHeightBehavior
    }

    public var strutStyle: StrutStyle?

    public var defaultSpanStyle: SpanStyle?

    /// The alignment of the text within the lines of the paragraph. If the last
    /// line is ellipsized (see `ellipsis` below), the alignment is applied to
    /// that line after it has been truncated but before the ellipsis has been
    /// added.
    public var textAlign: TextAlign?

    /// The directionality of the text, left-to-right (e.g. Norwegian) or
    /// right-to-left (e.g. Hebrew). This controls the overall directionality of
    /// the paragraph, as well as the meaning of [TextAlign.start] and
    /// [TextAlign.end] in the `textAlign` field.
    public var textDirection: TextDirection?

    /// The maximum number of lines painted. Lines beyond this number are
    /// silently dropped. For example, if `maxLines` is 1, then only one line is
    /// rendered. If `maxLines` is null, but `ellipsis` is not null, then lines
    /// after the first one that overflows the width constraints are dropped.
    /// The width constraints are those set in the [ParagraphConstraints] object
    /// passed to the [Paragraph.layout] method.
    public var maxLines: Int?

    /// String used to ellipsize overflowing text. If `maxLines` is not null,
    /// then the `ellipsis`, if any, is applied to the last rendered line, if
    /// that line overflows the width constraints. If `maxLines` is null, then
    /// the `ellipsis` is applied to the first line that overflows the width
    /// constraints, and subsequent lines are dropped. The width constraints are
    /// those set in the [ParagraphConstraints] object passed to the
    /// [Paragraph.layout] method. The empty string and the null value are
    /// considered equivalent and turn off this behavior.
    public var ellipsis: String?

    /// The fallback height of the spans as a multiplier of the font size. The
    /// fallback height is used when no height is provided through
    /// [TextStyle.height]. Omitting `height` here and in [TextStyle] will allow
    /// the line height to take the height as defined by the font, which may not
    /// be exactly the height of the `fontSize`.
    public var height: Float?

    /// Specifies how the `height` multiplier is applied to ascent of the first
    /// line and the descent of the last line.
    public var textHeightBehavior: TextHeightBehavior?

    // public var hintingIsOn: Bool
    // public var replaceTabCharacters: Bool
    // public var textIndent: TextIndent
    // public var fontRastrSettings: FontRastrSettings
}

public protocol ParagraphBuilder: AnyObject {
    /// Applies the given style to the added text until [pop] is called.
    ///
    /// See [pop] for details.
    func pushStyle(_ style: SpanStyle)

    /// Ends the effect of the most recent call to [pushStyle].
    ///
    /// Internally, the paragraph builder maintains a stack of text styles. Text
    /// added to the paragraph is affected by all the styles in the stack.
    /// Calling [pop] removes the topmost style in the stack, leaving the
    /// remaining styles in effect.
    func pop()

    /// Adds the given text to the paragraph.
    ///
    /// The text will be styled according to the current stack of text styles.
    func addText(_ text: String)

    /// Applies the given paragraph style and returns a [Paragraph] containing
    /// the added text and associated styling.
    ///
    /// After calling this function, the paragraph builder object is invalid and
    /// cannot be used further.
    func build() -> Paragraph
}

/// Layout constraints for [Paragraph] objects.
///
/// Instances of this class are typically used with [Paragraph.layout].
///
/// The only constraint that can be specified is the [width]. See the discussion
/// at [width] for more details.
public enum ParagraphConstraints: Equatable {
    /// The width the paragraph should use whey computing the positions of glyphs.
    ///
    /// If possible, the paragraph will select a soft line break prior to reaching
    /// this width. If no soft line break is available, the paragraph will select
    /// a hard line break prior to reaching this width. If that would force a line
    /// break without any characters having been placed (i.e. if the next
    /// character to be laid out does not fit within the given width constraint)
    /// then the next character is allowed to overflow the width constraint and a
    /// forced line break is placed after it (even if an explicit line break
    /// follows).
    ///
    /// The width influences how ellipses are applied. See the discussion at
    /// [ParagraphStyle.new] for more details.
    ///
    /// This width is also used to position glyphs according to the [TextAlign]
    /// alignment described in the [ParagraphStyle] used when building the
    /// [Paragraph] with a [ParagraphBuilder].
    case width(_ width: Float)
}

/// Defines various ways to horizontally bound the boxes returned by
/// [Paragraph.getBoxesForRange].
///
/// See [BoxHeightStyle] for a similar property to control height.
public enum BoxWidthStyle {
    /// Provide tight bounding boxes that fit widths to the runs of each line
    /// independently.
    case tight

    /// Adds up to two additional boxes as needed at the beginning and/or end
    /// of each line so that the widths of the boxes in line are the same width
    /// as the widest line in the paragraph.
    ///
    /// The additional boxes on each line are only added when the relevant box
    /// at the relevant edge of that line does not span the maximum width of
    /// the paragraph.
    case max
}

/// Defines various ways to vertically bound the boxes returned by
/// [Paragraph.getBoxesForRange].
///
/// See [BoxWidthStyle] for a similar property to control width.
public enum BoxHeightStyle {
    /// Provide tight bounding boxes that fit heights per run. This style may result
    /// in uneven bounding boxes that do not nicely connect with adjacent boxes.
    case tight

    /// The height of the boxes will be the maximum height of all runs in the
    /// line. All boxes in the same line will be the same height.
    ///
    /// This does not guarantee that the boxes will cover the entire vertical height of the line
    /// when there is additional line spacing.
    ///
    /// See [BoxHeightStyle.includeLineSpacingTop], [BoxHeightStyle.includeLineSpacingMiddle],
    /// and [BoxHeightStyle.includeLineSpacingBottom] for styles that will cover
    /// the entire line.
    case max

    /// Extends the top and bottom edge of the bounds to fully cover any line
    /// spacing.
    ///
    /// The top and bottom of each box will cover half of the
    /// space above and half of the space below the line.
    ///
    /// The top edge of each line should be the same as the bottom edge
    /// of the line above. There should be no gaps in vertical coverage given any
    /// amount of line spacing. Line spacing is not included above the first line
    /// and below the last line due to no additional space present there.
    case includeLineSpacingMiddle

    /// Extends the top edge of the bounds to fully cover any line spacing.
    ///
    /// The line spacing will be added to the top of the box.
    case includeLineSpacingTop

    /// Extends the bottom edge of the bounds to fully cover any line spacing.
    ///
    /// The line spacing will be added to the bottom of the box.
    case includeLineSpacingBottom

    /// Calculate box heights based on the metrics of this paragraph's [StrutStyle].
    ///
    /// Boxes based on the strut will have consistent heights throughout the
    /// entire paragraph.  The top edge of each line will align with the bottom
    /// edge of the previous line.  It is possible for glyphs to extend outside
    /// these boxes.
    case strut
}

/// A paragraph of text.
///
/// A paragraph retains the size and position of each glyph in the text and can
/// be efficiently resized and painted.
///
/// To create a [Paragraph] object, use a [ParagraphBuilder].
///
/// Paragraphs can be displayed on a [Canvas] using the [Canvas.drawParagraph]
/// method.
public protocol Paragraph: AnyObject {
    /// The amount of horizontal space this paragraph occupies.
    ///
    /// Valid only after [layout] has been called.
    var width: Float { get }

    /// The amount of vertical space this paragraph occupies.
    ///
    /// Valid only after [layout] has been called.
    var height: Float { get }

    /// The distance from the left edge of the leftmost glyph to the right edge of
    /// the rightmost glyph in the paragraph.
    ///
    /// Valid only after [layout] has been called.
    var longestLine: Float { get }

    /// The minimum width that this paragraph could be without failing to paint
    /// its contents within itself.
    ///
    /// Valid only after [layout] has been called.
    var minIntrinsicWidth: Float { get }

    /// Returns the smallest width beyond which increasing the width never
    /// decreases the height.
    ///
    /// Valid only after [layout] has been called.
    var maxIntrinsicWidth: Float { get }

    /// The distance from the top of the paragraph to the alphabetic
    /// baseline of the first line, in logical pixels.
    var alphabeticBaseline: Float { get }

    /// The distance from the top of the paragraph to the ideographic
    /// baseline of the first line, in logical pixels.
    var ideographicBaseline: Float { get }

    /// True if there is more vertical content, but the text was truncated, either
    /// because we reached `maxLines` lines of text or because the `maxLines` was
    /// null, `ellipsis` was not null, and one of the lines exceeded the width
    /// constraint.
    ///
    /// See the discussion of the `maxLines` and `ellipsis` arguments at
    /// [ParagraphStyle.new].
    var didExceedMaxLines: Bool { get }

    /// Computes the size and position of each glyph in the paragraph.
    ///
    /// The [ParagraphConstraints] control how wide the text is allowed to be.
    func layout(_ constraints: ParagraphConstraints)

    /// Returns a list of text boxes that enclose the given text range.
    ///
    /// The [boxHeightStyle] and [boxWidthStyle] parameters allow customization
    /// of how the boxes are bound vertically and horizontally. Both style
    /// parameters default to the tight option, which will provide close-fitting
    /// boxes and will not account for any line spacing.
    ///
    /// Coordinates of the TextBox are relative to the upper-left corner of the paragraph,
    /// where positive y values indicate down.
    ///
    /// The [boxHeightStyle] and [boxWidthStyle] parameters must not be null.
    ///
    /// See [BoxHeightStyle] and [BoxWidthStyle] for full descriptions of each option.
    func getBoxesForRange(
        _ start: TextIndex,
        _ end: TextIndex,
        boxHeightStyle: BoxHeightStyle,
        boxWidthStyle: BoxWidthStyle
    ) -> [TextBox]

    /// Returns a list of text boxes that enclose all placeholders in the paragraph.
    ///
    /// The order of the boxes are in the same order as passed in through
    /// [ParagraphBuilder.addPlaceholder].
    ///
    /// Coordinates of the [TextBox] are relative to the upper-left corner of the paragraph,
    /// where positive y values indicate down.
    func getBoxesForPlaceholders() -> [TextBox]

    /// Returns the text position closest to the given offset.
    func getPositionForOffset(_ offset: Offset) -> TextPosition

    /// Returns the `GlyphInfo` of the glyph closest to the given `offset` in the
    /// paragraph coordinate system, or null if if the text is empty, or is
    /// entirely clipped or ellipsized away.
    ///
    /// This method first finds the line closest to `offset.dy`, and then returns
    /// the `GlyphInfo` of the closest glyph(s) within that line.
    func getClosestGlyphInfoForOffset(_ offset: Offset) -> GlyphInfo?

    /// Returns the `GlyphInfo` located at the given UTF-16 `codeUnitOffset` in
    /// the paragraph, or null if the given `codeUnitOffset` is out of the visible
    /// lines or is ellipsized.
    func getGlyphInfoAt(_ offset: TextIndex) -> GlyphInfo?

    /// Returns the [TextRange] of the word at the given [TextPosition].
    ///
    /// Characters not part of a word, such as spaces, symbols, and punctuation,
    /// have word breaks on both sides. In such cases, this method will return
    /// (offset, offset+1). Word boundaries are defined more precisely in Unicode
    /// Standard Annex #29 http://www.unicode.org/reports/tr29/#Word_Boundaries
    ///
    /// The [TextPosition] is treated as caret position, its [TextPosition.affinity]
    /// is used to determine which character this position points to. For example,
    /// the word boundary at `TextPosition(offset: 5, affinity: TextPosition.upstream)`
    /// of the `string = 'Hello word'` will return range (0, 5) because the position
    /// points to the character 'o' instead of the space.
    func getWordBoundary(_ position: TextPosition) -> TextRange

    /// Returns the [TextRange] of the line at the given [TextPosition].
    ///
    /// The newline (if any) is returned as part of the range.
    ///
    /// Not valid until after layout.
    ///
    /// This can potentially be expensive, since it needs to compute the line
    /// metrics, so use it sparingly.
    func getLineBoundary(_ position: TextPosition) -> TextRange?

    /// Returns the full list of [LineMetrics] that describe in detail the various
    /// metrics of each laid out line.
    ///
    /// Not valid until after layout.
    ///
    /// This can potentially return a large amount of data, so it is not recommended
    /// to repeatedly call this. Instead, cache the results.
    func computeLineMetrics() -> [LineMetrics]

    /// Returns the [LineMetrics] for the line at `line`, or nil if the
    /// given `line` is greater than or equal to [numberOfLines].
    func getLineMetricsAt(line: Int) -> LineMetrics?

    /// The total number of visible lines in the paragraph.
    ///
    /// Returns a non-negative number. If `maxLines` is non-null, the value of
    /// [numberOfLines] never exceeds `maxLines`.
    var numberOfLines: Int { get }

    /// Returns the line number of the line that contains the code unit that
    /// `codeUnitOffset` points to.
    ///
    /// This method returns nil if the given `codeUnitOffset` is out of bounds, or
    /// is logically after the last visible codepoint. This includes the case where
    /// its codepoint belongs to a visible line, but the text layout library
    /// replaced it with an ellipsis.
    ///
    /// If the target code unit points to a control character that introduces
    /// mandatory line breaks (most notably the line feed character `LF`, typically
    /// represented in strings as the escape sequence "\n"), to conform to
    /// [the unicode rules](https://unicode.org/reports/tr14/#LB4), the control
    /// character itself is always considered to be at the end of "current" line
    /// rather than the beginning of the new line.
    func getLineNumberAt(_ offset: TextIndex) -> Int?
}

extension Paragraph {
    public func getLineBoundary(_ position: TextPosition) -> TextRange? {
        for lineMetrics in computeLineMetrics() {
            if lineMetrics.startIndex <= position.offset && position.offset < lineMetrics.endIndex {
                return TextRange(start: lineMetrics.startIndex, end: lineMetrics.endIndex)
            }
        }
        return nil
    }
}

/// [LineMetrics] stores the measurements and statistics of a single line in the
/// paragraph.
///
/// The measurements here are for the line as a whole, and represent the maximum
/// extent of the line instead of per-run or per-glyph metrics. For more detailed
/// metrics, see [TextBox] and [Paragraph.getBoxesForRange].
///
/// [LineMetrics] should be obtained directly from the [Paragraph.computeLineMetrics]
/// method.
public struct LineMetrics {
    public init(
        startIndex: TextIndex,
        endIndex: TextIndex,
        endIncludingNewline: TextIndex,
        endExcludingWhitespace: TextIndex,
        hardBreak: Bool,
        ascent: Float,
        descent: Float,
        unscaledAscent: Float,
        height: Float,
        width: Float,
        left: Float,
        baseline: Float,
        lineNumber: Int
    ) {
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.endIncludingNewline = endIncludingNewline
        self.endExcludingWhitespace = endExcludingWhitespace
        self.hardBreak = hardBreak
        self.ascent = ascent
        self.descent = descent
        self.unscaledAscent = unscaledAscent
        self.height = height
        self.width = width
        self.left = left
        self.baseline = baseline
        self.lineNumber = lineNumber
    }

    /// The starting index of the line in the text buffer.
    public let startIndex: TextIndex

    /// The ending index of the line in the text buffer, excluding any trailing whitespace.
    public let endIndex: TextIndex

    /// The ending index of the line in the text buffer, including any trailing whitespace.
    public let endIncludingNewline: TextIndex

    /// The ending index of the line in the text buffer, excluding any trailing whitespace or newline characters.
    public let endExcludingWhitespace: TextIndex

    /// True if this line ends with an explicit line break (e.g. '\n') or is the end
    /// of the paragraph. False otherwise.
    public let hardBreak: Bool

    /// The rise from the [baseline] as calculated from the font and style for this line.
    ///
    /// This is the final computed ascent and can be impacted by the strut, height, scaling,
    /// as well as outlying runs that are very tall.
    ///
    /// The [ascent] is provided as a positive value, even though it is typically definedå
    /// in fonts as negative. This is to ensure the signage of operations with these
    /// metrics directly reflects the intended signage of the value. For example,
    /// the y coordinate of the top edge of the line is `baseline - ascent`.
    public let ascent: Float

    /// The drop from the [baseline] as calculated from the font and style for this line.
    ///
    /// This is the final computed ascent and can be impacted by the strut, height, scaling,
    /// as well as outlying runs that are very tall.
    ///
    /// The y coordinate of the bottom edge of the line is `baseline + descent`.
    public let descent: Float

    /// The rise from the [baseline] as calculated from the font and style for this line
    /// ignoring the [TextStyle.height].
    ///
    /// The [unscaledAscent] is provided as a positive value, even though it is typically
    /// defined in fonts as negative. This is to ensure the signage of operations with
    /// these metrics directly reflects the intended signage of the value.
    public let unscaledAscent: Float

    /// Total height of the line from the top edge to the bottom edge.
    ///
    /// This is equivalent to `round(ascent + descent)`. This value is provided
    /// separately due to rounding causing sub-pixel differences from the unrounded
    /// values.
    public let height: Float

    /// Width of the line from the left edge of the leftmost glyph to the right
    /// edge of the rightmost glyph.
    ///
    /// This is not the same as the width of the pargraph.
    ///
    /// See also:
    ///
    ///  * [Paragraph.width], the max width passed in during layout.
    ///  * [Paragraph.longestLine], the width of the longest line in the paragraph.
    public let width: Float

    /// The x coordinate of left edge of the line.
    ///
    /// The right edge can be obtained with `left + width`.
    public let left: Float

    /// The y coordinate of the baseline for this line from the top of the paragraph.
    ///
    /// The bottom edge of the paragraph up to and including this line may be obtained
    /// through `baseline + descent`.
    public let baseline: Float

    /// The number of this line in the overall paragraph, with the first line being
    /// index zero.
    ///
    /// For example, the first line is line 0, second line is line 1.
    public let lineNumber: Int
}

/// Where to vertically align the placeholder relative to the surrounding text.
///
/// Used by [ParagraphBuilder.addPlaceholder].
public enum PlaceholderAlignment {
    /// Match the baseline of the placeholder with the baseline.
    ///
    /// The [TextBaseline] to use must be specified and non-null when using this
    /// alignment mode.
    case baseline

    /// Align the bottom edge of the placeholder with the baseline such that the
    /// placeholder sits on top of the baseline.
    ///
    /// The [TextBaseline] to use must be specified and non-null when using this
    /// alignment mode.
    case aboveBaseline

    /// Align the top edge of the placeholder with the baseline specified
    /// such that the placeholder hangs below the baseline.
    ///
    /// The [TextBaseline] to use must be specified and non-null when using this
    /// alignment mode.
    case belowBaseline

    /// Align the top edge of the placeholder with the top edge of the text.
    ///
    /// When the placeholder is very tall, the extra space will hang from
    /// the top and extend through the bottom of the line.
    case top

    /// Align the bottom edge of the placeholder with the bottom edge of the text.
    ///
    /// When the placeholder is very tall, the extra space will rise from the
    /// bottom and extend through the top of the line.
    case bottom

    /// Align the middle of the placeholder with the middle of the text.
    ///
    /// When the placeholder is very tall, the extra space will grow equally
    /// from the top and bottom of the line.
    case middle
}

/// A protocol that defines a collection of fonts that can be used to draw text.
public protocol FontCollection {
    /// Creates a typeface from the provided font file data.
    func makeTypefaceFrom(_ data: Data) -> Typeface

    /// Registers a typeface with the font collection. After registering a
    /// typeface, it becomes available for use in text rendering and can be
    /// found by family name when specifying text styles.
    func registerTypeface(_ typeface: Typeface)

    /// Finds the closest matching typeface to the specified family name and
    /// style.
    func findTypeface(_ family: [String], style: FontStyle, weight: FontWeight) -> [Typeface]

    /// Finds any font in the available font managers that resolves the
    /// specified Unicode codepoint.
    func findTypefaceFor(_ codepoint: UInt32) -> Typeface?
}

/// A typeface in Shaft is typically a loaded font file. It can be used to
/// create a font object with a specific size and style or to retrieve the
/// glyph id for a specific code point.
public protocol Typeface: AnyObject {
    // Retrieves the glyph ids for each code point in the provided string. Note
    // that glyph IDs are typeface-dependent; different faces may have different
    // ids for the same code point.
    func getGlyphIDs(_ text: String) -> [GlyphID?]

    /// Retrieves the glyph id for the provided unicode code point. Note that
    /// glyph IDs are typeface-dependent; different faces may have different ids
    /// for the same code point.
    func getGlyphID(_ codePoint: UInt32) -> GlyphID?

    /// Return the number of glyphs in the typeface.
    var glyphCount: Int { get }

    /// Creates a font object with the specified size and style.
    func createFont(_ size: Float) -> Font

    /// Return the family name for this typeface.
    var familyName: String { get }
}

/// A Typeface at specific size and style.
public protocol Font: AnyObject {
    /// The size of the font in logical pixels.
    var size: Float { get }
}

/// An id that represents a glyph in a typeface. This is typeface-dependent.
public typealias GlyphID = UInt16

/// A list of glyphs and their positions in the paragraph.
public protocol TextBlob {}
