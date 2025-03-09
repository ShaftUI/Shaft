// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CSkia
import Shaft

public class SkiaParagraphBuilder: ParagraphBuilder {
    public init(_ style: ParagraphStyle, fontCollection: SkiaFontCollection) {
        var skiaStyle = skia.textlayout.ParagraphStyle()
        style.copyToSkia(&skiaStyle)
        builder = paragraph_builder_new(&skiaStyle, fontCollection.collection)
    }

    deinit {
        paragraph_builder_unref(builder)
    }

    public let builder: UnsafeMutablePointer<skia.textlayout.ParagraphBuilder>

    public func pushStyle(_ style: SpanStyle) {
        var skiaStyle = skia.textlayout.TextStyle()
        style.copyToSkia(&skiaStyle)
        paragraph_builder_push_style(builder, &skiaStyle)
    }

    public func pop() {
        paragraph_builder_pop(builder)
    }

    public func addText(_ text: String) {
        paragraph_builder_add_text(builder, text)
    }

    public func build() -> Paragraph {
        let paragraph = paragraph_builder_build(builder)!
        return SkiaParagraph(paragraph)
    }

}

public class SkiaParagraph: Paragraph {
    fileprivate init(_ paragraph: UnsafeMutablePointer<skia.textlayout.Paragraph>) {
        self.paragraph = paragraph
    }

    deinit {
        paragraph_unref(paragraph)
    }

    private var paragraph: UnsafeMutablePointer<skia.textlayout.Paragraph>

    public var width: Float { paragraph.pointee.getMaxWidth() }

    public var height: Float { paragraph.pointee.getHeight() }

    public var longestLine: Float { paragraph.pointee.getLongestLine() }

    public var minIntrinsicWidth: Float { paragraph.pointee.getMinIntrinsicWidth() }

    public var maxIntrinsicWidth: Float { paragraph.pointee.getMaxIntrinsicWidth() }

    public var alphabeticBaseline: Float { paragraph.pointee.getAlphabeticBaseline() }

    public var ideographicBaseline: Float { paragraph.pointee.getIdeographicBaseline() }

    public var didExceedMaxLines: Bool { paragraph.pointee.didExceedMaxLines() }

    public func layout(_ constraints: ParagraphConstraints) {
        switch constraints {
        case .width(let width):
            paragraph_layout(paragraph, width)
        }
    }

    public func paint(_ canvas: SkiaCanvas, _ offset: Offset) {
        let canvas = canvas
        paragraph_paint(paragraph, canvas.skCanvas, offset.dx, offset.dy)
    }

    public func getPositionForOffset(_ offset: Offset) -> TextPosition {
        let position = paragraph_get_glyph_position_at_coordinate(paragraph, offset.dx, offset.dy)
        return TextPosition(
            offset: .init(utf16Offset: Int(position.position)),
            // enum Affinity { kUpstream, kDownstream };
            affinity: position.affinity.rawValue == 0 ? .upstream : .downstream
        )
    }

    public func getWordBoundary(_ position: TextPosition) -> Shaft.TextRange {
        let range = paragraph_get_word_boundary(paragraph, UInt32(position.offset.utf16Offset))
        return TextRange(
            start: .init(utf16Offset: Int(range.start)),
            end: .init(utf16Offset: Int(range.end))
        )
    }

    public func computeLineMetrics() -> [LineMetrics] {
        let metrics = paragraph_get_line_metrics(paragraph)
        return metrics.map(toLineMetrics)
    }

    public func getLineMetricsAt(line: Int) -> LineMetrics? {
        let metrics = paragraph_get_line_metrics_at(paragraph, UInt32(line))
        return toLineMetrics(metrics)
    }

    public func getBoxesForRange(
        _ start: TextIndex,
        _ end: TextIndex,
        boxHeightStyle: BoxHeightStyle,
        boxWidthStyle: BoxWidthStyle
    ) -> [TextBox] {
        let boxes = paragraph_get_rects_for_range(
            paragraph,
            start.utf16Offset,
            end.utf16Offset,
            boxHeightStyle.toSkia(),
            boxWidthStyle.toSkia()
        )
        return boxes.map(toTextBox)
    }

    public func getBoxesForPlaceholders() -> [TextBox] {
        let boxes = paragraph_get_rects_for_placeholders(paragraph)
        return boxes.map(toTextBox)
    }

    public var numberOfLines: Int {
        return paragraph_get_line_count(paragraph)
    }

    public func getLineNumberAt(_ offset: TextIndex) -> Int? {
        let result = paragraph_get_line_number_at(paragraph, offset.utf16Offset)
        if result < 0 {
            return nil
        }
        return Int(result)
    }

    public func getClosestGlyphInfoForOffset(_ offset: Offset) -> GlyphInfo? {
        let glyphInfo = paragraph_get_closest_glyph_info_at(paragraph, offset.dx, offset.dy)
        return toGlyphInfo(glyphInfo)
    }

    public func getGlyphInfoAt(_ offset: TextIndex) -> GlyphInfo? {
        var glyphInfo: skia.textlayout.Paragraph.GlyphInfo = .init()
        let valid = paragraph_get_glyph_info_at(paragraph, offset.utf16Offset, &glyphInfo)
        return valid ? toGlyphInfo(glyphInfo) : nil
    }
}

private func toLineMetrics(_ m: skia.textlayout.LineMetrics) -> LineMetrics {
    LineMetrics(
        startIndex: .init(utf16Offset: m.fStartIndex),
        endIndex: .init(utf16Offset: m.fEndIndex),
        endIncludingNewline: .init(utf16Offset: m.fEndIncludingNewline),
        endExcludingWhitespace: .init(utf16Offset: m.fEndExcludingWhitespaces),
        hardBreak: m.fHardBreak,
        ascent: Float(m.fAscent),
        descent: Float(m.fDescent),
        unscaledAscent: Float(m.fUnscaledAscent),
        height: Float(m.fHeight),
        width: Float(m.fWidth),
        left: Float(m.fLeft),
        baseline: Float(m.fBaseline),
        lineNumber: Int(m.fLineNumber)
    )
}

private func toTextBox(_ t: skia.textlayout.TextBox) -> TextBox {
    TextBox(
        left: t.rect.left(),
        top: t.rect.top(),
        right: t.rect.right(),
        bottom: t.rect.bottom(),
        direction: t.direction == .ltr ? .ltr : .rtl
    )
}

private func toGlyphInfo(_ g: skia.textlayout.Paragraph.GlyphInfo) -> GlyphInfo {
    GlyphInfo(
        graphemeClusterLayoutBounds: toRect(g.fGraphemeLayoutBounds),
        graphemeClusterCodeUnitRange: toTextRange(g.fGraphemeClusterTextRange),
        writingDirection: toTextDirection(g.fDirection)
    )
}

private func toRect(_ r: SkRect) -> Rect {
    Rect(
        left: r.left(),
        top: r.top(),
        right: r.right(),
        bottom: r.bottom()
    )
}

private func toTextRange(_ r: skia.textlayout.TextRange) -> Shaft.TextRange {
    Shaft.TextRange(
        start: .init(utf16Offset: Int(r.start)),
        end: .init(utf16Offset: Int(r.end))
    )
}

private func toTextDirection(_ d: skia.textlayout.TextDirection) -> TextDirection {
    switch d {
    case .ltr:
        return .ltr
    case .rtl:
        return .rtl
    default:
        fatalError()
    }
}
