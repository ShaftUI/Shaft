// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The description of the difference between two objects, in the context of how
/// it will affect the rendering.
///
/// Used by [TextSpan.compareTo] and [TextStyle.compareTo].
///
/// The values in this enum are ordered such that they are in increasing order
/// of cost. A value with index N implies all the values with index less than N.
/// For example, [layout] (index 3) implies [paint] (2).
public enum RenderComparison: Comparable {
    /// The two objects are identical (meaning deeply equal, not necessarily
    /// ===).
    case identical

    /// The two objects are identical for the purpose of layout, but may be different
    /// in other ways.
    ///
    /// For example, maybe some event handlers changed.
    case metadata

    /// The two objects are different but only in ways that affect paint, not layout.
    ///
    /// For example, only the color is changed.
    ///
    /// [RenderObject.markNeedsPaint] would be necessary to handle this kind of
    /// change in a render object.
    case paint

    /// The two objects are different in ways that affect layout (and therefore paint).
    ///
    /// For example, the size is changed.
    ///
    /// This is the most drastic level of change possible.
    ///
    /// [RenderObject.markNeedsLayout] would be necessary to handle this kind of
    /// change in a render object.
    case layout
}

/// The two cardinal directions in two dimensions.
///
/// The axis is always relative to the current coordinate space. This means, for
/// example, that a [horizontal] axis might actually be diagonally from top
/// right to bottom left, due to some local [Transform] applied to the scene.
///
/// See also:
///
///  * [AxisDirection], which is a directional version of this enum (with values
///    like left and right, rather than just horizontal).
///  * [TextDirection], which disambiguates between left-to-right horizontal
///    content and right-to-left horizontal content.
public enum Axis {
    /// Left and right.
    ///
    /// See also:
    ///
    ///  * [TextDirection], which disambiguates between left-to-right horizontal
    ///    content and right-to-left horizontal content.
    case horizontal

    /// Up and down.
    case vertical
}

extension Axis {
    /// Returns the opposite of the given [Axis].
    ///
    /// Specifically, returns [Axis.horizontal] for [Axis.vertical], and
    /// vice versa.
    public func flip() -> Axis {
        switch self {
        case Axis.horizontal:
            return Axis.vertical
        case Axis.vertical:
            return Axis.horizontal
        }
    }
}

/// A direction in which boxes flow vertically.
///
/// This is used by the flex algorithm (e.g. [Column]) to decide in which
/// direction to draw boxes.
///
/// This is also used to disambiguate `start` and `end` values (e.g.
/// [MainAxisAlignment.start] or [CrossAxisAlignment.end]).
///
/// See also:
///
///  * [TextDirection], which controls the same thing but horizontally.
public enum VerticalDirection {
    /// Boxes should start at the bottom and be stacked vertically towards the top.
    ///
    /// The "start" is at the bottom, the "end" is at the top.
    case up

    /// Boxes should start at the top and be stacked vertically towards the bottom.
    ///
    /// The "start" is at the top, the "end" is at the bottom.
    case down
}

/// A direction along either the horizontal or vertical [Axis] in which the
/// origin, or zero position, is determined.
///
/// This value relates to the direction in which the scroll offset increases
/// from the origin. This value does not represent the direction of user input
/// that may be modifying the scroll offset, such as from a drag. For the active
/// scrolling direction, see [ScrollDirection].
public enum AxisDirection {
    /// A direction in the [Axis.vertical] where zero is at the bottom and
    /// positive values are above it: `⇈`
    ///
    /// Alphabetical content with a [GrowthDirection.forward] would have the A
    /// at the bottom and the Z at the top.
    ///
    /// For example, the behavior of a [ListView] with [ListView.reverse] set to
    /// true would have this axis direction.
    case up

    /// A direction in the [Axis.horizontal] where zero is on the left and
    /// positive values are to the right of it: `⇉`
    ///
    /// Alphabetical content with a [GrowthDirection.forward] would have the A
    /// on the left and the Z on the right. This is the ordinary reading order
    /// for a horizontal set of tabs in an English application, for example.
    ///
    /// For example, the behavior of a [ListView] with
    /// [ListView.scrollDirection] set to [Axis.horizontal] would have this axis
    /// direction.
    case right

    /// A direction in the [Axis.vertical] where zero is at the top and positive
    /// values are below it: `⇊`
    ///
    /// Alphabetical content with a [GrowthDirection.forward] would have the A
    /// at the top and the Z at the bottom. This is the ordinary reading order
    /// for a vertical list.
    ///
    /// For example, the default behavior of a [ListView] would have this axis
    /// direction.
    case down

    /// A direction in the [Axis.horizontal] where zero is to the right and
    /// positive values are to the left of it: `⇇`
    ///
    /// Alphabetical content with a [GrowthDirection.forward] would have the A
    /// at the right and the Z at the left. This is the ordinary reading order
    /// for a horizontal set of tabs in a Hebrew application, for example.
    ///
    /// For example, the behavior of a [ListView] with
    /// [ListView.scrollDirection] set to [Axis.horizontal] and
    /// [ListView.reverse] set to true would have this axis direction.
    case left
}

extension AxisDirection {
    /// Returns the [Axis] that contains the given [AxisDirection].
    ///
    /// Specifically, returns [Axis.vertical] for [AxisDirection.up] and
    /// [AxisDirection.down] and returns [Axis.horizontal] for
    /// [AxisDirection.left] and [AxisDirection.right].
    public var axis: Axis {
        switch self {
        case AxisDirection.up, AxisDirection.down:
            return Axis.vertical
        case AxisDirection.left, AxisDirection.right:
            return Axis.horizontal
        }
    }

    /// Returns whether traveling along the given axis direction visits
    /// coordinates along that axis in numerically decreasing order.
    ///
    /// Specifically, returns true for [AxisDirection.up] and
    /// [AxisDirection.left] and false for [AxisDirection.down] and
    /// [AxisDirection.right].
    public var isReversed: Bool {
        switch self {
        case AxisDirection.up, AxisDirection.left:
            return true
        case AxisDirection.down, AxisDirection.right:
            return false
        }
    }
}

/// Returns the [Axis] that contains the given [AxisDirection].
///
/// Specifically, returns [Axis.vertical] for [AxisDirection.up] and
/// [AxisDirection.down] and returns [Axis.horizontal] for [AxisDirection.left]
/// and [AxisDirection.right].
public func axisDirectionToAxis(_ axisDirection: AxisDirection) -> Axis {
    switch axisDirection {
    case .up, .down:
        return .vertical
    case .left, .right:
        return .horizontal
    }
}

/// Returns the [AxisDirection] in which reading occurs in the given [TextDirection].
///
/// Specifically, returns [AxisDirection.left] for [TextDirection.rtl] and
/// [AxisDirection.right] for [TextDirection.ltr].
public func textDirectionToAxisDirection(_ textDirection: TextDirection) -> AxisDirection {
    switch textDirection {
    case .rtl:
        return .left
    case .ltr:
        return .right
    }
}

/// Returns the opposite of the given [AxisDirection].
///
/// Specifically, returns [AxisDirection.up] for [AxisDirection.down] (and
/// vice versa), as well as [AxisDirection.left] for [AxisDirection.right] (and
/// vice versa).
///
/// See also:
///
///  * [flipAxis], which does the same thing for [Axis] values.
public func flipAxisDirection(_ axisDirection: AxisDirection) -> AxisDirection {
    switch axisDirection {
    case .up:
        return .down
    case .right:
        return .left
    case .down:
        return .up
    case .left:
        return .right
    }
}

/// Returns whether traveling along the given axis direction visits coordinates
/// along that axis in numerically decreasing order.
///
/// Specifically, returns true for [AxisDirection.up] and [AxisDirection.left]
/// and false for [AxisDirection.down] and [AxisDirection.right].
public func axisDirectionIsReversed(_ axisDirection: AxisDirection) -> Bool {
    switch axisDirection {
    case .up, .left:
        return true
    case .down, .right:
        return false
    }
}
