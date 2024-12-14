// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// Signature for when a [ScrollController] has added or removed a
/// [ScrollPosition].
///
/// Since a [ScrollPosition] is not created and attached to a controller until
/// the [Scrollable] is built, this can be used to respond to the position being
/// attached to a controller.
///
/// By having access to the position directly, additional listeners can be
/// applied to aspects of the scroll position, like
/// [ScrollPosition.isScrollingNotifier].
///
/// Used by [ScrollController.onAttach] and [ScrollController.onDetach].
public typealias ScrollControllerCallback = (ScrollPosition) -> Void

/// Controls a scrollable widget.
///
/// Scroll controllers are typically stored as member variables in [State]
/// objects and are reused in each [State.build]. A single scroll controller can
/// be used to control multiple scrollable widgets, but some operations, such
/// as reading the scroll [offset], require the controller to be used with a
/// single scrollable widget.
///
/// A scroll controller creates a [ScrollPosition] to manage the state specific
/// to an individual [Scrollable] widget. To use a custom [ScrollPosition],
/// subclass [ScrollController] and override [createScrollPosition].
open class ScrollController: ChangeNotifier {
    public init(
        initialScrollOffset: Float = 0,
        keepScrollOffset: Bool = true,
        onAttach: ScrollControllerCallback? = nil,
        onDetach: ScrollControllerCallback? = nil,
        debugLabel: String? = nil
    ) {
        self.initialScrollOffset = initialScrollOffset
        self.keepScrollOffset = keepScrollOffset
        self.onAttach = onAttach
        self.onDetach = onDetach
        self.debugLabel = debugLabel
    }

    /// The initial value to use for [offset].
    ///
    /// New [ScrollPosition] objects that are created and attached to this
    /// controller will have their offset initialized to this value
    /// if [keepScrollOffset] is false or a scroll offset hasn't been saved yet.
    ///
    /// Defaults to 0.0.
    public let initialScrollOffset: Float

    /// Each time a scroll completes, save the current scroll [offset] with
    /// [PageStorage] and restore it if this controller's scrollable is recreated.
    ///
    /// If this property is set to false, the scroll offset is never saved
    /// and [initialScrollOffset] is always used to initialize the scroll
    /// offset. If true (the default), the initial scroll offset is used the
    /// first time the controller's scrollable is created, since there's no
    /// scroll offset to restore yet. Subsequently the saved offset is
    /// restored and [initialScrollOffset] is ignored.
    ///
    /// See also:
    ///
    ///  * [PageStorageKey], which should be used when more than one
    ///    scrollable appears in the same route, to distinguish the [PageStorage]
    ///    locations used to save scroll offsets.
    public let keepScrollOffset: Bool

    /// Called when a [ScrollPosition] is attached to the scroll controller.
    ///
    /// Since a scroll position is not attached until a [Scrollable] is actually
    /// built, this can be used to respond to a new position being attached.
    ///
    /// At the time that a scroll position is attached, the [ScrollMetrics], such as
    /// the [ScrollMetrics.maxScrollExtent], are not yet available. These are not
    /// determined until the [Scrollable] has finished laying out its contents and
    /// computing things like the full extent of that content.
    /// [ScrollPosition.hasContentDimensions] can be used to know when the
    /// metrics are available, or a [ScrollMetricsNotification] can be used,
    /// discussed further below.
    public let onAttach: ScrollControllerCallback?

    /// Called when a [ScrollPosition] is detached from the scroll controller.
    ///
    /// This is used to change the [AppBar]'s color when scrolling is occurring.
    public let onDetach: ScrollControllerCallback?

    /// A label that is used in the [toString] output. Intended to aid with
    /// identifying scroll controller instances in debug output.
    public let debugLabel: String?

    /// Whether any [ScrollPosition] objects have attached themselves to the
    /// [ScrollController] using the [attach] method.
    ///
    /// If this is false, then members that interact with the [ScrollPosition],
    /// such as [position], [offset], [animateTo], and [jumpTo], must not be
    /// called.
    public var hasClients: Bool {
        return !positions.isEmpty
    }

    /// Returns the attached [ScrollPosition], from which the actual scroll
    /// offset of the [ScrollView] can be obtained.
    ///
    /// Calling this is only valid when only a single position is attached.
    public var position: ScrollPosition! {
        assert(!positions.isEmpty, "ScrollController not attached to any scroll views.")
        assert(positions.count == 1, "ScrollController attached to multiple scroll views.")
        return positions.first
    }

    /// The current scroll offset of the scrollable widget.
    ///
    /// Requires the controller to be controlling exactly one scrollable widget.
    public var offset: Float! {
        return position?.pixels ?? 0
    }

    /// The currently attached positions.
    ///
    /// This should not be mutated directly. [ScrollPosition] objects can be added
    /// and removed using [attach] and [detach].
    public private(set) var positions = [ScrollPosition]()

    /// Register the given position with this controller.
    ///
    /// After this function returns, the [animateTo] and [jumpTo] methods on
    /// this controller will manipulate the given position.
    public func attach(_ position: ScrollPosition) {
        assert(!positions.contains(object: position))
        positions.append(position)
        position.addListener(self) { [weak self] in
            self?.notifyListeners()
        }
        if let onAttach {
            onAttach(position)
        }
    }

    /// Unregister the given position with this controller.
    ///
    /// After this function returns, the [animateTo] and [jumpTo] methods on
    /// this controller will not manipulate the given position.
    public func detach(_ position: ScrollPosition) {
        assert(positions.contains(object: position))
        if let onDetach = onDetach {
            onDetach(position)
        }
        position.removeListener(self)
        positions.remove(object: position)
    }

    public override func dispose() {
        for position in positions {
            position.removeListener(self)
        }
        super.dispose()
    }

    /// Creates a [ScrollPosition] for use by a [Scrollable] widget.
    ///
    /// Subclasses can override this function to customize the [ScrollPosition]
    /// used by the scrollable widgets they control. For example,
    /// [PageController] overrides this function to return a page-oriented
    /// scroll position subclass that keeps the same page visible when the
    /// scrollable widget resizes.
    ///
    /// By default, returns a [ScrollPositionWithSingleContext].
    ///
    /// The arguments are generally passed to the [ScrollPosition] being
    /// created:
    ///
    ///  * `physics`: An instance of [ScrollPhysics] that determines how the
    ///    [ScrollPosition] should react to user interactions, how it should
    ///    simulate scrolling when released or flung, etc. The value will not be
    ///    null. It typically comes from the [ScrollView] or other widget that
    ///    creates the [Scrollable], or, if none was provided, from the ambient
    ///    [ScrollConfiguration].
    ///  * `context`: A [ScrollContext] used for communicating with the object
    ///    that is to own the [ScrollPosition] (typically, this is the
    ///    [Scrollable] itself).
    ///  * `oldPosition`: If this is not the first time a [ScrollPosition] has
    ///    been created for this [Scrollable], this will be the previous
    ///    instance. This is used when the environment has changed and the
    ///    [Scrollable] needs to recreate the [ScrollPosition] object. It is
    ///    null the first time the [ScrollPosition] is created.
    open func createScrollPosition(
        physics: ScrollPhysics,
        context: ScrollContext,
        oldPosition: ScrollPosition?
    ) -> ScrollPosition {
        return ScrollPositionWithSingleContext(
            physics: physics,
            context: context,
            initialPixels: initialScrollOffset,
            keepScrollOffset: keepScrollOffset,
            oldPosition: oldPosition,
            debugLabel: debugLabel
        )
    }
}
