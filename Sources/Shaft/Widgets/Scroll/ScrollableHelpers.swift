// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A typedef for a function that can calculate the offset for a type of scroll
/// increment given a [ScrollIncrementDetails].
///
/// This function is used as the type for [Scrollable.incrementCalculator],
/// which is called from a [ScrollAction].
public typealias ScrollIncrementCalculator = (ScrollIncrementDetails) -> Double

/// Describes the type of scroll increment that will be performed by a
/// [ScrollAction] on a [Scrollable].
///
/// This is used to configure a [ScrollIncrementDetails] object to pass to a
/// [ScrollIncrementCalculator] function on a [Scrollable].
///
/// {@template flutter.widgets.ScrollIncrementType.intent}
/// This indicates the *intent* of the scroll, not necessarily the size. Not all
/// scrollable areas will have the concept of a "line" or "page", but they can
/// respond to the different standard key bindings that cause scrolling, which
/// are bound to keys that people use to indicate a "line" scroll (e.g.
/// control-arrowDown keys) or a "page" scroll (e.g. pageDown key). It is
/// recommended that at least the relative magnitudes of the scrolls match
/// expectations.
/// {@endtemplate}
public enum ScrollIncrementType {
    /// Indicates that the [ScrollIncrementCalculator] should return the scroll
    /// distance it should move when the user requests to scroll by a "line".
    ///
    /// The distance a "line" scrolls refers to what should happen when the key
    /// binding for "scroll down/up by a line" is triggered. It's up to the
    /// [ScrollIncrementCalculator] function to decide what that means for a
    /// particular scrollable.
    case line

    /// Indicates that the [ScrollIncrementCalculator] should return the scroll
    /// distance it should move when the user requests to scroll by a "page".
    ///
    /// The distance a "page" scrolls refers to what should happen when the key
    /// binding for "scroll down/up by a page" is triggered. It's up to the
    /// [ScrollIncrementCalculator] function to decide what that means for a
    /// particular scrollable.
    case page
}

/// A details object that describes the type of scroll increment being requested
/// of a [ScrollIncrementCalculator] function, as well as the current metrics
/// for the scrollable.
public struct ScrollIncrementDetails {
    /// A const constructor for a [ScrollIncrementDetails].
    public init(
        type: ScrollIncrementType,
        metrics: ScrollMetrics
    ) {
        self.type = type
        self.metrics = metrics
    }

    /// The type of scroll this is (e.g. line, page, etc.).
    ///
    /// {@macro flutter.widgets.ScrollIncrementType.intent}
    public let type: ScrollIncrementType

    /// The current metrics of the scrollable that is being scrolled.
    public let metrics: ScrollMetrics
}
/// An Intent that represents scrolling the nearest scrollable by an amount
/// appropriate for the type specified.
///
/// The actual amount of the scroll is determined by the
/// Scrollable.incrementCalculator, or by its defaults if that is not
/// specified.
public struct ScrollIntent: Intent {
    /// Creates a ScrollIntent that requests scrolling in the given
    /// direction, with the given type.
    public init(
        direction: AxisDirection,
        type: ScrollIncrementType = .line
    ) {
        self.direction = direction
        self.type = type
    }

    /// The direction in which to scroll the scrollable containing the focused
    /// widget.
    public let direction: AxisDirection

    /// The type of scrolling that is intended.
    public let type: ScrollIncrementType
}
