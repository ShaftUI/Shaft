// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

public protocol BorderRadiusGeometry {
    /// Convert this instance into a [BorderRadius], so that the radii are
    /// expressed for specific physical corners (top-left, top-right, etc) rather
    /// than in a direction-dependent manner.
    ///
    /// See also:
    ///
    ///  * [BorderRadius], for which this is a no-op (returns itself).
    ///  * [BorderRadiusDirectional], which flips the horizontal direction
    ///    based on the `direction` argument.
    func resolve(_ direction: TextDirection?) -> BorderRadius
}

extension BorderRadiusGeometry {
    public var isZero: Bool {
        if let borderRadius = self as? BorderRadius {
            return borderRadius == .zero
        }
        return false
    }
}

public struct BorderRadius: BorderRadiusGeometry, Equatable {
    public static func all(_ radius: Radius) -> BorderRadius {
        return BorderRadius(
            topLeft: radius,
            topRight: radius,
            bottomLeft: radius,
            bottomRight: radius
        )
    }

    public static var zero: BorderRadius {
        return BorderRadius.all(Radius.zero)
    }

    public init(
        topLeft: Radius,
        topRight: Radius,
        bottomLeft: Radius,
        bottomRight: Radius
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
    }

    /// The top-left [Radius].
    public var topLeft: Radius

    /// The top-right [Radius].
    public var topRight: Radius

    /// The bottom-left [Radius].
    public var bottomLeft: Radius

    /// The bottom-right [Radius].
    public var bottomRight: Radius

    /// Creates an [RRect] from the current border radius and a [Rect].
    ///
    /// If any of the radii have negative values in x or y, those values will be
    /// clamped to zero in order to produce a valid [RRect].
    public func toRRect(_ rect: Rect) -> RRect {
        // Because the current radii could be negative, we must clamp them
        // before converting them to an RRect to be rendered, since negative
        // radii on RRects don't make sense.
        return RRect.fromRectAndCorners(
            rect,
            topLeft: topLeft.clamp(minimum: Radius.zero),
            topRight: topRight.clamp(minimum: Radius.zero),
            bottomLeft: bottomLeft.clamp(minimum: Radius.zero),
            bottomRight: bottomRight.clamp(minimum: Radius.zero)
        )
    }

    public func resolve(_ direction: TextDirection?) -> BorderRadius {
        return self
    }
}

extension BorderRadiusGeometry where Self == BorderRadius {
    public static func all(_ radius: Radius) -> BorderRadius {
        return .all(radius)
    }

    public static func circular(_ radius: Float) -> BorderRadius {
        return .all(.circular(radius))
    }
}
