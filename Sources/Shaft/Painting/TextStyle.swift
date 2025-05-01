// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An immutable style describing how to format and paint text.
public struct TextStyle: Equatable {
    public init(
        inherit: Bool = true,
        color: Color? = nil,
        backgroundColor: Color? = nil,
        fontFamily: String? = nil,
        fontFamilyFallback: [String]? = nil,
        fontSize: Float? = nil,
        fontWeight: FontWeight? = nil,
        fontStyle: FontStyle? = nil,
        letterSpacing: Float? = nil,
        wordSpacing: Float? = nil,
        textBaseline: TextBaseline? = nil,
        height: Float? = nil,
        leadingDistribution: TextLeadingDistribution? = nil,
        foreground: Paint? = nil,
        background: Paint? = nil,
        decoration: TextDecoration? = nil,
        decorationColor: Color? = nil,
        decorationStyle: TextDecorationStyle? = nil,
        decorationThickness: Float? = nil,
        debugLabel: String? = nil,
        shadows: [Shadow]? = nil,
        fontVariations: [FontVariation]? = nil,
        overflow: TextOverflow? = nil
    ) {
        self.inherit = inherit
        self.color = color
        self.backgroundColor = backgroundColor
        self.fontFamily = fontFamily
        self.fontFamilyFallback = fontFamilyFallback
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontStyle = fontStyle
        self.letterSpacing = letterSpacing
        self.wordSpacing = wordSpacing
        self.textBaseline = textBaseline
        self.height = height
        self.leadingDistribution = leadingDistribution
        self.foreground = foreground
        self.background = background
        self.decoration = decoration
        self.decorationColor = decorationColor
        self.decorationStyle = decorationStyle
        self.decorationThickness = decorationThickness
        self.debugLabel = debugLabel
        self.shadows = shadows
        self.fontVariations = fontVariations
        self.overflow = overflow
    }

    /// Whether null values in this [TextStyle] can be replaced with their value
    /// in another [TextStyle] using [merge].
    ///
    /// The [merge] operation is not commutative: the [inherit] value of the
    /// method argument decides whether the two [TextStyle]s can be combined
    /// together. If it is false, the method argument [TextStyle] will be returned.
    /// Otherwise, the combining is allowed, and the returned [TextStyle] inherits
    /// the [inherit] value from the method receiver.
    ///
    /// This property has no effect on [TextSpan]'s text style cascading: in a
    /// [TextSpan] tree, a [TextSpan]'s text style can be combined with that of an
    /// ancestor [TextSpan] if it has unspecified fields, regardless of its
    /// [inherit] value.
    ///
    /// Properties that don't have explicit values or other default values to fall
    /// back to will revert to the defaults: white in color, a font size of 14
    /// pixels, in a sans-serif font face.
    ///
    /// See also:
    ///  * [TextStyle.merge], which can be used to combine properties from two
    ///    [TextStyle]s.
    public let inherit: Bool

    /// The color to use when painting the text.
    ///
    /// If [foreground] is specified, this value must be null. The [color] property
    /// is shorthand for `Paint()..color = color`.
    ///
    /// In [merge], [apply], and [lerp], conflicts between [color] and [foreground]
    /// specification are resolved in [foreground]'s favor - i.e. if [foreground] is
    /// specified in one place, it will dominate [color] in another.
    public let color: Color?

    /// The color to use as the background for the text.
    ///
    /// If [background] is specified, this value must be null. The
    /// [backgroundColor] property is shorthand for
    /// `background: Paint()..color = backgroundColor`.
    ///
    /// In [merge], [apply], and [lerp], conflicts between [backgroundColor] and [background]
    /// specification are resolved in [background]'s favor - i.e. if [background] is
    /// specified in one place, it will dominate [color] in another.
    public let backgroundColor: Color?

    /// The name of the font to use when painting the text (e.g., Roboto).
    ///
    /// The value provided in [fontFamily] will act as the preferred/first font
    /// family that glyphs are looked for in, followed in order by the font families
    /// in [fontFamilyFallback]. When [fontFamily] is null or not provided, the
    /// first value in [fontFamilyFallback] acts as the preferred/first font
    /// family. When neither is provided, then the default platform font will
    /// be used.
    public let fontFamily: String?

    /// The ordered list of font families to fall back on when a glyph cannot be
    /// found in a higher priority font family.
    ///
    /// The value provided in [fontFamily] will act as the preferred/first font
    /// family that glyphs are looked for in, followed in order by the font families
    /// in [fontFamilyFallback]. If all font families are exhausted and no match
    /// was found, the default platform font family will be used instead.
    ///
    /// When [fontFamily] is null or not provided, the first value in [fontFamilyFallback]
    /// acts as the preferred/first font family. When neither is provided, then
    /// the default platform font will be used. Providing an empty list or null
    /// for this property is the same as omitting it.
    ///
    /// For example, if a glyph is not found in [fontFamily], then each font family
    /// in [fontFamilyFallback] will be searched in order until it is found. If it
    /// is not found, then a box will be drawn in its place.
    public let fontFamilyFallback: [String]?

    /// The size of fonts (in logical pixels) to use when painting the text.
    ///
    /// The value specified matches the dimension of the
    /// [em square](https://fonts.google.com/knowledge/glossary/em) of the
    /// underlying font, and more often then not isn't exactly the height or the
    /// width of glyphs in the font.
    ///
    /// During painting, the [fontSize] is multiplied by the current
    /// `textScaleFactor` to let users make it easier to read text by increasing
    /// its size.
    ///
    /// The [getParagraphStyle] method defaults to 14 logical pixels if [fontSize]
    /// is set to null.
    public let fontSize: Float?

    /// The typeface thickness to use when painting the text (e.g., bold).
    public let fontWeight: FontWeight?

    /// The typeface variant to use when drawing the letters (e.g., italics).
    public let fontStyle: FontStyle?

    /// The amount of space (in logical pixels) to add between each letter.
    /// A negative value can be used to bring the letters closer.
    public let letterSpacing: Float?

    /// The amount of space (in logical pixels) to add at each sequence of
    /// white-space (i.e. between each word). A negative value can be used to
    /// bring the words closer.
    public let wordSpacing: Float?

    /// The common baseline that should be aligned between this text span and its
    /// parent text span, or, for the root text spans, with the line box.
    public let textBaseline: TextBaseline?

    /// The height of this text span, as a multiple of the font size.
    ///
    /// When [height] is null or omitted, the line height will be determined
    /// by the font's metrics directly, which may differ from the fontSize.
    /// When [height] is non-null, the line height of the span of text will be a
    /// multiple of [fontSize] and be exactly `fontSize * height` logical pixels
    /// tall.
    ///
    /// For most fonts, setting [height] to 1.0 is not the same as omitting or
    /// setting height to null because the [fontSize] sets the height of the EM-square,
    /// which is different than the font provided metrics for line height. The
    /// following diagram illustrates the difference between the font-metrics
    /// defined line height and the line height produced with `height: 1.0`
    /// (which forms the upper and lower edges of the EM-square):
    ///
    /// ![With the font-metrics-defined line height, there is space between lines appropriate for the font, whereas the EM-square is only the height required to hold most of the characters.](https://flutter.github.io/assets-for-api-docs/assets/painting/text_height_diagram.png)
    ///
    /// Examples of the resulting line heights from different values of `TextStyle.height`:
    ///
    /// ![Since the explicit line height is applied as a scale factor on the font-metrics-defined line height, the gap above the text grows faster, as the height grows, than the gap below the text.](https://flutter.github.io/assets-for-api-docs/assets/painting/text_height_comparison_diagram.png)
    ///
    /// See [StrutStyle] and [TextHeightBehavior] for further control of line
    /// height at the paragraph level.
    public let height: Float?

    /// How the vertical space added by the [height] multiplier should be
    /// distributed over and under the text.
    ///
    /// When a non-null [height] is specified, after accommodating the glyphs of
    /// the text, the remaining vertical space from the allotted line height will
    /// be distributed over and under the text, according to the
    /// [leadingDistribution] property. See the [TextStyle] class's documentation
    /// for an example.
    ///
    /// When [height] is null, [leadingDistribution] does not affect the text
    /// layout.
    ///
    /// Defaults to null, which defers to the paragraph's
    /// `ParagraphStyle.textHeightBehavior`'s [leadingDistribution].
    public let leadingDistribution: TextLeadingDistribution?

    /// The locale used to select region-specific glyphs.
    ///
    /// This property is rarely set. Typically the locale used to select
    /// region-specific glyphs is defined by the text widget's [BuildContext]
    /// using `Localizations.localeOf(context)`. For example [RichText] defines
    /// its locale this way. However, a rich text widget's [TextSpan]s could
    /// specify text styles with different explicit locales in order to select
    /// different region-specific glyphs for each text span.
    // var locale: Locale?

    /// The paint drawn as a foreground for the text.
    ///
    /// The value should ideally be cached and reused each time if multiple text
    /// styles are created with the same paint settings. Otherwise, each time it
    /// will appear like the style changed, which will result in unnecessary
    /// updates all the way through the framework.
    ///
    /// If [color] is specified, this value must be null. The [color] property
    /// is shorthand for `Paint()..color = color`.
    ///
    /// In [merge], [apply], and [lerp], conflicts between [color] and [foreground]
    /// specification are resolved in [foreground]'s favor - i.e. if [foreground] is
    /// specified in one place, it will dominate [color] in another.
    public let foreground: Paint?

    /// The paint drawn as a background for the text.
    ///
    /// The value should ideally be cached and reused each time if multiple text
    /// styles are created with the same paint settings. Otherwise, each time it
    /// will appear like the style changed, which will result in unnecessary
    /// updates all the way through the framework.
    ///
    /// If [backgroundColor] is specified, this value must be null. The
    /// [backgroundColor] property is shorthand for
    /// `background: Paint()..color = backgroundColor`.
    ///
    /// In [merge], [apply], and [lerp], conflicts between [backgroundColor] and
    /// [background] specification are resolved in [background]'s favor - i.e. if
    /// [background] is specified in one place, it will dominate [backgroundColor]
    /// in another.
    public let background: Paint?

    /// The decorations to paint near the text (e.g., an underline).
    ///
    /// Multiple decorations can be applied using [TextDecoration.combine].
    public let decoration: TextDecoration?

    /// The color in which to paint the text decorations.
    public let decorationColor: Color?

    /// The style in which to paint the text decorations (e.g., dashed).
    public let decorationStyle: TextDecorationStyle?

    /// The thickness of the decoration stroke as a multiplier of the thickness
    /// defined by the font.
    ///
    /// The font provides a base stroke width for [decoration]s which scales off
    /// of the [fontSize]. This property may be used to achieve a thinner or
    /// thicker decoration stroke, without changing the [fontSize]. For example,
    /// a [decorationThickness] of 2.0 will draw a decoration twice as thick as
    /// the font defined decoration thickness.
    ///
    /// The default [decorationThickness] is 1.0, which will use the font's base
    /// stroke thickness/width.
    public let decorationThickness: Float?

    /// A human-readable description of this text style.
    ///
    /// This property is maintained only in debug builds.
    ///
    /// When merging ([merge]), copying ([copyWith]), modifying using [apply], or
    /// interpolating ([lerp]), the label of the resulting style is marked with
    /// the debug labels of the original styles. This helps figuring out where a
    /// particular text style came from.
    ///
    /// This property is not considered when comparing text styles using `==` or
    /// [compareTo], and it does not affect [hashCode].
    public let debugLabel: String?

    /// A list of [Shadow]s that will be painted underneath the text.
    ///
    /// Multiple shadows are supported to replicate lighting from multiple light
    /// sources.
    ///
    /// Shadows must be in the same order for [TextStyle] to be considered as
    /// equivalent as order produces differing transparency.
    public let shadows: [Shadow]?

    /// A list of [FontFeature]s that affect how the font selects glyphs.
    ///
    /// Some fonts support multiple variants of how a given character can be
    /// rendered. For example, a font might provide both proportional and
    /// tabular numbers, or it might offer versions of the zero digit with
    /// and without slashes. [FontFeature]s can be used to select which of
    /// these variants will be used for rendering.
    // var fontFeatures: [ui.FontFeature]?

    /// A list of [FontVariation]s that affect how a variable font is rendered.
    ///
    /// Some fonts are variable fonts that can generate multiple font faces based
    /// on the values of customizable attributes. For example, a variable font
    /// may have a weight axis that can be set to a value between 1 and 1000.
    /// [FontVariation]s can be used to select the values of these design axes.
    ///
    /// For example, to control the weight axis of the Roboto Slab variable font
    /// (https://fonts.google.com/specimen/Roboto+Slab):
    /// ```swift
    /// TextStyle(
    ///   fontFamily: "RobotoSlab",
    ///   fontVariations: [FontVariation("wght", 900.0)]
    /// )
    /// ```
    public let fontVariations: [FontVariation]?

    /// How visual text overflow should be handled.
    public let overflow: TextOverflow?

    /// Returns a new text style that is a combination of this style and the given
    /// [other] style.
    ///
    /// If the given [other] text style has its [TextStyle.inherit] set to true,
    /// its null properties are replaced with the non-null properties of this text
    /// style. The [other] style _inherits_ the properties of this style. Another
    /// way to think of it is that the "missing" properties of the [other] style
    /// are _filled_ by the properties of this style.
    ///
    /// If the given [other] text style has its [TextStyle.inherit] set to false,
    /// returns the given [other] style unchanged. The [other] style does not
    /// inherit properties of this style.
    ///
    /// If the given text style is null, returns this text style.
    ///
    /// One of [color] or [foreground] must be null, and if this or `other` has
    /// [foreground] specified it will be given preference over any color parameter.
    ///
    /// Similarly, one of [backgroundColor] or [background] must be null, and if
    /// this or `other` has [background] specified it will be given preference
    /// over any backgroundColor parameter.
    public func merge(_ other: TextStyle?) -> TextStyle {
        guard let other = other else {
            return self
        }
        if !other.inherit {
            return other
        }

        var mergedDebugLabel: String?
        assert {
            if let otherDebugLabel = other.debugLabel ?? self.debugLabel {
                mergedDebugLabel = "(\(self.debugLabel ?? "default")).merge(\(otherDebugLabel))"
            }
            return true
        }

        return copyWith(
            color: other.color,
            backgroundColor: other.backgroundColor,
            fontFamily: other.fontFamily,
            fontFamilyFallback: other.fontFamilyFallback,
            fontSize: other.fontSize,
            fontWeight: other.fontWeight,
            fontStyle: other.fontStyle,
            letterSpacing: other.letterSpacing,
            wordSpacing: other.wordSpacing,
            textBaseline: other.textBaseline,
            height: other.height,
            leadingDistribution: other.leadingDistribution,
            foreground: other.foreground,
            background: other.background,
            decoration: other.decoration,
            decorationColor: other.decorationColor,
            decorationStyle: other.decorationStyle,
            decorationThickness: other.decorationThickness,
            debugLabel: mergedDebugLabel,
            shadows: other.shadows,
            fontVariations: other.fontVariations,
            overflow: other.overflow
        )
    }

    public func copyWith(
        inherit: Bool? = nil,
        color: Color? = nil,
        backgroundColor: Color? = nil,
        fontFamily: String? = nil,
        fontFamilyFallback: [String]? = nil,
        fontSize: Float? = nil,
        fontWeight: FontWeight? = nil,
        fontStyle: FontStyle? = nil,
        letterSpacing: Float? = nil,
        wordSpacing: Float? = nil,
        textBaseline: TextBaseline? = nil,
        height: Float? = nil,
        leadingDistribution: TextLeadingDistribution? = nil,
        foreground: Paint? = nil,
        background: Paint? = nil,
        decoration: TextDecoration? = nil,
        decorationColor: Color? = nil,
        decorationStyle: TextDecorationStyle? = nil,
        decorationThickness: Float? = nil,
        debugLabel: String? = nil,
        shadows: [Shadow]? = nil,
        fontVariations: [FontVariation]? = nil,
        overflow: TextOverflow? = nil
    ) -> TextStyle {
        TextStyle(
            inherit: inherit ?? self.inherit,
            color: color ?? self.color,
            backgroundColor: backgroundColor ?? self.backgroundColor,
            fontFamily: fontFamily ?? self.fontFamily,
            fontFamilyFallback: fontFamilyFallback ?? self.fontFamilyFallback,
            fontSize: fontSize ?? self.fontSize,
            fontWeight: fontWeight ?? self.fontWeight,
            fontStyle: fontStyle ?? self.fontStyle,
            letterSpacing: letterSpacing ?? self.letterSpacing,
            wordSpacing: wordSpacing ?? self.wordSpacing,
            textBaseline: textBaseline ?? self.textBaseline,
            height: height ?? self.height,
            leadingDistribution: leadingDistribution ?? self.leadingDistribution,
            foreground: foreground ?? self.foreground,
            background: background ?? self.background,
            decoration: decoration ?? self.decoration,
            decorationColor: decorationColor ?? self.decorationColor,
            decorationStyle: decorationStyle ?? self.decorationStyle,
            decorationThickness: decorationThickness ?? self.decorationThickness,
            debugLabel: debugLabel ?? self.debugLabel,
            shadows: shadows ?? self.shadows,
            fontVariations: fontVariations ?? self.fontVariations,
            overflow: overflow ?? self.overflow
        )
    }
}

extension TextStyle {
    func toSpanStyle(
        textScaler: any TextScaler = .noScaling
    ) -> SpanStyle {
        let effectFontFamily = fontFamily ?? self.fontFamily
        let effectFontFamilyFallback = fontFamilyFallback ?? self.fontFamilyFallback
        let fontFamilies = [effectFontFamily].compactMap { $0 } + (effectFontFamilyFallback ?? [])

        var effectFontSize = fontSize
        if let fontSize {
            effectFontSize = textScaler.scale(fontSize)
        }

        return SpanStyle(
            color: color,
            decoration: decoration,
            decorationColor: decorationColor,
            decorationStyle: decorationStyle,
            decorationThickness: decorationThickness,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            textBaseline: textBaseline,
            fontFamilies: fontFamilies,
            fontSize: effectFontSize,
            letterSpacing: letterSpacing,
            wordSpacing: wordSpacing,
            height: height,
            leadingDistribution: leadingDistribution,
            background: background,
            foreground: foreground,
            shadows: shadows,
            fontVariations: fontVariations
        )
    }

    func toParagraphStyle(
        textAlign: TextAlign? = nil,
        textDirection: TextDirection? = nil,
        textScaler: any TextScaler = .noScaling,
        strutStyle: StrutStyle? = nil,
        spanStyle: SpanStyle? = nil,
        maxLines: Int? = nil,
        ellipsis: String? = nil,
        height: Float? = nil,
        textHeightBehavior: TextHeightBehavior? = nil
    ) -> ParagraphStyle {
        let effectiveTextHeightBehavior: TextHeightBehavior? =
            if let textHeightBehavior {
                textHeightBehavior
            } else if let leadingDistribution {
                TextHeightBehavior(leadingDistribution: leadingDistribution)
            } else { nil }

        return ParagraphStyle(
            textAlign: textAlign,
            textDirection: textDirection,
            defaultSpanStyle: spanStyle ?? self.toSpanStyle(textScaler: textScaler),
            strutStyle: strutStyle,
            maxLines: maxLines,
            ellipsis: ellipsis,
            height: height ?? self.height,
            textHeightBehavior: effectiveTextHeightBehavior
        )
    }

    // func toStrutStyle() -> StrutStyle {
    //     StrutStyle(
    //         fontFamilies: [fontFamily].compactMap { $0 } + (fontFamilyFallback ?? []),
    //         fontSize: fontSize,
    //         fontWeight: fontWeight,
    //         fontStyle: fontStyle,
    //         height: height,
    //         leadingDistribution: leadingDistribution,
    //         forceStrutHeight: forc,
    //         debugLabel: debugLabel
    //     )
    // }
}
