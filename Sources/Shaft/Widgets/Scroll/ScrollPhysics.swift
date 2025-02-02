// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The rate at which scroll momentum will be decelerated.
public enum ScrollDecelerationRate {
    /// Standard deceleration, aligned with mobile software expectations.
    case normal
    /// Increased deceleration, aligned with desktop software expectations.
    ///
    /// Appropriate for use with input devices more precise than touch screens,
    /// such as trackpads or mouse wheels.
    case fast
}

// Examples can assume:
// class FooScrollPhysics extends ScrollPhysics {
//   const FooScrollPhysics({ super.parent });
//   @override
//   FooScrollPhysics applyTo(ScrollPhysics? ancestor) {
//     return FooScrollPhysics(parent: buildParent(ancestor));
//   }
// }
// class BarScrollPhysics extends ScrollPhysics {
//   const BarScrollPhysics({ super.parent });
// }

/// Determines the physics of a [Scrollable] widget.
///
/// For example, determines how the [Scrollable] will behave when the user
/// reaches the maximum scroll extent or when the user stops scrolling.
///
/// When starting a physics [Simulation], the current scroll position and
/// velocity are used as the initial conditions for the particle in the
/// simulation. The movement of the particle in the simulation is then used to
/// determine the scroll position for the widget.
///
/// Instead of creating your own subclasses, [parent] can be used to combine
/// [ScrollPhysics] objects of different types to get the desired scroll physics.
/// For example:
///
/// ```dart
/// const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
/// ```
///
/// You can also use `applyTo`, which is useful when you already have
/// an instance of [ScrollPhysics]:
///
/// ```dart
/// ScrollPhysics physics = const BouncingScrollPhysics();
/// // ...
/// final ScrollPhysics mergedPhysics = physics.applyTo(const AlwaysScrollableScrollPhysics());
/// ```
///
/// When implementing a subclass, you must override [applyTo] so that it returns
/// an appropriate instance of your subclass.  Otherwise, classes like
/// [Scrollable] that inform a [ScrollPosition] will combine them with
/// the default [ScrollPhysics] object instead of your custom subclass.
public class ScrollPhysics {
    /// Creates an object with the default scroll physics.
    public init(parent: ScrollPhysics? = nil) {
        self.parent = parent
    }

    /// If non-null, determines the default behavior for each method.
    ///
    /// If a subclass of [ScrollPhysics] does not override a method, that subclass
    /// will inherit an implementation from this base class that defers to
    /// [parent]. This mechanism lets you assemble novel combinations of
    /// [ScrollPhysics] subclasses at runtime. For example:
    ///
    /// ```dart
    /// const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
    /// ```
    ///
    /// will result in a [ScrollPhysics] that has the combined behavior
    /// of [BouncingScrollPhysics] and [AlwaysScrollableScrollPhysics]:
    /// behaviors that are not specified in [BouncingScrollPhysics]
    /// (e.g. [shouldAcceptUserOffset]) will defer to [AlwaysScrollableScrollPhysics].
    public let parent: ScrollPhysics?

    /// If [parent] is null then return ancestor, otherwise recursively build a
    /// ScrollPhysics that has [ancestor] as its parent.
    ///
    /// This method is typically used to define [applyTo] methods like:
    ///
    /// ```dart
    /// class MyScrollPhysics extends ScrollPhysics {
    ///   const MyScrollPhysics({ super.parent });
    ///
    ///   @override
    ///   MyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    ///     return MyScrollPhysics(parent: buildParent(ancestor));
    ///   }
    ///
    ///   // ...
    /// }
    /// ```
    internal func buildParent(_ ancestor: ScrollPhysics?) -> ScrollPhysics {
        return parent?.applyTo(ancestor) ?? ancestor!
    }

    /// Combines this [ScrollPhysics] instance with the given physics.
    ///
    /// The returned object uses this instance's physics when it has an
    /// opinion, and defers to the given `ancestor` object's physics
    /// when it does not.
    ///
    /// If [parent] is null then this returns a [ScrollPhysics] with the
    /// same [runtimeType], but where the [parent] has been replaced
    /// with the [ancestor].
    ///
    /// If this scroll physics object already has a parent, then this
    /// method is applied recursively and ancestor will appear at the
    /// end of the existing chain of parents.
    ///
    /// Calling this method with a null argument will copy the current
    /// object. This is inefficient.
    ///
    /// ## Implementing [applyTo]
    ///
    /// When creating a custom [ScrollPhysics] subclass, this method
    /// must be implemented. If the physics class has no constructor
    /// arguments, then implementing this method is merely a matter of
    /// calling the constructor with a [parent] constructed using
    /// [buildParent], as follows:
    ///
    /// ```dart
    /// class MyScrollPhysics extends ScrollPhysics {
    ///   const MyScrollPhysics({ super.parent });
    ///
    ///   @override
    ///   MyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    ///     return MyScrollPhysics(parent: buildParent(ancestor));
    ///   }
    ///
    ///   // ...
    /// }
    /// ```
    ///
    /// If the physics class has constructor arguments, they must be passed to
    /// the constructor here as well, so as to create a clone.
    ///
    /// See also:
    ///
    ///  * [buildParent], a utility method that's often used to define [applyTo]
    ///    methods for [ScrollPhysics] subclasses.
    public func applyTo(_ ancestor: ScrollPhysics?) -> ScrollPhysics {
        return ScrollPhysics(parent: buildParent(ancestor))
    }

    /// Used by [DragScrollActivity] and other user-driven activities to convert
    /// an offset in logical pixels as provided by the [DragUpdateDetails] into a
    /// delta to apply (subtract from the current position) using
    /// [ScrollActivityDelegate.setPixels].
    ///
    /// This is used by some [ScrollPosition] subclasses to apply friction during
    /// overscroll situations.
    ///
    /// This method must not adjust parts of the offset that are entirely within
    /// the bounds described by the given `position`.
    ///
    /// The given `position` is only valid during this method call. Do not keep a
    /// reference to it to use later, as the values may update, may not update, or
    /// may update to reflect an entirely unrelated scrollable.
    public func applyPhysicsToUserOffset(_ position: ScrollMetrics, _ offset: Double) -> Double {
        return parent?.applyPhysicsToUserOffset(position, offset) ?? offset
    }

    /// Whether the scrollable should let the user adjust the scroll offset, for
    /// example by dragging. If [allowUserScrolling] is false, the scrollable
    /// will never allow user input to change the scroll position.
    ///
    /// By default, the user can manipulate the scroll offset if, and only if,
    /// there is actually content outside the viewport to reveal.
    ///
    /// The given `position` is only valid during this method call. Do not keep a
    /// reference to it to use later, as the values may update, may not update, or
    /// may update to reflect an entirely unrelated scrollable.
    public func shouldAcceptUserOffset(_ position: ScrollMetrics) -> Bool {
        if !allowUserScrolling {
            return false
        }

        if parent == nil {
            return position.pixels != 0.0 || position.minScrollExtent != position.maxScrollExtent
        }
        return parent!.shouldAcceptUserOffset(position)
    }

    /// Provides a heuristic to determine if expensive frame-bound tasks should be
    /// deferred.
    ///
    /// The `velocity` parameter may be positive, negative, or zero.
    ///
    /// The `context` parameter normally refers to the [BuildContext] of the widget
    /// making the call, such as an [Image] widget in a [ListView].
    ///
    /// This can be used to determine whether decoding or fetching complex data
    /// for the currently visible part of the viewport should be delayed
    /// to avoid doing work that will not have a chance to appear before a new
    /// frame is rendered.
    ///
    /// For example, a list of images could use this logic to delay decoding
    /// images until scrolling is slow enough to actually render the decoded
    /// image to the screen.
    ///
    /// The default implementation is a heuristic that compares the current
    /// scroll velocity in local logical pixels to the longest side of the window
    /// in physical pixels. Implementers can change this heuristic by overriding
    /// this method and providing their custom physics to the scrollable widget.
    /// For example, an application that changes the local coordinate system with
    /// a large perspective transform could provide a more or less aggressive
    /// heuristic depending on whether the transform was increasing or decreasing
    /// the overall scale between the global screen and local scrollable
    /// coordinate systems.
    ///
    /// The default implementation is stateless, and provides a point-in-time
    /// decision about how fast the scrollable is scrolling. It would always
    /// return true for a scrollable that is animating back and forth at high
    /// velocity in a loop. It is assumed that callers will handle such
    /// a case, or that a custom stateful implementation would be written that
    /// tracks the sign of the velocity on successive calls.
    ///
    /// Returning true from this method indicates that the current scroll velocity
    /// is great enough that expensive operations impacting the UI should be
    /// deferred.
    public func recommendDeferredLoading(
        _ velocity: Double,
        _ metrics: ScrollMetrics,
        _ context: BuildContext
    ) -> Bool {
        if parent == nil {
            let maxPhysicalPixels = View.maybeOf(context)!.physicalSize.longestSide
            return abs(velocity) > Double(maxPhysicalPixels)
        }
        return parent!.recommendDeferredLoading(velocity, metrics, context)
    }

    /// Determines the overscroll by applying the boundary conditions.
    ///
    /// Called by [ScrollPosition.applyBoundaryConditions], which is called by
    /// [ScrollPosition.setPixels] just before the [ScrollPosition.pixels] value
    /// is updated, to determine how much of the offset is to be clamped off and
    /// sent to [ScrollPosition.didOverscrollBy].
    ///
    /// The `value` argument is guaranteed to not equal the [ScrollMetrics.pixels]
    /// of the `position` argument when this is called.
    ///
    /// It is possible for this method to be called when the `position` describes
    /// an already-out-of-bounds position. In that case, the boundary conditions
    /// should usually only prevent a further increase in the extent to which the
    /// position is out of bounds, allowing a decrease to be applied successfully,
    /// so that (for instance) an animation can smoothly snap an out of bounds
    /// position to the bounds. See [BallisticScrollActivity].
    ///
    /// This method must not clamp parts of the offset that are entirely within
    /// the bounds described by the given `position`.
    ///
    /// The given `position` is only valid during this method call. Do not keep a
    /// reference to it to use later, as the values may update, may not update, or
    /// may update to reflect an entirely unrelated scrollable.
    ///
    /// ## Examples
    ///
    /// [BouncingScrollPhysics] returns zero. In other words, it allows scrolling
    /// past the boundary unhindered.
    ///
    /// [ClampingScrollPhysics] returns the amount by which the value is beyond
    /// the position or the boundary, whichever is furthest from the content. In
    /// other words, it disallows scrolling past the boundary, but allows
    /// scrolling back from being overscrolled, if for some reason the position
    /// ends up overscrolled.
    public func applyBoundaryConditions(_ position: ScrollMetrics, _ value: Double) -> Double {
        return parent?.applyBoundaryConditions(position, value) ?? 0.0
    }

    /// Describes what the scroll position should be given new viewport dimensions.
    ///
    /// This is called by [ScrollPosition.correctForNewDimensions].
    ///
    /// The arguments consist of the scroll metrics as they stood in the previous
    /// frame and the scroll metrics as they now stand after the last layout,
    /// including the position and minimum and maximum scroll extents; a flag
    /// indicating if the current [ScrollActivity] considers that the user is
    /// actively scrolling (see [ScrollActivity.isScrolling]); and the current
    /// velocity of the scroll position, if it is being driven by the scroll
    /// activity (this is 0.0 during a user gesture) (see
    /// [ScrollActivity.velocity]).
    ///
    /// The scroll metrics will be identical except for the
    /// [ScrollMetrics.minScrollExtent] and [ScrollMetrics.maxScrollExtent]. They
    /// are referred to as the `oldPosition` and `newPosition` (even though they
    /// both technically have the same "position", in the form of
    /// [ScrollMetrics.pixels]) because they are generated from the
    /// [ScrollPosition] before and after updating the scroll extents.
    ///
    /// If the returned value does not exactly match the scroll offset given by
    /// the `newPosition` argument (see [ScrollMetrics.pixels]), then the
    /// [ScrollPosition] will call [ScrollPosition.correctPixels] to update the
    /// new scroll position to the returned value, and layout will be re-run. This
    /// is expensive. The new value is subject to further manipulation by
    /// [applyBoundaryConditions].
    ///
    /// If the returned value _does_ match the `newPosition.pixels` scroll offset
    /// exactly, then [ScrollPosition.applyNewDimensions] will be called next. In
    /// that case, [applyBoundaryConditions] is not applied to the return value.
    ///
    /// The given [ScrollMetrics] are only valid during this method call. Do not
    /// keep references to them to use later, as the values may update, may not
    /// update, or may update to reflect an entirely unrelated scrollable.
    ///
    /// The default implementation returns the [ScrollMetrics.pixels] of the
    /// `newPosition`, which indicates that the current scroll offset is
    /// acceptable.
    ///
    /// See also:
    ///
    ///  * [RangeMaintainingScrollPhysics], which is enabled by default, and
    ///    which prevents unexpected changes to the content dimensions from
    ///    causing the scroll position to get any further out of bounds.
    public func adjustPositionForNewDimensions(
        oldPosition: ScrollMetrics,
        newPosition: ScrollMetrics,
        isScrolling: Bool,
        velocity: Double
    ) -> Float {
        if parent == nil {
            return newPosition.pixels
        }
        return parent!.adjustPositionForNewDimensions(
            oldPosition: oldPosition,
            newPosition: newPosition,
            isScrolling: isScrolling,
            velocity: velocity
        )
    }

    /// Returns a simulation for ballistic scrolling starting from the given
    /// position with the given velocity.
    ///
    /// This is used by [ScrollPositionWithSingleContext] in the
    /// [ScrollPositionWithSingleContext.goBallistic] method. If the result
    /// is non-null, [ScrollPositionWithSingleContext] will begin a
    /// [BallisticScrollActivity] with the returned value. Otherwise, it will
    /// begin an idle activity instead.
    ///
    /// The given `position` is only valid during this method call. Do not keep a
    /// reference to it to use later, as the values may update, may not update, or
    /// may update to reflect an entirely unrelated scrollable.
    ///
    /// This method can potentially be called in every frame, even in the middle
    /// of what the user perceives as a single ballistic scroll.  For example, in
    /// a [ListView] when previously off-screen items come into view and are laid
    /// out, this method may be called with a new [ScrollMetrics.maxScrollExtent].
    /// The method implementation should ensure that when the same ballistic
    /// scroll motion is still intended, these calls have no side effects on the
    /// physics beyond continuing that motion.
    ///
    /// Generally this is ensured by having the [Simulation] conform to a physical
    /// metaphor of a particle in ballistic flight, where the forces on the
    /// particle depend only on its position, velocity, and environment, and not
    /// on the current time or any internal state.  This means that the
    /// time-derivative of [Simulation.dx] should be possible to write
    /// mathematically as a function purely of the values of [Simulation.x],
    /// [Simulation.dx], and the parameters used to construct the [Simulation],
    /// independent of the time.
    // TODO(gnprice): Some scroll physics in the framework violate that invariant; fix them.
    //   An audit found three cases violating the invariant:
    //     https://github.com/flutter/flutter/issues/120338
    //     https://github.com/flutter/flutter/issues/120340
    //     https://github.com/flutter/flutter/issues/109675
    public func createBallisticSimulation(_ position: ScrollMetrics, _ velocity: Double)
        -> Simulation?
    {
        return parent?.createBallisticSimulation(position, velocity)
    }

    private static let _kDefaultSpring = SpringDescription.withDampingRatio(
        mass: 0.5,
        stiffness: 100.0,
        ratio: 1.1
    )

    /// The spring to use for ballistic simulations.
    public var spring: SpringDescription {
        return parent?.spring ?? Self._kDefaultSpring
    }

    /// The tolerance to use for ballistic simulations.
    public func toleranceFor(_ metrics: ScrollMetrics) -> Tolerance {
        return parent?.toleranceFor(metrics)
            ?? Tolerance(
                distance: 1.0 / Double(metrics.devicePixelRatio),  // logical pixels
                velocity: 1.0 / (0.050 * Double(metrics.devicePixelRatio))  // logical pixels per second
            )
    }

    /// The minimum distance an input pointer drag must have moved to be
    /// considered a scroll fling gesture.
    ///
    /// This value is typically compared with the distance traveled along the
    /// scrolling axis.
    ///
    /// See also:
    ///
    ///  * [VelocityTracker.getVelocityEstimate], which computes the velocity
    ///    of a press-drag-release gesture.
    public var minFlingDistance: Float {
        return parent?.minFlingDistance ?? kTouchSlop
    }

    /// The minimum velocity for an input pointer drag to be considered a
    /// scroll fling.
    ///
    /// This value is typically compared with the magnitude of fling gesture's
    /// velocity along the scrolling axis.
    ///
    /// See also:
    ///
    ///  * [VelocityTracker.getVelocityEstimate], which computes the velocity
    ///    of a press-drag-release gesture.
    public var minFlingVelocity: Float {
        return parent?.minFlingVelocity ?? kMinFlingVelocity
    }

    /// Scroll fling velocity magnitudes will be clamped to this value.
    public var maxFlingVelocity: Float {
        return parent?.maxFlingVelocity ?? kMaxFlingVelocity
    }

    /// Returns the velocity carried on repeated flings.
    ///
    /// The function is applied to the existing scroll velocity when another
    /// scroll drag is applied in the same direction.
    ///
    /// By default, physics for platforms other than iOS doesn't carry momentum.
    public func carriedMomentum(_ existingVelocity: Double) -> Double {
        return parent?.carriedMomentum(existingVelocity) ?? 0.0
    }

    /// The minimum amount of pixel distance drags must move by to start motion
    /// the first time or after each time the drag motion stopped.
    ///
    /// If null, no minimum threshold is enforced.
    public var dragStartDistanceMotionThreshold: Double? {
        return parent?.dragStartDistanceMotionThreshold
    }

    /// Whether a viewport is allowed to change its scroll position implicitly in
    /// response to a call to [RenderObject.showOnScreen].
    ///
    /// [RenderObject.showOnScreen] is for example used to bring a text field
    /// fully on screen after it has received focus. This property controls
    /// whether the viewport associated with this object is allowed to change the
    /// scroll position to fulfill such a request.
    public var allowImplicitScrolling: Bool { true }

    /// Whether a viewport is allowed to change the scroll position as the result of user input.
    public var allowUserScrolling: Bool { true }
}

/// Scroll physics that always lets the user scroll.
///
/// This overrides the default behavior which is to disable scrolling
/// when there is no content to scroll. It does not override the
/// handling of overscrolling.
///
/// On Android, overscrolls will be clamped by default and result in an
/// overscroll glow. On iOS, overscrolls will load a spring that will return the
/// scroll view to its normal range when released.
///
/// See also:
///
///  * [ScrollPhysics], which can be used instead of this class when the default
///    behavior is desired instead.
///  * [BouncingScrollPhysics], which provides the bouncing overscroll behavior
///    found on iOS.
///  * [ClampingScrollPhysics], which provides the clamping overscroll behavior
///    found on Android.
public class AlwaysScrollableScrollPhysics: ScrollPhysics {

    public override func applyTo(_ ancestor: ScrollPhysics?) -> ScrollPhysics {
        return AlwaysScrollableScrollPhysics(parent: buildParent(ancestor))
    }

    public override func shouldAcceptUserOffset(_ position: ScrollMetrics) -> Bool {
        return true
    }
}
