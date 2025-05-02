import Foundation
import Shaft
import XCTest

/// Check the caret offsets are accurate for the given single line of LTR text.
///
/// This lays out the given text as a single line with ``TextDirection.ltr``
/// and checks the following invariants, which should always hold if the text
/// is made up of LTR characters:
///  * The caret offsets go monotonically from 0.0 to the width of the text.
///  * At each character (that is, grapheme cluster) boundary, the caret
///    offset equals the width that the text up to that point would have
///    if laid out on its own.
///
/// If you have a ``TextSpan`` instead of a plain ``String``,
/// see ``caretOffsetsForTextSpan``.
func checkCaretOffsetsLtr(_ text: String) {
    let boundaries: [String.Index] = Array(text.indices)

    let painter = TextPainter()
    painter.textDirection = .ltr

    // Lay out the string up to each boundary, and record the width.
    var prefixWidths: [Float] = []
    for boundary in boundaries {
        painter.text = TextSpan(text: String(text[..<boundary]))
        painter.layout()
        prefixWidths.append(painter.width)
    }

    // The painter has the full text laid out. Check the caret offsets.
    func caretOffset(_ offset: TextIndex) -> Float {
        let position = TextPosition(offset: offset)
        return painter.getOffsetForCaret(position, .zero).dx
    }

    XCTAssertEqual(boundaries.map { caretOffset(.init(from: $0, in: text)) }, prefixWidths)
    var lastOffset = caretOffset(.zero)
    for i in 1...text.utf16.count {
        let offset = caretOffset(.init(utf16Offset: i))
        XCTAssertGreaterThanOrEqual(offset, lastOffset)
        lastOffset = offset
    }
}

class TextPainterTest: XCTestCase {
    func testGetPositionForOffset() {
        let painter = TextPainter(
            text: TextSpan(
                text: "Hello, World!",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                    wordSpacing: 1,
                    height: 1.5
                )
            )
        )

        painter.layout(minWidth: 10, maxWidth: 30)

        // for x in 0...Int(painter.width) {
        //     for y in 0...Int(painter.height) {
        //         let position = painter.getPositionForOffset(.init(Float(x), Float(y)))
        //         print("x: \(x), y: \(y), position: \(position)")
        //     }
        // }

        XCTAssertEqual(
            painter.getPositionForOffset(.init(10, 20)),
            .init(offset: .init(utf16Offset: 6), affinity: .upstream)
        )
        XCTAssertEqual(
            painter.getPositionForOffset(.init(10, 25)),
            .init(offset: .init(utf16Offset: 6), affinity: .upstream)
        )
    }

    func testTextPainterCaret() {
        let painter = TextPainter()
        painter.textDirection = .ltr

        var text = "A"
        checkCaretOffsetsLtr(text)

        painter.text = TextSpan(text: text)
        painter.layout()

        var caretOffset = painter.getOffsetForCaret(
            TextPosition(offset: .zero),
            .zero
        )
        XCTAssertEqual(caretOffset.dx, 0)
        caretOffset = painter.getOffsetForCaret(
            .init(offset: .init(utf16Offset: text.utf16.count)),
            .zero
        )
        XCTAssertEqual(caretOffset.dx, painter.width)

        // Check that getOffsetForCaret handles a character that is encoded as a
        // surrogate pair.
        text = "A\u{1F600}"
        checkCaretOffsetsLtr(text)
        painter.text = TextSpan(text: text)
        painter.layout()
        caretOffset = painter.getOffsetForCaret(
            .init(offset: .init(utf16Offset: text.utf16.count)),
            .zero
        )
        XCTAssertEqual(caretOffset.dx, painter.width)

        // Test with trailing full-width space
        let textWithFullWidthSpace = "A\u{3000}"
        checkCaretOffsetsLtr(textWithFullWidthSpace)
        painter.text = TextSpan(text: textWithFullWidthSpace)
        painter.layout()
        caretOffset = painter.getOffsetForCaret(.init(offset: .zero), .zero)
        XCTAssertEqual(caretOffset.dx, 0)
        caretOffset = painter.getOffsetForCaret(.init(offset: .init(utf16Offset: 1)), .zero)
        XCTAssertGreaterThan(caretOffset.dx, 0)
        XCTAssertLessThan(caretOffset.dx, painter.width)
        caretOffset = painter.getOffsetForCaret(
            .init(offset: .init(utf16Offset: textWithFullWidthSpace.utf16.count)),
            .zero
        )
        XCTAssertEqual(caretOffset.dx, painter.width)
    }

    func testTextPainterNullText() {
        let painter = TextPainter()
        painter.textDirection = .ltr

        var children = [TextSpan(text: "B"), TextSpan(text: "C")]
        painter.text = TextSpan(children: children)
        painter.layout()

        var caretOffset = painter.getOffsetForCaret(.init(offset: .init(utf16Offset: 0)), .zero)
        XCTAssertEqual(caretOffset.dx, 0)
        caretOffset = painter.getOffsetForCaret(.init(offset: .init(utf16Offset: 1)), .zero)
        XCTAssertGreaterThan(caretOffset.dx, 0)
        XCTAssertLessThan(caretOffset.dx, painter.width)
        caretOffset = painter.getOffsetForCaret(.init(offset: .init(utf16Offset: 2)), .zero)
        XCTAssertEqual(caretOffset.dx, painter.width)

        children = []
        painter.text = TextSpan(children: children)
        painter.layout()

        caretOffset = painter.getOffsetForCaret(.init(offset: .init(utf16Offset: 0)), .zero)
        XCTAssertEqual(caretOffset.dx, 0)
        caretOffset = painter.getOffsetForCaret(.init(offset: .init(utf16Offset: 1)), .zero)
        XCTAssertEqual(caretOffset.dx, 0)
    }

    func testTextPainterSize() {
        let painter = TextPainter(
            text: TextSpan(
                text: "X",
                style: TextStyle(fontSize: 123.0, height: 1.0)
            )
        )
        painter.textDirection = .ltr
        painter.layout()
        XCTAssertGreaterThan(painter.size.width, 0.0)
        XCTAssertEqual(painter.size.height, 123.0)
    }

    func testTextPainterTextScaler() {
        let painter = TextPainter(
            text: TextSpan(
                text: "X",
                style: TextStyle(fontSize: 10.0, height: 1.0)
            )
        )
        painter.textDirection = .ltr
        painter.textScaler = .linear(2.0)
        painter.layout()
        XCTAssertGreaterThan(painter.size.width, 0.0)
        XCTAssertEqual(painter.size.height, 20.0)
    }

    func testTextPainterTextScalerNullStyle() {
        let painter = TextPainter(
            text: TextSpan(
                text: "X"
            )
        )
        painter.textDirection = .ltr
        painter.textScaler = .linear(2.0)
        painter.layout()
        XCTAssertEqual(painter.size.height, 33.0)
    }

    func testTextPainterDefaultTextHeight() {
        let painter = TextPainter(
            text: TextSpan(text: "x")
        )
        painter.textDirection = .ltr
        painter.layout()
        XCTAssertEqual(painter.preferredLineHeight, 16.0)
        XCTAssertEqual(painter.size.height, 16)
    }

    func testTextPainterLineMetrics() {
        let painter = TextPainter()
        painter.textDirection = .ltr

        let text = "test1\nhello line two really long for soft break\nfinal line 4"
        painter.text = TextSpan(
            text: text
        )

        painter.layout(maxWidth: 200)

        XCTAssertEqual(painter.preferredLineHeight, 16)

        let lines = painter.computeLineMetrics()

        XCTAssertEqual(lines.count, 4)

        XCTAssertTrue(lines[0].hardBreak)
        XCTAssertFalse(lines[1].hardBreak)
        XCTAssertTrue(lines[2].hardBreak)
        XCTAssertTrue(lines[3].hardBreak)

        // XCTAssertEqual(lines[0].ascent, 10.5)
        // XCTAssertEqual(lines[1].ascent, 10.5)
        // XCTAssertEqual(lines[2].ascent, 10.5)
        // XCTAssertEqual(lines[3].ascent, 10.5)

        // XCTAssertEqual(lines[0].descent, 3.5)
        // XCTAssertEqual(lines[1].descent, 3.5)
        // XCTAssertEqual(lines[2].descent, 3.5)
        // XCTAssertEqual(lines[3].descent, 3.5)

        // XCTAssertEqual(lines[0].unscaledAscent, 10.5)
        // XCTAssertEqual(lines[1].unscaledAscent, 10.5)
        // XCTAssertEqual(lines[2].unscaledAscent, 10.5)
        // XCTAssertEqual(lines[3].unscaledAscent, 10.5)

        // XCTAssertEqual(lines[0].baseline, 10.5)
        // XCTAssertEqual(lines[1].baseline, 24.5)
        // XCTAssertEqual(lines[2].baseline, 38.5)
        // XCTAssertEqual(lines[3].baseline, 52.5)

        XCTAssertEqual(lines[0].height, 16)
        XCTAssertEqual(lines[1].height, 16)
        XCTAssertEqual(lines[2].height, 16)
        XCTAssertEqual(lines[3].height, 16)

        // XCTAssertEqual(lines[0].width, 70)
        // XCTAssertEqual(lines[1].width, 294)
        // XCTAssertEqual(lines[2].width, 266)
        // XCTAssertEqual(lines[3].width, 168)

        XCTAssertEqual(lines[0].left, 0)
        XCTAssertEqual(lines[1].left, 0)
        XCTAssertEqual(lines[2].left, 0)
        XCTAssertEqual(lines[3].left, 0)

        XCTAssertEqual(lines[0].lineNumber, 0)
        XCTAssertEqual(lines[1].lineNumber, 1)
        XCTAssertEqual(lines[2].lineNumber, 2)
        XCTAssertEqual(lines[3].lineNumber, 3)
    }

    func testTextPainterGetWordBoundaryWorks() {
        let testCluster = "👨‍👩‍👦👨‍👩‍👦👨‍👩‍👦"  // 8 * 3
        let textPainter = TextPainter(
            text: TextSpan(text: testCluster)
        )
        textPainter.textDirection = .ltr

        textPainter.layout()
        XCTAssertEqual(
            textPainter.getWordBoundary(TextPosition(offset: .init(utf16Offset: 8))),
            TextRange(start: .init(utf16Offset: 8), end: .init(utf16Offset: 16))
        )
    }

    // func testTextHeightBehaviorWithStrutOnEmptyParagraph() {
    //     let style = TextStyle(fontSize: 7, height: 11)
    //     let simple = TextSpan(text: "x", style: style)
    //     let emptyString = TextSpan(text: "", style: style)
    //     let emptyParagraph = TextSpan(style: style)

    //     let painter = TextPainter(
    //         textDirection: .ltr,
    //         strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
    //         textHeightBehavior: TextHeightBehavior(
    //             applyHeightToFirstAscent: false,
    //             applyHeightToLastDescent: false
    //         )
    //     )

    //     painter.text = simple
    //     painter.layout()
    //     let height = painter.height
    //     for span in [simple, emptyString, emptyParagraph] {
    //         painter.text = span
    //         painter.layout()
    //         XCTAssertEqual(
    //             painter.height,
    //             height,
    //             "\(span) is expected to have a height of \(height)"
    //         )
    //         XCTAssertEqual(
    //             painter.preferredLineHeight,
    //             height,
    //             "\(span) is expected to have a height of \(height)"
    //         )
    //     }
    // }
}
