// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// MARK: - Offset

public struct TOffset<T: Numeric>: Equatable {
    public var dx: T

    public var dy: T

    public init(_ dx: T, _ dy: T) {
        self.dx = dx
        self.dy = dy
    }

    public static var zero: TOffset<T> {
        TOffset(0, 0)
    }
}

extension TOffset where T: FloatingPoint {
    /// Returns true if either component is [double.infinity], and false if both
    /// are finite (or negative infinity, or NaN).
    ///
    /// This is different than comparing for equality with an instance that has
    /// _both_ components set to [double.infinity].
    ///
    /// See also:
    ///
    ///  * [isFinite], which is true if both components are finite (and not NaN).
    var isInfinite: Bool { dx >= T.infinity || dy >= T.infinity }

    /// Whether both components are finite (neither infinite nor NaN).
    ///
    /// See also:
    ///
    ///  * [isInfinite], which returns true if either component is equal to
    ///    positive infinity.
    var isFinite: Bool { dx.isFinite && dy.isFinite }

    /// Unary negation operator.
    ///
    /// Returns an offset with the coordinates negated.
    public static prefix func - (offset: TOffset) -> TOffset {
        TOffset(-offset.dx, -offset.dy)
    }

    /// Binary subtraction operator.
    ///
    /// Returns an offset whose [dx] value is the left-hand-side operand's [dx]
    /// minus the right-hand-side operand's [dx] and whose [dy] value is the
    /// left-hand-side operand's [dy] minus the right-hand-side operand's [dy].
    public static func - (lhs: TOffset, rhs: TOffset) -> TOffset {
        TOffset(lhs.dx - rhs.dx, lhs.dy - rhs.dy)
    }

    /// Binary addition operator.
    ///
    /// Returns an offset whose [dx] value is the sum of the [dx] values of the
    /// two operands, and whose [dy] value is the sum of the [dy] values of the
    /// two operands.
    public static func + (lhs: TOffset, rhs: TOffset) -> TOffset {
        TOffset(lhs.dx + rhs.dx, lhs.dy + rhs.dy)
    }

    /// Multiplication operator.
    ///
    /// Returns an offset whose coordinates are the coordinates of the
    /// left-hand-side operand (an Offset) multiplied by the scalar
    /// right-hand-side operand (a double).
    public static func * (lhs: TOffset, rhs: T) -> TOffset {
        TOffset(lhs.dx * rhs, lhs.dy * rhs)
    }

    /// Division operator.
    ///
    /// Returns an offset whose coordinates are the coordinates of the
    /// left-hand-side operand (an Offset) divided by the scalar right-hand-side
    /// operand (a double).
    public static func / (lhs: TOffset, rhs: T) -> TOffset {
        TOffset(lhs.dx / rhs, lhs.dy / rhs)
    }

    /// Returns a new offset with translateX added to the x component and
    /// translateY added to the y component.
    ///
    /// If the arguments come from another [Offset], consider using the `+` or `-`
    /// operators instead:
    public func translate(_ translateX: T, _ translateY: T) -> TOffset {
        TOffset(dx + translateX, dy + translateY)
    }

    /// The magnitude of the offset.
    ///
    /// If you need this value to compare it to another [Offset]'s distance,
    /// consider using [distanceSquared] instead, since it is cheaper to
    /// compute.
    var distance: T {
        (dx * dx + dy * dy).squareRoot()
    }

    /// The square of the magnitude of the offset.
    ///
    /// This is cheaper than computing the [distance] itself.
    var distanceSquared: T {
        dx * dx + dy * dy
    }
}

extension Offset {
    /// Unary negation operator.
    ///
    /// Returns an offset with the coordinates negated.
    ///
    /// If the [Offset] represents an arrow on a plane, this operator returns the
    /// same arrow but pointing in the reverse direction.
    public static prefix func - (offset: Offset) -> Offset {
        Offset(-offset.dx, -offset.dy)
    }

    public static func + (lhs: Offset, rhs: Offset) -> Offset {
        Offset(lhs.dx + rhs.dx, lhs.dy + rhs.dy)
    }

    public static func - (lhs: Offset, rhs: Offset) -> Offset {
        Offset(lhs.dx - rhs.dx, lhs.dy - rhs.dy)
    }

    public static func & (lhs: Offset, rhs: Size) -> Rect {
        Rect(origin: lhs, size: rhs)
    }

    public static var zero: Offset {
        Offset(0, 0)
    }
}

public typealias Offset = TOffset<Float>

// MARK: - Size

/// Holds a 2D floating-point size.
///
/// You can think of this as an [Offset] from the origin.
public struct TSize<T: Numeric>: Equatable {
    public var width: T
    public var height: T

    public init(_ width: T, _ height: T) {
        self.width = width
        self.height = height
    }

    public static var zero: TSize<T> {
        TSize(0, 0)
    }

}

extension TSize where T: BinaryFloatingPoint {
    /// Returns true if either component is [double.infinity], and false if both
    /// are finite (or negative infinity, or NaN).
    ///
    /// This is different than comparing for equality with an instance that has
    /// _both_ components set to [double.infinity].
    ///
    /// See also:
    ///
    ///  * [isFinite], which is true if both components are finite (and not NaN).
    var isInfinite: Bool { width >= T.infinity || height >= T.infinity }

    /// Whether both components are finite (neither infinite nor NaN).
    ///
    /// See also:
    ///
    ///  * [isInfinite], which returns true if either component is equal to
    ///    positive infinity.
    var isFinite: Bool { width.isFinite && height.isFinite }

    /// Subtracting a [Size] from a [Size] returns the [Offset] that describes how
    /// much bigger the left-hand-side operand is than the right-hand-side
    /// operand. Adding that resulting [Offset] to the [Size] that was the
    /// right-hand-side operand would return a [Size] equal to the [Size] that was
    /// the left-hand-side operand. (i.e. if `sizeA - sizeB -> offsetA`, then
    /// `offsetA + sizeB -> sizeA`)
    public static func - (lhs: TSize<T>, rhs: TSize<T>) -> TOffset<T> {
        TOffset(lhs.width - rhs.width, lhs.height - rhs.height)
    }

    /// Subtracting an [Offset] from a [Size] returns the [Size] that is smaller than
    /// the [Size] operand by the difference given by the [Offset] operand. In other
    /// words, the returned [Size] has a [width] consisting of the [width] of the
    /// left-hand-side operand minus the [Offset.dx] dimension of the
    /// right-hand-side operand, and a [height] consisting of the [height] of the
    /// left-hand-side operand minus the [Offset.dy] dimension of the
    /// right-hand-side operand.
    public static func - (lhs: TSize<T>, rhs: TOffset<T>) -> TSize<T> {
        TSize(lhs.width - rhs.dx, lhs.height - rhs.dy)
    }

    /// Binary addition operator for adding an [Offset] to a [Size].
    ///
    /// Returns a [Size] whose [width] is the sum of the [width] of the
    /// left-hand-side operand, a [Size], and the [Offset.dx] dimension of the
    /// right-hand-side operand, an [Offset], and whose [height] is the sum of
    /// the [height] of the left-hand-side operand and the [Offset.dy] dimension
    /// of the right-hand-side operand.
    public static func + (lhs: TSize<T>, rhs: TOffset<T>) -> TSize<T> {
        TSize(lhs.width + rhs.dx, lhs.height + rhs.dy)
    }

    /// Multiplication operator.
    ///
    /// Returns a [Size] whose dimensions are the dimensions of the
    /// left-hand-side operand (a [Size]) multiplied by the scalar
    /// right-hand-side operand (a [double]).
    public static func * (lhs: TSize<T>, rhs: T) -> TSize<T> {
        TSize(lhs.width * rhs, lhs.height * rhs)
    }

    /// Division operator.
    ///
    /// Returns a [Size] whose dimensions are the dimensions of the
    /// left-hand-side operand (a [Size]) divided by the scalar right-hand-side
    /// operand (a [double]).
    public static func / (lhs: TSize<T>, rhs: T) -> TSize<T> {
        TSize(lhs.width / rhs, lhs.height / rhs)
    }

    /// The offset to the intersection of the top and left edges of the rectangle
    /// described by the given [Offset] (which is interpreted as the top-left corner)
    /// and this [Size].
    ///
    /// See also [Rect.topLeft].
    public func topLeft(origin: TOffset<T>) -> TOffset<T> {
        origin
    }

    /// The offset to the center of the top edge of the rectangle described by the
    /// given offset (which is interpreted as the top-left corner) and this size.
    ///
    /// See also [Rect.topCenter].
    public func topCenter(origin: TOffset<T>) -> TOffset<T> {
        TOffset<T>(origin.dx + width / T(2.0), origin.dy)
    }

    /// The offset to the intersection of the top and right edges of the rectangle
    /// described by the given offset (which is interpreted as the top-left corner)
    /// and this size.
    ///
    /// See also [Rect.topRight].
    public func topRight(origin: TOffset<T>) -> TOffset<T> {
        TOffset<T>(origin.dx + width, origin.dy)
    }

    /// The offset to the center of the left edge of the rectangle described by the
    /// given offset (which is interpreted as the top-left corner) and this size.
    ///
    /// See also [Rect.centerLeft].
    public func centerLeft(origin: TOffset<T>) -> TOffset<T> {
        TOffset<T>(origin.dx, origin.dy + height / T(2.0))
    }

    /// The offset to the point halfway between the left and right and the top and
    /// bottom edges of the rectangle described by the given offset (which is
    /// interpreted as the top-left corner) and this size.
    ///
    /// See also [Rect.center].
    public func center(origin: TOffset<T>) -> TOffset<T> {
        TOffset<T>(origin.dx + width / T(2.0), origin.dy + height / T(2.0))
    }

    /// The offset to the center of the right edge of the rectangle described by the
    /// given offset (which is interpreted as the top-left corner) and this size.
    ///
    /// See also [Rect.centerLeft].
    public func centerRight(origin: TOffset<T>) -> TOffset<T> {
        TOffset<T>(origin.dx + width, origin.dy + height / T(2.0))
    }

    /// The offset to the intersection of the bottom and left edges of the
    /// rectangle described by the given offset (which is interpreted as the
    /// top-left corner) and this size.
    ///
    /// See also [Rect.bottomLeft].
    public func bottomLeft(origin: TOffset<T>) -> TOffset<T> {
        TOffset<T>(origin.dx, origin.dy + height)
    }

    /// The offset to the center of the bottom edge of the rectangle described by
    /// the given offset (which is interpreted as the top-left corner) and this
    /// size.
    ///
    /// See also [Rect.bottomLeft].
    public func bottomCenter(origin: TOffset<T>) -> TOffset<T> {
        TOffset<T>(origin.dx + width / T(2.0), origin.dy + height)
    }

    /// The offset to the intersection of the bottom and right edges of the
    /// rectangle described by the given offset (which is interpreted as the
    /// top-left corner) and this size.
    ///
    /// See also [Rect.bottomRight].
    public func bottomRight(origin: TOffset<T>) -> TOffset<T> {
        TOffset<T>(origin.dx + width, origin.dy + height)
    }
}

extension TSize where T: BinaryInteger {
    public static func / (lhs: TSize, rhs: Float) -> Size {
        Size(Float(lhs.width) / rhs, Float(lhs.height) / rhs)
    }
}

extension TSize where T: SignedNumeric, T: Comparable {
    /// The lesser of the magnitudes of the [width] and the [height].
    public var shortestSide: T { min(abs(width), abs(height)) }

    /// The greater of the magnitudes of the [width] and the [height].
    public var longestSide: T { max(abs(width), abs(height)) }
}

extension TSize where T: Comparable {
    func contains(_ offset: TOffset<T>) -> Bool {
        offset.dx >= 0 && offset.dx < width && offset.dy >= 0 && offset.dy < height
    }

    public static func > (lhs: TSize, rhs: TSize) -> Bool {
        lhs.width > rhs.width && lhs.height > rhs.height
    }
}

public typealias Size = TSize<Float>

public typealias ISize = TSize<Int>

// MARK: - Rect

public struct TRect<T: Numeric>: Equatable {
    public var origin: TOffset<T>
    public var size: TSize<T>

    public init(origin: TOffset<T>, size: TSize<T>) {
        self.origin = origin
        self.size = size
    }

    /// Construct a rectangle from its left and top edges, its width, and its
    /// height.
    ///
    /// To construct a [Rect] from an [Offset] and a [Size], you can use the
    /// rectangle constructor operator `&`. See [Offset.&].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/rect_from_ltwh.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/rect_from_ltwh_dark.png#gh-dark-mode-only)
    public init(left: T, top: T, width: T, height: T) {
        self.init(origin: TOffset(left, top), size: TSize(width, height))
    }

    public init(left: T, top: T, right: T, bottom: T) {
        self.init(origin: TOffset(left, top), size: TSize(right - left, bottom - top))
    }

    public var top: T {
        get { origin.dy }
        set { origin.dy = newValue }
    }

    public var left: T {
        get { origin.dx }
        set { origin.dx = newValue }
    }

    public var bottom: T {
        get { origin.dy + size.height }
        set { origin.dy = newValue - size.height }
    }

    public var right: T {
        get { origin.dx + size.width }
        set { origin.dx = newValue - size.width }
    }

    /// The distance between the left and right edges of this rectangle.
    public var width: T { size.width }

    /// The distance between the top and bottom edges of this rectangle.
    public var height: T { size.height }

    public static var zero: TRect<T> {
        TRect(origin: .zero, size: .zero)
    }
}

/// An immutable, 2D, axis-aligned, floating-point rectangle whose coordinates
/// are relative to a given origin.
///
/// A Rect can be created with one of its constructors or from an [Offset] and a
/// [Size] using the `&` operator
extension TRect where T: BinaryFloatingPoint {
    /// Construct a rectangle that bounds the given circle.
    ///
    /// The `center` argument is assumed to be an offset from the origin.
    public static func fromCircle(center: TOffset<T>, radius: T) -> TRect<T> {
        fromCenter(center: center, width: radius * 2, height: radius * 2)
    }

    /// Constructs a rectangle from its center point, width, and height.
    ///
    /// The `center` argument is assumed to be an offset from the origin.
    public static func fromCenter(center: TOffset<T>, width: T, height: T) -> TRect<T> {
        TRect(
            left: center.dx - width / 2,
            top: center.dy - height / 2,
            right: center.dx + width / 2,
            bottom: center.dy + height / 2
        )
    }

    /// Construct the smallest rectangle that encloses the given offsets, treating
    /// them as vectors from the origin.
    public static func fromPoints(_ a: TOffset<T>, _ b: TOffset<T>) -> TRect<T> {
        TRect(
            left: min(a.dx, b.dx),
            top: min(a.dy, b.dy),
            right: max(a.dx, b.dx),
            bottom: max(a.dy, b.dy)
        )
    }

    /// The lesser of the magnitudes of the [width] and the [height] of this
    /// rectangle.
    public var shortestSide: T { min(abs(width), abs(height)) }

    /// The greater of the magnitudes of the [width] and the [height] of this
    /// rectangle.
    public var longestSide: T { max(abs(width), abs(height)) }

    /// The offset to the intersection of the top and left edges of this rectangle.
    ///
    /// See also [Size.topLeft].
    public var topLeft: TOffset<T> { TOffset<T>(left, top) }

    /// The offset to the center of the top edge of this rectangle.
    ///
    /// See also [Size.topCenter].
    public var topCenter: TOffset<T> { TOffset<T>(left + width / T(2.0), top) }

    /// The offset to the intersection of the top and right edges of this rectangle.
    ///
    /// See also [Size.topRight].
    public var topRight: TOffset<T> { TOffset<T>(right, top) }

    /// The offset to the center of the left edge of this rectangle.
    ///
    /// See also [Size.centerLeft].
    public var centerLeft: TOffset<T> { TOffset<T>(left, top + height / T(2.0)) }

    /// The offset to the point halfway between the left and right and the top and
    /// bottom edges of this rectangle.
    ///
    /// See also [Size.center].
    public var center: TOffset<T> { TOffset<T>(left + width / T(2.0), top + height / T(2.0)) }

    /// The offset to the center of the right edge of this rectangle.
    ///
    /// See also [Size.centerLeft].
    public var centerRight: TOffset<T> { TOffset<T>(right, top + height / T(2.0)) }

    /// The offset to the intersection of the bottom and left edges of this rectangle.
    ///
    /// See also [Size.bottomLeft].
    public var bottomLeft: TOffset<T> { TOffset<T>(left, bottom) }

    /// The offset to the center of the bottom edge of this rectangle.
    ///
    /// See also [Size.bottomLeft].
    public var bottomCenter: TOffset<T> { TOffset<T>(left + width / T(2.0), bottom) }

    /// The offset to the intersection of the bottom and right edges of this rectangle.
    ///
    /// See also [Size.bottomRight].
    public var bottomRight: TOffset<T> { TOffset<T>(right, bottom) }

    /// Whether all coordinates of this rectangle are finite.
    public var isFinite: Bool {
        origin.dx.isFinite && origin.dy.isFinite && width.isFinite && height.isFinite
    }

    /// Whether this rectangle encloses a non-zero area. Negative areas are
    /// considered empty.
    public var isEmpty: Bool { width <= 0 || height <= 0 }

    /// Returns a new rectangle translated by the given offset.
    ///
    /// To translate a rectangle by separate x and y components rather than by an
    /// [Offset], consider [translate].
    public func shift(_ offset: TOffset<T>) -> TRect<T> {
        TRect(
            origin: TOffset(origin.dx + offset.dx, origin.dy + offset.dy),
            size: size
        )
    }
    /// Returns a new rectangle with translateX added to the x components and
    /// translateY added to the y components.
    ///
    /// To translate a rectangle by an [Offset] rather than by separate x and y
    /// components, consider [shift].
    public func translate(_ translateX: T, _ translateY: T) -> TRect<T> {
        TRect(
            origin: TOffset(origin.dx + translateX, origin.dy + translateY),
            size: size
        )
    }

    /// Returns a new rectangle with edges moved outwards by the given delta.
    public func inflate(_ delta: T) -> TRect<T> {
        TRect(
            origin: TOffset(origin.dx - delta, origin.dy - delta),
            size: TSize(size.width + delta * 2, size.height + delta * 2)
        )
    }

    /// Returns a new rectangle with edges moved inwards by the given delta.
    public func deflate(_ delta: T) -> TRect<T> {
        inflate(-delta)
    }

    public func contains(_ offset: TOffset<T>) -> Bool {
        offset.dx >= left && offset.dx < right && offset.dy >= top && offset.dy < bottom
    }

    public func contains(_ rect: TRect<T>) -> Bool {
        rect.left >= left && rect.right <= right && rect.top >= top && rect.bottom <= bottom
    }

    public func intersects(_ rect: TRect<T>) -> Bool {
        rect.left < right && rect.right > left && rect.top < bottom && rect.bottom > top
    }

    /// Returns a new rectangle that is the intersection of the given
    /// rectangle and this rectangle. The two rectangles must overlap
    /// for this to be meaningful. If the two rectangles do not overlap,
    /// then the resulting Rect will have a negative width or height.
    public func intersect(_ rect: TRect<T>) -> TRect<T> {
        TRect(
            origin: TOffset(
                max(left, rect.left),
                max(top, rect.top)
            ),
            size: TSize(
                min(right, rect.right) - max(left, rect.left),
                min(bottom, rect.bottom) - max(top, rect.top)
            )
        )
    }

    /// Returns a new rectangle which is the bounding box containing this
    /// rectangle and the given rectangle.
    public func union(_ rect: TRect<T>) -> TRect<T> {
        TRect(
            origin: TOffset(
                min(left, rect.left),
                min(top, rect.top)
            ),
            size: TSize(
                max(right, rect.right) - min(left, rect.left),
                max(bottom, rect.bottom) - min(top, rect.top)
            )
        )
    }

    /// Whether any of the dimensions are `NaN`.
    public var hasNaN: Bool {
        left.isNaN || top.isNaN || right.isNaN || bottom.isNaN
    }
}

public typealias Rect = TRect<Float>

// MARK: - Radius

/// A radius for either circular or elliptical shapes.
public struct TRadius<T: Numeric>: Equatable {
    /// Constructs a circular radius. [x] and [y] will have the same radius value.
    public static func circular(_ radius: T) -> Self {
        TRadius.elliptical(radius, radius)
    }

    /// Constructs an elliptical radius with the given radii.
    public static func elliptical(_ x: T, _ y: T) -> Self {
        TRadius(x: x, y: y)
    }

    public static var zero: Self {
        Self(x: 0, y: 0)
    }

    /// The radius value on the horizontal axis.
    public var x: T

    /// The radius value on the vertical axis.
    public var y: T
}

public typealias Radius = TRadius<Float>

extension TRadius where T: Comparable {
    /// Returns this [Radius], with values clamped to the given min and max
    /// [Radius] values.
    ///
    /// The `min` value defaults to `Radius.circular(-double.infinity)`, and
    /// the `max` value defaults to `Radius.circular(double.infinity)`.
    public func clamp(
        minimum: Self = .circular(-Float.infinity),
        maximum: Self = .circular(Float.infinity)
    ) -> Self {
        Self.elliptical(
            min(max(x, minimum.x), maximum.x),
            min(max(y, minimum.y), maximum.y)
        )
    }
}

extension TRadius where T: BinaryFloatingPoint {
    /// Binary subtraction operator.
    ///
    /// Returns a radius whose [x] value is the left-hand-side operand's [x]
    /// minus the right-hand-side operand's [x] and whose [y] value is the
    /// left-hand-side operand's [y] minus the right-hand-side operand's [y].
    public static func - (lhs: Self, rhs: Self) -> Self {
        .elliptical(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    /// Binary addition operator.
    ///
    /// Returns a radius whose [x] value is the sum of the [x] values of the
    /// two operands, and whose [y] value is the sum of the [y] values of the
    /// two operands.
    public static func + (lhs: Self, rhs: Self) -> Self {
        .elliptical(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    /// Multiplication operator.
    ///
    /// Returns a radius whose coordinates are the coordinates of the
    /// left-hand-side operand (a radius) multiplied by the scalar
    /// right-hand-side operand (a double).
    public static func * (lhs: Self, rhs: T) -> Self {
        .elliptical(lhs.x * rhs, lhs.y * rhs)
    }

    /// Division operator.
    ///
    /// Returns a radius whose coordinates are the coordinates of the
    /// left-hand-side operand (a radius) divided by the scalar right-hand-side
    /// operand (a double).
    public static func / (lhs: Self, rhs: T) -> Self {
        .elliptical(lhs.x / rhs, lhs.y / rhs)
    }
}

// MARK: - RRect

/// An immutable rounded rectangle with the custom radii for all four corners.
public struct TRRect<T: Numeric>: Equatable {
    /// Construct a rounded rectangle from its bounding box and topLeft,
    /// topRight, bottomRight, and bottomLeft radii.
    ///
    /// The corner radii default to [Radius.zero], i.e. right-angled corners. Will
    /// assert in debug mode if any of the radii are negative in either x or y.
    public static func fromRectAndCorners(
        _ rect: TRect<T>,
        topLeft: TRadius<T> = TRadius<T>.zero,
        topRight: TRadius<T> = TRadius<T>.zero,
        bottomLeft: TRadius<T> = TRadius<T>.zero,
        bottomRight: TRadius<T> = TRadius<T>.zero
    ) -> Self {
        Self(
            left: rect.left,
            top: rect.top,
            right: rect.right,
            bottom: rect.bottom,
            tlRadiusX: topLeft.x,
            tlRadiusY: topLeft.y,
            trRadiusX: topRight.x,
            trRadiusY: topRight.y,
            blRadiusX: bottomLeft.x,
            blRadiusY: bottomLeft.y,
            brRadiusX: bottomRight.x,
            brRadiusY: bottomRight.y
        )
    }

    /// Construct a rounded rectangle from its bounding box and a radius that is
    /// the same in each corner.
    ///
    /// Will assert in debug mode if the `radius` is negative in either x or y.
    public static func fromRectAndRadius(_ rect: TRect<T>, _ radius: TRadius<T>) -> Self {
        Self(
            left: rect.left,
            top: rect.top,
            right: rect.right,
            bottom: rect.bottom,
            tlRadiusX: radius.x,
            tlRadiusY: radius.y,
            trRadiusX: radius.x,
            trRadiusY: radius.y,
            blRadiusX: radius.x,
            blRadiusY: radius.y,
            brRadiusX: radius.x,
            brRadiusY: radius.y
        )
    }

    /// Construct a rounded rectangle from its left, top, right, and bottom edges,
    /// and topLeft, topRight, bottomRight, and bottomLeft radii.
    ///
    /// The corner radii default to [Radius.zero], i.e. right-angled corners. Will
    /// assert in debug mode if any of the radii are negative in either x or y.
    public static func fromLTRBAndCorners(
        _ left: T,
        _ top: T,
        _ right: T,
        _ bottom: T,
        topLeft: TRadius<T> = .zero,
        topRight: TRadius<T> = .zero,
        bottomRight: TRadius<T> = .zero,
        bottomLeft: TRadius<T> = .zero
    ) -> Self {
        Self(
            left: left,
            top: top,
            right: right,
            bottom: bottom,
            tlRadiusX: topLeft.x,
            tlRadiusY: topLeft.y,
            trRadiusX: topRight.x,
            trRadiusY: topRight.y,
            blRadiusX: bottomLeft.x,
            blRadiusY: bottomLeft.y,
            brRadiusX: bottomRight.x,
            brRadiusY: bottomRight.y
        )
    }

    /// The offset of the left edge of this rectangle from the x axis.
    public let left: T

    /// The offset of the top edge of this rectangle from the y axis.
    public let top: T

    /// The offset of the right edge of this rectangle from the x axis.
    public let right: T

    /// The offset of the bottom edge of this rectangle from the y axis.
    public let bottom: T

    /// The top-left horizontal radius.
    public let tlRadiusX: T

    /// The top-left vertical radius.
    public let tlRadiusY: T

    /// The top-right horizontal radius.
    public let trRadiusX: T

    /// The top-right vertical radius.
    public let trRadiusY: T

    /// The bottom-left horizontal radius.
    public let blRadiusX: T

    /// The bottom-left vertical radius.
    public let blRadiusY: T

    /// The bottom-right horizontal radius.
    public let brRadiusX: T

    /// The bottom-right vertical radius.
    public let brRadiusY: T

    /// The top-right [Radius].
    public var trRadius: TRadius<T> { .elliptical(trRadiusX, trRadiusY) }

    /// The top-left [Radius].
    public var tlRadius: TRadius<T> { .elliptical(tlRadiusX, tlRadiusY) }

    /// The bottom-right [Radius].
    public var brRadius: TRadius<T> { .elliptical(brRadiusX, brRadiusY) }

    /// The bottom-left [Radius].
    public var blRadius: TRadius<T> { .elliptical(blRadiusX, blRadiusY) }

    /// The distance between the left and right edges of this rectangle.
    public var width: T { right - left }

    /// The distance between the top and bottom edges of this rectangle.
    public var height: T { bottom - top }
}

public typealias RRect = TRRect<Float>

extension TRRect where T: BinaryFloatingPoint {
    /// Returns the minimum between min and scale to which radius1 and radius2
    /// should be scaled with in order not to exceed the limit.
    private func getMin(_ min: T, _ radius1: T, _ radius2: T, _ limit: T) -> T {
        let sum = radius1 + radius2
        if sum > limit && sum != 0 {
            return Swift.min(min, limit / sum)
        }
        return min
    }

    /// Scales all radii so that on each side their sum will not exceed the size
    /// of the width/height.
    ///
    /// Skia already handles RRects with radii that are too large in this way.
    /// Therefore, this method is only needed for RRect use cases that require
    /// the appropriately scaled radii values.
    ///
    /// See the [Skia scaling implementation](https://github.com/google/skia/blob/main/src/core/SkRRect.cpp)
    /// for more details.
    public func scaleRadii() -> Self {
        var scale: T = T(1.0)
        scale = getMin(scale, blRadiusY, tlRadiusY, height)
        scale = getMin(scale, tlRadiusX, trRadiusX, width)
        scale = getMin(scale, trRadiusY, brRadiusY, height)
        scale = getMin(scale, brRadiusX, blRadiusX, width)
        assert(scale >= 0)

        if scale < T(1.0) {
            return Self(
                left: left,
                top: top,
                right: right,
                bottom: bottom,
                tlRadiusX: tlRadiusX * scale,
                tlRadiusY: tlRadiusY * scale,
                trRadiusX: trRadiusX * scale,
                trRadiusY: trRadiusY * scale,
                blRadiusX: blRadiusX * scale,
                blRadiusY: blRadiusY * scale,
                brRadiusX: brRadiusX * scale,
                brRadiusY: brRadiusY * scale
            )
        }

        return Self(
            left: left,
            top: top,
            right: right,
            bottom: bottom,
            tlRadiusX: tlRadiusX,
            tlRadiusY: tlRadiusY,
            trRadiusX: trRadiusX,
            trRadiusY: trRadiusY,
            blRadiusX: blRadiusX,
            blRadiusY: blRadiusY,
            brRadiusX: brRadiusX,
            brRadiusY: brRadiusY
        )
    }

    /// Whether the point specified by the given offset (which is assumed to be
    /// relative to the origin) lies inside the rounded rectangle.
    ///
    /// This method may allocate (and cache) a copy of the object with normalized
    /// radii the first time it is called on a particular [RRect] instance. When
    /// using this method, prefer to reuse existing [RRect]s rather than
    /// recreating the object each time.
    public func contains(_ offset: TOffset<T>) -> Bool {
        if offset.dx < left || offset.dx >= right || offset.dy < top || offset.dy >= bottom {
            return false
        }

        let scaled = scaleRadii()

        var x: T
        var y: T
        var radiusX: T
        var radiusY: T

        if offset.dx < left + scaled.tlRadiusX && offset.dy < top + scaled.tlRadiusY {
            x = offset.dx - left - scaled.tlRadiusX
            y = offset.dy - top - scaled.tlRadiusY
            radiusX = scaled.tlRadiusX
            radiusY = scaled.tlRadiusY
        } else if offset.dx > right - scaled.trRadiusX && offset.dy < top + scaled.trRadiusY {
            x = offset.dx - right + scaled.trRadiusX
            y = offset.dy - top - scaled.trRadiusY
            radiusX = scaled.trRadiusX
            radiusY = scaled.trRadiusY
        } else if offset.dx > right - scaled.brRadiusX && offset.dy > bottom - scaled.brRadiusY {
            x = offset.dx - right + scaled.brRadiusX
            y = offset.dy - bottom + scaled.brRadiusY
            radiusX = scaled.brRadiusX
            radiusY = scaled.brRadiusY
        } else if offset.dx < left + scaled.blRadiusX && offset.dy > bottom - scaled.blRadiusY {
            x = offset.dx - left - scaled.blRadiusX
            y = offset.dy - bottom + scaled.blRadiusY
            radiusX = scaled.blRadiusX
            radiusY = scaled.blRadiusY
        } else {
            return true  // inside and not within the rounded corner area
        }

        x = x / radiusX
        y = y / radiusY
        // check if the point is outside the unit circle
        if x * x + y * y > T(1.0) {
            return false
        }
        return true
    }

    /// Returns a new [RRect] with edges and radii moved outwards by the given
    /// delta.
    public func inflate(_ delta: T) -> Self {
        Self(
            left: left - delta,
            top: top - delta,
            right: right + delta,
            bottom: bottom + delta,
            tlRadiusX: max(0, tlRadiusX + delta),
            tlRadiusY: max(0, tlRadiusY + delta),
            trRadiusX: max(0, trRadiusX + delta),
            trRadiusY: max(0, trRadiusY + delta),
            blRadiusX: max(0, blRadiusX + delta),
            blRadiusY: max(0, blRadiusY + delta),
            brRadiusX: max(0, brRadiusX + delta),
            brRadiusY: max(0, brRadiusY + delta)
        )
    }

    /// Returns a new [RRect] with edges and radii moved inwards by the given delta.
    public func deflate(_ delta: T) -> Self {
        inflate(-delta)
    }
    /// Whether any of the dimensions are `NaN`.
    public var hasNaN: Bool {
        left.isNaN || top.isNaN || right.isNaN || bottom.isNaN || trRadiusX.isNaN || trRadiusY.isNaN
            || tlRadiusX.isNaN || tlRadiusY.isNaN || brRadiusX.isNaN || brRadiusY.isNaN
            || blRadiusX.isNaN || blRadiusY.isNaN
    }

}
