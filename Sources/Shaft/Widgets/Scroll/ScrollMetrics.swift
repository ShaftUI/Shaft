// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A description of a [Scrollable]'s contents, useful for modeling the state
/// of its viewport.
///
/// This class defines a current position, [pixels], and a range of values
/// considered "in bounds" for that position. The range has a minimum value at
/// [minScrollExtent] and a maximum value at [maxScrollExtent] (inclusive). The
/// viewport scrolls in the direction and axis described by [axisDirection]
/// and [axis].
///
/// The [outOfRange] getter will return true if [pixels] is outside this defined
/// range. The [atEdge] getter will return true if the [pixels] position equals
/// either the [minScrollExtent] or the [maxScrollExtent].
///
/// The dimensions of the viewport in the given [axis] are described by
/// [viewportDimension].
///
/// The above values are also exposed in terms of [extentBefore],
/// [extentInside], and [extentAfter], which may be more useful for use cases
/// such as scroll bars; for example, see [Scrollbar].
public protocol ScrollMetrics {
    /// The minimum in-range value for [pixels].
    ///
    /// The actual [pixels] value might be [outOfRange].
    ///
    /// This value is typically less than or equal to
    /// [maxScrollExtent]. It can be negative infinity, if the scroll is unbounded.
    var minScrollExtent: Float { get }

    /// The maximum in-range value for [pixels].
    ///
    /// The actual [pixels] value might be [outOfRange].
    ///
    /// This value is typically greater than or equal to
    /// [minScrollExtent]. It can be infinity, if the scroll is unbounded.
    var maxScrollExtent: Float { get }

    /// Whether the [minScrollExtent] and the [maxScrollExtent] properties are available.
    var hasContentDimensions: Bool { get }

    /// The current scroll position, in logical pixels along the [axisDirection].
    var pixels: Float! { get }

    /// Whether the [pixels] property is available.
    var hasPixels: Bool { get }

    /// The extent of the viewport along the [axisDirection].
    var viewportDimension: Float { get }

    /// Whether the [viewportDimension] property is available.
    var hasViewportDimension: Bool { get }

    /// The direction in which the scroll view scrolls.
    var axisDirection: AxisDirection { get }

    /// The axis in which the scroll view scrolls.
    var axis: Axis { get }

    /// Whether the [pixels] value is outside the [minScrollExtent] and
    /// [maxScrollExtent].
    var outOfRange: Bool { get }

    /// Whether the [pixels] value is exactly at the [minScrollExtent] or the
    /// [maxScrollExtent].
    var atEdge: Bool { get }

    /// The quantity of content conceptually "above" the viewport in the scrollable.
    /// This is the content above the content described by [extentInside].
    var extentBefore: Float { get }

    /// The quantity of content conceptually "inside" the viewport in the
    /// scrollable (including empty space if the total amount of content is less
    /// than the [viewportDimension]).
    ///
    /// The value is typically the extent of the viewport ([viewportDimension])
    /// when [outOfRange] is false. It can be less when overscrolling.
    ///
    /// The value is always non-negative, and less than or equal to [viewportDimension].
    var extentInside: Float { get }

    /// The quantity of content conceptually "below" the viewport in the scrollable.
    /// This is the content below the content described by [extentInside].
    var extentAfter: Float { get }

    /// The total quantity of content available.
    ///
    /// This is the sum of [extentBefore], [extentInside], and [extentAfter], modulo
    /// any rounding errors.
    var extentTotal: Float { get }

    /// The [FlutterView.devicePixelRatio] of the view that the [Scrollable]
    /// associated with this metrics object is drawn into.
    var devicePixelRatio: Float { get }
}

extension ScrollMetrics {
    /// Default implementation of [axis].
    public var axis: Axis {
        return axisDirectionToAxis(axisDirection)
    }

    /// Default implementation of [outOfRange].
    public var outOfRange: Bool {
        return pixels < minScrollExtent || pixels > maxScrollExtent
    }

    /// Default implementation of [atEdge].
    public var atEdge: Bool {
        return pixels == minScrollExtent || pixels == maxScrollExtent
    }

    /// Default implementation of [extentBefore].
    public var extentBefore: Float {
        return max(pixels - minScrollExtent, 0.0)
    }

    /// Default implementation of [extentInside].
    public var extentInside: Float {
        assert(minScrollExtent <= maxScrollExtent)
        return viewportDimension
            // "above" overscroll value
            - (minScrollExtent - pixels).clamped(to: 0...viewportDimension)
            // "below" overscroll value
            - (pixels - maxScrollExtent).clamped(to: 0...viewportDimension)
    }

    /// Default implementation of [extentAfter].
    public var extentAfter: Float {
        return max(maxScrollExtent - pixels, 0.0)
    }

    /// Default implementation of [extentTotal].
    public var extentTotal: Float {
        return maxScrollExtent - minScrollExtent + viewportDimension
    }
}
