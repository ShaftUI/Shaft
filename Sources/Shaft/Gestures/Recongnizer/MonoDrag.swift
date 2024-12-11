// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

private enum _DragState {
    case ready
    case possible
    case accepted
}

/// Signature for when a pointer that was previously in contact with the screen
/// and moving is no longer in contact with the screen.
///
/// The velocity at which the pointer was moving when it stopped contacting
/// the screen is available in the `details`.
///
/// Used by [DragGestureRecognizer.onEnd].
public typealias GestureDragEndCallback = (DragEndDetails) -> Void

/// Signature for when the pointer that previously triggered a
/// [GestureDragDownCallback] did not complete.
///
/// Used by [DragGestureRecognizer.onCancel].
public typealias GestureDragCancelCallback = () -> Void

/// Signature for a function that builds a [VelocityTracker].
///
/// Used by [DragGestureRecognizer.velocityTrackerBuilder].
public typealias GestureVelocityTrackerBuilder = (PointerEvent) -> VelocityTracker

/// Recognizes movement.
///
/// In contrast to [MultiDragGestureRecognizer], [DragGestureRecognizer]
/// recognizes a single gesture sequence for all the pointers it watches, which
/// means that the recognizer has at most one drag sequence active at any given
/// time regardless of how many pointers are in contact with the screen.
///
/// [DragGestureRecognizer] is not intended to be used directly. Instead,
/// consider using one of its subclasses to recognize specific types for drag
/// gestures.
///
/// [DragGestureRecognizer] competes on pointer events only when it has at
/// least one non-null callback. If it has no callbacks, it is a no-op.
///
/// See also:
///
///  * [HorizontalDragGestureRecognizer], for left and right drags.
///  * [VerticalDragGestureRecognizer], for up and down drags.
///  * [PanGestureRecognizer], for drags that are not locked to a single axis.
public class DragGestureRecognizer: OneSequenceGestureRecognizer {
    /// Initialize the object.
    init(
        debugOwner: AnyObject? = nil,
        dragStartBehavior: DragStartBehavior = .start,
        multitouchDragStrategy: MultitouchDragStrategy = .latestPointer,
        velocityTrackerBuilder: @escaping GestureVelocityTrackerBuilder = _defaultBuilder,
        onlyAcceptDragOnThreshold: Bool = false,
        supportedDevices: Set<PointerDeviceKind>? = nil,
        allowedButtonsFilter: @escaping (PointerButtons) -> Bool = _defaultButtonAcceptBehavior
    ) {
        self.dragStartBehavior = dragStartBehavior
        self.multitouchDragStrategy = multitouchDragStrategy
        self.velocityTrackerBuilder = velocityTrackerBuilder
        self.onlyAcceptDragOnThreshold = onlyAcceptDragOnThreshold
        super.init(
            debugOwner: debugOwner,
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter
        )
    }

    public static func _defaultBuilder(event: PointerEvent) -> VelocityTracker {
        return VelocityTracker(kind: event.kind)
    }

    // Accept the input if, and only if, [kPrimaryButton] is pressed.
    public static func _defaultButtonAcceptBehavior(buttons: PointerButtons) -> Bool {
        return buttons == .primaryButton
    }
    /// Configure the behavior of offsets passed to [onStart].
    ///
    /// If set to [DragStartBehavior.start], the [onStart] callback will be called
    /// with the position of the pointer at the time this gesture recognizer won
    /// the arena. If [DragStartBehavior.down], [onStart] will be called with
    /// the position of the first detected down event for the pointer. When there
    /// are no other gestures competing with this gesture in the arena, there's
    /// no difference in behavior between the two settings.
    ///
    /// For more information about the gesture arena:
    /// https://flutter.dev/to/gesture-disambiguation
    ///
    /// By default, the drag start behavior is [DragStartBehavior.start].
    ///
    /// ## Example:
    ///
    /// A [HorizontalDragGestureRecognizer] and a [VerticalDragGestureRecognizer]
    /// compete with each other. A finger presses down on the screen with
    /// offset (500.0, 500.0), and then moves to position (510.0, 500.0) before
    /// the [HorizontalDragGestureRecognizer] wins the arena. With
    /// [dragStartBehavior] set to [DragStartBehavior.down], the [onStart]
    /// callback will be called with position (500.0, 500.0). If it is
    /// instead set to [DragStartBehavior.start], [onStart] will be called with
    /// position (510.0, 500.0).
    public var dragStartBehavior: DragStartBehavior

    /// Configure the multi-finger drag strategy on multi-touch devices.
    ///
    /// If set to [MultitouchDragStrategy.latestPointer], the drag gesture recognizer
    /// will only track the latest active (accepted by this recognizer) pointer, which
    /// appears to be only one finger dragging.
    ///
    /// If set to [MultitouchDragStrategy.averageBoundaryPointers], all active
    /// pointers will be tracked, and the result is computed from the boundary pointers.
    ///
    /// If set to [MultitouchDragStrategy.sumAllPointers],
    /// all active pointers will be tracked together and the scrolling offset
    /// is the sum of the offsets of all active pointers
    ///
    /// By default, the strategy is [MultitouchDragStrategy.latestPointer].
    ///
    /// See also:
    ///
    ///  * [MultitouchDragStrategy], which defines several different drag strategies for
    ///  multi-finger drag.
    public var multitouchDragStrategy: MultitouchDragStrategy

    /// A pointer has contacted the screen with a primary button and might begin
    /// to move.
    ///
    /// The position of the pointer is provided in the callback's `details`
    /// argument, which is a [DragDownDetails] object.
    ///
    /// See also:
    ///
    ///  * [allowedButtonsFilter], which decides which button will be allowed.
    ///  * [DragDownDetails], which is passed as an argument to this callback.
    public var onDown: GestureDragDownCallback?

    /// A pointer has contacted the screen with a primary button and has begun to
    /// move.
    ///
    /// The position of the pointer is provided in the callback's `details`
    /// argument, which is a [DragStartDetails] object. The [dragStartBehavior]
    /// determines this position.
    ///
    /// See also:
    ///
    ///  * [allowedButtonsFilter], which decides which button will be allowed.
    ///  * [DragStartDetails], which is passed as an argument to this callback.
    public var onStart: GestureDragStartCallback?

    /// A pointer that is in contact with the screen with a primary button and
    /// moving has moved again.
    ///
    /// The distance traveled by the pointer since the last update is provided in
    /// the callback's `details` argument, which is a [DragUpdateDetails] object.
    ///
    /// If this gesture recognizer recognizes movement on a single axis (a
    /// [VerticalDragGestureRecognizer] or [HorizontalDragGestureRecognizer]),
    /// then `details` will reflect movement only on that axis and its
    /// [DragUpdateDetails.primaryDelta] will be non-null.
    /// If this gesture recognizer recognizes movement in all directions
    /// (a [PanGestureRecognizer]), then `details` will reflect movement on
    /// both axes and its [DragUpdateDetails.primaryDelta] will be null.
    ///
    /// See also:
    ///
    ///  * [allowedButtonsFilter], which decides which button will be allowed.
    ///  * [DragUpdateDetails], which is passed as an argument to this callback.
    public var onUpdate: GestureDragUpdateCallback?

    /// A pointer that was previously in contact with the screen with a primary
    /// button and moving is no longer in contact with the screen and was moving
    /// at a specific velocity when it stopped contacting the screen.
    ///
    /// The velocity is provided in the callback's `details` argument, which is a
    /// [DragEndDetails] object.
    ///
    /// If this gesture recognizer recognizes movement on a single axis (a
    /// [VerticalDragGestureRecognizer] or [HorizontalDragGestureRecognizer]),
    /// then `details` will reflect movement only on that axis and its
    /// [DragEndDetails.primaryVelocity] will be non-null.
    /// If this gesture recognizer recognizes movement in all directions
    /// (a [PanGestureRecognizer]), then `details` will reflect movement on
    /// both axes and its [DragEndDetails.primaryVelocity] will be null.
    ///
    /// See also:
    ///
    ///  * [allowedButtonsFilter], which decides which button will be allowed.
    ///  * [DragEndDetails], which is passed as an argument to this callback.
    public var onEnd: GestureDragEndCallback?

    /// The pointer that previously triggered [onDown] did not complete.
    ///
    /// See also:
    ///
    ///  * [allowedButtonsFilter], which decides which button will be allowed.
    public var onCancel: GestureDragCancelCallback?

    /// The minimum distance an input pointer drag must have moved
    /// to be considered a fling gesture.
    ///
    /// This value is typically compared with the distance traveled along the
    /// scrolling axis. If null then [kTouchSlop] is used.
    public var minFlingDistance: Float?

    /// The minimum velocity for an input pointer drag to be considered fling.
    ///
    /// This value is typically compared with the magnitude of fling gesture's
    /// velocity along the scrolling axis. If null then [kMinFlingVelocity]
    /// is used.
    public var minFlingVelocity: Float?

    /// Fling velocity magnitudes will be clamped to this value.
    ///
    /// If null then [kMaxFlingVelocity] is used.
    public var maxFlingVelocity: Float?

    /// Whether the drag threshold should be met before dispatching any drag callbacks.
    ///
    /// The drag threshold is met when the global distance traveled by a pointer has
    /// exceeded the defined threshold on the relevant axis, i.e. y-axis for the
    /// [VerticalDragGestureRecognizer], x-axis for the [HorizontalDragGestureRecognizer],
    /// and the entire plane for [PanGestureRecognizer]. The threshold for both
    /// [VerticalDragGestureRecognizer] and [HorizontalDragGestureRecognizer] are
    /// calculated by [computeHitSlop], while [computePanSlop] is used for
    /// [PanGestureRecognizer].
    ///
    /// If true, the drag callbacks will only be dispatched when this recognizer has
    /// won the arena and the drag threshold has been met.
    ///
    /// If false, the drag callbacks will be dispatched immediately when this recognizer
    /// has won the arena.
    ///
    /// This value defaults to false.
    public var onlyAcceptDragOnThreshold: Bool

    /// Determines the type of velocity estimation method to use for a potential
    /// drag gesture, when a new pointer is added.
    ///
    /// To estimate the velocity of a gesture, [DragGestureRecognizer] calls
    /// [velocityTrackerBuilder] when it starts to track a new pointer in
    /// [addAllowedPointer], and add subsequent updates on the pointer to the
    /// resulting velocity tracker, until the gesture recognizer stops tracking
    /// the pointer. This allows you to specify a different velocity estimation
    /// strategy for each allowed pointer added, by changing the type of velocity
    /// tracker this [GestureVelocityTrackerBuilder] returns.
    ///
    /// If left unspecified the default [velocityTrackerBuilder] creates a new
    /// [VelocityTracker] for every pointer added.
    ///
    /// See also:
    ///
    ///  * [VelocityTracker], a velocity tracker that uses least squares estimation
    ///    on the 20 most recent pointer data samples. It's a well-rounded velocity
    ///    tracker and is used by default.
    ///  * [IOSScrollViewFlingVelocityTracker], a specialized velocity tracker for
    ///    determining the initial fling velocity for a [Scrollable] on iOS, to
    ///    match the native behavior on that platform.
    public var velocityTrackerBuilder: GestureVelocityTrackerBuilder

    private var _state: _DragState = .ready
    private var _initialPosition: OffsetPair!
    private var _pendingDragOffset: OffsetPair!
    fileprivate var _finalPosition: OffsetPair!
    private var _lastPendingEventTimestamp: Duration?

    /// When asserts are enabled, returns the last tracked pending event timestamp
    /// for this recognizer.
    ///
    /// Otherwise, returns null.
    ///
    /// This getter is intended for use in framework unit tests. Applications must
    /// not depend on its value.
    package var debugLastPendingEventTimestamp: Duration? {
        var lastPendingEventTimestamp: Duration?
        assert(
            {
                lastPendingEventTimestamp = _lastPendingEventTimestamp
                return true
            }()
        )
        return lastPendingEventTimestamp
    }

    // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
    // different set of buttons, the gesture is canceled.
    private var _initialButtons: PointerButtons?
    private var _lastTransform: Matrix4x4f?

    /// Distance moved in the global coordinate space of the screen in drag direction.
    ///
    /// If drag is only allowed along a defined axis, this value may be negative to
    /// differentiate the direction of the drag.
    fileprivate var _globalDistanceMoved: Float!

    /// Determines if a gesture is a fling or not based on velocity.
    ///
    /// A fling calls its gesture end callback with a velocity, allowing the
    /// provider of the callback to respond by carrying the gesture forward with
    /// inertia, for example.
    public func isFlingGesture(_ estimate: VelocityEstimate, _ kind: PointerDeviceKind) -> Bool {
        fatalError()
    }

    /// Determines if a gesture is a fling or not, and if so its effective velocity.
    ///
    /// A fling calls its gesture end callback with a velocity, allowing the
    /// provider of the callback to respond by carrying the gesture forward with
    /// inertia, for example.
    fileprivate func _considerFling(_ estimate: VelocityEstimate, _ kind: PointerDeviceKind)
        -> DragEndDetails?
    {
        fatalError()
    }

    fileprivate func _getDeltaForDetails(_ delta: Offset) -> Offset {
        fatalError()
    }
    fileprivate func _getPrimaryValueFromOffset(_ value: Offset) -> Float? {
        fatalError()
    }

    /// The axis (horizontal or vertical) corresponding to the primary drag direction.
    ///
    /// The [PanGestureRecognizer] returns null.
    fileprivate func _getPrimaryDragAxis() -> _DragDirection? { return nil }
    fileprivate func _hasSufficientGlobalDistanceToAccept(
        _ pointerDeviceKind: PointerDeviceKind,
        _ deviceTouchSlop: Float?
    ) -> Bool {
        fatalError()
    }
    private var _hasDragThresholdBeenMet: Bool = false
    private var _velocityTrackers: [Int: VelocityTracker] = [:]

    // The move delta of each pointer before the next frame.
    //
    // The key is the pointer ID. It is cleared whenever a new batch of pointer events is detected.
    private var _moveDeltaBeforeFrame: [Int: Offset] = [:]

    // The timestamp of all events of the current frame.
    //
    // On a event with a different timestamp, the event is considered a new batch.
    private var _frameTimeStamp: Duration?
    private var _lastUpdatedDeltaForPan: Offset = .zero

    public override func isPointerAllowed(event: PointerEvent) -> Bool {
        if _initialButtons == nil {
            if onDown == nil && onStart == nil && onUpdate == nil && onEnd == nil && onCancel == nil
            {
                return false
            }
        } else {
            // There can be multiple drags simultaneously. Their effects are combined.
            if event.buttons != _initialButtons {
                return false
            }
        }
        return super.isPointerAllowed(event: event as! PointerDownEvent)
    }

    private func _addPointer(_ event: PointerEvent) {
        _velocityTrackers[event.pointer] = velocityTrackerBuilder(event)
        switch _state {
        case .ready:
            _state = .possible
            _initialPosition = OffsetPair(local: event.localPosition, global: event.position)
            _finalPosition = _initialPosition
            _pendingDragOffset = .zero
            _globalDistanceMoved = 0.0
            _lastPendingEventTimestamp = event.timeStamp
            _lastTransform = event.transform
            _checkDown()
        case .possible:
            break
        case .accepted:
            resolve(.accepted)
        }
    }

    public override func addAllowedPointer(event: PointerDownEvent) {
        super.addAllowedPointer(event: event)
        if _state == .ready {
            _initialButtons = event.buttons
        }
        _addPointer(event)
    }

    public override func addAllowedPointerPanZoom(event: PointerPanZoomStartEvent) {
        super.addAllowedPointerPanZoom(event: event)
        startTrackingPointer(event.pointer, transform: event.transform)
        if _state == .ready {
            _initialButtons = .primaryButton
        }
        _addPointer(event)
    }

    private func _shouldTrackMoveEvent(pointer: Int) -> Bool {
        let result: Bool
        switch multitouchDragStrategy {
        case .sumAllPointers, .averageBoundaryPointers:
            result = true
        case .latestPointer:
            result = _activePointer == nil || pointer == _activePointer
        }
        return result
    }

    private func _recordMoveDeltaForMultitouch(_ pointer: Int, _ localDelta: Offset) {
        if multitouchDragStrategy != .averageBoundaryPointers {
            assert(_frameTimeStamp == nil)
            assert(_moveDeltaBeforeFrame.isEmpty)
            return
        }

        // assert(_frameTimeStamp == SchedulerBinding.shared.currentSystemFrameTimeStamp)

        if _state != .accepted || localDelta == .zero {
            return
        }

        if _moveDeltaBeforeFrame[pointer] != nil {
            let offset = _moveDeltaBeforeFrame[pointer]!
            _moveDeltaBeforeFrame[pointer] = offset + localDelta
        } else {
            _moveDeltaBeforeFrame[pointer] = localDelta
        }
    }

    private func _getSumDelta(pointer: Int, positive: Bool, axis: _DragDirection) -> Float {
        var sum: Float = 0.0

        if _moveDeltaBeforeFrame[pointer] == nil {
            return sum
        }

        let offset = _moveDeltaBeforeFrame[pointer]!
        if positive {
            if axis == .vertical {
                sum = max(offset.dy, 0.0)
            } else {
                sum = max(offset.dx, 0.0)
            }
        } else {
            if axis == .vertical {
                sum = min(offset.dy, 0.0)
            } else {
                sum = min(offset.dx, 0.0)
            }
        }

        return sum
    }

    private func _getMaxSumDeltaPointer(positive: Bool, axis: _DragDirection) -> Int? {
        if _moveDeltaBeforeFrame.isEmpty {
            return nil
        }

        var ret: Int?
        var max: Float?
        var sum: Float
        for pointer in _moveDeltaBeforeFrame.keys {
            sum = _getSumDelta(pointer: pointer, positive: positive, axis: axis)
            if ret == nil {
                ret = pointer
                max = sum
            } else {
                if positive {
                    if sum > max! {
                        ret = pointer
                        max = sum
                    }
                } else {
                    if sum < max! {
                        ret = pointer
                        max = sum
                    }
                }
            }
        }
        assert(ret != nil)
        return ret
    }

    private func _resolveLocalDeltaForMultitouch(_ pointer: Int, _ localDelta: Offset) -> Offset {
        if multitouchDragStrategy != .averageBoundaryPointers {
            if _frameTimeStamp != nil {
                _moveDeltaBeforeFrame.removeAll()
                _frameTimeStamp = nil
                _lastUpdatedDeltaForPan = .zero
            }
            return localDelta
        }

        let currentSystemFrameTimeStamp = SchedulerBinding.shared.currentSystemFrameTimeStamp
        if _frameTimeStamp != currentSystemFrameTimeStamp {
            _moveDeltaBeforeFrame.removeAll()
            _lastUpdatedDeltaForPan = .zero
            _frameTimeStamp = currentSystemFrameTimeStamp
        }

        assert(_frameTimeStamp == SchedulerBinding.shared.currentSystemFrameTimeStamp)

        let axis = _getPrimaryDragAxis()

        if _state != .accepted || localDelta == .zero
            || (_moveDeltaBeforeFrame.isEmpty && axis != nil)
        {
            return localDelta
        }

        let dx: Float
        let dy: Float
        if axis == .horizontal {
            dx = _resolveDelta(pointer: pointer, axis: .horizontal, localDelta: localDelta)
            assert(abs(dx) <= abs(localDelta.dx))
            dy = 0.0
        } else if axis == .vertical {
            dx = 0.0
            dy = _resolveDelta(pointer: pointer, axis: .vertical, localDelta: localDelta)
            assert(abs(dy) <= abs(localDelta.dy))
        } else {
            let averageX = _resolveDeltaForPanGesture(axis: .horizontal, localDelta: localDelta)
            let averageY = _resolveDeltaForPanGesture(axis: .vertical, localDelta: localDelta)
            let updatedDelta = Offset(averageX, averageY) - _lastUpdatedDeltaForPan
            _lastUpdatedDeltaForPan = Offset(averageX, averageY)
            dx = updatedDelta.dx
            dy = updatedDelta.dy
        }

        return Offset(dx, dy)
    }

    private func _resolveDelta(pointer: Int, axis: _DragDirection, localDelta: Offset) -> Float {
        let positive = axis == .horizontal ? localDelta.dx > 0 : localDelta.dy > 0
        let delta = axis == .horizontal ? localDelta.dx : localDelta.dy
        let maxSumDeltaPointer = _getMaxSumDeltaPointer(positive: positive, axis: axis)
        assert(maxSumDeltaPointer != nil)

        if maxSumDeltaPointer == pointer {
            return delta
        } else {
            let maxSumDelta = _getSumDelta(
                pointer: maxSumDeltaPointer!,
                positive: positive,
                axis: axis
            )
            let curPointerSumDelta = _getSumDelta(pointer: pointer, positive: positive, axis: axis)
            if positive {
                if curPointerSumDelta + delta > maxSumDelta {
                    return curPointerSumDelta + delta - maxSumDelta
                } else {
                    return 0.0
                }
            } else {
                if curPointerSumDelta + delta < maxSumDelta {
                    return curPointerSumDelta + delta - maxSumDelta
                } else {
                    return 0.0
                }
            }
        }
    }
    private func _resolveDeltaForPanGesture(axis: _DragDirection, localDelta: Offset) -> Float {
        let delta = axis == .horizontal ? localDelta.dx : localDelta.dy
        let pointerCount = _acceptedActivePointers.count
        assert(pointerCount >= 1)

        var sum = delta
        for offset in _moveDeltaBeforeFrame.values {
            if axis == .horizontal {
                sum += offset.dx
            } else {
                sum += offset.dy
            }
        }
        return sum / Float(pointerCount)
    }

    public override func handleEvent(event: PointerEvent) {
        assert(_state != .ready)
        if event is PointerDownEvent || event is PointerMoveEvent
            || event is PointerPanZoomStartEvent || event is PointerPanZoomUpdateEvent
        {
            let position: Offset =
                switch event {
                case is PointerPanZoomStartEvent:
                    .zero
                case let panEvent as PointerPanZoomUpdateEvent:
                    panEvent.pan
                default:
                    event.localPosition
                }
            _velocityTrackers[event.pointer]?.addPosition(event.timeStamp, position)
        }
        if let moveEvent = event as? PointerMoveEvent, moveEvent.buttons != _initialButtons {
            _giveUpPointer(pointer: event.pointer)
            return
        }
        if (event is PointerMoveEvent || event is PointerPanZoomUpdateEvent)
            && _shouldTrackMoveEvent(pointer: event.pointer)
        {
            let delta =
                (event is PointerMoveEvent)
                ? (event as! PointerMoveEvent).delta
                : (event as! PointerPanZoomUpdateEvent).panDelta
            let localDelta =
                (event is PointerMoveEvent)
                ? (event as! PointerMoveEvent).localDelta
                : (event as! PointerPanZoomUpdateEvent).localPanDelta
            let position =
                (event is PointerMoveEvent)
                ? (event as! PointerMoveEvent).position
                : (event.position + (event as! PointerPanZoomUpdateEvent).pan)
            let localPosition =
                (event is PointerMoveEvent)
                ? (event as! PointerMoveEvent).localPosition
                : (event.localPosition + (event as! PointerPanZoomUpdateEvent).localPan)
            _finalPosition = OffsetPair(local: localPosition, global: position)
            let resolvedDelta = _resolveLocalDeltaForMultitouch(
                event.pointer,
                localDelta
            )
            switch _state {
            case .ready, .possible:
                _pendingDragOffset =
                    _pendingDragOffset + OffsetPair(local: localDelta, global: delta)
                _lastPendingEventTimestamp = event.timeStamp
                _lastTransform = event.transform
                let movedLocally = _getDeltaForDetails(localDelta)
                let localToGlobalTransform =
                    event.transform == nil ? nil : event.transform!.inversed
                _globalDistanceMoved +=
                    PointerEvent.transformDeltaViaPositions(
                        transform: localToGlobalTransform,
                        untransformedDelta: movedLocally,
                        untransformedEndPosition: localPosition
                    ).distance * (_getPrimaryValueFromOffset(movedLocally) ?? 1).signValue
                if _hasSufficientGlobalDistanceToAccept(event.kind, gestureSettings?.touchSlop) {
                    _hasDragThresholdBeenMet = true
                    if _acceptedActivePointers.contains(event.pointer) {
                        _checkDrag(pointer: event.pointer)
                    } else {
                        resolve(.accepted)
                    }
                }
            case .accepted:
                _checkUpdate(
                    sourceTimeStamp: event.timeStamp,
                    delta: _getDeltaForDetails(resolvedDelta),
                    primaryDelta: _getPrimaryValueFromOffset(resolvedDelta),
                    globalPosition: position,
                    localPosition: localPosition
                )
            }
            _recordMoveDeltaForMultitouch(event.pointer, localDelta)
        }
        if event is PointerUpEvent || event is PointerCancelEvent || event is PointerPanZoomEndEvent
        {
            _giveUpPointer(pointer: event.pointer)
        }
    }

    private var _acceptedActivePointers: [Int] = []
    // This value is used when the multitouch strategy is `latestPointer`,
    // it keeps track of the last accepted pointer. If this active pointer
    // leave up, it will be set to the first accepted pointer.
    // Refer to the implementation of Android `RecyclerView`(line 3846):
    // https://android.googlesource.com/platform/frameworks/support/+/refs/heads/androidx-main/recyclerview/recyclerview/src/main/java/androidx/recyclerview/widget/RecyclerView.java
    private var _activePointer: Int?

    public override func acceptGesture(pointer: Int) {
        assert(!_acceptedActivePointers.contains(pointer))
        _acceptedActivePointers.append(pointer)
        _activePointer = pointer
        if !onlyAcceptDragOnThreshold || _hasDragThresholdBeenMet {
            _checkDrag(pointer: pointer)
        }
    }

    public override func rejectGesture(pointer: Int) {
        _giveUpPointer(pointer: pointer)
    }

    public override func didStopTrackingLastPointer(pointer: Int) {
        assert(_state != .ready)
        switch _state {
        case .ready:
            break
        case .possible:
            resolve(.rejected)
            _checkCancel()
        case .accepted:
            _checkEnd(pointer: pointer)
        }
        _hasDragThresholdBeenMet = false
        _velocityTrackers.removeAll()
        _initialButtons = nil
        _state = .ready
    }

    private func _giveUpPointer(pointer: Int) {
        stopTrackingPointer(pointer)
        // If we never accepted the pointer, we reject it since we are no longer
        // interested in winning the gesture arena for it.
        if !_acceptedActivePointers.contains(pointer) {
            resolvePointer(pointer, .rejected)
        }
        _acceptedActivePointers.removeAll { $0 == pointer }
        _moveDeltaBeforeFrame.removeValue(forKey: pointer)
        if _activePointer == pointer {
            _activePointer = _acceptedActivePointers.isEmpty ? nil : _acceptedActivePointers.first
        }
    }

    private func _checkDown() {
        if onDown != nil {
            let details = DragDownDetails(
                globalPosition: _initialPosition.global,
                localPosition: _initialPosition.local
            )
            invokeCallback("onDown") { self.onDown?(details) }
        }
    }

    private func _checkDrag(pointer: Int) {
        if _state == .accepted {
            return
        }
        _state = .accepted
        let delta = _pendingDragOffset!
        let timestamp = _lastPendingEventTimestamp
        let transform = _lastTransform
        let localUpdateDelta: Offset
        switch dragStartBehavior {
        case .start:
            _initialPosition = _initialPosition + delta
            localUpdateDelta = .zero
        case .down:
            localUpdateDelta = _getDeltaForDetails(delta.local)
        }
        _pendingDragOffset = .zero
        _lastPendingEventTimestamp = nil
        _lastTransform = nil
        _checkStart(timestamp: timestamp, pointer: pointer)
        if localUpdateDelta != .zero && onUpdate != nil {
            let localToGlobal = transform != nil ? transform!.inversed : nil
            let correctedLocalPosition = _initialPosition.local + localUpdateDelta
            let globalUpdateDelta = PointerEvent.transformDeltaViaPositions(
                transform: localToGlobal,
                untransformedDelta: localUpdateDelta,
                untransformedEndPosition: correctedLocalPosition,
                transformedEndPosition: nil
            )
            let updateDelta = OffsetPair(local: localUpdateDelta, global: globalUpdateDelta)
            let correctedPosition = _initialPosition + updateDelta  // Only adds delta for down behaviour
            _checkUpdate(
                sourceTimeStamp: timestamp,
                delta: localUpdateDelta,
                primaryDelta: _getPrimaryValueFromOffset(localUpdateDelta),
                globalPosition: correctedPosition.global,
                localPosition: correctedPosition.local
            )
        }
        // This acceptGesture might have been called only for one pointer, instead
        // of all pointers. Resolve all pointers to `accepted`. This won't cause
        // infinite recursion because an accepted pointer won't be accepted again.
        resolve(.accepted)
    }

    private func _checkStart(timestamp: Duration?, pointer: Int) {
        if onStart != nil {
            let details = DragStartDetails(
                sourceTimeStamp: timestamp,
                globalPosition: _initialPosition.global,
                localPosition: _initialPosition.local,
                kind: getKindForPointer(pointer: pointer)
            )
            invokeCallback("onStart") { self.onStart?(details) }
        }
    }
    private func _checkUpdate(
        sourceTimeStamp: Duration?,
        delta: Offset,
        primaryDelta: Float?,
        globalPosition: Offset,
        localPosition: Offset?
    ) {
        if onUpdate != nil {
            let details = DragUpdateDetails(
                sourceTimeStamp: sourceTimeStamp,
                delta: delta,
                primaryDelta: primaryDelta,
                globalPosition: globalPosition,
                localPosition: localPosition
            )
            invokeCallback("onUpdate") { self.onUpdate?(details) }
        }
    }

    private func _checkEnd(pointer: Int) {
        if onEnd == nil {
            return
        }

        let tracker = _velocityTrackers[pointer]!
        let estimate = tracker.getVelocityEstimate()

        var details: DragEndDetails?
        // let debugReport: () -> String
        if estimate == nil {
            // debugReport = { "Could not estimate velocity." }
        } else {
            details = _considerFling(estimate!, tracker.kind)
            // debugReport =
            //     details != nil
            //     ? { "\(estimate!); fling at \(details!.velocity)." }
            //     : { "\(estimate!); judged to not be a fling." }
        }
        details =
            details
            ?? DragEndDetails(
                primaryVelocity: 0.0,
                globalPosition: _finalPosition.global,
                localPosition: _finalPosition.local
            )

        invokeCallback("onEnd", { self.onEnd?(details!) })
    }

    private func _checkCancel() {
        if onCancel != nil {
            invokeCallback("onCancel", onCancel!)
        }
    }

    public override func dispose() {
        _velocityTrackers.removeAll()
        super.dispose()
    }

}

/// Recognizes movement in the vertical direction.
///
/// Used for vertical scrolling.
///
/// See also:
///
///  * [HorizontalDragGestureRecognizer], for a similar recognizer but for
///    horizontal movement.
///  * [MultiDragGestureRecognizer], for a family of gesture recognizers that
///    track each touch point independently.
public class VerticalDragGestureRecognizer: DragGestureRecognizer {
    /// Create a gesture recognizer for interactions in the vertical axis.
    public init(
        debugOwner: AnyObject? = nil,
        supportedDevices: Set<PointerDeviceKind>? = nil,
        allowedButtonsFilter: @escaping (PointerButtons) -> Bool = DragGestureRecognizer
            ._defaultButtonAcceptBehavior
    ) {
        super.init(
            debugOwner: debugOwner,
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter
        )
    }

    public override func isFlingGesture(_ estimate: VelocityEstimate, _ kind: PointerDeviceKind)
        -> Bool
    {
        let minVelocity = minFlingVelocity ?? kMinFlingVelocity
        let minDistance = minFlingDistance ?? computeHitSlop(kind, gestureSettings)
        return abs(estimate.pixelsPerSecond.dy) > minVelocity
            && abs(estimate.offset.dy) > minDistance
    }

    fileprivate override func _considerFling(
        _ estimate: VelocityEstimate,
        _ kind: PointerDeviceKind
    ) -> DragEndDetails? {
        if !isFlingGesture(estimate, kind) {
            return nil
        }
        let maxVelocity = maxFlingVelocity ?? kMaxFlingVelocity
        let dy = estimate.pixelsPerSecond.dy.clamped(to: -maxVelocity...maxVelocity)
        return DragEndDetails(
            velocity: Velocity(pixelsPerSecond: Offset(0, dy)),
            primaryVelocity: dy,
            globalPosition: _finalPosition.global,
            localPosition: _finalPosition.local
        )
    }

    fileprivate override func _hasSufficientGlobalDistanceToAccept(
        _ pointerDeviceKind: PointerDeviceKind,
        _ deviceTouchSlop: Float?
    ) -> Bool {
        return abs(_globalDistanceMoved) > computeHitSlop(pointerDeviceKind, gestureSettings)
    }

    fileprivate override func _getDeltaForDetails(_ delta: Offset) -> Offset {
        return Offset(0.0, delta.dy)
    }

    fileprivate override func _getPrimaryValueFromOffset(_ value: Offset) -> Float {
        return value.dy
    }

    fileprivate override func _getPrimaryDragAxis() -> _DragDirection? {
        return .vertical
    }
}

/// Recognizes movement in the horizontal direction.
///
/// Used for horizontal scrolling.
///
/// See also:
///
///  * [VerticalDragGestureRecognizer], for a similar recognizer but for
///    vertical movement.
///  * [MultiDragGestureRecognizer], for a family of gesture recognizers that
///    track each touch point independently.
public class HorizontalDragGestureRecognizer: DragGestureRecognizer {
    /// Create a gesture recognizer for interactions in the horizontal axis.
    public init(
        debugOwner: AnyObject? = nil,
        supportedDevices: Set<PointerDeviceKind>? = nil,
        allowedButtonsFilter: @escaping (PointerButtons) -> Bool = DragGestureRecognizer
            ._defaultButtonAcceptBehavior
    ) {
        super.init(
            debugOwner: debugOwner,
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter
        )
    }

    public override func isFlingGesture(_ estimate: VelocityEstimate, _ kind: PointerDeviceKind)
        -> Bool
    {
        let minVelocity = minFlingVelocity ?? kMinFlingVelocity
        let minDistance = minFlingDistance ?? computeHitSlop(kind, gestureSettings)
        return abs(estimate.pixelsPerSecond.dx) > minVelocity
            && abs(estimate.offset.dx) > minDistance
    }

    fileprivate override func _considerFling(
        _ estimate: VelocityEstimate,
        _ kind: PointerDeviceKind
    ) -> DragEndDetails? {
        if !isFlingGesture(estimate, kind) {
            return nil
        }
        let maxVelocity = maxFlingVelocity ?? kMaxFlingVelocity
        let dx = estimate.pixelsPerSecond.dx.clamped(to: -maxVelocity...maxVelocity)
        return DragEndDetails(
            velocity: Velocity(pixelsPerSecond: Offset(dx, 0)),
            primaryVelocity: dx,
            globalPosition: _finalPosition.global,
            localPosition: _finalPosition.local
        )
    }

    fileprivate override func _hasSufficientGlobalDistanceToAccept(
        _ pointerDeviceKind: PointerDeviceKind,
        _ deviceTouchSlop: Float?
    ) -> Bool {
        return abs(_globalDistanceMoved) > computeHitSlop(pointerDeviceKind, gestureSettings)
    }

    fileprivate override func _getDeltaForDetails(_ delta: Offset) -> Offset {
        return Offset(delta.dx, 0.0)
    }

    fileprivate override func _getPrimaryValueFromOffset(_ value: Offset) -> Float {
        return value.dx
    }

    fileprivate override func _getPrimaryDragAxis() -> _DragDirection? {
        return .horizontal
    }
}

/// Recognizes movement both horizontally and vertically.
///
/// See also:
///
///  * [ImmediateMultiDragGestureRecognizer], for a similar recognizer that
///    tracks each touch point independently.
///  * [DelayedMultiDragGestureRecognizer], for a similar recognizer that
///    tracks each touch point independently, but that doesn't start until
///    some time has passed.
public class PanGestureRecognizer: DragGestureRecognizer {
    /// Create a gesture recognizer for tracking movement on a plane.
    public init(
        debugOwner: AnyObject? = nil,
        supportedDevices: Set<PointerDeviceKind>? = nil,
        allowedButtonsFilter: @escaping (PointerButtons) -> Bool = DragGestureRecognizer
            ._defaultButtonAcceptBehavior
    ) {
        super.init(
            debugOwner: debugOwner,
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter
        )
    }

    public override func isFlingGesture(_ estimate: VelocityEstimate, _ kind: PointerDeviceKind)
        -> Bool
    {
        let minVelocity = minFlingVelocity ?? kMinFlingVelocity
        let minDistance = minFlingDistance ?? computeHitSlop(kind, gestureSettings)
        return estimate.pixelsPerSecond.distanceSquared > minVelocity * minVelocity
            && estimate.offset.distanceSquared > minDistance * minDistance
    }

    fileprivate override func _considerFling(
        _ estimate: VelocityEstimate,
        _ kind: PointerDeviceKind
    ) -> DragEndDetails? {
        if !isFlingGesture(estimate, kind) {
            return nil
        }
        let velocity = Velocity(pixelsPerSecond: estimate.pixelsPerSecond)
            .clampMagnitude(
                minValue: minFlingVelocity ?? kMinFlingVelocity,
                maxValue: maxFlingVelocity ?? kMaxFlingVelocity
            )
        return DragEndDetails(
            velocity: velocity,
            globalPosition: _finalPosition.global,
            localPosition: _finalPosition.local
        )
    }

    fileprivate override func _hasSufficientGlobalDistanceToAccept(
        _ pointerDeviceKind: PointerDeviceKind,
        _ deviceTouchSlop: Float?
    ) -> Bool {
        return abs(_globalDistanceMoved) > computePanSlop(pointerDeviceKind, gestureSettings)
    }

    fileprivate override func _getDeltaForDetails(_ delta: Offset) -> Offset {
        return delta
    }

    fileprivate override func _getPrimaryValueFromOffset(_ value: Offset) -> Float? {
        return nil
    }

    fileprivate override func _getPrimaryDragAxis() -> _DragDirection? {
        return nil
    }
}
private enum _DragDirection {
    case horizontal
    case vertical
}
