// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

public class RenderColoredBox: RenderBox {
    public init(color: Color) {
        self.color = color
    }

    // public override var isRepaintBoundary: Bool {
    //     return true
    // }

    public var color: Color {
        didSet {
            if color != oldValue {
                markNeedsPaint()
            }
        }
    }

    public override func performLayout() {
        size = Size(130, 130)
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        var paint = Paint()
        paint.color = color

        if size > Size.zero {
            // context.canvas.drawRect(
            //     Rect(
            //         left: offset.dx,
            //         top: offset.dy,
            //         width: size.width,
            //         height: size.height
            //     ),
            //     paint
            // )

            context.canvas.drawRRect(
                RRect.fromRectAndCorners(
                    Rect(
                        left: offset.dx,
                        top: offset.dy,
                        width: size.width,
                        height: size.height
                    ),
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10)
                ),
                paint
            )
        }
    }
}
