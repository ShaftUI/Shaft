// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Details object for callbacks that use [GestureDragDownCallback].
///
/// See also:
///
///  * [DragGestureRecognizer.onDown], which uses [GestureDragDownCallback].
///  * [DragStartDetails], the details for [GestureDragStartCallback].
///  * [DragUpdateDetails], the details for [GestureDragUpdateCallback].
///  * [DragEndDetails], the details for [GestureDragEndCallback].
public struct DragDownDetails {
    /// Creates details for a [GestureDragDownCallback].
    public init(
        globalPosition: Offset = .zero,
        localPosition: Offset? = nil
    ) {
        self.globalPosition = globalPosition
        self.localPosition = localPosition ?? globalPosition
    }

    /// The global position at which the pointer contacted the screen.
    ///
    /// Defaults to the origin if not specified in the constructor.
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
}

/// Signature for when a pointer has contacted the screen and might begin to
/// move.
///
/// The `details` object provides the position of the touch.
///
/// See [DragGestureRecognizer.onDown].
public typealias GestureDragDownCallback = (DragDownDetails) -> Void

/// Details object for callbacks that use [GestureDragStartCallback].
///
/// See also:
///
///  * [DragGestureRecognizer.onStart], which uses [GestureDragStartCallback].
///  * [DragDownDetails], the details for [GestureDragDownCallback].
///  * [DragUpdateDetails], the details for [GestureDragUpdateCallback].
///  * [DragEndDetails], the details for [GestureDragEndCallback].
public struct DragStartDetails {
    /// Creates details for a [GestureDragStartCallback].
    public init(
        sourceTimeStamp: Duration? = nil,
        globalPosition: Offset = .zero,
        localPosition: Offset? = nil,
        kind: PointerDeviceKind? = nil
    ) {
        self.sourceTimeStamp = sourceTimeStamp
        self.globalPosition = globalPosition
        self.localPosition = localPosition ?? globalPosition
        self.kind = kind
    }

    /// Recorded timestamp of the source pointer event that triggered the drag
    /// event.
    ///
    /// Could be null if triggered from proxied events such as accessibility.
    public let sourceTimeStamp: Duration?

    /// The global position at which the pointer contacted the screen.
    ///
    /// Defaults to the origin if not specified in the constructor.
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
}

/// Signature for when a pointer has contacted the screen and has begun to move.
///
/// The `details` object provides the position of the touch when it first
/// touched the surface.
///
/// See [DragGestureRecognizer.onStart].
public typealias GestureDragStartCallback = (DragStartDetails) -> Void

/// Details object for callbacks that use [GestureDragUpdateCallback].
///
/// See also:
///
///  * [DragGestureRecognizer.onUpdate], which uses [GestureDragUpdateCallback].
///  * [DragDownDetails], the details for [GestureDragDownCallback].
///  * [DragStartDetails], the details for [GestureDragStartCallback].
///  * [DragEndDetails], the details for [GestureDragEndCallback].
public struct DragUpdateDetails {
    /// Creates details for a [GestureDragUpdateCallback].
    ///
    /// If [primaryDelta] is non-null, then its value must match one of the
    /// coordinates of [delta] and the other coordinate must be zero.
    public init(
        sourceTimeStamp: Duration? = nil,
        delta: Offset = .zero,
        primaryDelta: Float? = nil,
        globalPosition: Offset,
        localPosition: Offset? = nil
    ) {
        self.sourceTimeStamp = sourceTimeStamp
        self.delta = delta
        self.primaryDelta = primaryDelta
        self.globalPosition = globalPosition
        self.localPosition = localPosition ?? globalPosition

        assert(
            primaryDelta == nil
                || (primaryDelta == delta.dx && delta.dy == 0.0)
                || (primaryDelta == delta.dy && delta.dx == 0.0)
        )
    }

    /// Recorded timestamp of the source pointer event that triggered the drag
    /// event.
    ///
    /// Could be null if triggered from proxied events such as accessibility.
    public let sourceTimeStamp: Duration?

    /// The amount the pointer has moved in the coordinate space of the event
    /// receiver since the previous update.
    ///
    /// If the [GestureDragUpdateCallback] is for a one-dimensional drag (e.g.,
    /// a horizontal or vertical drag), then this offset contains only the delta
    /// in that direction (i.e., the coordinate in the other direction is zero).
    ///
    /// Defaults to zero if not specified in the constructor.
    public let delta: Offset

    /// The amount the pointer has moved along the primary axis in the coordinate
    /// space of the event receiver since the previous
    /// update.
    ///
    /// If the [GestureDragUpdateCallback] is for a one-dimensional drag (e.g.,
    /// a horizontal or vertical drag), then this value contains the component of
    /// [delta] along the primary axis (e.g., horizontal or vertical,
    /// respectively). Otherwise, if the [GestureDragUpdateCallback] is for a
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
}

/// Signature for when a pointer that is in contact with the screen and moving
/// has moved again.
///
/// The `details` object provides the position of the touch and the distance it
/// has traveled since the last update.
///
/// See [DragGestureRecognizer.onUpdate].
public typealias GestureDragUpdateCallback = (DragUpdateDetails) -> Void

/// Details object for callbacks that use [GestureDragEndCallback].
///
/// See also:
///
///  * [DragGestureRecognizer.onEnd], which uses [GestureDragEndCallback].
///  * [DragDownDetails], the details for [GestureDragDownCallback].
///  * [DragStartDetails], the details for [GestureDragStartCallback].
///  * [DragUpdateDetails], the details for [GestureDragUpdateCallback].
public struct DragEndDetails {
    /// Creates details for a [GestureDragEndCallback].
    ///
    /// If [primaryVelocity] is non-null, its value must match one of the
    /// coordinates of `velocity.pixelsPerSecond` and the other coordinate
    /// must be zero.
    public init(
        velocity: Velocity = .zero,
        primaryVelocity: Float? = nil,
        globalPosition: Offset = .zero,
        localPosition: Offset? = nil
    ) {
        self.velocity = velocity
        self.primaryVelocity = primaryVelocity
        self.globalPosition = globalPosition
        self.localPosition = localPosition ?? globalPosition

        assert(
            primaryVelocity == nil
                || (primaryVelocity == velocity.pixelsPerSecond.dx
                    && velocity.pixelsPerSecond.dy == 0)
                || (primaryVelocity == velocity.pixelsPerSecond.dy
                    && velocity.pixelsPerSecond.dx == 0)
        )
    }

    /// The velocity the pointer was moving when it stopped contacting the screen.
    ///
    /// Defaults to zero if not specified in the constructor.
    public let velocity: Velocity

    /// The velocity the pointer was moving along the primary axis when it stopped
    /// contacting the screen, in logical pixels per second.
    ///
    /// If the [GestureDragEndCallback] is for a one-dimensional drag (e.g., a
    /// horizontal or vertical drag), then this value contains the component of
    /// [velocity] along the primary axis (e.g., horizontal or vertical,
    /// respectively). Otherwise, if the [GestureDragEndCallback] is for a
    /// two-dimensional drag (e.g., a pan), then this value is null.
    ///
    /// Defaults to null if not specified in the constructor.
    public let primaryVelocity: Float?

    /// The global position the pointer is located at when the drag
    /// gesture has been completed.
    ///
    /// Defaults to the origin if not specified in the constructor.
    ///
    /// See also:
    ///
    ///  * [localPosition], which is the [globalPosition] transformed to the
    ///    coordinate space of the event receiver.
    public let globalPosition: Offset

    /// The local position in the coordinate system of the event receiver when
    /// the drag gesture has been completed.
    ///
    /// Defaults to [globalPosition] if not specified in the constructor.
    public let localPosition: Offset
}
