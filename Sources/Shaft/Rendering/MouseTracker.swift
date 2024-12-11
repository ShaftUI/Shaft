// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// Signature for hit testing at the given offset for the specified view.
///
/// It is used by the [MouseTracker] to fetch annotations for the mouse
/// position.
public typealias MouseTrackerHitTest = (Offset, Int) -> HitTestResult

// Various states of a connected mouse device used by [MouseTracker].
private class _MouseState {
    init(initialEvent: PointerEvent) {
        self.latestEvent = initialEvent
    }

    // The list of annotations that contains this device.
    //
    // It uses [KeyValuePairs] to keep the insertion order.
    public private(set) var _annotations: [AnyMouseTrackerAnnotation: Matrix4x4f] = [:]

    func replaceAnnotations(_ value: [AnyMouseTrackerAnnotation: Matrix4x4f])
        -> [AnyMouseTrackerAnnotation: Matrix4x4f]
    {
        let previous = _annotations
        _annotations = value
        return previous
    }

    // The most recently processed mouse event observed from this device.
    public private(set) var latestEvent: PointerEvent

    public func replaceLatestEvent(_ value: PointerEvent) -> PointerEvent {
        assert(value.device == latestEvent.device)
        let previous = latestEvent
        latestEvent = value
        return previous
    }

    public var device: Int {
        return latestEvent.device
    }
}

// The information in `MouseTracker._handleDeviceUpdate` to provide the details
// of an update of a mouse device.
//
// This class contains the information needed to handle the update that might
// change the state of a mouse device, or the [MouseTrackerAnnotation]s that
// the mouse device is hovering.
private struct _MouseTrackerUpdateDetails {
    /// When device update is triggered by a new frame.
    ///
    /// All parameters are required.
    init(
        lastAnnotations: [AnyMouseTrackerAnnotation: Matrix4x4f],
        nextAnnotations: [AnyMouseTrackerAnnotation: Matrix4x4f],
        previousEvent: PointerEvent
    ) {
        self.lastAnnotations = lastAnnotations
        self.nextAnnotations = nextAnnotations
        self.previousEvent = previousEvent
        self.triggeringEvent = nil
    }

    /// When device update is triggered by a pointer event.
    ///
    /// The [lastAnnotations], [nextAnnotations], and [triggeringEvent] are
    /// required.
    init(
        lastAnnotations: [AnyMouseTrackerAnnotation: Matrix4x4f],
        nextAnnotations: [AnyMouseTrackerAnnotation: Matrix4x4f],
        previousEvent: PointerEvent?,
        triggeringEvent: PointerEvent
    ) {
        self.lastAnnotations = lastAnnotations
        self.nextAnnotations = nextAnnotations
        self.previousEvent = previousEvent
        self.triggeringEvent = triggeringEvent
    }

    /// The annotations that the device is hovering before the update.
    ///
    /// It is never null.
    let lastAnnotations: [AnyMouseTrackerAnnotation: Matrix4x4f]

    /// The annotations that the device is hovering after the update.
    ///
    /// It is never null.
    let nextAnnotations: [AnyMouseTrackerAnnotation: Matrix4x4f]

    /// The last event that the device observed before the update.
    ///
    /// If the update is triggered by a frame, the [previousEvent] is never null,
    /// since the pointer must have been added before.
    ///
    /// If the update is triggered by a pointer event, the [previousEvent] is not
    /// null except for cases where the event is the first event observed by the
    /// pointer (which is not necessarily a [PointerAddedEvent]).
    let previousEvent: PointerEvent?

    /// The event that triggered this update.
    ///
    /// It is non-null if and only if the update is triggered by a pointer event.
    let triggeringEvent: PointerEvent?

    /// The pointing device of this update.
    var device: Int {
        return (previousEvent ?? triggeringEvent)!.device
    }

    /// The last event that the device observed after the update.
    ///
    /// The [latestEvent] is never null.
    var latestEvent: PointerEvent {
        return triggeringEvent ?? previousEvent!
    }
}

/// Tracks the relationship between mouse devices and annotations, and
/// triggers mouse events and cursor changes accordingly.
///
/// The [MouseTracker] tracks the relationship between mouse devices and
/// [MouseTrackerAnnotation], notified by [updateWithEvent] and
/// [updateAllDevices]. At every update, [MouseTracker] triggers the following
/// changes if applicable:
///
///  * Dispatches mouse-related pointer events (pointer enter, hover, and exit).
///  * Changes mouse cursors.
///  * Notifies when [mouseIsConnected] changes.
///
/// This class is a [ChangeNotifier] that notifies its listeners if the value of
/// [mouseIsConnected] changes.
///
/// An instance of [MouseTracker] is owned by the global singleton
/// [RendererBinding].
public class MouseTracker: ChangeNotifier {
    /// Create a mouse tracker.
    ///
    /// The `hitTestInView` is used to find the render objects on a given
    /// position in the specific view. It is typically provided by the
    /// [RendererBinding].
    init(hitTestInView: @escaping MouseTrackerHitTest) {
        self._hitTestInView = hitTestInView
    }

    private let _hitTestInView: MouseTrackerHitTest

    private let _mouseCursorMixin = MouseCursorManager(
        fallbackMouseCursor: .system(.basic)
    )

    // Tracks the state of connected mouse devices.
    //
    // It is the source of truth for the list of connected mouse devices, and
    // consists of two parts:
    //
    //  * The mouse devices that are connected.
    //  * In which annotations each device is contained.
    private var _mouseStates: [Int: _MouseState] = [:]

    // Used to wrap any procedure that might change `mouseIsConnected`.
    //
    // This method records `mouseIsConnected`, runs `task`, and calls
    // [notifyListeners] at the end if the `mouseIsConnected` has changed.
    private func _monitorMouseConnection(_ task: () -> Void) {
        let mouseWasConnected = mouseIsConnected
        task()
        if mouseWasConnected != mouseIsConnected {
            notifyListeners()
        }
    }

    private var _debugDuringDeviceUpdate = false
    // Used to wrap any procedure that might call `_handleDeviceUpdate`.
    //
    // In debug mode, this method uses `_debugDuringDeviceUpdate` to prevent
    // `_deviceUpdatePhase` being recursively called.
    private func _deviceUpdatePhase(_ task: () -> Void) {
        assert(!_debugDuringDeviceUpdate)
        assert {
            _debugDuringDeviceUpdate = true
            return true
        }
        task()
        assert {
            _debugDuringDeviceUpdate = false
            return true
        }
    }

    // Whether an observed event might update a device.
    private static func _shouldMarkStateDirty(_ state: _MouseState?, _ event: PointerEvent) -> Bool
    {
        if state == nil {
            return true
        }
        let lastEvent = state!.latestEvent
        assert(event.device == lastEvent.device)
        // An Added can only follow a Removed, and a Removed can only be followed
        // by an Added.
        assert((event is PointerAddedEvent) == (lastEvent is PointerRemovedEvent))

        // Ignore events that are unrelated to mouse tracking.
        if event is PointerSignalEvent {
            return false
        }
        return lastEvent is PointerAddedEvent
            || event is PointerRemovedEvent
            || lastEvent.position != event.position
    }

    private func _hitTestInViewResultToAnnotations(_ result: HitTestResult)
        -> [AnyMouseTrackerAnnotation: Matrix4x4f]
    {
        var annotations: [AnyMouseTrackerAnnotation: Matrix4x4f] = [:]
        for entry in result.path {
            if let target = entry.target as? MouseTrackerAnnotation {
                annotations[AnyMouseTrackerAnnotation(target)] = entry.transform!
            }
        }
        return annotations
    }

    // Find the annotations that is hovered by the device of the `state`, and
    // their respective global transform matrices.
    //
    // If the device is not connected or not a mouse, an empty map is returned
    // without calling `hitTest`.
    private func _findAnnotations(_ state: _MouseState) -> [AnyMouseTrackerAnnotation: Matrix4x4f] {
        let globalPosition = state.latestEvent.position
        let device = state.device
        let viewId = state.latestEvent.viewId
        if !_mouseStates.keys.contains(device) {
            return [:]
        }

        return _hitTestInViewResultToAnnotations(_hitTestInView(globalPosition, viewId))
    }

    // A callback that is called on the update of a device.
    //
    // An event (not necessarily a pointer event) that might change the
    // relationship between mouse devices and [MouseTrackerAnnotation]s is called
    // a _device update_. This method should be called at each such update.
    //
    // The update can be caused by two kinds of triggers:
    //
    //  * Triggered by the addition, movement, or removal of a pointer. Such calls
    //    occur during the handler of the event, indicated by
    //    `details.triggeringEvent` being non-null.
    //  * Triggered by the appearance, movement, or disappearance of an annotation.
    //    Such calls occur after each new frame, during the post-frame callbacks,
    //    indicated by `details.triggeringEvent` being null.
    //
    // Calls of this method must be wrapped in `_deviceUpdatePhase`.
    private func _handleDeviceUpdate(_ details: _MouseTrackerUpdateDetails) {
        assert(_debugDuringDeviceUpdate)
        Self._handleDeviceUpdateMouseEvents(details)
        _mouseCursorMixin.handleDeviceCursorUpdate(
            device: details.device,
            triggeringEvent: details.triggeringEvent,
            cursorCandidates: details.nextAnnotations.keys.map { $0.value.cursor }
        )
    }

    /// Whether or not at least one mouse is connected and has produced events.
    private var mouseIsConnected: Bool {
        return !_mouseStates.isEmpty
    }

    /// Perform a device update for one device according to the given new event.
    ///
    /// The [updateWithEvent] is typically called by [RendererBinding] during the
    /// handler of a pointer event. All pointer events should call this method,
    /// and let [MouseTracker] filter which to react to.
    ///
    /// The `hitTestResult` serves as an optional optimization, and is the hit
    /// test result already performed by [RendererBinding] for other gestures. It
    /// can be null, but when it's not null, it should be identical to the result
    /// from directly calling `hitTestInView` given in the constructor (which
    /// means that it should not use the cached result for [PointerMoveEvent]).
    ///
    /// The [updateWithEvent] is one of the two ways of updating mouse
    /// states, the other one being [updateAllDevices].
    public func updateWithEvent(_ event: PointerEvent, hitTestResult: HitTestResult?) {
        if event.kind != .mouse && event.kind != .stylus {
            return
        }
        if event is PointerSignalEvent {
            return
        }
        let result: HitTestResult
        if event is PointerRemovedEvent {
            result = HitTestResult()
        } else {
            let viewId = event.viewId
            result = hitTestResult ?? _hitTestInView(event.position, viewId)
        }
        let device = event.device
        let existingState = _mouseStates[device]
        if !Self._shouldMarkStateDirty(existingState, event) {
            return
        }

        _monitorMouseConnection {
            _deviceUpdatePhase {
                // Update mouseState to the latest devices that have not been removed,
                // so that [mouseIsConnected], which is decided by `_mouseStates`, is
                // correct during the callbacks.
                if existingState == nil {
                    if event is PointerRemovedEvent {
                        return
                    }
                    _mouseStates[device] = _MouseState(initialEvent: event)
                } else {
                    assert(!(event is PointerAddedEvent))
                    if event is PointerRemovedEvent {
                        _mouseStates.removeValue(forKey: event.device)
                    }
                }
                let targetState = _mouseStates[device] ?? existingState!

                let lastEvent = targetState.replaceLatestEvent(event)
                let nextAnnotations: [AnyMouseTrackerAnnotation: Matrix4x4f] =
                    event is PointerRemovedEvent ? [:] : _hitTestInViewResultToAnnotations(result)
                let lastAnnotations = targetState.replaceAnnotations(nextAnnotations)

                _handleDeviceUpdate(
                    _MouseTrackerUpdateDetails(
                        lastAnnotations: lastAnnotations,
                        nextAnnotations: nextAnnotations,
                        previousEvent: lastEvent,
                        triggeringEvent: event
                    )
                )
            }
        }
    }

    /// Perform a device update for all detected devices.
    ///
    /// The [updateAllDevices] is typically called during the post frame phase,
    /// indicating a frame has passed and all objects have potentially moved. For
    /// each connected device, the [updateAllDevices] will make a hit test on the
    /// device's last seen position, and check if necessary changes need to be
    /// made.
    ///
    /// The [updateAllDevices] is one of the two ways of updating mouse
    /// states, the other one being [updateWithEvent].
    public func updateAllDevices() {
        _deviceUpdatePhase {
            for dirtyState in _mouseStates.values {
                let lastEvent = dirtyState.latestEvent
                let nextAnnotations = _findAnnotations(dirtyState)
                let lastAnnotations = dirtyState.replaceAnnotations(nextAnnotations)

                _handleDeviceUpdate(
                    _MouseTrackerUpdateDetails(
                        lastAnnotations: lastAnnotations,
                        nextAnnotations: nextAnnotations,
                        previousEvent: lastEvent
                    )
                )
            }
        }
    }

    /// Returns the active mouse cursor for a device.
    ///
    /// The return value is the last [MouseCursor] activated onto this device, even
    /// if the activation failed.
    ///
    /// This function is only active when asserts are enabled. In release builds,
    /// it always returns null.
    // package func debugDeviceActiveCursor(_ device: Int) -> MouseCursor? {
    //     return _mouseCursorMixin.debugDeviceActiveCursor(device)
    // }

    // Handles device update and dispatches mouse event callbacks.
    private static func _handleDeviceUpdateMouseEvents(_ details: _MouseTrackerUpdateDetails) {
        let latestEvent = details.latestEvent
        let lastAnnotations = details.lastAnnotations
        let nextAnnotations = details.nextAnnotations

        // Order is important for mouse event callbacks. The
        // `_hitTestInViewResultToAnnotations` returns annotations in the visual order
        // from front to back, called the "hit-test order". The algorithm here is
        // explained in https://github.com/flutter/flutter/issues/41420

        // Send exit events to annotations that are in last but not in next, in
        // hit-test order.
        let baseExitEvent = PointerExitEvent.fromMouseEvent(latestEvent)
        for (annotation, transform) in lastAnnotations {
            if annotation.value.validForMouseTracker && !nextAnnotations.keys.contains(annotation) {
                annotation.value.onExit?(baseExitEvent.transformed(transform))
            }
        }

        // Send enter events to annotations that are not in last but in next, in
        // reverse hit-test order.
        let enteringAnnotations = nextAnnotations.keys.filter { annotation in
            !lastAnnotations.keys.contains(annotation)
        }
        let baseEnterEvent = PointerEnterEvent.fromMouseEvent(latestEvent)
        for annotation in enteringAnnotations.reversed() {
            if annotation.value.validForMouseTracker {
                annotation.value.onEnter?(baseEnterEvent.transformed(nextAnnotations[annotation]))
            }
        }
    }
}
