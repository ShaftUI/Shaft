// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Interface for ``Alignment`` that allows for text-direction aware resolution.
///
/// A property or argument of this type accepts classes created either with [
/// Alignment] and its variants, or ``AlignmentDirectional/new``.
///
/// To convert an ``AlignmentGeometry`` object of indeterminate type into an
/// ``Alignment`` object, call the ``resolve`` method.
public protocol AlignmentGeometry: Equatable {
    func resolve(_ direction: TextDirection) -> Alignment

    func isEqualTo(_ other: any AlignmentGeometry) -> Bool
}

/// A point within a rectangle.
///
/// `Alignment(0.0, 0.0)` represents the center of the rectangle. The distance
/// from -1.0 to +1.0 is the distance from one side of the rectangle to the
/// other side of the rectangle. Therefore, 2.0 units horizontally (or
/// vertically) is equivalent to the width (or height) of the rectangle.
///
/// `Alignment(-1.0, -1.0)` represents the top left of the rectangle.
///
/// `Alignment(1.0, 1.0)` represents the bottom right of the rectangle.
///
/// `Alignment(0.0, 3.0)` represents a point that is horizontally centered with
/// respect to the rectangle and vertically below the bottom of the rectangle by
/// the height of the rectangle.
///
/// `Alignment(0.0, -0.5)` represents a point that is horizontally centered with
/// respect to the rectangle and vertically half way between the top edge and
/// the center.
///
/// `Alignment(x, y)` in a rectangle with height h and width w describes the
/// point (x * w/2 + w/2, y * h/2 + h/2) in the coordinate system of the
/// rectangle.
///
/// ``Alignment`` uses visual coordinates, which means increasing ``x`` moves the
/// point from left to right. To support layouts with a right-to-left
/// [TextDirection], consider using ``AlignmentDirectional``, in which the
/// direction the point moves when increasing the horizontal value depends on
/// the [TextDirection].
public struct Alignment: AlignmentGeometry {
    /// Creates an alignment.
    public init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }

    /// The distance fraction in the horizontal direction.
    ///
    /// A value of -1.0 corresponds to the leftmost edge. A value of 1.0
    /// corresponds to the rightmost edge. Values are not limited to that range;
    /// values less than -1.0 represent positions to the left of the left edge,
    /// and values greater than 1.0 represent positions to the right of the right
    /// edge.
    public let x: Float

    /// The distance fraction in the vertical direction.
    ///
    /// A value of -1.0 corresponds to the topmost edge. A value of 1.0
    /// corresponds to the bottommost edge. Values are not limited to that range;
    /// values less than -1.0 represent positions above the top, and values
    /// greater than 1.0 represent positions below the bottom.
    public let y: Float

    public func resolve(_ direction: TextDirection) -> Alignment {
        self
    }

    public func isEqualTo(_ other: any AlignmentGeometry) -> Bool {
        if let other = other as? Alignment {
            return self == other
        }
        return false
    }

    /// Returns the offset that is this fraction in the direction of the given offset.
    public func alongOffset(_ other: Offset) -> Offset {
        let centerX = other.dx / 2
        let centerY = other.dy / 2
        return Offset(centerX + x * centerX, centerY + y * centerY)
    }

    /// Returns the offset that is this fraction within the given size.
    public func alongSize(_ other: Size) -> Offset {
        let centerX = other.width / 2
        let centerY = other.height / 2
        return Offset(centerX + x * centerX, centerY + y * centerY)
    }

    /// Returns the point that is this fraction within the given rect.
    public func withinRect(_ rect: Rect) -> Offset {
        let halfWidth = rect.width / 2
        let halfHeight = rect.height / 2
        return Offset(
            rect.left + halfWidth + x * halfWidth,
            rect.top + halfHeight + y * halfHeight
        )
    }

    /// Returns a rect of the given size, aligned within given rect as specified
    /// by this alignment.
    ///
    /// For example, a 100×100 size inscribed on a 200×200 rect using
    /// ``Alignment/topLeft`` would be the 100×100 rect at the top left of
    /// the 200×200 rect.
    public func inscribe(size: Size, rect: Rect) -> Rect {
        let halfWidthDelta = (rect.width - size.width) / 2
        let halfHeightDelta = (rect.height - size.height) / 2
        return Rect(
            left: rect.left + halfWidthDelta + x * halfWidthDelta,
            top: rect.top + halfHeightDelta + y * halfHeightDelta,
            width: size.width,
            height: size.height
        )
    }
}

extension AlignmentGeometry where Self == Alignment {
    /// The top left corner.
    public static var topLeft: Alignment { Self(-1.0, -1.0) }

    /// The center point along the top edge.
    public static var topCenter: Alignment { Self(0.0, -1.0) }

    /// The top right corner.
    public static var topRight: Alignment { Self(1.0, -1.0) }

    /// The center point along the left edge.
    public static var centerLeft: Alignment { Self(-1.0, 0.0) }

    /// The center point, both horizontally and vertically.
    public static var center: Alignment { Self(0.0, 0.0) }

    /// The center point along the right edge.
    public static var centerRight: Alignment { Self(1.0, 0.0) }

    /// The bottom left corner.
    public static var bottomLeft: Alignment { Self(-1.0, 1.0) }

    /// The center point along the bottom edge.
    public static var bottomCenter: Alignment { Self(0.0, 1.0) }

    /// The bottom right corner.
    public static var bottomRight: Alignment { Self(1.0, 1.0) }
}

/// The vertical alignment of text within an input box.
///
/// A single ``y`` value that can range from -1.0 to 1.0. -1.0 aligns to the top
/// of an input box so that the top of the first line of text fits within the
/// box and its padding. 0.0 aligns to the center of the box. 1.0 aligns so that
/// the bottom of the last line of text aligns with the bottom interior edge of
/// the input box.
///
/// See also:
///
///  * [TextField.textAlignVertical], which is passed on to the [InputDecorator].
///  * [CupertinoTextField.textAlignVertical], which behaves in the same way as
///    the parameter in TextField.
///  * [InputDecorator.textAlignVertical], which defines the alignment of
///    prefix, input, and suffix within an [InputDecorator].
public struct TextAlignVertical: Equatable {
    /// Creates a TextAlignVertical from any y value between -1.0 and 1.0.

    public init(y: Float) {
        precondition(y >= -1.0 && y <= 1.0)
        self.y = y
    }

    /// A value ranging from -1.0 to 1.0 that defines the topmost and bottommost
    /// locations of the top and bottom of the input box.
    public let y: Float

    /// Aligns a TextField's input Text with the topmost location within a
    /// TextField's input box.
    public static let top = TextAlignVertical(y: -1.0)

    /// Aligns a TextField's input Text to the center of the TextField.
    public static let center = TextAlignVertical(y: 0.0)

    /// Aligns a TextField's input Text with the bottommost location within a
    /// TextField.
    public static let bottom = TextAlignVertical(y: 1.0)
}

extension TextAlignVertical: CustomStringConvertible {
    public var description: String {
        "\(String(describing: type(of: self)))(y: \(y))"
    }
}
