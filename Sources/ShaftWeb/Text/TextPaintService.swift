// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Shaft

/// Responsible for painting a [CanvasParagraph] on a [BitmapCanvas].
class TextPaintService {
    init(_ paragraph: CanvasParagraph) {
        self.paragraph = paragraph
    }

    unowned let paragraph: CanvasParagraph

    func paint(canvas: Canvas2DCanvas, offset: Offset) {
        // Loop through all the lines, for each line, loop through all fragments and
        // paint them. The fragment objects have enough information to be painted
        // individually.
        let lines = paragraph.lines

        for line in lines {
            for fragment in line.fragments {
                _paintBackground(canvas: canvas, offset: offset, fragment: fragment)
                _paintText(canvas: canvas, offset: offset, line: line, fragment: fragment)
            }
        }
    }

    func _paintBackground(
        canvas: Canvas2DCanvas,
        offset: Offset,
        fragment: LayoutFragment
    ) {
        if fragment.isPlaceholder {
            return
        }

        // Paint the background of the box, if the span has a background.
        if let background = fragment.style.background {
            let rect = fragment.toPaintingTextBox().toRect()
            if !rect.isEmpty {
                canvas.drawRect(rect.shift(offset), background)
            }
        }
    }

    func _paintText(
        canvas: Canvas2DCanvas,
        offset: Offset,
        line: ParagraphLine,
        fragment: LayoutFragment
    ) {
        // There's no text to paint in placeholder spans.
        if fragment.isPlaceholder {
            return
        }

        // Don't paint the text for space-only boxes. This is just an
        // optimization, it doesn't have any effect on the output.
        if fragment.isSpaceOnly {
            return
        }

        _prepareCanvasForFragment(canvas: canvas, fragment: fragment)
        let fragmentX =
            fragment.textDirection == .ltr
            ? fragment.left
            : fragment.right

        let x = offset.dx + line.left + fragmentX
        let y = offset.dy + line.baseline

        let style = fragment.style

        let text = fragment.getText(paragraph)
        canvas.drawText(text, x, y, style: style.foreground?.style, shadows: style.shadows)
    }

    func _prepareCanvasForFragment(canvas: Canvas2DCanvas, fragment: LayoutFragment) {
        let style = fragment.style

        var paint: Paint
        if let foreground = style.foreground {
            paint = foreground
        } else {
            paint = Paint()
            if let color = style.color {
                paint.color = color
            }
        }

        canvas.setCssFont(style.cssFontString, textDirection: fragment.textDirection!)
        canvas.applyPaint(paint)
    }
}
