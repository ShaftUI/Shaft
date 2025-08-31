// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

private func getGlobalDistance(_ event: PointerEvent, _ originPosition: OffsetPair?) -> Float {
    assert(originPosition != nil)
    let offset = event.position - originPosition!.global
    return offset.distance
}

/// The possible states of a `BaseTapAndDragGestureRecognizer`.
///
/// The recognizer advances from `ready` to `possible` when it starts tracking
/// a pointer in `BaseTapAndDragGestureRecognizer.addAllowedPointer`. Where it advances
/// from there depends on the sequence of pointer events that is tracked by the
/// recognizer, following the initial `PointerDownEvent`:
///
/// * If a `PointerUpEvent` has not been tracked, the recognizer stays in the `possible`
///   state as long as it continues to track a pointer.
/// * If a `PointerMoveEvent` is tracked that has moved a sufficient global distance
///   from the initial `PointerDownEvent` and it came before a `PointerUpEvent`, then
///   this recognizer moves from the `possible` state to `accepted`.
/// * If a `PointerUpEvent` is tracked before the pointer has moved a sufficient global
///   distance to be considered a drag, then this recognizer moves from the `possible`
///   state to `ready`.
/// * If a `PointerCancelEvent` is tracked then this recognizer moves from its current
///   state to `ready`.
///
/// Once the recognizer has stopped tracking any remaining pointers, the recognizer
/// returns to the `ready` state.
private enum _DragState {
    /// The recognizer is ready to start recognizing a drag.
    case ready

    /// The sequence of pointer events seen thus far is consistent with a drag but
    /// it has not been accepted definitively.
    case possible

    /// The sequence of pointer events has been accepted definitively as a drag.
    case accepted
}

/// The consecutive tap count at the time the pointer contacted the
/// screen is given by [TapDragDownDetails.consecutiveTapCount].
///
/// Used by [BaseTapAndDragGestureRecognizer.onTapDown].
public typealias GestureTapDragDownCallback = (TapDragDownDetails) -> Void

/// Details for [GestureTapDragDownCallback], such as the number of
/// consecutive taps.
///
/// See also:
///
///  * [BaseTapAndDragGestureRecognizer], which passes this information to its
///    [BaseTapAndDragGestureRecognizer.onTapDown] callback.
///  * [TapDragUpDetails], the details for [GestureTapDragUpCallback].
///  * [TapDragStartDetails], the details for [GestureTapDragStartCallback].
///  * [TapDragUpdateDetails], the details for [GestureTapDragUpdateCallback].
///  * [TapDragEndDetails], the details for [GestureTapDragEndCallback].
public struct TapDragDownDetails: Diagnosticable {
    /// Creates details for a [GestureTapDragDownCallback].
    public init(
        globalPosition: Offset,
        localPosition: Offset,
        kind: PointerDeviceKind? = nil,
        consecutiveTapCount: Int
    ) {
        self.globalPosition = globalPosition
        self.localPosition = localPosition
        self.kind = kind
        self.consecutiveTapCount = consecutiveTapCount
    }

    /// The global position at which the pointer contacted the screen.
    public let globalPosition: Offset

    /// The local position at which the pointer contacted the screen.
    public let localPosition: Offset

    /// The kind of the device that initiated the event.
    public let kind: PointerDeviceKind?

    /// If this tap is in a series of taps, then this value represents
    /// the number in the series this tap is.
    public let consecutiveTapCount: Int
}

/// The consecutive tap count at the time the pointer contacted the
/// screen is given by [TapDragUpDetails.consecutiveTapCount].
///
/// Used by [BaseTapAndDragGestureRecognizer.onTapUp].
public typealias GestureTapDragUpCallback = (TapDragUpDetails) -> Void

/// Details for [GestureTapDragUpCallback], such as the number of
/// consecutive taps.
///
/// See also:
///
///  * [BaseTapAndDragGestureRecognizer], which passes this information to its
///    [BaseTapAndDragGestureRecognizer.onTapUp] callback.
///  * [TapDragDownDetails], the details for [GestureTapDragDownCallback].
///  * [TapDragStartDetails], the details for [GestureTapDragStartCallback].
///  * [TapDragUpdateDetails], the details for [GestureTapDragUpdateCallback].
///  * [TapDragEndDetails], the details for [GestureTapDragEndCallback].
public struct TapDragUpDetails: Diagnosticable {
    /// Creates details for a [GestureTapDragUpCallback].
    public init(
        kind: PointerDeviceKind,
        globalPosition: Offset,
        localPosition: Offset,
        consecutiveTapCount: Int
    ) {
        self.kind = kind
        self.globalPosition = globalPosition
        self.localPosition = localPosition
        self.consecutiveTapCount = consecutiveTapCount
    }

    /// The global position at which the pointer contacted the screen.
    public let globalPosition: Offset

    /// The local position at which the pointer contacted the screen.
    public let localPosition: Offset

    /// The kind of the device that initiated the event.
    public let kind: PointerDeviceKind

    /// If this tap is in a series of taps, then this value represents
    /// the number in the series this tap is.
    public let consecutiveTapCount: Int
}

/// {@macro flutter.gestures.dragdetails.GestureDragStartCallback}
///
/// The consecutive tap count at the time the pointer contacted the
/// screen is given by [TapDragStartDetails.consecutiveTapCount].
///
/// Used by [BaseTapAndDragGestureRecognizer.onDragStart].
public typealias GestureTapDragStartCallback = (TapDragStartDetails) -> Void

/// Details for [GestureTapDragStartCallback], such as the number of
/// consecutive taps.
///
/// See also:
///
///  * [BaseTapAndDragGestureRecognizer], which passes this information to its
///    [BaseTapAndDragGestureRecognizer.onDragStart] callback.
///  * [TapDragDownDetails], the details for [GestureTapDragDownCallback].
///  * [TapDragUpDetails], the details for [GestureTapDragUpCallback].
///  * [TapDragUpdateDetails], the details for [GestureTapDragUpdateCallback].
///  * [TapDragEndDetails], the details for [GestureTapDragEndCallback].
public struct TapDragStartDetails: Diagnosticable {
    /// Creates details for a [GestureTapDragStartCallback].
    public init(
        sourceTimeStamp: Duration? = nil,
        globalPosition: Offset,
        localPosition: Offset,
        kind: PointerDeviceKind? = nil,
        consecutiveTapCount: Int
    ) {
        self.sourceTimeStamp = sourceTimeStamp
        self.globalPosition = globalPosition
        self.localPosition = localPosition
        self.kind = kind
        self.consecutiveTapCount = consecutiveTapCount
    }

    /// Recorded timestamp of the source pointer event that triggered the drag
    /// event.
    ///
    /// Could be null if triggered from proxied events such as accessibility.
    public let sourceTimeStamp: Duration?

    /// The global position at which the pointer contacted the screen.
    ///
    /// See also:
    ///
    ///  * [localPosition], which is the [globalPosition] transformed to the
    ///    coordinate space of the event receiver.
    public let globalPosition: Offset

    /// The local position in the coordinate system of the event receiver at
    /// which the pointer contacted the screen.
    public let localPosition: Offset

    /// The kind of the device that initiated the event.
    public let kind: PointerDeviceKind?

    /// If this tap is in a series of taps, then this value represents
    /// the number in the series this tap is.
    public let consecutiveTapCount: Int
}

/// {@macro flutter.gestures.dragdetails.GestureDragUpdateCallback}
///
/// The consecutive tap count at the time the pointer contacted the
/// screen is given by [TapDragUpdateDetails.consecutiveTapCount].
///
/// Used by [BaseTapAndDragGestureRecognizer.onDragUpdate].
public typealias GestureTapDragUpdateCallback = (TapDragUpdateDetails) -> Void

/// Details for [GestureTapDragUpdateCallback], such as the number of
/// consecutive taps.
///
/// See also:
///
///  * [BaseTapAndDragGestureRecognizer], which passes this information to its
///    [BaseTapAndDragGestureRecognizer.onDragUpdate] callback.
///  * [TapDragDownDetails], the details for [GestureTapDragDownCallback].
///  * [TapDragUpDetails], the details for [GestureTapDragUpCallback].
///  * [TapDragStartDetails], the details for [GestureTapDragStartCallback].
///  * [TapDragEndDetails], the details for [GestureTapDragEndCallback].
public struct TapDragUpdateDetails: Diagnosticable {
    /// Creates details for a [GestureTapDragUpdateCallback].
    ///
    /// If [primaryDelta] is non-null, then its value must match one of the
    /// coordinates of [delta] and the other coordinate must be zero.
    public init(
        sourceTimeStamp: Duration? = nil,
        delta: Offset = .zero,
        primaryDelta: Float? = nil,
        globalPosition: Offset,
        kind: PointerDeviceKind? = nil,
        localPosition: Offset,
        offsetFromOrigin: Offset,
        localOffsetFromOrigin: Offset,
        consecutiveTapCount: Int
    ) {
        assert(
            primaryDelta == nil
                || (primaryDelta! == delta.dx && delta.dy == 0.0)
                || (primaryDelta! == delta.dy && delta.dx == 0.0)
        )

        self.sourceTimeStamp = sourceTimeStamp
        self.delta = delta
        self.primaryDelta = primaryDelta
        self.globalPosition = globalPosition
        self.kind = kind
        self.localPosition = localPosition
        self.offsetFromOrigin = offsetFromOrigin
        self.localOffsetFromOrigin = localOffsetFromOrigin
        self.consecutiveTapCount = consecutiveTapCount
    }

    /// Recorded timestamp of the source pointer event that triggered the drag
    /// event.
    ///
    /// Could be null if triggered from proxied events such as accessibility.
    public let sourceTimeStamp: Duration?

    /// The amount the pointer has moved in the coordinate space of the event
    /// receiver since the previous update.
    ///
    /// If the [GestureTapDragUpdateCallback] is for a one-dimensional drag (e.g.,
    /// a horizontal or vertical drag), then this offset contains only the delta
    /// in that direction (i.e., the coordinate in the other direction is zero).
    ///
    /// Defaults to zero if not specified in the constructor.
    public let delta: Offset

    /// The amount the pointer has moved along the primary axis in the coordinate
    /// space of the event receiver since the previous
    /// update.
    ///
    /// If the [GestureTapDragUpdateCallback] is for a one-dimensional drag (e.g.,
    /// a horizontal or vertical drag), then this value contains the component of
    /// [delta] along the primary axis (e.g., horizontal or vertical,
    /// respectively). Otherwise, if the [GestureTapDragUpdateCallback] is for a
    /// two-dimensional drag (e.g., a pan), then this value is null.
    ///
    /// Defaults to null if not specified in the constructor.
    public let primaryDelta: Float?

    /// The pointer's global position when it triggered this update.
    ///
    /// See also:
    ///
    ///  * [localPosition], which is the [globalPosition] transformed to the
    ///    coordinate space of the event receiver.
    public let globalPosition: Offset

    /// The local position in the coordinate system of the event receiver at
    /// which the pointer contacted the screen.
    ///
    /// Defaults to [globalPosition] if not specified in the constructor.
    public let localPosition: Offset

    /// The kind of the device that initiated the event.
    public let kind: PointerDeviceKind?

    /// A delta offset from the point where the drag initially contacted
    /// the screen to the point where the pointer is currently located in global
    /// coordinates (the present [globalPosition]) when this callback is triggered.
    ///
    /// When considering a [GestureRecognizer] that tracks the number of consecutive taps,
    /// this offset is associated with the most recent [PointerDownEvent] that occurred.
    public let offsetFromOrigin: Offset

    /// A local delta offset from the point where the drag initially contacted
    /// the screen to the point where the pointer is currently located in local
    /// coordinates (the present [localPosition]) when this callback is triggered.
    ///
    /// When considering a [GestureRecognizer] that tracks the number of consecutive taps,
    /// this offset is associated with the most recent [PointerDownEvent] that occurred.
    public let localOffsetFromOrigin: Offset

    /// If this tap is in a series of taps, then this value represents
    /// the number in the series this tap is.
    public let consecutiveTapCount: Int
}

/// The consecutive tap count at the time the pointer contacted the
/// screen is given by [TapDragEndDetails.consecutiveTapCount].
///
/// Used by [BaseTapAndDragGestureRecognizer.onDragEnd].
public typealias GestureTapDragEndCallback = (TapDragEndDetails) -> Void

/// Details for [GestureTapDragEndCallback], such as the number of
/// consecutive taps.
///
/// See also:
///
///  * [BaseTapAndDragGestureRecognizer], which passes this information to its
///    [BaseTapAndDragGestureRecognizer.onDragEnd] callback.
///  * [TapDragDownDetails], the details for [GestureTapDragDownCallback].
///  * [TapDragUpDetails], the details for [GestureTapDragUpCallback].
///  * [TapDragStartDetails], the details for [GestureTapDragStartCallback].
///  * [TapDragUpdateDetails], the details for [GestureTapDragUpdateCallback].
public struct TapDragEndDetails: Diagnosticable {
    /// Creates details for a [GestureTapDragEndCallback].
    public init(
        velocity: Velocity = .zero,
        primaryVelocity: Float? = nil,
        consecutiveTapCount: Int
    ) {
        self.velocity = velocity
        self.primaryVelocity = primaryVelocity
        self.consecutiveTapCount = consecutiveTapCount

        assert(
            primaryVelocity == nil
                || primaryVelocity! == velocity.pixelsPerSecond.dx
                || primaryVelocity! == velocity.pixelsPerSecond.dy
        )
    }

    /// The velocity the pointer was moving when it stopped contacting the screen.
    ///
    /// Defaults to zero if not specified in the constructor.
    public let velocity: Velocity

    /// The velocity the pointer was moving along the primary axis when it stopped
    /// contacting the screen, in logical pixels per second.
    ///
    /// If the [GestureTapDragEndCallback] is for a one-dimensional drag (e.g., a
    /// horizontal or vertical drag), then this value contains the component of
    /// [velocity] along the primary axis (e.g., horizontal or vertical,
    /// respectively). Otherwise, if the [GestureTapDragEndCallback] is for a
    /// two-dimensional drag (e.g., a pan), then this value is null.
    ///
    /// Defaults to null if not specified in the constructor.
    public let primaryVelocity: Float?

    /// If this tap is in a series of taps, then this value represents
    /// the number in the series this tap is.
    public let consecutiveTapCount: Int
}

/// Signature for when the pointer that previously triggered a
/// [GestureTapDragDownCallback] did not complete.
///
/// Used by [BaseTapAndDragGestureRecognizer.onCancel].
public typealias GestureCancelCallback = () -> Void

// A mixin for [OneSequenceGestureRecognizer] that tracks the number of taps
// that occur in a series of [PointerEvent]s and the most recent set of
// [LogicalKeyboardKey]s pressed on the most recent tap down.
//
// A tap is tracked as part of a series of taps if:
//
// 1. The elapsed time between when a [PointerUpEvent] and the subsequent
// [PointerDownEvent] does not exceed [kDoubleTapTimeout].
// 2. The delta between the position tapped in the global coordinate system
// and the position that was tapped previously must be less than or equal
// to [kDoubleTapSlop].
//
// This mixin's state, i.e. the series of taps being tracked is reset when
// a tap is tracked that does not meet any of the specifications stated above.
private struct TapStatusTrackerMixin {
    public init() {}

    public var gestureSettings: DeviceGestureSettings?

    // Public state available to [OneSequenceGestureRecognizer].

    // The [PointerDownEvent] that was most recently tracked in [addAllowedPointer].
    //
    // This value will be null if a [PointerDownEvent] has not been tracked yet in
    // [addAllowedPointer] or the timer between two taps has elapsed.
    //
    // This value is only reset when the timer between a [PointerUpEvent] and the
    // [PointerDownEvent] times out or when a new [PointerDownEvent] is tracked in
    // [addAllowedPointer].
    public var currentDown: PointerDownEvent? { down }

    // The [PointerUpEvent] that was most recently tracked in [handleEvent].
    //
    // This value will be null if a [PointerUpEvent] has not been tracked yet in
    // [handleEvent] or the timer between two taps has elapsed.
    //
    // This value is only reset when the timer between a [PointerUpEvent] and the
    // [PointerDownEvent] times out or when a new [PointerDownEvent] is tracked in
    // [addAllowedPointer].
    public var currentUp: PointerUpEvent? { up }

    // The number of consecutive taps that the most recently tracked [PointerDownEvent]
    // in [currentDown] represents.
    //
    // This value defaults to zero, meaning a tap series is not currently being tracked.
    //
    // When this value is greater than zero it means [addAllowedPointer] has run
    // and at least one [PointerDownEvent] belongs to the current series of taps
    // being tracked.
    //
    // [addAllowedPointer] will either increment this value by `1` or set the value to `1`
    // depending if the new [PointerDownEvent] is determined to be in the same series as the
    // tap that preceded it. If too much time has elapsed between two taps, the recognizer has lost
    // in the arena, the gesture has been cancelled, or the recognizer is being disposed then
    // this value will be set to `0`, and a new series will begin.
    // var consecutiveTapCount: Int { consecutiveTapCount }
    public private(set) var consecutiveTapCount = 0

    // The upper limit for the [consecutiveTapCount]. When this limit is reached
    // all tap related state is reset and a new tap series is tracked.
    //
    // If this value is null, [consecutiveTapCount] can grow infinitely large.
    public var maxConsecutiveTap: Int?

    // Private tap state tracked.
    private var down: PointerDownEvent?
    private var up: PointerUpEvent?

    private var originPosition: OffsetPair?
    private var previousButtons: PointerButtons?

    // For timing taps.
    private var consecutiveTapTimer: Timer?
    private var lastTapOffset: Offset?

    /// Callback used to indicate that a tap tracking has started upon
    /// a [PointerDownEvent].
    internal var onTapTrackStart: VoidCallback?

    /// Callback used to indicate that a tap tracking has been reset which
    /// happens on the next [PointerDownEvent] after the timer between two taps
    /// elapses, the recognizer loses the arena, the gesture is cancelled or
    /// the recognizer is disposed of.
    internal var onTapTrackReset: VoidCallback?

    // When tracking a tap, the [consecutiveTapCount] is incremented if the given tap
    // falls under the tolerance specifications and reset to 1 if not.
    mutating func addAllowedPointer(_ event: PointerDownEvent) {
        if let consecutiveTapTimer, !consecutiveTapTimer.isActive {
            tapTrackerReset()
        }
        if maxConsecutiveTap == consecutiveTapCount {
            tapTrackerReset()
        }
        up = nil
        if down != nil && !representsSameSeries(event) {
            // The given tap does not match the specifications of the series of taps being tracked,
            // reset the tap count and related state.
            consecutiveTapCount = 1
        } else {
            consecutiveTapCount += 1
        }
        consecutiveTapTimerStop()
        // `down` must be assigned in this method instead of [handleEvent],
        // because [acceptGesture] might be called before [handleEvent],
        // which may rely on `down` to initiate a callback.
        trackTap(event)
    }

    mutating func handleEvent(_ event: PointerEvent) {
        if let event = event as? PointerMoveEvent {
            let computedSlop = computeHitSlop(event.kind, gestureSettings)
            let isSlopPastTolerance = getGlobalDistance(event, originPosition) > computedSlop

            if isSlopPastTolerance {
                consecutiveTapTimerStop()
                previousButtons = nil
                lastTapOffset = nil
            }
        } else if let event = event as? PointerUpEvent {
            up = event
            if down != nil {
                consecutiveTapTimerStop()
                consecutiveTapTimerStart(event.timeStamp)
            }
        } else if event is PointerCancelEvent {
            tapTrackerReset()
        }
    }

    mutating func rejectGesture(_ pointer: Int) {
        tapTrackerReset()
    }

    mutating func dispose() {
        tapTrackerReset()
    }

    private mutating func trackTap(_ event: PointerDownEvent) {
        down = event
        previousButtons = event.buttons
        lastTapOffset = event.position
        originPosition = OffsetPair(local: event.localPosition, global: event.position)
        onTapTrackStart?()
    }

    private func hasSameButton(_ buttons: PointerButtons) -> Bool {
        assert(previousButtons != nil)
        if buttons == previousButtons! {
            return true
        } else {
            return false
        }
    }

    private func isWithinConsecutiveTapTolerance(_ secondTapOffset: Offset) -> Bool {
        if lastTapOffset == nil {
            return false
        }

        let difference = secondTapOffset - lastTapOffset!
        return difference.distance <= kDoubleTapSlop
    }

    private func representsSameSeries(_ event: PointerDownEvent) -> Bool {
        return consecutiveTapTimer != nil
            && isWithinConsecutiveTapTolerance(event.position)
            && hasSameButton(event.buttons)
    }

    private mutating func consecutiveTapTimerStart(_ timeStamp: Duration) {
        consecutiveTapTimer =
            consecutiveTapTimer
            ?? backend.createTimer(
                kDoubleTapTimeout,
                callback: consecutiveTapTimerTimeout
            )
    }

    private mutating func consecutiveTapTimerStop() {
        if let consecutiveTapTimer {
            consecutiveTapTimer.cancel()
            self.consecutiveTapTimer = nil
        }
    }

    private func consecutiveTapTimerTimeout() {
        // The consecutive tap timer may time out before a tap down/tap up event is
        // fired. In this case we should not reset the tap tracker state immediately.
        // Instead we should reset the tap tracker on the next call to [addAllowedPointer],
        // if the timer is no longer active.
    }

    private mutating func tapTrackerReset() {
        // The timer has timed out, i.e. the time between a [PointerUpEvent] and the subsequent
        // [PointerDownEvent] exceeded the duration of [kDoubleTapTimeout], so the tap belonging
        // to the [PointerDownEvent] cannot be considered part of the same tap series as the
        // previous [PointerUpEvent].
        consecutiveTapTimerStop()
        previousButtons = nil
        originPosition = nil
        lastTapOffset = nil
        consecutiveTapCount = 0
        down = nil
        up = nil
        onTapTrackReset?()
    }
}

/// A base class for gesture recognizers that recognize taps and movements.
///
/// Takes on the responsibilities of [TapGestureRecognizer] and
/// [DragGestureRecognizer] in one [GestureRecognizer].
///
/// ### Gesture arena behavior
///
/// [BaseTapAndDragGestureRecognizer] competes on the pointer events of
/// [kPrimaryButton] only when it has at least one non-null `onTap*`
/// or `onDrag*` callback.
///
/// It will declare defeat if it determines that a gesture is not a
/// tap (e.g. if the pointer is dragged too far while it's contacting the
/// screen) or a drag (e.g. if the pointer was not dragged far enough to
/// be considered a drag.
///
/// This recognizer will not immediately declare victory for every tap that it
/// recognizes, but it declares victory for every drag.
///
/// The recognizer will declare victory when all other recognizer's in
/// the arena have lost, if the timer of [kPressTimeout] elapses and a tap
/// series greater than 1 is being tracked, or until the pointer has moved
/// a sufficient global distance from the origin to be considered a drag.
///
/// If this recognizer loses the arena (either by declaring defeat or by
/// another recognizer declaring victory) while the pointer is contacting the
/// screen, it will fire [onCancel] instead of [onTapUp] or [onDragEnd].
///
/// ### When competing with `TapGestureRecognizer` and `DragGestureRecognizer`
///
/// Similar to [TapGestureRecognizer] and [DragGestureRecognizer],
/// [BaseTapAndDragGestureRecognizer] will not aggressively declare victory when
/// it detects a tap, so when it is competing with those gesture recognizers and
/// others it has a chance of losing. Similarly, when `eagerVictoryOnDrag` is set
/// to `false`, this recognizer will not aggressively declare victory when it
/// detects a drag. By default, `eagerVictoryOnDrag` is set to `true`, so this
/// recognizer will aggressively declare victory when it detects a drag.
///
/// When competing against [TapGestureRecognizer], if the pointer does not move past the tap
/// tolerance, then the recognizer that entered the arena first will win. In this case the
/// gesture detected is a tap. If the pointer does travel past the tap tolerance then this
/// recognizer will be declared winner by default. The gesture detected in this case is a drag.
///
/// When competing against [DragGestureRecognizer], if the pointer does not move a sufficient
/// global distance to be considered a drag, the recognizers will tie in the arena. If the
/// pointer does travel enough distance then the recognizer that entered the arena
/// first will win. The gesture detected in this case is a drag.
///
/// This example shows how to use the [TapAndPanGestureRecognizer] along with a
/// [RawGestureDetector] to scale a Widget.
///
/// This example shows how to hook up [TapAndPanGestureRecognizer]s' to nested
/// [RawGestureDetector]s'. It assumes that the code is being used inside a [State]
/// object with a `_last` field that is then displayed as the child of the gesture detector.
///
/// In this example, if the pointer has moved past the drag threshold, then the
/// the first [TapAndPanGestureRecognizer] instance to receive the [PointerEvent]
/// will win the arena because the recognizer will immediately declare victory.
///
/// The first one to receive the event in the example will depend on where on both
/// containers the pointer lands first. If your pointer begins in the overlapping
/// area of both containers, then the inner-most widget will receive the event first.
/// If your pointer begins in the yellow container then it will be the first to
/// receive the event.
///
/// If the pointer has not moved past the drag threshold, then the first recognizer
/// to enter the arena will win (i.e. they both tie and the gesture arena will call
/// [GestureArenaManager.sweep] so the first member of the arena will win).
///
///
/// RawGestureDetector(
///   gestures: [
///     TapAndPanGestureRecognizer.self: GestureRecognizerFactoryWithHandlers<TapAndPanGestureRecognizer>(
///       { TapAndPanGestureRecognizer() },
///       { instance in
///         instance.onTapDown = { details in self.setState { self._last = "down_a" } }
///         instance.onDragStart = { details in self.setState { self._last = "drag_start_a" } }
///         instance.onDragUpdate = { details in self.setState { self._last = "drag_update_a" } }
///         instance.onDragEnd = { details in self.setState { self._last = "drag_end_a" } }
///         instance.onTapUp = { details in self.setState { self._last = "up_a" } }
///         instance.onCancel = { self.setState { self._last = "cancel_a" } }
///       }
///     )
///   ],
///   child: Container(
///     width: 300.0,
///     height: 300.0,
///     color: .yellow,
///     alignment: .center,
///     child: RawGestureDetector(
///       gestures: [
///         TapAndPanGestureRecognizer.self: GestureRecognizerFactoryWithHandlers<TapAndPanGestureRecognizer>(
///           { TapAndPanGestureRecognizer() },
///           { instance in
///             instance.onTapDown = { details in self.setState { self._last = "down_b" } }
///             instance.onDragStart = { details in self.setState { self._last = "drag_start_b" } }
///             instance.onDragUpdate = { details in self.setState { self._last = "drag_update_b" } }
///             instance.onDragEnd = { details in self.setState { self._last = "drag_end_b" } }
///             instance.onTapUp = { details in self.setState { self._last = "up_b" } }
///             instance.onCancel = { self.setState { self._last = "cancel_b" } }
///           }
///         )
///       ],
///       child: Container(
///         width: 150.0,
///         height: 150.0,
///         color: .blue,
///         child: Text(_last)
///       )
///     )
///   )
/// )
///
public class BaseTapAndDragGestureRecognizer: OneSequenceGestureRecognizer {
    /// Creates a tap and drag gesture recognizer.
    init(
        debugOwner: AnyObject? = nil,
        supportedDevices: Set<PointerDeviceKind>? = nil,
        allowedButtonsFilter: AllowedButtonsFilter? = nil,
        eagerVictoryOnDrag: Bool = true
    ) {
        self.eagerVictoryOnDrag = eagerVictoryOnDrag
        self.deadline = kPressTimeout
        self.dragStartBehavior = .start
        super.init(
            debugOwner: debugOwner,
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter
        )
        self.tapStatusTracker.gestureSettings = self.gestureSettings
    }

    /// A mixin that tracks the state of taps for a gesture recognizer.
    private var tapStatusTracker = TapStatusTrackerMixin()

    public override var gestureSettings: DeviceGestureSettings? {
        didSet {
            self.tapStatusTracker.gestureSettings = self.gestureSettings
        }
    }

    /// Configure the behavior of offsets passed to [onDragStart].
    ///
    /// If set to [DragStartBehavior.start], the [onDragStart] callback will be called
    /// with the position of the pointer at the time this gesture recognizer won
    /// the arena. If [DragStartBehavior.down], [onDragStart] will be called with
    /// the position of the first detected down event for the pointer. When there
    /// are no other gestures competing with this gesture in the arena, there's
    /// no difference in behavior between the two settings.
    ///
    /// For more information about the gesture arena:
    /// https://flutter.dev/to/gesture-disambiguation
    ///
    /// By default, the drag start behavior is [DragStartBehavior.start].
    ///
    /// See also:
    ///
    ///  * [DragGestureRecognizer.dragStartBehavior], which includes more details and an example.
    public var dragStartBehavior: DragStartBehavior

    /// The frequency at which the [onDragUpdate] callback is called.
    ///
    /// The value defaults to null, meaning there is no delay for [onDragUpdate] callback.
    public var dragUpdateThrottleFrequency: Duration?

    /// An upper bound for the amount of taps that can belong to one tap series.
    ///
    /// When this limit is reached the series of taps being tracked by this
    /// recognizer will be reset.
    public var maxConsecutiveTap: Int? {
        get { tapStatusTracker.maxConsecutiveTap }
        set { tapStatusTracker.maxConsecutiveTap = newValue }
    }

    /// Whether this recognizer eagerly declares victory when it has detected
    /// a drag.
    ///
    /// When this value is `false`, this recognizer will wait until it is the last
    /// recognizer in the gesture arena before declaring victory on a drag.
    ///
    /// Defaults to `true`.
    public var eagerVictoryOnDrag: Bool

    /// This triggers after the down event, once a short timeout ([kPressTimeout]) has
    /// elapsed, or once the gestures has won the arena, whichever comes first.
    ///
    /// The position of the pointer is provided in the callback's `details`
    /// argument, which is a [TapDragDownDetails] object.
    ///
    /// {@template flutter.gestures.selectionrecognizers.BaseTapAndDragGestureRecognizer.tapStatusTrackerData}
    /// The number of consecutive taps, and the keys that were pressed on tap down
    /// are also provided in the callback's `details` argument.
    /// {@endtemplate}
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [TapDragDownDetails], which is passed as an argument to this callback.
    public var onTapDown: GestureTapDragDownCallback?

    /// This triggers on the up event, if the recognizer wins the arena with it
    /// or has previously won.
    ///
    /// The position of the pointer is provided in the callback's `details`
    /// argument, which is a [TapDragUpDetails] object.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [TapDragUpDetails], which is passed as an argument to this callback.
    public var onTapUp: GestureTapDragUpCallback?

    /// The position of the pointer is provided in the callback's `details`
    /// argument, which is a [TapDragStartDetails] object. The [dragStartBehavior]
    /// determines this position.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [TapDragStartDetails], which is passed as an argument to this callback.
    public var onDragStart: GestureTapDragStartCallback?

    /// The distance traveled by the pointer since the last update is provided in
    /// the callback's `details` argument, which is a [TapDragUpdateDetails] object.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [TapDragUpdateDetails], which is passed as an argument to this callback.
    public var onDragUpdate: GestureTapDragUpdateCallback?

    /// The velocity is provided in the callback's `details` argument, which is a
    /// [TapDragEndDetails] object.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    ///  * [TapDragEndDetails], which is passed as an argument to this callback.
    public var onDragEnd: GestureTapDragEndCallback?

    /// The pointer that previously triggered [onTapDown] did not complete.
    ///
    /// This is called when a [PointerCancelEvent] is tracked when the [onTapDown] callback
    /// was previously called.
    ///
    /// It may also be called if a [PointerUpEvent] is tracked after the pointer has moved
    /// past the tap tolerance but not past the drag tolerance, and the recognizer has not
    /// yet won the arena.
    ///
    /// See also:
    ///
    ///  * [kPrimaryButton], the button this callback responds to.
    public var onCancel: GestureCancelCallback?

    /// Callback used to indicate that a tap tracking has started upon
    /// a [PointerDownEvent].
    public var onTapTrackStart: VoidCallback? {
        get { tapStatusTracker.onTapTrackStart }
        set { tapStatusTracker.onTapTrackStart = newValue }
    }

    /// Callback used to indicate that a tap tracking has been reset which
    /// happens on the next [PointerDownEvent] after the timer between two taps
    /// elapses, the recognizer loses the arena, the gesture is cancelled or
    /// the recognizer is disposed of.
    public var onTapTrackReset: VoidCallback? {
        get { tapStatusTracker.onTapTrackStart }
        set { tapStatusTracker.onTapTrackStart = newValue }
    }

    // Tap related state.
    private var pastSlopTolerance = false
    private var sentTapDown = false
    private var wonArenaForPrimaryPointer = false

    // Primary pointer being tracked by this recognizer.
    private var primaryPointer: Int?
    private var deadlineTimer: Timer?
    // The recognizer will call [onTapDown] after this amount of time has elapsed
    // since starting to track the primary pointer.
    //
    // [onTapDown] will not be called if the primary pointer is
    // accepted, rejected, or all pointers are up or canceled before [deadline].
    let deadline: Duration

    // Drag related state.
    private var dragState: _DragState = .ready
    private var start: PointerEvent?
    private var initialPosition: OffsetPair!
    internal var globalDistanceMoved: Float!
    private var globalDistanceMovedAllAxes: Float!
    private var correctedPosition: OffsetPair?

    // For drag update throttle.
    private var lastDragUpdateDetails: TapDragUpdateDetails?
    private var dragUpdateThrottleTimer: Timer?

    private var acceptedActivePointers = Set<Int>()

    internal func getDeltaForDetails(_ delta: Offset) -> Offset {
        return delta
    }

    internal func getPrimaryValueFromOffset(_ value: Offset) -> Float? {
        return value.dx
    }

    internal func hasSufficientGlobalDistanceToAccept(_ pointerDeviceKind: PointerDeviceKind)
        -> Bool
    {
        return true
    }

    // Drag updates may require throttling to avoid excessive updating, such as for text layouts in text
    // fields. The frequency of invocations is controlled by the [dragUpdateThrottleFrequency].
    //
    // Once the drag gesture ends, any pending drag update will be fired
    // immediately. See [_checkDragEnd].
    func _handleDragUpdateThrottled() {
        assert(lastDragUpdateDetails != nil)
        if onDragUpdate != nil {
            invokeCallback("onDragUpdate") {
                onDragUpdate!(lastDragUpdateDetails!)
            }
        }
        dragUpdateThrottleTimer = nil
        lastDragUpdateDetails = nil
    }

    public override func isPointerAllowed(event: PointerEvent) -> Bool {
        if primaryPointer == nil {
            switch event.buttons {
            case .primaryButton:
                if onTapDown == nil && onDragStart == nil && onDragUpdate == nil && onDragEnd == nil
                    && onTapUp == nil && onCancel == nil
                {
                    return false
                }
            default:
                return false
            }
        } else {
            if event.pointer != primaryPointer {
                return false
            }
        }

        return super.isPointerAllowed(event: event as! PointerDownEvent)
    }

    public override func addAllowedPointer(event: PointerDownEvent) {
        if dragState == .ready {
            super.addAllowedPointer(event: event)
            tapStatusTracker.addAllowedPointer(event)
            primaryPointer = event.pointer
            globalDistanceMoved = 0.0
            globalDistanceMovedAllAxes = 0.0
            dragState = .possible
            initialPosition = OffsetPair(local: event.localPosition, global: event.position)
            deadlineTimer = backend.createTimer(deadline) { [self] in
                didExceedDeadlineWithEvent(event: event)
            }
        }
    }

    public override func handleNonAllowedPointer(event: PointerDownEvent) {
        // There can be multiple drags simultaneously. Their effects are combined.
        if event.buttons != .primaryButton {
            if !wonArenaForPrimaryPointer {
                super.handleNonAllowedPointer(event: event)
            }
        }
    }

    public override func acceptGesture(pointer: Int) {
        if pointer != primaryPointer {
            return
        }

        stopDeadlineTimer()

        assert(!acceptedActivePointers.contains(pointer))
        acceptedActivePointers.insert(pointer)

        // Called when this recognizer is accepted by the [GestureArena].
        if let currentDown = tapStatusTracker.currentDown {
            _checkTapDown(currentDown)
        }

        wonArenaForPrimaryPointer = true

        // resolve(.accepted) will be called when the [PointerMoveEvent]
        // has moved a sufficient global distance to be considered a drag and
        // `eagerVictoryOnDrag` is set to `true`.
        if let _start = start, eagerVictoryOnDrag {
            assert(dragState == .accepted)
            assert(tapStatusTracker.currentUp == nil)
            acceptDrag(_start)
        }

        // This recognizer will wait until it is the last one in the gesture arena
        // before accepting a drag when `eagerVictoryOnDrag` is set to `false`.
        if let _start = start, !eagerVictoryOnDrag {
            assert(dragState == .possible)
            assert(tapStatusTracker.currentUp == nil)
            dragState = .accepted
            acceptDrag(_start)
        }

        if let currentUp = tapStatusTracker.currentUp {
            checkTapUp(currentUp)
        }
    }

    public override func didStopTrackingLastPointer(pointer: Int) {
        switch dragState {
        case .ready:
            checkCancel()
            resolve(.rejected)

        case .possible:
            if pastSlopTolerance {
                // This means the pointer was not accepted as a tap.
                if wonArenaForPrimaryPointer {
                    // If the recognizer has already won the arena for the primary pointer being tracked
                    // but the pointer has exceeded the tap tolerance, then the pointer is accepted as a
                    // drag gesture.
                    if let currentDown = tapStatusTracker.currentDown {
                        if acceptedActivePointers.remove(pointer) == nil {
                            resolvePointer(pointer, .rejected)
                        }
                        dragState = .accepted
                        acceptDrag(currentDown)
                        checkDragEnd()
                    }
                } else {
                    checkCancel()
                    resolve(.rejected)
                }
            } else {
                // The pointer is accepted as a tap.
                if let currentUp = tapStatusTracker.currentUp {
                    checkTapUp(currentUp)
                }
            }

        case .accepted:
            // For the case when the pointer has been accepted as a drag.
            // Meaning [_checkTapDown] and [_checkDragStart] have already ran.
            checkDragEnd()
        }

        stopDeadlineTimer()
        dragState = .ready
        pastSlopTolerance = false
    }

    public override func handleEvent(event: PointerEvent) {
        if event.pointer != primaryPointer {
            return
        }
        tapStatusTracker.handleEvent(event)
        if let event = event as? PointerMoveEvent {
            // Receiving a [PointerMoveEvent], does not automatically mean the pointer
            // being tracked is doing a drag gesture. There is some drift that can happen
            // between the initial [PointerDownEvent] and subsequent [PointerMoveEvent]s.
            // Accessing [_pastSlopTolerance] lets us know if our tap has moved past the
            // acceptable tolerance. If the pointer does not move past this tolerance than
            // it is not considered a drag.
            //
            // To be recognized as a drag, the [PointerMoveEvent] must also have moved
            // a sufficient global distance from the initial [PointerDownEvent] to be
            // accepted as a drag. This logic is handled in [_hasSufficientGlobalDistanceToAccept].
            //
            // The recognizer will also detect the gesture as a drag when the pointer
            // has been accepted and it has moved past the [slopTolerance] but has not moved
            // a sufficient global distance from the initial position to be considered a drag.
            // In this case since the gesture cannot be a tap, it defaults to a drag.
            let computedSlop = computeHitSlop(event.kind, gestureSettings)
            pastSlopTolerance =
                pastSlopTolerance || getGlobalDistance(event, initialPosition) > computedSlop

            if dragState == .accepted {
                checkDragUpdate(event)
            } else if dragState == .possible {
                if start == nil {
                    // Only check for a drag if the start of a drag was not already identified.
                    checkDrag(event: event)
                }

                // This can occur when the recognizer is accepted before a [PointerMoveEvent] has been
                // received that moves the pointer a sufficient global distance to be considered a drag.
                if start != nil && wonArenaForPrimaryPointer {
                    dragState = .accepted
                    acceptDrag(start!)
                }
            }
        } else if event is PointerUpEvent {
            if dragState == .possible {
                // The drag has not been accepted before a [PointerUpEvent], therefore the recognizer
                // attempts to recognize a tap.
                stopTrackingIfPointerNoLongerDown(event: event)
            } else if dragState == .accepted {
                giveUpPointer(event.pointer)
            }
        } else if event is PointerCancelEvent {
            dragState = .ready
            giveUpPointer(event.pointer)
        }
    }

    public override func rejectGesture(pointer: Int) {
        if pointer != primaryPointer {
            return
        }
        tapStatusTracker.rejectGesture(pointer)

        stopDeadlineTimer()
        giveUpPointer(pointer)
        resetTaps()
        resetDragUpdateThrottle()
    }

    public override func dispose() {
        stopDeadlineTimer()
        resetDragUpdateThrottle()
        tapStatusTracker.dispose()
        super.dispose()
    }

    func acceptDrag(_ event: PointerEvent) {
        if !wonArenaForPrimaryPointer {
            return
        }
        if dragStartBehavior == .start {
            initialPosition =
                initialPosition + OffsetPair(local: event.localDelta, global: event.delta)
        }
        checkDragStart(event)
        if event.localDelta != .zero {
            let localToGlobal = event.transform != nil ? event.transform!.inversed : nil
            let correctedLocalPosition = initialPosition.local + event.localDelta
            let globalUpdateDelta = PointerEvent.transformDeltaViaPositions(
                transform: localToGlobal,
                untransformedDelta: event.localDelta,
                untransformedEndPosition: correctedLocalPosition
            )
            let updateDelta = OffsetPair(local: event.localDelta, global: globalUpdateDelta)
            correctedPosition = initialPosition + updateDelta  // Only adds delta for down behaviour
            checkDragUpdate(event)
            correctedPosition = nil
        }
    }

    func checkDrag(event: PointerMoveEvent) {
        let localToGlobalTransform =
            event.transform == nil ? nil : event.transform!.inversed
        let movedLocally = getDeltaForDetails(event.localDelta)
        globalDistanceMoved +=
            PointerEvent.transformDeltaViaPositions(
                transform: localToGlobalTransform,
                untransformedDelta: movedLocally,
                untransformedEndPosition: event.localPosition
            ).distance * (getPrimaryValueFromOffset(movedLocally) ?? 1).signValue
        globalDistanceMovedAllAxes +=
            PointerEvent.transformDeltaViaPositions(
                transform: localToGlobalTransform,
                untransformedDelta: event.localDelta,
                untransformedEndPosition: event.localPosition
            ).distance  // * 1.signValue
        if hasSufficientGlobalDistanceToAccept(event.kind)
            || (wonArenaForPrimaryPointer
                && globalDistanceMovedAllAxes.magnitude
                    > computePanSlop(event.kind, gestureSettings))
        {
            start = event
            if eagerVictoryOnDrag {
                dragState = .accepted
                if !wonArenaForPrimaryPointer {
                    resolve(.accepted)
                }
            }
        }
    }

    func _checkTapDown(_ event: PointerDownEvent) {
        if sentTapDown {
            return
        }

        let details = TapDragDownDetails(
            globalPosition: event.position,
            localPosition: event.localPosition,
            kind: getKindForPointer(pointer: event.pointer),
            consecutiveTapCount: tapStatusTracker.consecutiveTapCount
        )

        if onTapDown != nil {
            invokeCallback("onTapDown") { onTapDown!(details) }
        }

        sentTapDown = true
    }

    func checkTapUp(_ event: PointerUpEvent) {
        if !wonArenaForPrimaryPointer {
            return
        }

        let upDetails = TapDragUpDetails(
            kind: event.kind,
            globalPosition: event.position,
            localPosition: event.localPosition,
            consecutiveTapCount: tapStatusTracker.consecutiveTapCount
        )

        if onTapUp != nil {
            invokeCallback("onTapUp") { onTapUp!(upDetails) }
        }

        resetTaps()
        if acceptedActivePointers.remove(event.pointer) == nil {
            resolvePointer(event.pointer, .rejected)
        }
    }

    func checkDragStart(_ event: PointerEvent) {
        if onDragStart != nil {
            let details = TapDragStartDetails(
                sourceTimeStamp: event.timeStamp,
                globalPosition: initialPosition.global,
                localPosition: initialPosition.local,
                kind: getKindForPointer(pointer: event.pointer),
                consecutiveTapCount: tapStatusTracker.consecutiveTapCount
            )

            invokeCallback("onDragStart") { onDragStart!(details) }
        }

        start = nil
    }

    func checkDragUpdate(_ event: PointerEvent) {
        let globalPosition = correctedPosition != nil ? correctedPosition!.global : event.position
        let localPosition =
            correctedPosition != nil ? correctedPosition!.local : event.localPosition

        let details = TapDragUpdateDetails(
            sourceTimeStamp: event.timeStamp,
            delta: event.localDelta,
            globalPosition: globalPosition,
            kind: getKindForPointer(pointer: event.pointer),
            localPosition: localPosition,
            offsetFromOrigin: globalPosition - initialPosition.global,
            localOffsetFromOrigin: localPosition - initialPosition.local,
            consecutiveTapCount: tapStatusTracker.consecutiveTapCount
        )

        if dragUpdateThrottleFrequency != nil {
            lastDragUpdateDetails = details
            // Only schedule a new timer if there's not one pending.
            dragUpdateThrottleTimer =
                dragUpdateThrottleTimer
                ?? backend.createTimer(
                    dragUpdateThrottleFrequency!,
                    callback: _handleDragUpdateThrottled
                )
        } else {
            if onDragUpdate != nil {
                invokeCallback("onDragUpdate") { onDragUpdate!(details) }
            }
        }
    }

    func checkDragEnd() {
        if let dragUpdateThrottleTimer {
            // If there's already an update scheduled, trigger it immediately and
            // cancel the timer.
            dragUpdateThrottleTimer.cancel()
            _handleDragUpdateThrottled()
        }

        let endDetails = TapDragEndDetails(
            primaryVelocity: 0.0,
            consecutiveTapCount: tapStatusTracker.consecutiveTapCount
        )

        if onDragEnd != nil {
            invokeCallback("onDragEnd") { onDragEnd!(endDetails) }
        }

        resetTaps()
        resetDragUpdateThrottle()
    }

    func checkCancel() {
        if !sentTapDown {
            // Do not fire tap cancel if [onTapDown] was never called.
            return
        }
        if onCancel != nil {
            invokeCallback("onCancel", onCancel!)
        }
        resetDragUpdateThrottle()
        resetTaps()
    }

    func didExceedDeadlineWithEvent(event: PointerDownEvent) {
        didExceedDeadline()
    }

    func didExceedDeadline() {
        if tapStatusTracker.currentDown != nil {
            _checkTapDown(tapStatusTracker.currentDown!)

            if tapStatusTracker.consecutiveTapCount > 1 {
                // If our consecutive tap count is greater than 1, i.e. is a double tap or greater,
                // then this recognizer declares victory to prevent the [LongPressGestureRecognizer]
                // from declaring itself the winner if a double tap is held for too long.
                resolve(.accepted)
            }
        }
    }

    func giveUpPointer(_ pointer: Int) {
        stopTrackingPointer(pointer)
        // If the pointer was never accepted, then it is rejected since this recognizer is no longer
        // interested in winning the gesture arena for it.
        if acceptedActivePointers.remove(pointer) == nil {
            resolvePointer(pointer, .rejected)
        }
    }

    func resetTaps() {
        sentTapDown = false
        wonArenaForPrimaryPointer = false
        primaryPointer = nil
    }

    func resetDragUpdateThrottle() {
        if dragUpdateThrottleFrequency == nil {
            return
        }
        lastDragUpdateDetails = nil
        if dragUpdateThrottleTimer != nil {
            dragUpdateThrottleTimer!.cancel()
            dragUpdateThrottleTimer = nil
        }
    }

    func stopDeadlineTimer() {
        if let deadlineTimer {
            deadlineTimer.cancel()
            self.deadlineTimer = nil
        }
    }
}

/// Recognizes taps along with movement in the horizontal direction.
///
/// Before this recognizer has won the arena for the primary pointer being tracked,
/// it will only accept a drag on the horizontal axis. If a drag is detected after
/// this recognizer has won the arena then it will accept a drag on any axis.
///
/// See also:
///
///  * [BaseTapAndDragGestureRecognizer], for the class that provides the main
///  implementation details of this recognizer.
///  * [TapAndPanGestureRecognizer], for a similar recognizer that accepts a drag
///  on any axis regardless if the recognizer has won the arena for the primary
///  pointer being tracked.
///  * [HorizontalDragGestureRecognizer], for a similar recognizer that only recognizes
///  horizontal movement.
public class TapAndHorizontalDragGestureRecognizer: BaseTapAndDragGestureRecognizer {
    /// Create a gesture recognizer for interactions in the horizontal axis.
    init(debugOwner: AnyObject? = nil, supportedDevices: Set<PointerDeviceKind>? = nil) {
        super.init(debugOwner: debugOwner, supportedDevices: supportedDevices)
    }

    override func hasSufficientGlobalDistanceToAccept(_ pointerDeviceKind: PointerDeviceKind)
        -> Bool
    {
        return abs(globalDistanceMoved)
            > computeHitSlop(pointerDeviceKind, gestureSettings)
    }

    override func getDeltaForDetails(_ delta: Offset) -> Offset {
        return Offset(delta.dx, 0.0)
    }

    override func getPrimaryValueFromOffset(_ value: Offset) -> Float? {
        return value.dx
    }
}

/// Recognizes taps along with both horizontal and vertical movement.
///
/// This recognizer will accept a drag on any axis, regardless if it has won the
/// arena for the primary pointer being tracked.
///
/// See also:
///
///  * [BaseTapAndDragGestureRecognizer], for the class that provides the main
///  implementation details of this recognizer.
///  * [TapAndHorizontalDragGestureRecognizer], for a similar recognizer that
///  only accepts horizontal drags before it has won the arena for the primary
///  pointer being tracked.
///  * [PanGestureRecognizer], for a similar recognizer that only recognizes
///  movement.
public class TapAndPanGestureRecognizer: BaseTapAndDragGestureRecognizer {
    /// Create a gesture recognizer for interactions on a plane.
    public init(debugOwner: AnyObject? = nil, supportedDevices: Set<PointerDeviceKind>? = nil) {
        super.init(debugOwner: debugOwner, supportedDevices: supportedDevices)
    }

    override func hasSufficientGlobalDistanceToAccept(_ pointerDeviceKind: PointerDeviceKind)
        -> Bool
    {
        return abs(globalDistanceMoved)
            > computePanSlop(pointerDeviceKind, gestureSettings)
    }

    override func getDeltaForDetails(_ delta: Offset) -> Offset {
        return delta
    }

    override func getPrimaryValueFromOffset(_ value: Offset) -> Float? {
        return nil
    }
}
