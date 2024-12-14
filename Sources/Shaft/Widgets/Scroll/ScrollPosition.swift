// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Determines which portion of the content is visible in a scroll view.
///
/// The [pixels] value determines the scroll offset that the scroll view uses to
/// select which part of its content to display. As the user scrolls the
/// viewport, this value changes, which changes the content that is displayed.
///
/// The [ScrollPosition] applies [physics] to scrolling, and stores the
/// [minScrollExtent] and [maxScrollExtent].
///
/// Scrolling is controlled by the current [activity], which is set by
/// [beginActivity]. [ScrollPosition] itself does not start any activities.
/// Instead, concrete subclasses, such as [ScrollPositionWithSingleContext],
/// typically start activities in response to user input or instructions from a
/// [ScrollController].
public class ScrollPosition: ChangeNotifier, ViewportOffset, ScrollMetrics {
    public init(
        physics: ScrollPhysics,
        context: ScrollContext,
        keepScrollOffset: Bool = true,
        oldPosition: ScrollPosition? = nil,
        debugLabel: String? = nil
    ) {
        self.physics = physics
        self.context = context
        self.keepScrollOffset = keepScrollOffset
        self.debugLabel = debugLabel
    }

    /// How the scroll position should respond to user input.
    ///
    /// For example, determines how the widget continues to animate after the
    /// user stops dragging the scroll view.
    public let physics: ScrollPhysics

    /// Where the scrolling is taking place.
    ///
    /// Typically implemented by [ScrollableState].
    public unowned let context: ScrollContext

    /// Save the current scroll offset with [PageStorage] and restore it if
    /// this scroll position's scrollable is recreated.
    ///
    /// See also:
    ///
    ///  * [ScrollController.keepScrollOffset] and [PageController.keepPage], which
    ///    create scroll positions and initialize this property.
    public let keepScrollOffset: Bool

    /// A label that is used in the [toString] output.
    ///
    /// Intended to aid with identifying animation controller instances in debug
    /// output.
    public let debugLabel: String?

    public private(set) var minScrollExtent: Float!

    public private(set) var maxScrollExtent: Float!

    public var hasContentDimensions: Bool { minScrollExtent != nil && maxScrollExtent != nil }

    public private(set) var pixels: Float!

    public private(set) var viewportDimension: Float!

    public var hasViewportDimension: Bool { viewportDimension != nil }

    public var allowImplicitScrolling: Bool { physics.allowImplicitScrolling }

    /// Whether [viewportDimension], [minScrollExtent], [maxScrollExtent],
    /// [outOfRange], and [atEdge] are available.
    ///
    /// Set to true just before the first time [applyNewDimensions] is called.
    public private(set) var haveDimensions: Bool = false

    private var didChangeViewportDimensionOrReceiveCorrection = false

    public var userScrollDirection: ScrollDirection {
        assertionFailure("Subclasses should override this method.")
        return .idle
    }

    public func applyViewportDimension(_ viewportDimension: Float) -> Bool {
        if self.viewportDimension != viewportDimension {
            self.viewportDimension = viewportDimension
            didChangeViewportDimensionOrReceiveCorrection = true
            // If this is called, you can rely on applyContentDimensions being called
            // soon afterwards in the same layout phase. So we put all the logic that
            // relies on both values being computed into applyContentDimensions.
        }
        return true
    }

    public func applyContentDimensions(_ minScrollExtent: Float, _ maxScrollExtent: Float) -> Bool {
        //         assert(haveDimensions == (_lastMetrics != null));
        // if (!nearEqual(_minScrollExtent, minScrollExtent, Tolerance.defaultTolerance.distance) ||
        //     !nearEqual(_maxScrollExtent, maxScrollExtent, Tolerance.defaultTolerance.distance) ||
        //     _didChangeViewportDimensionOrReceiveCorrection ||
        //     _lastAxis != axis) {
        assert(minScrollExtent <= maxScrollExtent)
        self.minScrollExtent = minScrollExtent
        self.maxScrollExtent = maxScrollExtent
        //   _lastAxis = axis;
        //   final ScrollMetrics? currentMetrics = haveDimensions ? copyWith() : null;
        didChangeViewportDimensionOrReceiveCorrection = false
        //   _pendingDimensions = true;
        //   if (haveDimensions && !correctForNewDimensions(_lastMetrics!, currentMetrics!)) {
        //     return false;
        //   }
        //   _haveDimensions = true;
        // }
        // assert(haveDimensions)
        // if _pendingDimensions {
        //     applyNewDimensions()
        //     _pendingDimensions = false
        // }
        // assert(!_didChangeViewportDimensionOrReceiveCorrection, 'Use correctForNewDimensions() (and return true) to change the scroll offset during applyContentDimensions().');

        // if (_isMetricsChanged()) {
        //   // It is too late to send useful notifications, because the potential
        //   // listeners have, by definition, already been built this frame. To make
        //   // sure the notification is sent at all, we delay it until after the frame
        //   // is complete.
        //   if (!_haveScheduledUpdateNotification) {
        //     scheduleMicrotask(didUpdateScrollMetrics);
        //     _haveScheduledUpdateNotification = true;
        //   }
        //   _lastMetrics = copyWith();
        // }
        return true
    }

    /// Change the value of [pixels] to the new value, without notifying any
    /// customers.
    ///
    /// This is used to adjust the position while doing layout. In particular,
    /// this is typically called as a response to [applyViewportDimension] or
    /// [applyContentDimensions] (in both cases, if this method is called, those
    /// methods should then return false to indicate that the position has been
    /// adjusted).
    ///
    /// Calling this is rarely correct in other contexts. It will not immediately
    /// cause the rendering to change, since it does not notify the widgets or
    /// render objects that might be listening to this object: they will only
    /// change when they next read the value, which could be arbitrarily later. It
    /// is generally only appropriate in the very specific case of the value being
    /// corrected during layout (since then the value is immediately read), in the
    /// specific case of a [ScrollPosition] with a single viewport customer.
    ///
    /// To cause the position to jump or animate to a new value, consider [jumpTo]
    /// or [animateTo], which will honor the normal conventions for changing the
    /// scroll offset.
    ///
    /// To force the [pixels] to a particular value without honoring the normal
    /// conventions for changing the scroll offset, consider [forcePixels]. (But
    /// see the discussion there for why that might still be a bad idea.)
    public func correctPixels(_ value: Float) {
        pixels = value
    }

    /// Apply a layout-time correction to the scroll offset.
    ///
    /// This method should change the [pixels] value by `correction`, but without
    /// calling [notifyListeners]. It is called during layout by the
    /// [RenderViewport], before [applyContentDimensions]. After this method is
    /// called, the layout will be recomputed and that may result in this method
    /// being called again, though this should be very rare.
    public func correctBy(_ correction: Float) {
        assert(
            hasPixels,
            "An initial pixels value must exist by calling correctPixels on the ScrollPosition"
        )
        pixels = pixels! + correction
        notifyListeners()
        didChangeViewportDimensionOrReceiveCorrection = true
    }

    /// Change the value of [pixels] to the new value, and notify any customers,
    /// but without honoring normal conventions for changing the scroll offset.
    ///
    /// This is used to implement [jumpTo]. It can also be used adjust the
    /// position when the dimensions of the viewport change. It should only be
    /// used when manually implementing the logic for honoring the relevant
    /// conventions of the class. For example, [ScrollPositionWithSingleContext]
    /// introduces [ScrollActivity] objects and uses [forcePixels] in conjunction
    /// with adjusting the activity, e.g. by calling
    /// [ScrollPositionWithSingleContext.goIdle], so that the activity does
    /// not immediately set the value back. (Consider, for instance, a case where
    /// one is using a [DrivenScrollActivity]. That object will ignore any calls
    /// to [forcePixels], which would result in the rendering stuttering: changing
    /// in response to [forcePixels], and then changing back to the next value
    /// derived from the animation.)
    ///
    /// To cause the position to jump or animate to a new value, consider [jumpTo]
    /// or [animateTo].
    ///
    /// This should not be called during layout (e.g. when setting the initial
    /// scroll offset). Consider [correctPixels] if you find you need to adjust
    /// the position during layout.
    public func forcePixels(_ value: Float) {
        assert(hasPixels)
        // _impliedVelocity = value - pixels
        pixels = value
        notifyListeners()
        // SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
        //     _impliedVelocity = 0
        // }, debugLabel: 'ScrollPosition.resetVelocity')
    }

    /// Jumps the scroll position from its current value to the given value,
    /// without animation, and without checking if the new value is in range.
    ///
    /// Any active animation is canceled. If the user is currently scrolling, that
    /// action is canceled.
    ///
    /// If this method changes the scroll position, a sequence of start/update/end
    /// scroll notifications will be dispatched. No overscroll notifications can
    /// be generated by this method.
    public func jumpTo(_ pixels: Float) {
        assertionFailure("Subclasses should override this method.")
    }

    /// Animates the position from its current value to the given value.
    ///
    /// Any active animation is canceled. If the user is currently scrolling, that
    /// action is canceled.
    ///
    /// The returned [Future] will complete when the animation ends, whether it
    /// completed successfully or whether it was interrupted prematurely.
    ///
    /// An animation will be interrupted whenever the user attempts to scroll
    /// manually, or whenever another activity is started, or whenever the
    /// animation reaches the edge of the viewport and attempts to overscroll. (If
    /// the [ScrollPosition] does not overscroll but instead allows scrolling
    /// beyond the extents, then going beyond the extents will not interrupt the
    /// animation.)
    ///
    /// The animation is indifferent to changes to the viewport or content
    /// dimensions.
    ///
    /// Once the animation has completed, the scroll position will attempt to
    /// begin a ballistic activity in case its value is not stable (for example,
    /// if it is scrolled beyond the extents and in that situation the scroll
    /// position would normally bounce back).
    ///
    /// The duration must not be zero. To jump to a particular value without an
    /// animation, use [jumpTo].
    ///
    /// The animation is typically handled by an [DrivenScrollActivity].
    public func animateTo(_ to: Float, duration: Duration, curve: Curve) {
        assertionFailure("Not implemented")
    }

    /// Changes the scrolling position based on a pointer signal from current
    /// value to delta without animation and without checking if new value is in
    /// range, taking min/max scroll extent into account.
    ///
    /// Any active animation is canceled. If the user is currently scrolling, that
    /// action is canceled.
    ///
    /// This method dispatches the start/update/end sequence of scrolling
    /// notifications.
    ///
    /// This method is very similar to [jumpTo], but [pointerScroll] will
    /// update the [ScrollDirection].
    public func pointerScroll(_ delta: Float) {
        assertionFailure("Subclasses should override this method.")
    }
}
