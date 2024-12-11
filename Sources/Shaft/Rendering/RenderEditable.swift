// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// in pixels
private let kCaretGap: Float = 1.0
// in pixels
private let kCaretHeightOffset: Float = 2.0

// The additional size on the x and y axis with which to expand the prototype
// cursor to render the floating cursor in pixels.
private let kFloatingCursorSizeIncrease = EdgeInsets.symmetric(vertical: 1.0, horizontal: 0.5)

// The corner radius of the floating cursor in pixels.
private let kFloatingCursorRadius = Radius.circular(1.0)

// This constant represents the shortest squared distance required between the floating cursor
// and the regular cursor when both are present in the text field.
// If the squared distance between the two cursors is less than this value,
// it's not necessary to display both cursors at the same time.
// This behavior is consistent with the one observed in iOS UITextField.
private let kShortestDistanceSquaredWithFloatingAndRegularCursors: Float = 15.0 * 15.0
/// Displays some text in a scrollable container with a potentially blinking
/// cursor and with gesture recognizers.
///
/// This is the renderer for an editable text field. It does not directly
/// provide affordances for editing the text, but it does handle text selection
/// and manipulation of the text cursor.
///
/// The [text] is displayed, scrolled by the given [offset], aligned according
/// to [textAlign]. The [maxLines] property controls whether the text displays
/// on one line or many. The [selection], if it is not collapsed, is painted in
/// the [selectionColor]. If it _is_ collapsed, then it represents the cursor
/// position. The cursor is shown while [showCursor] is true. It is painted in
/// the [cursorColor].
///
/// Keyboard handling, IME handling, scrolling, toggling the [showCursor] value
/// to actually blink the cursor, and other features not mentioned above are the
/// responsibility of higher layers and not handled by this object.
public class RenderEditable: RenderBox, RenderObjectWithChildren, TextLayoutMetrics {
    /// Creates a render object that implements the visual aspects of a text field.
    ///
    /// The `textAlign` argument defaults to `TextAlign.start`.
    ///
    /// If `showCursor` is not specified, then it defaults to hiding the cursor.
    ///
    /// The `maxLines` property can be set to nil to remove the restriction on
    /// the number of lines. By default, it is 1, meaning this is a single-line
    /// text field. If it is not nil, it must be greater than zero.
    ///
    /// Use `ViewportOffset.zero` for the `offset` if there is no need for
    /// scrolling.
    public init(
        text: InlineSpan? = nil,
        textDirection: TextDirection,
        textAlign: TextAlign = .start,
        cursorColor: Color? = nil,
        backgroundCursorColor: Color? = nil,
        showCursor: Bool = false,
        hasFocus: Bool? = nil,
        // startHandleLayerLink: LayerLink,
        // endHandleLayerLink: LayerLink,
        maxLines: Int? = 1,
        minLines: Int? = nil,
        expands: Bool = false,
        strutStyle: StrutStyle? = nil,
        selectionColor: Color? = nil,
        textScaler: any TextScaler = .noScaling,
        selection: TextSelection? = nil,
        offset: ViewportOffset,
        ignorePointer: Bool = false,
        readOnly: Bool = false,
        forceLine: Bool = true,
        textHeightBehavior: TextHeightBehavior? = nil,
        textWidthBasis: TextWidthBasis = .parent,
        obscuringCharacter: Character = "•",
        obscureText: Bool = false,
        // locale: Locale? = nil,
        cursorWidth: Float = 1.0,
        cursorHeight: Float? = nil,
        cursorRadius: Radius? = nil,
        paintCursorAboveText: Bool = false,
        cursorOffset: Offset = .zero,
        devicePixelRatio: Float = 1.0,
        selectionHeightStyle: BoxHeightStyle = .tight,
        selectionWidthStyle: BoxWidthStyle = .tight,
        enableInteractiveSelection: Bool? = nil,
        floatingCursorAddedMargin: EdgeInsets = EdgeInsets(
            left: 4,
            top: 4,
            right: 4,
            bottom: 5
        ),
        promptRectRange: TextRange? = nil,
        promptRectColor: Color? = nil,
        clipBehavior: Clip = .hardEdge,
        textSelectionDelegate: TextSelectionDelegate,
        // painter: RenderEditablePainter? = nil,
        // foregroundPainter: RenderEditablePainter? = nil,
        children: [RenderBox]? = nil
    ) {
        assert(maxLines == nil || maxLines! > 0)
        assert(minLines == nil || minLines! > 0)
        assert(
            (maxLines == nil) || (minLines == nil) || (maxLines! >= minLines!),
            "minLines can't be greater than maxLines"
        )
        assert(
            !expands || (maxLines == nil && minLines == nil),
            "minLines and maxLines must be nil when expands is true."
        )
        assert(cursorWidth >= 0.0)
        assert(cursorHeight == nil || cursorHeight! >= 0.0)

        self.textPainter = TextPainter(
            text: text,
            textAlign: textAlign,
            textDirection: textDirection,
            textScaler: textScaler,
            // locale: locale,
            maxLines: maxLines == 1 ? 1 : nil,
            strutStyle: strutStyle,
            textHeightBehavior: textHeightBehavior,
            textWidthBasis: textWidthBasis
        )
        self.maxLines = maxLines
        self.minLines = minLines
        self.expands = expands
        self.selection = selection
        self.offset = offset
        self.cursorWidth = cursorWidth
        self.cursorHeight = cursorHeight
        // self.paintCursorOnTop = paintCursorAboveText
        // self.enableInteractiveSelection = enableInteractiveSelection
        self.devicePixelRatio = devicePixelRatio
        // self.startHandleLayerLink = startHandleLayerLink
        // self.endHandleLayerLink = endHandleLayerLink
        self.obscuringCharacter = obscuringCharacter
        self.obscureText = obscureText
        self.readOnly = readOnly
        self.forceLine = forceLine
        self.clipBehavior = clipBehavior
        self.hasFocus = hasFocus ?? false
        self.ignorePointer = ignorePointer
        // self.floatingCursorAddedMargin = floatingCursorAddedMargin
        self.textSelectionDelegate = textSelectionDelegate

        // assert(!self.showCursor.value || cursorColor != nil)

        selectionPainter.highlightColor = selectionColor
        selectionPainter.highlightedRange = selection?.range
        selectionPainter.selectionHeightStyle = selectionHeightStyle
        selectionPainter.selectionWidthStyle = selectionWidthStyle

        autocorrectHighlightPainter.highlightColor = promptRectColor
        autocorrectHighlightPainter.highlightedRange = promptRectRange

        super.init()

        caretPainter.caretColor = cursorColor
        caretPainter.cursorRadius = cursorRadius
        caretPainter.cursorOffset = cursorOffset
        caretPainter.backgroundCursorColor = backgroundCursorColor

        self.showCursor = showCursor

        updateForegroundPainter(foregroundPainter)
        updatePainter(painter)
        // addAll(children)
    }

    // public init(
    //     offset: ViewportOffset,
    //     textSelectionDelegate: TextSelectionDelegate
    // ) {
    //     self.offset = offset
    //     self.textSelectionDelegate = textSelectionDelegate
    // }

    public typealias ParentDataType = TextParentData
    public typealias ChildType = RenderBox

    public var childMixin = RenderContainerMixin<RenderBox>()

    // MARK: - Properties

    /// The text to paint in the form of a tree of [InlineSpan]s.
    ///
    /// In order to get the plain text representation, use [plainText].
    public var text: InlineSpan? {
        get {
            textPainter.text
        }
        set {
            if newValue !== textPainter.text {
                cachedLineBreakCount = nil
                textPainter.text = newValue
                // cachedAttributedValue = nil
                // cachedCombinedSemanticsInfos = nil
                // canComputeIntrinsicsCached = nil
                markNeedsTextLayout()
                // markNeedsSemanticsUpdate()
            }
        }
    }

    /// How the text should be aligned horizontally.
    public var textAlign: TextAlign {
        get {
            textPainter.textAlign
        }
        set {
            if textPainter.textAlign != newValue {
                textPainter.textAlign = newValue
                markNeedsTextLayout()
            }
        }
    }

    /// The directionality of the text.
    ///
    /// This decides how the [TextAlign.start], [TextAlign.end], and
    /// [TextAlign.justify] values of [textAlign] are interpreted.
    ///
    /// This is also used to disambiguate how to render bidirectional text. For
    /// example, if the [text] is an English phrase followed by a Hebrew phrase,
    /// in a [TextDirection.ltr] context the English phrase will be on the left
    /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
    /// context, the English phrase will be on the right and the Hebrew phrase on
    /// its left.
    // TextPainter.textDirection is nilable, but it is set to a
    // non-nil value in the RenderEditable constructor and we refuse to
    // set it to nil here, so textPainter.textDirection cannot be nil.
    public var textDirection: TextDirection {
        get {
            textPainter.textDirection!
        }
        set {
            if textPainter.textDirection != newValue {
                textPainter.textDirection = newValue
                markNeedsTextLayout()
                // markNeedsSemanticsUpdate();
            }
        }
    }

    /// Used by this renderer's internal [TextPainter] to select a locale-specific
    /// font.
    ///
    /// In some cases the same Unicode character may be rendered differently depending
    /// on the locale. For example the '骨' character is rendered differently in
    /// the Chinese and Japanese locales. In these cases the [locale] may be used
    /// to select a locale-specific font.
    ///
    /// If this value is nil, a system-dependent algorithm is used to select
    /// the font.
    // public var locale: Locale? {
    //     get {
    //         textPainter.locale
    //     }
    //     set {
    //         if textPainter.locale != newValue {
    //             textPainter.locale = newValue
    //             markNeedsTextLayout()
    //         }
    //     }
    // }

    /// The [StrutStyle] used by the renderer's internal [TextPainter] to
    /// determine the strut to use.
    public var strutStyle: StrutStyle? {
        get {
            textPainter.strutStyle
        }
        set {
            if textPainter.strutStyle != newValue {
                textPainter.strutStyle = newValue
                markNeedsTextLayout()
            }
        }
    }

    /// The color to use when painting the cursor.
    public var cursorColor: Color? {
        get {
            caretPainter.caretColor
        }
        set {
            caretPainter.caretColor = newValue
        }
    }

    /// The color to use when painting the cursor aligned to the text while
    /// rendering the floating cursor.
    ///
    /// Typically this would be set to [CupertinoColors.inactiveGray].
    ///
    /// If this is nil, the background cursor is not painted.
    ///
    /// See also:
    ///
    ///  * [FloatingCursorDragState], which explains the floating cursor feature
    ///    in detail.
    public var backgroundCursorColor: Color? {
        get {
            caretPainter.backgroundCursorColor
        }
        set {
            caretPainter.backgroundCursorColor = newValue
        }
    }

    /// Whether to paint the cursor.
    public var showCursor: Bool {
        get {
            caretPainter.shouldPaint
        }
        set {
            caretPainter.shouldPaint = newValue
        }
    }

    /// Whether the editable is currently focused.
    public var hasFocus: Bool = false {
        didSet {
            if hasFocus != oldValue {
                // markNeedsSemanticsUpdate()
            }
        }
    }

    /// Whether this rendering object will take a full line regardless the text
    /// width.
    public var forceLine: Bool = false {
        didSet {
            if forceLine != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// The pixel ratio of the current device.
    ///
    /// Should be obtained by querying MediaQuery for the devicePixelRatio.
    public var devicePixelRatio: Float {
        didSet {
            if devicePixelRatio == oldValue {
                return
            }
            markNeedsLayout()
        }
    }

    /// Character used for obscuring text if obscureText is true.
    ///
    /// Must have a length of exactly one.
    public var obscuringCharacter: Character {
        didSet {
            if obscuringCharacter == oldValue {
                return
            }
            markNeedsLayout()
        }
    }

    /// Whether to hide the text being edited (e.g., for passwords).
    public var obscureText: Bool {
        didSet {
            if obscureText == oldValue {
                return
            }
            // _cachedAttributedValue = nil
            // markNeedsSemanticsUpdate()
        }
    }

    /// Whether this rendering object is read only.
    public var readOnly: Bool = false {
        didSet {
            if readOnly != oldValue {
                // markNeedsSemanticsUpdate()
            }
        }
    }

    /// Controls how tall the selection highlight boxes are computed to be.
    ///
    /// See [ui.BoxHeightStyle] for details on available styles.
    public var selectionHeightStyle: BoxHeightStyle {
        get {
            selectionPainter.selectionHeightStyle
        }
        set {
            selectionPainter.selectionHeightStyle = newValue
        }
    }

    /// Controls how wide the selection highlight boxes are computed to be.
    ///
    /// See [ui.BoxWidthStyle] for details on available styles.
    public var selectionWidthStyle: BoxWidthStyle {
        get {
            selectionPainter.selectionWidthStyle
        }
        set {
            selectionPainter.selectionWidthStyle = newValue
        }
    }
    /// The maximum number of lines for the text to span, wrapping if necessary.
    ///
    /// If this is 1 (the default), the text will not wrap, but will extend
    /// indefinitely instead.
    ///
    /// If this is nil, there is no limit to the number of lines.
    ///
    /// When this is not nil, the intrinsic height of the render object is the
    /// height of one line of text multiplied by this value. In other words,
    /// this also controls the height of the actual editing widget.
    public var maxLines: Int? {
        didSet {
            if maxLines != oldValue {
                // Special case maxLines == 1 to keep only the first line so we
                // can get the height of the first line in case there are hard
                // line breaks in the text. See the `_preferredHeight` method.
                textPainter.maxLines = maxLines == 1 ? 1 : nil
                markNeedsTextLayout()
            }
        }
    }

    /// See: ``EditableText.minLines``.
    public var minLines: Int? {
        didSet {
            if minLines != oldValue {
                markNeedsTextLayout()
            }
        }
    }

    /// See: ``EditableText.expands``.
    public var expands: Bool = false {
        didSet {
            if expands != oldValue {
                markNeedsTextLayout()
            }
        }
    }

    /// The color to use when painting the selection.
    public var selectionColor: Color? {
        get {
            selectionPainter.highlightColor
        }
        set {
            selectionPainter.highlightColor = newValue
        }
    }

    public var textScaler: any TextScaler {
        get {
            textPainter.textScaler
        }
        set {
            if !textPainter.textScaler.isEqualTo(newValue) {
                textPainter.textScaler = newValue
                markNeedsTextLayout()
            }
        }
    }

    /// The region of text that is selected, if any.
    ///
    /// The caret position is represented by a collapsed selection.
    ///
    /// If [selection] is nil, there is no selection and attempts to
    /// manipulate the selection will throw.
    public var selection: TextSelection? {
        didSet {
            if selection != oldValue {
                selectionPainter.highlightedRange = selection?.range
                markNeedsPaint()
                // markNeedsSemanticsUpdate()
            }
        }
    }

    /// The offset at which the text should be painted.
    ///
    /// If the text content is larger than the editable line itself, the editable
    /// line clips the text. This property controls which part of the text is
    /// visible by shifting the text by the given offset before clipping.
    public var offset: ViewportOffset {
        didSet {
            if offset !== oldValue {
                if attached {
                    oldValue.removeListener(self)
                    offset.addListener(self, callback: markNeedsPaint)
                }
                markNeedsLayout()
            }
        }
    }

    /// How thick the cursor will be.
    public var cursorWidth: Float = 1.0 {
        didSet {
            if cursorWidth != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// How tall the cursor will be.
    ///
    /// This can be nil, in which case the getter will actually return
    /// [preferredLineHeight].
    ///
    /// Setting this to itself fixes the value to the current
    /// [preferredLineHeight]. Setting this to nil returns the behavior of
    /// deferring to [preferredLineHeight].
    public var cursorHeight: Float? {
        didSet {
            if cursorHeight != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// If the cursor should be painted on top of the text or underneath it.
    ///
    /// By default, the cursor should be painted on top for iOS platforms and
    /// underneath for Android platforms.
    public var paintCursorAboveText: Bool = false {
        didSet {
            if paintCursorAboveText == oldValue {
                return
            }
            // Clear cached built-in painters and reconfigure painters.
            cachedBuiltInForegroundPainters = nil
            cachedBuiltInPainters = nil
            // Call update methods to rebuild and set the effective painters.
            updateForegroundPainter(foregroundPainter)
            updatePainter(painter)
        }
    }

    /// The offset that is used, in pixels, when painting the cursor on screen.
    ///
    /// By default, the cursor position should be set to an offset of
    /// (-[cursorWidth] * 0.5, 0.0) on iOS platforms and (0, 0) on Android
    /// platforms. The origin from where the offset is applied to is the
    /// arbitrary location where the cursor ends up being rendered from by
    /// default.
    public var cursorOffset: Offset {
        get {
            caretPainter.cursorOffset
        }
        set {
            caretPainter.cursorOffset = newValue
        }
    }

    /// How rounded the corners of the cursor should be.
    ///
    /// A nil value is the same as [Radius.zero].
    public var cursorRadius: Radius? {
        get {
            caretPainter.cursorRadius
        }
        set {
            caretPainter.cursorRadius = newValue
        }
    }

    /// The [LayerLink] of start selection handle.
    ///
    /// [RenderEditable] is responsible for calculating the [Offset] of this
    /// [LayerLink], which will be used as [CompositedTransformTarget] of start handle.
    // public var startHandleLayerLink: LayerLink? {
    //     didSet {
    //         if startHandleLayerLink !== oldValue {
    //             markNeedsPaint()
    //         }

    //     }
    // }

    /// The [LayerLink] of end selection handle.
    ///
    /// [RenderEditable] is responsible for calculating the [Offset] of this
    /// [LayerLink], which will be used as [CompositedTransformTarget] of end handle.
    // public var endHandleLayerLink: LayerLink? {
    //     didSet {
    //         if endHandleLayerLink !== oldValue {
    //             markNeedsPaint()
    //         }
    //     }
    // }

    /// See: ``Clip``.
    ///
    /// Defaults to [Clip.hardEdge].
    public var clipBehavior: Clip = .hardEdge {
        didSet {
            if clipBehavior != oldValue {
                markNeedsPaint()
                // markNeedsSemanticsUpdate()
            }
        }
    }

    /// The object that controls the text selection, used by this render object
    /// for implementing cut, copy, and paste keyboard shortcuts.
    ///
    /// It will make cut, copy and paste functionality work with the most recently
    /// set [TextSelectionDelegate].
    public var textSelectionDelegate: TextSelectionDelegate

    /// Whether the [handleEvent] will propagate pointer events to selection
    /// handlers.
    ///
    /// If this property is true, the [handleEvent] assumes that this renderer
    /// will be notified of input gestures via [handleTapDown], [handleTap],
    /// [handleDoubleTap], and [handleLongPress].
    ///
    /// If there are any gesture recognizers in the text span, the [handleEvent]
    /// will still propagate pointer events to those recognizers.
    ///
    /// The default value of this property is false.
    public var ignorePointer: Bool = false

    /// The RenderEditablePainter to use for painting above this
    /// RenderEditable's text content.
    ///
    /// The new RenderEditablePainter will replace the previously specified
    /// foreground painter, and schedule a repaint if the new painter's
    /// `shouldRepaint` method returns true.
    public var foregroundPainter: RenderEditablePainter? {
        didSet {
            if foregroundPainter === oldValue {
                return
            }
            updateForegroundPainter(foregroundPainter)
        }
    }

    /// Sets the RenderEditablePainter to use for painting beneath this
    /// RenderEditable's text content.
    ///
    /// The new RenderEditablePainter will replace the previously specified
    /// painter, and schedule a repaint if the new painter's `shouldRepaint`
    /// method returns true.
    public var painter: RenderEditablePainter? {
        didSet {
            if painter === oldValue {
                return
            }
            updatePainter(painter)
        }
    }

    // MARK: - FloatingCursorPainter

    /// Returns true if the floating cursor is visible, false otherwise.

    private(set) var floatingCursorOn = false
    var floatingCursorTextPosition: TextPosition!

    // MARK: - Painters

    private func updateForegroundPainter(_ newPainter: RenderEditablePainter?) {
        let effectivePainter =
            newPainter == nil
            ? builtInForegroundPainters
            : CompositeRenderEditablePainter(painters: [
                builtInForegroundPainters,
                newPainter!,
            ])

        if foregroundRenderObject == nil {
            let foregroundRenderObject = RenderEditableCustomPaint(painter: effectivePainter)
            adoptChild(child: foregroundRenderObject)
            self.foregroundRenderObject = foregroundRenderObject
        } else {
            foregroundRenderObject?.painter = effectivePainter
        }
        foregroundPainter = newPainter
    }

    private func updatePainter(_ newPainter: RenderEditablePainter?) {
        let effectivePainter =
            newPainter == nil
            ? builtInPainters
            : CompositeRenderEditablePainter(painters: [builtInPainters, newPainter!])

        if backgroundRenderObject == nil {
            let backgroundRenderObject = RenderEditableCustomPaint(painter: effectivePainter)
            adoptChild(child: backgroundRenderObject)
            self.backgroundRenderObject = backgroundRenderObject
        } else {
            backgroundRenderObject?.painter = effectivePainter
        }
        painter = newPainter
    }

    // Caret Painters:
    // A single painter for both the regular caret and the floating cursor.
    private lazy var caretPainter = CaretPainter()

    // Text Highlight painters:
    private let selectionPainter = TextHighlightPainter()
    private let autocorrectHighlightPainter = TextHighlightPainter()

    private var builtInForegroundPainters: CompositeRenderEditablePainter {
        cachedBuiltInForegroundPainters ?? createBuiltInForegroundPainters()
    }
    private var cachedBuiltInForegroundPainters: CompositeRenderEditablePainter?
    private func createBuiltInForegroundPainters() -> CompositeRenderEditablePainter {
        return CompositeRenderEditablePainter(
            painters: paintCursorAboveText ? [caretPainter] : []
        )
    }

    private var builtInPainters: CompositeRenderEditablePainter {
        cachedBuiltInPainters = cachedBuiltInPainters ?? createBuiltInPainters()
        return cachedBuiltInPainters!
    }
    private var cachedBuiltInPainters: CompositeRenderEditablePainter?
    private func createBuiltInPainters() -> CompositeRenderEditablePainter {
        var painters: [RenderEditablePainter] = [
            autocorrectHighlightPainter,
            selectionPainter,
        ]
        if !paintCursorAboveText {
            painters.append(caretPainter)
        }
        return CompositeRenderEditablePainter(painters: painters)
    }

    private var caretMargin: Float {
        kCaretGap + cursorWidth
    }

    private var isMultiline: Bool {
        maxLines != 1
    }

    private var viewportAxis: Axis {
        isMultiline ? .vertical : .horizontal
    }

    fileprivate var paintOffset: Offset {
        switch viewportAxis {
        case .horizontal:
            return Offset(-offset.pixels, 0.0)
        case .vertical:
            return Offset(0.0, -offset.pixels)
        }
    }

    private var viewportExtent: Float {
        assert(hasSize)
        switch viewportAxis {
        case .horizontal:
            return size.width
        case .vertical:
            return size.height
        }
    }

    private var effectiveCursorHeight: Float {
        cursorHeight ?? preferredLineHeight
    }

    public var preferredLineHeight: Float {
        textPainter.preferredLineHeight
    }

    /// Returns a plain text version of the text in [TextPainter].
    ///
    /// If [obscureText] is true, returns the obscured text. See
    /// [obscureText] and [obscuringCharacter].
    /// In order to get the styled text as an [InlineSpan] tree, use [text].
    public var plainText: String {
        textPainter.plainText
    }

    fileprivate var textPainter = TextPainter()
    // private var cachedAttributedValue: AttributedString?
    // private var cachedCombinedSemanticsInfos: [InlineSpanSemanticsInformation]?

    // bool? _canComputeIntrinsicsCached;
    // bool get _canComputeIntrinsics => _canComputeIntrinsicsCached ??= _canComputeDryLayoutForInlineWidgets();

    private var textLayoutLastMaxWidth: Float?
    private var textLayoutLastMinWidth: Float?

    /// Assert that the last layout still matches the constraints.
    private func debugAssertLayoutUpToDate() {
        assert(
            textLayoutLastMaxWidth == boxConstraint.maxWidth
                && textLayoutLastMinWidth == boxConstraint.minWidth,
            "Last width (\(String(describing: textLayoutLastMinWidth)), \(String(describing: textLayoutLastMaxWidth))) not the same as max width constraint (\(boxConstraint.minWidth), \(boxConstraint.maxWidth))."
        )
    }

    /// Marks the render object as needing to be laid out again and have its
    /// text metrics recomputed.
    ///
    /// Implies ``markNeedsLayout``.
    private func markNeedsTextLayout() {
        textLayoutLastMaxWidth = nil
        textLayoutLastMinWidth = nil
        markNeedsLayout()
    }

    /// Child render objects
    private var foregroundRenderObject: RenderEditableCustomPaint?
    private var backgroundRenderObject: RenderEditableCustomPaint?

    private var tap: TapGestureRecognizer!
    // private var longPress: LongPressGestureRecognizer!

    // MARK:- TextLayoutMetrics.

    /// Returns the TextPosition above or below the given offset.
    private func getTextPositionVertical(_ position: TextPosition, _ verticalOffset: Float)
        -> TextPosition
    {
        let caretOffset = textPainter.getOffsetForCaret(position, caretPrototype)
        let caretOffsetTranslated = caretOffset.translate(0.0, verticalOffset)
        return textPainter.getPositionForOffset(caretOffsetTranslated)
    }

    public func getLineAtOffset(_ position: TextPosition) -> TextRange? {
        guard let line = textPainter.getLineBoundary(position) else {
            return nil
        }
        // If text is obscured, the entire string should be treated as one line.
        if obscureText {
            return TextRange(
                start: .zero,
                end: .init(utf16Offset: plainText.count)
            )
        }
        return TextRange(start: line.start, end: line.end)
    }

    public func getWordBoundary(_ position: TextPosition) -> TextRange {
        return textPainter.getWordBoundary(position)
    }

    public func getTextPositionAbove(_ position: TextPosition) -> TextPosition {
        // The caret offset gives a location in the upper left hand corner of
        // the caret so the middle of the line above is a half line above that
        // point and the line below is 1.5 lines below that point.
        let preferredLineHeight = textPainter.preferredLineHeight
        let verticalOffset = -0.5 * preferredLineHeight
        return getTextPositionVertical(position, verticalOffset)
    }

    public func getTextPositionBelow(_ position: TextPosition) -> TextPosition {
        // The caret offset gives a location in the upper left hand corner of
        // the caret so the middle of the line above is a half line above that
        // point and the line below is 1.5 lines below that point.
        let preferredLineHeight = textPainter.preferredLineHeight
        let verticalOffset = 1.5 * preferredLineHeight
        return getTextPositionVertical(position, verticalOffset)
    }

    // MARK:- Event handling

    public override func handleEvent(_ event: PointerEvent, entry: HitTestEntry) {
        if let event = event as? PointerDownEvent {
            if !ignorePointer {
                tap.addPointer(event: event)
                // longPress.addPointer(event: event)
            }
        }
    }

    public private(set) var lastTapDownPosition: Offset?
    public private(set) var lastSecondaryTapDownPosition: Offset?

    internal func handleTapDown(event: TapDownDetails) {
        lastTapDownPosition = event.globalPosition
    }

    private func handleTap() {
        selectPosition(cause: SelectionChangedCause.tap)
    }

    /// Move selection to the location of the last tap down.
    ///
    /// This method is mainly used to translate user inputs in global positions
    /// into a [TextSelection]. When used in conjunction with a [EditableText],
    /// the selection change is fed back into [TextEditingController.selection].
    ///
    /// If you have a [TextEditingController], it's generally easier to
    /// programmatically manipulate its `value` or `selection` directly.
    public func selectPosition(cause: SelectionChangedCause) {
        selectPositionAt(from: lastTapDownPosition!, cause: cause)
    }

    /// Select text between the global positions [from] and [to].
    ///
    /// [from] corresponds to the [TextSelection.baseOffset], and [to] corresponds
    /// to the [TextSelection.extentOffset].
    public func selectPositionAt(from: Offset, to: Offset? = nil, cause: SelectionChangedCause) {
        layoutText(minWidth: boxConstraint.minWidth, maxWidth: boxConstraint.maxWidth)
        let fromPosition = textPainter.getPositionForOffset(globalToLocal(from - paintOffset))
        let toPosition =
            to == nil
            ? nil
            : textPainter.getPositionForOffset(globalToLocal(to! - paintOffset))

        let baseOffset = fromPosition.offset
        let extentOffset = toPosition?.offset ?? fromPosition.offset

        let newSelection = TextSelection(
            baseOffset: baseOffset,
            extentOffset: extentOffset,
            affinity: fromPosition.affinity
        )

        setSelection(newSelection, cause: cause)
    }

    /// Word boundaries of the text
    var wordBoundaries: WordBoundary {
        textPainter.wordBoundaries
    }

    /// Select a word around the location of the last tap down.
    ///
    /// See also: ``selectPosition``
    func selectWord(cause: SelectionChangedCause) {
        selectWordsInRange(from: lastTapDownPosition!, cause: cause)
    }

    /// Selects the set words of a paragraph that intersect a given range of global positions.
    ///
    /// The set of words selected are not strictly bounded by the range of global positions.
    ///
    /// The first and last endpoints of the selection will always be at the
    /// beginning and end of a word respectively.
    ///
    /// See also: ``selectPosition``
    func selectWordsInRange(from: Offset, to: Offset? = nil, cause: SelectionChangedCause) {
        computeTextMetricsIfNeeded()
        let fromPosition = textPainter.getPositionForOffset(globalToLocal(from - paintOffset))
        let fromWord = getWordAtOffset(fromPosition)
        let toPosition =
            to == nil
            ? fromPosition : textPainter.getPositionForOffset(globalToLocal(to! - paintOffset))
        let toWord = toPosition == fromPosition ? fromWord : getWordAtOffset(toPosition)  // 这里有问题！！！
        let isFromWordBeforeToWord = fromWord.range.start < toWord.range.end

        setSelection(
            TextSelection(
                baseOffset: isFromWordBeforeToWord ? fromWord.base.offset : fromWord.extent.offset,
                extentOffset: isFromWordBeforeToWord ? toWord.extent.offset : toWord.base.offset,
                affinity: fromWord.affinity
            ),
            cause: cause
        )
    }

    /// Move the selection to the beginning or end of a word.
    ///
    /// See also: ``selectPosition``
    func selectWordEdge(cause: SelectionChangedCause) {
        computeTextMetricsIfNeeded()
        assert(lastTapDownPosition != nil)
        let position = textPainter.getPositionForOffset(
            globalToLocal(lastTapDownPosition! - paintOffset)
        )
        let word = textPainter.getWordBoundary(position)
        var newSelection: TextSelection
        if position.offset <= word.start {
            newSelection = TextSelection.collapsed(offset: word.start)
        } else {
            newSelection = TextSelection.collapsed(offset: word.end, affinity: .upstream)
        }
        setSelection(newSelection, cause: cause)
    }

    /// Returns a [TextSelection] that encompasses the word at the given
    /// [TextPosition].
    package func getWordAtOffset(_ position: TextPosition) -> TextSelection {
        // When long-pressing past the end of the text, we want a collapsed cursor.
        if position.offset.utf16Offset >= plainText.utf16.count {
            return .fromPosition(
                TextPosition(offset: .init(utf16Offset: plainText.utf16.count), affinity: .upstream)
            )
        }
        // If text is obscured, the entire sentence should be treated as one word.
        if obscureText {
            return TextSelection(
                baseOffset: .zero,
                extentOffset: .init(utf16Offset: plainText.utf16.count)
            )
        }
        let word = textPainter.getWordBoundary(position)
        let effectiveOffset: TextIndex
        switch position.affinity {
        case .upstream:
            // upstream affinity is effectively -1 in text position.
            effectiveOffset = position.offset.advanced(by: -1)
        case .downstream:
            effectiveOffset = position.offset
        }
        assert(effectiveOffset >= .zero)

        // On iOS, select the previous word if there is a previous word, or select
        // to the end of the next word if there is a next word. Select nothing if
        // there is neither a previous word nor a next word.
        //
        // If the platform is Android and the text is read only, try to select the
        // previous word if there is one; otherwise, select the single whitespace at
        // the position.
        if effectiveOffset > .zero
            && isWhitespace(
                plainText.codeUnitAt(effectiveOffset)
            )
        {
            let previousWord = getPreviousWord(word.start)
            switch backend.targetPlatform {
            case .iOS:
                if previousWord == nil {
                    let nextWord = getNextWord(word.start)
                    if nextWord == nil {
                        return TextSelection.collapsed(offset: position.offset)
                    }
                    return TextSelection(
                        baseOffset: position.offset,
                        extentOffset: nextWord!.end
                    )
                }
                return TextSelection(
                    baseOffset: previousWord!.start,
                    extentOffset: position.offset
                )
            case .android:
                if readOnly {
                    if previousWord == nil {
                        return TextSelection(
                            baseOffset: position.offset,
                            extentOffset: position.offset.advanced(by: 1)
                        )
                    }
                    return TextSelection(
                        baseOffset: previousWord!.start,
                        extentOffset: position.offset
                    )
                }
            case .fuchsia, .macOS, .linux, .windows, nil:
                break
            }
        }

        return TextSelection(baseOffset: word.start, extentOffset: word.end)
    }

    public func setSelection(_ nextSelection: TextSelection, cause: SelectionChangedCause) {
        var nextSelection = nextSelection
        if nextSelection.range.isValid {
            // The nextSelection is calculated based on plainText, which can be out
            // of sync with the textSelectionDelegate.textEditingValue by one frame.
            // This is due to the render editable and editable text handle pointer
            // event separately. If the editable text changes the text during the
            // event handler, the render editable will use the outdated text stored in
            // the plainText when handling the pointer event.
            //
            // If this happens, we need to make sure the new selection is still valid.
            let textLength = TextIndex(
                utf16Offset: textSelectionDelegate.textEditingValue.text.utf16.count
            )
            nextSelection = nextSelection.copyWith(
                baseOffset: min(nextSelection.baseOffset, textLength),
                extentOffset: min(nextSelection.extentOffset, textLength)
            )
        }
        setTextEditingValue(
            textSelectionDelegate.textEditingValue.copyWith(selection: nextSelection),
            cause
        )
    }

    private func setTextEditingValue(_ newValue: TextEditingValue, _ cause: SelectionChangedCause) {
        textSelectionDelegate.userUpdateTextEditingValue(newValue, cause: cause)
    }

    private func getNextWord(_ offset: TextIndex) -> TextRange? {
        var offset = offset
        while true {
            let range = textPainter.getWordBoundary(TextPosition(offset: offset))
            if !range.isValid || range.isCollapsed {
                return nil
            }
            if !onlyWhitespace(range) {
                return range
            }
            offset = range.end
        }
    }

    private func getPreviousWord(_ offset: TextIndex) -> TextRange? {
        var offset = offset
        while offset >= .zero {
            let range = textPainter.getWordBoundary(TextPosition(offset: offset))
            if !range.isValid || range.isCollapsed {
                return nil
            }
            if !onlyWhitespace(range) {
                return range
            }
            offset = range.start.advanced(by: -1)
        }
        return nil
    }

    // Check if the given text range only contains white space or separator
    // characters.
    //
    // Includes newline characters from ASCII and separators from the
    // [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
    // TODO(zanderso): replace when we expose this ICU information.
    private func onlyWhitespace(_ range: TextRange) -> Bool {
        for i in range.start..<range.end {
            let codeUnit = text!.codeUnitAt(i)!
            if !isWhitespace(codeUnit) {
                return false
            }
        }
        return true
    }

    public override func attach(_ owner: RenderOwner) {
        super.attach(owner)
        // foregroundRenderObject?.attach(owner)
        // backgroundRenderObject?.attach(owner)

        tap = TapGestureRecognizer(debugOwner: self)
        tap.onTapDown = handleTapDown
        tap.onTap = handleTap
        // longPress = LongPressGestureRecognizer(debugOwner: this)
        // longPress.onLongPress = _handleLongPress
        offset.addListener(self, callback: markNeedsPaint)
    }

    public override func detach() {
        tap.dispose()
        // longPress.dispose()
        offset.removeListener(self)
        super.detach()
        // foregroundRenderObject?.detach()
        // backgroundRenderObject?.detach()
    }

    public override func markNeedsPaint() {
        super.markNeedsPaint()
        // Tell the painters to repaint since text layout may have changed.
        foregroundRenderObject?.markNeedsPaint()
        backgroundRenderObject?.markNeedsPaint()
    }

    public func redepthChildren() {
        let foregroundChild = foregroundRenderObject
        let backgroundChild = backgroundRenderObject
        if let foregroundChild {
            redepthChild(foregroundChild)
        }
        if let backgroundChild {
            redepthChild(backgroundChild)
        }
    }

    public func visitChildren(visitor: (RenderBox) -> Void) {
        if let foregroundRenderObject = foregroundRenderObject {
            visitor(foregroundRenderObject)
        }
        if let backgroundRenderObject = backgroundRenderObject {
            visitor(backgroundRenderObject)
        }
    }

    private func layoutText(minWidth: Float, maxWidth: Float) {
        let availableMaxWidth = max(0.0, maxWidth - caretMargin)
        let availableMinWidth = min(minWidth, availableMaxWidth)
        let textMaxWidth = isMultiline ? availableMaxWidth : .infinity
        let textMinWidth = forceLine ? availableMaxWidth : availableMinWidth
        textPainter.layout(
            minWidth: textMinWidth,
            maxWidth: textMaxWidth
        )
        textLayoutLastMinWidth = minWidth
        textLayoutLastMaxWidth = maxWidth
    }

    // Computes the text metrics if `textPainter`'s layout information was
    // marked as dirty.
    //
    // This method must be called in `RenderEditable`'s public methods that
    // expose `textPainter`'s metrics. For instance, `systemFontsDidChange`
    // sets textPainter._paragraph to nil, so accessing textPainter's metrics
    // immediately after `systemFontsDidChange` without first calling this
    // method may crash.
    //
    // This method is also called in various paint methods
    // (`RenderEditable.paint` as well as its foreground/background painters'
    // `paint`). It's needed because invisible render objects kept in the tree
    // by `KeepAlive` may not get a chance to do layout but can still paint. See
    // https://github.com/flutter/flutter/issues/84896.
    //
    // This method only re-computes layout if the underlying `textPainter`'s
    // layout cache is invalidated (by calling `TextPainter.markNeedsLayout`),
    // or the constraints used to layout the `textPainter` is different. See
    // `TextPainter.layout`.
    fileprivate func computeTextMetricsIfNeeded() {
        layoutText(
            minWidth: boxConstraint.minWidth,
            maxWidth: boxConstraint.maxWidth
        )
    }

    /// Returns the smallest [Rect], in the local coordinate system, that covers
    /// the text within the [TextRange] specified.
    ///
    /// This method is used to calculate the approximate position of the IME bar
    /// on iOS.
    ///
    /// Returns nil if [TextRange.isValid] is false for the given `range`, or the
    /// given `range` is collapsed.
    func getRectForComposingRange(_ range: TextRange) -> Rect? {
        if !range.isValid || range.isCollapsed {
            return nil
        }
        computeTextMetricsIfNeeded()

        let boxes = textPainter.getBoxesForSelection(
            TextSelection(baseOffset: range.start, extentOffset: range.end),
            boxHeightStyle: selectionHeightStyle,
            boxWidthStyle: selectionWidthStyle
        )

        return boxes.reduce(nil) { accum, incoming in
            accum?.union(incoming.toRect()) ?? incoming.toRect()
        }?.shift(paintOffset)
    }

    /// Returns the position in the text for the given global coordinate.
    ///
    /// See also:
    ///
    ///  * `getLocalRectForCaret`, which is the reverse operation, taking
    ///    a `TextPosition` and returning a `Rect`.
    ///  * `TextPainter.getPositionForOffset`, which is the equivalent method
    ///    for a `TextPainter` object.
    public func getPositionForPoint(_ globalPosition: Offset) -> TextPosition {
        computeTextMetricsIfNeeded()
        return textPainter.getPositionForOffset(globalToLocal(globalPosition) - paintOffset)
    }

    /// Returns the [Rect] in local coordinates for the caret at the given text
    /// position.
    ///
    /// See also:
    ///
    ///  * [getPositionForPoint], which is the reverse operation, taking
    ///    an [Offset] in global coordinates and returning a [TextPosition].
    ///  * [getEndpointsForSelection], which is the equivalent but for
    ///    a selection rather than a particular text position.
    ///  * [TextPainter.getOffsetForCaret], the equivalent method for a
    ///    [TextPainter] object.
    func getLocalRectForCaret(_ caretPosition: TextPosition) -> Rect {
        computeTextMetricsIfNeeded()
        let caretPrototype = self.caretPrototype
        let caretOffset = textPainter.getOffsetForCaret(caretPosition, caretPrototype)
        var caretRect = caretPrototype.shift(caretOffset + cursorOffset)
        let scrollableWidth = max(textPainter.width + caretMargin, size.width)

        let caretX = caretRect.left.clamped(to: 0...max(scrollableWidth - caretMargin, 0))
        caretRect = Rect(origin: Offset(caretX, caretRect.top), size: caretRect.size)

        let fullHeight = textPainter.getFullHeightForCaret(caretPosition, caretPrototype)
        switch backend.targetPlatform {
        case .iOS, .macOS:
            // Center the caret vertically along the text.
            let heightDiff = fullHeight - caretRect.height
            caretRect = Rect(
                left: caretRect.left,
                top: caretRect.top + heightDiff / 2,
                width: caretRect.width,
                height: caretRect.height
            )
        case .android, .fuchsia, .linux, .windows, nil:
            // Override the height to take the full height of the glyph at the TextPosition
            // when not on iOS. iOS has special handling that creates a taller caret.
            // TODO(garyq): see https://github.com/flutter/flutter/issues/120836.
            let caretHeight = effectiveCursorHeight
            // Center the caret vertically along the text.
            let heightDiff = fullHeight - caretHeight
            caretRect = Rect(
                left: caretRect.left,
                top: caretRect.top - kCaretHeightOffset + heightDiff / 2,
                width: caretRect.width,
                height: caretHeight
            )
        }

        caretRect = caretRect.shift(paintOffset)
        return caretRect.shift(snapToPhysicalPixel(caretRect.topLeft))
    }
    private func preferredHeight(_ width: Float) -> Float {
        let maxLines = self.maxLines
        let minLines = self.minLines ?? maxLines
        let minHeight = preferredLineHeight * Float(minLines ?? 0)

        if maxLines == nil {
            let estimatedHeight: Float
            if width == .infinity {
                estimatedHeight = preferredLineHeight * Float(countHardLineBreaks(plainText) + 1)
            } else {
                layoutText(minWidth: width, maxWidth: width)
                estimatedHeight = textPainter.height
            }
            return max(estimatedHeight, minHeight)
        }

        // Special case maxLines == 1 since it forces the scrollable direction
        // to be horizontal. Report the real height to prevent the text from
        // being clipped.
        if maxLines == 1 {
            // The layoutText call lays out the paragraph using infinite width
            // when maxLines == 1. Also textPainter.maxLines will be set to 1
            // so should there be any line breaks only the first line is shown.
            assert(textPainter.maxLines == 1)
            layoutText(minWidth: width, maxWidth: width)
            return textPainter.height
        }
        if minLines == maxLines {
            return minHeight
        }
        layoutText(minWidth: width, maxWidth: width)
        let maxHeight = preferredLineHeight * Float(maxLines!)
        return textPainter.height.clamped(to: minHeight...maxHeight)
    }

    private var cachedLineBreakCount: Int?

    private func countHardLineBreaks(_ text: String) -> Int {
        if let cachedValue = cachedLineBreakCount {
            return cachedValue
        }
        var count = 0
        for index in text.indices {
            switch text[index] {
            // LF, NEL, VT, FF, LS, PS
            case "\n", "\u{0085}", "\u{000B}", "\u{000C}", "\u{2028}", "\u{2029}":
                count += 1
            default:
                continue
            }
        }
        cachedLineBreakCount = count
        return count
    }

    private var caretPrototype = Rect.zero

    /// On iOS, the cursor is taller than the cursor on Android. The height
    /// of the cursor for iOS is approximate and obtained through an eyeball
    /// comparison.
    private func computeCaretPrototype() {
        switch backend.targetPlatform {
        case .iOS, .macOS:
            caretPrototype = .init(
                left: 0.0,
                top: 0.0,
                width: cursorWidth,
                height: effectiveCursorHeight + 2
            )
        default:
            caretPrototype = .init(
                left: 0.0,
                top: kCaretHeightOffset,
                width: cursorWidth,
                height: effectiveCursorHeight - 2.0 * kCaretHeightOffset
            )
        }
    }

    private func getMaxScrollExtent(_ contentSize: Size) -> Float {
        assert(hasSize)
        switch viewportAxis {
        case .horizontal:
            return max(0.0, contentSize.width - size.width)
        case .vertical:
            return max(0.0, contentSize.height - size.height)
        }
    }

    /// The maximum amount the text is allowed to scroll.
    ///
    /// This value is only valid after layout and can change as additional text
    /// is entered or removed in order to accommodate expanding when [expands]
    /// is set to true.
    public private(set) var maxScrollExtent: Float = 0

    // We need to check the paint offset here because during animation, the start of
    // the text may position outside the visible region even when the text fits.
    private var hasVisualOverflow: Bool {
        maxScrollExtent > 0 || paintOffset != Offset.zero
    }

    // Computes the offset to apply to the given [sourceOffset] so it perfectly
    // snaps to physical pixels.
    private func snapToPhysicalPixel(_ sourceOffset: Offset) -> Offset {
        let globalOffset = localToGlobal(sourceOffset)
        let pixelMultiple = 1.0 / devicePixelRatio
        return Offset(
            globalOffset.dx.isFinite
                ? (globalOffset.dx / pixelMultiple).rounded() * pixelMultiple - globalOffset.dx
                : 0,
            globalOffset.dy.isFinite
                ? (globalOffset.dy / pixelMultiple).rounded() * pixelMultiple - globalOffset.dy
                : 0
        )
    }

    public override func performLayout() {
        let constraints = boxConstraint
        // _placeholderDimensions = layoutInlineChildren(
        //     constraints.maxWidth,
        //     ChildLayoutHelper.layoutChild
        // )
        // textPainter.setPlaceholderDimensions(_placeholderDimensions);
        computeTextMetricsIfNeeded()
        // positionInlineChildren(textPainter.inlinePlaceholderBoxes!);
        computeCaretPrototype()

        // // We grab textPainter.size here because assigning to `size` on the next
        // // line will trigger us to validate our intrinsic sizes, which will change
        // // textPainter's layout because the intrinsic size calculations are
        // // destructive, which would mean we would get different results if we later
        // // used properties on textPainter in this method.
        // // Other textPainter state like didExceedMaxLines will also be affected,
        // // though we currently don't use those here.
        // // See also RenderParagraph which has a similar issue.
        let textPainterSize = textPainter.size
        let width =
            if forceLine { constraints.maxWidth } else {
                constraints.constrainWidth(textPainter.size.width + caretMargin)
            }
        let preferredHeight = preferredHeight(constraints.maxWidth)
        size = Size(width, constraints.constrainHeight(preferredHeight))
        let contentSize = Size(textPainterSize.width + caretMargin, textPainterSize.height)

        let painterConstraints = BoxConstraints.tight(contentSize)

        foregroundRenderObject?.layout(painterConstraints)
        backgroundRenderObject?.layout(painterConstraints)

        maxScrollExtent = getMaxScrollExtent(contentSize)
        let _ = offset.applyViewportDimension(viewportExtent)
        let _ = offset.applyContentDimensions(0.0, maxScrollExtent)
    }

    private var clipRectLayer: ClipRectLayer? = nil

    public override func paint(context: PaintingContext, offset: Offset) {
        computeTextMetricsIfNeeded()
        if hasVisualOverflow && clipBehavior != Clip.none {
            clipRectLayer = context.pushClipRect(
                needsCompositing: needsCompositing,
                offset: offset,
                clipRect: Offset.zero & size,
                clipBehavior: clipBehavior,
                painter: paintContents,
                oldLayer: clipRectLayer
            )
        } else {
            clipRectLayer = nil
            paintContents(context: context, offset: offset)
        }
        // final TextSelection? selection = this.selection;
        // if (selection != nil && selection.isValid) {
        //   _paintHandleLayers(context, getEndpointsForSelection(selection), offset);
        // }
    }

    private func paintContents(context: PaintingContext, offset: Offset) {
        debugAssertLayoutUpToDate()
        let effectiveOffset = offset + paintOffset

        // if (selection != nil && !_floatingCursorOn) {
        //   _updateSelectionExtentsVisibility(effectiveOffset);
        // }

        let foregroundChild = foregroundRenderObject
        let backgroundChild = backgroundRenderObject

        // The painters paint in the viewport's coordinate space, since the
        // textPainter's coordinate space is not known to high level widgets.
        if let backgroundChild {
            context.paintChild(backgroundChild, offset: offset)
        }

        textPainter.paint(context.canvas, offset: effectiveOffset)
        // paintInlineChildren(context, effectiveOffset)

        if let foregroundChild {
            context.paintChild(foregroundChild, offset: offset)
        }
    }

    public override func dispose() {
        // _leaderLayerHandler.layer = null;
        foregroundRenderObject?.dispose()
        foregroundRenderObject = nil
        backgroundRenderObject?.dispose()
        backgroundRenderObject = nil
        clipRectLayer = nil
        cachedBuiltInForegroundPainters?.dispose()
        cachedBuiltInPainters?.dispose()
        // selectionStartInViewport.dispose()
        // selectionEndInViewport.dispose()
        autocorrectHighlightPainter.dispose()
        selectionPainter.dispose()
        caretPainter.dispose()
        // _textIntrinsicsCache?.dispose()
        super.dispose()
    }
}

private class RenderEditableCustomPaint: RenderBox {
    init(painter: RenderEditablePainter? = nil) {
        self.painter = painter
        super.init()
    }

    override var isRepaintBoundary: Bool {
        true
    }

    override var sizedByParent: Bool {
        true
    }

    var painter: RenderEditablePainter? {
        didSet {
            if painter === oldValue {
                return
            }

            if painter?.shouldRepaint(oldValue) ?? true {
                markNeedsPaint()
            }

            if attached {
                oldValue?.removeListener(self)
                painter?.addListener(self, callback: markNeedsPaint)
            }
        }
    }

    override func paint(context: PaintingContext, offset: Offset) {
        let parent = self.parent as? RenderEditable
        assert(parent != nil)
        let painter = self.painter
        if let painter = painter, let parent = parent {
            parent.computeTextMetricsIfNeeded()
            painter.paint(canvas: context.canvas, size: size, renderEditable: parent)
        }
    }

    override func attach(_ owner: RenderOwner) {
        super.attach(owner)
        painter?.addListener(self, callback: markNeedsPaint)
    }

    override func detach() {
        painter?.removeListener(self)
        super.detach()
    }

    override func computeDryLayout(_ constraints: BoxConstraints) -> Size {
        constraints.biggest
    }
}

/// An interface that paints within a RenderEditable's bounds, above or
/// beneath its text content.
///
/// This painter is typically used for painting auxiliary content that depends
/// on text layout metrics (for instance, for painting carets and text highlight
/// blocks). It can paint independently from its RenderEditable, allowing it
/// to repaint without triggering a repaint on the entire RenderEditable stack
/// when only auxiliary content changes (e.g. a blinking cursor) are present. It
/// will be scheduled to repaint when:
///
///  * It's assigned to a new RenderEditable (replacing a prior
///    RenderEditablePainter) and the shouldRepaint method returns true.
///  * Any of the RenderEditables it is attached to repaints.
///  * The notifyListeners method is called, which typically happens when the
///    painter's attributes change.
///
/// See also:
///
///  * RenderEditable.foregroundPainter, which takes a RenderEditablePainter
///    and sets it as the foreground painter of the RenderEditable.
///  * RenderEditable.painter, which takes a RenderEditablePainter
///    and sets it as the background painter of the RenderEditable.
///  * CustomPainter, a similar class which paints within a RenderCustomPaint.
public protocol RenderEditablePainter: ChangeNotifier {
    /// Determines whether repaint is needed when a new RenderEditablePainter
    /// is provided to a RenderEditable.
    ///
    /// If the new instance represents different information than the old
    /// instance, then the method should return true, otherwise it should return
    /// false. When oldDelegate is null, this method should always return true
    /// unless the new painter initially does not paint anything.
    ///
    /// If the method returns false, then the paint call might be optimized
    /// away. However, the paint method will get called whenever the
    /// RenderEditables it attaches to repaint, even if shouldRepaint returns
    /// false.
    func shouldRepaint(_ oldDelegate: RenderEditablePainter?) -> Bool

    /// Paints within the bounds of a RenderEditable.
    ///
    /// The given Canvas has the same coordinate space as the RenderEditable,
    /// which may be different from the coordinate space the RenderEditable's
    /// TextPainter uses, when the text moves inside the RenderEditable.
    ///
    /// Paint operations performed outside of the region defined by the canvas's
    /// origin and the size parameter may get clipped, when RenderEditable's
    /// RenderEditable.clipBehavior is not Clip.none.
    func paint(canvas: Canvas, size: Size, renderEditable: RenderEditable)
}

class TextHighlightPainter: ChangeNotifier, RenderEditablePainter {
    init(highlightedRange: TextRange? = nil, highlightColor: Color? = nil) {
        self.highlightedRange = highlightedRange
        self.highlightColor = highlightColor
        super.init()
    }

    var highlightPaint = Paint()

    var highlightColor: Color? {
        didSet {
            if highlightColor?.value == oldValue?.value {
                return
            }
            notifyListeners()
        }
    }

    var highlightedRange: TextRange? {
        didSet {
            if highlightedRange == oldValue {
                return
            }
            notifyListeners()
        }
    }

    /// Controls how tall the selection highlight boxes are computed to be.
    ///
    /// See [ui.BoxHeightStyle] for details on available styles.
    var selectionHeightStyle: BoxHeightStyle = .tight {
        didSet {
            if selectionHeightStyle == oldValue {
                return
            }
            notifyListeners()
        }
    }

    /// Controls how wide the selection highlight boxes are computed to be.
    ///
    /// See [ui.BoxWidthStyle] for details on available styles.
    var selectionWidthStyle: BoxWidthStyle = .tight {
        didSet {
            if selectionWidthStyle == oldValue {
                return
            }
            notifyListeners()
        }
    }

    func paint(canvas: Canvas, size: Size, renderEditable: RenderEditable) {
        let range = highlightedRange
        let color = highlightColor
        guard let range, let color else {
            return
        }
        if range.isCollapsed {
            return
        }

        highlightPaint.color = color
        let textPainter = renderEditable.textPainter
        let boxes = textPainter.getBoxesForSelection(
            TextSelection(baseOffset: range.start, extentOffset: range.end),
            boxHeightStyle: selectionHeightStyle,
            boxWidthStyle: selectionWidthStyle
        )

        for box in boxes {
            canvas.drawRect(
                box.toRect().shift(renderEditable.paintOffset)
                    .intersect(
                        Rect(left: 0, top: 0, width: textPainter.width, height: textPainter.height)
                    ),
                highlightPaint
            )
        }
    }

    func shouldRepaint(_ oldDelegate: RenderEditablePainter?) -> Bool {
        if oldDelegate === self {
            return false
        }
        if oldDelegate == nil {
            return highlightColor != nil && highlightedRange != nil
        }
        guard let oldDelegate = oldDelegate as? TextHighlightPainter else {
            return true
        }
        return oldDelegate.highlightColor != highlightColor
            || oldDelegate.highlightedRange != highlightedRange
            || oldDelegate.selectionHeightStyle != selectionHeightStyle
            || oldDelegate.selectionWidthStyle != selectionWidthStyle
    }
}

class CaretPainter: ChangeNotifier, RenderEditablePainter {
    override init() {}

    var shouldPaint: Bool = true {
        didSet {
            if shouldPaint == oldValue {
                return
            }
            notifyListeners()
        }
    }

    // This is directly manipulated by the RenderEditable during
    // setFloatingCursor.
    //
    // When changing this value, the caller is responsible for ensuring that
    // listeners are notified.
    var showRegularCaret = false

    var caretPaint = Paint()
    private(set) lazy var floatingCursorPaint = Paint()

    var caretColor: Color? {
        didSet {
            if caretColor?.value == oldValue?.value {
                return
            }
            notifyListeners()
        }
    }

    var cursorRadius: Radius? {
        didSet {
            if cursorRadius == oldValue {
                return
            }
            notifyListeners()
        }
    }

    var cursorOffset: Offset = .zero {
        didSet {
            if cursorOffset == oldValue {
                return
            }
            notifyListeners()
        }
    }

    var backgroundCursorColor: Color? {
        didSet {
            if backgroundCursorColor?.value == oldValue?.value {
                return
            }
            if showRegularCaret {
                notifyListeners()
            }
        }
    }

    var floatingCursorRect: Rect? {
        didSet {
            if floatingCursorRect == oldValue {
                return
            }
            notifyListeners()
        }
    }

    func paintRegularCursor(
        canvas: Canvas,
        renderEditable: RenderEditable,
        caretColor: Color,
        textPosition: TextPosition
    ) {
        let integralRect = renderEditable.getLocalRectForCaret(textPosition)
        if shouldPaint {
            if let floatingCursorRect {
                let distanceSquared = (floatingCursorRect.center - integralRect.center)
                    .distanceSquared
                if distanceSquared < kShortestDistanceSquaredWithFloatingAndRegularCursors {
                    return
                }
            }
            let radius = cursorRadius
            caretPaint.color = caretColor
            if radius == nil {
                canvas.drawRect(integralRect, caretPaint)
            } else {
                let caretRRect = RRect.fromRectAndRadius(integralRect, radius!)
                canvas.drawRRect(caretRRect, caretPaint)
            }
        }
    }

    func paint(canvas: Canvas, size: Size, renderEditable: RenderEditable) {
        // Compute the caret location even when `shouldPaint` is false.
        let selection = renderEditable.selection

        if selection == nil || !selection!.range.isCollapsed {
            return
        }

        let floatingCursorRect = self.floatingCursorRect

        let caretColor =
            floatingCursorRect == nil
            ? self.caretColor
            : showRegularCaret ? backgroundCursorColor : nil
        let caretTextPosition: TextPosition =
            floatingCursorRect == nil
            ? selection!.extent
            : renderEditable.floatingCursorTextPosition

        if let caretColor = caretColor {
            paintRegularCursor(
                canvas: canvas,
                renderEditable: renderEditable,
                caretColor: caretColor,
                textPosition: caretTextPosition
            )
        }

        let floatingCursorColor = self.caretColor?.withOpacity(0.75)
        // Floating Cursor.
        if floatingCursorRect == nil || floatingCursorColor == nil || !shouldPaint {
            return
        }

        floatingCursorPaint.color = floatingCursorColor!
        canvas.drawRRect(
            RRect.fromRectAndRadius(floatingCursorRect!, kFloatingCursorRadius),
            floatingCursorPaint
        )
    }

    func shouldRepaint(_ oldDelegate: RenderEditablePainter?) -> Bool {
        if oldDelegate === self {
            return false
        }

        if oldDelegate == nil {
            return shouldPaint
        }
        guard let oldDelegate = oldDelegate as? CaretPainter else {
            return true
        }
        return oldDelegate.shouldPaint != shouldPaint
            || oldDelegate.showRegularCaret != showRegularCaret
            || oldDelegate.caretColor != caretColor
            || oldDelegate.cursorRadius != cursorRadius
            || oldDelegate.cursorOffset != cursorOffset
            || oldDelegate.backgroundCursorColor != backgroundCursorColor
            || oldDelegate.floatingCursorRect != floatingCursorRect
    }
}

class CompositeRenderEditablePainter: ChangeNotifier, RenderEditablePainter {
    let painters: [RenderEditablePainter]

    init(painters: [RenderEditablePainter]) {
        self.painters = painters
    }

    override func addListener(_ listener: AnyObject, callback: @escaping VoidCallback) {
        for painter in painters {
            painter.addListener(listener, callback: callback)
        }
    }

    override func removeListener(_ listener: AnyObject) {
        for painter in painters {
            painter.removeListener(listener)
        }
    }

    func paint(canvas: Canvas, size: Size, renderEditable: RenderEditable) {
        for painter in painters {
            painter.paint(canvas: canvas, size: size, renderEditable: renderEditable)
        }
    }

    func shouldRepaint(_ oldDelegate: RenderEditablePainter?) -> Bool {
        if oldDelegate === self {
            return false
        }
        guard let oldDelegate = oldDelegate as? CompositeRenderEditablePainter,
            oldDelegate.painters.count == painters.count
        else {
            return true
        }

        var oldPainters = oldDelegate.painters.makeIterator()
        var newPainters = painters.makeIterator()
        var oldPainter = oldPainters.next()
        var newPainter = newPainters.next()

        while let old = oldPainter, let new = newPainter {
            if new.shouldRepaint(old) {
                return true
            }
            oldPainter = oldPainters.next()
            newPainter = newPainters.next()
        }

        return false
    }
}
