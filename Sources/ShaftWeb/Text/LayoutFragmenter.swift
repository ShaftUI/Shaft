// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Shaft

/// Splits [text] into fragments that are ready to be laid out by
/// [TextLayoutService].
///
/// This fragmenter takes into account line breaks, directionality and styles.
class LayoutFragmenter: TextFragmenter {
    init(_ text: String, _ paragraphSpans: [ParagraphSpanProtocol]) {
        self.text = text
        self.paragraphSpans = paragraphSpans
    }

    let text: String
    let paragraphSpans: [ParagraphSpanProtocol]

    func fragment() -> [LayoutFragment] {
        var fragments: [LayoutFragment] = []

        var fragmentStart = TextIndex.zero

        let lineBreakFragmenter = createLineBreakFragmenter(text: text)
        var lineBreakFragments = lineBreakFragmenter.fragment().makeIterator()

        let bidiFragmenter = BidiFragmenter(text)
        var bidiFragments = bidiFragmenter.fragment().makeIterator()

        var spans = paragraphSpans.makeIterator()

        guard var currentLineBreakFragment = lineBreakFragments.next(),
            var currentBidiFragment = bidiFragments.next(),
            var currentSpan = spans.next()
        else {
            return fragments
        }

        while true {
            let fragmentEnd = min(
                currentLineBreakFragment.end,
                min(
                    currentBidiFragment.end,
                    currentSpan.end
                )
            )

            let distanceFromLineBreak = currentLineBreakFragment.end - fragmentEnd

            let lineBreakType =
                distanceFromLineBreak == .zero
                ? currentLineBreakFragment.type
                : LineBreakType.prohibited

            let trailingNewlines = currentLineBreakFragment.trailingNewlines - distanceFromLineBreak
            let trailingSpaces = currentLineBreakFragment.trailingSpaces - distanceFromLineBreak

            let fragmentLength = fragmentEnd - fragmentStart
            fragments.append(
                LayoutFragment(
                    fragmentStart,
                    fragmentEnd,
                    lineBreakType,
                    currentBidiFragment.textDirection,
                    currentBidiFragment.fragmentFlow,
                    currentSpan,
                    trailingNewlines: max(.zero, min(trailingNewlines, fragmentLength)),
                    trailingSpaces: max(.zero, min(trailingSpaces, fragmentLength))
                )
            )

            fragmentStart = fragmentEnd

            var moved = false
            if currentLineBreakFragment.end == fragmentEnd {
                if let next = lineBreakFragments.next() {
                    moved = true
                    currentLineBreakFragment = next
                }
            }
            if currentBidiFragment.end == fragmentEnd {
                if let next = bidiFragments.next() {
                    moved = true
                    currentBidiFragment = next
                }
            }
            if currentSpan.end == fragmentEnd {
                if let next = spans.next() {
                    moved = true
                    currentSpan = next
                }
            }

            // Once we reached the end of all fragments, exit the loop.
            if !moved {
                break
            }
        }

        return fragments
    }
}

/// A protocol that combines text fragment with additional layout properties.
protocol CombinedFragment: TextFragment, AnyObject {
    var type: LineBreakType { get }
    var textDirection: TextDirection? { get set }
    var fragmentFlow: FragmentFlow { get }
    var span: ParagraphSpanProtocol { get }
    var trailingNewlines: TextIndex { get }
    var trailingSpaces: TextIndex { get }
}

class LayoutFragment: CombinedFragment, FragmentMetrics, FragmentPosition, FragmentBox {
    var start: TextIndex
    var end: TextIndex
    var type: LineBreakType
    var textDirection: TextDirection?
    var fragmentFlow: FragmentFlow
    var span: ParagraphSpanProtocol
    var trailingNewlines: TextIndex
    var trailingSpaces: TextIndex

    // FragmentMetrics properties
    var spanometer: Spanometer!
    var ascent: Float = 0.0
    var descent: Float = 0.0
    var widthExcludingTrailingSpaces: Float = 0.0
    var widthIncludingTrailingSpaces: Float = 0.0
    var extraWidthForJustification: Float = 0.0

    // FragmentPosition properties
    var startOffset: Float = 0.0
    var line: ParagraphLine!

    init(
        _ start: TextIndex,
        _ end: TextIndex,
        _ type: LineBreakType,
        _ textDirection: TextDirection?,
        _ fragmentFlow: FragmentFlow,
        _ span: ParagraphSpanProtocol,
        trailingNewlines: TextIndex,
        trailingSpaces: TextIndex
    ) {
        self.start = start
        self.end = end
        self.type = type
        self.textDirection = textDirection
        self.fragmentFlow = fragmentFlow
        self.span = span
        self.trailingNewlines = trailingNewlines
        self.trailingSpaces = trailingSpaces
    }

    var length: TextIndex { return end - start }
    var isSpaceOnly: Bool { return length == trailingSpaces }
    var isPlaceholder: Bool { return span is PlaceholderSpan }
    var isBreak: Bool { return type != .prohibited }
    var isHardBreak: Bool { return type == .mandatory || type == .endOfText }
    var style: SpanStyle { return span.style }

    /// Returns the substring from paragraph that corresponds to this fragment,
    /// excluding new line characters.
    func getText(_ paragraph: CanvasParagraph) -> String {
        return (start..<(end - trailingNewlines)).textInside(paragraph.plainText)
    }

    /// Splits this fragment into two fragments with the split point being the
    /// given index.
    func split(_ index: TextIndex) -> [LayoutFragment?] {
        assert(start <= index)
        assert(index <= end)

        if start == index {
            return [nil, self]
        }

        if end == index {
            return [self, nil]
        }

        // The length of the second fragment after the split.
        let secondLength = end - index

        // Trailing spaces/new lines go to the second fragment. Any left over goes
        // to the first fragment.
        let secondTrailingNewlines = min(trailingNewlines, secondLength)
        let secondTrailingSpaces = min(trailingSpaces, secondLength)

        return [
            LayoutFragment(
                start,
                index,
                .prohibited,
                textDirection,
                fragmentFlow,
                span,
                trailingNewlines: trailingNewlines - secondTrailingNewlines,
                trailingSpaces: trailingSpaces - secondTrailingSpaces
            ),
            LayoutFragment(
                index,
                end,
                type,
                textDirection,
                fragmentFlow,
                span,
                trailingNewlines: secondTrailingNewlines,
                trailingSpaces: secondTrailingSpaces
            ),
        ]
    }
}

protocol FragmentMetrics: AnyObject {
    /// The spanometer used for measuring text.
    var spanometer: Spanometer! { get set }

    /// The rise from the baseline as calculated from the font and style for this text.
    var ascent: Float { get set }

    /// The drop from the baseline as calculated from the font and style for this text.
    var descent: Float { get set }

    /// The width of the measured text, not including trailing spaces.
    var widthExcludingTrailingSpaces: Float { get set }

    /// The width of the measured text, including any trailing spaces.
    var widthIncludingTrailingSpaces: Float { get set }

    /// Extra width added for justification.
    var extraWidthForJustification: Float { get set }

    /// The total height as calculated from the font and style for this text.
    var height: Float { get }

    /// The width of trailing spaces in the fragment.
    var widthOfTrailingSpaces: Float { get }

    /// Set measurement values for the fragment.
    func setMetrics(
        _ spanometer: Spanometer,
        ascent: Float,
        descent: Float,
        widthExcludingTrailingSpaces: Float,
        widthIncludingTrailingSpaces: Float
    )
}

extension FragmentMetrics {
    var height: Float {
        return ascent + descent
    }

    var widthOfTrailingSpaces: Float {
        return widthIncludingTrailingSpaces - widthExcludingTrailingSpaces
    }

    func setMetrics(
        _ spanometer: Spanometer,
        ascent: Float,
        descent: Float,
        widthExcludingTrailingSpaces: Float,
        widthIncludingTrailingSpaces: Float
    ) {
        self.spanometer = spanometer
        self.ascent = ascent
        self.descent = descent
        self.widthExcludingTrailingSpaces = widthExcludingTrailingSpaces
        self.widthIncludingTrailingSpaces = widthIncludingTrailingSpaces
    }
}

/// Encapsulates positioning of the fragment relative to the line.
///
/// The coordinates are all relative to the line it belongs to. For example,
/// [left] is the distance from the left edge of the line to the left edge of
/// the fragment.
///
/// This is what the various measurements/coordinates look like for a fragment
/// in an LTR paragraph:
///
///          *------------------------line.width-----------------*
///                            *---width----*
///          ┌─────────────────┬────────────┬────────────────────┐
///          │                 │--FRAGMENT--│                    │
///          └─────────────────┴────────────┴────────────────────┘
///          *---startOffset---*
///          *------left-------*
///          *--------endOffset-------------*
///          *----------right---------------*
///
///
/// And in an RTL paragraph, [startOffset] and [endOffset] are flipped because
/// the line starts from the right. Here's what they look like:
///
///          *------------------------line.width-----------------*
///                            *---width----*
///          ┌─────────────────┬────────────┬────────────────────┐
///          │                 │--FRAGMENT--│                    │
///          └─────────────────┴────────────┴────────────────────┘
///                                         *----startOffset-----*
///          *------left-------*
///                            *-----------endOffset-------------*
///          *----------right---------------*
///
protocol FragmentPosition: CombinedFragment, FragmentMetrics, AnyObject {
    /// The distance from the beginning of the line to the beginning of the fragment.
    var startOffset: Float { get set }

    /// The width of the line that contains this fragment.
    var line: ParagraphLine! { get set }

    /// The distance from the beginning of the line to the end of the fragment.
    var endOffset: Float { get }

    /// The distance from the left edge of the line to the left edge of the fragment.
    var left: Float { get }

    /// The distance from the left edge of the line to the right edge of the fragment.
    var right: Float { get }

    /// Set the horizontal position of this fragment relative to the [line] that
    /// contains it.
    func setPosition(startOffset: Float, textDirection: TextDirection)

    /// Adjust the width of this fragment for paragraph justification.
    func justifyTo(paragraphWidth: Float)
}

extension FragmentPosition {
    var endOffset: Float {
        return startOffset + widthIncludingTrailingSpaces
    }

    var left: Float {
        return line.textDirection == .ltr
            ? startOffset
            : line.width - endOffset
    }

    var right: Float {
        return line.textDirection == .ltr
            ? endOffset
            : line.width - startOffset
    }

    /// Set the horizontal position of this fragment relative to the [line] that
    /// contains it.
    func setPosition(startOffset: Float, textDirection: TextDirection) {
        self.startOffset = startOffset
        self.textDirection = textDirection
    }

    func justifyTo(paragraphWidth: Float) {
        // Only justify this fragment if it's not a trailing space in the line.
        if end > line.endIndex - line.trailingSpaces {
            // Don't justify fragments that are part of trailing spaces of the line.
            return
        }

        if trailingSpaces == .zero {
            // If this fragment has no spaces, there's nothing to justify.
            return
        }

        let justificationTotal = paragraphWidth - line.width
        let justificationPerSpace = justificationTotal / Float(line.nonTrailingSpaces.utf16Offset)
        extraWidthForJustification = justificationPerSpace * Float(trailingSpaces.utf16Offset)
    }
}

/// Encapsulates calculations related to the bounding box of the fragment
/// relative to the paragraph.
protocol FragmentBox: FragmentMetrics, FragmentPosition {
    /// The distance from the top of the paragraph to the top edge of the fragment.
    var top: Float { get }

    /// The distance from the top of the paragraph to the bottom edge of the fragment.
    var bottom: Float { get }

    /// Whether the trailing spaces of this fragment are part of trailing
    /// spaces of the line containing the fragment.
    var isPartOfTrailingSpacesInLine: Bool { get }

    /// Returns a TextBox for the purpose of painting this fragment.
    ///
    /// The coordinates of the resulting TextBox are relative to the
    /// paragraph, not to the line.
    ///
    /// Trailing spaces in each line aren't painted on the screen, so they are
    /// excluded from the resulting text box.
    func toPaintingTextBox() -> TextBox

    /// Returns a TextBox representing this fragment.
    ///
    /// The coordinates of the resulting TextBox are relative to the
    /// paragraph, not to the line.
    ///
    /// As opposed to toPaintingTextBox, the resulting text box from this method
    /// includes trailing spaces of the fragment.
    func toTextBox(start: TextIndex?, end: TextIndex?) -> TextBox

    /// Returns the text position within this fragment's range that's closest to
    /// the given x offset.
    ///
    /// The x offset is expected to be relative to the left edge of the fragment.
    func getPositionForX(_ x: Float) -> TextPosition

    /// Whether the first codepoints of this fragment is not a valid grapheme start,
    /// and belongs in the the previous fragment.
    var hasLeadingBrokenGrapheme: Bool { get }

    /// Returns the GlyphInfo of the character in the fragment that is closest to
    /// the given offset x.
    func getClosestCharacterBox(_ x: Float) -> GlyphInfo
}

extension FragmentBox {
    var top: Float {
        return line.baseline - ascent
    }

    var bottom: Float {
        return line.baseline + descent
    }

    var isPartOfTrailingSpacesInLine: Bool {
        return end > line.endIndex - line.trailingSpaces
    }

    func toPaintingTextBox() -> TextBox {
        if isPartOfTrailingSpacesInLine {
            // For painting, we exclude the width of trailing spaces from the box.
            return textDirection == .ltr
                ? TextBox(
                    left: line.left + left,
                    top: top,
                    right: line.left + right - widthOfTrailingSpaces,
                    bottom: bottom,
                    direction: textDirection!
                )
                : TextBox(
                    left: line.left + left + widthOfTrailingSpaces,
                    top: top,
                    right: line.left + right,
                    bottom: bottom,
                    direction: textDirection!
                )
        }
        return TextBox(
            left: line.left + left,
            top: top,
            right: line.left + right,
            bottom: bottom,
            direction: textDirection!
        )
    }

    func toTextBox(start: TextIndex? = nil, end: TextIndex? = nil) -> TextBox {
        let startIndex = start ?? self.start
        let endIndex = end ?? self.end

        if startIndex <= self.start && endIndex >= (self.end - trailingNewlines) {
            return TextBox(
                left: line.left + left,
                top: top,
                right: line.left + right,
                bottom: bottom,
                direction: textDirection!
            )
        }
        return intersect(startIndex, endIndex)
    }

    /// Performs the intersection of this fragment with the range given by start and
    /// end indices, and returns a TextBox representing that intersection.
    ///
    /// The coordinates of the resulting TextBox are relative to the
    /// paragraph, not to the line.
    func intersect(_ start: TextIndex, _ end: TextIndex) -> TextBox {
        // `intersect` should only be called when there's an actual intersection.
        assert(start > self.start || end < self.end)

        let before: Float
        if start <= self.start {
            before = 0.0
        } else {
            spanometer.currentSpan = span
            before = spanometer.measureRange(start: self.start, end: start)
        }

        let after: Float
        if end >= (self.end - trailingNewlines) {
            after = 0.0
        } else {
            spanometer.currentSpan = span
            after = spanometer.measureRange(
                start: end,
                end: self.end - trailingNewlines
            )
        }

        let (left, right): (Float, Float)
        if textDirection == .ltr {
            // Example: let's say the text is "Loremipsum" and we want to get the box
            // for "rem". In this case, `before` is the width of "Lo", and `after`
            // is the width of "ipsum".
            //
            // Here's how the measurements/coordinates look like:
            //
            //              before         after
            //              |----|     |----------|
            //              +---------------------+
            //              | L o r e m i p s u m |
            //              +---------------------+
            //    this.left ^                     ^ this.right
            left = self.left + before
            right = self.right - after
        } else {
            // Example: let's say the text is "txet_werbeH" ("Hebrew_text" flowing from
            // right to left). Say we want to get the box for "brew". The `before` is
            // the width of "He", and `after` is the width of "_text".
            //
            //                 after           before
            //              |----------|       |----|
            //              +-----------------------+
            //              | t x e t _ w e r b e H |
            //              +-----------------------+
            //    this.left ^                       ^ this.right
            //
            // Notice how `before` and `after` are reversed in the RTL example. That's
            // because the text flows from right to left.
            left = self.left + after
            right = self.right - before
        }

        return TextBox(
            left: line.left + left,
            top: top,
            right: line.left + right,
            bottom: bottom,
            direction: textDirection!
        )
    }

    func getPositionForX(_ x: Float) -> TextPosition {
        let adjustedX = makeXDirectionAgnostic(x)

        let startIndex = start
        let endIndex = end - trailingNewlines

        // Check some special cases to return the result quicker.
        let length = endIndex - startIndex
        if length == .zero {
            return TextPosition(offset: startIndex)
        }
        if length == .one {
            // Find out if `x` is closer to `startIndex` or `endIndex`.
            let distanceFromStart = adjustedX
            let distanceFromEnd = widthIncludingTrailingSpaces - adjustedX
            return distanceFromStart < distanceFromEnd
                ? TextPosition(offset: startIndex)
                : TextPosition(offset: endIndex, affinity: .upstream)
        }

        spanometer.currentSpan = span
        // The resulting `cutoff` is the index of the character where the `x` offset
        // falls. We should return the text position of either `cutoff` or
        // `cutoff + 1` depending on which one `x` is closer to.
        //
        //   offset x
        //      ↓
        // "A B C D E F"
        //     ↑
        //   cutoff
        let cutoff = spanometer.forceBreak(
            start: startIndex,
            end: endIndex,
            availableWidth: adjustedX,
            allowEmpty: true
        )

        if cutoff == endIndex {
            return TextPosition(
                offset: cutoff,
                affinity: .upstream
            )
        }

        let lowWidth = spanometer.measureRange(start: startIndex, end: cutoff)
        let highWidth = spanometer.measureRange(start: startIndex, end: cutoff.advanced(by: 1))

        // See if `x` is closer to `cutoff` or `cutoff + 1`.
        if adjustedX - lowWidth < highWidth - adjustedX {
            // The offset is closer to cutoff.
            return TextPosition(offset: cutoff)
        } else {
            // The offset is closer to cutoff + 1.
            return TextPosition(
                offset: cutoff.advanced(by: 1),
                affinity: .upstream
            )
        }
    }
    /// Transforms the [x] coordinate to be direction-agnostic.
    ///
    /// The X (input) is relative to the [left] edge of the fragment, and this
    /// method returns an X' (output) that's relative to beginning of the text.
    ///
    /// Here's how it looks for a fragment with LTR content:
    ///
    ///          *------------------------line width------------------*
    ///                      *-----X (input)
    ///          ┌───────────┬────────────────────────┬───────────────┐
    ///          │           │ ---text-direction----> │               │
    ///          └───────────┴────────────────────────┴───────────────┘
    ///                      *-----X' (output)
    ///          *---left----*
    ///          *---------------right----------------*
    ///
    ///
    /// And here's how it looks for a fragment with RTL content:
    ///
    ///          *------------------------line width------------------*
    ///                      *-----X (input)
    ///          ┌───────────┬────────────────────────┬───────────────┐
    ///          │           │ <---text-direction---- │               │
    ///          └───────────┴────────────────────────┴───────────────┘
    ///                   (output) X'-----------------*
    ///          *---left----*
    ///          *---------------right----------------*
    ///
    func makeXDirectionAgnostic(_ x: Float) -> Float {
        if textDirection == .rtl {
            return widthIncludingTrailingSpaces - x
        }
        return x
    }

    func getClosestCharacterBox(_ x: Float) -> GlyphInfo {
        assert(end > start)
        guard let graphemeStartIndexRange = getGraphemeStartIndexRange() else {
            fatalError("Fragment must have at least one grapheme start")
        }

        let (rangeStart, rangeEnd) = graphemeStartIndexRange
        return getClosestCharacterInRange(x, rangeStart, rangeEnd)
    }

    func getGraphemeStartIndexRange() -> (Int, Int)? {
        if end == start {
            return nil
        }

        let lineGraphemeBreaks = line.graphemeStarts
        assert(end > start)
        assert(!lineGraphemeBreaks.isEmpty)

        let startIndex = line.graphemeStartIndexBefore(start, 0, lineGraphemeBreaks.count)
        let endIndex =
            end == start.advanced(by: 1)
            ? startIndex + 1
            : line.graphemeStartIndexBefore(
                end.advanced(by: -1),
                startIndex,
                lineGraphemeBreaks.count
            ) + 1

        let firstGraphemeStart = lineGraphemeBreaks[startIndex]
        return firstGraphemeStart > start
            ? (endIndex == startIndex + 1 ? nil : (startIndex + 1, endIndex))
            : (startIndex, endIndex)
    }

    var hasLeadingBrokenGrapheme: Bool {
        guard let graphemeStartIndexRange = getGraphemeStartIndexRange() else {
            return true
        }
        let graphemeStartIndexRangeStart = graphemeStartIndexRange.0
        return line.graphemeStarts[graphemeStartIndexRangeStart] != start
    }

    func getClosestCharacterInRange(_ x: Float, _ startIndex: Int, _ endIndex: Int) -> GlyphInfo {
        let graphemeStartIndices = line.graphemeStarts
        let fullRange = TextRange(
            start: graphemeStartIndices[startIndex],
            end: graphemeStartIndices[endIndex]
        )
        let fullBox = toTextBox(start: fullRange.start, end: fullRange.end)

        if startIndex + 1 == endIndex {
            return GlyphInfo(
                graphemeClusterLayoutBounds: fullBox.toRect(),
                graphemeClusterCodeUnitRange: fullRange,
                writingDirection: fullBox.direction
            )
        }

        assert(startIndex + 1 < endIndex)
        let left = fullBox.left
        let right = fullBox.right

        // The toTextBox call is potentially expensive so we'll try reducing the
        // search steps with a binary search.
        //
        // x ∈ (left, right),
        if left < x && x < right {
            let midIndex = (startIndex + endIndex) / 2
            // endIndex >= startIndex + 2, so midIndex >= start + 1
            let firstHalf = getClosestCharacterInRange(x, startIndex, midIndex)
            if firstHalf.graphemeClusterLayoutBounds.left < x
                && x < firstHalf.graphemeClusterLayoutBounds.right
            {
                return firstHalf
            }
            // startIndex <= endIndex - 2, so midIndex <= endIndex - 1
            let secondHalf = getClosestCharacterInRange(x, midIndex, endIndex)
            if secondHalf.graphemeClusterLayoutBounds.left < x
                && x < secondHalf.graphemeClusterLayoutBounds.right
            {
                return secondHalf
            }
            // Neither box clips the given x. This is supposed to be rare.
            let distanceToFirst = abs(
                x
                    - min(
                        max(firstHalf.graphemeClusterLayoutBounds.left, x),
                        firstHalf.graphemeClusterLayoutBounds.right
                    )
            )
            let distanceToSecond = abs(
                x
                    - min(
                        max(secondHalf.graphemeClusterLayoutBounds.left, x),
                        secondHalf.graphemeClusterLayoutBounds.right
                    )
            )
            return distanceToFirst > distanceToSecond ? firstHalf : secondHalf
        }

        // x ∉ (left, right), it's either the first character or the last, since
        // there can only be one writing direction in the fragment.
        let range: TextRange
        switch (fullBox.direction, x <= left) {
        case (.ltr, true), (.rtl, false):
            range = TextRange(
                start: graphemeStartIndices[startIndex],
                end: graphemeStartIndices[startIndex + 1]
            )
        case (.ltr, false), (.rtl, true):
            range = TextRange(
                start: graphemeStartIndices[endIndex - 1],
                end: graphemeStartIndices[endIndex]
            )
        }

        assert(!range.isCollapsed)
        let box = toTextBox(start: range.start, end: range.end)
        return GlyphInfo(
            graphemeClusterLayoutBounds: box.toRect(),
            graphemeClusterCodeUnitRange: range,
            writingDirection: box.direction
        )
    }
}

class EllipsisFragment: LayoutFragment {
    init(
        index: TextIndex,
        span: ParagraphSpanProtocol
    ) {
        super.init(
            index,
            index,
            LineBreakType.endOfText,
            nil,
            // The ellipsis is always at the end of the line, so it can't be
            // sandwiched. This means it'll always follow the paragraph direction.
            FragmentFlow.sandwich,
            span,
            trailingNewlines: TextIndex.zero,
            trailingSpaces: TextIndex.zero
        )
    }

    override var isSpaceOnly: Bool { false }

    override var isPlaceholder: Bool { false }

    override func getText(_ paragraph: CanvasParagraph) -> String {
        return paragraph.paragraphStyle.ellipsis!
    }

    override func split(_ index: TextIndex) -> [LayoutFragment?] {
        fatalError("Cannot split an EllipsisFragment")
    }
}
