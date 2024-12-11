// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// How to paint any portions of a box not covered by an image.
public enum ImageRepeat {
    /// Repeat the image in both the x and y directions until the box is filled.
    case `repeat`

    /// Repeat the image in the x direction until the box is filled horizontally.
    case repeatX

    /// Repeat the image in the y direction until the box is filled vertically.
    case repeatY

    /// Leave uncovered portions of the box transparent.
    case noRepeat
}

/// Util to paints an image into the given rectangle on the canvas.
struct ImagePainter {
    /// The image to paint onto the canvas.
    let image: NativeImage

    /// The number of image pixels for each logical pixel.
    let scale: Float

    /// The opacity to paint the image onto the canvas with.
    let opacity: Float

    /// If non-null, the color filter to apply when painting the image.
    // let colorFilter: ColorFilter?

    /// How the image should be inscribed into `rect`. If null, the default
    /// behavior depends on `centerSlice`. If `centerSlice` is also null, the
    /// default behavior is [BoxFit.scaleDown]. If `centerSlice` is non-null,
    /// the default behavior is [BoxFit.fill]. See [BoxFit] for details.
    let fit: BoxFit?

    /// How the destination rectangle defined by applying `fit` is aligned
    /// within `rect`. For example, if `fit` is [BoxFit.contain] and `alignment`
    /// is [Alignment.bottomRight], the image will be as large as possible
    /// within `rect` and placed with its bottom right corner at the bottom
    /// right corner of `rect`. Defaults to [Alignment.center].
    let alignment: Alignment

    /// The image is drawn in nine portions described by splitting the image by
    /// drawing two horizontal lines and two vertical lines, where `centerSlice`
    /// describes the rectangle formed by the four points where these four lines
    /// intersect each other. (This forms a 3-by-3 grid of regions, the center
    /// region being described by `centerSlice`.) The four regions in the
    /// corners are drawn, without scaling, in the four corners of the
    /// destination rectangle defined by applying `fit`. The remaining five
    /// regions are drawn by stretching them to fit such that they exactly cover
    /// the destination rectangle while maintaining their relative positions.
    /// See also [Canvas.drawImageNine].
    let centerSlice: Rect?

    /// If the image does not fill `rect`, whether and how the image should be
    /// repeated to fill `rect`. By default, the image is not repeated. See
    /// [ImageRepeat] for details.
    let `repeat`: ImageRepeat

    /// Whether to flip the image horizontally. This is occasionally used with
    /// images in right-to-left environments, for images that were designed for
    /// left-to-right locales (or vice versa). Be careful, when using this, to
    /// not flip images with integral shadows, text, or other effects that will
    /// look incorrect when flipped.
    let flipHorizontally: Bool

    /// Inverting the colors of an image applies a new color filter to the
    /// paint. If there is another specified color filter, the invert will be
    /// applied after it. This is primarily used for implementing smart invert
    /// on iOS.
    let invertColors: Bool

    /// Use this to change the quality when scaling an image. Use the
    /// [FilterQuality.low] quality setting to scale the image, which
    /// corresponds to bilinear interpolation, rather than the default
    /// [FilterQuality.none] which corresponds to nearest-neighbor.
    let filterQuality: FilterQuality

    /// Algorithms to use when painting on the canvas.
    let blendMode: BlendMode

    /// Paints an image into the given rectangle on the canvas.
    ///
    /// The image might not fill the entire rectangle (e.g., depending on the
    /// `fit`). If `rect` is empty, nothing is painted.
    public func paint(canvas: Canvas, rect: Rect) {
        if rect.isEmpty {
            return
        }

        var outputSize = rect.size
        var inputSize = Size(Float(image.width), Float(image.height))
        var sliceBorder: Offset?

        if let centerSlice {
            sliceBorder = inputSize / scale - centerSlice.size as Offset
            outputSize = outputSize - sliceBorder! as Size
            inputSize = inputSize - sliceBorder! * scale as Size
        }
        let fit = fit ?? (centerSlice == nil ? .scaleDown : .fill)
        // assert(centerSlice == null || (fit != BoxFit.none && fit != BoxFit.cover))
        let fittedSizes = applyBoxFit(fit, inputSize: inputSize / scale, outputSize: outputSize)
        let sourceSize = fittedSizes.source * scale
        var destinationSize = fittedSizes.destination
        if centerSlice != nil {
            outputSize = outputSize + sliceBorder!
            destinationSize = destinationSize + sliceBorder!
            // We don't have the ability to draw a subset of the image at the same time
            // as we apply a nine-patch stretch.
            assert(
                sourceSize == inputSize,
                "centerSlice was used with a BoxFit that does not guarantee that the image is fully visible."
            )
        }

        var `repeat` = `repeat`
        if `repeat` != .noRepeat && destinationSize == outputSize {
            // There's no need to repeat the image because we're exactly filling the
            // output rect with the image.
            `repeat` = .noRepeat
        }

        var paint = Paint()
        paint.isAntiAlias = false
        // if let colorFilter = colorFilter {
        //     paint.colorFilter = colorFilter
        // }
        paint.color = .rgbo(0, 0, 0, opacity.clamped(to: 0.0...1.0))
        paint.filterQuality = filterQuality
        // paint.invertColors = invertColors
        paint.blendMode = blendMode
        let halfWidthDelta = (outputSize.width - destinationSize.width) / 2.0
        let halfHeightDelta = (outputSize.height - destinationSize.height) / 2.0
        let dx = halfWidthDelta + (flipHorizontally ? (-alignment.x) : alignment.x) * halfWidthDelta
        let dy = halfHeightDelta + alignment.y * halfHeightDelta
        let destinationPosition = rect.topLeft.translate(dx, dy)
        let destinationRect = destinationPosition & destinationSize

        // Set to true if we added a saveLayer to the canvas to invert/flip the image.
        // var invertedCanvas = false

        let needSave = centerSlice != nil || `repeat` != .noRepeat || flipHorizontally
        if needSave {
            canvas.save()
        }
        if `repeat` != .noRepeat {
            canvas.clipRect(rect)
        }
        if flipHorizontally {
            let dx = -(rect.left + rect.width / 2.0)
            canvas.translate(-dx, 0.0)
            canvas.scale(-1.0, 1.0)
            canvas.translate(dx, 0.0)
        }
        if let centerSlice {
            canvas.scale(1 / scale)
            if `repeat` == .noRepeat {
                canvas.drawImageNine(
                    image,
                    _scaleRect(centerSlice, scale),
                    _scaleRect(destinationRect, scale),
                    paint
                )
            } else {
                for tileRect in _generateImageTileRects(rect, destinationRect, `repeat`) {
                    canvas.drawImageNine(
                        image,
                        _scaleRect(centerSlice, scale),
                        _scaleRect(tileRect, scale),
                        paint
                    )
                }
            }
        } else {
            let sourceRect = alignment.inscribe(
                size: sourceSize,
                rect: Offset.zero & inputSize
            )
            if `repeat` == .noRepeat {
                canvas.drawImageRect(image, sourceRect, destinationRect, paint)
            } else {
                for tileRect in _generateImageTileRects(rect, destinationRect, `repeat`) {
                    canvas.drawImageRect(image, sourceRect, tileRect, paint)
                }
            }
        }
        if needSave {
            canvas.restore()
        }
        // if invertedCanvas {
        //     canvas.restore()
        // }
    }

}

func _scaleRect(_ rect: Rect, _ scale: Float) -> Rect {
    return Rect(
        left: rect.left * scale,
        top: rect.top * scale,
        right: rect.right * scale,
        bottom: rect.bottom * scale
    )
}

func _generateImageTileRects(_ outputRect: Rect, _ fundamentalRect: Rect, _ `repeat`: ImageRepeat)
    -> [Rect]
{
    var startX = 0
    var startY = 0
    var stopX = 0
    var stopY = 0
    let strideX = fundamentalRect.width
    let strideY = fundamentalRect.height

    if `repeat` == .repeat || `repeat` == .repeatX {
        startX = ((outputRect.left - fundamentalRect.left) / strideX).floor()
        stopX = ((outputRect.right - fundamentalRect.right) / strideX).ceil()
    }

    if `repeat` == .repeat || `repeat` == .repeatY {
        startY = ((outputRect.top - fundamentalRect.top) / strideY).floor()
        stopY = ((outputRect.bottom - fundamentalRect.bottom) / strideY).ceil()
    }

    var result = [Rect]()
    for i in startX...stopX {
        for j in startY...stopY {
            result.append(
                fundamentalRect.shift(Offset(Float(i) * strideX, Float(j) * strideY))
            )
        }
    }
    return result
}
