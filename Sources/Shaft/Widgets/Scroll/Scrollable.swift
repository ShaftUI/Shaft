// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Signature used by [Scrollable] to build the viewport through which the
/// scrollable content is displayed.
public typealias ViewportBuilder = (BuildContext, ViewportOffset) -> Widget

/// A widget that manages scrolling in one dimension and informs the [Viewport]
/// through which the content is viewed.
///
/// [Scrollable] implements the interaction model for a scrollable widget,
/// including gesture recognition, but does not have an opinion about how the
/// viewport, which actually displays the children, is constructed.
///
/// It's rare to construct a [Scrollable] directly. Instead, consider [ListView]
/// or [GridView], which combine scrolling, viewporting, and a layout model. To
/// combine layout models (or to use a custom layout mode), consider using
/// [CustomScrollView].
///
/// The static [Scrollable.of] and [Scrollable.ensureVisible] functions are
/// often used to interact with the [Scrollable] widget inside a [ListView] or
/// a [GridView].
///
/// To further customize scrolling behavior with a [Scrollable]:
///
/// 1. You can provide a [viewportBuilder] to customize the child model. For
///    example, [SingleChildScrollView] uses a viewport that displays a single
///    box child whereas [CustomScrollView] uses a [Viewport] or a
///    [ShrinkWrappingViewport], both of which display a list of slivers.
///
/// 2. You can provide a custom [ScrollController] that creates a custom
///    [ScrollPosition] subclass. For example, [PageView] uses a
///    [PageController], which creates a page-oriented scroll position subclass
///    that keeps the same page visible when the [Scrollable] resizes.
///
/// ## Persisting the scroll position during a session
///
/// Scrollables attempt to persist their scroll position using [PageStorage].
/// This can be disabled by setting [ScrollController.keepScrollOffset] to false
/// on the [controller]. If it is enabled, using a [PageStorageKey] for the
/// [key] of this widget (or one of its ancestors, e.g. a [ScrollView]) is
/// recommended to help disambiguate different [Scrollable]s from each other.
public final class Scrollable: StatefulWidget {
    public init(
        axisDirection: AxisDirection = .down,
        controller: ScrollController? = nil,
        physics: ScrollPhysics? = nil,
        excludeFromSemantics: Bool = false,
        semanticChildCount: Int? = nil,
        dragStartBehavior: DragStartBehavior = .start,
        restorationId: String? = nil,
        scrollBehavior: ScrollBehavior? = nil,
        clipBehavior: Clip = .hardEdge,
        viewportBuilder: @escaping ViewportBuilder
    ) {
        self.axisDirection = axisDirection
        self.controller = controller
        self.physics = physics
        self.viewportBuilder = viewportBuilder
        self.excludeFromSemantics = excludeFromSemantics
        self.semanticChildCount = semanticChildCount
        self.dragStartBehavior = dragStartBehavior
        self.restorationId = restorationId
        self.scrollBehavior = scrollBehavior
        self.clipBehavior = clipBehavior
    }

    /// The direction in which this widget scrolls.
    ///
    /// For example, if the [Scrollable.axisDirection] is [AxisDirection.down],
    /// increasing the scroll position will cause content below the bottom of the
    /// viewport to become visible through the viewport. Similarly, if the
    /// axisDirection is [AxisDirection.right], increasing the scroll position
    /// will cause content beyond the right edge of the viewport to become visible
    /// through the viewport.
    ///
    /// Defaults to [AxisDirection.down].
    public let axisDirection: AxisDirection

    /// An object that can be used to control the position to which this widget is
    /// scrolled.
    ///
    /// A [ScrollController] serves several purposes. It can be used to control
    /// the initial scroll position (see [ScrollController.initialScrollOffset]).
    /// It can be used to control whether the scroll view should automatically
    /// save and restore its scroll position in the [PageStorage] (see
    /// [ScrollController.keepScrollOffset]). It can be used to read the current
    /// scroll position (see [ScrollController.offset]), or change it (see
    /// [ScrollController.animateTo]).
    ///
    /// If nil, a [ScrollController] will be created internally by [Scrollable]
    /// in order to create and manage the [ScrollPosition].
    ///
    /// See also:
    ///
    ///  * [Scrollable.ensureVisible], which animates the scroll position to
    ///    reveal a given [BuildContext].
    public let controller: ScrollController?

    /// How the widgets should respond to user input.
    ///
    /// For example, determines how the widget continues to animate after the
    /// user stops dragging the scroll view.
    ///
    /// Defaults to matching platform conventions via the physics provided from
    /// the ambient [ScrollConfiguration].
    ///
    /// If an explicit [ScrollBehavior] is provided to
    /// [Scrollable.scrollBehavior], the [ScrollPhysics] provided by that behavior
    /// will take precedence after [Scrollable.physics].
    ///
    /// The physics can be changed dynamically, but new physics will only take
    /// effect if the _class_ of the provided object changes. Merely constructing
    /// a new instance with a different configuration is insufficient to cause the
    /// physics to be reapplied. (This is because the final object used is
    /// generated dynamically, which can be relatively expensive, and it would be
    /// inefficient to speculatively create this object each frame to see if the
    /// physics should be updated.)
    ///
    /// See also:
    ///
    ///  * [AlwaysScrollableScrollPhysics], which can be used to indicate that the
    ///    scrollable should react to scroll requests (and possible overscroll)
    ///    even if the scrollable's contents fit without scrolling being necessary.
    public let physics: ScrollPhysics?

    /// Builds the viewport through which the scrollable content is displayed.
    ///
    /// A typical viewport uses the given [ViewportOffset] to determine which part
    /// of its content is actually visible through the viewport.
    ///
    /// See also:
    ///
    ///  * [Viewport], which is a viewport that displays a list of slivers.
    ///  * [ShrinkWrappingViewport], which is a viewport that displays a list of
    ///    slivers and sizes itself based on the size of the slivers.
    public let viewportBuilder: ViewportBuilder

    /// An optional function that will be called to calculate the distance to
    /// scroll when the scrollable is asked to scroll via the keyboard using a
    /// [ScrollAction].
    ///
    /// If not supplied, the [Scrollable] will scroll a default amount when a
    /// keyboard navigation key is pressed (e.g. pageUp/pageDown, control-upArrow,
    /// etc.), or otherwise invoked by a [ScrollAction].
    ///
    /// If [incrementCalculator] is nil, the default for
    /// [ScrollIncrementType.page] is 80% of the size of the scroll window, and
    /// for [ScrollIncrementType.line], 50 logical pixels.
    // public let incrementCalculator: ScrollIncrementCalculator?

    /// Whether the scroll actions introduced by this [Scrollable] are exposed
    /// in the semantics tree.
    ///
    /// Text fields with an overflow are usually scrollable to make sure that the
    /// user can get to the beginning/end of the entered text. However, these
    /// scrolling actions are generally not exposed to the semantics layer.
    ///
    /// See also:
    ///
    ///  * [GestureDetector.excludeFromSemantics], which is used to accomplish the
    ///    exclusion.
    public let excludeFromSemantics: Bool

    /// The number of children that will contribute semantic information.
    ///
    /// The value will be nil if the number of children is unknown or unbounded.
    ///
    /// Some subtypes of [ScrollView] can infer this value automatically. For
    /// example [ListView] will use the number of widgets in the child list,
    /// while the [ListView.separated] constructor will use half that amount.
    ///
    /// For [CustomScrollView] and other types which do not receive a builder
    /// or list of widgets, the child count must be explicitly provided.
    ///
    /// See also:
    ///
    ///  * [CustomScrollView], for an explanation of scroll semantics.
    ///  * [SemanticsConfiguration.scrollChildCount], the corresponding semantics property.
    public let semanticChildCount: Int?

    // TODO(jslavitz): Set the DragStartBehavior default to be start across all widgets.
    /// Determines the way that drag start behavior is handled.
    ///
    /// If set to [DragStartBehavior.start], scrolling drag behavior will
    /// begin at the position where the drag gesture won the arena. If set to
    /// [DragStartBehavior.down] it will begin at the position where a down
    /// event is first detected.
    ///
    /// In general, setting this to [DragStartBehavior.start] will make drag
    /// animation smoother and setting it to [DragStartBehavior.down] will make
    /// drag behavior feel slightly more reactive.
    ///
    /// By default, the drag start behavior is [DragStartBehavior.start].
    ///
    /// See also:
    ///
    ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for
    ///    the different behaviors.
    public let dragStartBehavior: DragStartBehavior

    /// Restoration ID to save and restore the scroll offset of the scrollable.
    ///
    /// If a restoration id is provided, the scrollable will persist its current
    /// scroll offset and restore it during state restoration.
    ///
    /// The scroll offset is persisted in a [RestorationBucket] claimed from
    /// the surrounding [RestorationScope] using the provided restoration ID.
    ///
    /// See also:
    ///
    ///  * [RestorationManager], which explains how state restoration works in
    ///    Flutter.
    public let restorationId: String?

    /// [ScrollBehavior]s also provide [ScrollPhysics]. If an explicit
    /// [ScrollPhysics] is provided in [physics], it will take precedence,
    /// followed by [scrollBehavior], and then the inherited ancestor
    /// [ScrollBehavior].
    public let scrollBehavior: ScrollBehavior?

    /// Defaults to [Clip.hardEdge].
    ///
    /// This is passed to decorators in [ScrollableDetails], and does not directly affect
    /// clipping of the [Scrollable]. This reflects the same [Clip] that is provided
    /// to [ScrollView.clipBehavior] and is supplied to the [Viewport].
    public let clipBehavior: Clip

    public func createState() -> State<Scrollable> {
        ScrollableState()
    }

    /// The state from the closest instance of this class that encloses the given
    /// context, or nil if none is found.
    ///
    /// Typical usage is as follows:
    ///
    /// ```swift
    /// let scrollable = Scrollable.maybeOf(context)
    /// ```
    ///
    /// Calling this method will create a dependency on the [ScrollableState]
    /// that is returned, if there is one. This is typically the closest
    /// [Scrollable], but may be a more distant ancestor if [axis] is used to
    /// target a specific [Scrollable].
    ///
    /// Using the optional [Axis] is useful when Scrollables are nested and the
    /// target [Scrollable] is not the closest instance. When [axis] is provided,
    /// the nearest enclosing [ScrollableState] in that [Axis] is returned, or
    /// nil if there is none.
    ///
    /// This finds the nearest _ancestor_ [Scrollable] of the `context`. This
    /// means that if the `context` is that of a [Scrollable], it will _not_ find
    /// _that_ [Scrollable].
    ///
    /// See also:
    ///
    /// * [Scrollable.of], which is similar to this method, but asserts
    ///   if no [Scrollable] ancestor is found.
    static func maybeOf(_ context: BuildContext, axis: Axis? = nil) -> ScrollableState? {
        // This is the context that will need to establish the dependency.
        var context = context
        let originalContext = context
        var element = context.getElementForInheritedWidgetOfExactType(ScrollableScope.self)
        while let currentElement = element {
            let scrollable = (currentElement.widget as! ScrollableScope).scrollable
            if axis == nil || scrollable.axisDirection.axis == axis {
                // Establish the dependency on the correct context.
                _ = originalContext.dependOnInheritedElement(currentElement)
                return scrollable
            }
            context = scrollable.context
            element = context.getElementForInheritedWidgetOfExactType(ScrollableScope.self)
        }
        return nil
    }
}

// Enable Scrollable.of() to work as if ScrollableState was an inherited widget.
// ScrollableState.build() always rebuilds its ScrollableScope.
private class ScrollableScope: InheritedWidget {
    init(
        scrollable: ScrollableState,
        position: ScrollPosition,
        @WidgetBuilder child: () -> Widget
    ) {
        self.scrollable = scrollable
        self.position = position
        self.child = child()
    }

    let scrollable: ScrollableState
    let position: ScrollPosition
    let child: Widget

    func updateShouldNotify(_ oldWidget: ScrollableScope) -> Bool {
        return position !== oldWidget.position
    }
}

public final class ScrollableState: State<Scrollable>, ScrollContext {
    public private(set) var position: ScrollPosition!

    public var axisDirection: AxisDirection {
        widget.axisDirection
    }

    public var devicePixelRatio: Float { 2 }

    private var fallbackScrollController: ScrollController?

    private var effectiveScrollController: ScrollController {
        widget.controller ?? fallbackScrollController!
    }

    private var configuration: ScrollBehavior!

    // Only call this from places that will definitely trigger a rebuild.
    private func updatePosition() {
        configuration = widget.scrollBehavior ?? ScrollConfiguration.of(context)
        let physics = ScrollPhysics()
        // physics = configuration.getScrollPhysics(context)
        // if let physics = widget.physics {
        //     physics.applyTo(physics)
        // } else if let scrollBehavior = widget.scrollBehavior {
        //     scrollBehavior.getScrollPhysics(context).applyTo(physics)
        // }
        let oldPosition = position
        if let oldPosition {
            effectiveScrollController.detach(oldPosition)
            // It's important that we not dispose the old position until after the
            // viewport has had a chance to unregister its listeners from the old
            // position. So, schedule a microtask to do it.
            // scheduleMicrotask(oldPosition.dispose)
        }
        position = effectiveScrollController.createScrollPosition(
            physics: physics,
            context: self,
            oldPosition: oldPosition
        )
        assert(position != nil)
        effectiveScrollController.attach(position!)
    }

    private func receivedPointerSignal(event: PointerSignalEvent) {
        if let event = event as? PointerScrollEvent, let position = position {
            if let physics = widget.physics, !physics.shouldAcceptUserOffset(position) {
                return
            }
            let delta = pointerSignalEventDelta(event: event)
            let targetScrollOffset = targetScrollOffsetForPointerScroll(delta)
            if delta != 0.0 && targetScrollOffset != position.pixels {
                GestureBinding.shared.pointerSignalResolver.register(event, handlePointerScroll)
            }
        } else if event is PointerScrollInertiaCancelEvent {
            position?.pointerScroll(0)
            // Don't use the pointer signal resolver, all hit-tested scrollables should stop.
        }
    }

    private func handlePointerScroll(event: PointerEvent) {
        assert(event is PointerScrollEvent)
        let delta = pointerSignalEventDelta(event: event as! PointerScrollEvent)
        let targetScrollOffset = targetScrollOffsetForPointerScroll(delta)
        if delta != 0.0 && targetScrollOffset != position?.pixels {
            position?.pointerScroll(delta)
        }
    }

    // Returns the delta that should result from applying [event] with axis,
    // direction, and any modifiers specified by the ScrollBehavior taken into
    // account.
    private func pointerSignalEventDelta(event: PointerScrollEvent) -> Float {
        var delta: Float
        // let pressed = HardwareKeyboard.instance.logicalKeysPressed
        // let flipAxes =
        //     pressed.contains(where: widget.scrollBehavior!.pointerAxisModifiers.contains)
        //     // Axes are only flipped for physical mouse wheel input.
        //     // On some platforms, like web, trackpad input is handled through pointer
        //     // signals, but should not be included in this axis modifying behavior.
        //     // This is because on a trackpad, all directional axes are available to
        //     // the user, while mouse scroll wheels typically are restricted to one
        //     // axis.
        //     && event.kind == .mouse
        let flipAxes = false  // TODO: implement
        switch widget.axisDirection.axis {
        case .horizontal:
            delta = flipAxes ? event.scrollDelta.dy : event.scrollDelta.dx
        case .vertical:
            delta = flipAxes ? event.scrollDelta.dx : event.scrollDelta.dy
        }
        if widget.axisDirection.isReversed {
            delta *= -1
        }
        return delta
    }

    // Returns the offset that should result from applying [event] to the current
    // position, taking min/max scroll extent into account.
    private func targetScrollOffsetForPointerScroll(_ delta: Float) -> Float {
        (position!.pixels + delta).clamped(
            to: position!.minScrollExtent...position!.maxScrollExtent
        )
    }

    public override func initState() {
        if widget.controller == nil {
            fallbackScrollController = ScrollController()
        }
        super.initState()
    }

    public override func didChangeDependencies() {
        // _mediaQueryGestureSettings = MediaQuery.maybeGestureSettingsOf(context)
        // _devicePixelRatio =
        //     MediaQuery.maybeDevicePixelRatioOf(context) ?? View.of(context).devicePixelRatio
        updatePosition()
        super.didChangeDependencies()
    }

    public override func didUpdateWidget(_ oldWidget: Scrollable) {
        super.didUpdateWidget(oldWidget)

        if widget.controller !== oldWidget.controller {
            if oldWidget.controller == nil {
                // The old controller was nil, meaning the fallback cannot be nil.
                // Dispose of the fallback.
                assert(fallbackScrollController != nil)
                assert(widget.controller != nil)
                fallbackScrollController!.detach(position)
                fallbackScrollController!.dispose()
                fallbackScrollController = nil
            } else {
                // The old controller was not nil, detach.
                oldWidget.controller?.detach(position)
                if widget.controller == nil {
                    // If the new controller is nil, we need to set up the fallback
                    // ScrollController.
                    fallbackScrollController = ScrollController()
                }
            }
            // Attach the updated effective scroll controller.
            effectiveScrollController.attach(position)
        }

        if shouldUpdatePosition(oldWidget: oldWidget) {
            updatePosition()
        }
    }

    private func shouldUpdatePosition(oldWidget: Scrollable) -> Bool {
        if (widget.scrollBehavior == nil) != (oldWidget.scrollBehavior == nil) {
            return true
        }
        if widget.scrollBehavior != nil && oldWidget.scrollBehavior != nil
            && widget.scrollBehavior!.shouldNotify(oldWidget.scrollBehavior!)
        {
            return true
        }
        // var newPhysics = widget.physics ?? widget.scrollBehavior?.getScrollPhysics(context)
        // var oldPhysics = oldWidget.physics ?? oldWidget.scrollBehavior?.getScrollPhysics(context)
        // while newPhysics != nil || oldPhysics != nil {
        //     if newPhysics?.runtimeType != oldPhysics?.runtimeType {
        //         return true
        //     }
        //     newPhysics = newPhysics?.parent
        //     oldPhysics = oldPhysics?.parent
        // }
        return type(of: widget.controller) != type(of: oldWidget.controller)
    }

    public override func build(context: BuildContext) -> Widget {
        // _ScrollableScope must be placed above the BuildContext returned by
        // notificationContext so that we can get this ScrollableState by doing
        // the following:
        //
        // ScrollNotification notification; Scrollable.of(notification.context)
        //
        // Since notificationContext is pointing to _gestureDetectorKey.context,
        // _ScrollableScope must be placed above the widget using it:
        // RawGestureDetector
        ScrollableScope(scrollable: self, position: position) {
            Listener(onPointerSignal: receivedPointerSignal) {
                RawGestureDetector(gestures: [], behavior: .opaque) {
                    widget.viewportBuilder(context, position!)
                }
            }
        }
    }
}
