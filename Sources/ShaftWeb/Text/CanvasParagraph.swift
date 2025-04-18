import Shaft

/// A paragraph made up of a flat list of text spans and placeholders.
///
/// [CanvasParagraph] doesn't use a DOM element to represent the structure of
/// its spans and styles. Instead it uses a flat list of [ParagraphSpan]
/// objects.
class CanvasParagraph: Paragraph {
    /// This class is created by the engine, and should not be instantiated
    /// or extended directly.
    ///
    /// To create a [CanvasParagraph] object, use a [CanvasParagraphBuilder].
    init(
        spans: [ParagraphSpanProtocol],
        paragraphStyle: ParagraphStyle,
        plainText: String,
    ) {
        self.spans = spans
        self.paragraphStyle = paragraphStyle
        self.plainText = plainText
        assert(!spans.isEmpty)
    }

    /// The flat list of spans that make up this paragraph.
    let spans: [ParagraphSpanProtocol]

    /// General styling information for this paragraph.
    let paragraphStyle: ParagraphStyle

    /// The full textual content of the paragraph.
    let plainText: String

    var width: Float {
        return _layoutService.width
    }

    var height: Float {
        return _layoutService.height
    }

    var longestLine: Float {
        return _layoutService.longestLine?.width ?? 0.0
    }

    var minIntrinsicWidth: Float {
        return _layoutService.minIntrinsicWidth
    }

    var maxIntrinsicWidth: Float {
        return _layoutService.maxIntrinsicWidth
    }

    var alphabeticBaseline: Float {
        return _layoutService.alphabeticBaseline
    }

    var ideographicBaseline: Float {
        return _layoutService.ideographicBaseline
    }

    var didExceedMaxLines: Bool {
        return _layoutService.didExceedMaxLines
    }

    var lines: [ParagraphLine] {
        return _layoutService.lines
    }

    /// The bounds that contain the text painted inside this paragraph.
    var paintBounds: Shaft.Rect {
        return _layoutService.paintBounds
    }

    /// Whether this paragraph has been laid out or not.
    var isLaidOut = false

    var _lastUsedConstraints: ParagraphConstraints?

    lazy var _layoutService: TextLayoutService = TextLayoutService(self)
    lazy var _paintService: TextPaintService = TextPaintService(self)

    func layout(_ constraints: ParagraphConstraints) {
        if constraints == _lastUsedConstraints {
            return
        }

        _layoutService.performLayout(constraints)

        isLaidOut = true
        _lastUsedConstraints = constraints
    }

    // TODO(mdebbar): Returning true means we always require a bitmap canvas. Revisit
    // this decision once `CanvasParagraph` is fully implemented.
    /// Whether this paragraph is doing arbitrary paint operations that require
    /// a bitmap canvas, and can't be expressed in a DOM canvas.
    var hasArbitraryPaint: Bool {
        return true
    }

    /// Paints this paragraph instance on a [canvas] at the given [offset].
    func paint(_ canvas: Canvas2DCanvas, _ offset: Offset) {
        _paintService.paint(canvas: canvas, offset: offset)
    }

    func getBoxesForPlaceholders() -> [TextBox] {
        return _layoutService.getBoxesForPlaceholders()
    }

    func getBoxesForRange(
        _ start: TextIndex,
        _ end: TextIndex,
        boxHeightStyle: BoxHeightStyle = BoxHeightStyle.tight,
        boxWidthStyle: BoxWidthStyle = BoxWidthStyle.tight
    ) -> [TextBox] {
        return _layoutService.getBoxesForRange(start, end, boxHeightStyle, boxWidthStyle)
    }

    func getPositionForOffset(_ offset: Offset) -> TextPosition {
        return _layoutService.getPositionForOffset(offset)
    }

    func getClosestGlyphInfoForOffset(_ offset: Offset) -> GlyphInfo? {
        return _layoutService.getClosestGlyphInfo(offset)
    }

    func getGlyphInfoAt(_ codeUnitOffset: TextIndex) -> GlyphInfo? {
        let lineNumber = _findLine(codeUnitOffset, 0, numberOfLines)
        if lineNumber == nil {
            return nil
        }
        let line = lines[lineNumber!]
        let range = line.getCharacterRangeAt(codeUnitOffset)
        if range == nil {
            return nil
        }
        assert(line.overlapsWith(range!.start, range!.end))
        for fragment in line.fragments {
            if fragment.overlapsWith(start: range!.start, end: range!.end) {
                // If the grapheme cluster is split into multiple fragments (which really
                // shouldn't happen but currently if they are in different TextSpans they
                // don't combine), use the layout box of the first base character as its
                // layout box has a better chance to be not that far-off.
                let textBox = fragment.toTextBox(start: range!.start, end: range!.end)
                return GlyphInfo(
                    graphemeClusterLayoutBounds: textBox.toRect(),
                    graphemeClusterCodeUnitRange: range!,
                    writingDirection: textBox.direction
                )
            }
        }
        assert(false, "This should not be reachable.")
        return nil
    }

    func getWordBoundary(_ position: TextPosition) -> TextRange {
        let characterPosition: TextIndex
        switch position.affinity {
        case TextAffinity.upstream:
            characterPosition = position.offset - .one
        case TextAffinity.downstream:
            characterPosition = position.offset
        }
        let start = WordBreaker.prevBreakIndex(
            text: plainText,
            index: characterPosition.advanced(by: 1)
        )
        let end = WordBreaker.nextBreakIndex(text: plainText, index: characterPosition)
        return TextRange(start: start, end: end)
    }

    func getLineBoundary(_ position: TextPosition) -> TextRange {
        if lines.isEmpty {
            return TextRange.empty
        }
        let lineNumber = getLineNumberAt(position.offset)
        // Fallback to the last line for backward compatibility.
        let line = lineNumber != nil ? lines[lineNumber!] : lines.last!
        return TextRange(start: line.startIndex, end: line.endIndex - line.trailingNewlines)
    }

    func computeLineMetrics() -> [LineMetrics] {
        return lines.map { $0.lineMetrics }
    }

    func getLineMetricsAt(line: Int) -> LineMetrics? {
        return 0 <= line && line < lines.count
            ? lines[line].lineMetrics
            : nil
    }

    var numberOfLines: Int {
        return lines.count
    }

    func getLineNumberAt(_ offset: TextIndex) -> Int? {
        return _findLine(offset, 0, lines.count)
    }

    func _findLine(_ offset: TextIndex, _ startLine: Int, _ endLine: Int) -> Int? {
        assert(endLine <= lines.count)
        let isOutOfBounds =
            endLine <= startLine
            || offset < lines[startLine].startIndex
            || (endLine < numberOfLines && lines[endLine].startIndex <= offset)
        if isOutOfBounds {
            return nil
        }

        if endLine == startLine + 1 {
            assert(lines[startLine].startIndex <= offset)
            assert(endLine == numberOfLines || offset < lines[endLine].startIndex)
            return offset >= lines[startLine].visibleEndIndex ? nil : startLine
        }
        // endLine >= startLine + 2 thus we have
        // startLine + 1 <= midIndex <= endLine - 1
        let midIndex = (startLine + endLine) / 2
        return _findLine(offset, midIndex, endLine)
            ?? _findLine(offset, startLine, midIndex)
    }

    var _disposed = false

    func dispose() {
        // TODO(dnfield): It should be possible to clear resources here, but would
        // need refcounting done on any surfaces/pictures holding references to this
        // object.
        _disposed = true
    }

}

class ParagraphLine {
    init(
        hardBreak: Bool,
        ascent: Float,
        descent: Float,
        height: Float,
        width: Float,
        left: Float,
        baseline: Float,
        lineNumber: Int,
        startIndex: TextIndex,
        endIndex: TextIndex,
        trailingNewlines: TextIndex,
        trailingSpaces: TextIndex,
        spaceCount: TextIndex,
        widthWithTrailingSpaces: Float,
        fragments: [LayoutFragment],
        textDirection: TextDirection,
        paragraph: CanvasParagraph,
        displayText: String? = nil
    ) {
        assert(trailingNewlines <= endIndex - startIndex)
        self.lineMetrics = LineMetrics(
            startIndex: startIndex,
            endIndex: endIndex,
            endIncludingNewline: endIndex + trailingNewlines,
            endExcludingWhitespace: endIndex - trailingSpaces,
            hardBreak: hardBreak,
            ascent: ascent,
            descent: descent,
            unscaledAscent: ascent,
            height: height,
            width: width,
            left: left,
            baseline: baseline,
            lineNumber: lineNumber
        )
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.trailingNewlines = trailingNewlines
        self.trailingSpaces = trailingSpaces
        self.spaceCount = spaceCount
        self.widthWithTrailingSpaces = widthWithTrailingSpaces
        self.fragments = fragments
        self.textDirection = textDirection
        self.paragraph = paragraph
        self.displayText = displayText
    }

    /// Metrics for this line of the paragraph.
    let lineMetrics: LineMetrics

    /// The index (inclusive) in the text where this line begins.
    let startIndex: TextIndex

    /// The index (exclusive) in the text where this line ends.
    ///
    /// When the line contains an overflow, then [endIndex] goes until the end of
    /// the text and doesn't stop at the overflow cutoff.
    let endIndex: TextIndex

    /// The largest visible index (exclusive) in this line.
    ///
    /// When the line contains an overflow, or is ellipsized at the end, this is
    /// the largest index that remains visible in this line. If the entire line is
    /// ellipsized, this returns [startIndex];
    lazy var visibleEndIndex: TextIndex = {
        if fragments.isEmpty {
            return startIndex
        }
        if let last = fragments.last, last is EllipsisFragment {
            return fragments.dropLast().last?.end ?? startIndex
        }
        return fragments.last?.end ?? startIndex
    }()

    /// The number of new line characters at the end of the line.
    let trailingNewlines: TextIndex

    /// The number of spaces at the end of the line.
    let trailingSpaces: TextIndex

    /// The number of space characters in the entire line.
    let spaceCount: TextIndex

    /// The full width of the line including all trailing space but not new lines.
    ///
    /// The difference between [width] and [widthWithTrailingSpaces] is that
    /// [widthWithTrailingSpaces] includes trailing spaces in the width
    /// calculation while [width] doesn't.
    ///
    /// For alignment purposes for example, the [width] property is the right one
    /// to use because trailing spaces shouldn't affect the centering of text.
    /// But for placing cursors in text fields, we do care about trailing
    /// spaces so [widthWithTrailingSpaces] is more suitable.
    let widthWithTrailingSpaces: Float

    /// The fragments that make up this line.
    ///
    /// The fragments in the [List] are sorted by their logical order in within the
    /// line. In other words, a [LayoutFragment] in the [List] will have larger
    /// start and end indices than all [LayoutFragment]s that appear before it.
    let fragments: [LayoutFragment]

    /// The text direction of this line, which is the same as the paragraph's.
    let textDirection: TextDirection

    /// The text to be rendered on the screen representing this line.
    let displayText: String?

    /// The [CanvasParagraph] this line is part of.
    let paragraph: CanvasParagraph

    /// The number of space characters in the line excluding trailing spaces.
    var nonTrailingSpaces: TextIndex { spaceCount - trailingSpaces }

    // Convenient getters for line metrics properties.

    var hardBreak: Bool { lineMetrics.hardBreak }
    var ascent: Float { lineMetrics.ascent }
    var descent: Float { lineMetrics.descent }
    var unscaledAscent: Float { lineMetrics.unscaledAscent }
    var height: Float { lineMetrics.height }
    var width: Float { lineMetrics.width }
    var left: Float { lineMetrics.left }
    var baseline: Float { lineMetrics.baseline }
    var lineNumber: Int { lineMetrics.lineNumber }

    func overlapsWith(_ startIndex: TextIndex, _ endIndex: TextIndex) -> Bool {
        return startIndex < self.endIndex && self.startIndex < endIndex
    }

    func getText(_ paragraph: CanvasParagraph) -> String {
        var buffer = ""
        for fragment in fragments {
            buffer += fragment.getText(paragraph)
        }
        return buffer
    }

    // This is the fallback graphme breaker that is only used if Intl.Segmenter()
    // is not supported so _fromDomSegmenter can't be called. This implementation
    // breaks the text into UTF-16 codepoints instead of graphme clusters.
    func _fallbackGraphemeStartIterable(_ lineText: String) -> [TextIndex] {
        var graphemeStarts: [TextIndex] = []
        var precededByHighSurrogate = false
        for i in 0..<lineText.count {
            let index = lineText.index(lineText.startIndex, offsetBy: i)
            let codeUnit = lineText.utf16[index]
            let maskedCodeUnit = codeUnit & 0xFC00
            // Only skip `i` if it points to a low surrogate in a valid surrogate pair.
            if maskedCodeUnit != 0xDC00 || !precededByHighSurrogate {
                graphemeStarts.append(startIndex.advanced(by: i))
            }
            precededByHighSurrogate = maskedCodeUnit == 0xD800
        }
        return graphemeStarts
    }

    func _breakTextIntoGraphemes(_ text: String) -> [TextIndex] {
        var graphemeStarts = _fallbackGraphemeStartIterable(text)
        // Add the end index of the fragment to the list if the text is not empty.
        if !graphemeStarts.isEmpty {
            graphemeStarts.append(visibleEndIndex)
        }
        return graphemeStarts
    }

    /// This List contains an ascending sequence of UTF16 offsets that points to
    /// grapheme starts within the line. Each UTF16 offset is relative to the
    /// start of the paragraph, instead of the start of the line.
    ///
    /// For example, `graphemeStarts[n]` gives the UTF16 offset of the `n`-th
    /// grapheme in the line.
    lazy var graphemeStarts: [TextIndex] = {
        if visibleEndIndex == startIndex {
            return []
        }
        let substringStart = paragraph.plainText.index(
            paragraph.plainText.startIndex,
            offsetBy: startIndex.utf16Offset
        )
        let substringEnd = paragraph.plainText.index(
            paragraph.plainText.startIndex,
            offsetBy: visibleEndIndex.utf16Offset
        )
        let substring = String(paragraph.plainText[substringStart..<substringEnd])
        return _breakTextIntoGraphemes(substring)
    }()

    /// Translate a UTF16 code unit in the paragaph (`offset`), to a grapheme
    /// offset with in the current line.
    ///
    /// The `start` and `end` parameters are both grapheme offsets within the
    /// current line. They are used to limit the search range (so the return value
    /// that corresponds to the code unit `offset` must be with in [start, end)).
    func graphemeStartIndexBefore(_ offset: TextIndex, _ start: Int, _ end: Int) -> Int {
        var low = start
        var high = end
        assert(0 <= low)
        assert(low < high)

        let lineGraphemeBreaks = graphemeStarts
        assert(offset >= lineGraphemeBreaks[start])
        assert(offset < lineGraphemeBreaks.last!, "\(offset), \(lineGraphemeBreaks)")
        assert(end == lineGraphemeBreaks.count || offset < lineGraphemeBreaks[end])
        while low + 2 <= high {
            // high >= low + 2, so low + 1 <= mid <= high - 1
            let mid = (low + high) / 2
            switch lineGraphemeBreaks[mid].utf16Offset - offset.utf16Offset {
            case let diff where diff > 0: high = mid
            case let diff where diff < 0: low = mid
            case 0: return mid
            default: break
            }
        }

        assert(lineGraphemeBreaks[low] <= offset)
        assert(high == lineGraphemeBreaks.count || offset < lineGraphemeBreaks[high])
        return low
    }

    /// Returns the UTF-16 range of the character that encloses the code unit at
    /// the given offset.
    func getCharacterRangeAt(_ codeUnitOffset: TextIndex) -> TextRange? {
        assert(codeUnitOffset >= self.startIndex)
        if codeUnitOffset >= visibleEndIndex || graphemeStarts.isEmpty {
            return nil
        }

        let startIndex = graphemeStartIndexBefore(codeUnitOffset, 0, graphemeStarts.count)
        assert(startIndex < graphemeStarts.count - 1)
        return TextRange(start: graphemeStarts[startIndex], end: graphemeStarts[startIndex + 1])
    }

    func closestFragmentTo(_ targetFragment: LayoutFragment, searchLeft: Bool) -> LayoutFragment? {
        var closestFragment: (fragment: LayoutFragment, distance: Float)? = nil
        for fragment in fragments {
            assert(!(fragment is EllipsisFragment))
            if fragment.start >= visibleEndIndex {
                break
            }
            if fragment.getGraphemeStartIndexRange() == nil {
                continue
            }
            let distance =
                searchLeft
                ? targetFragment.left - fragment.right
                : fragment.left - targetFragment.right
            let minDistance = closestFragment?.distance
            switch distance {
            case let d where d > 0.0 && (minDistance == nil || minDistance! > d):
                closestFragment = (fragment: fragment, distance: d)
            case 0.0: return fragment
            default: continue
            }
        }
        return closestFragment?.fragment
    }

    /// Finds the closest [LayoutFragment] to the given horizontal offset `dx` in
    /// this line, that is not an [EllipsisFragment] and contains at least one
    /// grapheme start.
    func closestFragmentAtOffset(_ dx: Float) -> LayoutFragment? {
        if graphemeStarts.isEmpty {
            return nil
        }
        assert(graphemeStarts.count >= 2)
        var graphemeIndex = 0
        var closestFragment: (fragment: LayoutFragment, distance: Float)? = nil
        for fragment in fragments {
            assert(!(fragment is EllipsisFragment))
            if fragment.start >= visibleEndIndex {
                break
            }
            if fragment.length == .zero {
                continue
            }
            while fragment.start > graphemeStarts[graphemeIndex] {
                graphemeIndex += 1
            }
            let firstGraphemeStartInFragment = graphemeStarts[graphemeIndex]
            if firstGraphemeStartInFragment >= fragment.end {
                continue
            }
            let distance: Float
            if dx < fragment.left {
                distance = fragment.left - dx
            } else if dx > fragment.right {
                distance = dx - fragment.right
            } else {
                return fragment
            }
            assert(distance > 0)

            let minDistance = closestFragment?.distance
            if minDistance == nil || minDistance! > distance {
                closestFragment = (fragment: fragment, distance: distance)
            }
        }
        return closestFragment?.fragment
    }
}

extension ParagraphLine: CustomStringConvertible {
    var description: String {
        return
            "\(type(of: self))(\(startIndex.utf16Offset), \(endIndex.utf16Offset), \(lineMetrics))"
    }
}

extension ParagraphStyle {
    var effectiveTextDirection: TextDirection {
        return self.textDirection ?? .ltr
    }

    var effectiveTextAlign: TextAlign {
        return self.textAlign ?? .start
    }
}
