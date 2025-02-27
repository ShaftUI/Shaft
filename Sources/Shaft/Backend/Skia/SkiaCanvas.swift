// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CSkia
import SwiftMath

/// A canvas implemention that uses Skia as the backend.
public class SkiaCanvas: DirectCanvas {
    /// Creates a new canvas that draws to the given Skia canvas. It's the
    /// caller's responsibility to ensure that the canvas is valid during the
    /// lifetime of this object.
    init(_ skSurface: SkSurface_sp, _ grDirectContext: GrDirectContext_sp, _ size: ISize) {
        self.skSurface = skSurface
        self.skCanvas = sk_surface_get_canvas(skSurface)!
        self.grDirectContext = grDirectContext
        self.size = size
    }

    public let size: ISize

    /// The Skia canvas provided by the Skia surface.
    internal let skCanvas: OpaquePointer

    /// The underlying Skia surface.
    private let skSurface: SkSurface_sp

    /// The GrDirectContext that backs the skCanvas. Used to flush the canvas.
    internal var grDirectContext: GrDirectContext_sp

    private var skPaint = SkPaint()

    public func drawLine(_ p0: Offset, _ p1: Offset, _ paint: Paint) {
        paint.copyToSkia(paint: &self.skPaint)
        sk_canvas_draw_line(skCanvas, p0.dx, p0.dy, p1.dx, p1.dy, self.skPaint)
    }

    public func drawRect(_ rect: Rect, _ paint: Paint) {
        var skRect = SkRect()
        skRect.setLTRB(rect.left, rect.top, rect.right, rect.bottom)

        paint.copyToSkia(paint: &self.skPaint)
        sk_canvas_draw_rect(skCanvas, skRect, self.skPaint)
    }

    public func drawParagraph(_ paragraph: Paragraph, _ offset: Offset) {
        let paragraph = paragraph as! SkiaParagraph
        paragraph.paint(self, offset)
    }

    public func drawTextBlob(_ blob: any TextBlob, _ offset: Offset, _ paint: Paint) {
        let blob = blob as! SkiaTextBlob
        paint.copyToSkia(paint: &self.skPaint)
        sk_canvas_draw_text_blob(skCanvas, &blob.skTextBlob, offset.dx, offset.dy, self.skPaint)
    }

    public func drawRRect(_ rrect: RRect, _ paint: Paint) {
        var skRect = SkRect()
        skRect.setLTRB(rrect.left, rrect.top, rrect.right, rrect.bottom)

        var radii = [SkPoint]()
        radii.append(SkPoint(fX: rrect.tlRadiusX, fY: rrect.tlRadiusY))
        radii.append(SkPoint(fX: rrect.trRadiusX, fY: rrect.trRadiusY))
        radii.append(SkPoint(fX: rrect.brRadiusX, fY: rrect.brRadiusY))
        radii.append(SkPoint(fX: rrect.blRadiusX, fY: rrect.blRadiusY))

        var skRrect = SkRRect()
        radii.withUnsafeBufferPointer { ptr in
            skRrect.setRectRadii(skRect, ptr.baseAddress)
        }

        paint.copyToSkia(paint: &self.skPaint)
        sk_canvas_draw_rrect(skCanvas, skRrect, self.skPaint)
    }

    public func drawDRRect(_ outer: RRect, _ inner: RRect, _ paint: Paint) {
        var skOuter = SkRect()
        skOuter.setLTRB(outer.left, outer.top, outer.right, outer.bottom)

        var radiiOuter = [SkPoint]()
        radiiOuter.append(SkPoint(fX: outer.tlRadiusX, fY: outer.tlRadiusY))
        radiiOuter.append(SkPoint(fX: outer.trRadiusX, fY: outer.trRadiusY))
        radiiOuter.append(SkPoint(fX: outer.brRadiusX, fY: outer.brRadiusY))
        radiiOuter.append(SkPoint(fX: outer.blRadiusX, fY: outer.blRadiusY))

        var skInner = SkRect()
        skInner.setLTRB(inner.left, inner.top, inner.right, inner.bottom)

        var radiiInner = [SkPoint]()
        radiiInner.append(SkPoint(fX: inner.tlRadiusX, fY: inner.tlRadiusY))
        radiiInner.append(SkPoint(fX: inner.trRadiusX, fY: inner.trRadiusY))
        radiiInner.append(SkPoint(fX: inner.brRadiusX, fY: inner.brRadiusY))
        radiiInner.append(SkPoint(fX: inner.blRadiusX, fY: inner.blRadiusY))

        var skOuterRrect = SkRRect()
        radiiOuter.withUnsafeBufferPointer { ptr in
            skOuterRrect.setRectRadii(skOuter, ptr.baseAddress)
        }

        var skInnerRrect = SkRRect()
        radiiInner.withUnsafeBufferPointer { ptr in
            skInnerRrect.setRectRadii(skInner, ptr.baseAddress)
        }

        paint.copyToSkia(paint: &self.skPaint)
        sk_canvas_draw_drrect(skCanvas, skOuterRrect, skInnerRrect, self.skPaint)
    }

    public func drawCircle(_ center: Offset, _ radius: Float, _ paint: Paint) {
        paint.copyToSkia(paint: &self.skPaint)
        sk_canvas_draw_circle(skCanvas, center.dx, center.dy, radius, self.skPaint)
    }

    public func drawPath(_ path: Path, _ paint: Paint) {
        let path = path as! SkiaPath
        paint.copyToSkia(paint: &self.skPaint)
        sk_canvas_draw_path(skCanvas, path.skPath, self.skPaint)
    }

    public func drawImage(_ image: NativeImage, _ offset: Offset, _ paint: Paint) {
        let image = image as! SkiaImage
        paint.copyToSkia(paint: &self.skPaint)
        sk_canvas_draw_image(skCanvas, &image.skImage, offset.dx, offset.dy, &self.skPaint)
    }

    public func drawImageRect(_ image: NativeImage, _ src: Rect, _ dst: Rect, _ paint: Paint) {
        let image = image as! SkiaImage
        var skSrc = SkRect()
        skSrc.setLTRB(src.left, src.top, src.right, src.bottom)
        var skDst = SkRect()
        skDst.setLTRB(dst.left, dst.top, dst.right, dst.bottom)
        paint.copyToSkia(paint: &self.skPaint)
        sk_canvas_draw_image_rect(skCanvas, &image.skImage, skSrc, skDst, &self.skPaint)
    }

    public func drawImageNine(_ image: NativeImage, _ center: Rect, _ dst: Rect, _ paint: Paint) {
        let image = image as! SkiaImage
        var skCenter = SkIRect()
        skCenter.setLTRB(
            Int32(center.left),
            Int32(center.top),
            Int32(center.right),
            Int32(center.bottom)
        )
        var skDst = SkRect()
        skDst.setLTRB(dst.left, dst.top, dst.right, dst.bottom)
        paint.copyToSkia(paint: &self.skPaint)
        sk_canvas_draw_image_nine(skCanvas, &image.skImage, skCenter, skDst, &self.skPaint)
    }

    public func clear(color: Color) {
        sk_canvas_clear(skCanvas, color.value)
    }

    public func transform(_ transform: Matrix4x4f) {
        let skMatrix = SkM44(
            transform[0, 0],
            transform[1, 0],
            transform[2, 0],
            transform[3, 0],
            transform[0, 1],
            transform[1, 1],
            transform[2, 1],
            transform[3, 1],
            transform[0, 2],
            transform[1, 2],
            transform[2, 2],
            transform[3, 2],
            transform[0, 3],
            transform[1, 3],
            transform[2, 3],
            transform[3, 3]
        )
        sk_canvas_concat(skCanvas, skMatrix)
    }

    public func translate(_ dx: Float, _ dy: Float) {
        sk_canvas_translate(skCanvas, dx, dy)
    }

    public func scale(_ sx: Float, _ sy: Float) {
        sk_canvas_scale(skCanvas, sx, sy)
    }

    public func clipRect(_ rect: Rect, _ clipOp: ClipOp, _ doAntiAlias: Bool) {
        var skRect = SkRect()
        skRect.setLTRB(rect.left, rect.top, rect.right, rect.bottom)
        sk_canvas_clip_rect(skCanvas, skRect, clipOp.toSkia(), doAntiAlias)
    }

    public func clipRRect(_ rrect: RRect, _ doAntiAlias: Bool) {
        var skRect = SkRect()
        skRect.setLTRB(rrect.left, rrect.top, rrect.right, rrect.bottom)

        var radii = [SkPoint]()
        radii.append(SkPoint(fX: rrect.tlRadiusX, fY: rrect.tlRadiusY))
        radii.append(SkPoint(fX: rrect.trRadiusX, fY: rrect.trRadiusY))
        radii.append(SkPoint(fX: rrect.brRadiusX, fY: rrect.brRadiusY))
        radii.append(SkPoint(fX: rrect.blRadiusX, fY: rrect.blRadiusY))

        var skRrect = SkRRect()
        radii.withUnsafeBufferPointer { ptr in
            skRrect.setRectRadii(skRect, ptr.baseAddress)
        }

        sk_canvas_clip_rrect(skCanvas, skRrect, SkClipOp.intersect, doAntiAlias)
    }

    public func save() {
        sk_canvas_save(skCanvas)
    }

    public func saveLayer(_ bounds: Rect, paint: Paint?) {
        var skRect = SkRect()
        skRect.setLTRB(bounds.left, bounds.top, bounds.right, bounds.bottom)
        if let paint = paint {
            paint.copyToSkia(paint: &self.skPaint)
            sk_canvas_save_layer(skCanvas, &skRect, &self.skPaint)
        } else {
            sk_canvas_save_layer(skCanvas, &skRect, nil)
        }
    }

    public func restore() {
        sk_canvas_restore(skCanvas)
    }

    public func getSaveCount() -> Int {
        Int(sk_canvas_get_save_count(skCanvas))
    }

    public func flush() {
        gr_direct_context_flush_and_submit(&grDirectContext, GrSyncCpu.yes)
    }
}
