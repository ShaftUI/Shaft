// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// Generic signature for callbacks passed to
/// [GestureRecognizer.invokeCallback]. This allows the
/// [GestureRecognizer.invokeCallback] mechanism to be generically used with
/// anonymous functions that return objects of particular types.
public typealias RecognizerCallback<T> = () -> T

/// Configuration of offset passed to [DragStartDetails].
///
/// See also:
///
///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for the
///  different behaviors.
public enum DragStartBehavior {
    /// Set the initial offset at the position where the first down event was
    /// detected.
    case down

    /// Set the initial position at the position where this gesture recognizer
    /// won the arena.
    case start
}

/// Configuration of multi-finger drag strategy on multi-touch devices.
///
/// When dragging with only one finger, there's no difference in behavior
/// between all the settings.
///
/// Used by [DragGestureRecognizer.multitouchDragStrategy].
public enum MultitouchDragStrategy {
    /// Only the latest active pointer is tracked by the recognizer.
    ///
    /// If the tracked pointer is released, the first accepted of the remaining active
    /// pointers will continue to be tracked.
    ///
    /// This is the behavior typically seen on Android.
    case latestPointer

    /// All active pointers will be tracked, and the result is computed from
    /// the boundary pointers.
    ///
    /// The scrolling offset is determined by the maximum deltas of both directions.
    ///
    /// If the user is dragging with 3 pointers at the same time, each having
    /// \[+10, +20, +33\] pixels of offset, the recognizer will report a delta of 33 pixels.
    ///
    /// If the user is dragging with 5 pointers at the same time, each having
    /// \[+10, +20, +33, -1, -12\] pixels of offset, the recognizer will report a
    /// delta of (+33) + (-12) = 21 pixels.
    ///
    /// The panning [PanGestureRecognizer] offset is the average of all pointers.
    ///
    /// If the user is dragging with 3 pointers at the same time, each having
    /// \[+10, +50, -30\] pixels of offset in one direction (horizontal or vertical),
    /// the recognizer will report a delta of (10 + 50 -30) / 3 = 10 pixels in this direction.
    ///
    /// This is the behavior typically seen on iOS.
    case averageBoundaryPointers

    /// All active pointers will be tracked together. The scrolling offset
    /// is the sum of the offsets of all active pointers.
    ///
    /// When a [Scrollable] drives scrolling by this drag strategy, the scrolling
    /// speed will double or triple, depending on how many fingers are dragging
    /// at the same time.
    ///
    /// If the user is dragging with 3 pointers at the same time, each having
    /// \[+10, +20, +33\] pixels of offset, the recognizer will report a delta
    /// of 10 + 20 + 33 = 63 pixels.
    ///
    /// If the user is dragging with 5 pointers at the same time, each having
    /// \[+10, +20, +33, -1, -12\] pixels of offset, the recognizer will report
    /// a delta of 10 + 20 + 33 - 1 - 12 = 50 pixels.
    case sumAllPointers
}
/// Signature for `allowedButtonsFilter` in [GestureRecognizer].
/// Used to filter the input buttons of incoming pointer events.
/// The parameter `buttons` comes from [PointerEvent.buttons].
public typealias AllowedButtonsFilter = (PointerButtons) -> Bool

/// The base class that all gesture recognizers inherit from.
///
/// Provides a basic API that can be used by classes that work with
/// gesture recognizers but don't care about the specific details of
/// the gestures recognizers themselves.
open class GestureRecognizer: GestureArenaMember {
    public init(
        debugOwner: AnyObject? = nil,
        supportedDevices: Set<PointerDeviceKind>? = nil,
        allowedButtonsFilter: AllowedButtonsFilter? = nil
    ) {
        self.debugOwner = debugOwner
        self.supportedDevices = supportedDevices
        self.allowedButtonsFilter = allowedButtonsFilter ?? Self.defaultButtonAcceptBehavior
    }

    /// Initializes the gesture recognizer.

    /// The recognizer's owner.
    ///
    /// This is used in the [toString] serialization to report the object for which
    /// this gesture recognizer was created, to aid in debugging.
    public weak var debugOwner: AnyObject?

    /// Optional device specific configuration for device gestures that will
    /// take precedence over framework defaults.
    public var gestureSettings: DeviceGestureSettings?

    /// The kind of devices that are allowed to be recognized as provided by
    /// `supportedDevices` in the constructor, or the currently deprecated `kind`.
    /// These cannot both be set. If both are null, events from all device kinds will be
    /// tracked and recognized.
    public var supportedDevices: Set<PointerDeviceKind>?

    /// Called when interaction starts. This limits the dragging behavior
    /// for custom clicks (such as scroll click). Its parameter comes
    /// from [PointerEvent.buttons].
    ///
    /// Due to how [kPrimaryButton], [kSecondaryButton], etc., use integers,
    /// bitwise operations can help filter how buttons are pressed.
    /// For example, if someone simultaneously presses the primary and secondary
    /// buttons, the default behavior will return false. The following code
    /// accepts any button press with primary:
    /// `(int buttons) => buttons & kPrimaryButton != 0`.
    ///
    /// When value is `(int buttons) => false`, allow no interactions.
    /// When value is `(int buttons) => true`, allow all interactions.
    ///
    /// Defaults to all buttons.
    public let allowedButtonsFilter: AllowedButtonsFilter

    /// The default value for [allowedButtonsFilter].
    /// Accept any input.
    private static let defaultButtonAcceptBehavior: AllowedButtonsFilter = { _ in true }

    /// Holds a mapping between pointer IDs and the kind of devices they are
    /// coming from.
    private var pointerToKind: [Int: PointerDeviceKind] = [:]

    /// Registers a new pointer pan/zoom that might be relevant to this gesture
    /// detector.
    ///
    /// A pointer pan/zoom is a stream of events that conveys data covering
    /// pan, zoom, and rotate data from a multi-finger trackpad gesture.
    ///
    /// The owner of this gesture recognizer calls addPointerPanZoom() with the
    /// PointerPanZoomStartEvent of each pointer that should be considered for
    /// this gesture.
    ///
    /// It's the GestureRecognizer's responsibility to then add itself
    /// to the global pointer router (see [PointerRouter]) to receive
    /// subsequent events for this pointer, and to add the pointer to
    /// the global gesture arena manager (see [GestureArenaManager]) to track
    /// that pointer.
    ///
    /// This method is called for each and all pointers being added. In
    /// most cases, you want to override [addAllowedPointerPanZoom] instead.
    public final func addPointerPanZoom(event: PointerPanZoomStartEvent) {
        pointerToKind[event.pointer] = event.kind
        if isPointerPanZoomAllowed(event: event) {
            addAllowedPointerPanZoom(event: event)
        } else {
            handleNonAllowedPointerPanZoom(event: event)
        }
    }

    /// Checks whether or not a pointer pan/zoom is allowed to be tracked by this recognizer.
    public final func isPointerPanZoomAllowed(event: PointerPanZoomStartEvent) -> Bool {
        if let supportedDevices {
            if !supportedDevices.contains(event.kind) {
                return false
            }
        }
        return true
    }

    /// Registers a new pointer pan/zoom that's been checked to be allowed by this
    /// gesture recognizer.
    ///
    /// Subclasses of [GestureRecognizer] are supposed to override this method
    /// instead of [addPointerPanZoom] because [addPointerPanZoom] will be called for each
    /// pointer being added while [addAllowedPointerPanZoom] is only called for pointers
    /// that are allowed by this recognizer.
    open func addAllowedPointerPanZoom(event: PointerPanZoomStartEvent) {}

    /// Handles a pointer pan/zoom being added that's not allowed by this recognizer.
    ///
    /// Subclasses can override this method and reject the gesture.
    open func handleNonAllowedPointerPanZoom(event: PointerPanZoomStartEvent) {}

    /// Registers a new pointer that might be relevant to this gesture
    /// detector.
    ///
    /// The owner of this gesture recognizer calls addPointer() with the
    /// PointerDownEvent of each pointer that should be considered for
    /// this gesture.
    ///
    /// It's the GestureRecognizer's responsibility to then add itself
    /// to the global pointer router (see [PointerRouter]) to receive
    /// subsequent events for this pointer, and to add the pointer to
    /// the global gesture arena manager (see [GestureArenaManager]) to track
    /// that pointer.
    ///
    /// This method is called for each and all pointers being added. In
    /// most cases, you want to override [addAllowedPointer] instead.
    public final func addPointer(event: PointerDownEvent) {
        pointerToKind[event.pointer] = event.kind
        if isPointerAllowed(event: event) {
            addAllowedPointer(event: event)
        } else {
            handleNonAllowedPointer(event: event)
        }
    }

    /// Checks whether or not a pointer is allowed to be tracked by this
    /// recognizer.
    open func isPointerAllowed(event: PointerDownEvent) -> Bool {
        if let supportedDevices {
            if !supportedDevices.contains(event.kind) {
                return false
            }
        }
        return allowedButtonsFilter(event.buttons)
    }

    /// Registers a new pointer that's been checked to be allowed by this gesture
    /// recognizer.
    ///
    /// Subclasses of [GestureRecognizer] are supposed to override this method
    /// instead of [addPointer] because [addPointer] will be called for each
    /// pointer being added while [addAllowedPointer] is only called for pointers
    /// that are allowed by this recognizer.
    open func addAllowedPointer(event: PointerDownEvent) {}

    /// Handles a pointer being added that's not allowed by this recognizer.
    ///
    /// Subclasses can override this method and reject the gesture.
    ///
    /// See:
    /// - [OneSequenceGestureRecognizer.handleNonAllowedPointer].
    open func handleNonAllowedPointer(event: PointerDownEvent) {}

    /// For a given pointer ID, returns the device kind associated with it.
    ///
    /// The pointer ID is expected to be a valid one i.e. an event was received
    /// with that pointer ID.
    public final func getKindForPointer(pointer: Int) -> PointerDeviceKind {
        assert(pointerToKind[pointer] != nil)
        return pointerToKind[pointer]!
    }

    /// Releases any resources used by the object.
    ///
    /// This method is called by the owner of this gesture recognizer
    /// when the object is no longer needed (e.g. when a gesture
    /// recognizer is being unregistered from a [GestureDetector], the
    /// GestureDetector widget calls this method).
    open func dispose() {}

    open func acceptGesture(pointer: Int) {}

    open func rejectGesture(pointer: Int) {}

    /// Invoke a callback provided by the application, printing debug output
    /// if necessary.
    public final func invokeCallback<T>(_ name: String, _ callback: RecognizerCallback<T>) -> T {
        let result = callback()
        assert {
            if debugPrintRecognizerCallbacksTrace {
                mark("\(self) callling \(name) callback")
            }
            return true
        }
        return result
    }
}

/// Base class for gesture recognizers that can only recognize one
/// gesture at a time. For example, a single [TapGestureRecognizer]
/// can never recognize two taps happening simultaneously, even if
/// multiple pointers are placed on the same widget.
///
/// This is in contrast to, for instance, [MultiTapGestureRecognizer],
/// which manages each pointer independently and can consider multiple
/// simultaneous touches to each result in a separate tap.
open class OneSequenceGestureRecognizer: GestureRecognizer, PointerRoute {
    private var entries: [Int: GestureArenaEntry] = [:]
    private var trackedPointers: Set<Int> = []

    open override func addAllowedPointer(event: PointerDownEvent) {
        startTrackingPointer(event.pointer, transform: event.transform)
    }

    open override func handleNonAllowedPointer(event: PointerDownEvent) {
        resolve(.rejected)
    }

    /// Called when a pointer event is routed to this recognizer.
    ///
    /// This will be called for every pointer event while the pointer is being
    /// tracked. Typically, this recognizer will start tracking the pointer in
    /// [addAllowedPointer], which means that [handleEvent] will be called
    /// starting with the [PointerDownEvent] that was passed to [addAllowedPointer].
    ///
    /// See also:
    ///
    ///  * [startTrackingPointer], which causes pointer events to be routed to
    ///    this recognizer.
    ///  * [stopTrackingPointer], which stops events from being routed to this
    ///    recognizer.
    ///  * [stopTrackingIfPointerNoLongerDown], which conditionally stops events
    ///    from being routed to this recognizer.
    open func handleEvent(event: PointerEvent) {}

    /// Called when the number of pointers this recognizer is tracking changes from one to zero.
    ///
    /// The given pointer ID is the ID of the last pointer this recognizer was
    /// tracking.
    open func didStopTrackingLastPointer(pointer: Int) {}

    /// Resolves this recognizer's participation in each gesture arena with the
    /// given disposition.
    open func resolve(_ disposition: GestureDisposition) {
        let localEntries = Array(entries.values)
        entries.removeAll()
        for entry in localEntries {
            entry.resolve(disposition)
        }
    }

    /// Resolves this recognizer's participation in the given gesture arena with
    /// the given disposition.
    open func resolvePointer(_ pointer: Int, _ disposition: GestureDisposition) {
        let entry = entries[pointer]
        if let entry {
            entries.removeValue(forKey: pointer)
            entry.resolve(disposition)
        }
    }

    /// The team that this recognizer belongs to, if any.
    ///
    /// If [team] is null, this recognizer competes directly in the
    /// [GestureArenaManager] to recognize a sequence of pointer events as a
    /// gesture. If [team] is non-null, this recognizer competes in the arena in
    /// a group with other recognizers on the same team.
    ///
    /// A recognizer can be assigned to a team only when it is not participating
    /// in the arena. For example, a common time to assign a recognizer to a team
    /// is shortly after creating the recognizer.
    var team: GestureArenaTeam? {
        didSet {
            assert(entries.isEmpty)
            assert(trackedPointers.isEmpty)
            assert(team == nil)
        }
    }

    private func addPointerToArena(_ pointer: Int) -> GestureArenaEntry {
        if let team = team {
            return team.add(pointer, self)
        }
        return GestureBinding.shared.gestureArena.add(pointer, self)
    }

    /// Causes events related to the given pointer ID to be routed to this
    /// recognizer.
    ///
    /// The pointer events are transformed according to `transform` and then
    /// delivered to [handleEvent]. The value for the `transform` argument is
    /// usually obtained from [PointerDownEvent.transform] to transform the
    /// events from the global coordinate space into the coordinate space of the
    /// event receiver. It may be null if no transformation is necessary.
    ///
    /// Use [stopTrackingPointer] to remove the route added by this function.
    ///
    /// This method also adds this recognizer (or its [team] if it's non-null)
    /// to the gesture arena for the specified pointer.
    ///
    /// This is called by [OneSequenceGestureRecognizer.addAllowedPointer].
    func startTrackingPointer(_ pointer: Int, transform: Matrix4x4f?) {
        GestureBinding.shared.pointerRouter.addRoute(pointer, self, transform)
        trackedPointers.insert(pointer)
        entries[pointer] = addPointerToArena(pointer)
    }

    /// Stops events related to the given pointer ID from being routed to this recognizer.
    ///
    /// If this function reduces the number of tracked pointers to zero, it will
    /// call [didStopTrackingLastPointer] synchronously.
    ///
    /// Use [startTrackingPointer] to add the routes in the first place.
    public func stopTrackingPointer(_ pointer: Int) {
        if trackedPointers.contains(pointer) {
            GestureBinding.shared.pointerRouter.removeRoute(pointer, self)
            trackedPointers.remove(pointer)
            if trackedPointers.isEmpty {
                didStopTrackingLastPointer(pointer: pointer)
            }
        }
    }

    /// Stops tracking the pointer associated with the given event if the event is
    /// a [PointerUpEvent] or a [PointerCancelEvent] event.
    public func stopTrackingIfPointerNoLongerDown(event: PointerEvent) {
        if event is PointerUpEvent || event is PointerCancelEvent {
            stopTrackingPointer(event.pointer)
        }
    }

    open override func dispose() {
        resolve(.rejected)
        for pointer in trackedPointers {
            GestureBinding.shared.pointerRouter.removeRoute(pointer, self)
        }
        trackedPointers.removeAll()
        assert(entries.isEmpty)
        super.dispose()
    }
}

/// The possible states of a [PrimaryPointerGestureRecognizer].
///
/// The recognizer advances from [ready] to [possible] when it starts tracking a
/// primary pointer. Where it advances from there depends on how the gesture is
/// resolved for that pointer:
///
///  * If the primary pointer is resolved by the gesture winning the arena, the
///    recognizer stays in the [possible] state as long as it continues to track
///    a pointer.
///  * If the primary pointer is resolved by the gesture being rejected and
///    losing the arena, the recognizer's state advances to [defunct].
///
/// Once the recognizer has stopped tracking any remaining pointers, the
/// recognizer returns to [ready].
public enum GestureRecognizerState {
    /// The recognizer is ready to start recognizing a gesture.
    case ready

    /// The sequence of pointer events seen thus far is consistent with the
    /// gesture the recognizer is attempting to recognize but the gesture has not
    /// been accepted definitively.
    case possible

    /// Further pointer events cannot cause this recognizer to recognize the
    /// gesture until the recognizer returns to the [ready] state (typically when
    /// all the pointers the recognizer is tracking are removed from the screen).
    case defunct
}

/// A base class for gesture recognizers that track a single primary pointer.
///
/// Gestures based on this class will stop tracking the gesture if the primary
/// pointer travels beyond [preAcceptSlopTolerance] or [postAcceptSlopTolerance]
/// pixels from the original contact point of the gesture.
///
/// If the [preAcceptSlopTolerance] was breached before the gesture was accepted
/// in the gesture arena, the gesture will be rejected.
open class PrimaryPointerGestureRecognizer: OneSequenceGestureRecognizer {
    public init(
        debugOwner: AnyObject? = nil,
        deadline: Duration? = nil,
        preAcceptSlopTolerance: Float? = kTouchSlop,
        postAcceptSlopTolerance: Float? = kTouchSlop,
        supportedDevices: Set<PointerDeviceKind>? = nil,
        allowedButtonsFilter: AllowedButtonsFilter? = nil
    ) {
        self.deadline = deadline
        self.preAcceptSlopTolerance = preAcceptSlopTolerance
        self.postAcceptSlopTolerance = postAcceptSlopTolerance
        super.init(
            debugOwner: debugOwner,
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter
        )
    }

    /// If non-null, the recognizer will call [didExceedDeadline] after this
    /// amount of time has elapsed since starting to track the primary pointer.
    ///
    /// The [didExceedDeadline] will not be called if the primary pointer is
    /// accepted, rejected, or all pointers are up or canceled before [deadline].
    public let deadline: Duration?

    /// The maximum distance in logical pixels the gesture is allowed to drift
    /// from the initial touch down position before the gesture is accepted.
    ///
    /// Drifting past the allowed slop amount causes the gesture to be rejected.
    ///
    /// Can be null to indicate that the gesture can drift for any distance.
    /// Defaults to 18 logical pixels.
    public let preAcceptSlopTolerance: Float?

    /// The maximum distance in logical pixels the gesture is allowed to drift
    /// after the gesture has been accepted.
    ///
    /// Drifting past the allowed slop amount causes the gesture to stop tracking
    /// and signaling subsequent callbacks.
    ///
    /// Can be null to indicate that the gesture can drift for any distance.
    /// Defaults to 18 logical pixels.
    public let postAcceptSlopTolerance: Float?

    /// The current state of the recognizer.
    ///
    /// See [GestureRecognizerState] for a description of the states.
    public private(set) var state: GestureRecognizerState = .ready

    /// The ID of the primary pointer this recognizer is tracking.
    ///
    /// If this recognizer is no longer tracking any pointers, this field holds
    /// the ID of the primary pointer this recognizer was most recently tracking.
    /// This enables the recognizer to know which pointer it was most recently
    /// tracking when [acceptGesture] or [rejectGesture] is called (which may be
    /// called after the recognizer is no longer tracking a pointer if, e.g.
    /// [GestureArenaManager.hold] has been called, or if there are other
    /// recognizers keeping the arena open).
    public private(set) var primaryPointer: Int?

    /// The location at which the primary pointer contacted the screen.
    ///
    /// This will only be non-null while this recognizer is tracking at least
    /// one pointer.
    public private(set) var initialPosition: OffsetPair?

    // Whether this pointer is accepted by winning the arena or as defined by
    // a subclass calling acceptGesture.
    private var gestureAccepted = false

    //   Timer? _timer;

    open override func addAllowedPointer(event: PointerDownEvent) {
        super.addAllowedPointer(event: event)
        if state == .ready {
            state = .possible
            primaryPointer = event.pointer
            initialPosition = .init(local: event.localPosition, global: event.position)
            // if let deadline = deadline {
            //     _timer = Timer(deadline: deadline, target: self, selector: #selector(didExceedDeadline), userInfo: nil, repeats: false)
            // }
        }
    }

    open override func handleNonAllowedPointer(event: PointerDownEvent) {
        if !gestureAccepted {
            super.handleNonAllowedPointer(event: event)
        }
    }

    open override func handleEvent(event: PointerEvent) {
        assert(state != .ready)
        if state == .possible && event.pointer == primaryPointer {
            let isPreAcceptSlopPastTolerance =
                !gestureAccepted && preAcceptSlopTolerance != nil
                && getGlobalDistance(event: event) > preAcceptSlopTolerance!
            let isPostAcceptSlopPastTolerance =
                gestureAccepted && postAcceptSlopTolerance != nil
                && getGlobalDistance(event: event) > postAcceptSlopTolerance!

            if event is PointerMoveEvent
                && (isPreAcceptSlopPastTolerance || isPostAcceptSlopPastTolerance)
            {
                resolve(.rejected)
                stopTrackingPointer(primaryPointer!)
            } else {
                handlePrimaryPointer(event: event)
            }
        }
        stopTrackingIfPointerNoLongerDown(event: event)
    }

    /// Override to provide behavior for the primary pointer when the gesture is still possible.
    open func handlePrimaryPointer(event: PointerEvent) {}

    /// Override to be notified when [deadline] is exceeded.
    ///
    /// You must override this method or [didExceedDeadlineWithEvent] if you
    /// supply a [deadline]. Subclasses that override this method must _not_
    /// call `super.didExceedDeadline()`.
    open func didExceedDeadline() {
        assert(deadline == nil)
    }

    /// Same as [didExceedDeadline] but receives the [event] that initiated the
    /// gesture.
    ///
    /// You must override this method or [didExceedDeadline] if you supply a
    /// [deadline]. Subclasses that override this method must _not_ call
    /// `super.didExceedDeadlineWithEvent(event)`.
    open func didExceedDeadlineWithEvent(event: PointerDownEvent) {
        didExceedDeadline()
    }

    open override func acceptGesture(pointer: Int) {
        if pointer == primaryPointer {
            stopTimer()
            gestureAccepted = true
        }
    }

    open override func rejectGesture(pointer: Int) {
        if pointer == primaryPointer && state == .possible {
            stopTimer()
            state = .defunct
        }
    }

    open override func didStopTrackingLastPointer(pointer: Int) {
        assert(state != .ready)
        stopTimer()
        state = .ready
        initialPosition = nil
        gestureAccepted = false
    }

    private func stopTimer() {
        // timer?.cancel()
        // timer = nil
    }

    private func getGlobalDistance(event: PointerEvent) -> Float {
        let offset = event.position - initialPosition!.global
        return offset.distance
    }

    open override func dispose() {
        stopTimer()
        super.dispose()
    }
}

/// A container for a [local] and [global] [Offset] pair.
///
/// Usually, the [global] [Offset] is in the coordinate space of the screen
/// after conversion to logical pixels and the [local] offset is the same
/// [Offset], but transformed to a local coordinate space.
public struct OffsetPair {
    /// Creates a [OffsetPair] combining a [local] and [global] [Offset].
    public init(local: Offset, global: Offset) {
        self.local = local
        self.global = global
    }

    /// Creates a [OffsetPair] from [PointerEvent.localPosition] and
    /// [PointerEvent.position].
    init(fromEventPosition event: PointerEvent) {
        local = event.localPosition
        global = event.position
    }

    /// Creates a [OffsetPair] from [PointerEvent.localDelta] and
    /// [PointerEvent.delta].
    init(fromEventDelta event: PointerEvent) {
        local = event.localDelta
        global = event.delta
    }

    /// The [Offset] in the local coordinate space.
    public let local: Offset

    /// The [Offset] in the global coordinate space after conversion to logical
    /// pixels.
    public let global: Offset

    /// Adds the `other.global` to [global] and `other.local` to [local].
    public static func + (lhs: OffsetPair, rhs: OffsetPair) -> OffsetPair {
        OffsetPair(local: lhs.local + rhs.local, global: lhs.global + rhs.global)
    }

    /// Subtracts the `other.global` from [global] and `other.local` from [local].
    public static func - (lhs: OffsetPair, rhs: OffsetPair) -> OffsetPair {
        OffsetPair(local: lhs.local - rhs.local, global: lhs.global - rhs.global)
    }

    /// A [OffsetPair] where both [Offset]s are [Offset.zero].
    public static var zero: OffsetPair { OffsetPair(local: .zero, global: .zero) }
}
