// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
/// [ScrollPhysics] objects of different types to get the desired scroll
/// physics. For example:
///
/// ```swift
/// BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
/// ```
///
/// You can also use `applyTo`, which is useful when you already have an
/// instance of [ScrollPhysics]:
///
/// ```swift
/// let physics = BouncingScrollPhysics();
/// // ...
/// let mergedPhysics = physics.applyTo(const AlwaysScrollableScrollPhysics());
/// ```
///
/// When implementing a subclass, you must override [applyTo] so that it returns
/// an appropriate instance of your subclass.  Otherwise, classes like
/// [Scrollable] that inform a [ScrollPosition] will combine them with the
/// default [ScrollPhysics] object instead of your custom subclass.
public class ScrollPhysics {
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
    //   bool shouldAcceptUserOffset(ScrollMetrics position) {
    //     if (!allowUserScrolling) {
    //       return false;
    //     }

    //     if (parent == null) {
    //       return position.pixels != 0.0 || position.minScrollExtent != position.maxScrollExtent;
    //     }
    //     return parent!.shouldAcceptUserOffset(position);
    //   }
    public func shouldAcceptUserOffset(_ position: ScrollMetrics) -> Bool {
        return true

        // if !allowUserScrolling {
        //     return false
        // }
        // if parent == nil {
        //     return position.pixels != 0.0 || position.minScrollExtent != position.maxScrollExtent
        // }
        // return parent!.shouldAcceptUserOffset(position: position)
    }

    /// Whether a viewport is allowed to change its scroll position implicitly in
    /// response to a call to [RenderObject.showOnScreen].
    ///
    /// [RenderObject.showOnScreen] is for example used to bring a text field
    /// fully on screen after it has received focus. This property controls
    /// whether the viewport associated with this object is allowed to change the
    /// scroll position to fulfill such a request.
    //   bool get allowImplicitScrolling => true;
    public var allowImplicitScrolling: Bool { true }
}
