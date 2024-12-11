// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// Details for [GestureTapDownCallback], such as position.
///
/// See also:
///
///  * [GestureDetector.onTapDown], which receives this information.
///  * [TapGestureRecognizer], which passes this information to one of its callbacks.
public struct TapDownDetails {
    public init(
        globalPosition: Offset,
        localPosition: Offset? = nil,
        kind: PointerDeviceKind? = nil
    ) {
        self.globalPosition = globalPosition
        self.localPosition = localPosition ?? globalPosition
        self.kind = kind
    }

    /// The global position at which the pointer contacted the screen.
    public var globalPosition: Offset

    /// The local position at which the pointer contacted the screen.
    public var localPosition: Offset

    /// The kind of the device that initiated the event.
    public var kind: PointerDeviceKind?
}

/// Signature for when a pointer that might cause a tap has contacted the
/// screen.
///
/// The position at which the pointer contacted the screen is available in the
/// `details`.
///
/// See also:
///
///  * [GestureDetector.onTapDown], which matches this signature.
///  * [TapGestureRecognizer], which uses this signature in one of its callbacks.
public typealias GestureTapDownCallback = (TapDownDetails) -> Void

/// Details for [GestureTapUpCallback], such as position.
///
/// See also:
///
///  * [GestureDetector.onTapUp], which receives this information.
///  * [TapGestureRecognizer], which passes this information to one of its callbacks.
public struct TapUpDetails {
    /// The global position at which the pointer contacted the screen.
    public var globalPosition: Offset

    /// The local position at which the pointer contacted the screen.
    public var localPosition: Offset

    /// The kind of the device that initiated the event.
    public var kind: PointerDeviceKind
}

/// Signature for when a pointer that will trigger a tap has stopped contacting
/// the screen.
///
/// The position at which the pointer stopped contacting the screen is available
/// in the `details`.
///
/// See also:
///
///  * [GestureDetector.onTapUp], which matches this signature.
///  * [TapGestureRecognizer], which uses this signature in one of its callbacks.
public typealias GestureTapUpCallback = (TapUpDetails) -> Void

/// Signature for when a tap has occurred.
///
/// See also:
///
///  * [GestureDetector.onTap], which matches this signature.
///  * [TapGestureRecognizer], which uses this signature in one of its callbacks.
public typealias GestureTapCallback = () -> Void

/// Signature for when the pointer that previously triggered a
/// [GestureTapDownCallback] will not end up causing a tap.
///
/// See also:
///
///  * [GestureDetector.onTapCancel], which matches this signature.
///  * [TapGestureRecognizer], which uses this signature in one of its callbacks.
public typealias GestureTapCancelCallback = () -> Void

/// A base class for gesture recognizers that recognize taps.
///
/// Gesture recognizers take part in gesture arenas to enable potential gestures
/// to be disambiguated from each other. This process is managed by a
/// [GestureArenaManager].
///
/// A tap is defined as a sequence of events that starts with a down, followed
/// by optional moves, then ends with an up. All move events must contain the
/// same `buttons` as the down event, and must not be too far from the initial
/// position. The gesture is rejected on any violation, a cancel event, or
/// if any other recognizers wins the arena. It is accepted only when it is the
/// last member of the arena.
///
/// The [BaseTapGestureRecognizer] considers all the pointers involved in the
/// pointer event sequence as contributing to one gesture. For this reason,
/// extra pointer interactions during a tap sequence are not recognized as
/// additional taps. For example, down-1, down-2, up-1, up-2 produces only one
/// tap on up-1.
///
/// The [BaseTapGestureRecognizer] can not be directly used, since it does not
/// define which buttons to accept, or what to do when a tap happens. If you
/// want to build a custom tap recognizer, extend this class by overriding
/// [isPointerAllowed] and the handler methods.
///
/// See also:
///
///  * [TapGestureRecognizer], a ready-to-use tap recognizer that recognizes
///    taps of the primary button and taps of the secondary button.
///  * [ModalBarrier], a widget that uses a custom tap recognizer that accepts
///    any buttons.
open class BaseTapGestureRecognizer: PrimaryPointerGestureRecognizer {
    public init(
        debugOwner: AnyObject? = nil,
        supportedDevices: Set<PointerDeviceKind>?,
        allowedButtonsFilter: AllowedButtonsFilter?
    ) {
        super.init(
            debugOwner: debugOwner,
            deadline: kPressTimeout,
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter
        )
    }

    private var sentTapDown = false
    private var wonArenaForPrimaryPointer = false

    private var down: PointerDownEvent?
    private var up: PointerUpEvent?

    /// A pointer has contacted the screen, which might be the start of a tap.
    ///
    /// This triggers after the down event, once a short timeout ([deadline]) has
    /// elapsed, or once the gesture has won the arena, whichever comes first.
    ///
    /// The parameter `down` is the down event of the primary pointer that started
    /// the tap sequence.
    ///
    /// If this recognizer doesn't win the arena, [handleTapCancel] is called next.
    /// Otherwise, [handleTapUp] is called next.
    open func handleTapDown(down: PointerDownEvent) {}

    /// A pointer has stopped contacting the screen, which is recognized as a tap.
    ///
    /// This triggers on the up event if the recognizer wins the arena with it
    /// or has previously won.
    ///
    /// The parameter `down` is the down event of the primary pointer that started
    /// the tap sequence, and `up` is the up event that ended the tap sequence.
    ///
    /// If this recognizer doesn't win the arena, [handleTapCancel] is called
    /// instead.
    open func handleTapUp(down: PointerDownEvent, up: PointerUpEvent) {}

    /// A pointer that previously triggered [handleTapDown] will not end up
    /// causing a tap.
    ///
    /// This triggers once the gesture loses the arena if [handleTapDown] has
    /// been previously triggered.
    ///
    /// The parameter `down` is the down event of the primary pointer that started
    /// the tap sequence; `cancel` is the cancel event, which might be null;
    /// `reason` is a short description of the cause if `cancel` is null, which
    /// can be "forced" if other gestures won the arena, or "spontaneous"
    /// otherwise.
    ///
    /// If this recognizer wins the arena, [handleTapUp] is called instead.
    open func handleTapCancel(down: PointerDownEvent, cancel: PointerCancelEvent?, reason: String) {
    }

    open override func addAllowedPointer(event: PointerDownEvent) {
        if state == .ready {
            // If there is no result in the previous gesture arena,
            // we ignore them and prepare to accept a new pointer.
            if let down, let up {
                assert(down.pointer == up.pointer)
                reset()
            }

            assert(down == nil && up == nil)
            // `down` must be assigned in this method instead of `handlePrimaryPointer`,
            // because `acceptGesture` might be called before `handlePrimaryPointer`,
            // which relies on `down` to call `handleTapDown`.
            down = event
        }
        if down != nil {
            // This happens when this tap gesture has been rejected while the pointer
            // is down (i.e. due to movement), when another allowed pointer is added,
            // in which case all pointers are ignored. The `_down` being nil
            // means that _reset() has been called, since it is always set at the
            // first allowed down event and will not be cleared except for reset(),
            super.addAllowedPointer(event: event)
        }
    }

    override func startTrackingPointer(_ pointer: Int, transform: Matrix4x4f?) {
        // The recognizer should never track any pointers when `down` is null,
        // because calling `checkDown` in this state will throw exception.
        assert(down != nil)
        super.startTrackingPointer(pointer, transform: transform)
    }

    open override func handlePrimaryPointer(event: PointerEvent) {
        if let event = event as? PointerUpEvent {
            up = event
            checkUp()
        } else if let event = event as? PointerCancelEvent {
            resolve(GestureDisposition.rejected)
            if sentTapDown {
                checkCancel(event: event, note: "")
            }
            reset()
        } else if event.buttons != down!.buttons {
            resolve(GestureDisposition.rejected)
            stopTrackingPointer(primaryPointer!)
        }
    }

    open override func resolve(_ disposition: GestureDisposition) {
        if wonArenaForPrimaryPointer && disposition == .rejected {
            // This can happen if the gesture has been canceled. For example, when
            // the pointer has exceeded the touch slop, the buttons have been changed,
            // or if the recognizer is disposed.
            assert(sentTapDown)
            checkCancel(event: nil, note: "spontaneous")
            reset()
        }
        super.resolve(disposition)
    }

    open override func didExceedDeadline() {
        checkDown()
    }

    open override func acceptGesture(pointer: Int) {
        super.acceptGesture(pointer: pointer)
        if pointer == primaryPointer {
            checkDown()
            wonArenaForPrimaryPointer = true
            checkUp()
        }
    }

    open override func rejectGesture(pointer: Int) {
        super.rejectGesture(pointer: pointer)
        if pointer == primaryPointer {
            // Another gesture won the arena.
            assert(state != .possible)
            if sentTapDown {
                checkCancel(event: nil, note: "forced")
            }
            reset()
        }
    }

    private func checkDown() {
        if sentTapDown {
            return
        }
        handleTapDown(down: down!)
        sentTapDown = true
    }

    private func checkUp() {
        if !wonArenaForPrimaryPointer || up == nil {
            return
        }
        assert(up!.pointer == down!.pointer)
        handleTapUp(down: down!, up: up!)
        reset()
    }

    private func checkCancel(event: PointerCancelEvent?, note: String) {
        handleTapCancel(down: down!, cancel: event, reason: note)
    }

    private func reset() {
        sentTapDown = false
        wonArenaForPrimaryPointer = false
        up = nil
        down = nil
    }
}

/// Recognizes taps.
///
/// Gesture recognizers take part in gesture arenas to enable potential gestures
/// to be disambiguated from each other. This process is managed by a
/// [GestureArenaManager].
///
/// [TapGestureRecognizer] considers all the pointers involved in the pointer
/// event sequence as contributing to one gesture. For this reason, extra
/// pointer interactions during a tap sequence are not recognized as additional
/// taps. For example, down-1, down-2, up-1, up-2 produces only one tap on up-1.
///
/// [TapGestureRecognizer] competes on pointer events of [kPrimaryButton] only
/// when it has at least one non-null `onTap*` callback, on events of
/// [kSecondaryButton] only when it has at least one non-null `onSecondaryTap*`
/// callback, and on events of [kTertiaryButton] only when it has at least
/// one non-null `onTertiaryTap*` callback. If it has no callbacks, it is a
/// no-op.
///
/// The [allowedButtonsFilter] argument only gives this recognizer the
/// ability to limit the buttons it accepts. It does not provide the
/// ability to recognize any buttons beyond the ones it already accepts:
/// kPrimaryButton, kSecondaryButton or kTertiaryButton. Therefore, a
/// combined value of `kPrimaryButton & kSecondaryButton` would be ignored,
/// but `kPrimaryButton | kSecondaryButton` would be allowed, as long as
/// only one of them is selected at a time.
public class TapGestureRecognizer: BaseTapGestureRecognizer {
    public override init(
        debugOwner: AnyObject? = nil,
        supportedDevices: Set<PointerDeviceKind>? = nil,
        allowedButtonsFilter: AllowedButtonsFilter? = nil
    ) {
        super.init(
            debugOwner: debugOwner,
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter
        )
    }

    /// A pointer has contacted the screen at a particular location with a primary
    /// button, which might be the start of a tap.
    ///
    /// This triggers after the down event, once a short timeout ([deadline]) has
    /// elapsed, or once the gestures has won the arena, whichever comes first.
    ///
    /// If this recognizer doesn't win the arena, [onTapCancel] is called next.
    /// Otherwise, [onTapUp] is called next.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [onSecondaryTapDown], a similar callback but for a secondary button.
    ///  * [onTertiaryTapDown], a similar callback but for a tertiary button.
    ///  * [TapDownDetails], which is passed as an argument to this callback.
    ///  * [GestureDetector.onTapDown], which exposes this callback.
    public var onTapDown: GestureTapDownCallback?

    /// A pointer has stopped contacting the screen at a particular location,
    /// which is recognized as a tap of a primary button.
    ///
    /// This triggers on the up event, if the recognizer wins the arena with it
    /// or has previously won, immediately followed by [onTap].
    ///
    /// If this recognizer doesn't win the arena, [onTapCancel] is called instead.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [onSecondaryTapUp], a similar callback but for a secondary button.
    ///  * [onTertiaryTapUp], a similar callback but for a tertiary button.
    ///  * [TapUpDetails], which is passed as an argument to this callback.
    ///  * [GestureDetector.onTapUp], which exposes this callback.
    public var onTapUp: GestureTapUpCallback?

    /// A pointer has stopped contacting the screen, which is recognized as a tap
    /// of a primary button.
    ///
    /// This triggers on the up event, if the recognizer wins the arena with it
    /// or has previously won, immediately following [onTapUp].
    ///
    /// If this recognizer doesn't win the arena, [onTapCancel] is called instead.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [onSecondaryTap], a similar callback but for a secondary button.
    ///  * [onTapUp], which has the same timing but with details.
    ///  * [GestureDetector.onTap], which exposes this callback.
    public var onTap: GestureTapCallback?

    /// A pointer that previously triggered [onTapDown] will not end up causing
    /// a tap.
    ///
    /// This triggers once the gesture loses the arena if [onTapDown] has
    /// previously been triggered.
    ///
    /// If this recognizer wins the arena, [onTapUp] and [onTap] are called
    /// instead.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [onSecondaryTapCancel], a similar callback but for a secondary button.
    ///  * [onTertiaryTapCancel], a similar callback but for a tertiary button.
    ///  * [GestureDetector.onTapCancel], which exposes this callback.
    public var onTapCancel: GestureTapCancelCallback?

    /// A pointer has stopped contacting the screen, which is recognized as a tap
    /// of a secondary button.
    ///
    /// This triggers on the up event, if the recognizer wins the arena with it or
    /// has previously won, immediately following [onSecondaryTapUp].
    ///
    /// If this recognizer doesn't win the arena, [onSecondaryTapCancel] is called
    /// instead.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [onSecondaryTapUp], which has the same timing but with details.
    ///  * [GestureDetector.onSecondaryTap], which exposes this callback.
    public var onSecondaryTap: GestureTapCallback?

    /// A pointer has contacted the screen at a particular location with a
    /// secondary button, which might be the start of a secondary tap.
    ///
    /// This triggers after the down event, once a short timeout ([deadline]) has
    /// elapsed, or once the gestures has won the arena, whichever comes first.
    ///
    /// If this recognizer doesn't win the arena, [onSecondaryTapCancel] is called
    /// next. Otherwise, [onSecondaryTapUp] is called next.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [onTapDown], a similar callback but for a primary button.
    ///  * [onTertiaryTapDown], a similar callback but for a tertiary button.
    ///  * [TapDownDetails], which is passed as an argument to this callback.
    ///  * [GestureDetector.onSecondaryTapDown], which exposes this callback.
    public var onSecondaryTapDown: GestureTapDownCallback?

    /// A pointer has stopped contacting the screen at a particular location,
    /// which is recognized as a tap of a secondary button.
    ///
    /// This triggers on the up event if the recognizer wins the arena with it
    /// or has previously won.
    ///
    /// If this recognizer doesn't win the arena, [onSecondaryTapCancel] is called
    /// instead.
    ///
    /// See also:
    ///
    ///  * [onSecondaryTap], a handler triggered right after this one that doesn't
    ///    pass any details about the tap.
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [onTapUp], a similar callback but for a primary button.
    ///  * [onTertiaryTapUp], a similar callback but for a tertiary button.
    ///  * [TapUpDetails], which is passed as an argument to this callback.
    ///  * [GestureDetector.onSecondaryTapUp], which exposes this callback.
    public var onSecondaryTapUp: GestureTapUpCallback?

    /// A pointer that previously triggered [onSecondaryTapDown] will not end up
    /// causing a tap.
    ///
    /// This triggers once the gesture loses the arena if [onSecondaryTapDown]
    /// has previously been triggered.
    ///
    /// If this recognizer wins the arena, [onSecondaryTapUp] is called instead.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [onTapCancel], a similar callback but for a primary button.
    ///  * [onTertiaryTapCancel], a similar callback but for a tertiary button.
    ///  * [GestureDetector.onSecondaryTapCancel], which exposes this callback.
    public var onSecondaryTapCancel: GestureTapCancelCallback?

    /// A pointer has contacted the screen at a particular location with a
    /// tertiary button, which might be the start of a tertiary tap.
    ///
    /// This triggers after the down event, once a short timeout ([deadline]) has
    /// elapsed, or once the gestures has won the arena, whichever comes first.
    ///
    /// If this recognizer doesn't win the arena, [onTertiaryTapCancel] is called
    /// next. Otherwise, [onTertiaryTapUp] is called next.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    ///  * [onTapDown], a similar callback but for a primary button.
    ///  * [onSecondaryTapDown], a similar callback but for a secondary button.
    ///  * [TapDownDetails], which is passed as an argument to this callback.
    ///  * [GestureDetector.onTertiaryTapDown], which exposes this callback.
    public var onTertiaryTapDown: GestureTapDownCallback?

    /// A pointer has stopped contacting the screen at a particular location,
    /// which is recognized as a tap of a tertiary button.
    ///
    /// This triggers on the up event if the recognizer wins the arena with it
    /// or has previously won.
    ///
    /// If this recognizer doesn't win the arena, [onTertiaryTapCancel] is called
    /// instead.
    ///
    /// See also:
    ///
    ///  * [kTertiaryButton], the button this callback responds to.
    ///  * [onTapUp], a similar callback but for a primary button.
    ///  * [onSecondaryTapUp], a similar callback but for a secondary button.
    ///  * [TapUpDetails], which is passed as an argument to this callback.
    ///  * [GestureDetector.onTertiaryTapUp], which exposes this callback.
    public var onTertiaryTapUp: GestureTapUpCallback?

    /// A pointer that previously triggered [onTertiaryTapDown] will not end up
    /// causing a tap.
    ///
    /// This triggers once the gesture loses the arena if [onTertiaryTapDown]
    /// has previously been triggered.
    ///
    /// If this recognizer wins the arena, [onTertiaryTapUp] is called instead.
    ///
    /// See also:
    ///
    ///  * [kSecondaryButton], the button this callback responds to.
    ///  * [onTapCancel], a similar callback but for a primary button.
    ///  * [onSecondaryTapCancel], a similar callback but for a secondary button.
    ///  * [GestureDetector.onTertiaryTapCancel], which exposes this callback.
    public var onTertiaryTapCancel: GestureTapCancelCallback?

    public override func isPointerAllowed(event: PointerDownEvent) -> Bool {
        switch event.buttons {
        case .primaryButton:
            if onTapDown == nil
                && onTap == nil
                && onTapUp == nil
                && onTapCancel == nil
            {
                return false
            }
        case .secondaryButton:
            if onSecondaryTap == nil
                && onSecondaryTapDown == nil
                && onSecondaryTapUp == nil
                && onSecondaryTapCancel == nil
            {
                return false
            }
        case .tertiaryButton:
            if onTertiaryTapDown == nil
                && onTertiaryTapUp == nil
                && onTertiaryTapCancel == nil
            {
                return false
            }
        default:
            return false
        }
        return super.isPointerAllowed(event: event)
    }

    public override func handleTapDown(down: PointerDownEvent) {
        let details = TapDownDetails(
            globalPosition: down.position,
            localPosition: down.localPosition,
            kind: getKindForPointer(pointer: down.pointer)
        )
        switch down.buttons {
        case .primaryButton:
            if let onTapDown {
                invokeCallback("onTapDown", { onTapDown(details) })
            }
        case .secondaryButton:
            if let onSecondaryTapDown {
                invokeCallback("onSecondaryTapDown", { onSecondaryTapDown(details) })
            }
        case .tertiaryButton:
            if let onTertiaryTapDown {
                invokeCallback("onTertiaryTapDown", { onTertiaryTapDown(details) })
            }
        default:
            break
        }
    }

    public override func handleTapUp(down: PointerDownEvent, up: PointerUpEvent) {
        let details = TapUpDetails(
            globalPosition: up.position,
            localPosition: up.localPosition,
            kind: getKindForPointer(pointer: up.pointer)
        )
        switch down.buttons {
        case .primaryButton:
            if let onTapUp {
                invokeCallback("onTapUp", { onTapUp(details) })
            }
            if let onTap {
                invokeCallback("onTap", onTap)
            }
        case .secondaryButton:
            if let onSecondaryTapUp {
                invokeCallback("onSecondaryTapUp", { onSecondaryTapUp(details) })
            }
            if let onSecondaryTap {
                invokeCallback("onSecondaryTap", onSecondaryTap)
            }
        case .tertiaryButton:
            if let onTertiaryTapUp {
                invokeCallback("onTertiaryTapUp", { onTertiaryTapUp(details) })
            }
        default:
            break
        }
    }

    public override func handleTapCancel(
        down: PointerDownEvent,
        cancel: PointerCancelEvent?,
        reason: String
    ) {
        let note = reason == "" ? reason : "\(reason) "
        switch down.buttons {
        case .primaryButton:
            if let onTapCancel {
                invokeCallback("\(note)onTapCancel", onTapCancel)
            }
        case .secondaryButton:
            if let onSecondaryTapCancel {
                invokeCallback("\(note)onSecondaryTapCancel", onSecondaryTapCancel)
            }
        case .tertiaryButton:
            if let onTertiaryTapCancel {
                invokeCallback("\(note)onTertiaryTapCancel", onTertiaryTapCancel)
            }
        default:
            break
        }
    }

}
