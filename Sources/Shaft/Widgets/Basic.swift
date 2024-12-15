// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A widget that paints its area with a specified [Color] and then draws its
/// child on top of that color.
public class ColoredBox: LeafRenderObjectWidget {
    public init(color: Color) {
        self.color = color
    }

    /// The color to paint the background area with.
    public let color: Color

    public func createRenderObject(context: BuildContext) -> RenderColoredBox {
        return RenderColoredBox(color: color)
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderColoredBox) {
        mark("updateRenderObject", renderObject)
        renderObject.color = color
    }
}

/// A widget that calls callbacks in response to common pointer events.
///
/// It listens to events that can construct gestures, such as when the
/// pointer is pressed, moved, then released or canceled.
///
/// It does not listen to events that are exclusive to mouse, such as when the
/// mouse enters, exits or hovers a region without pressing any buttons. For
/// these events, use [MouseRegion].
///
/// Rather than listening for raw pointer events, consider listening for
/// higher-level gestures using [GestureDetector].
public class Listener: SingleChildRenderObjectWidget {
    public init(
        onPointerDown: PointerDownEventListener? = nil,
        onPointerMove: PointerMoveEventListener? = nil,
        onPointerUp: PointerUpEventListener? = nil,
        onPointerCancel: PointerCancelEventListener? = nil,
        onPointerPanZoomStart: PointerPanZoomStartEventListener? = nil,
        onPointerPanZoomUpdate: PointerPanZoomUpdateEventListener? = nil,
        onPointerPanZoomEnd: PointerPanZoomEndEventListener? = nil,
        onPointerSignal: PointerSignalEventListener? = nil,
        behavior: HitTestBehavior = .deferToChild,
        @OptionalWidgetBuilder child: () -> Widget? = voidBuilder
    ) {
        self.onPointerDown = onPointerDown
        self.onPointerMove = onPointerMove
        self.onPointerUp = onPointerUp
        self.onPointerCancel = onPointerCancel
        self.onPointerPanZoomStart = onPointerPanZoomStart
        self.onPointerPanZoomUpdate = onPointerPanZoomUpdate
        self.onPointerPanZoomEnd = onPointerPanZoomEnd
        self.onPointerSignal = onPointerSignal
        self.behavior = behavior
        self.child = child()
    }

    public var onPointerDown: PointerDownEventListener?
    public var onPointerMove: PointerMoveEventListener?
    public var onPointerUp: PointerUpEventListener?
    public var onPointerCancel: PointerCancelEventListener?
    public var onPointerPanZoomStart: PointerPanZoomStartEventListener?
    public var onPointerPanZoomUpdate: PointerPanZoomUpdateEventListener?
    public var onPointerPanZoomEnd: PointerPanZoomEndEventListener?
    public var onPointerSignal: PointerSignalEventListener?
    public var behavior: HitTestBehavior
    public var child: Widget?

    public func createRenderObject(context: BuildContext) -> RenderPointerListener {
        RenderPointerListener(
            onPointerDown: onPointerDown,
            onPointerMove: onPointerMove,
            onPointerUp: onPointerUp,
            onPointerCancel: onPointerCancel,
            onPointerPanZoomStart: onPointerPanZoomStart,
            onPointerPanZoomUpdate: onPointerPanZoomUpdate,
            onPointerPanZoomEnd: onPointerPanZoomEnd,
            onPointerSignal: onPointerSignal,
            behavior: behavior
        )
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderPointerListener) {
        renderObject.onPointerDown = onPointerDown
        renderObject.onPointerMove = onPointerMove
        renderObject.onPointerUp = onPointerUp
        renderObject.onPointerCancel = onPointerCancel
        renderObject.onPointerPanZoomStart = onPointerPanZoomStart
        renderObject.onPointerPanZoomUpdate = onPointerPanZoomUpdate
        renderObject.onPointerPanZoomEnd = onPointerPanZoomEnd
        renderObject.onPointerSignal = onPointerSignal
        renderObject.behavior = behavior
    }
}

/// A widget that tracks the movement of mice.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=1oF3pI5umck}
///
/// [MouseRegion] is used
/// when it is needed to compare the list of objects that a mouse pointer is
/// hovering over between this frame and the last frame. This means entering
/// events, exiting events, and mouse cursors.
///
/// To listen to general pointer events, use [Listener], or more preferably,
/// [GestureDetector].
///
/// ## Layout behavior
///
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// If it has a child, this widget defers to the child for sizing behavior. If
/// it does not have a child, it grows to fit the parent instead.
///
/// See also:
///
///  * [Listener], a similar widget that tracks pointer events when the pointer
///    has buttons pressed.
public class MouseRegion: SingleChildRenderObjectWidget {
    /// Creates a widget that forwards mouse events to callbacks.
    ///
    /// By default, all callbacks are empty, [cursor] is [MouseCursor.defer], and
    /// [opaque] is true.
    public init(
        onEnter: PointerEnterEventListener? = nil,
        onExit: PointerExitEventListener? = nil,
        onHover: PointerHoverEventListener? = nil,
        cursor: MouseCursor = .defer,
        opaque: Bool = true,
        hitTestBehavior: HitTestBehavior? = nil,
        @WidgetBuilder child: () -> Widget
    ) {
        self.onEnter = onEnter
        self.onExit = onExit
        self.onHover = onHover
        self.cursor = cursor
        self.opaque = opaque
        self.hitTestBehavior = hitTestBehavior
        self.child = child()
    }

    /// Triggered when a mouse pointer has entered this widget.
    ///
    /// This callback is triggered when the pointer, with or without buttons
    /// pressed, has started to be contained by the region of this widget. More
    /// specifically, the callback is triggered by the following cases:
    ///
    ///  * This widget has appeared under a pointer.
    ///  * This widget has moved to under a pointer.
    ///  * A new pointer has been added to somewhere within this widget.
    ///  * An existing pointer has moved into this widget.
    ///
    /// This callback is not always matched by an [onExit]. If the [MouseRegion]
    /// is unmounted while being hovered by a pointer, the [onExit] of the widget
    /// callback will never called. For more details, see [onExit].
    ///
    /// The time that this callback is triggered is always between frames: either
    /// during the post-frame callbacks, or during the callback of a pointer
    /// event.
    ///
    /// See also:
    ///
    ///  * [onExit], which is triggered when a mouse pointer exits the region.
    ///  * [MouseTrackerAnnotation.onEnter], which is how this callback is
    ///    internally implemented.
    public let onEnter: PointerEnterEventListener?

    /// Triggered when a pointer moves into a position within this widget without
    /// buttons pressed.
    ///
    /// Usually this is only fired for pointers which report their location when
    /// not down (e.g. mouse pointers). Certain devices also fire this event on
    /// single taps in accessibility mode.
    ///
    /// This callback is not triggered by the movement of the widget.
    ///
    /// The time that this callback is triggered is during the callback of a
    /// pointer event, which is always between frames.
    ///
    /// See also:
    ///
    ///  * [Listener.onPointerHover], which does the same job. Prefer using
    ///    [Listener.onPointerHover], since hover events are similar to other regular
    ///    events.
    public let onHover: PointerHoverEventListener?

    /// Triggered when a mouse pointer has exited this widget when the widget is
    /// still mounted.
    ///
    /// This callback is triggered when the pointer, with or without buttons
    /// pressed, has stopped being contained by the region of this widget, except
    /// when the exit is caused by the disappearance of this widget. More
    /// specifically, this callback is triggered by the following cases:
    ///
    ///  * A pointer that is hovering this widget has moved away.
    ///  * A pointer that is hovering this widget has been removed.
    ///  * This widget, which is being hovered by a pointer, has moved away.
    ///
    /// And is __not__ triggered by the following case:
    ///
    ///  * This widget, which is being hovered by a pointer, has disappeared.
    ///
    /// This means that a [MouseRegion.onExit] might not be matched by a
    /// [MouseRegion.onEnter].
    ///
    /// This restriction aims to prevent a common misuse: if [State.setState] is
    /// called during [MouseRegion.onExit] without checking whether the widget is
    /// still mounted, an exception will occur. This is because the callback is
    /// triggered during the post-frame phase, at which point the widget has been
    /// unmounted. Since [State.setState] is exclusive to widgets, the restriction
    /// is specific to [MouseRegion], and does not apply to its lower-level
    /// counterparts, [RenderMouseRegion] and [MouseTrackerAnnotation].
    ///
    /// There are a few ways to mitigate this restriction:
    ///
    ///  * If the hover state is completely contained within a widget that
    ///    unconditionally creates this [MouseRegion], then this will not be a
    ///    concern, since after the [MouseRegion] is unmounted the state is no
    ///    longer used.
    ///  * Otherwise, the outer widget very likely has access to the variable that
    ///    controls whether this [MouseRegion] is present. If so, call [onExit] at
    ///    the event that turns the condition from true to false.
    ///  * In cases where the solutions above won't work, you can always
    ///    override [State.dispose] and call [onExit], or create your own widget
    ///    using [RenderMouseRegion].
    ///
    /// See also:
    ///
    ///  * [onEnter], which is triggered when a mouse pointer enters the region.
    ///  * [RenderMouseRegion] and [MouseTrackerAnnotation.onExit], which are how
    ///    this callback is internally implemented, but without the restriction.
    public let onExit: PointerExitEventListener?

    /// The mouse cursor for mouse pointers that are hovering over the region.
    ///
    /// When a mouse enters the region, its cursor will be changed to the [cursor].
    /// When the mouse leaves the region, the cursor will be decided by the region
    /// found at the new location.
    ///
    /// The [cursor] defaults to [MouseCursor.defer], deferring the choice of
    /// cursor to the next region behind it in hit-test order.
    public let cursor: MouseCursor

    /// Whether this widget should prevent other [MouseRegion]s visually behind it
    /// from detecting the pointer.
    ///
    /// This changes the list of regions that a pointer hovers, thus affecting how
    /// their [onHover], [onEnter], [onExit], and [cursor] behave.
    ///
    /// If [opaque] is true, this widget will absorb the mouse pointer and
    /// prevent this widget's siblings (or any other widgets that are not
    /// ancestors or descendants of this widget) from detecting the mouse
    /// pointer even when the pointer is within their areas.
    ///
    /// If [opaque] is false, this object will not affect how [MouseRegion]s
    /// behind it behave, which will detect the mouse pointer as long as the
    /// pointer is within their areas.
    ///
    /// This defaults to true.
    public let opaque: Bool

    /// How to behave during hit testing.
    ///
    /// This defaults to [HitTestBehavior.opaque] if null.
    public let hitTestBehavior: HitTestBehavior?

    public var child: Widget?

    public func createRenderObject(context: BuildContext) -> RenderMouseRegion {
        RenderMouseRegion(
            onEnter: onEnter,
            onHover: onHover,
            onExit: onExit,
            cursor: cursor,
            opaque: opaque,
            hitTestBehavior: hitTestBehavior
        )
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderMouseRegion) {
        renderObject.onEnter = onEnter
        renderObject.onHover = onHover
        renderObject.onExit = onExit
        renderObject.cursor = cursor
        renderObject.opaque = opaque
        renderObject.hitTestBehavior = hitTestBehavior
    }
}

/// A widget that displays its children in a one-dimensional array.
///
/// The [Flex] widget allows you to control the axis along which the children are
/// placed (horizontal or vertical). This is referred to as the _main axis_. If
/// you know the main axis in advance, then consider using a [Row] (if it's
/// horizontal) or [Column] (if it's vertical) instead, because that will be less
/// verbose.
///
/// To cause a child to expand to fill the available space in the [direction]
/// of this widget's main axis, wrap the child in an [Expanded] widget.
///
/// The [Flex] widget does not scroll (and in general it is considered an error
/// to have more children in a [Flex] than will fit in the available room). If
/// you have some widgets and want them to be able to scroll if there is
/// insufficient room, consider using a [ListView].
///
/// The [Flex] widget does not allow its children to wrap across multiple
/// horizontal or vertical runs. For a widget that allows its children to wrap,
/// consider using the [Wrap] widget instead of [Flex].
///
/// If you only have one child, then rather than using [Flex], [Row], or
/// [Column], consider using [Align] or [Center] to position the child.
public class Flex: MultiChildRenderObjectWidget {
    public init(
        direction: Axis,
        mainAxisAlignment: MainAxisAlignment = .start,
        mainAxisSize: MainAxisSize = .max,
        crossAxisAlignment: CrossAxisAlignment = .center,
        textDirection: TextDirection? = nil,
        verticalDirection: VerticalDirection = .down,
        textBaseline: TextBaseline? = nil,
        clipBehavior: Clip = .none,
        @WidgetListBuilder children: () -> [Widget]
    ) {
        self.direction = direction
        self.mainAxisAlignment = mainAxisAlignment
        self.mainAxisSize = mainAxisSize
        self.crossAxisAlignment = crossAxisAlignment
        self.textDirection = textDirection
        self.verticalDirection = verticalDirection
        self.textBaseline = textBaseline
        self.clipBehavior = clipBehavior
        self.children = children()
    }

    /// The direction to use as the main axis.
    ///
    /// If you know the axis in advance, then consider using a [Row] (if it's
    /// horizontal) or [Column] (if it's vertical) instead of a [Flex], since that
    /// will be less verbose. (For [Row] and [Column] this property is fixed to
    /// the appropriate axis.)
    var direction: Axis

    /// How the children should be placed along the main axis.
    ///
    /// For example, [MainAxisAlignment.start], the default, places the children
    /// at the start (i.e., the left for a [Row] or the top for a [Column]) of the
    /// main axis.
    var mainAxisAlignment: MainAxisAlignment

    /// How much space should be occupied in the main axis.
    ///
    /// After allocating space to children, there might be some remaining free
    /// space. This value controls whether to maximize or minimize the amount of
    /// free space, subject to the incoming layout constraints.
    ///
    /// If some children have a non-zero flex factors (and none have a fit of
    /// [FlexFit.loose]), they will expand to consume all the available space and
    /// there will be no remaining free space to maximize or minimize, making this
    /// value irrelevant to the final layout.
    var mainAxisSize: MainAxisSize

    /// How the children should be placed along the cross axis.
    ///
    /// For example, [CrossAxisAlignment.center], the default, centers the
    /// children in the cross axis (e.g., horizontally for a [Column]).
    var crossAxisAlignment: CrossAxisAlignment

    /// Determines the order to lay children out horizontally and how to interpret
    /// `start` and `end` in the horizontal direction.
    ///
    /// Defaults to the ambient [Directionality].
    var textDirection: TextDirection?

    /// Determines the order to lay children out vertically and how to interpret
    /// `start` and `end` in the vertical direction.
    ///
    /// Defaults to [VerticalDirection.down].
    var verticalDirection: VerticalDirection

    /// If aligning items according to their baseline, which baseline to use.
    ///
    /// This must be set if using baseline alignment. There is no default because there is no
    /// way for the framework to know the correct baseline _a priori_.
    var textBaseline: TextBaseline?

    /// Defaults to [Clip.none].
    var clipBehavior: Clip

    public var children: [Widget]

    public func createRenderObject(context: BuildContext) -> RenderFlex {
        RenderFlex(
            direction: direction,
            mainAxisAlignment: mainAxisAlignment,
            mainAxisSize: mainAxisSize,
            crossAxisAlignment: crossAxisAlignment,
            textDirection: textDirection,
            verticalDirection: verticalDirection,
            textBaseline: textBaseline,
            clipBehavior: clipBehavior
        )
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderFlex) {
        renderObject.direction = direction
        renderObject.mainAxisAlignment = mainAxisAlignment
        renderObject.mainAxisSize = mainAxisSize
        renderObject.crossAxisAlignment = crossAxisAlignment
        renderObject.textDirection = textDirection
        renderObject.verticalDirection = verticalDirection
        renderObject.textBaseline = textBaseline
        renderObject.clipBehavior = clipBehavior
    }
}

/// A widget that displays its children in a horizontal array.
///
/// To cause a child to expand to fill the available horizontal space, wrap the
/// child in an [Expanded] widget.
///
/// The [Row] widget does not scroll (and in general it is considered an error
/// to have more children in a [Row] than will fit in the available room). If
/// you have a line of widgets and want them to be able to scroll if there is
/// insufficient room, consider using a [ListView].
///
/// For a vertical variant, see [Column].
///
/// If you only have one child, then consider using [Align] or [Center] to
/// position the child.
public class Row: Flex {
    public init(
        mainAxisAlignment: MainAxisAlignment = .start,
        mainAxisSize: MainAxisSize = .max,
        crossAxisAlignment: CrossAxisAlignment = .center,
        spacing: Float? = nil,
        textDirection: TextDirection? = nil,
        verticalDirection: VerticalDirection = .down,
        textBaseline: TextBaseline? = nil,
        clipBehavior: Clip = .none,
        @WidgetListBuilder children: () -> [Widget]
    ) {
        super.init(
            direction: .horizontal,
            mainAxisAlignment: mainAxisAlignment,
            mainAxisSize: mainAxisSize,
            crossAxisAlignment: crossAxisAlignment,
            textDirection: textDirection,
            verticalDirection: verticalDirection,
            textBaseline: textBaseline,
            clipBehavior: clipBehavior
        ) {
            if let spacing {
                children().separated(by: SizedBox(width: spacing))
            } else {
                children()
            }
        }
    }
}

/// A widget that displays its children in a vertical array.
///
/// To cause a child to expand to fill the available vertical space, wrap the
/// child in an [Expanded] widget.
///
/// The [Column] widget does not scroll (and in general it is considered an error
/// to have more children in a [Column] than will fit in the available room). If
/// you have a line of widgets and want them to be able to scroll if there is
/// insufficient room, consider using a [ListView].
///
/// For a horizontal variant, see [Row].
///
/// If you only have one child, then consider using [Align] or [Center] to
/// position the child.
public class Column: Flex {
    public init(
        mainAxisAlignment: MainAxisAlignment = .start,
        mainAxisSize: MainAxisSize = .max,
        crossAxisAlignment: CrossAxisAlignment = .center,
        spacing: Float? = nil,
        textDirection: TextDirection? = .ltr,
        verticalDirection: VerticalDirection = .down,
        textBaseline: TextBaseline? = nil,
        clipBehavior: Clip = .none,
        @WidgetListBuilder children: () -> [Widget]
    ) {
        super.init(
            direction: .vertical,
            mainAxisAlignment: mainAxisAlignment,
            mainAxisSize: mainAxisSize,
            crossAxisAlignment: crossAxisAlignment,
            textDirection: textDirection,
            verticalDirection: verticalDirection,
            textBaseline: textBaseline,
            clipBehavior: clipBehavior
        ) {
            if let spacing {
                children().separated(by: SizedBox(height: spacing))
            } else {
                children()
            }
        }
    }
}

/// A widget that controls how a child of a [Row], [Column], or [Flex] flexes.
///
/// Using a [Flexible] widget gives a child of a [Row], [Column], or [Flex]
/// the flexibility to expand to fill the available space in the main axis
/// (e.g., horizontally for a [Row] or vertically for a [Column]), but, unlike
/// [Expanded], [Flexible] does not require the child to fill the available
/// space.
///
/// A [Flexible] widget must be a descendant of a [Row], [Column], or [Flex],
/// and the path from the [Flexible] widget to its enclosing [Row], [Column], or
/// [Flex] must contain only [StatelessWidget]s or [StatefulWidget]s (not other
/// kinds of widgets, like [RenderObjectWidget]s).
public class Flexible: ParentDataWidget {
    public init(
        flex: Float = 1.0,
        fit: FlexFit = .loose,
        @WidgetBuilder child: () -> Widget
    ) {
        self.flex = flex
        self.fit = fit
        self.child = child()
    }

    public var child: Widget

    /// The flex factor to use for this child.
    ///
    /// If null or zero, the child is inflexible and determines its own size. If
    /// non-zero, the amount of space the child's can occupy in the main axis is
    /// determined by dividing the free space (after placing the inflexible
    /// children) according to the flex factors of the flexible children.
    public let flex: Float

    /// How a flexible child is inscribed into the available space.
    ///
    /// If [flex] is non-zero, the [fit] determines whether the child fills the
    /// space the parent makes available during layout. If the fit is
    /// [FlexFit.tight], the child is required to fill the available space. If the
    /// fit is [FlexFit.loose], the child can be at most as large as the available
    /// space (but is allowed to be smaller).
    public let fit: FlexFit

    public func applyParentData(_ renderObject: RenderObject) {
        assert(renderObject.parentData is FlexParentData)
        let parentData = renderObject.parentData as! FlexParentData
        var needsLayout = false

        if parentData.flex != flex {
            parentData.flex = flex
            needsLayout = true
        }

        if parentData.fit != fit {
            parentData.fit = fit
            needsLayout = true
        }

        if needsLayout {
            let targetParent = renderObject.parent
            if let targetParent = targetParent {
                targetParent.markNeedsLayout()
            }
        }
    }
}

/// A widget that expands a child of a [Row], [Column], or [Flex] so that the
/// child fills the available space.
///
/// Using an [Expanded] widget makes a child of a [Row], [Column], or [Flex]
/// expand to fill the available space along the main axis (e.g., horizontally
/// for a [Row] or vertically for a [Column]). If multiple children are
/// expanded, the available space is divided among them according to the [flex]
/// factor.
///
/// An [Expanded] widget must be a descendant of a [Row], [Column], or [Flex],
/// and the path from the [Expanded] widget to its enclosing [Row], [Column], or
/// [Flex] must contain only [StatelessWidget]s or [StatefulWidget]s (not other
/// kinds of widgets, like [RenderObjectWidget]s).
public class Expanded: Flexible {
    public init(
        flex: Float = 1,
        @WidgetBuilder child: () -> Widget
    ) {
        super.init(flex: flex, fit: .tight, child: child)
    }
}

/// A widget that insets its child by the given padding.
///
/// When passing layout constraints to its child, padding shrinks the
/// constraints by the given padding, causing the child to layout at a smaller
/// size. Padding then sizes itself to its child's size, inflated by the
/// padding, effectively creating empty space around the child.
public class Padding: SingleChildRenderObjectWidget {
    public init(
        _ padding: EdgeInsetsGeometry,
        @OptionalWidgetBuilder child: () -> Widget?
    ) {
        self.padding = padding
        self.child = child()
    }

    public var child: Widget?

    /// The amount of space by which to inset the child.
    let padding: EdgeInsetsGeometry

    public func createRenderObject(context: BuildContext) -> RenderPadding {
        RenderPadding(
            padding: padding,
            textDirection: .ltr
                //   textDirection: Directionality.maybeOf(context),
        )
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderPadding) {
        renderObject.padding = padding
        // renderObject.textDirection = Directionality.maybeOf(context)
    }
}

extension Widget {
    /// Adds padding to the outside of the child.
    public func padding(
        _ padding: EdgeInsetsGeometry
    ) -> Padding {
        Padding(padding) { self }
    }
}

public func voidBuilder() -> Widget? {
    nil
}
/// A widget that aligns its child within itself and optionally sizes itself
/// based on the child's size.
///
/// For example, to align a box at the bottom right, you would pass this box a
/// tight constraint that is bigger than the child's natural size,
/// with an alignment of [Alignment.bottomRight].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=g2E7yl3MwMk}
///
/// This widget will be as big as possible if its dimensions are constrained and
/// [widthFactor] and [heightFactor] are null. If a dimension is unconstrained
/// and the corresponding size factor is null then the widget will match its
/// child's size in that dimension. If a size factor is non-null then the
/// corresponding dimension of this widget will be the product of the child's
/// dimension and the size factor. For example if widthFactor is 2.0 then
/// the width of this widget will always be twice its child's width.
///
/// ## How it works
///
/// The [alignment] property describes a point in the `child`'s coordinate system
/// and a different point in the coordinate system of this widget. The [Align]
/// widget positions the `child` such that both points are lined up on top of
/// each other.
///
/// See also:
///
///  * [AnimatedAlign], which animates changes in [alignment] smoothly over a
///    given duration.
///  * [CustomSingleChildLayout], which uses a delegate to control the layout of
///    a single child.
///  * [Center], which is the same as [Align] but with the [alignment] always
///    set to [Alignment.center].
///  * [FractionallySizedBox], which sizes its child based on a fraction of its
///    own size and positions the child according to an [Alignment] value.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
public class Align: SingleChildRenderObjectWidget {
    /// Creates an alignment widget.
    ///
    /// The alignment defaults to [Alignment.center].
    public init(
        key: (any Key)? = nil,
        alignment: any AlignmentGeometry = Alignment.center,
        widthFactor: Float? = nil,
        heightFactor: Float? = nil,
        @OptionalWidgetBuilder child: () -> Widget? = voidBuilder
    ) {
        assert(widthFactor == nil || widthFactor! >= 0.0)
        assert(heightFactor == nil || heightFactor! >= 0.0)
        self.key = key
        self.alignment = alignment
        self.widthFactor = widthFactor
        self.heightFactor = heightFactor
        self.child = child()
    }

    public let key: (any Key)?

    /// How to align the child.
    ///
    /// The x and y values of the [Alignment] control the horizontal and vertical
    /// alignment, respectively. An x value of -1.0 means that the left edge of
    /// the child is aligned with the left edge of the parent whereas an x value
    /// of 1.0 means that the right edge of the child is aligned with the right
    /// edge of the parent. Other values interpolate (and extrapolate) linearly.
    /// For example, a value of 0.0 means that the center of the child is aligned
    /// with the center of the parent.
    ///
    /// See also:
    ///
    ///  * [Alignment], which has more details and some convenience constants for
    ///    common positions.
    ///  * [AlignmentDirectional], which has a horizontal coordinate orientation
    ///    that depends on the [TextDirection].
    public let alignment: any AlignmentGeometry

    /// If non-null, sets its width to the child's width multiplied by this factor.
    ///
    /// Can be both greater and less than 1.0 but must be non-negative.
    public let widthFactor: Float?

    /// If non-null, sets its height to the child's height multiplied by this factor.
    ///
    /// Can be both greater and less than 1.0 but must be non-negative.
    public let heightFactor: Float?

    public var child: Widget?

    public func createRenderObject(context: BuildContext) -> RenderPositionedBox {
        RenderPositionedBox(
            widthFactor: widthFactor,
            heightFactor: heightFactor,
            alignment: alignment,
            textDirection: .ltr
        )
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderPositionedBox) {
        renderObject.widthFactor = widthFactor
        renderObject.heightFactor = heightFactor
        renderObject.alignment = alignment
        renderObject.textDirection = .ltr
    }
}

extension Widget {
    /// Aligns the child within it's parent.
    public func align(
        alignment: any AlignmentGeometry = Alignment.center,
        widthFactor: Float? = nil,
        heightFactor: Float? = nil
    ) -> Align {
        Align(alignment: alignment, widthFactor: widthFactor, heightFactor: heightFactor) { self }
    }
}

/// A widget that centers its child within itself.
///
/// This widget will be as big as possible if its dimensions are constrained and
/// [widthFactor] and [heightFactor] are null. If a dimension is unconstrained
/// and the corresponding size factor is null then the widget will match its
/// child's size in that dimension. If a size factor is non-null then the
/// corresponding dimension of this widget will be the product of the child's
/// dimension and the size factor. For example if widthFactor is 2.0 then
/// the width of this widget will always be twice its child's width.
///
/// See also:
///
///  * [Align], which lets you arbitrarily position a child within itself,
///    rather than just centering it.
///  * [Row], a widget that displays its children in a horizontal array.
///  * [Column], a widget that displays its children in a vertical array.
///  * [Container], a convenience widget that combines common painting,
///    positioning, and sizing widgets.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
public class Center: Align {
    /// Creates a widget that centers its child.
    public init(
        key: (any Key)? = nil,
        widthFactor: Float? = nil,
        heightFactor: Float? = nil,
        @OptionalWidgetBuilder child: () -> Widget? = voidBuilder
    ) {
        super.init(
            key: key,
            alignment: Alignment.center,
            widthFactor: widthFactor,
            heightFactor: heightFactor,
            child: child
        )
    }
}

extension Widget {
    /// Centers the child within it's parent.
    public func center() -> Center {
        Center { self }
    }
}

/// A box with a specified size.
///
/// If given a child, this widget forces it to have a specific width and/or height.
/// These values will be ignored if this widget's parent does not permit them.
/// For example, this happens if the parent is the screen (forces the child to
/// be the same size as the parent), or another [SizedBox] (forces its child to
/// have a specific width and/or height). This can be remedied by wrapping the
/// child [SizedBox] in a widget that does permit it to be any size up to the
/// size of the parent, such as [Center] or [Align].
///
/// If either the width or height is null, this widget will try to size itself to
/// match the child's size in that dimension. If the child's size depends on the
/// size of its parent, the height and width must be provided.
///
/// If not given a child, [SizedBox] will try to size itself as close to the
/// specified height and width as possible given the parent's constraints. If
/// [height] or [width] is null or unspecified, it will be treated as zero.
///
/// The [SizedBox.expand] constructor can be used to make a [SizedBox] that
/// sizes itself to fit the parent. It is equivalent to setting [width] and
/// [height] to [double.infinity].
public class SizedBox: SingleChildRenderObjectWidget {
    /// Creates a fixed size box. The [width] and [height] parameters can be
    /// null to indicate that the size of the box should not be constrained in
    /// the corresponding dimension.
    public init(
        width: Float? = nil,
        height: Float? = nil,
        @OptionalWidgetBuilder child: () -> Widget? = voidBuilder
    ) {
        self.width = width
        self.height = height
        self.child = child()
    }

    /// Creates a box that will become as large as its parent allows.
    public static func expand(
        @OptionalWidgetBuilder child: () -> Widget? = voidBuilder
    ) -> SizedBox {
        SizedBox(width: Float.infinity, height: Float.infinity, child: child)
    }

    /// Creates a box that will become as small as its parent allows.
    public static func shrink(
        @OptionalWidgetBuilder child: () -> Widget? = voidBuilder
    ) -> SizedBox {
        SizedBox(width: 0, height: 0, child: child)
    }

    /// If non-null, requires the child to have exactly this width.
    public let width: Float?

    /// If non-null, requires the child to have exactly this height.
    public let height: Float?

    public let child: Widget?

    private var additionalConstraints: BoxConstraints {
        BoxConstraints.tightFor(width: width, height: height)
    }

    public func createRenderObject(context: BuildContext) -> RenderConstrainedBox {
        RenderConstrainedBox(
            additionalConstraints: additionalConstraints
        )
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderConstrainedBox) {
        renderObject.additionalConstraints = additionalConstraints
    }
}

extension Widget {
    /// Adds a box constraint to the child that forces it to occupy as much
    /// horizontal space as possible.
    public func horizontalExpand() -> SizedBox {
        SizedBox(width: .infinity) { self }
    }

    /// Adds a box constraint to the child that forces it to occupy as much
    /// vertical space as possible.
    public func verticalExpand() -> SizedBox {
        SizedBox(height: .infinity) { self }
    }

    /// Adds a box constraint to the child that forces it to occupy as much
    /// space as possible in both dimensions.
    public func expand() -> SizedBox {
        SizedBox.expand { self }
    }

    /// Adds a box constraint to the child that forces it to occupy as little
    /// space as possible in both dimensions.
    public func shrink() -> SizedBox {
        SizedBox.shrink { self }
    }

    /// Adds additional constraints to the child.
    public func constrained(
        width: Float? = nil,
        height: Float? = nil
    ) -> SizedBox {
        SizedBox(width: width, height: height) { self }
    }
}

/// A paragraph of rich text.
///
/// The [RichText] widget displays text that uses multiple different styles. The
/// text to display is described using a tree of [TextSpan] objects, each of
/// which has an associated style that is used for that subtree. The text might
/// break across multiple lines or might all be displayed on the same line
/// depending on the layout constraints.
///
/// Text displayed in a [RichText] widget must be explicitly styled. When
/// picking which style to use, consider using [DefaultTextStyle.of] the current
/// [BuildContext] to provide defaults. For more details on how to style text in
/// a [RichText] widget, see the documentation for [TextStyle].
///
/// Consider using the [Text] widget to integrate with the [DefaultTextStyle]
/// automatically. When all the text uses the same style, the default constructor
/// is less verbose. The [Text.rich] constructor allows you to style multiple
/// spans with the default text style while still allowing specified styles per
/// span.
public class RichText: MultiChildRenderObjectWidget {
    public init(
        text: InlineSpan,
        textAlign: TextAlign,
        textDirection: TextDirection? = nil,
        softWrap: Bool,
        overflow: TextOverflow,
        textScaler: any TextScaler,
        maxLines: Int? = nil,
        strutStyle: StrutStyle? = nil,
        textWidthBasis: TextWidthBasis,
        textHeightBehavior: TextHeightBehavior? = nil,
        selectionColor: Color? = nil
    ) {
        self.text = text
        self.textAlign = textAlign
        self.textDirection = textDirection
        self.softWrap = softWrap
        self.overflow = overflow
        self.textScaler = textScaler
        self.maxLines = maxLines
        self.strutStyle = strutStyle
        self.textWidthBasis = textWidthBasis
        self.textHeightBehavior = textHeightBehavior
        self.selectionColor = selectionColor
    }

    public let children: [Widget] = []

    /// The text to display in this widget.
    public let text: InlineSpan

    /// How the text should be aligned horizontally.
    public let textAlign: TextAlign

    /// The directionality of the text.
    ///
    /// This decides how [textAlign] values like [TextAlign.start] and
    /// [TextAlign.end] are interpreted.
    ///
    /// This is also used to disambiguate how to render bidirectional text. For
    /// example, if the [text] is an English phrase followed by a Hebrew phrase,
    /// in a [TextDirection.ltr] context the English phrase will be on the left
    /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
    /// context, the English phrase will be on the right and the Hebrew phrase on
    /// its left.
    ///
    /// Defaults to the ambient [Directionality], if any. If there is no ambient
    /// [Directionality], then this must not be null.
    public let textDirection: TextDirection?

    /// Whether the text should break at soft line breaks.
    ///
    /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
    public let softWrap: Bool

    /// How visual overflow should be handled.
    public let overflow: TextOverflow

    /// {@macro flutter.painting.textPainter.textScaler}
    public let textScaler: any TextScaler

    /// An optional maximum number of lines for the text to span, wrapping if necessary.
    /// If the text exceeds the given number of lines, it will be truncated according
    /// to [overflow].
    ///
    /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
    /// edge of the box.
    public let maxLines: Int?

    /// Used to select a font when the same Unicode character can
    /// be rendered differently, depending on the locale.
    ///
    /// It's rarely necessary to set this property. By default its value
    /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
    ///
    /// See [RenderParagraph.locale] for more information.
    // public let locale: Locale?

    public let strutStyle: StrutStyle?

    public let textWidthBasis: TextWidthBasis

    public let textHeightBehavior: TextHeightBehavior?

    /// The [SelectionRegistrar] this rich text is subscribed to.
    ///
    /// If this is set, [selectionColor] must be non-null.
    // public let selectionRegistrar: SelectionRegistrar?

    /// The color to use when painting the selection.
    ///
    /// This is ignored if [selectionRegistrar] is null.
    ///
    /// See the section on selections in the [RichText] top-level API
    /// documentation for more details on enabling selection in [RichText]
    /// widgets.
    public let selectionColor: Color?

    public func createRenderObject(context: BuildContext) -> RenderParagraph {
        // assert(textDirection != null || debugCheckHasDirectionality(context));
        RenderParagraph(
            text,
            textAlign: textAlign,
            textDirection: textDirection ?? .ltr,
            // textDirection: textDirection ?? Directionality.of(context),
            softWrap: softWrap,
            overflow: overflow,
            textScaler: textScaler,
            maxLines: maxLines,
            strutStyle: strutStyle,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior
                // children: children,
                // selectionColor: selectionColor,
        )
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderParagraph) {
        renderObject.text = text
        // renderObject.textAlign = textAlign
        renderObject.textDirection = textDirection ?? .ltr
        // renderObject.textDirection = textDirection ?? Directionality.of(context)
        renderObject.softWrap = softWrap
        renderObject.overflow = overflow
        renderObject.textScaler = textScaler
        renderObject.maxLines = maxLines
        renderObject.strutStyle = strutStyle
        renderObject.textWidthBasis = textWidthBasis
        renderObject.textHeightBehavior = textHeightBehavior
        // renderObject.selectionColor = selectionColor
    }
}

/// A widget that displays a [Image] directly.
///
/// The image is painted using [paintImage], which describes the meanings of the
/// various fields on this class in more detail.
///
/// The [image] is not disposed of by this widget. Creators of the widget are
/// expected to call [Image.dispose] on the [image] once the [RawImage] is no
/// longer buildable.
///
/// This widget is rarely used directly. Instead, consider using [Image].
public class RawImage: LeafRenderObjectWidget {
    public init(
        image: NativeImage? = nil,
        debugImageLabel: String? = nil,
        width: Float? = nil,
        height: Float? = nil,
        scale: Float = 1.0,
        color: Color? = nil,
        filterQuality: FilterQuality = .low,
        colorBlendMode: BlendMode = .srcIn,
        fit: BoxFit? = nil,
        alignment: any AlignmentGeometry = Alignment.center,
        `repeat`: ImageRepeat = .noRepeat,
        centerSlice: Rect? = nil,
        matchTextDirection: Bool = false,
        invertColors: Bool = false,
        isAntiAlias: Bool = false
    ) {
        self.image = image
        self.debugImageLabel = debugImageLabel
        self.width = width
        self.height = height
        self.scale = scale
        self.color = color
        self.filterQuality = filterQuality
        self.colorBlendMode = colorBlendMode
        self.fit = fit
        self.alignment = alignment
        self.`repeat` = `repeat`
        self.centerSlice = centerSlice
        self.matchTextDirection = matchTextDirection
        self.invertColors = invertColors
        self.isAntiAlias = isAntiAlias
    }

    /// The image to display.
    ///
    /// Since a [RawImage] is stateless, it does not ever dispose this image.
    /// Creators of a [RawImage] are expected to call [Image.dispose] on this
    /// image handle when the [RawImage] will no longer be needed.
    public let image: NativeImage?

    /// A string identifying the source of the image.
    public let debugImageLabel: String?

    /// If non-null, require the image to have this width.
    ///
    /// If null, the image will pick a size that best preserves its intrinsic
    /// aspect ratio.
    public let width: Float?

    /// If non-null, require the image to have this height.
    ///
    /// If null, the image will pick a size that best preserves its intrinsic
    /// aspect ratio.
    public let height: Float?

    /// Specifies the image's scale.
    ///
    /// Used when determining the best display size for the image.
    public let scale: Float

    /// If non-null, this color is blended with each image pixel using [colorBlendMode].
    public let color: Color?

    /// If non-null, the value from the [Animation] is multiplied with the opacity
    /// of each image pixel before painting onto the canvas.
    ///
    /// This is more efficient than using [FadeTransition] to change the opacity
    /// of an image.
    // public let opacity: Animation<Float>?

    /// Used to set the filterQuality of the image.
    ///
    /// Defaults to [FilterQuality.low] to scale the image, which corresponds to
    /// bilinear interpolation.
    public let filterQuality: FilterQuality

    /// Used to combine [color] with this image.
    ///
    /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
    /// the source and this image is the destination.
    ///
    /// See also:
    ///
    ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
    public let colorBlendMode: BlendMode

    /// How to inscribe the image into the space allocated during layout.
    ///
    /// The default varies based on the other fields. See the discussion at
    /// [paintImage].
    public let fit: BoxFit?

    /// How to align the image within its bounds.
    ///
    /// The alignment aligns the given position in the image to the given position
    /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
    /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
    /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
    /// image with the bottom right corner of its layout bounds. Similarly, an
    /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
    /// middle of the bottom edge of its layout bounds.
    ///
    /// To display a subpart of an image, consider using a [CustomPainter] and
    /// [Canvas.drawImageRect].
    ///
    /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
    /// [AlignmentDirectional]), then an ambient [Directionality] widget
    /// must be in scope.
    ///
    /// Defaults to [Alignment.center].
    ///
    /// See also:
    ///
    ///  * [Alignment], a class with convenient constants typically used to
    ///    specify an [AlignmentGeometry].
    ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
    ///    relative to text direction.
    public let alignment: any AlignmentGeometry

    /// How to paint any portions of the layout bounds not covered by the image.
    public let `repeat`: ImageRepeat

    /// The center slice for a nine-patch image.
    ///
    /// The region of the image inside the center slice will be stretched both
    /// horizontally and vertically to fit the image into its destination. The
    /// region of the image above and below the center slice will be stretched
    /// only horizontally and the region of the image to the left and right of
    /// the center slice will be stretched only vertically.
    public let centerSlice: Rect?

    /// Whether to paint the image in the direction of the [TextDirection].
    ///
    /// If this is true, then in [TextDirection.ltr] contexts, the image will be
    /// drawn with its origin in the top left (the "normal" painting direction for
    /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
    /// a scaling factor of -1 in the horizontal direction so that the origin is
    /// in the top right.
    ///
    /// This is occasionally used with images in right-to-left environments, for
    /// images that were designed for left-to-right locales. Be careful, when
    /// using this, to not flip images with integral shadows, text, or other
    /// effects that will look incorrect when flipped.
    ///
    /// If this is true, there must be an ambient [Directionality] widget in
    /// scope.
    public let matchTextDirection: Bool

    /// Whether the colors of the image are inverted when drawn.
    ///
    /// Inverting the colors of an image applies a new color filter to the paint.
    /// If there is another specified color filter, the invert will be applied
    /// after it. This is primarily used for implementing smart invert on iOS.
    public let invertColors: Bool

    /// Whether to paint the image with anti-aliasing.
    ///
    /// Anti-aliasing alleviates the sawtooth artifact when the image is rotated.
    public let isAntiAlias: Bool

    public func createRenderObject(context: BuildContext) -> RenderImage {
        RenderImage(
            image: image,
            width: width,
            height: height,
            scale: scale,
            color: color,
            filterQuality: filterQuality,
            colorBlendMode: colorBlendMode,
            fit: fit,
            alignment: alignment,
            repeat: `repeat`,
            centerSlice: centerSlice,
            matchTextDirection: matchTextDirection,
            // invertColors: invertColors,
            isAntiAlias: isAntiAlias
        )
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderImage) {
        renderObject.image = image
        renderObject.width = width
        renderObject.height = height
        renderObject.scale = scale
        renderObject.color = color
        renderObject.filterQuality = filterQuality
        renderObject.colorBlendMode = colorBlendMode
        renderObject.fit = fit
        renderObject.alignment = alignment
        renderObject.repeat = `repeat`
        renderObject.centerSlice = centerSlice
        renderObject.matchTextDirection = matchTextDirection
        // renderObject.invertColors = invertColors
        renderObject.isAntiAlias = isAntiAlias
    }
}

/// Returns the [AxisDirection] in the given [Axis] in the current
/// [Directionality] (or the reverse if `reverse` is true).
///
/// If `axis` is [Axis.vertical], this function returns [AxisDirection.down]
/// unless `reverse` is true, in which case this function returns
/// [AxisDirection.up].
///
/// If `axis` is [Axis.horizontal], this function checks the current
/// [Directionality]. If the current [Directionality] is right-to-left, then
/// this function returns [AxisDirection.left] (unless `reverse` is true, in
/// which case it returns [AxisDirection.right]). Similarly, if the current
/// [Directionality] is left-to-right, then this function returns
/// [AxisDirection.right] (unless `reverse` is true, in which case it returns
/// [AxisDirection.left]).
///
/// This function is used by a number of scrolling widgets (e.g., [ListView],
/// [GridView], [PageView], and [SingleChildScrollView]) as well as [ListBody]
/// to translate their [Axis] and `reverse` properties into a concrete
/// [AxisDirection].
public func getAxisDirectionFromAxisReverseAndDirectionality(
    context: BuildContext,
    axis: Axis,
    reverse: Bool
) -> AxisDirection {
    switch axis {
    case .horizontal:
        // assert(debugCheckHasDirectionality(context))
        // let textDirection = Directionality.of(context)
        // let axisDirection = textDirectionToAxisDirection(textDirection)
        // return reverse ? flipAxisDirection(axisDirection) : axisDirection
        return reverse ? .left : .right
    case .vertical:
        return reverse ? .up : .down
    }
}
/// A widget that positions its children relative to the edges of its box.
///
/// This class is useful if you want to overlap several children in a simple
/// way, for example having some text and an image, overlaid with a gradient and
/// a button attached to the bottom.
///
/// Each child of a [Stack] widget is either _positioned_ or _non-positioned_.
/// Positioned children are those wrapped in a [Positioned] widget that has at
/// least one non-null property. The stack sizes itself to contain all the
/// non-positioned children, which are positioned according to [alignment]
/// (which defaults to the top-left corner in left-to-right environments and the
/// top-right corner in right-to-left environments). The positioned children are
/// then placed relative to the stack according to their top, right, bottom, and
/// left properties.
///
/// The stack paints its children in order with the first child being at the
/// bottom. If you want to change the order in which the children paint, you
/// can rebuild the stack with the children in the new order. If you reorder
/// the children in this way, consider giving the children non-null keys.
/// These keys will cause the framework to move the underlying objects for
/// the children to their new locations rather than recreate them at their
/// new location.
///
/// For more details about the stack layout algorithm, see [RenderStack].
///
/// If you want to lay a number of children out in a particular pattern, or if
/// you want to make a custom layout manager, you probably want to use
/// [CustomMultiChildLayout] instead. In particular, when using a [Stack] you
/// can't position children relative to their size or the stack's own size.
public class Stack: MultiChildRenderObjectWidget {
    public init(
        alignment: any AlignmentGeometry = Alignment.topLeft,
        textDirection: TextDirection = .ltr,
        fit: StackFit = .loose,
        clipBehavior: Clip = .hardEdge,
        @WidgetListBuilder children: () -> [Widget]
    ) {
        self.alignment = alignment
        self.textDirection = textDirection
        self.fit = fit
        self.clipBehavior = clipBehavior
        self.children = children()
    }

    public var children: [Widget]

    /// How to align the non-positioned and partially-positioned children in the
    /// stack.
    ///
    /// The non-positioned children are placed relative to each other such that
    /// the points determined by [alignment] are co-located. For example, if the
    /// [alignment] is [Alignment.topLeft], then the top left corner of
    /// each non-positioned child will be located at the same global coordinate.
    ///
    /// Partially-positioned children, those that do not specify an alignment in a
    /// particular axis (e.g. that have neither `top` nor `bottom` set), use the
    /// alignment to determine how they should be positioned in that
    /// under-specified axis.
    ///
    /// Defaults to [AlignmentDirectional.topStart].
    public var alignment: any AlignmentGeometry

    /// The text direction with which to resolve [alignment].
    ///
    /// Defaults to the ambient [Directionality].
    public var textDirection: TextDirection

    /// How to size the non-positioned children in the stack.
    ///
    /// The constraints passed into the [Stack] from its parent are either
    /// loosened ([StackFit.loose]) or tightened to their biggest size
    /// ([StackFit.expand]).
    public var fit: StackFit

    /// Stacks only clip children whose _geometry_ overflows the stack. A child
    /// that paints outside its bounds (e.g. a box with a shadow) will not be
    /// clipped, regardless of the value of this property. Similarly, a child that
    /// itself has a descendant that overflows the stack will not be clipped, as
    /// only the geometry of the stack's direct children are considered.
    /// [Transform] is an example of a widget that can cause its children to paint
    /// outside its geometry.
    ///
    /// To clip children whose geometry does not overflow the stack, consider
    /// using a [ClipRect] widget.
    ///
    /// Defaults to [Clip.hardEdge].
    public var clipBehavior: Clip

    public func createRenderObject(context: BuildContext) -> RenderStack {
        RenderStack(
            alignment: alignment,
            textDirection: textDirection,
            fit: fit,
            clipBehavior: clipBehavior
        )
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderStack) {
        renderObject.alignment = alignment
        renderObject.textDirection = textDirection
        renderObject.fit = fit
        renderObject.clipBehavior = clipBehavior
    }
}

/// A widget that controls where a child of a [Stack] is positioned.
///
/// A [Positioned] widget must be a descendant of a [Stack], and the path from
/// the [Positioned] widget to its enclosing [Stack] must contain only
/// [StatelessWidget]s or [StatefulWidget]s (not other kinds of widgets, like
/// [RenderObjectWidget]s).
///
/// If a widget is wrapped in a [Positioned], then it is a _positioned_ widget
/// in its [Stack]. If the [top] property is non-null, the top edge of this
/// child will be positioned [top] layout units from the top of the stack
/// widget. The [right], [bottom], and [left] properties work analogously.
///
/// If both the [top] and [bottom] properties are non-null, then the child will
/// be forced to have exactly the height required to satisfy both constraints.
/// Similarly, setting the [right] and [left] properties to non-null values will
/// force the child to have a particular width. Alternatively the [width] and
/// [height] properties can be used to give the dimensions, with one
/// corresponding position property (e.g. [top] and [height]).
///
/// If all three values on a particular axis are null, then the
/// [Stack.alignment] property is used to position the child.
///
/// If all six values are null, the child is a non-positioned child. The [Stack]
/// uses only the non-positioned children to size itself.
public class Positioned: ParentDataWidget {
    public init(
        left: Float? = nil,
        top: Float? = nil,
        right: Float? = nil,
        bottom: Float? = nil,
        width: Float? = nil,
        height: Float? = nil,
        @WidgetBuilder child: () -> Widget
    ) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
        self.width = width
        self.height = height
        self.child = child()
    }

    /// Creates a Positioned object with the values from the given size and offset.
    public init(size: Size, offset: Offset, @WidgetBuilder child: () -> Widget) {
        self.left = offset.dx
        self.top = offset.dy
        self.width = size.width
        self.height = size.height
        self.child = child()
    }

    /// Creates a Positioned object with the values from the given [Rect].
    public init(rect: Rect, @WidgetBuilder child: () -> Widget) {
        self.left = rect.left
        self.top = rect.top
        self.width = rect.width
        self.height = rect.height
        self.child = child()
    }

    public var child: Widget

    /// The distance that the child's left edge is inset from the left of the stack.
    ///
    /// Only two out of the three horizontal values ([left], [right], [width]) can be
    /// set. The third must be null.
    ///
    /// If all three are null, the [Stack.alignment] is used to position the child
    /// horizontally.
    public var left: Float?

    /// The distance that the child's top edge is inset from the top of the stack.
    ///
    /// Only two out of the three vertical values ([top], [bottom], [height]) can be
    /// set. The third must be null.
    ///
    /// If all three are null, the [Stack.alignment] is used to position the child
    /// vertically.
    public var top: Float?

    /// The distance that the child's right edge is inset from the right of the stack.
    ///
    /// Only two out of the three horizontal values ([left], [right], [width]) can be
    /// set. The third must be null.
    ///
    /// If all three are null, the [Stack.alignment] is used to position the child
    /// horizontally.
    public var right: Float?

    /// The distance that the child's bottom edge is inset from the bottom of the stack.
    ///
    /// Only two out of the three vertical values ([top], [bottom], [height]) can be
    /// set. The third must be null.
    ///
    /// If all three are null, the [Stack.alignment] is used to position the child
    /// vertically.
    public var bottom: Float?

    /// The child's width.
    ///
    /// Only two out of the three horizontal values ([left], [right], [width]) can be
    /// set. The third must be null.
    ///
    /// If all three are null, the [Stack.alignment] is used to position the child
    /// horizontally.
    public var width: Float?

    /// The child's height.
    ///
    /// Only two out of the three vertical values ([top], [bottom], [height]) can be
    /// set. The third must be null.
    ///
    /// If all three are null, the [Stack.alignment] is used to position the child
    /// vertically.
    public var height: Float?

    public final func applyParentData(_ renderObject: RenderObject) {
        assert(renderObject.parentData is StackParentData)
        let parentData = renderObject.parentData as! StackParentData
        var needsLayout = false

        if parentData.left != left {
            parentData.left = left
            needsLayout = true
        }

        if parentData.top != top {
            parentData.top = top
            needsLayout = true
        }

        if parentData.right != right {
            parentData.right = right
            needsLayout = true
        }

        if parentData.bottom != bottom {
            parentData.bottom = bottom
            needsLayout = true
        }

        if parentData.width != width {
            parentData.width = width
            needsLayout = true
        }

        if parentData.height != height {
            parentData.height = height
            needsLayout = true
        }

        if needsLayout {
            if let targetParent = renderObject.parent {
                targetParent.markNeedsLayout()
            }
        }
    }
}

/// A widget that builds its child.
///
/// Useful for attaching a key to an existing widget.
public class KeyedSubtree: StatelessWidget {
    /// Creates a widget that builds its child.
    public init(
        key: (any Key)?,
        @WidgetBuilder child: () -> Widget
    ) {
        self.key = key
        self.child = child()
    }

    public var key: (any Key)?

    /// The widget below this widget in the tree.
    public var child: Widget

    public func build(context: BuildContext) -> Widget { child }
}

/// A stateless utility widget whose [build] method uses its
/// [builder] callback to create the widget's child.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=xXNOkIuSYuA}
///
/// This widget is an inline alternative to defining a [StatelessWidget]
/// subclass. For example, instead of defining a widget as follows:
public class Builder: StatelessWidget {
    /// Creates a widget that delegates its build to a callback.
    public init(
        key: (any Key)? = nil,
        @WidgetBuilder builder: @escaping (BuildContext) -> Widget
    ) {
        self.key = key
        self.builder = builder
    }

    public var key: (any Key)?

    /// Called to obtain the child widget.
    ///
    /// This function is called whenever this widget is included in its parent's
    /// build and the old widget (if any) that it synchronizes with has a distinct
    /// object identity. Typically the parent's build method will construct
    /// a new tree of widgets and so a new Builder child will not be [identical]
    /// to the corresponding old one.
    public let builder: (BuildContext) -> Widget

    public func build(context: BuildContext) -> Widget {
        builder(context)
    }
}
