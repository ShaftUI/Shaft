// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Callback signature for [LongPressGestureRecognizer.onLongPressDown].
///
/// Called when a pointer that might cause a long-press has contacted the
/// screen. The position at which the pointer contacted the screen is available
/// in the `details`.
///
/// See also:
///
///  * [GestureDetector.onLongPressDown], which matches this signature.
///  * [GestureLongPressStartCallback], the signature that gets called when the
///    pointer has been in contact with the screen long enough to be considered
///    a long-press.
public typealias GestureLongPressDownCallback = (LongPressDownDetails) -> Void

/// Callback signature for [LongPressGestureRecognizer.onLongPressCancel].
///
/// Called when the pointer that previously triggered a
/// [GestureLongPressDownCallback] will not end up causing a long-press.
///
/// See also:
///
///  * [GestureDetector.onLongPressCancel], which matches this signature.
public typealias GestureLongPressCancelCallback = () -> Void

/// Callback signature for [LongPressGestureRecognizer.onLongPress].
///
/// Called when a pointer has remained in contact with the screen at the
/// same location for a long period of time.
///
/// See also:
///
///  * [GestureDetector.onLongPress], which matches this signature.
///  * [GestureLongPressStartCallback], which is the same signature but with
///    details of where the long press occurred.
public typealias GestureLongPressCallback = () -> Void

/// Callback signature for [LongPressGestureRecognizer.onLongPressUp].
///
/// Called when a pointer stops contacting the screen after a long press
/// gesture was detected.
///
/// See also:
///
///  * [GestureDetector.onLongPressUp], which matches this signature.
public typealias GestureLongPressUpCallback = () -> Void

/// Callback signature for [LongPressGestureRecognizer.onLongPressStart].
///
/// Called when a pointer has remained in contact with the screen at the
/// same location for a long period of time. Also reports the long press down
/// position.
///
/// See also:
///
///  * [GestureDetector.onLongPressStart], which matches this signature.
///  * [GestureLongPressCallback], which is the same signature without the
///    details.
public typealias GestureLongPressStartCallback = (LongPressStartDetails) -> Void

/// Callback signature for [LongPressGestureRecognizer.onLongPressMoveUpdate].
///
/// Called when a pointer is moving after being held in contact at the same
/// location for a long period of time. Reports the new position and its offset
/// from the original down position.
///
/// See also:
///
///  * [GestureDetector.onLongPressMoveUpdate], which matches this signature.
public typealias GestureLongPressMoveUpdateCallback = (LongPressMoveUpdateDetails) -> Void

/// Callback signature for [LongPressGestureRecognizer.onLongPressEnd].
///
/// Called when a pointer stops contacting the screen after a long press
/// gesture was detected. Also reports the position where the pointer stopped
/// contacting the screen.
///
/// See also:
///
///  * [GestureDetector.onLongPressEnd], which matches this signature.
public typealias GestureLongPressEndCallback = (LongPressEndDetails) -> Void

/// Details for callbacks that use [GestureLongPressDownCallback].
///
/// See also:
///
///  * [LongPressGestureRecognizer.onLongPressDown], whose callback passes
///    these details.
///  * [LongPressGestureRecognizer.onSecondaryLongPressDown], whose callback
///    passes these details.
///  * [LongPressGestureRecognizer.onTertiaryLongPressDown], whose callback
///    passes these details.
public struct LongPressDownDetails {
    /// Creates the details for a [GestureLongPressDownCallback].
    ///
    /// If the `localPosition` argument is not specified, it will default to the
    /// global position.
    init(
        globalPosition: Offset = .zero,
        localPosition: Offset? = nil,
        kind: PointerDeviceKind? = nil
    ) {
        self.globalPosition = globalPosition
        self.localPosition = localPosition ?? globalPosition
        self.kind = kind
    }

    /// The global position at which the pointer contacted the screen.
    public let globalPosition: Offset

    /// The kind of the device that initiated the event.
    public let kind: PointerDeviceKind?

    /// The local position at which the pointer contacted the screen.
    public let localPosition: Offset
}

/// Details for callbacks that use [GestureLongPressStartCallback].
///
/// See also:
///
///  * [LongPressGestureRecognizer.onLongPressStart], which uses [GestureLongPressStartCallback].
///  * [LongPressMoveUpdateDetails], the details for [GestureLongPressMoveUpdateCallback]
///  * [LongPressEndDetails], the details for [GestureLongPressEndCallback].
public struct LongPressStartDetails {
    /// Creates the details for a [GestureLongPressStartCallback].
    ///
    /// If the `localPosition` argument is not specified, it will default to the
    /// global position.
    public init(globalPosition: Offset = .zero, localPosition: Offset? = nil) {
        self.globalPosition = globalPosition
        self.localPosition = localPosition ?? globalPosition
    }

    /// The global position at which the pointer initially contacted the screen.
    public let globalPosition: Offset

    /// The local position at which the pointer initially contacted the screen.
    public let localPosition: Offset
}

/// Details for callbacks that use [GestureLongPressMoveUpdateCallback].
///
/// See also:
///
///  * [LongPressGestureRecognizer.onLongPressMoveUpdate], which uses [GestureLongPressMoveUpdateCallback].
///  * [LongPressEndDetails], the details for [GestureLongPressEndCallback]
///  * [LongPressStartDetails], the details for [GestureLongPressStartCallback].
public struct LongPressMoveUpdateDetails {
    /// Creates the details for a [GestureLongPressMoveUpdateCallback].
    ///
    /// If the `localPosition` argument is not specified, it will default to the
    /// global position.
    public init(
        globalPosition: Offset = .zero,
        localPosition: Offset? = nil,
        offsetFromOrigin: Offset = .zero,
        localOffsetFromOrigin: Offset? = nil
    ) {
        self.globalPosition = globalPosition
        self.localPosition = localPosition ?? globalPosition
        self.offsetFromOrigin = offsetFromOrigin
        self.localOffsetFromOrigin = localOffsetFromOrigin ?? offsetFromOrigin
    }

    /// The global position of the pointer when it triggered this update.
    public let globalPosition: Offset

    /// The local position of the pointer when it triggered this update.
    public let localPosition: Offset

    /// A delta offset from the point where the long press drag initially contacted
    /// the screen to the point where the pointer is currently located (the
    /// present [globalPosition]) when this callback is triggered.
    public let offsetFromOrigin: Offset

    /// A local delta offset from the point where the long press drag initially contacted
    /// the screen to the point where the pointer is currently located (the
    /// present [localPosition]) when this callback is triggered.
    public let localOffsetFromOrigin: Offset
}

/// Details for callbacks that use [GestureLongPressEndCallback].
///
/// See also:
///
///  * [LongPressGestureRecognizer.onLongPressEnd], which uses [GestureLongPressEndCallback].
///  * [LongPressMoveUpdateDetails], the details for [GestureLongPressMoveUpdateCallback].
///  * [LongPressStartDetails], the details for [GestureLongPressStartCallback].
public struct LongPressEndDetails {
    /// Creates the details for a [GestureLongPressEndCallback].
    public init(
        globalPosition: Offset = .zero,
        localPosition: Offset? = nil,
        velocity: Velocity = .zero
    ) {
        self.globalPosition = globalPosition
        self.localPosition = localPosition ?? globalPosition
        self.velocity = velocity
    }

    /// The global position at which the pointer lifted from the screen.
    public let globalPosition: Offset

    /// The local position at which the pointer contacted the screen.
    public let localPosition: Offset

    /// The pointer's velocity when it stopped contacting the screen.
    ///
    /// Defaults to zero if not specified in the constructor.
    public let velocity: Velocity
}

/// Recognizes when the user has pressed down at the same location for a long
/// period of time.
///
/// The gesture must not deviate in position from its touch down point for 500ms
/// until it's recognized. Once the gesture is accepted, the finger can be
/// moved, triggering [onLongPressMoveUpdate] callbacks, unless the
/// [postAcceptSlopTolerance] constructor argument is specified.
///
/// [LongPressGestureRecognizer] may compete on pointer events of
/// [PointerButtons.primaryButton], [PointerButtons.secondaryButton], and/or [PointerButtons.tertiaryButton] if at least
/// one corresponding callback is non-nil. If it has no callbacks, it is a
/// no-op.
public class LongPressGestureRecognizer: PrimaryPointerGestureRecognizer {
    /// Creates a long-press gesture recognizer.
    ///
    /// Consider assigning the [onLongPressStart] callback after creating this
    /// object.
    ///
    /// The [postAcceptSlopTolerance] argument can be used to specify a maximum
    /// allowed distance for the gesture to deviate from the starting point once
    /// the long press has triggered. If the gesture deviates past that point,
    /// subsequent callbacks ([onLongPressMoveUpdate], [onLongPressUp],
    /// [onLongPressEnd]) will stop. Defaults to nil, which means the gesture
    /// can be moved without limit once the long press is accepted.
    ///
    /// The [duration] argument can be used to overwrite the default duration
    /// after which the long press will be recognized.
    public init(
        duration: Duration? = nil,
        postAcceptSlopTolerance: Float? = nil,
        supportedDevices: Set<PointerDeviceKind>? = nil,
        debugOwner: AnyObject? = nil,
        allowedButtonsFilter: AllowedButtonsFilter? = nil
    ) {
        super.init(
            debugOwner: debugOwner,
            deadline: duration ?? kLongPressTimeout,
            postAcceptSlopTolerance: postAcceptSlopTolerance,
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter ?? Self.defaultButtonAcceptBehavior
        )
    }

    private var longPressAccepted = false

    private var longPressOrigin: OffsetPair?

    // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
    // different set of buttons, the gesture is canceled.
    private var initialButtons: PointerButtons?

    public var velocityTracker: VelocityTracker?

    // Accept the input if, and only if, a single button is pressed.
    static private func defaultButtonAcceptBehavior(buttons: PointerButtons) -> Bool {
        buttons == .primaryButton || buttons == .secondaryButton
            || buttons == .tertiaryButton
    }

    /// Called when a pointer has contacted the screen at a particular location
    /// with a primary button, which might be the start of a long-press.
    ///
    /// This triggers after the pointer down event.
    ///
    /// If this recognizer doesn't win the arena, [onLongPressCancel] is called
    /// next. Otherwise, [onLongPressStart] is called next.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.primaryButton], the button this callback responds to.
    ///  * [onSecondaryLongPressDown], a similar callback but for a secondary button.
    ///  * [onTertiaryLongPressDown], a similar callback but for a tertiary button.
    ///  * [LongPressDownDetails], which is passed as an argument to this callback.
    ///  * [GestureDetector.onLongPressDown], which exposes this callback in a widget.
    public var onLongPressDown: GestureLongPressDownCallback?

    /// Called when a pointer that previously triggered [onLongPressDown] will
    /// not end up causing a long-press.
    ///
    /// This triggers once the gesture loses the arena if [onLongPressDown] has
    /// previously been triggered.
    ///
    /// If this recognizer wins the arena, [onLongPressStart] and [onLongPress]
    /// are called instead.
    ///
    /// If the gesture is deactivated due to [postAcceptSlopTolerance] having
    /// been exceeded, this callback will not be called, since the gesture will
    /// have already won the arena at that point.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.primaryButton], the button this callback responds to.
    public var onLongPressCancel: GestureLongPressCancelCallback?

    /// Called when a long press gesture by a primary button has been recognized.
    ///
    /// This is equivalent to (and is called immediately after) [onLongPressStart].
    /// The only difference between the two is that this callback does not
    /// contain details of the position at which the pointer initially contacted
    /// the screen.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.primaryButton], the button this callback responds to.
    public var onLongPress: GestureLongPressCallback?

    /// Called when a long press gesture by a primary button has been recognized.
    ///
    /// This is equivalent to (and is called immediately before) [onLongPress].
    /// The only difference between the two is that this callback contains
    /// details of the position at which the pointer initially contacted the
    /// screen, whereas [onLongPress] does not.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.primaryButton], the button this callback responds to.
    ///  * [LongPressStartDetails], which is passed as an argument to this callback.
    public var onLongPressStart: GestureLongPressStartCallback?

    /// Called when moving after the long press by a primary button is recognized.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.primaryButton], the button this callback responds to.
    ///  * [LongPressMoveUpdateDetails], which is passed as an argument to this
    ///    callback.
    public var onLongPressMoveUpdate: GestureLongPressMoveUpdateCallback?

    /// Called when the pointer stops contacting the screen after a long-press
    /// by a primary button.
    ///
    /// This is equivalent to (and is called immediately after) [onLongPressEnd].
    /// The only difference between the two is that this callback does not
    /// contain details of the state of the pointer when it stopped contacting
    /// the screen.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.primaryButton], the button this callback responds to.
    public var onLongPressUp: GestureLongPressUpCallback?

    /// Called when the pointer stops contacting the screen after a long-press
    /// by a primary button.
    ///
    /// This is equivalent to (and is called immediately before) [onLongPressUp].
    /// The only difference between the two is that this callback contains
    /// details of the state of the pointer when it stopped contacting the
    /// screen, whereas [onLongPressUp] does not.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.primaryButton], the button this callback responds to.
    ///  * [LongPressEndDetails], which is passed as an argument to this
    ///    callback.
    public var onLongPressEnd: GestureLongPressEndCallback?

    /// Called when a pointer has contacted the screen at a particular location
    /// with a secondary button, which might be the start of a long-press.
    ///
    /// This triggers after the pointer down event.
    ///
    /// If this recognizer doesn't win the arena, [onSecondaryLongPressCancel] is
    /// called next. Otherwise, [onSecondaryLongPressStart] is called next.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.secondaryButton], the button this callback responds to.
    ///  * [onLongPressDown], a similar callback but for a primary button.
    ///  * [onTertiaryLongPressDown], a similar callback but for a tertiary button.
    ///  * [LongPressDownDetails], which is passed as an argument to this callback.
    ///  * [GestureDetector.onSecondaryLongPressDown], which exposes this callback
    ///    in a widget.
    public var onSecondaryLongPressDown: GestureLongPressDownCallback?

    /// Called when a pointer that previously triggered [onSecondaryLongPressDown]
    /// will not end up causing a long-press.
    ///
    /// This triggers once the gesture loses the arena if
    /// [onSecondaryLongPressDown] has previously been triggered.
    ///
    /// If this recognizer wins the arena, [onSecondaryLongPressStart] and
    /// [onSecondaryLongPress] are called instead.
    ///
    /// If the gesture is deactivated due to [postAcceptSlopTolerance] having
    /// been exceeded, this callback will not be called, since the gesture will
    /// have already won the arena at that point.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.secondaryButton], the button this callback responds to.
    public var onSecondaryLongPressCancel: GestureLongPressCancelCallback?

    /// Called when a long press gesture by a secondary button has been
    /// recognized.
    ///
    /// This is equivalent to (and is called immediately after)
    /// [onSecondaryLongPressStart]. The only difference between the two is that
    /// this callback does not contain details of the position at which the
    /// pointer initially contacted the screen.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.secondaryButton], the button this callback responds to.
    public var onSecondaryLongPress: GestureLongPressCallback?

    /// Called when a long press gesture by a secondary button has been recognized.
    ///
    /// This is equivalent to (and is called immediately before)
    /// [onSecondaryLongPress]. The only difference between the two is that this
    /// callback contains details of the position at which the pointer initially
    /// contacted the screen, whereas [onSecondaryLongPress] does not.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.secondaryButton], the button this callback responds to.
    ///  * [LongPressStartDetails], which is passed as an argument to this
    ///    callback.
    public var onSecondaryLongPressStart: GestureLongPressStartCallback?

    /// Called when moving after the long press by a secondary button is
    /// recognized.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.secondaryButton], the button this callback responds to.
    ///  * [LongPressMoveUpdateDetails], which is passed as an argument to this
    ///    callback.
    public var onSecondaryLongPressMoveUpdate: GestureLongPressMoveUpdateCallback?

    /// Called when the pointer stops contacting the screen after a long-press by
    /// a secondary button.
    ///
    /// This is equivalent to (and is called immediately after)
    /// [onSecondaryLongPressEnd]. The only difference between the two is that
    /// this callback does not contain details of the state of the pointer when
    /// it stopped contacting the screen.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.secondaryButton], the button this callback responds to.
    public var onSecondaryLongPressUp: GestureLongPressUpCallback?

    /// Called when the pointer stops contacting the screen after a long-press by
    /// a secondary button.
    ///
    /// This is equivalent to (and is called immediately before)
    /// [onSecondaryLongPressUp]. The only difference between the two is that
    /// this callback contains details of the state of the pointer when it
    /// stopped contacting the screen, whereas [onSecondaryLongPressUp] does not.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.secondaryButton], the button this callback responds to.
    ///  * [LongPressEndDetails], which is passed as an argument to this callback.
    public var onSecondaryLongPressEnd: GestureLongPressEndCallback?

    /// Called when a pointer has contacted the screen at a particular location
    /// with a tertiary button, which might be the start of a long-press.
    ///
    /// This triggers after the pointer down event.
    ///
    /// If this recognizer doesn't win the arena, [onTertiaryLongPressCancel] is
    /// called next. Otherwise, [onTertiaryLongPressStart] is called next.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.tertiaryButton], the button this callback responds to.
    ///  * [onLongPressDown], a similar callback but for a primary button.
    ///  * [onSecondaryLongPressDown], a similar callback but for a secondary button.
    ///  * [LongPressDownDetails], which is passed as an argument to this callback.
    ///  * [GestureDetector.onTertiaryLongPressDown], which exposes this callback
    ///    in a widget.
    public var onTertiaryLongPressDown: GestureLongPressDownCallback?

    /// Called when a pointer that previously triggered [onTertiaryLongPressDown]
    /// will not end up causing a long-press.
    ///
    /// This triggers once the gesture loses the arena if
    /// [onTertiaryLongPressDown] has previously been triggered.
    ///
    /// If this recognizer wins the arena, [onTertiaryLongPressStart] and
    /// [onTertiaryLongPress] are called instead.
    ///
    /// If the gesture is deactivated due to [postAcceptSlopTolerance] having
    /// been exceeded, this callback will not be called, since the gesture will
    /// have already won the arena at that point.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.tertiaryButton], the button this callback responds to.
    public var onTertiaryLongPressCancel: GestureLongPressCancelCallback?

    /// Called when a long press gesture by a tertiary button has been
    /// recognized.
    ///
    /// This is equivalent to (and is called immediately after)
    /// [onTertiaryLongPressStart]. The only difference between the two is that
    /// this callback does not contain details of the position at which the
    /// pointer initially contacted the screen.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.tertiaryButton], the button this callback responds to.
    public var onTertiaryLongPress: GestureLongPressCallback?

    /// Called when a long press gesture by a tertiary button has been recognized.
    ///
    /// This is equivalent to (and is called immediately before)
    /// [onTertiaryLongPress]. The only difference between the two is that this
    /// callback contains details of the position at which the pointer initially
    /// contacted the screen, whereas [onTertiaryLongPress] does not.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.tertiaryButton], the button this callback responds to.
    ///  * [LongPressStartDetails], which is passed as an argument to this
    ///    callback.
    public var onTertiaryLongPressStart: GestureLongPressStartCallback?

    /// Called when moving after the long press by a tertiary button is
    /// recognized.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.tertiaryButton], the button this callback responds to.
    ///  * [LongPressMoveUpdateDetails], which is passed as an argument to this
    ///    callback.
    public var onTertiaryLongPressMoveUpdate: GestureLongPressMoveUpdateCallback?

    /// Called when the pointer stops contacting the screen after a long-press by
    /// a tertiary button.
    ///
    /// This is equivalent to (and is called immediately after)
    /// [onTertiaryLongPressEnd]. The only difference between the two is that
    /// this callback does not contain details of the state of the pointer when
    /// it stopped contacting the screen.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.tertiaryButton], the button this callback responds to.
    public var onTertiaryLongPressUp: GestureLongPressUpCallback?

    /// Called when the pointer stops contacting the screen after a long-press by
    /// a tertiary button.
    ///
    /// This is equivalent to (and is called immediately before)
    /// [onTertiaryLongPressUp]. The only difference between the two is that
    /// this callback contains details of the state of the pointer when it
    /// stopped contacting the screen, whereas [onTertiaryLongPressUp] does not.
    ///
    /// See also:
    ///
    ///  * [PointerButtons.tertiaryButton], the button this callback responds to.
    ///  * [LongPressEndDetails], which is passed as an argument to this callback.
    public var onTertiaryLongPressEnd: GestureLongPressEndCallback?

    public override func isPointerAllowed(event: PointerDownEvent) -> Bool {
        switch event.buttons {
        case .primaryButton:
            if onLongPressDown == nil && onLongPressCancel == nil && onLongPressStart == nil
                && onLongPress == nil && onLongPressMoveUpdate == nil && onLongPressEnd == nil
                && onLongPressUp == nil
            {
                return false
            }
        case .secondaryButton:
            if onSecondaryLongPressDown == nil && onSecondaryLongPressCancel == nil
                && onSecondaryLongPressStart == nil && onSecondaryLongPress == nil
                && onSecondaryLongPressMoveUpdate == nil && onSecondaryLongPressEnd == nil
                && onSecondaryLongPressUp == nil
            {
                return false
            }
        case .tertiaryButton:
            if onTertiaryLongPressDown == nil && onTertiaryLongPressCancel == nil
                && onTertiaryLongPressStart == nil && onTertiaryLongPress == nil
                && onTertiaryLongPressMoveUpdate == nil && onTertiaryLongPressEnd == nil
                && onTertiaryLongPressUp == nil
            {
                return false
            }
        default:
            return false
        }
        return super.isPointerAllowed(event: event)
    }

    public override func didExceedDeadline() {
        // Exceeding the deadline puts the gesture in the accepted state.
        resolve(GestureDisposition.accepted)
        longPressAccepted = true
        super.acceptGesture(pointer: primaryPointer!)
        checkLongPressStart()
    }

    public override func handlePrimaryPointer(event: PointerEvent) {
        if event is PointerDownEvent {
            velocityTracker = VelocityTracker(kind: event.kind)
            velocityTracker!.addPosition(event.timeStamp, event.localPosition)
        }
        if event is PointerMoveEvent {
            assert(velocityTracker != nil)
            velocityTracker!.addPosition(event.timeStamp, event.localPosition)
        }

        if event is PointerUpEvent {
            if longPressAccepted {
                checkLongPressEnd(event)
            } else {
                // Pointer is lifted before timeout.
                resolve(GestureDisposition.rejected)
            }
            reset()
        } else if event is PointerCancelEvent {
            checkLongPressCancel()
            reset()
        } else if let event = event as? PointerDownEvent {
            // The first touch.
            longPressOrigin = OffsetPair(fromEventPosition: event)
            initialButtons = event.buttons
            checkLongPressDown(event)
        } else if event is PointerMoveEvent {
            if event.buttons != initialButtons && !longPressAccepted {
                resolve(GestureDisposition.rejected)
                stopTrackingPointer(primaryPointer!)
            } else if longPressAccepted {
                checkLongPressMoveUpdate(event)
            }
        }
    }

    private func checkLongPressDown(_ event: PointerDownEvent) {
        assert(longPressOrigin != nil)
        let details = LongPressDownDetails(
            globalPosition: longPressOrigin!.global,
            localPosition: longPressOrigin!.local,
            kind: getKindForPointer(pointer: event.pointer)
        )
        switch initialButtons {
        case .primaryButton:
            if onLongPressDown != nil {
                invokeCallback("onLongPressDown") { onLongPressDown!(details) }
            }
        case .secondaryButton:
            if onSecondaryLongPressDown != nil {
                invokeCallback("onSecondaryLongPressDown") { onSecondaryLongPressDown!(details) }
            }
        case .tertiaryButton:
            if onTertiaryLongPressDown != nil {
                invokeCallback("onTertiaryLongPressDown") { onTertiaryLongPressDown!(details) }
            }
        default:
            assertionFailure("Unhandled button \(String(describing: initialButtons))")
        }
    }

    func checkLongPressCancel() {
        if state == .possible {
            switch initialButtons {
            case .primaryButton:
                if onLongPressCancel != nil {
                    invokeCallback("onLongPressCancel", onLongPressCancel!)
                }
            case .secondaryButton:
                if onSecondaryLongPressCancel != nil {
                    invokeCallback("onSecondaryLongPressCancel", onSecondaryLongPressCancel!)
                }
            case .tertiaryButton:
                if onTertiaryLongPressCancel != nil {
                    invokeCallback("onTertiaryLongPressCancel", onTertiaryLongPressCancel!)
                }
            default:
                assertionFailure("Unhandled button \(String(describing: initialButtons))")
            }
        }
    }

    private func checkLongPressStart() {
        switch initialButtons {
        case .primaryButton:
            if let onLongPressStart {
                let details = LongPressStartDetails(
                    globalPosition: longPressOrigin!.global,
                    localPosition: longPressOrigin!.local
                )
                invokeCallback("onLongPressStart", { onLongPressStart(details) })
            }
            if let onLongPress {
                invokeCallback("onLongPress", onLongPress)
            }
        case .secondaryButton:
            if let onSecondaryLongPressStart {
                let details = LongPressStartDetails(
                    globalPosition: longPressOrigin!.global,
                    localPosition: longPressOrigin!.local
                )
                invokeCallback("onSecondaryLongPressStart", { onSecondaryLongPressStart(details) })
            }
            if let onSecondaryLongPress {
                invokeCallback("onSecondaryLongPress", onSecondaryLongPress)
            }
        case .tertiaryButton:
            if let onTertiaryLongPressStart {
                let details = LongPressStartDetails(
                    globalPosition: longPressOrigin!.global,
                    localPosition: longPressOrigin!.local
                )
                invokeCallback("onTertiaryLongPressStart", { onTertiaryLongPressStart(details) })
            }
            if let onTertiaryLongPress {
                invokeCallback("onTertiaryLongPress", onTertiaryLongPress)
            }
        default:
            assertionFailure("Unhandled button \(String(describing: initialButtons))")
        }
    }

    private func checkLongPressMoveUpdate(_ event: PointerEvent) {
        let details = LongPressMoveUpdateDetails(
            globalPosition: event.position,
            localPosition: event.localPosition,
            offsetFromOrigin: event.position - longPressOrigin!.global,
            localOffsetFromOrigin: event.localPosition - longPressOrigin!.local
        )
        switch initialButtons {
        case .primaryButton:
            if let onLongPressMoveUpdate {
                invokeCallback("onLongPressMoveUpdate") { onLongPressMoveUpdate(details) }
            }
        case .secondaryButton:
            if let onSecondaryLongPressMoveUpdate {
                invokeCallback("onSecondaryLongPressMoveUpdate") {
                    onSecondaryLongPressMoveUpdate(details)
                }
            }
        case .tertiaryButton:
            if let onTertiaryLongPressMoveUpdate {
                invokeCallback("onTertiaryLongPressMoveUpdate") {
                    onTertiaryLongPressMoveUpdate(details)
                }
            }
        default:
            assertionFailure("Unhandled button \(String(describing: initialButtons))")
        }
    }

    private func checkLongPressEnd(_ event: PointerEvent) {
        let estimate = velocityTracker!.getVelocityEstimate()
        let velocity =
            estimate == nil
            ? Velocity.zero
            : Velocity(pixelsPerSecond: estimate!.pixelsPerSecond)
        let details = LongPressEndDetails(
            globalPosition: event.position,
            localPosition: event.localPosition,
            velocity: velocity
        )

        velocityTracker = nil
        switch initialButtons {
        case .primaryButton:
            if let onLongPressEnd {
                invokeCallback("onLongPressEnd") { onLongPressEnd(details) }
            }
            if let onLongPressUp {
                invokeCallback("onLongPressUp", onLongPressUp)
            }
        case .secondaryButton:
            if let onSecondaryLongPressEnd {
                invokeCallback("onSecondaryLongPressEnd") {
                    onSecondaryLongPressEnd(details)
                }
            }
            if let onSecondaryLongPressUp {
                invokeCallback("onSecondaryLongPressUp", onSecondaryLongPressUp)
            }
        case .tertiaryButton:
            if let onTertiaryLongPressEnd {
                invokeCallback("onTertiaryLongPressEnd") {
                    onTertiaryLongPressEnd(details)
                }
            }
            if let onTertiaryLongPressUp {
                invokeCallback("onTertiaryLongPressUp", onTertiaryLongPressUp)
            }
        default:
            assertionFailure("Unhandled button \(String(describing: initialButtons))")
        }
    }

    private func reset() {
        longPressAccepted = false
        longPressOrigin = nil
        initialButtons = nil
        velocityTracker = nil
    }

    public override func resolve(_ disposition: GestureDisposition) {
        if disposition == .rejected {
            if longPressAccepted {
                // This can happen if the gesture has been canceled. For example when
                // the buttons have changed.
                reset()
            } else {
                checkLongPressCancel()
            }
        }
        super.resolve(disposition)
    }

    public override func acceptGesture(pointer: Int) {
        // Winning the arena isn't important here since it may happen from a sweep.
        // Explicitly exceeding the deadline puts the gesture in accepted state.
    }
}
