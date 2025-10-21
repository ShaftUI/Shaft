// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An image in the render tree.
///
/// The render image attempts to find a size for itself that fits in the given
/// constraints and preserves the image's intrinsic aspect ratio.
///
/// The image is painted using [paintImage], which describes the meanings of the
/// various fields on this class in more detail.
public class RenderImage: RenderBox {
    public init(
        image: NativeImage? = nil,
        width: Float? = nil,
        height: Float? = nil,
        scale: Float = 1,
        color: Color? = nil,
        filterQuality: FilterQuality = .low,
        colorBlendMode: BlendMode = .srcIn,
        fit: BoxFit? = nil,
        alignment: any AlignmentGeometry = Alignment.center,
        repeat: ImageRepeat = .noRepeat,
        centerSlice: Rect? = nil,
        invertColors: Bool = false,
        matchTextDirection: Bool,
        textDirection: TextDirection = .ltr,
        isAntiAlias: Bool = false
    ) {
        self.image = image
        self.width = width
        self.height = height
        self.scale = scale
        self.color = color
        self.filterQuality = filterQuality
        self.colorBlendMode = colorBlendMode
        self.fit = fit
        self.alignment = alignment
        self.repeat = `repeat`
        self.centerSlice = centerSlice
        self.invertColors = invertColors
        self.matchTextDirection = matchTextDirection
        self.textDirection = textDirection
        self.isAntiAlias = isAntiAlias
    }

    /// The image to display.
    public var image: NativeImage? {
        didSet {
            if image !== oldValue {
                markNeedsPaint()
                if width == nil || height == nil {
                    markNeedsLayout()
                }
            }
        }
    }

    /// If non-null, requires the image to have this width.
    ///
    /// If null, the image will pick a size that best preserves its intrinsic
    /// aspect ratio.
    public var width: Float? {
        didSet {
            if width != oldValue {
                markNeedsLayout()
            }
        }
    }
    /// If non-null, require the image to have this height.
    ///
    /// If null, the image will pick a size that best preserves its intrinsic
    /// aspect ratio.
    public var height: Float? {
        didSet {
            if height != oldValue {
                markNeedsLayout()
            }
        }
    }
    /// Specifies the image's scale.
    ///
    /// Used when determining the best display size for the image.
    public var scale: Float {
        didSet {
            assert(scale.isFinite)

            if scale != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// If non-null, this color is blended with each image pixel using [colorBlendMode].
    public var color: Color? {
        didSet {
            if color != oldValue {
                updateColorFilter()
                markNeedsPaint()
            }
        }
    }
    /// If non-null, the value from the [Animation] is multiplied with the opacity
    /// of each image pixel before painting onto the canvas.
    // var opacity: Animation<Float>? {
    //     didSet {
    //         if opacity != oldValue {
    //             if attached {
    //                 oldValue?.removeListener(markNeedsPaint)
    //             }
    //             if attached {
    //                 opacity?.addListener(markNeedsPaint)
    //             }
    //         }
    //     }
    // }

    /// Used to set the filterQuality of the image.
    ///
    /// Use the [FilterQuality.low] quality setting to scale the image, which corresponds to
    /// bilinear interpolation, rather than the default [FilterQuality.none] which corresponds
    /// to nearest-neighbor.
    public var filterQuality: FilterQuality {
        didSet {
            if filterQuality != oldValue {
                markNeedsPaint()
            }
        }
    }

    /// Used to combine [color] with this image.
    ///
    /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
    /// the source and this image is the destination.
    ///
    /// See also:
    ///
    ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
    public var colorBlendMode: BlendMode {
        didSet {
            if colorBlendMode != oldValue {
                updateColorFilter()
                markNeedsPaint()
            }
        }
    }
    /// How to inscribe the image into the space allocated during layout.
    ///
    /// The default varies based on the other fields. See the discussion at
    /// [paintImage].
    public var fit: BoxFit? {
        didSet {
            if fit != oldValue {
                markNeedsPaint()
            }
        }
    }
    /// How to align the image within its bounds.
    ///
    /// If this is set to a text-direction-dependent value, [textDirection] must
    /// not be null.
    public var alignment: any AlignmentGeometry {
        didSet {
            if alignment.isEqualTo(oldValue) {
                markNeedResolution()
            }
        }
    }

    /// How to repeat this image if it doesn't fill its layout bounds.
    public var `repeat`: ImageRepeat {
        didSet {
            if `repeat` != oldValue {
                markNeedsPaint()
            }
        }
    }

    /// The center slice for a nine-patch image.
    ///
    /// The region of the image inside the center slice will be stretched both
    /// horizontally and vertically to fit the image into its destination. The
    /// region of the image above and below the center slice will be stretched
    /// only horizontally and the region of the image to the left and right of
    /// the center slice will be stretched only vertically.
    public var centerSlice: Rect? {
        didSet {
            if centerSlice != oldValue {
                markNeedsPaint()
            }
        }
    }

    /// Whether to invert the colors of the image.
    ///
    /// Inverting the colors of an image applies a new color filter to the paint.
    /// If there is another specified color filter, the invert will be applied
    /// after it. This is primarily used for implementing smart invert on iOS.
    public var invertColors: Bool {
        didSet {
            if invertColors != oldValue {
                markNeedsPaint()
            }
        }
    }

    /// Whether to paint the image in the direction of the [TextDirection].
    ///
    /// If this is true, then in [TextDirection.ltr] contexts, the image will be
    /// drawn with its origin in the top left (the "normal" painting direction for
    /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
    /// a scaling factor of -1 in the horizontal direction so that the origin is
    /// in the top right.
    ///
    /// This is occasionally used with images in right-to-left environments, for
    /// images that were designed for left-to-right locales. Be careful, when
    /// using this, to not flip images with integral shadows, text, or other
    /// effects that will look incorrect when flipped.
    ///
    /// If this is set to true, [textDirection] must not be null.
    public var matchTextDirection: Bool {
        didSet {
            if matchTextDirection != oldValue {
                markNeedResolution()
            }
        }
    }

    /// The text direction with which to resolve [alignment].
    ///
    /// This may be changed to null, but only after the [alignment] and
    /// [matchTextDirection] properties have been changed to values that do not
    /// depend on the direction.
    public var textDirection: TextDirection {
        didSet {
            if textDirection != oldValue {
                markNeedResolution()
            }
        }
    }

    /// Whether to paint the image with anti-aliasing.
    ///
    /// Anti-aliasing alleviates the sawtooth artifact when the image is rotated.
    public var isAntiAlias: Bool {
        didSet {
            if isAntiAlias == oldValue {
                markNeedsPaint()
            }
        }
    }

    //   ColorFilter? _colorFilter;

    //   void _updateColorFilter() {
    //     if (_color == null) {
    //       _colorFilter = null;
    //     } else {
    //       _colorFilter = ColorFilter.mode(_color!, _colorBlendMode ?? BlendMode.srcIn);
    //     }
    //   }
    private func updateColorFilter() {

    }

    private var resolvedAlignment: Alignment? = nil
    private var flipHorizontally: Bool? = nil

    private func resolve() {
        if resolvedAlignment != nil {
            return
        }
        resolvedAlignment = alignment.resolve(textDirection)
        flipHorizontally = matchTextDirection && textDirection == TextDirection.rtl
    }

    private func markNeedResolution() {
        resolvedAlignment = nil
        flipHorizontally = nil
        markNeedsPaint()
    }

    /// Find a size for the render image within the given constraints.
    ///
    ///  - The dimensions of the RenderImage must fit within the constraints.
    ///  - The aspect ratio of the RenderImage matches the intrinsic aspect
    ///    ratio of the image.
    ///  - The RenderImage's dimension are maximal subject to being smaller than
    ///    the intrinsic size of the image.
    private func sizeForConstraints(_ constraints: BoxConstraints) -> Size {
        let constraints = BoxConstraints.tightFor(width: width, height: height).enforce(constraints)

        guard let image else {
            return constraints.smallest
        }

        return constraints.constrainSizeAndAttemptToPreserveAspectRatio(
            Size(
                Float(image.width) / scale,
                Float(image.height) / scale
            )
        )
    }

    public override func hitTestSelf(_ position: Offset) -> Bool {
        true
    }

    public override func performLayout() {
        size = sizeForConstraints(boxConstraint)
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        guard let image else {
            return
        }

        resolve()

        ImagePainter(
            image: image,
            scale: scale,
            opacity: 1.0,
            fit: fit,
            alignment: resolvedAlignment!,
            centerSlice: centerSlice,
            repeat: `repeat`,
            flipHorizontally: flipHorizontally!,
            invertColors: invertColors,
            filterQuality: filterQuality,
            blendMode: .srcOver
                // isAntiAlias: isAntiAlias
        ).paint(canvas: context.canvas, rect: offset & size)
    }
}
