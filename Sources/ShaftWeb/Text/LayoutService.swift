import JavaScriptKit
import Shaft

/// A single canvas2d context to use for all text measurements.
var textContext: JSValue = {
    // We don't use this canvas to draw anything, so let's make it as small as
    // possible to save memory.
    return createDomCanvasElement(width: 0, height: 0).getContext("2d")
}()

/// The last font used in the [textContext].
private var _lastContextFont: String?

/// Performs layout on a [CanvasParagraph].
///
/// It uses a [DomCanvasElement] to measure text.
class TextLayoutService {
    init(_ paragraph: CanvasParagraph) {
        self.paragraph = paragraph
    }

    unowned let paragraph: CanvasParagraph

    // *** Results of layout *** //

    // Look at the Paragraph class for documentation of the following properties.

    var width: Float = -1.0

    var height: Float = 0.0

    var longestLine: ParagraphLine?

    var minIntrinsicWidth: Float = 0.0

    var maxIntrinsicWidth: Float = 0.0

    var alphabeticBaseline: Float = -1.0

    var ideographicBaseline: Float = -1.0

    var didExceedMaxLines: Bool = false

    var lines: [ParagraphLine] = []

    /// The bounds that contain the text painted inside this paragraph.
    var paintBounds: Rect {
        _paintBounds
    }
    private var _paintBounds: Rect = Rect.zero

    lazy var spanometer: Spanometer = Spanometer(paragraph: paragraph)

    lazy var layoutFragmenter: LayoutFragmenter = LayoutFragmenter(
        paragraph.plainText,
        paragraph.spans
    )

    /// Performs the layout on a paragraph given the [constraints].
    ///
    /// The function starts by resetting all layout-related properties. Then it
    /// starts looping through the paragraph to calculate all layout metrics.
    ///
    /// It uses a [Spanometer] to perform measurements within spans of the
    /// paragraph. It also uses [LineBuilders] to generate [ParagraphLine]s as
    /// it iterates through the paragraph.
    ///
    /// The main loop keeps going until:
    ///
    /// 1. The end of the paragraph is reached (i.e. LineBreakType.endOfText).
    /// 2. Enough lines have been computed to satisfy [maxLines].
    /// 3. An ellipsis is appended because of an overflow.
    func performLayout(_ constraints: ParagraphConstraints) {
        // Reset results from previous layout.
        // width = constraints.width
        width =
            switch constraints {
            case .width(let width): width
            }
        height = 0.0
        longestLine = nil
        minIntrinsicWidth = 0.0
        maxIntrinsicWidth = 0.0
        didExceedMaxLines = false
        lines.removeAll()

        let constraintsWidth =
            switch constraints {
            case .width(let width): width
            }
        var currentLine = LineBuilder.first(
            paragraph: paragraph,
            spanometer: spanometer,
            maxWidth: constraintsWidth
        )

        let fragments = layoutFragmenter.fragment()
        for fragment in fragments {
            spanometer.measureFragment(fragment)
        }

        outerLoop: for var i in 0..<fragments.count {
            let fragment = fragments[i]

            currentLine.addFragment(fragment)

            while currentLine.isOverflowing {
                if currentLine.canHaveEllipsis {
                    currentLine.insertEllipsis()
                    lines.append(currentLine.build())
                    didExceedMaxLines = true
                    break outerLoop
                }

                if currentLine.isBreakable {
                    currentLine.revertToLastBreakOpportunity()
                } else {
                    // The line can't be legally broken, so the last fragment (that caused
                    // the line to overflow) needs to be force-broken.
                    currentLine.forceBreakLastFragment()
                }

                i += currentLine.appendZeroWidthFragments(fragments, startFrom: i + 1)
                lines.append(currentLine.build())
                currentLine = currentLine.nextLine()
            }

            if currentLine.isHardBreak {
                lines.append(currentLine.build())
                currentLine = currentLine.nextLine()
            }
        }

        let maxLines = paragraph.paragraphStyle.maxLines
        if let maxLines = maxLines, lines.count > maxLines {
            didExceedMaxLines = true
            lines.removeSubrange(maxLines..<lines.count)
        }

        // ***************************************************************** //
        // *** PARAGRAPH BASELINE & HEIGHT & LONGEST LINE & PAINT BOUNDS *** //
        // ***************************************************************** //

        var boundsLeft = Float.infinity
        var boundsRight = -Float.infinity
        for line in lines {
            height += line.height
            if alphabeticBaseline == -1.0 {
                alphabeticBaseline = line.baseline
                ideographicBaseline = alphabeticBaseline * baselineRatioHack
            }
            let longestLineWidth = longestLine?.width ?? 0.0
            if longestLineWidth < line.width {
                longestLine = line
            }

            let left = line.left
            if left < boundsLeft {
                boundsLeft = left
            }
            let right = left + line.width
            if right > boundsRight {
                boundsRight = right
            }
        }
        _paintBounds = Rect(
            left: boundsLeft,
            top: 0,
            right: boundsRight,
            bottom: height
        )

        // **************************** //
        // *** FRAGMENT POSITIONING *** //
        // **************************** //

        // We have to perform justification alignment first so that we can position
        // fragments correctly later.
        if !lines.isEmpty {
            let shouldJustifyParagraph =
                width.isFinite && paragraph.paragraphStyle.textAlign == TextAlign.justify

            if shouldJustifyParagraph {
                // Don't apply justification to the last line.
                for i in 0..<(lines.count - 1) {
                    for fragment in lines[i].fragments {
                        fragment.justifyTo(paragraphWidth: width)
                    }
                }
            }
        }

        lines.forEach(_positionLineFragments)

        // ******************************** //
        // *** MAX/MIN INTRINSIC WIDTHS *** //
        // ******************************** //

        // TODO(mdebbar): Handle maxLines https://github.com/flutter/flutter/issues/91254

        var runningMinIntrinsicWidth: Float = 0
        var runningMaxIntrinsicWidth: Float = 0

        for fragment in fragments {
            runningMinIntrinsicWidth += fragment.widthExcludingTrailingSpaces
            // Max intrinsic width includes the width of trailing spaces.
            runningMaxIntrinsicWidth += fragment.widthIncludingTrailingSpaces

            switch fragment.type {
            case .prohibited:
                break

            case .opportunity:
                minIntrinsicWidth = max(minIntrinsicWidth, runningMinIntrinsicWidth)
                runningMinIntrinsicWidth = 0

            case .mandatory, .endOfText:
                minIntrinsicWidth = max(minIntrinsicWidth, runningMinIntrinsicWidth)
                maxIntrinsicWidth = max(maxIntrinsicWidth, runningMaxIntrinsicWidth)
                runningMinIntrinsicWidth = 0
                runningMaxIntrinsicWidth = 0
            }
        }
    }

    private var _paragraphDirection: TextDirection {
        paragraph.paragraphStyle.effectiveTextDirection
    }

    /// Positions the fragments taking into account their directions and the
    /// paragraph's direction.
    private func _positionLineFragments(_ line: ParagraphLine) {
        var previousDirection = _paragraphDirection

        var startOffset: Float = 0.0
        var sandwichStart: Int?
        var sequenceStart = 0

        for i in 0...line.fragments.count {
            if i < line.fragments.count {
                let fragment = line.fragments[i]

                if fragment.fragmentFlow == .previous {
                    sandwichStart = nil
                    continue
                }
                if fragment.fragmentFlow == .sandwich {
                    sandwichStart = sandwichStart ?? i
                    continue
                }

                assert(fragment.fragmentFlow == .ltr || fragment.fragmentFlow == .rtl)

                let currentDirection =
                    fragment.fragmentFlow == .ltr ? TextDirection.ltr : TextDirection.rtl

                if currentDirection == previousDirection {
                    sandwichStart = nil
                    continue
                }
            }

            // We've reached a fragment that'll flip the text direction. Let's
            // position the sequence that we've been traversing.

            if sandwichStart == nil {
                // Position fragments in range [sequenceStart:i)
                startOffset += _positionFragmentRange(
                    line: line,
                    start: sequenceStart,
                    end: i,
                    direction: previousDirection,
                    startOffset: startOffset
                )
            } else {
                // Position fragments in range [sequenceStart:sandwichStart)
                startOffset += _positionFragmentRange(
                    line: line,
                    start: sequenceStart,
                    end: sandwichStart!,
                    direction: previousDirection,
                    startOffset: startOffset
                )
                // Position fragments in range [sandwichStart:i)
                startOffset += _positionFragmentRange(
                    line: line,
                    start: sandwichStart!,
                    end: i,
                    direction: _paragraphDirection,
                    startOffset: startOffset
                )
            }

            sequenceStart = i
            sandwichStart = nil

            if i < line.fragments.count {
                previousDirection = line.fragments[i].textDirection!
            }
        }
    }

    private func _positionFragmentRange(
        line: ParagraphLine,
        start: Int,
        end: Int,
        direction: TextDirection,
        startOffset: Float
    ) -> Float {
        assert(start <= end)

        var cumulativeWidth: Float = 0.0

        // The bodies of the two for loops below must remain identical. The only
        // difference is the looping direction. One goes from start to end, while
        // the other goes from end to start.

        if direction == _paragraphDirection {
            for i in start..<end {
                cumulativeWidth += _positionOneFragment(
                    line,
                    i,
                    startOffset + cumulativeWidth,
                    direction
                )
            }
        } else {
            for i in (start..<end).reversed() {
                cumulativeWidth += _positionOneFragment(
                    line,
                    i,
                    startOffset + cumulativeWidth,
                    direction
                )
            }
        }

        return cumulativeWidth
    }

    private func _positionOneFragment(
        _ line: ParagraphLine,
        _ i: Int,
        _ startOffset: Float,
        _ direction: TextDirection
    ) -> Float {
        let fragment = line.fragments[i]
        fragment.setPosition(startOffset: startOffset, textDirection: direction)
        return fragment.widthIncludingTrailingSpaces
    }

    func getBoxesForPlaceholders() -> [TextBox] {
        var boxes: [TextBox] = []
        for line in lines {
            for fragment in line.fragments {
                if fragment.isPlaceholder {
                    boxes.append(fragment.toTextBox())
                }
            }
        }
        return boxes
    }

    func getBoxesForRange(
        _ start: TextIndex,
        _ end: TextIndex,
        _ boxHeightStyle: BoxHeightStyle,
        _ boxWidthStyle: BoxWidthStyle
    ) -> [TextBox] {
        // Zero-length ranges and invalid ranges return an empty list.
        if start >= end || start < .zero || end < .zero {
            return []
        }

        let length = TextIndex(utf16Offset: paragraph.plainText.utf16.count)
        // Ranges that are out of bounds should return an empty list.
        if start > length || end > length {
            return []
        }

        var boxes: [TextBox] = []

        for line in lines {
            if line.overlapsWith(start, end) {
                for fragment in line.fragments {
                    if !fragment.isPlaceholder && fragment.overlapsWith(start: start, end: end) {
                        boxes.append(fragment.toTextBox(start: start, end: end))
                    }
                }
            }
        }
        return boxes
    }

    func getPositionForOffset(_ offset: Offset) -> TextPosition {
        // After layout, each line has boxes that contain enough information to make
        // it possible to do hit testing. Once we find the box, we look inside that
        // box to find where exactly the `offset` is located.

        guard let line = _findLineForY(offset.dy) else {
            return TextPosition(offset: .zero)
        }
        // [offset] is to the left of the line.
        if offset.dx <= line.left {
            return TextPosition(
                offset: line.startIndex
            )
        }

        // [offset] is to the right of the line.
        if offset.dx >= line.left + line.widthWithTrailingSpaces {
            return TextPosition(
                offset: line.endIndex - line.trailingNewlines,
                affinity: TextAffinity.upstream
            )
        }

        let dx = offset.dx - line.left
        for fragment in line.fragments {
            if fragment.left <= dx && dx <= fragment.right {
                return fragment.getPositionForX(dx - fragment.left)
            }
        }
        // Is this ever reachable?
        return TextPosition(offset: line.startIndex)
    }

    func getClosestGlyphInfo(_ offset: Offset) -> GlyphInfo? {
        guard let line = _findLineForY(offset.dy) else {
            return nil
        }
        guard let fragment = line.closestFragmentAtOffset(offset.dx - line.left) else {
            return nil
        }
        let dx = offset.dx
        let closestGraphemeStartInFragment =
            !fragment.hasLeadingBrokenGrapheme
            || dx <= fragment.line.left
            || fragment.line.left + fragment.line.width <= dx
            || {
                switch fragment.textDirection! {
                // If dx is closer to the trailing edge, no need to check other fragments.
                case .ltr:
                    return dx >= line.left + (fragment.left + fragment.right) / 2
                case .rtl:
                    return dx <= line.left + (fragment.left + fragment.right) / 2
                }
            }()
        let candidate1 = fragment.getClosestCharacterBox(dx)
        if closestGraphemeStartInFragment {
            return candidate1
        }
        let searchLeft = fragment.textDirection! == .ltr
        guard
            let candidate2 = fragment.line.closestFragmentTo(fragment, searchLeft: searchLeft)?
                .getClosestCharacterBox(dx)
        else {
            return candidate1
        }

        let distance1 = min(
            abs(candidate1.graphemeClusterLayoutBounds.left - dx),
            abs(candidate1.graphemeClusterLayoutBounds.right - dx)
        )
        let distance2 = min(
            abs(candidate2.graphemeClusterLayoutBounds.left - dx),
            abs(candidate2.graphemeClusterLayoutBounds.right - dx)
        )
        return distance2 > distance1 ? candidate1 : candidate2
    }

    private func _findLineForY(_ y: Float) -> ParagraphLine? {
        if lines.isEmpty {
            return nil
        }
        // We could do a binary search here but it's not worth it because the number
        // of line is typically low, and each iteration is a cheap comparison of
        // doubles.
        var remainingY = y
        for line in lines {
            if remainingY <= line.height {
                return line
            }
            remainingY -= line.height
        }
        return lines.last
    }
}

/// Builds instances of [ParagraphLine] for the given [paragraph].
///
/// Usage of this class starts by calling [LineBuilder.first] to start building
/// the first line of the paragraph.
///
/// Then fragments can be added by calling [addFragment].
///
/// After adding a fragment, one can use [isOverflowing] to determine whether
/// the added fragment caused the line to overflow or not.
///
/// Once the line is complete, it can be built by calling [build] to generate
/// a [ParagraphLine] instance.
///
/// To start building the next line, simply call [nextLine] to get a new
/// [LineBuilder] for the next line.
class LineBuilder {
    private let paragraph: CanvasParagraph
    private let spanometer: Spanometer
    private let maxWidth: Float
    private let lineNumber: Int
    private let accumulatedHeight: Float
    private var fragments: [LayoutFragment]
    private var fragmentsForNextLine: [LayoutFragment]?

    private init(
        paragraph: CanvasParagraph,
        spanometer: Spanometer,
        maxWidth: Float,
        lineNumber: Int,
        accumulatedHeight: Float,
        fragments: [LayoutFragment]
    ) {
        self.paragraph = paragraph
        self.spanometer = spanometer
        self.maxWidth = maxWidth
        self.lineNumber = lineNumber
        self.accumulatedHeight = accumulatedHeight
        self.fragments = fragments
        recalculateMetrics()
    }

    /// Creates a [LineBuilder] for the first line in a paragraph.
    static func first(
        paragraph: CanvasParagraph,
        spanometer: Spanometer,
        maxWidth: Float
    ) -> LineBuilder {
        return LineBuilder(
            paragraph: paragraph,
            spanometer: spanometer,
            maxWidth: maxWidth,
            lineNumber: 0,
            accumulatedHeight: 0.0,
            fragments: []
        )
    }

    var startIndex: TextIndex {
        assert(!fragments.isEmpty || !fragmentsForNextLine!.isEmpty)

        return !isEmpty
            ? fragments.first!.start
            : fragmentsForNextLine!.first!.start
    }

    var endIndex: TextIndex {
        assert(!fragments.isEmpty || !fragmentsForNextLine!.isEmpty)

        return !isEmpty
            ? fragments.last!.end
            : fragmentsForNextLine!.first!.start
    }

    /// The width of the line so far, excluding trailing white space.
    private(set) var width: Float = 0.0

    /// The width of the line so far, including trailing white space.
    private(set) var widthIncludingSpace: Float = 0.0

    private var widthExcludingLastFragment: Float {
        return fragments.count > 1
            ? widthIncludingSpace - fragments.last!.widthIncludingTrailingSpaces
            : 0
    }

    /// The distance from the top of the line to the alphabetic baseline.
    private(set) var ascent: Float = 0.0

    /// The distance from the bottom of the line to the alphabetic baseline.
    private(set) var descent: Float = 0.0

    /// The height of the line so far.
    var height: Float { ascent + descent }

    private var lastBreakableFragment = -1
    private var breakCount = 0

    /// Whether this line can be legally broken into more than one line.
    var isBreakable: Bool {
        if fragments.isEmpty {
            return false
        }
        if fragments.last!.isBreak {
            // We need one more break other than the last one.
            return breakCount > 1
        }
        return breakCount > 0
    }

    /// Returns true if the line can't be legally broken any further.
    var isNotBreakable: Bool { !isBreakable }

    private var spaceCount = TextIndex.zero
    private var trailingSpaces = TextIndex.zero

    var isEmpty: Bool { fragments.isEmpty }
    var isNotEmpty: Bool { !fragments.isEmpty }

    var isHardBreak: Bool { !fragments.isEmpty && fragments.last!.isHardBreak }

    /// The horizontal offset necessary for the line to be correctly aligned.
    var alignOffset: Float {
        let emptySpace = maxWidth - width
        let textAlign = paragraph.paragraphStyle.effectiveTextAlign

        switch textAlign {
        case .center:
            return emptySpace / 2.0
        case .right:
            return emptySpace
        case .start:
            return paragraphDirection == .rtl ? emptySpace : 0.0
        case .end:
            return paragraphDirection == .rtl ? 0.0 : emptySpace
        default:
            return 0.0
        }
    }

    var isOverflowing: Bool { width > maxWidth }

    var canHaveEllipsis: Bool {
        if paragraph.paragraphStyle.ellipsis == nil {
            return false
        }

        let maxLines = paragraph.paragraphStyle.maxLines
        return maxLines == nil || maxLines == lineNumber + 1
    }

    private var canAppendEmptyFragments: Bool {
        if isHardBreak {
            // Can't append more fragments to this line if it has a hard break.
            return false
        }

        if let fragmentsForNextLine = fragmentsForNextLine, !fragmentsForNextLine.isEmpty {
            // If we already have fragments prepared for the next line, then we can't
            // append more fragments to this line.
            return false
        }

        return true
    }

    private var paragraphDirection: TextDirection {
        paragraph.paragraphStyle.effectiveTextDirection
    }

    func addFragment(_ fragment: LayoutFragment) {
        updateMetrics(fragment)

        if fragment.isBreak {
            lastBreakableFragment = fragments.count
        }

        fragments.append(fragment)
    }

    /// Updates the [LineBuilder]'s metrics to take into account the new [fragment].
    private func updateMetrics(_ fragment: LayoutFragment) {
        spaceCount = spaceCount + fragment.trailingSpaces

        if fragment.isSpaceOnly {
            trailingSpaces = trailingSpaces + fragment.trailingSpaces
        } else {
            trailingSpaces = fragment.trailingSpaces
            width = widthIncludingSpace + fragment.widthExcludingTrailingSpaces
        }
        widthIncludingSpace += fragment.widthIncludingTrailingSpaces

        if fragment.isPlaceholder {
            adjustPlaceholderAscentDescent(fragment)
        }

        if fragment.isBreak {
            breakCount += 1
        }

        ascent = max(ascent, fragment.ascent)
        descent = max(descent, fragment.descent)
    }

    private func adjustPlaceholderAscentDescent(_ fragment: LayoutFragment) {
        let placeholder = fragment.span as! PlaceholderSpan

        let (ascent, descent): (Float, Float)
        switch placeholder.placeholder.alignment {
        case .top:
            // The placeholder is aligned to the top of text, which means it has the
            // same `ascent` as the remaining text. We only need to extend the
            // `descent` enough to fit the placeholder.
            ascent = self.ascent
            descent = placeholder.placeholder.height - self.ascent

        case .bottom:
            // The opposite of `top`. The `descent` is the same, but we extend the
            // `ascent`.
            ascent = placeholder.placeholder.height - self.descent
            descent = self.descent

        case .middle:
            let textMidPoint = height / 2
            let placeholderMidPoint = placeholder.placeholder.height / 2
            let diff = placeholderMidPoint - textMidPoint
            ascent = self.ascent + diff
            descent = self.descent + diff

        case .aboveBaseline:
            ascent = placeholder.placeholder.height
            descent = 0.0

        case .belowBaseline:
            ascent = 0.0
            descent = placeholder.placeholder.height

        case .baseline:
            ascent = placeholder.placeholder.baselineOffset
            descent = placeholder.placeholder.height - ascent
        }

        // Update the metrics of the fragment to reflect the calculated ascent and
        // descent.
        fragment.setMetrics(
            spanometer,
            ascent: ascent,
            descent: descent,
            widthExcludingTrailingSpaces: fragment.widthExcludingTrailingSpaces,
            widthIncludingTrailingSpaces: fragment.widthIncludingTrailingSpaces
        )
    }

    private func recalculateMetrics() {
        width = 0
        widthIncludingSpace = 0
        ascent = 0
        descent = 0
        spaceCount = TextIndex.zero
        trailingSpaces = TextIndex.zero
        breakCount = 0
        lastBreakableFragment = -1

        for (i, fragment) in fragments.enumerated() {
            updateMetrics(fragment)
            if fragment.isBreak {
                lastBreakableFragment = i
            }
        }
    }

    func forceBreakLastFragment(availableWidth: Float? = nil, allowEmptyLine: Bool = false) {
        assert(isNotEmpty)

        let availableWidth = availableWidth ?? maxWidth
        assert(widthIncludingSpace > availableWidth)

        fragmentsForNextLine = fragmentsForNextLine ?? []

        // When the line has fragments other than the last one, we can always allow
        // the last fragment to be empty (i.e. completely removed from the line).
        let hasOtherFragments = fragments.count > 1
        let allowLastFragmentToBeEmpty = hasOtherFragments || allowEmptyLine

        let lastFragment = fragments.last!

        if lastFragment.isPlaceholder {
            // Placeholder can't be force-broken. Either keep all of it in the line or
            // move it to the next line.
            if allowLastFragmentToBeEmpty {
                fragmentsForNextLine!.insert(fragments.removeLast(), at: 0)
                recalculateMetrics()
            }
            return
        }

        spanometer.currentSpan = lastFragment.span
        let lineWidthWithoutLastFragment =
            widthIncludingSpace - lastFragment.widthIncludingTrailingSpaces
        let availableWidthForFragment = availableWidth - lineWidthWithoutLastFragment
        let forceBreakEnd = lastFragment.end - lastFragment.trailingNewlines

        let breakingPoint = spanometer.forceBreak(
            start: lastFragment.start,
            end: forceBreakEnd,
            availableWidth: availableWidthForFragment,
            allowEmpty: allowLastFragmentToBeEmpty
        )

        if breakingPoint == forceBreakEnd {
            // The entire fragment remained intact. Let's keep everything as is.
            return
        }

        fragments.removeLast()
        recalculateMetrics()

        let split = lastFragment.split(breakingPoint)

        if let first = split.first ?? nil {
            spanometer.measureFragment(first)
            addFragment(first)
        }

        if let second = split.last ?? nil {
            spanometer.measureFragment(second)
            fragmentsForNextLine!.insert(second, at: 0)
        }
    }

    func insertEllipsis() {
        assert(canHaveEllipsis)
        assert(isOverflowing)

        let ellipsisText = paragraph.paragraphStyle.ellipsis!

        fragmentsForNextLine = []

        spanometer.currentSpan = fragments.last!.span
        var ellipsisWidth = spanometer.measureText(ellipsisText)
        var availableWidth = max(0, maxWidth - ellipsisWidth)

        while widthExcludingLastFragment > availableWidth {
            fragmentsForNextLine!.insert(fragments.removeLast(), at: 0)
            recalculateMetrics()

            spanometer.currentSpan = fragments.last!.span
            ellipsisWidth = spanometer.measureText(ellipsisText)
            availableWidth = maxWidth - ellipsisWidth
        }

        let lastFragment = fragments.last!
        forceBreakLastFragment(availableWidth: availableWidth, allowEmptyLine: true)

        let ellipsisFragment = EllipsisFragment(
            index: endIndex,
            span: lastFragment.span
        )
        ellipsisFragment.setMetrics(
            spanometer,
            ascent: lastFragment.ascent,
            descent: lastFragment.descent,
            widthExcludingTrailingSpaces: ellipsisWidth,
            widthIncludingTrailingSpaces: ellipsisWidth
        )
        addFragment(ellipsisFragment)
    }

    func revertToLastBreakOpportunity() {
        assert(isBreakable)

        // The last fragment in the line may or may not be breakable. Regardless,
        // it needs to be removed.
        //
        // We need to find the latest breakable fragment in the line (other than the
        // last fragment). Such breakable fragment is guaranteed to be found because
        // the line `isBreakable`.

        // Start from the end and skip the last fragment.
        var i = fragments.count - 2
        while !fragments[i].isBreak {
            i -= 1
        }

        fragmentsForNextLine = Array(fragments[(i + 1)...])
        fragments.removeSubrange((i + 1)...)
        recalculateMetrics()
    }

    /// Appends as many zero-width fragments as this line allows.
    ///
    /// Returns the number of fragments that were appended.
    func appendZeroWidthFragments(_ fragments: [LayoutFragment], startFrom: Int) -> Int {
        var i = startFrom
        while canAppendEmptyFragments && i < fragments.count
            && fragments[i].widthExcludingTrailingSpaces == 0
        {
            addFragment(fragments[i])
            i += 1
        }
        return i - startFrom
    }

    /// Builds the [ParagraphLine] instance that represents this line.
    func build() -> ParagraphLine {
        if fragmentsForNextLine == nil {
            fragmentsForNextLine = Array(fragments[(lastBreakableFragment + 1)...])
            fragments.removeSubrange((lastBreakableFragment + 1)...)
        }
        let trailingNewlines = isEmpty ? .zero : fragments.last!.trailingNewlines
        let line = ParagraphLine(
            hardBreak: isHardBreak,
            ascent: ascent,
            descent: descent,
            height: height,
            width: width,
            left: alignOffset,
            baseline: accumulatedHeight + ascent,
            lineNumber: lineNumber,
            startIndex: startIndex,
            endIndex: endIndex,
            trailingNewlines: trailingNewlines,
            trailingSpaces: trailingSpaces,
            spaceCount: spaceCount,
            widthWithTrailingSpaces: widthIncludingSpace,
            fragments: fragments,
            textDirection: paragraphDirection,
            paragraph: paragraph
        )

        for fragment in fragments {
            fragment.line = line
        }

        return line
    }

    /// Creates a new [LineBuilder] to build the next line in the paragraph.
    func nextLine() -> LineBuilder {
        return LineBuilder(
            paragraph: paragraph,
            spanometer: spanometer,
            maxWidth: maxWidth,
            lineNumber: lineNumber + 1,
            accumulatedHeight: accumulatedHeight + height,
            fragments: fragmentsForNextLine ?? []
        )
    }
}

/// Responsible for taking measurements within spans of a paragraph.
///
/// Can't perform measurements across spans. To measure across spans, multiple
/// measurements have to be taken.
///
/// Before performing any measurement, the [currentSpan] has to be set. Once
/// it's set, the [Spanometer] updates the underlying [context] so that
/// subsequent measurements use the correct styles.
class Spanometer {
    init(paragraph: CanvasParagraph) {
        self.paragraph = paragraph
    }

    let paragraph: CanvasParagraph

    private static let _rulerHost = RulerHost()

    private static var _rulers: [TextHeightStyle: TextHeightRuler] = [:]

    static var rulers: [TextHeightStyle: TextHeightRuler] { _rulers }

    /// Clears the cache of rulers that are used for measuring text height and
    /// baseline metrics.
    static func clearRulersCache() {
        for (_, ruler) in _rulers {
            ruler.dispose()
        }
        _rulers.removeAll()
    }

    var letterSpacing: Float? {
        currentSpan!.style.letterSpacing
    }

    private var _currentRuler: TextHeightRuler?
    var currentSpan: ParagraphSpanProtocol? {
        didSet {
            // Update the font string if it's different from the last applied font
            // string.
            //
            // Also, we need to update the font string even if the span isn't changing.
            // That's because `textContext` is shared across all spanometers.
            if let span = currentSpan {
                let newCssFontString = span.style.cssFontString
                if _lastContextFont != newCssFontString {
                    _lastContextFont = newCssFontString
                    textContext.font = .string(newCssFontString)
                }

                // Update the height ruler.
                // If the ruler doesn't exist in the cache, create a new one and cache it.
                let heightStyle = span.style.heightStyle
                var ruler = Self._rulers[heightStyle]
                if ruler == nil {
                    ruler = TextHeightRuler(heightStyle, Self._rulerHost)
                    Self._rulers[heightStyle] = ruler
                }
                _currentRuler = ruler
            } else {
                _currentRuler = nil
            }
        }
    }

    /// Whether the spanometer is ready to take measurements.
    var isReady: Bool { currentSpan != nil }

    /// The distance from the top of the current span to the alphabetic baseline.
    var ascent: Float { _currentRuler!.alphabeticBaseline }

    /// The distance from the bottom of the current span to the alphabetic baseline.
    var descent: Float { height - ascent }

    /// The line height of the current span.
    var height: Float { _currentRuler!.height }

    func measureText(_ text: String) -> Float {
        return measureSubstring(
            textContext,
            text,
            TextIndex(utf16Offset: 0),
            TextIndex(utf16Offset: text.utf16.count)
        )
    }

    func measureRange(start: TextIndex, end: TextIndex) -> Float {
        assert(currentSpan != nil)

        // Make sure the range is within the current span.
        assert(start >= currentSpan!.start && start <= currentSpan!.end)
        assert(end >= currentSpan!.start && end <= currentSpan!.end)

        return _measure(start: start, end: end)
    }

    func measureFragment(_ fragment: LayoutFragment) {
        if fragment.isPlaceholder {
            let placeholder = fragment.span as! PlaceholderSpan
            // The ascent/descent values of the placeholder fragment will be finalized
            // later when the line is built.
            fragment.setMetrics(
                self,
                ascent: placeholder.placeholder.height,
                descent: 0,
                widthExcludingTrailingSpaces: placeholder.placeholder.width,
                widthIncludingTrailingSpaces: placeholder.placeholder.width
            )
        } else {
            currentSpan = fragment.span
            let widthExcludingTrailingSpaces = _measure(
                start: fragment.start,
                end: fragment.end - fragment.trailingSpaces
            )
            let widthIncludingTrailingSpaces = _measure(
                start: fragment.start,
                end: fragment.end - fragment.trailingNewlines
            )
            fragment.setMetrics(
                self,
                ascent: ascent,
                descent: descent,
                widthExcludingTrailingSpaces: widthExcludingTrailingSpaces,
                widthIncludingTrailingSpaces: widthIncludingTrailingSpaces
            )
        }
    }

    /// In a continuous, unbreakable block of text from [start] to [end], finds
    /// the point where text should be broken to fit in the given [availableWidth].
    ///
    /// The [start] and [end] indices have to be within the same text span.
    ///
    /// When [allowEmpty] is true, the result is guaranteed to be at least one
    /// character after [start]. But if [allowEmpty] is false and there isn't
    /// enough [availableWidth] to fit the first character, then [start] is
    /// returned.
    ///
    /// See also:
    /// - [LineBuilder.forceBreak].
    func forceBreak(
        start: TextIndex,
        end: TextIndex,
        availableWidth: Float,
        allowEmpty: Bool
    ) -> TextIndex {
        assert(currentSpan != nil)

        // Make sure the range is within the current span.
        assert(start >= currentSpan!.start && start <= currentSpan!.end)
        assert(end >= currentSpan!.start && end <= currentSpan!.end)

        if availableWidth <= 0.0 {
            return allowEmpty ? start : start + .one
        }

        var low = start
        var high = end
        while high.utf16Offset - low.utf16Offset > 1 {
            let mid = TextIndex(utf16Offset: (low.utf16Offset + high.utf16Offset) / 2)
            let width = _measure(start: start, end: mid)
            if width < availableWidth {
                low = mid
            } else if width > availableWidth {
                high = mid
            } else {
                low = mid
                high = mid
            }
        }

        if low == start && !allowEmpty {
            low = low + .one
        }
        return low
    }

    private func _measure(start: TextIndex, end: TextIndex) -> Float {
        assert(currentSpan != nil)
        // Make sure the range is within the current span.
        assert(start >= currentSpan!.start && start <= currentSpan!.end)
        assert(end >= currentSpan!.start && end <= currentSpan!.end)

        return measureSubstring(
            textContext,
            paragraph.plainText,
            start,
            end,
            letterSpacing: letterSpacing
        )
    }
}
