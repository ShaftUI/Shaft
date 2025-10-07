// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

public class PointerEvent {
    public required init(
        viewId: Int = 0,
        timeStamp: Duration = .zero,
        pointer: Int = 0,
        kind: PointerDeviceKind = .touch,
        device: Int = 0,
        position: Offset = .zero,
        delta: Offset = .zero,
        buttons: PointerButtons = .init(),
        down: Bool = false,
        transform: Matrix4x4f? = nil
    ) {
        self.viewId = viewId
        self.timeStamp = timeStamp
        self.pointer = pointer
        self.kind = kind
        self.device = device
        self.position = position
        self.delta = delta
        self.buttons = buttons
        self.down = down
        self.transform = transform
    }

    public func copyWith(
        viewId: Int? = nil,
        timeStamp: Duration? = nil,
        pointer: Int? = nil,
        kind: PointerDeviceKind? = nil,
        device: Int? = nil,
        position: Offset? = nil,
        delta: Offset? = nil,
        buttons: PointerButtons? = nil,
        down: Bool? = nil,
        transform: Matrix4x4f? = nil
    ) -> Self {
        Self(
            viewId: viewId ?? self.viewId,
            timeStamp: timeStamp ?? self.timeStamp,
            pointer: pointer ?? self.pointer,
            kind: kind ?? self.kind,
            device: device ?? self.device,
            position: position ?? self.position,
            delta: delta ?? self.delta,
            buttons: buttons ?? self.buttons,
            down: down ?? self.down,
            transform: transform ?? self.transform
        )
    }

    /// The ID of the ``NativeView`` which this event originated from.
    public let viewId: Int

    /// Time of event dispatch, relative to an arbitrary timeline.
    public let timeStamp: Duration

    /// Unique identifier for the pointer, not reused. Changes for each new
    /// pointer down event.
    public let pointer: Int

    /// The kind of input device for which the event was generated.
    public let kind: PointerDeviceKind

    /// Unique identifier for the pointing device, reused across interactions.
    public let device: Int

    /// Coordinate of the position of the pointer, in logical pixels in the
    /// global coordinate space.
    public let position: Offset

    /// Distance in logical pixels that the pointer moved since the last
    /// ``PointerMoveEvent`` or ``PointerHoverEvent``.
    ///
    /// This value is always 0.0 for down, up, and cancel events.
    public let delta: Offset

    /// Bit field containing the buttons that are currently pressed when this
    /// event was generated.
    ///
    /// For example, if this has the value 6 and the ``kind`` is
    /// ``PointerDeviceKind/invertedStylus``, then this indicates an upside-down
    /// stylus with both its primary and secondary buttons pressed.
    public let buttons: PointerButtons

    /// Set if the pointer is currently down.
    ///
    /// For touch and stylus pointers, this means the object (finger, pen) is in
    /// contact with the input surface. For mice, it means a button is pressed.
    public let down: Bool

    /// The transformation used to transform this event from the global coordinate
    /// space into the coordinate space of the event receiver.
    ///
    /// This value affects what is returned by ``localPosition`` and ``localDelta``.
    /// If this value is null, it is treated as the identity transformation.
    public let transform: Matrix4x4f?

    /// The ``position`` transformed into the event receiver's local coordinate
    /// system according to ``transform``.
    ///
    /// If this event has not been transformed, ``position`` is returned as-is.
    /// See also:
    public private(set) lazy var localPosition: Offset = Self.transformPosition(transform, position)

    /// The ``delta`` transformed into the event receiver's local coordinate
    /// system according to ``transform``.
    ///
    /// If this event has not been transformed, ``delta`` is returned as-is.
    lazy var localDelta: Offset = {
        return delta
    }()

    public func transformed(_ transform: Matrix4x4f?) -> Self {
        if let transform {
            if transform == self.transform {
                return self
            }
            return copyWith(transform: transform)
        } else {
            return self
        }
    }

    /// Returns the transformation of `position` into the coordinate system
    /// described by `transform`.
    ///
    /// The z-value of `position` is assumed to be 0.0. If `transform` is null,
    /// `position` is returned as-is.
    public static func transformPosition(_ transform: Matrix4x4f?, _ position: Offset) -> Offset {
        guard let transform else { return position }
        let position3 = Vector3f(position.dx, position.dy, 0)
        let transformed3 = transform.multiplyAndProject(v: position3)
        return Offset(transformed3.x, transformed3.y)
    }

    /// Transforms `untransformedDelta` into the coordinate system described by
    /// `transform`.
    ///
    /// It uses the provided `untransformedEndPosition` and
    /// `transformedEndPosition` of the provided delta to increase accuracy.
    ///
    /// If `transform` is null, `untransformedDelta` is returned.
    public static func transformDeltaViaPositions(
        transform: Matrix4x4f? = nil,
        untransformedDelta: Offset,
        untransformedEndPosition: Offset,
        transformedEndPosition: Offset? = nil
    ) -> Offset {
        if transform == nil {
            return untransformedDelta
        }
        // We could transform the delta directly with the transformation matrix.
        // While that is mathematically equivalent, in practice we are seeing a
        // greater precision error with that approach. Instead, we are transforming
        // start and end point of the delta separately and calculate the delta in
        // the new space for greater accuracy.
        let transformedEndPosition =
            transformedEndPosition ?? transformPosition(transform, untransformedEndPosition)
        let transformedStartPosition = transformPosition(
            transform,
            untransformedEndPosition - untransformedDelta
        )
        return transformedEndPosition - transformedStartPosition
    }
}

/// The device has started tracking the pointer.
///
/// For example, the pointer might be hovering above the device, having not yet
/// made contact with the surface of the device.
public final class PointerAddedEvent: PointerEvent {}

/// The pointer has moved with respect to the device while the pointer is not
/// in contact with the device.
public final class PointerHoverEvent: PointerEvent {}

/// The pointer has made contact with the device.
public final class PointerDownEvent: PointerEvent {
    public required init(
        viewId: Int = 0,
        timeStamp: Duration = .zero,
        pointer: Int = 0,
        kind: PointerDeviceKind = .touch,
        device: Int = 0,
        position: Offset = .zero,
        delta: Offset = .zero,
        buttons: PointerButtons = .primaryButton,
        down: Bool = true,
        transform: Matrix4x4f? = nil
    ) {
        assert(down == true)
        super.init(
            viewId: viewId,
            timeStamp: timeStamp,
            pointer: pointer,
            kind: kind,
            device: device,
            position: position,
            delta: delta,
            buttons: buttons,
            down: true,
            transform: transform
        )
    }
}

/// The pointer has moved with respect to the device while the pointer is in
/// contact with the device.
public final class PointerMoveEvent: PointerEvent {
    public required init(
        viewId: Int = 0,
        timeStamp: Duration = .zero,
        pointer: Int = 0,
        kind: PointerDeviceKind = .touch,
        device: Int = 0,
        position: Offset = .zero,
        delta: Offset = .zero,
        buttons: PointerButtons = .primaryButton,
        down: Bool = true,
        transform: Matrix4x4f? = nil
    ) {
        assert(down == true)
        super.init(
            viewId: viewId,
            timeStamp: timeStamp,
            pointer: pointer,
            kind: kind,
            device: device,
            position: position,
            delta: delta,
            buttons: buttons,
            down: true,
            transform: transform
        )
    }
}

/// The pointer has moved with respect to the device while the pointer is or is
/// not in contact with the device, and it has entered a target object.
public final class PointerEnterEvent: PointerEvent {
    /// Creates an enter event from a [PointerEvent].
    ///
    /// This is used by the [MouseTracker] to synthesize enter events.
    public static func fromMouseEvent(_ event: PointerEvent) -> PointerEnterEvent {
        return PointerEnterEvent(
            viewId: event.viewId,
            timeStamp: event.timeStamp,
            pointer: event.pointer,
            kind: event.kind,
            position: event.position,
            delta: event.delta,
            buttons: event.buttons,
            transform: event.transform
        )
    }
}

/// The pointer has moved with respect to the device while the pointer is or is
/// not in contact with the device, and exited a target object.
public final class PointerExitEvent: PointerEvent {
    /// Creates an exit event from a [PointerEvent].
    ///
    /// This is used by the [MouseTracker] to synthesize exit events.
    public static func fromMouseEvent(_ event: PointerEvent) -> PointerExitEvent {
        return PointerExitEvent(
            viewId: event.viewId,
            timeStamp: event.timeStamp,
            pointer: event.pointer,
            kind: event.kind,
            position: event.position,
            delta: event.delta,
            buttons: event.buttons,
            transform: event.transform
        )
    }
}

/// The pointer has stopped making contact with the device.
public final class PointerUpEvent: PointerEvent {
    public required init(
        viewId: Int = 0,
        timeStamp: Duration = .zero,
        pointer: Int = 0,
        kind: PointerDeviceKind = .touch,
        device: Int = 0,
        position: Offset = .zero,
        delta: Offset = .zero,
        buttons: PointerButtons = .primaryButton,
        down: Bool = false,
        transform: Matrix4x4f? = nil
    ) {
        assert(down == false)
        super.init(
            viewId: viewId,
            timeStamp: timeStamp,
            pointer: pointer,
            kind: kind,
            device: device,
            position: position,
            delta: delta,
            buttons: buttons,
            down: false,
            transform: transform
        )
    }
}

/// The input from the pointer is no longer directed towards this receiver.
public final class PointerCancelEvent: PointerEvent {}

/// The device is no longer tracking the pointer.
///
/// For example, the pointer might have drifted out of the device's hover
/// detection range or might have been disconnected from the system entirely.
public final class PointerRemovedEvent: PointerEvent {}

/// An event that corresponds to a discrete pointer signal.
///
/// Pointer signals are events that originate from the pointer but don't change
/// the state of the pointer itself, and are discrete rather than needing to be
/// interpreted in the context of a series of events.
public protocol PointerSignalEvent: PointerEvent {}

/// The pointer issued a scroll event.
///
/// Scrolling the scroll wheel on a mouse is an example of an event that
/// would create a [PointerScrollEvent].
public final class PointerScrollEvent: PointerEvent, PointerSignalEvent {
    public init(
        viewId: Int,
        timeStamp: Duration = .zero,
        kind: PointerDeviceKind,
        device: Int = 0,
        position: Offset,
        scrollDelta: Offset,
        transform: Matrix4x4f? = nil
    ) {
        self.scrollDelta = scrollDelta
        super.init(
            viewId: viewId,
            timeStamp: timeStamp,
            kind: kind,
            device: device,
            position: position,
            transform: transform
        )
    }

    public required init(
        viewId: Int = 0,
        timeStamp: Duration = .zero,
        pointer: Int = 0,
        kind: PointerDeviceKind = .touch,
        device: Int = 0,
        position: Offset = .zero,
        delta: Offset = .zero,
        buttons: PointerButtons = .init(),
        down: Bool = false,
        transform: Matrix4x4f? = nil
    ) {
        self.scrollDelta = .zero
        super.init(
            viewId: viewId,
            timeStamp: timeStamp,
            pointer: pointer,
            kind: kind,
            device: device,
            position: position,
            delta: delta,
            buttons: buttons,
            down: down,
            transform: transform
        )
    }

    /// The amount to scroll, in logical pixels.
    public let scrollDelta: Offset

    public override func copyWith(
        viewId: Int? = nil,
        timeStamp: Duration? = nil,
        pointer: Int? = nil,
        kind: PointerDeviceKind? = nil,
        device: Int? = nil,
        position: Offset? = nil,
        delta: Offset? = nil,
        buttons: PointerButtons? = nil,
        down: Bool? = nil,
        transform: Matrix4x4f? = nil
    ) -> Self {
        Self(
            viewId: viewId ?? self.viewId,
            timeStamp: timeStamp ?? self.timeStamp,
            kind: kind ?? self.kind,
            device: device ?? self.device,
            position: position ?? self.position,
            scrollDelta: scrollDelta,
            transform: transform ?? self.transform
        )
    }
}

/// The pointer issued a scroll-inertia cancel event.
///
/// Touching the trackpad immediately after a scroll is an example of an event
/// that would create a [PointerScrollInertiaCancelEvent].
public final class PointerScrollInertiaCancelEvent: PointerEvent, PointerSignalEvent {}

public final class PointerPanZoomStartEvent: PointerEvent {}

public final class PointerPanZoomEndEvent: PointerEvent {}

public final class PointerPanZoomUpdateEvent: PointerEvent {
    public let pan: Offset = .zero
    public var localPan: Offset { pan }
    public let panDelta: Offset = .zero
    public var localPanDelta: Offset { panDelta }
    public let scale: Float = 1.0
    public let rotation: Float = 0.0
}

/// Determine the appropriate hit slop pixels based on the ``kind`` of pointer.
func computeHitSlop(_ kind: PointerDeviceKind, _ settings: DeviceGestureSettings?) -> Float {
    switch kind {
    case .mouse:
        return kPrecisePointerHitSlop
    case .stylus, .invertedStylus, .touch, .trackpad:
        return settings?.touchSlop ?? kTouchSlop
    }
}

/// Determine the appropriate pan slop pixels based on the ``kind`` of pointer.
func computePanSlop(_ kind: PointerDeviceKind, _ settings: DeviceGestureSettings?) -> Float {
    switch kind {
    case .mouse:
        return kPrecisePointerPanSlop
    case .stylus, .invertedStylus, .touch, .trackpad:
        return settings?.panSlop ?? kPanSlop
    }
}

/// Determine the appropriate scale slop pixels based on the ``kind`` of pointer.
func computeScaleSlop(_ kind: PointerDeviceKind) -> Float {
    switch kind {
    case .mouse:
        return kPrecisePointerScaleSlop
    case .stylus, .invertedStylus, .touch, .trackpad:
        return kScaleSlop
    }
}
