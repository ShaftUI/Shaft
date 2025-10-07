// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

// The default font size if none is specified. This should be kept in sync with
// the defaults set in skia (paragraph_style.h).
private let kDefaultFontSize = Float(14.0)

/// How overflowing text should be handled.
///
/// A ``TextOverflow`` can be passed to ``Text`` and ``RichText`` via their
/// ``Text/overflow`` and ``RichText/overflow`` properties respectively.
public enum TextOverflow {
    /// Clip the overflowing text to fix its container.
    case clip

    /// Fade the overflowing text to transparent.
    case fade

    /// Use an ellipsis to indicate that the text has overflowed.
    case ellipsis

    /// Render overflowing text outside of its container.
    case visible
}

/// The different ways of measuring the width of one or more lines of text.
///
/// See ``Text/textWidthBasis``, for example.
public enum TextWidthBasis {
    /// multiline text will take up the full width given by the parent. For single
    /// line text, only the minimum amount of width needed to contain the text
    /// will be used. A common use case for this is a standard series of
    /// paragraphs.
    case parent

    /// The width will be exactly enough to contain the longest line and no
    /// longer. A common use case for this is chat bubbles.
    case longestLine
}

/// Holds the ``Size`` and baseline required to represent the dimensions of
/// a placeholder in text.
///
/// Placeholders specify an empty space in the text layout, which is used
/// to later render arbitrary inline widgets into defined by a ``WidgetSpan``.
///
/// See also:
///
///  * ``WidgetSpan``, a subclass of ``InlineSpan`` and ``PlaceholderSpan`` that
///    represents an inline widget embedded within text. The space this
///    widget takes is indicated by a placeholder.
///  * ``RichText``, a text widget that supports text inline widgets.
public struct PlaceholderDimensions {
    /// A constant representing an empty placeholder.
    static var empty = PlaceholderDimensions(size: .zero, alignment: .bottom)

    /// Width and height dimensions of the placeholder.
    var size: Size

    /// How to align the placeholder with the text.
    ///
    /// See also:
    ///
    ///  * ``baseline``, the baseline to align to when using
    ///    ``PlaceholderAlignment/baseline``,
    ///    [PlaceholderAlignment.aboveBaseline], or
    ///    [PlaceholderAlignment.belowBaseline].
    ///  * [baselineOffset], the distance of the alphabetic baseline from the
    ///    upper edge of the placeholder.
    var alignment: PlaceholderAlignment

    /// Distance of the ``baseline`` from the upper edge of the placeholder.
    ///
    /// Only used when [alignment] is [ui.PlaceholderAlignment.baseline].
    var baselineOffset: Double?

    /// The [TextBaseline] to align to. Used with:
    ///
    ///  * ``PlaceholderAlignment/baseline``
    ///  * [PlaceholderAlignment.aboveBaseline]
    ///  * [PlaceholderAlignment.belowBaseline]
    ///  * [PlaceholderAlignment.middle]
    var baseline: TextBaseline?
}

/// The _CaretMetrics for carets located in a non-empty paragraph. Such carets
/// are anchored to the trailing edge or the leading edge of a glyph, or a
/// ligature component.
private struct LineCaretMetrics {
    init(offset: Offset, writingDirection: TextDirection) {
        self.offset = offset
        self.writingDirection = writingDirection
    }
    /// The offset from the top left corner of the paragraph to the caret's top
    /// start location.
    let offset: Offset

    /// The writing direction of the glyph the LineCaretMetrics is associated with.
    /// The value determines whether the cursor is painted to the left or to the
    /// right of [offset].
    let writingDirection: TextDirection

    func shift(_ offset: Offset) -> LineCaretMetrics {
        return offset == .zero
            ? self
            : LineCaretMetrics(offset: offset + self.offset, writingDirection: writingDirection)
    }
}

/// An object that paints a [TextSpan] tree into a [Canvas].
///
/// To use a [TextPainter], follow these steps:
///
/// 1. Create a [TextSpan] tree and pass it to the [TextPainter] constructor.
///
/// 2. Call [layout] to prepare the paragraph.
///
/// 3. Call [paint] as often as desired to paint the paragraph.
///
/// If the width of the area into which the text is being painted changes,
/// return to step 2. If the text to be painted changes, return to step 1.
///
/// The default text style is white. To change the color of the text, pass a
/// [TextStyle] object to the [TextSpan] in `text`.
public final class TextPainter {
    public init(
        text: InlineSpan? = nil,
        textAlign: TextAlign = .start,
        textDirection: TextDirection? = .ltr,
        textScaler: any TextScaler = .noScaling,
        ellipsis: String? = nil,
        maxLines: Int? = nil,
        strutStyle: StrutStyle? = nil,
        textHeightBehavior: TextHeightBehavior? = nil,
        textWidthBasis: TextWidthBasis = .parent
    ) {
        self.text = text
        self.textAlign = textAlign
        self.textDirection = textDirection
        self.textScaler = textScaler
        self.ellipsis = ellipsis
        self.maxLines = maxLines
        self.strutStyle = strutStyle
        self.textHeightBehavior = textHeightBehavior
        self.textWidthBasis = textWidthBasis
    }

    /// The (potentially styled) text to paint.
    ///
    /// After this is set, you must call [layout] before the next call to [paint].
    /// This and [textDirection] must be non-null before you call [layout].
    ///
    /// The ``InlineSpan`` this provides is in the form of a tree that may contain
    /// multiple instances of [TextSpan]s and ``WidgetSpan``s. To obtain a plain text
    /// representation of the contents of this [TextPainter], use [plainText].
    public var text: InlineSpan? {
        didSet {
            if text === oldValue {
                return
            }
            if text?.style != oldValue?.style {
                layoutTemplate = nil
            }

            let comparison =
                if let text {
                    oldValue?.compareTo(text) ?? RenderComparison.layout
                } else {
                    RenderComparison.layout
                }

            cachedPlainText = nil

            if comparison >= RenderComparison.layout {
                markNeedsLayout()
            } else if comparison >= RenderComparison.paint {
                // Don't invalid the layoutCache just yet. It still contains valid layout
                // information.
                rebuildParagraphForPaint = true
            }
            // Neither relayout or repaint is needed.
        }
    }

    /// How the text should be aligned horizontally.
    ///
    /// After this is set, you must call [layout] before the next call to [paint].
    ///
    /// The [textAlign] property defaults to [TextAlign.start].
    public var textAlign: TextAlign {
        didSet {
            if textAlign != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// The default directionality of the text.
    ///
    /// This controls how the [TextAlign.start], [TextAlign.end], and
    /// [TextAlign.justify] values of [textAlign] are resolved.
    ///
    /// This is also used to disambiguate how to render bidirectional text. For
    /// example, if the [text] is an English phrase followed by a Hebrew phrase,
    /// in a [TextDirection.ltr] context the English phrase will be on the left
    /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
    /// context, the English phrase will be on the right and the Hebrew phrase on
    /// its left.
    ///
    /// After this is set, you must call [layout] before the next call to [paint].
    ///
    /// This and [text] must be non-null before you call [layout].
    public var textDirection: TextDirection? {
        didSet {
            if textDirection != oldValue {
                markNeedsLayout()
                layoutTemplate = nil  // Shouldn't really matter, but for strict correctness...
            }
        }
    }

    /// The font scaling strategy to use when laying out and rendering the text.
    ///
    /// The value usually comes from [MediaQuery.textScalerOf], which typically
    /// reflects the user-specified text scaling value in the platform's
    /// accessibility settings. The [TextStyle.fontSize] of the text will be
    /// adjusted by the [TextScaler] before the text is laid out and rendered.
    ///
    /// The [layout] method must be called after [textScaler] changes as it
    /// affects the text layout.
    public var textScaler: any TextScaler {
        didSet {
            if !textScaler.isEqualTo(oldValue) {
                markNeedsLayout()
                layoutTemplate = nil
            }
        }
    }

    /// The string used to ellipsize overflowing text. Setting this to a non-empty
    /// string will cause this string to be substituted for the remaining text
    /// if the text can not fit within the specified maximum width.
    ///
    /// Specifically, the ellipsis is applied to the last line before the line
    /// truncated by [maxLines], if [maxLines] is non-null and that line overflows
    /// the width constraint, or to the first line that is wider than the width
    /// constraint, if [maxLines] is null. The width constraint is the `maxWidth`
    /// passed to [layout].
    ///
    /// After this is set, you must call [layout] before the next call to [paint].
    ///
    /// The higher layers of the system, such as the ``Text`` widget, represent
    /// overflow effects using the ``TextOverflow`` enum. The
    /// [TextOverflow.ellipsis] value corresponds to setting this property to
    /// U+2026 HORIZONTAL ELLIPSIS (…).
    public var ellipsis: String? {
        didSet {
            assert(ellipsis == nil || ellipsis!.isNotEmpty)
            if ellipsis != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// The locale used to select region-specific glyphs.
    // var locale: Locale? {
    //     didSet {
    //         if locale == oldValue {
    //             return
    //         }
    //         markNeedsLayout()
    //     }
    // }

    /// An optional maximum number of lines for the text to span, wrapping if
    /// necessary.
    ///
    /// If the text exceeds the given number of lines, it is truncated such that
    /// subsequent lines are dropped.
    ///
    /// After this is set, you must call [layout] before the next call to [paint].
    public var maxLines: Int? {
        didSet {
            // The value may be null. If it is not null, then it must be greater than zero.
            assert(maxLines == nil || maxLines! > 0)
            if maxLines != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// {@template flutter.painting.textPainter.strutStyle}
    /// The strut style to use. Strut style defines the strut, which sets minimum
    /// vertical layout metrics.
    ///
    /// Omitting or providing null will disable strut.
    ///
    /// Omitting or providing null for any properties of [StrutStyle] will result in
    /// default values being used. It is highly recommended to at least specify a
    /// [StrutStyle.fontSize].
    ///
    /// See [StrutStyle] for details.
    /// {@endtemplate}
    public var strutStyle: StrutStyle? {
        didSet {
            if strutStyle != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// Defines how to measure the width of the rendered text.
    public var textWidthBasis: TextWidthBasis {
        didSet {
            // assert {
            //     debugNeedsRelayout = true
            // }
        }
    }

    /// Defines how to apply [TextStyle.height] over and under text.
    public var textHeightBehavior: TextHeightBehavior? {
        didSet {
            if textHeightBehavior != oldValue {
                markNeedsLayout()
            }
        }
    }

    private var cachedPlainText: String?

    /// Returns a plain text version of the text to paint.
    ///
    /// This uses [InlineSpan.toPlainText] to get the full contents of all nodes in the tree.
    public var plainText: String {
        if let cachedPlainText {
            return cachedPlainText
        }
        cachedPlainText = text?.toPlainText() ?? ""
        return cachedPlainText!
    }

    private var layoutCache: TextPainterLayoutCacheWithOffset?

    private var debugAssertTextLayoutIsValid: Bool {
        // assert(!debugDisposed);
        assert(layoutCache != nil, "Text layout not available")
        return true
    }

    /// Marks this text painter's layout information as dirty and removes cached
    /// information.
    ///
    /// Uses this method to notify text painter to relayout in the case of
    /// layout changes in engine. In most cases, updating text painter properties
    /// in framework will automatically invoke this method.
    private func markNeedsLayout() {
        layoutCache = nil
    }

    // Whether layoutCache contains outdated paint information and needs to be
    // updated before painting.
    //
    // Paragraph is entirely immutable, thus text style changes that can affect
    // layout and those who can't both require the ui.Paragraph object being
    // recreated. The caller may not call `layout` again after text color is
    // updated.
    private var rebuildParagraphForPaint = true

    private var placeholderDimensions: [PlaceholderDimensions] = []

    private func createParagraphStyle(_ defaultTextDirection: TextDirection? = nil)
        -> ParagraphStyle
    {
        // The defaultTextDirection argument is used for preferredLineHeight in case
        // textDirection hasn't yet been set.
        assert(
            textDirection != nil || defaultTextDirection != nil,
            "TextPainter.textDirection must be set to a non-null value before using the TextPainter."
        )
        return if let style = text!.style {
            style.toParagraphStyle(
                textAlign: textAlign,
                textDirection: textDirection ?? defaultTextDirection,
                textScaler: textScaler,
                strutStyle: strutStyle,
                maxLines: maxLines,
                ellipsis: ellipsis,
                textHeightBehavior: textHeightBehavior
                    // locale: locale,
            )
        } else {
            ParagraphStyle(
                textAlign: textAlign,
                textDirection: textDirection ?? defaultTextDirection,
                defaultSpanStyle: SpanStyle(
                    // Use the default font size to multiply by as RichText does not
                    // perform inheriting [TextStyle]s and would otherwise
                    // fail to apply textScaler.
                    fontSize: textScaler.scale(kDefaultFontSize)
                ),
                maxLines: maxLines,
                ellipsis: ellipsis,
                textHeightBehavior: textHeightBehavior
                    // locale: locale
            )
        }
    }

    private var layoutTemplate: Paragraph?
    private func createLayoutTemplate() -> Paragraph {
        let builder = backend.renderer.createParagraphBuilder(
            createParagraphStyle(TextDirection.rtl)  // direction doesn't matter, text is just a space
        )
        let textStyle = text?.style?.toSpanStyle(textScaler: textScaler)
        if let textStyle {
            builder.pushStyle(textStyle)
        }
        builder.addText(" ")
        let paragraph = builder.build()
        paragraph.layout(.width(Float.infinity))
        return paragraph
    }

    private func getOrCreateLayoutTemplate() -> Paragraph {
        layoutTemplate = layoutTemplate ?? createLayoutTemplate()
        return layoutTemplate!
    }

    private static func computePaintOffsetFraction(
        _ textAlign: TextAlign,
        _ textDirection: TextDirection
    ) -> Float {
        return switch (textAlign, textDirection) {
        case (TextAlign.left, _): 0.0
        case (TextAlign.right, _): 1.0
        case (TextAlign.center, _): 0.5
        case (TextAlign.start, TextDirection.ltr): 0.0
        case (TextAlign.start, TextDirection.rtl): 1.0
        case (TextAlign.justify, TextDirection.ltr): 0.0
        case (TextAlign.justify, TextDirection.rtl): 1.0
        case (TextAlign.end, TextDirection.ltr): 1.0
        case (TextAlign.end, TextDirection.rtl): 0.0
        }
    }

    // Creates a ui.Paragraph using the current configurations in this class and
    // assign it to _paragraph.
    private func createParagraph(_ text: InlineSpan) -> Paragraph {
        let builder = backend.renderer.createParagraphBuilder(createParagraphStyle())
        text.build(builder: builder, textScaler: textScaler, dimensions: placeholderDimensions)
        rebuildParagraphForPaint = false
        return builder.build()
    }

    /// The height of a space in [text] in logical pixels.
    ///
    /// Not every line of text in [text] will have this height, but this height
    /// is "typical" for text in [text] and useful for sizing other objects
    /// relative a typical line of text.
    ///
    /// Obtaining this value does not require calling [layout].
    ///
    /// The style of the [text] property is used to determine the font settings
    /// that contribute to the [preferredLineHeight]. If [text] is null or if it
    /// specifies no styles, the default [TextStyle] values are used (a 10 pixel
    /// sans-serif font).
    public var preferredLineHeight: Float {
        return getOrCreateLayoutTemplate().height
    }

    /// The width at which decreasing the width of the text would prevent it from
    /// painting itself completely within its bounds.
    ///
    /// Valid only after [layout] has been called.
    public var minIntrinsicWidth: Float {
        assert(debugAssertTextLayoutIsValid)
        return layoutCache!.layout.minIntrinsicLineExtent
    }

    /// The width at which increasing the width of the text no longer decreases the height.
    ///
    /// Valid only after [layout] has been called.
    public var maxIntrinsicWidth: Float {
        assert(debugAssertTextLayoutIsValid)
        return layoutCache!.layout.maxIntrinsicLineExtent
    }

    /// The horizontal space required to paint this text.
    ///
    /// Valid only after [layout] has been called.
    public var width: Float {
        assert(debugAssertTextLayoutIsValid)
        // assert(!_debugNeedsRelayout)
        return layoutCache!.contentWidth
    }

    /// The vertical space required to paint this text.
    ///
    /// Valid only after [layout] has been called.
    public var height: Float {
        assert(debugAssertTextLayoutIsValid)
        return layoutCache!.layout.height
    }

    /// The amount of space required to paint this text.
    ///
    /// Valid only after [layout] has been called.
    public var size: Size {
        assert(debugAssertTextLayoutIsValid)
        // assert(!_debugNeedsRelayout)
        return Size(width, height)
    }

    /// Whether any text was truncated or ellipsized.
    ///
    /// If [maxLines] is not null, this is true if there were more lines to be
    /// drawn than the given [maxLines], and thus at least one line was omitted in
    /// the output; otherwise it is false.
    ///
    /// If [maxLines] is null, this is true if [ellipsis] is not the empty string
    /// and there was a line that overflowed the `maxWidth` argument passed to
    /// [layout]; otherwise it is false.
    ///
    /// Valid only after [layout] has been called.
    public var didExceedMaxLines: Bool {
        assert(debugAssertTextLayoutIsValid)
        return layoutCache!.paragraph.didExceedMaxLines
    }

    /// Computes the visual position of the glyphs for painting the text.
    ///
    /// The text will layout with a width that's as close to its max intrinsic
    /// width (or its longest line, if [textWidthBasis] is set to
    /// [TextWidthBasis.parent]) as possible while still being greater than or
    /// equal to `minWidth` and less than or equal to `maxWidth`.
    ///
    /// The [text] and [textDirection] properties must be non-null before this
    /// is called.
    public func layout(minWidth: Float = 0, maxWidth: Float = Float.infinity) {
        assert(!maxWidth.isNaN)
        assert(!minWidth.isNaN)
        assert(minWidth <= maxWidth)

        if layoutCache != nil {
            if layoutCache!.resizeToFit(
                minWidth: minWidth,
                maxWidth: maxWidth,
                widthBasis: textWidthBasis
            ) {
                return
            }
        }

        guard let text else {
            assertionFailure(
                "TextPainter.text must be set to a non-null value before using the TextPainter."
            )
            return
        }
        guard let textDirection else {
            assertionFailure(
                "TextPainter.textDirection must be set to a non-null value before using the TextPainter."
            )
            return
        }

        let paintOffsetAlignment = Self.computePaintOffsetFraction(textAlign, textDirection)
        // Try to avoid laying out the paragraph with maxWidth=double.infinity
        // when the text is not left-aligned, so we don't have to deal with an
        // infinite paint offset.
        let adjustMaxWidth = !maxWidth.isFinite && paintOffsetAlignment != 0
        let adjustedMaxWidth =
            if !adjustMaxWidth {
                maxWidth
            } else {
                layoutCache?.layout.maxIntrinsicLineExtent
            }
        let layoutMaxWidth = adjustedMaxWidth ?? maxWidth

        // Only rebuild the paragraph when there're layout changes, even when
        // `_rebuildParagraphForPaint` is true. It's best to not eagerly rebuild
        // the paragraph to avoid the extra work, because:
        // 1. the text color could change again before `paint` is called (so one of
        //    the paragraph rebuilds is unnecessary)
        // 2. the user could be measuring the text layout so `paint` will never be
        //    called.
        let paragraph = (layoutCache?.paragraph ?? createParagraph(text))
        paragraph.layout(.width(layoutMaxWidth))
        let layout = TextLayout(
            writingDirection: textDirection,
            painter: self,
            paragraph: paragraph
        )
        let contentWidth = layout.contentWidthFor(
            minWidth: minWidth,
            maxWidth: maxWidth,
            widthBasis: textWidthBasis
        )

        // Call layout again if newLayoutCache had an infinite paint offset.
        // This is not as expensive as it seems, line breaking is relatively cheap
        // as compared to shaping.

        if adjustedMaxWidth == nil && minWidth.isFinite {
            assert(maxWidth.isInfinite)
            let newInputWidth = layout.maxIntrinsicLineExtent
            paragraph.layout(.width(newInputWidth))
            layoutCache = TextPainterLayoutCacheWithOffset(
                layout: layout,
                textAlignment: paintOffsetAlignment,
                layoutMaxWidth: newInputWidth,
                contentWidth: contentWidth
            )
        } else {
            layoutCache = TextPainterLayoutCacheWithOffset(
                layout: layout,
                textAlignment: paintOffsetAlignment,
                layoutMaxWidth: layoutMaxWidth,
                contentWidth: contentWidth
            )
        }
    }

    public func paint(_ canvas: Canvas, offset: Offset) {
        assert(
            layoutCache != nil,
            "TextPainter.paint called when text geometry was not yet calculated.\n"
                + "Please call layout() before paint() to position the text before painting it."
        )

        guard layoutCache!.paintOffset.dx.isFinite && layoutCache!.paintOffset.dy.isFinite else {
            return
        }

        if rebuildParagraphForPaint {
            let paragraph = layoutCache!.paragraph
            // Unfortunately even if we know that there is only paint changes, there's
            // no API to only make those updates so the paragraph has to be recreated
            // and re-laid out.
            assert(!layoutCache!.layoutMaxWidth.isNaN)
            layoutCache!.layout.paragraph = createParagraph(text!)
            layoutCache!.layout.paragraph.layout(.width(layoutCache!.layoutMaxWidth))
            assert(paragraph.width == layoutCache!.layout.paragraph.width)
        }
        assert(rebuildParagraphForPaint == false)
        canvas.drawParagraph(layoutCache!.paragraph, offset + layoutCache!.paintOffset)
    }

    // Returns true if value falls in the valid range of the UTF16 encoding.
    static func _isUTF16(_ value: Int) -> Bool {
        return value >= 0x0 && value <= 0xFFFFF
    }

    /// Returns true iff the given value is a valid UTF-16 high (first) surrogate.
    /// The value must be a UTF-16 code unit, meaning it must be in the range
    /// 0x0000-0xFFFF.
    ///
    /// See also:
    ///   * https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
    ///   * [isLowSurrogate], which checks the same thing for low (second)
    /// surrogates.
    static func isHighSurrogate(_ value: Int) -> Bool {
        assert(_isUTF16(value))
        return value & 0xFC00 == 0xD800
    }

    /// Returns true iff the given value is a valid UTF-16 low (second) surrogate.
    /// The value must be a UTF-16 code unit, meaning it must be in the range
    /// 0x0000-0xFFFF.
    ///
    /// See also:
    ///   * https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
    ///   * [isHighSurrogate], which checks the same thing for high (first)
    /// surrogates.
    static func isLowSurrogate(_ value: Int) -> Bool {
        assert(_isUTF16(value))
        return value & 0xFC00 == 0xDC00
    }

    /// Returns the offset at which to paint the caret.
    ///
    /// Valid only after [layout] has been called.
    public func getOffsetForCaret(_ position: TextPosition, _ caretPrototype: Rect) -> Offset {
        let caretMetrics = _computeCaretMetrics(position)

        guard let caretMetrics else {
            let paintOffsetAlignment = Self.computePaintOffsetFraction(textAlign, textDirection!)
            // The full width is not (width - caretPrototype.width), because
            // RenderEditable reserves cursor width on the right. Ideally this
            // should be handled by RenderEditable instead.
            let dx =
                paintOffsetAlignment == 0 ? 0 : paintOffsetAlignment * layoutCache!.contentWidth
            return Offset(dx, 0.0)
        }

        let rawOffset =
            switch caretMetrics.writingDirection {
            case .ltr:
                caretMetrics.offset
            case .rtl:
                Offset(caretMetrics.offset.dx - caretPrototype.width, caretMetrics.offset.dy)
            }

        // If offset.dx is outside of the advertised content area, then the associated
        // glyph belongs to a trailing whitespace character. Ideally the behavior
        // should be handled by higher-level implementations (for instance,
        // RenderEditable reserves width for showing the caret, it's best to handle
        // the clamping there).
        let adjustedDx = (rawOffset.dx + layoutCache!.paintOffset.dx).clamped(
            to: 0...layoutCache!.contentWidth
        )
        return Offset(adjustedDx, rawOffset.dy + layoutCache!.paintOffset.dy)
    }

    /// Returns the strut bounded height of the glyph at the given `position`.
    ///
    /// Valid only after [layout] has been called.
    public func getFullHeightForCaret(_ position: TextPosition, _ caretPrototype: Rect) -> Float {
        let textBox = getOrCreateLayoutTemplate().getBoxesForRange(
            .zero,
            .init(utf16Offset: 1),
            boxHeightStyle: .strut,
            boxWidthStyle: .tight
        )
        .first!
        return textBox.toRect().height
    }

    private func isNewlineAtOffset(_ offset: TextIndex) -> Bool {
        return .zero <= offset && offset.utf16Offset < plainText.utf16.count
            && WordBoundary._isNewline(
                plainText.codeUnitAt(offset)
            )
    }

    // Cached caret metrics. This allows multiple invokes of [getOffsetForCaret] and
    // [getFullHeightForCaret] in a row without performing redundant and expensive
    // get rect calls to the paragraph.
    //
    // The cache implementation assumes there's only one cursor at any given time.
    private var caretMetrics: LineCaretMetrics!

    // This function returns the caret's offset and height for the given
    // `position` in the text, or nil if the paragraph is empty.
    //
    // For a TextPosition, typically when its TextAffinity is downstream, the
    // corresponding I-beam caret is anchored to the leading edge of the character
    // at `offset` in the text. When the TextAffinity is upstream, the I-beam is
    // then anchored to the trailing edge of the preceding character, except for a
    // few edge cases:
    //
    // 1. empty paragraph: this method returns nil and the caller handles this
    //    case.
    //
    // 2. (textLength, downstream), the end-of-text caret when the text is not
    //    empty: it's placed next to the trailing edge of the last line of the
    //    text, in case the text and its last bidi run have different writing
    //    directions. See the `computeEndOfTextCaretAnchorOffset` method for more
    //    details.
    //
    // 3. (0, upstream), which isn't a valid position, but it's not a conventional
    //    "invalid" caret location either (the offset isn't negative). For
    //    historical reasons, this is treated as (0, downstream).
    //
    // 4. (x, upstream) where x - 1 points to a line break character. The caret
    //    should be displayed at the beginning of the newline instead of at the
    //    end of the previous line. Converts the location to (x, downstream). The
    //    choice we makes in 5. allows us to still check (x - 1) in case x points
    //    to a multi-code-unit character.
    //
    // 5. (x, downstream || upstream), where x points to a multi-code-unit
    //    character. There's no perfect caret placement in this case. Here we chose
    //    to draw the caret at the location that makes the most sense when the
    //    user wants to backspace (which also means it's left-arrow-key-biased):
    //
    //     * downstream: show the caret at the leading edge of the character only if
    //       x points to the start of the grapheme. Otherwise show the caret at the
    //       leading edge of the next logical character.
    //     * upstream: show the caret at the trailing edge of the previous character
    //       only if x points to the start of the grapheme. Otherwise place the
    //       caret at the trailing edge of the character.
    private func _computeCaretMetrics(_ position: TextPosition) -> LineCaretMetrics? {
        assert(debugAssertTextLayoutIsValid)
        // assert(!_debugNeedsRelayout)

        // If nothing is laid out, top start is the only reasonable place to place
        // the cursor.
        // The HTML renderer reports numberOfLines == 1 when the text is empty:
        // https://github.com/flutter/flutter/issues/143331
        if layoutCache!.paragraph.numberOfLines < 1 || plainText.isEmpty {
            // TODO(LongCatIsLooong): assert when an invalid position is given.
            return nil
        }

        let (offset, anchorToLeadingEdge): (TextIndex, Bool)
        switch position {
        case let pos where pos.offset == .zero:
            (offset, anchorToLeadingEdge) = (.zero, true)  // As a special case, always anchor to the leading edge of the first grapheme regardless of the affinity.
        case let pos where pos.affinity == .downstream:
            (offset, anchorToLeadingEdge) = (pos.offset, true)
        case let pos
        where pos.affinity == .upstream && isNewlineAtOffset(pos.offset.advanced(by: -1)):
            (offset, anchorToLeadingEdge) = (pos.offset, true)
        case let pos where pos.affinity == .upstream:
            (offset, anchorToLeadingEdge) = (pos.offset.advanced(by: -1), false)
        default:
            fatalError("Unexpected case")
        }

        let caretPositionCacheKey =
            anchorToLeadingEdge ? offset : .init(utf16Offset: -offset.utf16Offset - 1)
        if caretPositionCacheKey == layoutCache!.previousCaretPositionKey {
            return caretMetrics
        }

        let glyphInfo = layoutCache!.paragraph.getGlyphInfoAt(offset)

        if glyphInfo == nil {
            // If the glyph isn't laid out, then the position points to a character
            // that is not laid out. Use the EOT caret.
            // TODO(LongCatIsLooong): assert when an invalid position is given.
            let template = getOrCreateLayoutTemplate()
            assert(template.numberOfLines == 1)
            let baselineOffset = template.getLineMetricsAt(line: 0)!.baseline
            return layoutCache!.layout.endOfTextCaretMetrics.shift(Offset(0.0, -baselineOffset))
        }

        let graphemeRange = glyphInfo!.graphemeClusterCodeUnitRange

        // Works around a SkParagraph bug (https://github.com/flutter/flutter/issues/120836#issuecomment-1937343854):
        // placeholders with a size of (0, 0) always have a rect of Rect.zero and a
        // range of (0, 0).
        if graphemeRange.isCollapsed {
            assert(graphemeRange.start == .zero)
            return _computeCaretMetrics(TextPosition(offset: offset.advanced(by: 1)))
        }
        if anchorToLeadingEdge && graphemeRange.start != offset {
            assert(graphemeRange.end > graphemeRange.start.advanced(by: 1))
            // Addresses the case where `offset` points to a multi-code-unit grapheme
            // that doesn't start at `offset`.
            return _computeCaretMetrics(TextPosition(offset: graphemeRange.end))
        }

        let metrics: LineCaretMetrics
        let boxes = layoutCache!.paragraph
            .getBoxesForRange(
                graphemeRange.start,
                graphemeRange.end,
                boxHeightStyle: .strut,
                boxWidthStyle: .tight
            )

        if !boxes.isEmpty {
            let anchorToLeft: Bool
            switch glyphInfo!.writingDirection {
            case .ltr:
                anchorToLeft = anchorToLeadingEdge
            case .rtl:
                anchorToLeft = !anchorToLeadingEdge
            }
            let box = anchorToLeft ? boxes.first! : boxes.last!
            metrics = LineCaretMetrics(
                offset: Offset(anchorToLeft ? box.left : box.right, box.top),
                writingDirection: box.direction
            )
        } else {
            // Fall back to glyphInfo. This should only happen when using the HTML renderer.
            let graphemeBounds = glyphInfo!.graphemeClusterLayoutBounds
            let dx =
                switch glyphInfo!.writingDirection {
                case .ltr:
                    anchorToLeadingEdge ? graphemeBounds.left : graphemeBounds.right
                case .rtl:
                    anchorToLeadingEdge ? graphemeBounds.right : graphemeBounds.left
                }
            metrics = LineCaretMetrics(
                offset: Offset(dx, graphemeBounds.top),
                writingDirection: glyphInfo!.writingDirection
            )
        }

        layoutCache!.previousCaretPositionKey = caretPositionCacheKey
        caretMetrics = metrics
        return metrics
    }

    /// Returns a list of rects that bound the given selection.
    ///
    /// The [selection] must be a valid range (with [TextSelection.isValid] true).
    ///
    /// The [boxHeightStyle] and [boxWidthStyle] arguments may be used to select
    /// the shape of the [TextBox]s. These properties default to
    /// [ui.BoxHeightStyle.tight] and [ui.BoxWidthStyle.tight] respectively.
    ///
    /// A given selection might have more than one rect if this text painter
    /// contains bidirectional text because logically contiguous text might not be
    /// visually contiguous.
    ///
    /// Leading or trailing newline characters will be represented by zero-width
    /// `TextBox`es.
    ///
    /// The method only returns `TextBox`es of glyphs that are entirely enclosed by
    /// the given `selection`: a multi-code-unit glyph will be excluded if only
    /// part of its code units are in `selection`.
    func getBoxesForSelection(
        _ selection: TextSelection,
        boxHeightStyle: BoxHeightStyle = .tight,
        boxWidthStyle: BoxWidthStyle = .tight
    ) -> [TextBox] {
        assert(debugAssertTextLayoutIsValid)
        // assert(!debugNeedsRelayout)
        let offset = layoutCache!.paintOffset
        if !offset.dx.isFinite || !offset.dy.isFinite {
            return []
        }
        let boxes = layoutCache!.paragraph.getBoxesForRange(
            selection.range.start,
            selection.range.end,
            boxHeightStyle: boxHeightStyle,
            boxWidthStyle: boxWidthStyle
        )
        return offset == .zero
            ? boxes
            : boxes.map { box in Self.shiftTextBox(box, offset) }
    }

    /// Returns the closest position within the text for the given pixel offset.
    public func getPositionForOffset(_ offset: Offset) -> TextPosition {
        assert(debugAssertTextLayoutIsValid)
        // assert(!_debugNeedsRelayout);
        return layoutCache!.paragraph.getPositionForOffset(offset - layoutCache!.paintOffset)
    }

    /// Returns the text range of the word at the given offset. Characters not
    /// part of a word, such as spaces, symbols, and punctuation, have word breaks
    /// on both sides. In such cases, this method will return a text range that
    /// contains the given text position.
    ///
    /// Word boundaries are defined more precisely in Unicode Standard Annex #29
    /// <http://www.unicode.org/reports/tr29/#Word_Boundaries>.
    public func getWordBoundary(_ position: TextPosition) -> TextRange {
        assert(debugAssertTextLayoutIsValid)
        return layoutCache!.paragraph.getWordBoundary(position)
    }

    /// Returns a TextBoundary that can be used to perform word boundary analysis
    /// on the current text.
    ///
    /// This TextBoundary uses word boundary rules defined in Unicode Standard
    /// Annex #29 (http://www.unicode.org/reports/tr29/#Word_Boundaries).
    ///
    /// Currently word boundary analysis can only be performed after layout
    /// has been called.
    var wordBoundaries: WordBoundary {
        return WordBoundary(text!, layoutCache!.paragraph)
    }

    /// Returns the text range of the line at the given offset.
    ///
    /// The newline (if any) is not returned as part of the range.
    public func getLineBoundary(_ position: TextPosition) -> TextRange? {
        assert(debugAssertTextLayoutIsValid)
        return layoutCache!.paragraph.getLineBoundary(position)
    }

    static func shiftTextBox(_ box: TextBox, _ offset: Offset) -> TextBox {
        assert(offset.dx.isFinite)
        assert(offset.dy.isFinite)
        return TextBox(
            left: box.left + offset.dx,
            top: box.top + offset.dy,
            right: box.right + offset.dx,
            bottom: box.bottom + offset.dy,
            direction: box.direction
        )
    }

    static func shiftLineMetrics(_ metrics: LineMetrics, offset: Offset) -> LineMetrics {
        assert(offset.dx.isFinite)
        assert(offset.dy.isFinite)
        return LineMetrics(
            startIndex: metrics.startIndex,
            endIndex: metrics.endIndex,
            endIncludingNewline: metrics.endIncludingNewline,
            endExcludingWhitespace: metrics.endExcludingWhitespace,
            hardBreak: metrics.hardBreak,
            ascent: metrics.ascent,
            descent: metrics.descent,
            unscaledAscent: metrics.unscaledAscent,
            height: metrics.height,
            width: metrics.width,
            left: metrics.left + offset.dx,
            baseline: metrics.baseline + offset.dy,
            lineNumber: metrics.lineNumber
        )
    }

    /// Returns the full list of [LineMetrics] that describe in detail the various
    /// metrics of each laid out line.
    ///
    /// The [LineMetrics] list is presented in the order of the lines they represent.
    /// For example, the first line is in the zeroth index.
    ///
    /// [LineMetrics] contains measurements such as ascent, descent, baseline, and
    /// width for the line as a whole, and may be useful for aligning additional
    /// widgets to a particular line.
    ///
    /// Valid only after [layout] has been called.
    public func computeLineMetrics() -> [LineMetrics] {
        assert(debugAssertTextLayoutIsValid)
        // assert(!debugNeedsRelayout)
        let offset = layoutCache!.paintOffset
        if !offset.dx.isFinite || !offset.dy.isFinite {
            return []
        }
        let rawMetrics = layoutCache!.lineMetrics
        return offset == .zero
            ? rawMetrics
            : rawMetrics.map { metrics in Self.shiftLineMetrics(metrics, offset: offset) }
    }
}

/// A TextBoundary subclass for locating word breaks.
///
/// The underlying implementation uses [UAX #29](https://unicode.org/reports/tr29/)
/// defined default word boundaries.
///
/// The default word break rules can be tailored to meet the requirements of
/// different use cases. For instance, the default rule set keeps horizontal
/// whitespaces together as a single word, which may not make sense in a
/// word-counting context -- "hello    world" counts as 3 words instead of 2.
/// An example is the moveByWordBoundary variant, which is a tailored
/// word-break locator that more closely matches the default behavior of most
/// platforms and editors when it comes to handling text editing keyboard
/// shortcuts that move or delete word by word.
class WordBoundary: TextBoundary {
    /// Creates a WordBoundary with the text and layout information.
    init(_ text: InlineSpan, _ paragraph: Paragraph) {
        self._text = text
        self._paragraph = paragraph
    }

    private let _text: InlineSpan
    private let _paragraph: Paragraph

    func getTextBoundaryAt(_ position: TextIndex) -> TextRange? {
        return _paragraph.getWordBoundary(TextPosition(offset: max(position, .zero)))
    }

    // Combines two UTF-16 code units (high surrogate + low surrogate) into a
    // single code point that represents a supplementary character.

    static func _codePointFromSurrogates(_ highSurrogate: Int, _ lowSurrogate: Int) -> Int {
        assert(
            TextPainter.isHighSurrogate(highSurrogate),
            "U+\(String(format: "%04X", highSurrogate)) is not a high surrogate."
        )
        assert(
            TextPainter.isLowSurrogate(lowSurrogate),
            "U+\(String(format: "%04X", lowSurrogate)) is not a low surrogate."
        )
        let base = 0x010000 - (0xD800 << 10) - 0xDC00
        return (highSurrogate << 10) + lowSurrogate + base
    }

    // The Runes class does not provide random access with a code unit offset.

    func _codePointAt(_ index: TextIndex) -> Int? {
        guard let codeUnitAtIndex = _text.codeUnitAt(index) else {
            return nil
        }
        switch codeUnitAtIndex & 0xFC00 {
        case 0xD800:
            return WordBoundary._codePointFromSurrogates(
                codeUnitAtIndex,
                _text.codeUnitAt(index.advanced(by: 1))!
            )
        case 0xDC00:
            return WordBoundary._codePointFromSurrogates(
                _text.codeUnitAt(index.advanced(by: -1))!,
                codeUnitAtIndex
            )
        default:
            return codeUnitAtIndex
        }
    }

    static func _isNewline(_ codePoint: Int) -> Bool {
        // Carriage Return is not treated as a hard line break.
        switch codePoint {
        case 0x000A,  // Line Feed
            0x0085,  // New Line
            0x000B,  // Form Feed
            0x000C,  // Vertical Feed
            0x2028,  // Line Separator
            0x2029:  // Paragraph Separator
            return true
        default:
            return false
        }
    }

    func _skipSpacesAndPunctuations(_ offset: TextIndex, _ forward: Bool) -> Bool {
        // Use code point since some punctuations are supplementary characters.
        // "inner" here refers to the code unit that's before the break in the
        // search direction (`forward`).
        let innerCodePoint = _codePointAt(forward ? offset.advanced(by: -1) : offset)
        let outerCodeUnit = _text.codeUnitAt(forward ? offset : offset.advanced(by: -1))

        // Make sure the hard break rules in UAX#29 take precedence over the ones we
        // add below. Luckily there're only 4 hard break rules for word breaks, and
        // dictionary based breaking does not introduce new hard breaks:
        // https://unicode-org.github.io/icu/userguide/boundaryanalysis/break-rules.html#word-dictionaries
        //
        // WB1 & WB2: always break at the start or the end of the text.
        let hardBreakRulesApply =
            innerCodePoint == nil || outerCodeUnit == nil
            // WB3a & WB3b: always break before and after newlines.
            || WordBoundary._isNewline(innerCodePoint!) || WordBoundary._isNewline(outerCodeUnit!)
        return hardBreakRulesApply
            || CharacterSet.punctuationCharacters.contains((Unicode.Scalar(innerCodePoint!)!))
            || CharacterSet.whitespaces.contains((Unicode.Scalar(innerCodePoint!)!))
    }

    /// Returns a TextBoundary suitable for handling keyboard navigation
    /// commands that change the current selection word by word.
    ///
    /// This TextBoundary is used by text widgets in the flutter framework to
    /// provide default implementation for text editing shortcuts, for example,
    /// "delete to the previous word".
    ///
    /// The implementation applies the same set of rules WordBoundary uses,
    /// except that word breaks end on a space separator or a punctuation will be
    /// skipped, to match the behavior of most platforms. Additional rules may be
    /// added in the future to better match platform behaviors.
    lazy var moveByWordBoundary: TextBoundary = _UntilTextBoundary(self, _skipSpacesAndPunctuations)
}

class _UntilTextBoundary: TextBoundary {
    init(_ textBoundary: TextBoundary, _ predicate: @escaping (TextIndex, Bool) -> Bool) {
        self._textBoundary = textBoundary
        self._predicate = predicate
    }

    private let _predicate: (TextIndex, Bool) -> Bool
    private let _textBoundary: TextBoundary

    func getLeadingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        if position < .zero {
            return nil
        }
        guard let offset = _textBoundary.getLeadingTextBoundaryAt(position) else {
            return nil
        }
        return _predicate(offset, false)
            ? offset
            : getLeadingTextBoundaryAt(offset.advanced(by: -1))
    }

    func getTrailingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        guard let offset = _textBoundary.getTrailingTextBoundaryAt(max(position, .zero)) else {
            return nil
        }
        return _predicate(offset, true) ? offset : getTrailingTextBoundaryAt(offset)
    }
}

private struct TextLayout {
    let writingDirection: TextDirection

    // Computing plainText is a bit expensive and is currently not needed for
    // simple static text. Pass in the entire text painter so `TextPainter.plainText`
    // is only called when needed.
    unowned let painter: TextPainter

    // This field is not final because the owner TextPainter could create a new
    // ui.Paragraph with the exact same text layout (for example, when only the
    // color of the text is changed).
    //
    // The creator of this TextLayout is also responsible for disposing this
    // object when it's no logner needed.
    var paragraph: Paragraph

    /// The horizontal space required to paint this text.
    ///
    /// If a line ends with trailing spaces, the trailing spaces may extend
    /// outside of the horizontal paint bounds defined by [width].
    var width: Float { paragraph.width }

    /// The vertical space required to paint this text.
    var height: Float { paragraph.height }

    /// The width at which decreasing the width of the text would prevent it from
    /// painting itself completely within its bounds.
    var minIntrinsicLineExtent: Float { paragraph.minIntrinsicWidth }

    /// The width at which increasing the width of the text no longer decreases the height.
    ///
    /// Includes trailing spaces if any.
    var maxIntrinsicLineExtent: Float { paragraph.maxIntrinsicWidth }

    /// The distance from the left edge of the leftmost glyph to the right edge of
    /// the rightmost glyph in the paragraph.
    var longestLine: Float { paragraph.longestLine }

    /// Returns the distance from the top of the text to the first baseline of the
    /// given type.
    func getDistanceToBaseline(_ baseline: TextBaseline) -> Float {
        return switch baseline {
        case .alphabetic: paragraph.alphabeticBaseline
        case .ideographic: paragraph.ideographicBaseline
        }
    }

    /// The line caret metrics representing the end of text location.
    ///
    /// This is usually used when the caret is placed at the end of the text
    /// (text.length, downstream), unless maxLines is set to a non-nil value, in
    /// which case the caret is placed at the visual end of the last visible line.
    ///
    /// This should not be called when the paragraph is empty as the implementation
    /// relies on line metrics.
    ///
    /// When the last bidi level run in the paragraph and the paragraph's bidi
    /// levels have opposite parities (which implies opposite writing directions),
    /// this makes sure the caret is placed at the same "end" of the line as if the
    /// line ended with a line feed.
    lazy var endOfTextCaretMetrics: LineCaretMetrics = computeEndOfTextCaretAnchorOffset()

    private func computeEndOfTextCaretAnchorOffset() -> LineCaretMetrics {
        let rawString = painter.plainText
        let lastLineIndex = paragraph.numberOfLines - 1
        assert(lastLineIndex >= 0)
        let lineMetrics = paragraph.getLineMetricsAt(line: lastLineIndex)!
        // Trailing white spaces don't contribute to the line width and thus require special handling
        // when they're present.
        // Luckily they have the same bidi embedding level as the paragraph as per
        // https://unicode.org/reports/tr9/#L1, so we can anchor the caret to the
        // last logical trailing space.
        let hasTrailingSpaces =
            switch rawString.codeUnitAt(.init(utf16Offset: rawString.utf16.count - 1)) {
            case 0x9, 0x3000, 0x20: true  // horizontal tab, ideographic space, space
            default: false
            }

        let baseline = lineMetrics.baseline
        let lastGlyph = paragraph.getGlyphInfoAt(
            .init(utf16Offset: rawString.utf16.count - 1)
        )
        // TODO(LongCatIsLooong): handle the case where maxLine is set to non-nil
        // and the last line ends with trailing whitespaces.
        let dx: Float
        if hasTrailingSpaces && lastGlyph != nil {
            let glyphBounds = lastGlyph!.graphemeClusterLayoutBounds
            assert(!glyphBounds.isEmpty)

            dx =
                switch writingDirection {
                case .ltr: glyphBounds.right
                case .rtl: glyphBounds.left
                }
        } else {

            dx =
                switch writingDirection {
                case .ltr: lineMetrics.left + lineMetrics.width
                case .rtl: lineMetrics.left
                }
        }
        return LineCaretMetrics(
            offset: Offset(dx, baseline),
            writingDirection: writingDirection
        )
    }

    func contentWidthFor(minWidth: Float, maxWidth: Float, widthBasis: TextWidthBasis) -> Float {
        switch widthBasis {
        case .longestLine:
            return longestLine.clamped(to: minWidth...maxWidth)
        case .parent:
            return maxIntrinsicLineExtent.clamped(to: minWidth...maxWidth)
        }
    }

}

// This struct stores the current text layout and the corresponding
// paintOffset/contentWidth, as well as some cached text metrics values that
// depends on the current text layout, which will be invalidated as soon as the
// text layout is invalidated.
private struct TextPainterLayoutCacheWithOffset {
    internal init(
        layout: TextLayout,
        textAlignment: Float,
        layoutMaxWidth: Float,
        contentWidth: Float
    ) {
        self.layout = layout
        self.textAlignment = textAlignment
        self.layoutMaxWidth = layoutMaxWidth
        self.contentWidth = contentWidth
    }

    var layout: TextLayout

    // The input width used to lay out the paragraph.
    let layoutMaxWidth: Float

    /// The effective text alignment in the TextPainter's canvas. The value is
    /// within the [0, 1] interval: 0 for left aligned and 1 for right aligned.
    let textAlignment: Float

    // The content width the text painter should report in TextPainter.width.
    // This is also used to compute `paintOffset`
    public private(set) var contentWidth: Float

    var paragraph: Paragraph { layout.paragraph }

    // The paintOffset of the `paragraph` in the TextPainter's canvas.
    //
    // It's coordinate values are guaranteed to not be NaN.
    var paintOffset: Offset {
        if textAlignment == 0 {
            return Offset.zero
        }
        if !paragraph.width.isFinite {
            return Offset(Float.infinity, 0.0)
        }
        let dx = textAlignment * (contentWidth - paragraph.width)
        assert(!dx.isNaN)
        return Offset(dx, 0)
    }

    // Try to resize the contentWidth to fit the new input constraints, by just
    // adjusting the paint offset (so no line-breaking changes needed).
    //
    // Returns false if the new constraints require the text layout library to
    // re-compute the line breaks.
    mutating func resizeToFit(minWidth: Float, maxWidth: Float, widthBasis: TextWidthBasis)
        -> Bool
    {
        assert(layout.maxIntrinsicLineExtent.isFinite)
        assert(minWidth <= maxWidth)
        // The assumption here is that if a Paragraph's width is already >= its
        // maxIntrinsicWidth, further increasing the input width does not change its
        // layout (but may change the paint offset if it's not left-aligned). This is
        // true even for TextAlign.justify: when width >= maxIntrinsicWidth
        // TextAlign.justify will behave exactly the same as TextAlign.start.
        //
        // An exception to this is when the text is not left-aligned, and the input
        // width is Float.infinity. Since the resulting Paragraph will have a width
        // of Float.infinity, and to make the text visible the paintOffset.dx is
        // bound to be Float.negativeInfinity, which invalidates all arithmetic
        // operations.

        if maxWidth == contentWidth && minWidth == contentWidth {
            contentWidth = layout.contentWidthFor(
                minWidth: minWidth,
                maxWidth: maxWidth,
                widthBasis: widthBasis
            )
            return true
        }

        // Special case:
        // When the paint offset and the paragraph width are both +∞, it's likely
        // that the text layout engine skipped layout because there weren't anything
        // to paint. Always try to re-compute the text layout.
        if !paintOffset.dx.isFinite && !paragraph.width.isFinite && minWidth.isFinite {
            assert(paintOffset.dx == Float.infinity)
            assert(paragraph.width == Float.infinity)
            return false
        }

        let maxIntrinsicWidth = paragraph.maxIntrinsicWidth
        // Skip line breaking if the input width remains the same, of there will be
        // no soft breaks.
        let skipLineBreaking =
            maxWidth == layoutMaxWidth  // Same input max width so relayout is unnecessary.
            || ((paragraph.width - maxIntrinsicWidth) > -precisionErrorTolerance
                && (maxWidth - maxIntrinsicWidth) > -precisionErrorTolerance)
        if skipLineBreaking {
            // Adjust the content width in case the TextWidthBasis changed.
            contentWidth = layout.contentWidthFor(
                minWidth: minWidth,
                maxWidth: maxWidth,
                widthBasis: widthBasis
            )
            return true
        }
        return false
    }

    // ---- Cached Values ----

    lazy var lineMetrics: [LineMetrics] = paragraph.computeLineMetrics()

    // Used to determine whether the caret metrics cache should be invalidated.
    var previousCaretPositionKey: TextIndex?
}
