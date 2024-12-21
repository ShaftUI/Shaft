// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import SwiftMath

internal enum DisplayListOp {
    case drawRect(rect: Rect, paint: Paint)
    case drawLine(p0: Offset, p1: Offset, paint: Paint)
    case drawDisplayList(displayList: DisplayList)
    case drawParagraph(paragraph: Paragraph, offset: Offset)
    case drawTextBlob(textBlob: TextBlob, offset: Offset, paint: Paint)
    case drawRRect(rrect: RRect, paint: Paint)
    case drawDRRect(outer: RRect, inner: RRect, paint: Paint)
    case drawCircle(center: Offset, radius: Float, paint: Paint)
    case drawPath(path: Path, paint: Paint)
    case drawImage(image: NativeImage, offset: Offset, paint: Paint)
    case drawImageRect(image: NativeImage, src: Rect, dst: Rect, paint: Paint)
    case drawImageNine(image: NativeImage, center: Rect, dst: Rect, paint: Paint)
    case transform(transform: Matrix4x4f)
    case translate(dx: Float, dy: Float)
    case scale(sx: Float, sy: Float)
    case clipRect(rect: Rect, clipOp: ClipOp, doAntiAlias: Bool)
    case save
    case saveLayer(bounds: Rect, paint: Paint?)
    case restore
    case clear(color: Color)
}

public class DisplayListBuilder: DlOpReceiver {
    /// Creates an empty display list ready to receive drawing operations.
    public init() {}

    /// Recorded drawing operations in drawing order.
    private var buffer = [DisplayListOp]()

    /// Builds the display list. After this method is called, the builder is
    /// still usable and can be used to add more operations on top of the
    /// existing display list.
    public func build() -> DisplayList {
        DisplayList(buffer: buffer)
    }

    public func drawLine(_ p0: Offset, _ p1: Offset, _ paint: Paint) {
        push(.drawLine(p0: p0, p1: p1, paint: paint))
    }

    public func drawRect(_ rect: Rect, _ paint: Paint) {
        push(.drawRect(rect: rect, paint: paint))
    }

    public func drawDisplayList(_ displayList: DisplayList) {
        push(.drawDisplayList(displayList: displayList))
    }

    public func drawParagraph(_ paragraph: Paragraph, _ offset: Offset) {
        push(.drawParagraph(paragraph: paragraph, offset: offset))
    }

    public func drawTextBlob(_ textBlob: TextBlob, _ offset: Offset, _ paint: Paint) {
        push(.drawTextBlob(textBlob: textBlob, offset: offset, paint: paint))
    }

    public func drawRRect(_ rrect: RRect, _ paint: Paint) {
        push(.drawRRect(rrect: rrect, paint: paint))
    }

    public func drawDRRect(_ outer: RRect, _ inner: RRect, _ paint: Paint) {
        push(.drawDRRect(outer: outer, inner: inner, paint: paint))
    }

    public func drawCircle(_ center: Offset, _ radius: Float, _ paint: Paint) {
        push(.drawCircle(center: center, radius: radius, paint: paint))
    }

    public func drawPath(_ path: Path, _ paint: Paint) {
        push(.drawPath(path: path, paint: paint))
    }

    public func drawImage(_ image: NativeImage, _ offset: Offset, _ paint: Paint) {
        push(.drawImage(image: image, offset: offset, paint: paint))
    }

    public func drawImageRect(_ image: NativeImage, _ src: Rect, _ dst: Rect, _ paint: Paint) {
        push(.drawImageRect(image: image, src: src, dst: dst, paint: paint))
    }

    public func drawImageNine(_ image: NativeImage, _ center: Rect, _ dst: Rect, _ paint: Paint) {
        push(.drawImageNine(image: image, center: center, dst: dst, paint: paint))
    }

    public func transform(_ transform: Matrix4x4f) {
        push(.transform(transform: transform))
    }

    public func translate(_ dx: Float, _ dy: Float) {
        push(.translate(dx: dx, dy: dy))
    }

    public func scale(_ sx: Float, _ sy: Float) {
        push(.scale(sx: sx, sy: sy))
    }

    public func clipRect(_ rect: Rect, _ clipOp: ClipOp, _ doAntiAlias: Bool) {
        push(.clipRect(rect: rect, clipOp: clipOp, doAntiAlias: doAntiAlias))
    }

    public func save() {
        push(.save)
    }

    public func saveLayer(_ bounds: Rect, paint: Paint?) {
        push(.saveLayer(bounds: bounds, paint: paint))
    }

    public func restore() {
        push(.restore)
    }

    public func clear(color: Color) {
        push(.clear(color: color))
    }

    private func push(_ value: DisplayListOp) {
        buffer.append(value)
    }
}
