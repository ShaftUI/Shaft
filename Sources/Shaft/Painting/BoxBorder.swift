// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The shape to use when rendering a ``Border`` or ``BoxDecoration``.
///
/// Consider using ``ShapeBorder`` subclasses directly (with ``ShapeDecoration``),
/// instead of using ``BoxShape`` and ``Border``, if the shapes will need to be
/// interpolated or animated. The ``Border`` class cannot interpolate between
/// different shapes.
public enum BoxShape {
    /// An axis-aligned, 2D rectangle. May have rounded corners (described by a
    /// ``BorderRadius``). The edges of the rectangle will match the edges of the box
    /// into which the ``Border`` or ``BoxDecoration`` is painted.
    ///
    /// See also:
    ///
    ///  * ``RoundedRectangleBorder``, the equivalent ``ShapeBorder``.
    case rectangle

    /// A circle centered in the middle of the box into which the ``Border`` or
    /// ``BoxDecoration`` is painted. The diameter of the circle is the shortest
    /// dimension of the box, either the width or the height, such that the circle
    /// touches the edges of the box.
    ///
    /// See also:
    ///
    ///  * [CircleBorder], the equivalent ``ShapeBorder``.
    case circle

    // Don't add more, instead create a new ShapeBorder.
}

/// Base class for box borders that can paint as rectangles, circles, or rounded
/// rectangles.
///
/// This class is extended by ``Border`` and [BorderDirectional] to provide
/// concrete versions of four-sided borders using different conventions for
/// specifying the sides.
///
/// The only API difference that this class introduces over ``ShapeBorder`` is
/// that its [paint] method takes additional arguments.
public protocol BoxBorder: ShapeBorder {
    /// Paints the border within the given [Rect] on the given [Canvas].
    ///
    /// This is an extension of the [ShapeBorder.paint] method. It allows
    /// [BoxBorder] borders to be applied to different ``BoxShape``s and with
    /// different [borderRadius] parameters, without changing the [BoxBorder]
    /// object itself.
    ///
    /// The `shape` argument specifies the ``BoxShape`` to draw the border on.
    ///
    /// If the `shape` is specifies a rectangular box shape
    /// ([BoxShape.rectangle]), then the `borderRadius` argument describes the
    /// corners of the rectangle.
    ///
    /// The [getInnerPath] and [getOuterPath] methods do not know about the
    /// `shape` and `borderRadius` arguments.
    ///
    /// See also:
    ///
    ///  * [paintBorder], which is used if the border has non-uniform colors or styles and no borderRadius.
    ///  * [Border.paint], similar to this method, includes additional comments
    ///    and provides more details on each parameter than described here.
    func paint(
        _ canvas: Canvas,
        _ rect: Rect,
        _ textDirection: TextDirection?,
        _ shape: BoxShape,
        _ borderRadius: BorderRadius?
    )
}

extension BoxBorder {
    /// A convenience version of [paint] that provides a default value for the
    /// `textDirection` argument.
    func paint(
        _ canvas: Canvas,
        _ rect: Rect,
        textDirection: TextDirection? = nil,
        shape: BoxShape = .rectangle,
        borderRadius: BorderRadius? = nil
    ) {
        paint(canvas, rect, textDirection, shape, borderRadius)
    }
}

func _paintUniformBorderWithRadius(
    _ canvas: Canvas,
    _ rect: Rect,
    _ side: BorderSide,
    _ borderRadius: BorderRadius
) {
    assert(side.style != BorderStyle.none)
    var paint = Paint()
    paint.color = side.color
    let width = side.width
    if width == 0.0 {
        paint.style = PaintingStyle.stroke
        paint.strokeWidth = 0.0
        canvas.drawRRect(borderRadius.toRRect(rect), paint)
    } else {
        let borderRect = borderRadius.toRRect(rect)
        let inner = borderRect.deflate(side.strokeInset)
        let outer = borderRect.inflate(side.strokeOutset)
        canvas.drawDRRect(outer, inner, paint)
    }
}

/// Paints a Border with different widths, styles and strokeAligns, on any
/// borderRadius while using a single color.
///
/// See also:
///
///  * [paintBorder], which supports multiple colors but not borderRadius.
///  * [paint], which calls this method.
func paintNonUniformBorder(
    _ canvas: Canvas,
    _ rect: Rect,
    borderRadius: BorderRadius?,
    textDirection: TextDirection?,
    shape: BoxShape = .rectangle,
    top: BorderSide = .none,
    right: BorderSide = .none,
    bottom: BorderSide = .none,
    left: BorderSide = .none,
    color: Color
) {
    let borderRect: RRect
    switch shape {
    case .rectangle:
        borderRect = (borderRadius ?? BorderRadius.zero)
            .resolve(textDirection)
            .toRRect(rect)
    case .circle:
        assert(
            borderRadius == nil,
            "A borderRadius cannot be given when shape is a BoxShape.circle."
        )
        borderRect = RRect.fromRectAndRadius(
            Rect.fromCircle(center: rect.center, radius: rect.shortestSide / 2.0),
            Radius.circular(rect.width)
        )
    }
    var paint = Paint()
    paint.color = color
    let inner = _deflateRRect(
        borderRect,
        .ltrb(
            left.strokeInset,
            top.strokeInset,
            right.strokeInset,
            bottom.strokeInset
        )
    )
    let outer = _inflateRRect(
        borderRect,
        .ltrb(
            left.strokeOutset,
            top.strokeOutset,
            right.strokeOutset,
            bottom.strokeOutset
        )
    )
    canvas.drawDRRect(outer, inner, paint)
}

private func _inflateRRect(_ rect: RRect, _ insets: EdgeInsets) -> RRect {
    return RRect.fromLTRBAndCorners(
        rect.left - insets.left,
        rect.top - insets.top,
        rect.right + insets.right,
        rect.bottom + insets.bottom,
        topLeft: (rect.tlRadius + Radius.elliptical(insets.left, insets.top)).clamp(
            minimum: Radius.zero
        ),
        topRight: (rect.trRadius + Radius.elliptical(insets.right, insets.top)).clamp(
            minimum: Radius.zero
        ),
        bottomRight: (rect.brRadius + Radius.elliptical(insets.right, insets.bottom)).clamp(
            minimum: Radius.zero
        ),
        bottomLeft: (rect.blRadius + Radius.elliptical(insets.left, insets.bottom)).clamp(
            minimum: Radius.zero
        )
    )
}

private func _deflateRRect(_ rect: RRect, _ insets: EdgeInsets) -> RRect {
    return RRect.fromLTRBAndCorners(
        rect.left + insets.left,
        rect.top + insets.top,
        rect.right - insets.right,
        rect.bottom - insets.bottom,
        topLeft: (rect.tlRadius - Radius.elliptical(insets.left, insets.top)).clamp(
            minimum: Radius.zero
        ),
        topRight: (rect.trRadius - Radius.elliptical(insets.right, insets.top)).clamp(
            minimum: Radius.zero
        ),
        bottomRight: (rect.brRadius - Radius.elliptical(insets.right, insets.bottom)).clamp(
            minimum: Radius.zero
        ),
        bottomLeft: (rect.blRadius - Radius.elliptical(insets.left, insets.bottom)).clamp(
            minimum: Radius.zero
        )
    )
}

func _paintUniformBorderWithCircle(_ canvas: Canvas, _ rect: Rect, _ side: BorderSide) {
    assert(side.style != BorderStyle.none)
    let radius = (rect.shortestSide + side.strokeOffset) / 2
    canvas.drawCircle(rect.center, radius, side.toPaint())
}

func _paintUniformBorderWithRectangle(_ canvas: Canvas, _ rect: Rect, _ side: BorderSide) {
    assert(side.style != BorderStyle.none)
    canvas.drawRect(rect.inflate(side.strokeOffset / 2), side.toPaint())
}

/// A border of a box, comprised of four sides: top, right, bottom, left.
///
/// The sides are represented by [BorderSide] objects.
///
/// See also:
///
///  * ``BoxDecoration``, which uses this class to describe its edge decoration.
///  * [BorderSide], which is used to describe each side of the box.
///  * [Theme], from the material layer, which can be queried to obtain appropriate colors
///    to use for borders in a [MaterialApp], as shown in the "divider" sample above.
///  * [paint], which explains the behavior of ``BoxDecoration`` parameters.
///  * <https://pub.dev/packages/non_uniform_border>, a package that implements
///    a Non-Uniform Border on ShapeBorder, which is used by Material Design
///    buttons and other widgets, under the "shape" field.
public struct Border: BoxBorder, Hashable {
    /// Creates a border.
    ///
    /// All the sides of the border default to [BorderSide.none].
    public init(
        top: BorderSide = .none,
        right: BorderSide = .none,
        bottom: BorderSide = .none,
        left: BorderSide = .none
    ) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }

    /// Creates a border whose sides are all the same.
    public static func fromBorderSide(_ side: BorderSide) -> Border {
        return Border(
            top: side,
            right: side,
            bottom: side,
            left: side
        )
    }

    /// Creates a border with symmetrical vertical and horizontal sides.
    ///
    /// The `vertical` argument applies to the [left] and [right] sides, and the
    /// `horizontal` argument applies to the [top] and [bottom] sides.
    ///
    /// All arguments default to [BorderSide.none].
    public static func symmetric(
        vertical: BorderSide = .none,
        horizontal: BorderSide = .none
    ) -> Border {
        return Border(
            top: horizontal,
            right: vertical,
            bottom: horizontal,
            left: vertical
        )
    }

    /// A uniform border with all sides the same color and width.
    ///
    /// The sides default to black solid borders, one logical pixel wide.
    public static func all(
        color: Color = Color(0xFF00_0000),
        width: Float = 1.0,
        style: BorderStyle = .solid,
        strokeAlign: Float = BorderSide.strokeAlignInside
    ) -> Border {
        let side = BorderSide(color: color, width: width, style: style, strokeAlign: strokeAlign)
        return fromBorderSide(side)
    }

    /// Creates a ``Border`` that represents the addition of the two given
    /// ``Border``s.
    ///
    /// It is only valid to call this if [BorderSide.canMerge] returns true for
    /// the pairwise combination of each side on both ``Border``s.
    public static func merge(_ a: Border, _ b: Border) -> Border {
        assert(BorderSide.canMerge(a.top, b.top))
        assert(BorderSide.canMerge(a.right, b.right))
        assert(BorderSide.canMerge(a.bottom, b.bottom))
        assert(BorderSide.canMerge(a.left, b.left))
        return Border(
            top: BorderSide.merge(a.top, b.top),
            right: BorderSide.merge(a.right, b.right),
            bottom: BorderSide.merge(a.bottom, b.bottom),
            left: BorderSide.merge(a.left, b.left)
        )
    }

    public let top: BorderSide

    /// The right side of this border.
    public let right: BorderSide

    public let bottom: BorderSide

    /// The left side of this border.
    public let left: BorderSide

    public var dimensions: EdgeInsetsGeometry {
        if _widthIsUniform {
            return EdgeInsets.all(top.strokeInset)
        }

        return EdgeInsets.ltrb(
            left.strokeInset,
            top.strokeInset,
            right.strokeInset,
            bottom.strokeInset
        )
    }

    public var isUniform: Bool {
        return _colorIsUniform && _widthIsUniform && _styleIsUniform && _strokeAlignIsUniform
    }

    private var _colorIsUniform: Bool {
        let topColor = top.color
        return left.color == topColor && bottom.color == topColor && right.color == topColor
    }

    private var _widthIsUniform: Bool {
        let topWidth = top.width
        return left.width == topWidth && bottom.width == topWidth && right.width == topWidth
    }

    private var _styleIsUniform: Bool {
        let topStyle = top.style
        return left.style == topStyle && bottom.style == topStyle && right.style == topStyle
    }

    private var _strokeAlignIsUniform: Bool {
        let topStrokeAlign = top.strokeAlign
        return left.strokeAlign == topStrokeAlign
            && bottom.strokeAlign == topStrokeAlign

            && right.strokeAlign == topStrokeAlign
    }

    private func _distinctVisibleColors() -> Set<Color> {
        var colors = Set<Color>()
        if top.style != .none { colors.insert(top.color) }
        if right.style != .none { colors.insert(right.color) }
        if bottom.style != .none { colors.insert(bottom.color) }
        if left.style != .none { colors.insert(left.color) }
        return colors
    }

    private var _hasHairlineBorder: Bool {
        return (top.style == .solid && top.width == 0.0)
            || (right.style == .solid && right.width == 0.0)
            || (bottom.style == .solid && bottom.width == 0.0)
            || (left.style == .solid && left.width == 0.0)
    }

    public func add(_ other: ShapeBorder, reversed: Bool = false) -> Border? {
        if let other = other as? Border,
            BorderSide.canMerge(top, other.top),
            BorderSide.canMerge(right, other.right),
            BorderSide.canMerge(bottom, other.bottom),
            BorderSide.canMerge(left, other.left)
        {
            return Border.merge(self, other)
        }

        return nil
    }

    public func scale(_ t: Float) -> Border {
        return Border(

            top: top.scale(t),
            right: right.scale(t),
            bottom: bottom.scale(t),
            left: left.scale(t)
        )
    }

    // public func lerpFrom(_ a: ShapeBorder?, _ t: Float) -> ShapeBorder? {
    //     if let a = a as? Border {
    //         return Border.lerp(a, self, t)
    //     }
    //     return super.lerpFrom(a, t)
    // }

    // public func lerpTo(_ b: ShapeBorder?, _ t: Float) -> ShapeBorder? {
    //     if let b = b as? Border {
    //         return Border.lerp(self, b, t)
    //     }
    //     return super.lerpTo(b, t)
    // }

    /// Linearly interpolate between two borders.
    ///
    /// If a border is null, it is treated as having four [BorderSide.none]
    /// borders.
    public static func lerp(_ a: Border?, _ b: Border?, _ t: Float) -> Border? {
        if a == b {
            return a
        }
        guard let a else {
            return b?.scale(t)
        }
        guard let b else {
            return a.scale(1.0 - t)
        }
        return Border(
            top: BorderSide.lerp(a.top, b.top, t),
            right: BorderSide.lerp(a.right, b.right, t),
            bottom: BorderSide.lerp(a.bottom, b.bottom, t),
            left: BorderSide.lerp(a.left, b.left, t)
        )
    }

    /// Paints the border within the given [Rect] on the given [Canvas].
    ///
    /// Uniform borders and non-uniform borders with similar colors and styles
    /// are more efficient to paint than more complex borders.
    ///
    /// You can provide a ``BoxShape`` to draw the border on. If the `shape` in
    /// [BoxShape.circle], there is the requirement that the border has uniform
    /// color and style.
    ///
    /// If you specify a rectangular box shape ([BoxShape.rectangle]), then you
    /// may specify a ``BorderRadius``. If a `borderRadius` is specified, there is
    /// the requirement that the border has uniform color and style.
    ///
    /// The [getInnerPath] and [getOuterPath] methods do not know about the
    /// `shape` and `borderRadius` arguments.
    ///
    /// The `textDirection` argument is not used by this paint method.
    ///
    /// See also:
    ///
    ///  * [paintBorder], which is used if the border has non-uniform colors or styles and no borderRadius.
    ///  * <https://pub.dev/packages/non_uniform_border>, a package that implements
    ///    a Non-Uniform Border on ShapeBorder, which is used by Material Design
    ///    buttons and other widgets, under the "shape" field.
    public func paint(
        _ canvas: Canvas,
        _ rect: Rect,
        _ textDirection: TextDirection? = nil,
        _ shape: BoxShape = .rectangle,
        _ borderRadius: BorderRadius? = nil
    ) {
        if isUniform {
            switch top.style {
            case .none:
                return
            case .solid:
                switch shape {
                case .circle:
                    assert(
                        borderRadius == nil,
                        "A borderRadius cannot be given when shape is a BoxShape.circle."
                    )
                    _paintUniformBorderWithCircle(canvas, rect, top)
                case .rectangle:
                    if let borderRadius = borderRadius, borderRadius != .zero {
                        _paintUniformBorderWithRadius(canvas, rect, top, borderRadius)
                        return
                    }
                    _paintUniformBorderWithRectangle(canvas, rect, top)
                }
                return
            }
        }

        if _styleIsUniform && top.style == .none {
            return
        }

        // Allow painting non-uniform borders if the visible colors are uniform.

        let visibleColors = _distinctVisibleColors()
        let hasHairlineBorder = _hasHairlineBorder
        // Paint a non uniform border if a single color is visible
        // and (borderRadius is present) or (border is visible and width != 0.0).
        if visibleColors.count == 1 && !hasHairlineBorder
            && (shape == .circle || (borderRadius != nil && borderRadius != .zero))
        {
            paintNonUniformBorder(
                canvas,
                rect,
                borderRadius: borderRadius,
                textDirection: textDirection,
                shape: shape,
                top: top.style == .none ? .none : top,
                right: right.style == .none ? .none : right,
                bottom: bottom.style == .none ? .none : bottom,
                left: left.style == .none ? .none : left,
                color: visibleColors.first!
            )
            return
        }

        assert {
            if hasHairlineBorder {
                assert(
                    borderRadius == nil || borderRadius == .zero,
                    "A hairline border like `BorderSide(width: 0.0, style: BorderStyle.solid)` can only be drawn when BorderRadius is zero or null."
                )
            }
            if let borderRadius = borderRadius, borderRadius != .zero {
                assertionFailure(
                    "A borderRadius can only be given on borders with uniform colors."
                )
            }
            return true
        }

        assert {
            if shape != .rectangle {
                assertionFailure(
                    "A Border can only be drawn as a circle on borders with uniform colors."
                )
            }
            return true
        }
        assert {
            if !_strokeAlignIsUniform || top.strokeAlign != BorderSide.strokeAlignInside {
                assertionFailure(
                    "A Border can only draw strokeAlign different than BorderSide.strokeAlignInside on borders with uniform colors."
                )
            }
            return true
        }

        paintBorder(canvas, rect, top: top, right: right, bottom: bottom, left: left)
    }
}

extension BoxBorder where Self == Border {
    public static func all(_ side: BorderSide) -> Border {
        return Border.fromBorderSide(side)
    }

    public static func symmetric(
        vertical: BorderSide = .none,
        horizontal: BorderSide = .none
    ) -> Border {
        return Border.symmetric(vertical: vertical, horizontal: horizontal)
    }
}
