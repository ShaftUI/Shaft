import Shaft

private let placeholderChar = "\u{FFFC}"

/// Builds a [CanvasParagraph] containing text with the given styling
/// information.
class Canvas2DParagraphBuilder: ParagraphBuilder {
    /// Creates a [CanvasParagraphBuilder] object, which is used to create a
    /// [CanvasParagraph].
    init(style: ParagraphStyle) {
        self._paragraphStyle = style
        self._rootStyleNode = RootStyleNode(style)
    }

    private let _plainTextBuffer = StringBuilder()
    private let _paragraphStyle: ParagraphStyle

    private var _spans: [ParagraphSpanProtocol] = []
    private var _styleStack: [StyleNode] = []

    private let _rootStyleNode: RootStyleNode
    private var _currentStyleNode: StyleNode {
        return _styleStack.isEmpty ? _rootStyleNode : _styleStack.last!
    }

    public var placeholderCount: Int { _placeholderCount }
    private var _placeholderCount: Int = 0

    public var placeholderScales: [Float] { _placeholderScales }
    private var _placeholderScales: [Float] = []

    func addPlaceholder(
        width: Float,
        height: Float,
        alignment: PlaceholderAlignment,
        scale: Float = 1.0,
        baselineOffset: Float? = nil,
        baseline: TextBaseline? = nil
    ) {
        // Require a baseline to be specified if using a baseline-based alignment.
        assert(
            !(alignment == PlaceholderAlignment.aboveBaseline
                || alignment == PlaceholderAlignment.belowBaseline
                || alignment == PlaceholderAlignment.baseline) || baseline != nil
        )

        let start = TextIndex(utf16Offset: _plainTextBuffer.buffer.utf16.count)
        _plainTextBuffer.append(placeholderChar)
        let end = TextIndex(utf16Offset: _plainTextBuffer.buffer.utf16.count)

        let style = _currentStyleNode.resolveStyle()

        _placeholderCount += 1
        _placeholderScales.append(scale)
        _spans.append(
            PlaceholderSpan(
                style: style,
                start: start,
                end: end,
                width: width * scale,
                height: height * scale,
                alignment: alignment,
                baselineOffset: (baselineOffset ?? height) * scale,
                baseline: baseline ?? TextBaseline.alphabetic
            )
        )
    }

    public func pushStyle(_ style: SpanStyle) {
        _styleStack.append(_currentStyleNode.createChild(style))
    }

    public func pop() {
        if !_styleStack.isEmpty {
            _styleStack.removeLast()
        }
    }

    public func addText(_ text: String) {
        let start = TextIndex(utf16Offset: _plainTextBuffer.buffer.utf16.count)
        _plainTextBuffer.append(text)
        let end = TextIndex(utf16Offset: _plainTextBuffer.buffer.utf16.count)

        let style = _currentStyleNode.resolveStyle()

        _spans.append(ParagraphSpan(style: style, start: start, end: end))
    }

    func build() -> Shaft.Paragraph {
        if _spans.isEmpty {
            // In case `addText` and `addPlaceholder` were never called.
            //
            // We want the paragraph to always have a non-empty list of spans to match
            // the expectations of the [LayoutFragmenter].
            _spans.append(
                ParagraphSpan(
                    style: _rootStyleNode.resolveStyle(),
                    start: TextIndex.zero,
                    end: TextIndex.zero
                )
            )
        }

        return CanvasParagraph(
            spans: _spans,
            paragraphStyle: _paragraphStyle,
            plainText: _plainTextBuffer.build()
        )
    }
}

/// Represents a span in the paragraph.
///
/// Instead of keeping spans and styles in a tree hierarchy like the framework
/// does, we flatten the structure and resolve/merge all the styles from parent
/// nodes.
///
/// These spans are stored as a flat list in the paragraph object.
protocol ParagraphSpanProtocol {
    /// The resolved style of the span.
    var style: SpanStyle { get }

    /// The index of the beginning of the range of text represented by this span.
    var start: TextIndex { get }

    /// The index of the end of the range of text represented by this span.
    var end: TextIndex { get }
}

/// Default implementation of ParagraphSpan
struct ParagraphSpan: ParagraphSpanProtocol {
    /// Creates a [ParagraphSpan] with the given [style], representing the span of
    /// text in the range between [start] and [end].
    init(style: SpanStyle, start: TextIndex, end: TextIndex) {
        self.style = style
        self.start = start
        self.end = end
    }

    /// The resolved style of the span.
    let style: SpanStyle

    /// The index of the beginning of the range of text represented by this span.
    let start: TextIndex

    /// The index of the end of the range of text represented by this span.
    let end: TextIndex
}

/// Holds information for a placeholder in a paragraph.
///
/// [width], [height] and [baselineOffset] are expected to be already scaled.
struct ParagraphPlaceholder {
    /// Creates a new paragraph placeholder.
    init(
        width: Float,
        height: Float,
        alignment: PlaceholderAlignment,
        baselineOffset: Float,
        baseline: TextBaseline
    ) {
        self.width = width
        self.height = height
        self.alignment = alignment
        self.baselineOffset = baselineOffset
        self.baseline = baseline
    }

    /// The scaled width of the placeholder.
    let width: Float

    /// The scaled height of the placeholder.
    let height: Float

    /// Specifies how the placeholder rectangle will be vertically aligned with
    /// the surrounding text.
    let alignment: PlaceholderAlignment

    /// When the [alignment] value is [ui.PlaceholderAlignment.baseline], the
    /// [baselineOffset] indicates the distance from the baseline to the top of
    /// the placeholder rectangle.
    let baselineOffset: Float

    /// Dictates whether to use alphabetic or ideographic baseline.
    let baseline: TextBaseline
}

/// A placeholder span in a paragraph.
struct PlaceholderSpan: ParagraphSpanProtocol {
    /// Creates a new placeholder span.
    init(
        style: SpanStyle,
        start: TextIndex,
        end: TextIndex,
        width: Float,
        height: Float,
        alignment: PlaceholderAlignment,
        baselineOffset: Float,
        baseline: TextBaseline
    ) {
        self.style = style
        self.start = start
        self.end = end
        self.placeholder = ParagraphPlaceholder(
            width: width,
            height: height,
            alignment: alignment,
            baselineOffset: baselineOffset,
            baseline: baseline
        )
    }

    /// The resolved style of the span.
    let style: SpanStyle

    /// The index of the beginning of the range of text represented by this span.
    let start: TextIndex

    /// The index of the end of the range of text represented by this span.
    let end: TextIndex

    /// The placeholder information.
    let placeholder: ParagraphPlaceholder
}

/// Represents a node in the tree of text styles pushed to [ParagraphBuilder].
///
/// The [ParagraphBuilder.pushText] and [ParagraphBuilder.pop] operations
/// represent the entire tree of styles in the paragraph. In our implementation,
/// we don't need to keep the entire tree structure in memory. At any point in
/// time, we only need a stack of nodes that represent the current branch in the
/// tree. The items in the stack are [StyleNode] objects.
protocol StyleNode: AnyObject {
    /// Create a child for this style node.
    ///
    /// We are not creating a tree structure, hence there's no need to keep track
    /// of the children.
    func createChild(_ style: SpanStyle) -> ChildStyleNode

    var _cachedStyle: SpanStyle? { get set }

    /// Generates the final text style to be applied to the text span.
    ///
    /// The resolved text style is equivalent to the entire ascendent chain of
    /// parent style nodes.
    func resolveStyle() -> SpanStyle

    var _color: Shaft.Color? { get }
    var _decoration: TextDecoration? { get }
    var _decorationColor: Shaft.Color? { get }
    var _decorationStyle: TextDecorationStyle? { get }
    var _decorationThickness: Float? { get }
    var _fontWeight: FontWeight? { get }
    var _fontStyle: FontStyle? { get }
    var _textBaseline: TextBaseline? { get }
    var _fontFamilies: [String]? { get }
    // var _fontFeatures: [FontFeature]? { get }
    // var _fontVariations: [FontVariation]? { get }
    var _fontSize: Float { get }
    var _letterSpacing: Float? { get }
    var _wordSpacing: Float? { get }
    var _height: Float? { get }
    var _leadingDistribution: TextLeadingDistribution? { get }
    // var _locale: Locale? { get }
    var _background: Paint? { get }
    var _foreground: Paint? { get }
    var _shadows: [Shadow]? { get }
}

extension StyleNode {
    func createChild(_ style: SpanStyle) -> ChildStyleNode {
        return ChildStyleNode(parent: self, style: style)
    }

    func resolveStyle() -> SpanStyle {
        if let style = _cachedStyle {
            return style
        }
        let style = SpanStyle(
            color: _color,
            decoration: _decoration,
            decorationColor: _decorationColor,
            decorationStyle: _decorationStyle,
            decorationThickness: _decorationThickness,
            fontWeight: _fontWeight,
            fontStyle: _fontStyle,
            textBaseline: _textBaseline,
            fontFamilies: _fontFamilies,
            fontSize: _fontSize,
            letterSpacing: _letterSpacing,
            wordSpacing: _wordSpacing,
            height: _height,
            leadingDistribution: _leadingDistribution,
            background: _background,
            foreground: _foreground,
            shadows: _shadows
        )
        _cachedStyle = style
        return style
    }
}

/// Represents a non-root [StyleNode].
class ChildStyleNode: StyleNode {
    /// Creates a [ChildStyleNode] with the given [parent] and [style].
    init(parent: StyleNode, style: SpanStyle) {
        self.parent = parent
        self.style = style
    }

    /// The parent node to be used when resolving text styles.
    let parent: StyleNode

    /// The text style associated with the current node.
    let style: SpanStyle

    var _cachedStyle: SpanStyle?

    // Read these properties from the TextStyle associated with this node. If the
    // property isn't defined, go to the parent node.

    var _color: Shaft.Color? {
        return style.color ?? ((_foreground == nil) ? parent._color : nil)
    }

    var _decoration: TextDecoration? {
        return style.decoration ?? parent._decoration
    }

    var _decorationColor: Shaft.Color? {
        return style.decorationColor ?? parent._decorationColor
    }

    var _decorationStyle: TextDecorationStyle? {
        return style.decorationStyle ?? parent._decorationStyle
    }

    var _decorationThickness: Float? {
        return style.decorationThickness.map { Float($0) } ?? parent._decorationThickness
    }

    var _fontWeight: FontWeight? {
        return style.fontWeight ?? parent._fontWeight
    }

    var _fontStyle: FontStyle? {
        return style.fontStyle ?? parent._fontStyle
    }

    var _textBaseline: TextBaseline? {
        return style.textBaseline ?? parent._textBaseline
    }

    var _fontFamilies: [String]? {
        return style.fontFamilies ?? parent._fontFamilies
    }

    // var _fontFeatures: [FontFeature]? {
    //     return style.fontFeatures ?? parent._fontFeatures
    // }

    // var _fontVariations: [FontVariation]? {
    //     return style.fontVariations ?? parent._fontVariations
    // }

    var _fontSize: Float {
        return style.fontSize.map { Float($0) } ?? parent._fontSize
    }

    var _letterSpacing: Float? {
        return style.letterSpacing.map { Float($0) } ?? parent._letterSpacing
    }

    var _wordSpacing: Float? {
        return style.wordSpacing.map { Float($0) } ?? parent._wordSpacing
    }

    var _height: Float? {
        if style.height == nil {
            return parent._height
        }
        return Float(style.height!)
    }

    var _leadingDistribution: TextLeadingDistribution? {
        return style.leadingDistribution ?? parent._leadingDistribution
    }

    // var _locale: Locale? {
    //     return style.locale ?? parent._locale
    // }

    var _background: Paint? {
        return style.background ?? parent._background
    }

    var _foreground: Paint? {
        return style.foreground ?? parent._foreground
    }

    var _shadows: [Shadow]? {
        return style.shadows ?? parent._shadows
    }
}

/// The root style node for the paragraph.
///
/// The style of the root is derived from a [ParagraphStyle] and is the root
/// style for all spans in the paragraph.
class RootStyleNode: StyleNode {
    /// Creates a [RootStyleNode] from [paragraphStyle].
    init(_ paragraphStyle: ParagraphStyle) {
        self.paragraphStyle = paragraphStyle
    }

    /// The style of the paragraph being built.
    let paragraphStyle: ParagraphStyle

    var _cachedStyle: SpanStyle?

    var _color: Shaft.Color? {
        return nil
    }

    var _decoration: TextDecoration? {
        return nil
    }

    var _decorationColor: Shaft.Color? {
        return nil
    }

    var _decorationStyle: TextDecorationStyle? {
        return nil
    }

    var _decorationThickness: Float? {
        return nil
    }

    var _fontWeight: FontWeight? {
        return paragraphStyle.defaultSpanStyle?.fontWeight
    }

    var _fontStyle: FontStyle? {
        return paragraphStyle.defaultSpanStyle?.fontStyle
    }

    var _textBaseline: TextBaseline? {
        return nil
    }

    var _fontFamilies: [String]? {
        return paragraphStyle.defaultSpanStyle?.fontFamilies
    }

    // var _fontFeatures: [FontFeature]? {
    //     return nil
    // }

    // var _fontVariations: [FontVariation]? {
    //     return nil
    // }

    var _fontSize: Float {
        return Float(paragraphStyle.defaultSpanStyle?.fontSize ?? 14.0)
    }

    var _letterSpacing: Float? {
        return nil
    }

    var _wordSpacing: Float? {
        return nil
    }

    var _height: Float? {
        return paragraphStyle.defaultSpanStyle?.height.map { Float($0) }
    }

    var _leadingDistribution: TextLeadingDistribution? {
        return nil
    }

    // var _locale: Locale? {
    //     return paragraphStyle.locale
    // }

    var _background: Paint? {
        return nil
    }

    var _foreground: Paint? {
        return nil
    }

    var _shadows: [Shadow]? {
        return nil
    }
}
