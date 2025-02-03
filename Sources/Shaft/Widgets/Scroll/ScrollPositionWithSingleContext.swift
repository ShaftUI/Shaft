// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A scroll position that manages scroll activities for a single
/// [ScrollContext].
///
/// This class is a concrete subclass of [ScrollPosition] logic that handles a
/// single [ScrollContext], such as a [Scrollable]. An instance of this class
/// manages [ScrollActivity] instances, which change what content is visible in
/// the [Scrollable]'s [Viewport].
public class ScrollPositionWithSingleContext: ScrollPosition {
    public init(
        physics: ScrollPhysics,
        context: ScrollContext,
        initialPixels: Float? = 0.0,
        keepScrollOffset: Bool = true,
        oldPosition: ScrollPosition? = nil,
        debugLabel: String? = nil
    ) {
        super.init(
            physics: physics,
            context: context,
            keepScrollOffset: keepScrollOffset,
            oldPosition: oldPosition,
            debugLabel: debugLabel
        )
        // If oldPosition is not null, the superclass will first call absorb(),
        // which may set _pixels and _activity.
        if !hasPixels, let initialPixels {
            correctPixels(initialPixels)
        }
        // if activity == nil {
        //     goIdle()
        // }
    }

    public func goIdle() {
        // beginActivity(IdleScrollActivity(self))
    }

    /// Start a physics-driven simulation that settles the [pixels] position,
    /// starting at a particular velocity.
    ///
    /// This method defers to [ScrollPhysics.createBallisticSimulation], which
    /// typically provides a bounce simulation when the current position is out of
    /// bounds and a friction simulation when the position is in bounds but has a
    /// non-zero velocity.
    ///
    /// The velocity should be in logical pixels per second.
    public func goBallistic(_ velocity: Float) {
        assert(hasPixels)
        // let simulation = physics.createBallisticSimulation(self, velocity)
        // if simulation != nil {
        //     beginActivity(BallisticScrollActivity(
        //         self,
        //         simulation,
        //         context.vsync,
        //         activity?.shouldIgnorePointer ?? true
        //     ))
        // } else {
        //     goIdle()
        // }
    }

    private var _userScrollDirection: ScrollDirection = .idle
    public override var userScrollDirection: ScrollDirection {
        _userScrollDirection
    }

    /// Set [userScrollDirection] to the given value.
    ///
    /// If this changes the value, then a [UserScrollNotification] is dispatched.
    public func updateUserScrollDirection(_ value: ScrollDirection) {
        if userScrollDirection == value {
            return
        }
        _userScrollDirection = value
        // didUpdateScrollDirection(value)
    }

    public override func jumpTo(_ value: Float) {
        goIdle()
        if pixels != value {
            // let oldPixels = pixels
            forcePixels(value)
            // didStartScroll()
            // didUpdateScrollPositionBy(pixels - oldPixels)
            // didEndScroll()
        }
        goBallistic(0.0)
    }

    public override func pointerScroll(_ delta: Float) {
        // If an update is made to pointer scrolling here, consider if the same
        // (or similar) change should be made in
        // _NestedScrollCoordinator.pointerScroll.
        if delta == 0.0 {
            goBallistic(0.0)
            return
        }

        let targetPixels = (pixels! + delta).clamped(to: minScrollExtent...maxScrollExtent)

        if targetPixels != pixels {
            //   goIdle();
            updateUserScrollDirection(
                -delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse
            )
            //   final double oldPixels = pixels;
            //   // Set the notifier before calling force pixels.
            //   // This is set to false again after going ballistic below.
            //   isScrollingNotifier.value = true;
            forcePixels(targetPixels)
            //   didStartScroll();
            //   didUpdateScrollPositionBy(pixels - oldPixels);
            //   didEndScroll();
            //   goBallistic(0.0);
        }
    }

    public override var axisDirection: AxisDirection {
        context.axisDirection
    }
}
