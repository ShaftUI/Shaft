// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An immutable description of how to paint a box.
///
/// The [BoxDecoration] class provides a variety of ways to draw a box.
///
/// The box has a [border], a body, and may cast a [boxShadow].
///
/// The [shape] of the box can be a circle or a rectangle. If it is a rectangle,
/// then the [borderRadius] property controls the roundness of the corners.
///
/// The body of the box is painted in layers. The bottom-most layer is the
/// [color], which fills the box. Above that is the [gradient], which also fills
/// the box. Finally there is the [image], the precise alignment of which is
/// controlled by the [DecorationImage] class.
///
/// The [border] paints over the body; the [boxShadow], naturally, paints below it.
public class BoxDecoration: Decoration {
    public init(
        color: Color? = nil,
        border: BoxBorder? = nil,
        borderRadius: (any BorderRadiusGeometry)? = nil,
        boxShadow: [BoxShadow]? = nil,
        backgroundBlendMode: BlendMode? = nil,
        shape: BoxShape = .rectangle
    ) {
        self.color = color
        self.border = border
        self.borderRadius = borderRadius
        self.boxShadow = boxShadow
        self.backgroundBlendMode = backgroundBlendMode
        self.shape = shape
    }

    /// The color to fill in the background of the box.
    ///
    /// The color is filled into the [shape] of the box (e.g., either a rectangle,
    /// potentially with a [borderRadius], or a circle).
    ///
    /// This is ignored if [gradient] is non-null.
    ///
    /// The [color] is drawn under the [image].
    let color: Color?

    /// An image to paint above the background [color] or [gradient].
    ///
    /// If [shape] is [BoxShape.circle] then the image is clipped to the circle's
    /// boundary; if [borderRadius] is non-null then the image is clipped to the
    /// given radii.
    // let image: DecorationImage?

    /// A border to draw above the background [color], [gradient], or [image].
    ///
    /// Follows the [shape] and [borderRadius].
    ///
    /// Use [Border] objects to describe borders that do not depend on the reading
    /// direction.
    ///
    /// Use [BoxBorder] objects to describe borders that should flip their left
    /// and right edges based on whether the text is being read left-to-right or
    /// right-to-left.
    let border: BoxBorder?

    /// If non-null, the corners of this box are rounded by this [BorderRadius].
    ///
    /// Applies only to boxes with rectangular shapes; ignored if [shape] is not
    /// [BoxShape.rectangle].
    let borderRadius: (any BorderRadiusGeometry)?

    /// A list of shadows cast by this box behind the box.
    ///
    /// The shadow follows the [shape] of the box.
    ///
    /// See also:
    ///
    ///  * [kElevationToShadow], for some predefined shadows used in Material
    ///    Design.
    ///  * [PhysicalModel], a widget for showing shadows.
    let boxShadow: [BoxShadow]?

    /// A gradient to use when filling the box.
    ///
    /// If this is specified, [color] has no effect.
    ///
    /// The [gradient] is drawn under the [image].
    // let gradient: Gradient?
    let gradient: Int? = nil

    /// The blend mode applied to the [color] or [gradient] background of the box.
    ///
    /// If no [backgroundBlendMode] is provided then the default painting blend
    /// mode is used.
    ///
    /// If no [color] or [gradient] is provided then the blend mode has no impact.
    let backgroundBlendMode: BlendMode?

    /// The shape to fill the background [color], [gradient], and [image] into and
    /// to cast as the [boxShadow].
    ///
    /// If this is [BoxShape.circle] then [borderRadius] is ignored.
    ///
    /// The [shape] cannot be interpolated; animating between two [BoxDecoration]s
    /// with different [shape]s will result in a discontinuity in the rendering.
    /// To interpolate between two shapes, consider using [ShapeDecoration] and
    /// different [ShapeBorder]s; in particular, [CircleBorder] instead of
    /// [BoxShape.circle] and [RoundedRectangleBorder] instead of
    /// [BoxShape.rectangle].
    let shape: BoxShape

    public func hitTest(_ size: Size, _ position: Offset, textDirection: TextDirection?) -> Bool {
        assert((Offset.zero & size).contains(position))
        switch shape {
        case BoxShape.rectangle:
            if borderRadius != nil {
                let bounds = borderRadius!.resolve(textDirection).toRRect(Offset.zero & size)
                return bounds.contains(position)
            }
            return true
        case BoxShape.circle:
            // Circles are inscribed into our smallest dimension.
            let center = size.center(origin: .zero)
            let distance = (position - center).distance
            return distance <= min(size.width, size.height) / 2.0
        }
    }

    public func createBoxPainter(onChanged: VoidCallback?) -> BoxPainter {
        BoxDecorationPainter(self, onChanged: onChanged)
    }
}

extension Decoration where Self == BoxDecoration {
    /// Creates a new `BoxDecoration` with the specified properties.
    ///
    /// This is a convenience constructor that allows you to easily create a
    /// `BoxDecoration` with common properties set. The parameters correspond to
    /// the properties of the `BoxDecoration` class.
    public static func box(
        color: Color? = nil,
        border: BoxBorder? = nil,
        borderRadius: (any BorderRadiusGeometry)? = nil,
        boxShadow: [BoxShadow]? = nil,
        backgroundBlendMode: BlendMode? = nil,
        shape: BoxShape = .rectangle
    ) -> Self {
        .init(
            color: color,
            border: border,
            borderRadius: borderRadius,
            boxShadow: boxShadow,
            backgroundBlendMode: backgroundBlendMode,
            shape: shape
        )
    }
}

private class BoxDecorationPainter: BoxPainter {

    init(_ decoration: BoxDecoration, onChanged: VoidCallback?) {
        self.decoration = decoration
        self.onChanged = onChanged
    }

    let decoration: BoxDecoration

    let onChanged: VoidCallback?

    //       Paint? _cachedBackgroundPaint;
    //   Rect? _rectForCachedBackgroundPaint;
    //   Paint _getBackgroundPaint(Rect rect, TextDirection? textDirection) {
    //     assert(_decoration.gradient != null || _rectForCachedBackgroundPaint == null);

    //     if (_cachedBackgroundPaint == null ||
    //         (_decoration.gradient != null && _rectForCachedBackgroundPaint != rect)) {
    //       final Paint paint = Paint();
    //       if (_decoration.backgroundBlendMode != null) {
    //         paint.blendMode = _decoration.backgroundBlendMode!;
    //       }
    //       if (_decoration.color != null) {
    //         paint.color = _decoration.color!;
    //       }
    //       if (_decoration.gradient != null) {
    //         paint.shader = _decoration.gradient!.createShader(rect, textDirection: textDirection);
    //         _rectForCachedBackgroundPaint = rect;
    //       }
    //       _cachedBackgroundPaint = paint;
    //     }

    //     return _cachedBackgroundPaint!;
    //   }
    var cachedBackgroundPaint: Paint?
    var rectForCachedBackgroundPaint: Rect?
    private func getBackgroundPaint(
        _ rect: Rect,
        _ textDirection: TextDirection?
    ) -> Paint {
        if cachedBackgroundPaint == nil
            || (decoration.gradient != nil && rectForCachedBackgroundPaint != rect)
        {
            var paint = Paint()
            if decoration.backgroundBlendMode != nil {
                paint.blendMode = decoration.backgroundBlendMode!
            }
            if decoration.color != nil {
                paint.color = decoration.color!
            }
            // if decoration.gradient != nil {
            //     paint.shader = decoration.gradient!.createShader(rect, textDirection: textDirection)
            //     rectForCachedBackgroundPaint = rect
            // }
            cachedBackgroundPaint = paint
        }
        return cachedBackgroundPaint!
    }

    private func paintBackgroundColor(
        _ canvas: Canvas,
        _ rect: Rect,
        _ textDirection: TextDirection?
    ) {
        if decoration.color != nil  // || decoration.gradient != nil
        {
            paintBox(canvas, rect, getBackgroundPaint(rect, textDirection), textDirection)
        }
    }

    private func paintBox(
        _ canvas: Canvas,
        _ rect: Rect,
        _ paint: Paint,
        _ textDirection: TextDirection?
    ) {
        switch decoration.shape {
        case .circle:
            assert(decoration.borderRadius == nil)
            let center = rect.center
            let radius = rect.shortestSide / 2.0
            canvas.drawCircle(center, radius, paint)
        case .rectangle:
            if decoration.borderRadius == nil || decoration.borderRadius!.isZero {
                canvas.drawRect(rect, paint)
            } else {
                canvas.drawRRect(
                    decoration.borderRadius!.resolve(textDirection).toRRect(rect),
                    paint
                )
            }
        }
    }

    private func paintShadows(_ canvas: Canvas, _ rect: Rect, _ textDirection: TextDirection?) {
        if decoration.boxShadow == nil {
            return
        }
        for boxShadow in decoration.boxShadow! {
            let paint = boxShadow.toPaint()
            let bounds = rect.shift(boxShadow.offset).inflate(boxShadow.spreadRadius)
            paintBox(canvas, bounds, paint, textDirection)
        }
    }

    func paint(_ canvas: Canvas, _ offset: Offset, configuration: ImageConfiguration) {
        assert(configuration.size != nil)
        let rect = offset & configuration.size!
        let textDirection = configuration.textDirection
        paintShadows(canvas, rect, textDirection)
        paintBackgroundColor(canvas, rect, textDirection)
        // _paintBackgroundImage(canvas, rect, configuration);
        decoration.border?.paint(
            canvas,
            rect,
            textDirection: configuration.textDirection,
            shape: decoration.shape,
            borderRadius: decoration.borderRadius?.resolve(textDirection)
        )
    }
}
