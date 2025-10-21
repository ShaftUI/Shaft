// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Factory for creating gesture recognizers.
public protocol GestureRecognizerFactory {
    typealias GestureRecognizerConstructor = () -> GestureRecognizer
    typealias GestureRecognizerInitializer = (GestureRecognizer) -> Void

    var constructor: GestureRecognizerConstructor { get }

    var initializer: GestureRecognizerInitializer { get }
}

public struct CallbackGestureRecognizerFactory<T: GestureRecognizer>: GestureRecognizerFactory {
    public let constructor: GestureRecognizerConstructor

    public let initializer: GestureRecognizerInitializer

    public init(
        constructor: @escaping () -> T,
        initializer: @escaping (T) -> Void
    ) {
        self.constructor = constructor
        self.initializer = { recognizer in
            initializer(recognizer as! T)
        }
    }
}

/// A widget that detects gestures described by the given gesture factories.
///
/// For common gestures, use a [GestureDetector]. [RawGestureDetector] is useful
/// primarily when developing your own gesture recognizers.
public final class RawGestureDetector: StatefulWidget {
    public init(
        gestures: [GestureRecognizerFactory],
        behavior: HitTestBehavior? = nil,
        @WidgetBuilder child: () -> Widget?
    ) {
        self.gestures = gestures
        self.behavior = behavior
        self.child = child()
    }

    /// The gestures that this widget will attempt to recognize.
    ///
    /// This should be a map from [GestureRecognizer] subclasses to
    /// [GestureRecognizerFactory] subclasses specialized with the same type.
    ///
    /// This value can be late-bound at layout time using
    /// [RawGestureDetectorState.replaceGestureRecognizers].
    public let gestures: [GestureRecognizerFactory]

    /// How this gesture detector should behave during hit testing.
    ///
    /// This defaults to [HitTestBehavior.deferToChild] if [child] is not null and
    /// [HitTestBehavior.translucent] if child is null.
    //   final HitTestBehavior? behavior;
    public let behavior: HitTestBehavior?

    /// The widget below this widget in the tree.
    public let child: Widget?

    public func createState() -> RawGestureDetectorState {
        RawGestureDetectorState()
    }
}

/// State for a [RawGestureDetector].
public final class RawGestureDetectorState: State<RawGestureDetector> {
    private var recognizers: [ObjectIdentifier: GestureRecognizer] = [:]

    public override func initState() {
        super.initState()
        syncAll(widget.gestures)
    }

    public override func didUpdateWidget(_ oldWidget: RawGestureDetector) {
        super.didUpdateWidget(oldWidget)
        syncAll(widget.gestures)
    }

    public override func dispose() {
        for recognizer in recognizers.values {
            recognizer.dispose()
        }
        super.dispose()
    }

    private func syncAll(_ gestures: [GestureRecognizerFactory]) {
        let oldRecognizers = recognizers
        recognizers = [:]
        for gesture in gestures {
            let gestureType = ObjectIdentifier(type(of: gesture))
            let recognizer = oldRecognizers[gestureType] ?? gesture.constructor()
            recognizers[gestureType] = recognizer
            gesture.initializer(recognizer)
        }
        for (type, recognizer) in oldRecognizers where recognizers[type] == nil {
            recognizer.dispose()
        }
    }

    private func handlePointerDown(event: PointerDownEvent) {
        assert(mounted)
        for recognizer in recognizers.values {
            recognizer.addPointer(event: event)
        }
    }

    private func handlePointerPanZoomStart(event: PointerPanZoomStartEvent) {
        assert(mounted)
        for recognizer in recognizers.values {
            recognizer.addPointerPanZoom(event: event)
        }
    }

    private var defaultBehavior: HitTestBehavior {
        widget.child == nil ? .translucent : .deferToChild
    }

    public override func build(context: BuildContext) -> Widget {
        Listener(
            onPointerDown: handlePointerDown,
            onPointerPanZoomStart: handlePointerPanZoomStart,
            behavior: widget.behavior ?? defaultBehavior
        ) {
            widget.child
        }
    }
}

/// A widget that detects gestures.
///
/// Attempts to recognize gestures that correspond to its non-null callbacks.
///
/// If this widget has a child, it defers to that child for its sizing behavior.
/// If it does not have a child, it grows to fit the parent instead.
///
/// By default a GestureDetector with an invisible child ignores touches;
/// this behavior can be controlled with [behavior].
///
/// GestureDetector also listens for accessibility events and maps
/// them to the callbacks. To ignore accessibility events, set
/// [excludeFromSemantics] to true.
public final class GestureDetector: StatelessWidget {
    public init(
        onTapDown: GestureTapDownCallback? = nil,
        onTapUp: GestureTapUpCallback? = nil,
        onTap: GestureTapCallback? = nil,
        onTapCancel: GestureTapCancelCallback? = nil,
        onSecondaryTap: GestureTapCallback? = nil,
        onSecondaryTapDown: GestureTapDownCallback? = nil,
        onSecondaryTapUp: GestureTapUpCallback? = nil,
        onSecondaryTapCancel: GestureTapCancelCallback? = nil,
        onTertiaryTapDown: GestureTapDownCallback? = nil,
        onTertiaryTapUp: GestureTapUpCallback? = nil,
        onTertiaryTapCancel: GestureTapCancelCallback? = nil,
        onVerticalDragDown: GestureDragDownCallback? = nil,
        onVerticalDragStart: GestureDragStartCallback? = nil,
        onVerticalDragUpdate: GestureDragUpdateCallback? = nil,
        onVerticalDragEnd: GestureDragEndCallback? = nil,
        onVerticalDragCancel: GestureDragCancelCallback? = nil,
        onHorizontalDragDown: GestureDragDownCallback? = nil,
        onHorizontalDragStart: GestureDragStartCallback? = nil,
        onHorizontalDragUpdate: GestureDragUpdateCallback? = nil,
        onHorizontalDragEnd: GestureDragEndCallback? = nil,
        onHorizontalDragCancel: GestureDragCancelCallback? = nil,
        onPanDown: GestureDragDownCallback? = nil,
        onPanStart: GestureDragStartCallback? = nil,
        onPanUpdate: GestureDragUpdateCallback? = nil,
        onPanEnd: GestureDragEndCallback? = nil,
        onPanCancel: GestureDragCancelCallback? = nil,
        behavior: HitTestBehavior? = nil,
        dragStartBehavior: DragStartBehavior = .start,
        supportedDevices: Set<PointerDeviceKind>? = nil,
        @OptionalWidgetBuilder child: () -> Widget?
    ) {
        self.onTapDown = onTapDown
        self.onTapUp = onTapUp
        self.onTap = onTap
        self.onTapCancel = onTapCancel
        self.onSecondaryTap = onSecondaryTap
        self.onSecondaryTapDown = onSecondaryTapDown
        self.onSecondaryTapUp = onSecondaryTapUp
        self.onSecondaryTapCancel = onSecondaryTapCancel
        self.onTertiaryTapDown = onTertiaryTapDown
        self.onTertiaryTapUp = onTertiaryTapUp
        self.onTertiaryTapCancel = onTertiaryTapCancel
        self.onVerticalDragDown = onVerticalDragDown
        self.onVerticalDragStart = onVerticalDragStart
        self.onVerticalDragUpdate = onVerticalDragUpdate
        self.onVerticalDragEnd = onVerticalDragEnd
        self.onVerticalDragCancel = onVerticalDragCancel
        self.onHorizontalDragDown = onHorizontalDragDown
        self.onHorizontalDragStart = onHorizontalDragStart
        self.onHorizontalDragUpdate = onHorizontalDragUpdate
        self.onHorizontalDragEnd = onHorizontalDragEnd
        self.onHorizontalDragCancel = onHorizontalDragCancel
        self.onPanDown = onPanDown
        self.onPanStart = onPanStart
        self.onPanUpdate = onPanUpdate
        self.onPanEnd = onPanEnd
        self.onPanCancel = onPanCancel
        self.behavior = behavior
        self.dragStartBehavior = dragStartBehavior
        self.supportedDevices = supportedDevices
        self.child = child()
    }

    /// A pointer that might cause a tap with a primary button has contacted the
    /// screen at a particular location.
    ///
    /// This is called after a short timeout, even if the winning gesture has not
    /// yet been selected. If the tap gesture wins, [onTapUp] will be called,
    /// otherwise [onTapCancel] will be called.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onTapDown: GestureTapDownCallback?

    /// A pointer that will trigger a tap with a primary button has stopped
    /// contacting the screen at a particular location.
    ///
    /// This triggers immediately before [onTap] in the case of the tap gesture
    /// winning. If the tap gesture did not win, [onTapCancel] is called instead.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onTapUp: GestureTapUpCallback?

    /// A tap with a primary button has occurred.
    ///
    /// This triggers when the tap gesture wins. If the tap gesture did not win,
    /// [onTapCancel] is called instead.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [onTapUp], which is called at the same time but includes details
    ///    regarding the pointer position.
    public let onTap: GestureTapCallback?

    /// The pointer that previously triggered [onTapDown] will not end up causing
    /// a tap.
    ///
    /// This is called after [onTapDown], and instead of [onTapUp] and [onTap], if
    /// the tap gesture did not win.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onTapCancel: GestureTapCancelCallback?

    /// A tap with a secondary button has occurred.
    ///
    /// This triggers when the tap gesture wins. If the tap gesture did not win,
    /// [onSecondaryTapCancel] is called instead.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [onSecondaryTapUp], which is called at the same time but includes details
    ///    regarding the pointer position.
    public let onSecondaryTap: GestureTapCallback?

    /// A pointer that might cause a tap with a secondary button has contacted the
    /// screen at a particular location.
    ///
    /// This is called after a short timeout, even if the winning gesture has not
    /// yet been selected. If the tap gesture wins, [onSecondaryTapUp] will be
    /// called, otherwise [onSecondaryTapCancel] will be called.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    public let onSecondaryTapDown: GestureTapDownCallback?

    /// A pointer that will trigger a tap with a secondary button has stopped
    /// contacting the screen at a particular location.
    ///
    /// This triggers in the case of the tap gesture winning. If the tap gesture
    /// did not win, [onSecondaryTapCancel] is called instead.
    ///
    /// See also:
    ///
    ///  * [onSecondaryTap], a handler triggered right after this one that doesn't
    ///    pass any details about the tap.
    ///  * [kSecondaryButton], the button this callback responds to.
    public let onSecondaryTapUp: GestureTapUpCallback?

    /// The pointer that previously triggered [onSecondaryTapDown] will not end up
    /// causing a tap.
    ///
    /// This is called after [onSecondaryTapDown], and instead of
    /// [onSecondaryTapUp], if the tap gesture did not win.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    public let onSecondaryTapCancel: GestureTapCancelCallback?

    /// A pointer that might cause a tap with a tertiary button has contacted the
    /// screen at a particular location.
    ///
    /// This is called after a short timeout, even if the winning gesture has not
    /// yet been selected. If the tap gesture wins, [onTertiaryTapUp] will be
    /// called, otherwise [onTertiaryTapCancel] will be called.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    public let onTertiaryTapDown: GestureTapDownCallback?

    /// A pointer that will trigger a tap with a tertiary button has stopped
    /// contacting the screen at a particular location.
    ///
    /// This triggers in the case of the tap gesture winning. If the tap gesture
    /// did not win, [onTertiaryTapCancel] is called instead.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    public let onTertiaryTapUp: GestureTapUpCallback?

    /// The pointer that previously triggered [onTertiaryTapDown] will not end up
    /// causing a tap.
    ///
    /// This is called after [onTertiaryTapDown], and instead of
    /// [onTertiaryTapUp], if the tap gesture did not win.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    public let onTertiaryTapCancel: GestureTapCancelCallback?

    /// A pointer that might cause a double tap has contacted the screen at a
    /// particular location.
    ///
    /// Triggered immediately after the down event of the second tap.
    ///
    /// If the user completes the double tap and the gesture wins, [onDoubleTap]
    /// will be called after this callback. Otherwise, [onDoubleTapCancel] will
    /// be called after this callback.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    // let onDoubleTapDown: GestureTapDownCallback?

    /// The user has tapped the screen with a primary button at the same location
    /// twice in quick succession.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    // let onDoubleTap: GestureTapCallback?

    /// The pointer that previously triggered [onDoubleTapDown] will not end up
    /// causing a double tap.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    // let onDoubleTapCancel: GestureTapCancelCallback?

    /// The pointer has contacted the screen with a primary button, which might
    /// be the start of a long-press.
    ///
    /// This triggers after the pointer down event.
    ///
    /// If the user completes the long-press, and this gesture wins,
    /// [onLongPressStart] will be called after this callback. Otherwise,
    /// [onLongPressCancel] will be called after this callback.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [onSecondaryLongPressDown], a similar callback but for a secondary button.
    ///  * [onTertiaryLongPressDown], a similar callback but for a tertiary button.
    ///  * [LongPressGestureRecognizer.onLongPressDown], which exposes this
    ///    callback at the gesture layer.
    // let onLongPressDown: GestureLongPressDownCallback?

    /// A pointer that previously triggered [onLongPressDown] will not end up
    /// causing a long-press.
    ///
    /// This triggers once the gesture loses if [onLongPressDown] has previously
    /// been triggered.
    ///
    /// If the user completed the long-press, and the gesture won, then
    /// [onLongPressStart] and [onLongPress] are called instead.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onLongPressCancel], which exposes this
    ///    callback at the gesture layer.
    // let onLongPressCancel: GestureLongPressCancelCallback?

    /// Called when a long press gesture with a primary button has been recognized.
    ///
    /// Triggered when a pointer has remained in contact with the screen at the
    /// same location for a long period of time.
    ///
    /// This is equivalent to (and is called immediately after) [onLongPressStart].
    /// The only difference between the two is that this callback does not
    /// contain details of the position at which the pointer initially contacted
    /// the screen.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onLongPress], which exposes this
    ///    callback at the gesture layer.
    // let onLongPress: GestureLongPressCallback?

    /// Called when a long press gesture with a primary button has been recognized.
    ///
    /// Triggered when a pointer has remained in contact with the screen at the
    /// same location for a long period of time.
    ///
    /// This is equivalent to (and is called immediately before) [onLongPress].
    /// The only difference between the two is that this callback contains
    /// details of the position at which the pointer initially contacted the
    /// screen, whereas [onLongPress] does not.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onLongPressStart], which exposes this
    ///    callback at the gesture layer.
    // let onLongPressStart: GestureLongPressStartCallback?

    /// A pointer has been drag-moved after a long-press with a primary button.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onLongPressMoveUpdate], which exposes this
    ///    callback at the gesture layer.
    // let onLongPressMoveUpdate: GestureLongPressMoveUpdateCallback?

    /// A pointer that has triggered a long-press with a primary button has
    /// stopped contacting the screen.
    ///
    /// This is equivalent to (and is called immediately after) [onLongPressEnd].
    /// The only difference between the two is that this callback does not
    /// contain details of the state of the pointer when it stopped contacting
    /// the screen.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onLongPressUp], which exposes this
    ///    callback at the gesture layer.
    // let onLongPressUp: GestureLongPressUpCallback?

    /// A pointer that has triggered a long-press with a primary button has
    /// stopped contacting the screen.
    ///
    /// This is equivalent to (and is called immediately before) [onLongPressUp].
    /// The only difference between the two is that this callback contains
    /// details of the state of the pointer when it stopped contacting the
    /// screen, whereas [onLongPressUp] does not.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onLongPressEnd], which exposes this
    ///    callback at the gesture layer.
    // let onLongPressEnd: GestureLongPressEndCallback?

    /// The pointer has contacted the screen with a secondary button, which might
    /// be the start of a long-press.
    ///
    /// This triggers after the pointer down event.
    ///
    /// If the user completes the long-press, and this gesture wins,
    /// [onSecondaryLongPressStart] will be called after this callback. Otherwise,
    /// [onSecondaryLongPressCancel] will be called after this callback.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [onLongPressDown], a similar callback but for a secondary button.
    ///  * [onTertiaryLongPressDown], a similar callback but for a tertiary button.
    ///  * [LongPressGestureRecognizer.onSecondaryLongPressDown], which exposes
    ///    this callback at the gesture layer.
    // let onSecondaryLongPressDown: GestureLongPressDownCallback?

    /// A pointer that previously triggered [onSecondaryLongPressDown] will not
    /// end up causing a long-press.
    ///
    /// This triggers once the gesture loses if [onSecondaryLongPressDown] has
    /// previously been triggered.
    ///
    /// If the user completed the long-press, and the gesture won, then
    /// [onSecondaryLongPressStart] and [onSecondaryLongPress] are called instead.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onSecondaryLongPressCancel], which exposes
    ///    this callback at the gesture layer.
    // let onSecondaryLongPressCancel: GestureLongPressCancelCallback?

    /// Called when a long press gesture with a secondary button has been
    /// recognized.
    ///
    /// Triggered when a pointer has remained in contact with the screen at the
    /// same location for a long period of time.
    ///
    /// This is equivalent to (and is called immediately after)
    /// [onSecondaryLongPressStart]. The only difference between the two is that
    /// this callback does not contain details of the position at which the
    /// pointer initially contacted the screen.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onSecondaryLongPress], which exposes
    ///    this callback at the gesture layer.
    // let onSecondaryLongPress: GestureLongPressCallback?

    /// Called when a long press gesture with a secondary button has been
    /// recognized.
    ///
    /// Triggered when a pointer has remained in contact with the screen at the
    /// same location for a long period of time.
    ///
    /// This is equivalent to (and is called immediately before)
    /// [onSecondaryLongPress]. The only difference between the two is that this
    /// callback contains details of the position at which the pointer initially
    /// contacted the screen, whereas [onSecondaryLongPress] does not.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onSecondaryLongPressStart], which exposes
    ///    this callback at the gesture layer.
    // let onSecondaryLongPressStart: GestureLongPressStartCallback?

    /// A pointer has been drag-moved after a long press with a secondary button.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onSecondaryLongPressMoveUpdate], which exposes
    ///    this callback at the gesture layer.
    // let onSecondaryLongPressMoveUpdate: GestureLongPressMoveUpdateCallback?

    /// A pointer that has triggered a long-press with a secondary button has
    /// stopped contacting the screen.
    ///
    /// This is equivalent to (and is called immediately after)
    /// [onSecondaryLongPressEnd]. The only difference between the two is that
    /// this callback does not contain details of the state of the pointer when
    /// it stopped contacting the screen.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onSecondaryLongPressUp], which exposes
    ///    this callback at the gesture layer.
    // let onSecondaryLongPressUp: GestureLongPressUpCallback?

    /// A pointer that has triggered a long-press with a secondary button has
    /// stopped contacting the screen.
    ///
    /// This is equivalent to (and is called immediately before)
    /// [onSecondaryLongPressUp]. The only difference between the two is that
    /// this callback contains details of the state of the pointer when it
    /// stopped contacting the screen, whereas [onSecondaryLongPressUp] does not.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onSecondaryLongPressEnd], which exposes
    ///    this callback at the gesture layer.
    // let onSecondaryLongPressEnd: GestureLongPressEndCallback?

    /// The pointer has contacted the screen with a tertiary button, which might
    /// be the start of a long-press.
    ///
    /// This triggers after the pointer down event.
    ///
    /// If the user completes the long-press, and this gesture wins,
    /// [onTertiaryLongPressStart] will be called after this callback. Otherwise,
    /// [onTertiaryLongPressCancel] will be called after this callback.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    ///  * [onLongPressDown], a similar callback but for a primary button.
    ///  * [onSecondaryLongPressDown], a similar callback but for a secondary button.
    ///  * [LongPressGestureRecognizer.onTertiaryLongPressDown], which exposes
    ///    this callback at the gesture layer.
    // let onTertiaryLongPressDown: GestureLongPressDownCallback?

    /// A pointer that previously triggered [onTertiaryLongPressDown] will not
    /// end up causing a long-press.
    ///
    /// This triggers once the gesture loses if [onTertiaryLongPressDown] has
    /// previously been triggered.
    ///
    /// If the user completed the long-press, and the gesture won, then
    /// [onTertiaryLongPressStart] and [onTertiaryLongPress] are called instead.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onTertiaryLongPressCancel], which exposes
    ///    this callback at the gesture layer.
    // let onTertiaryLongPressCancel: GestureLongPressCancelCallback?

    /// Called when a long press gesture with a tertiary button has been
    /// recognized.
    ///
    /// Triggered when a pointer has remained in contact with the screen at the
    /// same location for a long period of time.
    ///
    /// This is equivalent to (and is called immediately after)
    /// [onTertiaryLongPressStart]. The only difference between the two is that
    /// this callback does not contain details of the position at which the
    /// pointer initially contacted the screen.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onTertiaryLongPress], which exposes
    ///    this callback at the gesture layer.
    // let onTertiaryLongPress: GestureLongPressCallback?

    /// Called when a long press gesture with a tertiary button has been
    /// recognized.
    ///
    /// Triggered when a pointer has remained in contact with the screen at the
    /// same location for a long period of time.
    ///
    /// This is equivalent to (and is called immediately before)
    /// [onTertiaryLongPress]. The only difference between the two is that this
    /// callback contains details of the position at which the pointer initially
    /// contacted the screen, whereas [onTertiaryLongPress] does not.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onTertiaryLongPressStart], which exposes
    ///    this callback at the gesture layer.
    // let onTertiaryLongPressStart: GestureLongPressStartCallback?

    /// A pointer has been drag-moved after a long press with a tertiary button.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onTertiaryLongPressMoveUpdate], which exposes
    ///    this callback at the gesture layer.
    // let onTertiaryLongPressMoveUpdate: GestureLongPressMoveUpdateCallback?

    /// A pointer that has triggered a long-press with a tertiary button has
    /// stopped contacting the screen.
    ///
    /// This is equivalent to (and is called immediately after)
    /// [onTertiaryLongPressEnd]. The only difference between the two is that
    /// this callback does not contain details of the state of the pointer when
    /// it stopped contacting the screen.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onTertiaryLongPressUp], which exposes
    ///    this callback at the gesture layer.
    // let onTertiaryLongPressUp: GestureLongPressUpCallback?

    /// A pointer that has triggered a long-press with a tertiary button has
    /// stopped contacting the screen.
    ///
    /// This is equivalent to (and is called immediately before)
    /// [onTertiaryLongPressUp]. The only difference between the two is that
    /// this callback contains details of the state of the pointer when it
    /// stopped contacting the screen, whereas [onTertiaryLongPressUp] does not.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    ///  * [LongPressGestureRecognizer.onTertiaryLongPressEnd], which exposes
    ///    this callback at the gesture layer.
    // let onTertiaryLongPressEnd: GestureLongPressEndCallback?

    /// A pointer has contacted the screen with a primary button and might begin
    /// to move vertically.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onVerticalDragDown: GestureDragDownCallback?

    /// A pointer has contacted the screen with a primary button and has begun to
    /// move vertically.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onVerticalDragStart: GestureDragStartCallback?

    /// A pointer that is in contact with the screen with a primary button and
    /// moving vertically has moved in the vertical direction.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onVerticalDragUpdate: GestureDragUpdateCallback?

    /// A pointer that was previously in contact with the screen with a primary
    /// button and moving vertically is no longer in contact with the screen and
    /// was moving at a specific velocity when it stopped contacting the screen.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onVerticalDragEnd: GestureDragEndCallback?

    /// The pointer that previously triggered [onVerticalDragDown] did not
    /// complete.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onVerticalDragCancel: GestureDragCancelCallback?

    /// A pointer has contacted the screen with a primary button and might begin
    /// to move horizontally.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onHorizontalDragDown: GestureDragDownCallback?

    /// A pointer has contacted the screen with a primary button and has begun to
    /// move horizontally.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onHorizontalDragStart: GestureDragStartCallback?

    /// A pointer that is in contact with the screen with a primary button and
    /// moving horizontally has moved in the horizontal direction.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onHorizontalDragUpdate: GestureDragUpdateCallback?

    /// A pointer that was previously in contact with the screen with a primary
    /// button and moving horizontally is no longer in contact with the screen and
    /// was moving at a specific velocity when it stopped contacting the screen.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onHorizontalDragEnd: GestureDragEndCallback?

    /// The pointer that previously triggered [onHorizontalDragDown] did not
    /// complete.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onHorizontalDragCancel: GestureDragCancelCallback?

    /// A pointer has contacted the screen with a primary button and might begin
    /// to move.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onPanDown: GestureDragDownCallback?

    /// A pointer has contacted the screen with a primary button and has begun to
    /// move.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onPanStart: GestureDragStartCallback?

    /// A pointer that is in contact with the screen with a primary button and
    /// moving has moved again.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onPanUpdate: GestureDragUpdateCallback?

    /// A pointer that was previously in contact with the screen with a primary
    /// button and moving is no longer in contact with the screen and was moving
    /// at a specific velocity when it stopped contacting the screen.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onPanEnd: GestureDragEndCallback?

    /// The pointer that previously triggered [onPanDown] did not complete.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public let onPanCancel: GestureDragCancelCallback?

    /// The pointers in contact with the screen have established a focal point and
    /// initial scale of 1.0.
    // let onScaleStart: GestureScaleStartCallback?

    /// The pointers in contact with the screen have indicated a new focal point
    /// and/or scale.
    // let onScaleUpdate: GestureScaleUpdateCallback?

    /// The pointers are no longer in contact with the screen.
    // let onScaleEnd: GestureScaleEndCallback?

    /// The pointer is in contact with the screen and has pressed with sufficient
    /// force to initiate a force press. The amount of force is at least
    /// [ForcePressGestureRecognizer.startPressure].
    ///
    /// This callback will only be fired on devices with pressure
    /// detecting screens.
    // let onForcePressStart: GestureForcePressStartCallback?

    /// The pointer is in contact with the screen and has pressed with the maximum
    /// force. The amount of force is at least
    /// [ForcePressGestureRecognizer.peakPressure].
    ///
    /// This callback will only be fired on devices with pressure
    /// detecting screens.
    // let onForcePressPeak: GestureForcePressPeakCallback?

    /// A pointer is in contact with the screen, has previously passed the
    /// [ForcePressGestureRecognizer.startPressure] and is either moving on the
    /// plane of the screen, pressing the screen with varying forces or both
    /// simultaneously.
    ///
    /// This callback will only be fired on devices with pressure
    /// detecting screens.
    // let onForcePressUpdate: GestureForcePressUpdateCallback?

    /// The pointer tracked by [onForcePressStart] is no longer in contact with the screen.
    ///
    /// This callback will only be fired on devices with pressure
    /// detecting screens.
    // let onForcePressEnd: GestureForcePressEndCallback?

    /// How this gesture detector should behave during hit testing when deciding
    /// how the hit test propagates to children and whether to consider targets
    /// behind this one.
    ///
    /// This defaults to [HitTestBehavior.deferToChild] if [child] is not null and
    /// [HitTestBehavior.translucent] if child is null.
    ///
    /// See [HitTestBehavior] for the allowed values and their meanings.
    public let behavior: HitTestBehavior?

    /// Determines the way that drag start behavior is handled.
    ///
    /// If set to [DragStartBehavior.start], gesture drag behavior will
    /// begin at the position where the drag gesture won the arena. If set to
    /// [DragStartBehavior.down] it will begin at the position where a down event
    /// is first detected.
    ///
    /// In general, setting this to [DragStartBehavior.start] will make drag
    /// animation smoother and setting it to [DragStartBehavior.down] will make
    /// drag behavior feel slightly more reactive.
    ///
    /// By default, the drag start behavior is [DragStartBehavior.start].
    ///
    /// Only the [DragGestureRecognizer.onStart] callbacks for the
    /// [VerticalDragGestureRecognizer], [HorizontalDragGestureRecognizer] and
    /// [PanGestureRecognizer] are affected by this setting.
    ///
    /// See also:
    ///
    ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for the different behaviors.
    public let dragStartBehavior: DragStartBehavior

    /// The kind of devices that are allowed to be recognized.
    ///
    /// If set to null, events from all device types will be recognized. Defaults to null.
    public let supportedDevices: Set<PointerDeviceKind>?

    /// The widget below this widget in the tree.
    public let child: Widget?

    public func build(context: BuildContext) -> Widget {
        var gestures: [GestureRecognizerFactory] = []
        // final DeviceGestureSettings? gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
        let gestureSettings: DeviceGestureSettings? = nil

        // if (onTapDown != null ||
        //     onTapUp != null ||
        //     onTap != null ||
        //     onTapCancel != null ||
        //     onSecondaryTap != null ||
        //     onSecondaryTapDown != null ||
        //     onSecondaryTapUp != null ||
        //     onSecondaryTapCancel != null||
        //     onTertiaryTapDown != null ||
        //     onTertiaryTapUp != null ||
        //     onTertiaryTapCancel != null
        // ) {
        //   gestures[TapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        //     () => TapGestureRecognizer(debugOwner: this, supportedDevices: supportedDevices),
        //     (TapGestureRecognizer instance) {
        //       instance
        //         ..onTapDown = onTapDown
        //         ..onTapUp = onTapUp
        //         ..onTap = onTap
        //         ..onTapCancel = onTapCancel
        //         ..onSecondaryTap = onSecondaryTap
        //         ..onSecondaryTapDown = onSecondaryTapDown
        //         ..onSecondaryTapUp = onSecondaryTapUp
        //         ..onSecondaryTapCancel = onSecondaryTapCancel
        //         ..onTertiaryTapDown = onTertiaryTapDown
        //         ..onTertiaryTapUp = onTertiaryTapUp
        //         ..onTertiaryTapCancel = onTertiaryTapCancel
        //         ..gestureSettings = gestureSettings
        //         ..supportedDevices = supportedDevices;
        //     },
        //   );
        // }
        if onTapDown != nil || onTapUp != nil || onTap != nil || onTapCancel != nil {
            gestures.append(
                CallbackGestureRecognizerFactory {
                    TapGestureRecognizer(debugOwner: self)
                } initializer: { instance in
                    instance.onTapDown = self.onTapDown
                    instance.onTapUp = self.onTapUp
                    instance.onTap = self.onTap
                    instance.onTapCancel = self.onTapCancel
                    instance.onSecondaryTap = self.onSecondaryTap
                    instance.onSecondaryTapDown = self.onSecondaryTapDown
                    instance.onSecondaryTapUp = self.onSecondaryTapUp
                    instance.onSecondaryTapCancel = self.onSecondaryTapCancel
                    instance.onTertiaryTapDown = self.onTertiaryTapDown
                    instance.onTertiaryTapUp = self.onTertiaryTapUp
                    instance.onTertiaryTapCancel = self.onTertiaryTapCancel
                    instance.gestureSettings = gestureSettings
                    instance.supportedDevices = self.supportedDevices
                }
            )
        }

        // if (onDoubleTap != null ||
        //     onDoubleTapDown != null ||
        //     onDoubleTapCancel != null) {
        //   gestures[DoubleTapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
        //     () => DoubleTapGestureRecognizer(debugOwner: this, supportedDevices: supportedDevices),
        //     (DoubleTapGestureRecognizer instance) {
        //       instance
        //         ..onDoubleTapDown = onDoubleTapDown
        //         ..onDoubleTap = onDoubleTap
        //         ..onDoubleTapCancel = onDoubleTapCancel
        //         ..gestureSettings = gestureSettings
        //         ..supportedDevices = supportedDevices;
        //     },
        //   );
        // }

        // if (onLongPressDown != null ||
        //     onLongPressCancel != null ||
        //     onLongPress != null ||
        //     onLongPressStart != null ||
        //     onLongPressMoveUpdate != null ||
        //     onLongPressUp != null ||
        //     onLongPressEnd != null ||
        //     onSecondaryLongPressDown != null ||
        //     onSecondaryLongPressCancel != null ||
        //     onSecondaryLongPress != null ||
        //     onSecondaryLongPressStart != null ||
        //     onSecondaryLongPressMoveUpdate != null ||
        //     onSecondaryLongPressUp != null ||
        //     onSecondaryLongPressEnd != null ||
        //     onTertiaryLongPressDown != null ||
        //     onTertiaryLongPressCancel != null ||
        //     onTertiaryLongPress != null ||
        //     onTertiaryLongPressStart != null ||
        //     onTertiaryLongPressMoveUpdate != null ||
        //     onTertiaryLongPressUp != null ||
        //     onTertiaryLongPressEnd != null) {
        //   gestures[LongPressGestureRecognizer] = GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        //     () => LongPressGestureRecognizer(debugOwner: this, supportedDevices: supportedDevices),
        //     (LongPressGestureRecognizer instance) {
        //       instance
        //         ..onLongPressDown = onLongPressDown
        //         ..onLongPressCancel = onLongPressCancel
        //         ..onLongPress = onLongPress
        //         ..onLongPressStart = onLongPressStart
        //         ..onLongPressMoveUpdate = onLongPressMoveUpdate
        //         ..onLongPressUp = onLongPressUp
        //         ..onLongPressEnd = onLongPressEnd
        //         ..onSecondaryLongPressDown = onSecondaryLongPressDown
        //         ..onSecondaryLongPressCancel = onSecondaryLongPressCancel
        //         ..onSecondaryLongPress = onSecondaryLongPress
        //         ..onSecondaryLongPressStart = onSecondaryLongPressStart
        //         ..onSecondaryLongPressMoveUpdate = onSecondaryLongPressMoveUpdate
        //         ..onSecondaryLongPressUp = onSecondaryLongPressUp
        //         ..onSecondaryLongPressEnd = onSecondaryLongPressEnd
        //         ..onTertiaryLongPressDown = onTertiaryLongPressDown
        //         ..onTertiaryLongPressCancel = onTertiaryLongPressCancel
        //         ..onTertiaryLongPress = onTertiaryLongPress
        //         ..onTertiaryLongPressStart = onTertiaryLongPressStart
        //         ..onTertiaryLongPressMoveUpdate = onTertiaryLongPressMoveUpdate
        //         ..onTertiaryLongPressUp = onTertiaryLongPressUp
        //         ..onTertiaryLongPressEnd = onTertiaryLongPressEnd
        //         ..gestureSettings = gestureSettings
        //         ..supportedDevices = supportedDevices;
        //     },
        //   );
        // }

        if onVerticalDragDown != nil || onVerticalDragStart != nil || onVerticalDragUpdate != nil
            || onVerticalDragEnd != nil || onVerticalDragCancel != nil
        {
            gestures.append(
                CallbackGestureRecognizerFactory {
                    VerticalDragGestureRecognizer(debugOwner: self)
                } initializer: { instance in
                    instance.onDown = self.onVerticalDragDown
                    instance.onStart = self.onVerticalDragStart
                    instance.onUpdate = self.onVerticalDragUpdate
                    instance.onEnd = self.onVerticalDragEnd
                    instance.onCancel = self.onVerticalDragCancel
                    instance.dragStartBehavior = self.dragStartBehavior
                    instance.gestureSettings = gestureSettings
                    instance.supportedDevices = self.supportedDevices
                }
            )
        }

        if onHorizontalDragDown != nil || onHorizontalDragStart != nil
            || onHorizontalDragUpdate != nil || onHorizontalDragEnd != nil
            || onHorizontalDragCancel != nil
        {
            gestures.append(
                CallbackGestureRecognizerFactory {
                    HorizontalDragGestureRecognizer(debugOwner: self)
                } initializer: { instance in
                    instance.onDown = self.onHorizontalDragDown
                    instance.onStart = self.onHorizontalDragStart
                    instance.onUpdate = self.onHorizontalDragUpdate
                    instance.onEnd = self.onHorizontalDragEnd
                    instance.onCancel = self.onHorizontalDragCancel
                    instance.dragStartBehavior = self.dragStartBehavior
                    instance.gestureSettings = gestureSettings
                    instance.supportedDevices = self.supportedDevices
                }
            )
        }

        if onPanDown != nil || onPanStart != nil || onPanUpdate != nil || onPanEnd != nil
            || onPanCancel != nil
        {
            gestures.append(
                CallbackGestureRecognizerFactory {
                    PanGestureRecognizer(debugOwner: self)
                } initializer: { instance in
                    instance.onDown = self.onPanDown
                    instance.onStart = self.onPanStart
                    instance.onUpdate = self.onPanUpdate
                    instance.onEnd = self.onPanEnd
                    instance.onCancel = self.onPanCancel
                    instance.dragStartBehavior = self.dragStartBehavior
                    instance.gestureSettings = gestureSettings
                    instance.supportedDevices = self.supportedDevices
                }
            )
        }
        // if (onScaleStart != null || onScaleUpdate != null || onScaleEnd != null) {
        //   gestures[ScaleGestureRecognizer] = GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
        //     () => ScaleGestureRecognizer(debugOwner: this, supportedDevices: supportedDevices),
        //     (ScaleGestureRecognizer instance) {
        //       instance
        //         ..onStart = onScaleStart
        //         ..onUpdate = onScaleUpdate
        //         ..onEnd = onScaleEnd
        //         ..dragStartBehavior = dragStartBehavior
        //         ..gestureSettings = gestureSettings
        //         ..trackpadScrollCausesScale = trackpadScrollCausesScale
        //         ..trackpadScrollToScaleFactor = trackpadScrollToScaleFactor
        //         ..supportedDevices = supportedDevices;
        //     },
        //   );
        // }

        // if (onForcePressStart != null ||
        //     onForcePressPeak != null ||
        //     onForcePressUpdate != null ||
        //     onForcePressEnd != null) {
        //   gestures[ForcePressGestureRecognizer] = GestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
        //     () => ForcePressGestureRecognizer(debugOwner: this, supportedDevices: supportedDevices),
        //     (ForcePressGestureRecognizer instance) {
        //       instance
        //         ..onStart = onForcePressStart
        //         ..onPeak = onForcePressPeak
        //         ..onUpdate = onForcePressUpdate
        //         ..onEnd = onForcePressEnd
        //         ..gestureSettings = gestureSettings
        //         ..supportedDevices = supportedDevices;
        //     },
        //   );
        // }

        return RawGestureDetector(
            gestures: gestures,
            behavior: behavior
                //   excludeFromSemantics: excludeFromSemantics,
        ) {
            child ?? Text("TODO")
        }
    }
}

extension Widget {
    public func gesture(
        onTapDown: GestureTapDownCallback? = nil,
        onTapUp: GestureTapUpCallback? = nil,
        onTap: GestureTapCallback? = nil,
        onTapCancel: GestureTapCancelCallback? = nil,
        onSecondaryTap: GestureTapCallback? = nil,
        onSecondaryTapDown: GestureTapDownCallback? = nil,
        onSecondaryTapUp: GestureTapUpCallback? = nil,
        onSecondaryTapCancel: GestureTapCancelCallback? = nil
    ) -> GestureDetector {
        GestureDetector(
            onTapDown: onTapDown,
            onTapUp: onTapUp,
            onTap: onTap,
            onTapCancel: onTapCancel,
            onSecondaryTap: onSecondaryTap,
            onSecondaryTapDown: onSecondaryTapDown,
            onSecondaryTapUp: onSecondaryTapUp,
            onSecondaryTapCancel: onSecondaryTapCancel,
        ) {
            self
        }
    }
}
