// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The style of line to draw for a [BorderSide] in a [Border].
public enum BorderStyle {
    /// Skip the border.
    case none

    /// Draw the border as a solid line.
    case solid

    // if you add more, think about how they will lerp
}

/// A side of a border of a box.
///
/// A [Border] consists of four [BorderSide] objects: [Border.top],
/// [Border.left], [Border.right], and [Border.bottom].
///
/// Setting [BorderSide.width] to 0.0 will result in hairline rendering; see
/// [BorderSide.width] for a more involved explanation.
public struct BorderSide: Hashable {
    /// Creates the side of a border.
    ///
    /// By default, the border is 1.0 logical pixels wide and solid black.
    public init(
        color: Color = Color(0xFF00_0000),
        width: Float = 1.0,
        style: BorderStyle = .solid,
        strokeAlign: Float = 0.0
    ) {
        self.color = color
        self.width = width
        self.style = style
        self.strokeAlign = strokeAlign
    }

    /// Creates a [BorderSide] that represents the addition of the two given
    /// [BorderSide]s.
    ///
    /// It is only valid to call this if [canMerge] returns true for the two
    /// sides.
    ///
    /// If one of the sides is zero-width with [BorderStyle.none], then the other
    /// side is return as-is. If both of the sides are zero-width with
    /// [BorderStyle.none], then [BorderSide.none] is returned.
    public static func merge(_ a: BorderSide, _ b: BorderSide) -> BorderSide {
        assert(canMerge(a, b))
        let aIsNone = a.style == .none && a.width == 0.0
        let bIsNone = b.style == .none && b.width == 0.0
        if aIsNone && bIsNone {
            return .none
        }
        if aIsNone {
            return b
        }
        if bIsNone {
            return a
        }
        assert(a.color == b.color)
        assert(a.style == b.style)
        return BorderSide(
            color: a.color,  // == b.color
            width: a.width + b.width,
            style: a.style,
            strokeAlign: max(a.strokeAlign, b.strokeAlign)  // == b.style
        )
    }

    /// The color of this side of the border.
    public let color: Color

    /// The width of this side of the border, in logical pixels.
    ///
    /// Setting width to 0.0 will result in a hairline border. This means that
    /// the border will have the width of one physical pixel. Hairline
    /// rendering takes shortcuts when the path overlaps a pixel more than once.
    /// This means that it will render faster than otherwise, but it might
    /// double-hit pixels, giving it a slightly darker/lighter result.
    ///
    /// To omit the border entirely, set the [style] to [BorderStyle.none].
    public let width: Float

    /// The style of this side of the border.
    ///
    /// To omit a side, set [style] to [BorderStyle.none]. This skips
    /// painting the border, but the border still has a [width].
    public let style: BorderStyle

    /// The relative position of the stroke on a [BorderSide] in an
    /// [OutlinedBorder] or [Border].
    ///
    /// Values typically range from -1.0 ([strokeAlignInside], inside border,
    /// default) to 1.0 ([strokeAlignOutside], outside border), without any
    /// bound constraints (e.g., a value of -2.0 is not typical, but allowed).
    /// A value of 0 ([strokeAlignCenter]) will center the border on the edge
    /// of the widget.
    ///
    /// When set to [strokeAlignInside], the stroke is drawn completely inside
    /// the widget. For [strokeAlignCenter] and [strokeAlignOutside], a property
    /// such as [Container.clipBehavior] can be used in an outside widget to clip
    /// it. If [Container.decoration] has a border, the container may incorporate
    /// [width] as additional padding:
    /// - [strokeAlignInside] provides padding with full [width].
    /// - [strokeAlignCenter] provides padding with half [width].
    /// - [strokeAlignOutside] provides zero padding, as stroke is drawn entirely outside.
    ///
    /// This property is not honored by [toPaint] (because the [Paint] object
    /// cannot represent it); it is intended that classes that use [BorderSide]
    /// objects implement this property when painting borders by suitably
    /// inflating or deflating their regions.
    public let strokeAlign: Float

    /// The border is drawn fully inside of the border path.
    ///
    /// This is a constant for use with [strokeAlign].
    ///
    /// This is the default value for [strokeAlign].
    public static let strokeAlignInside: Float = -1.0

    /// The border is drawn on the center of the border path, with half of the
    /// [BorderSide.width] on the inside, and the other half on the outside of
    /// the path.
    ///
    /// This is a constant for use with [strokeAlign].
    public static let strokeAlignCenter: Float = 0.0

    /// The border is drawn on the outside of the border path.
    ///
    /// This is a constant for use with [strokeAlign].
    public static let strokeAlignOutside: Float = 1.0

    /// A hairline black border that is not rendered.
    public static var none: BorderSide {
        BorderSide(width: 0.0, style: .none)
    }

    /// Creates a copy of this border but with the given fields replaced with the new values.
    public func copyWith(
        color: Color? = nil,
        width: Float? = nil,
        style: BorderStyle? = nil,
        strokeAlign: Float? = nil
    ) -> BorderSide {
        return BorderSide(
            color: color ?? self.color,
            width: width ?? self.width,
            style: style ?? self.style,
            strokeAlign: strokeAlign ?? self.strokeAlign
        )
    }

    /// Creates a copy of this border side description but with the width scaled
    /// by the factor `t`.
    ///
    /// The `t` argument represents the multiplicand, or the position on the
    /// timeline for an interpolation from nothing to `this`, with 0.0 meaning
    /// that the object returned should be the nil variant of this object, 1.0
    /// meaning that no change should be applied, returning `this` (or something
    /// equivalent to `this`), and other values meaning that the object should be
    /// multiplied by `t`. Negative values are treated like zero.
    ///
    /// Since a zero width is normally painted as a hairline width rather than no
    /// border at all, the zero factor is special-cased to instead change the
    /// style to [BorderStyle.none].
    ///
    /// Values for `t` are usually obtained from an [Animation<double>], such as
    /// an [AnimationController].
    public func scale(_ t: Float) -> BorderSide {
        return BorderSide(
            color: color,
            width: max(0.0, width * t),
            style: t <= 0.0 ? .none : style
        )
    }

    /// Create a [Paint] object that, if used to stroke a line, will draw the line
    /// in this border's style.
    ///
    /// The [strokeAlign] property is not reflected in the [Paint]; consumers must
    /// implement that directly by inflating or deflating their region appropriately.
    ///
    /// Not all borders use this method to paint their border sides. For example,
    /// non-uniform rectangular [Border]s have beveled edges and so paint their
    /// border sides as filled shapes rather than using a stroke.
    public func toPaint() -> Paint {
        switch style {
        case .solid:
            var paint = Paint()
            paint.color = color
            paint.strokeWidth = width
            paint.style = .stroke
            return paint
        case .none:
            var paint = Paint()
            paint.color = Color(0x0000_0000)
            paint.strokeWidth = 0.0
            paint.style = .stroke
            return paint
        }
    }

    /// Whether the two given [BorderSide]s can be merged using
    /// [BorderSide.merge].
    ///
    /// Two sides can be merged if one or both are zero-width with
    /// [BorderStyle.none], or if they both have the same color and style.
    public static func canMerge(_ a: BorderSide, _ b: BorderSide) -> Bool {
        if (a.style == .none && a.width == 0.0) || (b.style == .none && b.width == 0.0) {
            return true
        }
        return a.style == b.style && a.color == b.color
    }

    /// Linearly interpolate between two border sides.
    public static func lerp(_ a: BorderSide, _ b: BorderSide, _ t: Float) -> BorderSide {
        if a == b {
            return a
        }
        if t == 0.0 {
            return a
        }
        if t == 1.0 {
            return b
        }
        let width = lerpFloat(a.width, b.width, t: t)
        if width < 0.0 {
            return .none
        }
        if a.style == b.style && a.strokeAlign == b.strokeAlign {
            return BorderSide(
                color: Color.lerp(a.color, b.color, t)!,
                width: width,
                style: a.style,  // == b.style
                strokeAlign: a.strokeAlign  // == b.strokeAlign
            )
        }
        let colorA: Color =
            switch a.style {
            case .solid: a.color
            case .none: a.color.withAlpha(0x00)
            }
        let colorB: Color =
            switch b.style {
            case .solid: b.color
            case .none: b.color.withAlpha(0x00)
            }
        if a.strokeAlign != b.strokeAlign {
            return BorderSide(
                color: Color.lerp(colorA, colorB, t)!,
                width: width,
                strokeAlign: lerpFloat(a.strokeAlign, b.strokeAlign, t: t)
            )
        }
        return BorderSide(
            color: Color.lerp(colorA, colorB, t)!,
            width: width,
            strokeAlign: a.strokeAlign  // == b.strokeAlign
        )
    }

    /// Get the amount of the stroke width that lies inside of the [BorderSide].
    ///
    /// For example, this will return the [width] for a [strokeAlign] of -1, half
    /// the [width] for a [strokeAlign] of 0, and 0 for a [strokeAlign] of 1.
    public var strokeInset: Float {
        return width * (1 - (1 + strokeAlign) / 2)
    }

    /// Get the amount of the stroke width that lies outside of the [BorderSide].
    ///
    /// For example, this will return 0 for a [strokeAlign] of -1, half the
    /// [width] for a [strokeAlign] of 0, and the [width] for a [strokeAlign]
    /// of 1.
    public var strokeOutset: Float {
        return width * (1 + strokeAlign) / 2
    }

    /// The offset of the stroke, taking into account the stroke alignment.
    ///
    /// For example, this will return the negative [width] of the stroke
    /// for a [strokeAlign] of -1, 0 for a [strokeAlign] of 0, and the
    /// [width] for a [strokeAlign] of -1.
    public var strokeOffset: Float {
        return width * strokeAlign
    }
}

/// Base class for shape outlines.
///
/// This class handles how to add multiple borders together. Subclasses define
/// various shapes, like circles ([CircleBorder]), rounded rectangles
/// ([RoundedRectangleBorder]), continuous rectangles
/// ([ContinuousRectangleBorder]), or beveled rectangles
/// ([BeveledRectangleBorder]).
public protocol ShapeBorder {
    //       /// The top side of this border.
    //   ///
    //   /// This getter is available on both [Border] and [BorderDirectional]. If
    //   /// [isUniform] is true, then this is the same style as all the other sides.
    //   BorderSide get top;

    //   /// The bottom side of this border.
    //   BorderSide get bottom;

    //   /// Whether all four sides of the border are identical. Uniform borders are
    //   /// typically more efficient to paint.
    //   ///
    //   /// A uniform border by definition has no text direction dependency and
    //   /// therefore could be expressed as a [Border], even if it is currently a
    //   /// [BorderDirectional]. A uniform border can also be expressed as a
    //   /// [RoundedRectangleBorder].
    //   bool get isUniform;

    //     /// Paints the border within the given [Rect] on the given [Canvas].
    //   ///
    //   /// This is an extension of the [ShapeBorder.paint] method. It allows
    //   /// [BoxBorder] borders to be applied to different [BoxShape]s and with
    //   /// different [borderRadius] parameters, without changing the [BoxBorder]
    //   /// object itself.
    //   ///
    //   /// The `shape` argument specifies the [BoxShape] to draw the border on.
    //   ///
    //   /// If the `shape` is specifies a rectangular box shape
    //   /// ([BoxShape.rectangle]), then the `borderRadius` argument describes the
    //   /// corners of the rectangle.
    //   ///
    //   /// The [getInnerPath] and [getOuterPath] methods do not know about the
    //   /// `shape` and `borderRadius` arguments.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [paintBorder], which is used if the border has non-uniform colors or styles and no borderRadius.
    //   ///  * [Border.paint], similar to this method, includes additional comments
    //   ///    and provides more details on each parameter than described here.
    //   @override
    //   void paint(
    //     Canvas canvas,
    //     Rect rect, {
    //     TextDirection? textDirection,
    //     BoxShape shape = BoxShape.rectangle,
    //     BorderRadius? borderRadius,
    //   });
}

/// Paints a border around the given rectangle on the canvas.
///
/// The four sides can be independently specified. They are painted in the order
/// top, right, bottom, left. This is only notable if the widths of the borders
/// and the size of the given rectangle are such that the border sides will
/// overlap each other. No effort is made to optimize the rendering of uniform
/// borders (where all the borders have the same configuration); to render a
/// uniform border, consider using [Canvas.drawRect] directly.
///
/// See also:
///
///  * [paintImage], which paints an image in a rectangle on a canvas.
///  * [Border], which uses this function to paint its border when the border is
///    not uniform.
///  * [BoxDecoration], which describes its border using the [Border] class.
public func paintBorder(
    _ canvas: Canvas,
    _ rect: Rect,
    top: BorderSide = .none,
    right: BorderSide = .none,
    bottom: BorderSide = .none,
    left: BorderSide = .none
) {
    // We draw the borders as filled shapes, unless the borders are hairline
    // borders, in which case we use PaintingStyle.stroke, with the stroke width
    // specified here.
    var paint = Paint()
    paint.strokeWidth = 0.0

    let path = backend.renderer.createPath()

    switch top.style {
    case .solid:
        paint.color = top.color
        path.reset()
        path.moveTo(rect.left, rect.top)
        path.lineTo(rect.right, rect.top)
        if top.width == 0.0 {
            paint.style = .stroke
        } else {
            paint.style = .fill
            path.lineTo(rect.right - right.width, rect.top + top.width)
            path.lineTo(rect.left + left.width, rect.top + top.width)
        }
        canvas.drawPath(path, paint)
    case .none:
        break
    }

    switch right.style {
    case .solid:
        paint.color = right.color
        path.reset()
        path.moveTo(rect.right, rect.top)
        path.lineTo(rect.right, rect.bottom)
        if right.width == 0.0 {
            paint.style = .stroke
        } else {
            paint.style = .fill
            path.lineTo(rect.right - right.width, rect.bottom - bottom.width)
            path.lineTo(rect.right - right.width, rect.top + top.width)
        }
        canvas.drawPath(path, paint)
    case .none:
        break
    }

    switch bottom.style {
    case .solid:
        paint.color = bottom.color
        path.reset()
        path.moveTo(rect.right, rect.bottom)
        path.lineTo(rect.left, rect.bottom)
        if bottom.width == 0.0 {
            paint.style = .stroke
        } else {
            paint.style = .fill
            path.lineTo(rect.left + left.width, rect.bottom - bottom.width)
            path.lineTo(rect.right - right.width, rect.bottom - bottom.width)
        }
        canvas.drawPath(path, paint)
    case .none:
        break
    }

    switch left.style {
    case .solid:
        paint.color = left.color
        path.reset()
        path.moveTo(rect.left, rect.bottom)
        path.lineTo(rect.left, rect.top)
        if left.width == 0.0 {
            paint.style = .stroke
        } else {
            paint.style = .fill
            path.lineTo(rect.left + left.width, rect.top + top.width)
            path.lineTo(rect.left + left.width, rect.bottom - bottom.width)
        }
        canvas.drawPath(path, paint)
    case .none:
        break
    }
}
