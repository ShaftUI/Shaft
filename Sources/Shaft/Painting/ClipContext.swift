// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Clip utilities used by [PaintingContext].
internal protocol ClipContext {
    /// The canvas on which to paint.
    var canvas: Canvas { get }
}

extension ClipContext {
    private func clipAndPaint(
        _ canvasClipCall: (Bool) -> Void,
        _ clipBehavior: Clip,
        _ bounds: Rect,
        _ painter: () -> Void
    ) {
        canvas.save()
        switch clipBehavior {
        case .none:
            break
        case .hardEdge:
            canvasClipCall(false)
        case .antiAlias:
            canvasClipCall(true)
        case .antiAliasWithSaveLayer:
            canvasClipCall(true)
            canvas.saveLayer(bounds, paint: nil)
        }
        painter()
        if clipBehavior == .antiAliasWithSaveLayer {
            canvas.restore()
        }
        canvas.restore()
    }

    /// Clip [canvas] with [Path] according to [Clip] and then paint. [canvas] is
    /// restored to the pre-clip status afterwards.
    ///
    /// `bounds` is the saveLayer bounds used for [Clip.antiAliasWithSaveLayer].
    // public func clipPathAndPaint(
    //     _ path: Path,
    //     _ clipBehavior: Clip,
    //     _ bounds: Rect,
    //     _ painter: () -> Void
    // ) {
    //     clipAndPaint(
    //         { doAntiAlias in canvas.clipPath(path, doAntiAlias: doAntiAlias) },
    //         clipBehavior,
    //         bounds,
    //         painter
    //     )
    // }

    /// Clip [canvas] with [Path] according to `rrect` and then paint. [canvas] is
    /// restored to the pre-clip status afterwards.
    ///
    /// `bounds` is the saveLayer bounds used for [Clip.antiAliasWithSaveLayer].
    // public func clipRRectAndPaint(
    //     _ rrect: RRect,
    //     _ clipBehavior: Clip,
    //     _ bounds: Rect,
    //     _ painter: () -> Void
    // ) {
    //     clipAndPaint(
    //         { doAntiAlias in canvas.clipRRect(rrect, doAntiAlias: doAntiAlias) },
    //         clipBehavior,
    //         bounds,
    //         painter
    //     )
    // }

    /// Clip [canvas] with [Path] according to `rect` and then paint. [canvas] is
    /// restored to the pre-clip status afterwards.
    ///
    /// `bounds` is the saveLayer bounds used for [Clip.antiAliasWithSaveLayer].
    public func clipRectAndPaint(
        _ rect: Rect,
        _ clipBehavior: Clip,
        _ bounds: Rect,
        _ painter: () -> Void
    ) {
        clipAndPaint(
            { doAntiAlias in canvas.clipRect(rect, doAntiAlias: doAntiAlias) },
            clipBehavior,
            bounds,
            painter
        )
    }
}
