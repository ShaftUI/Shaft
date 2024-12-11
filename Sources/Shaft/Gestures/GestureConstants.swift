// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Modeled after Android's ViewConfiguration:
// https://github.com/android/platform_frameworks_base/blob/main/core/java/android/view/ViewConfiguration.java

/// The time that must elapse before a tap gesture sends onTapDown, if there's
/// any doubt that the gesture is a tap.
public let kPressTimeout = Duration.milliseconds(100)

/// Maximum length of time between a tap down and a tap up for the gesture to be
/// considered a tap. (Currently not honored by the TapGestureRecognizer.)
// TODO(ianh): Remove this, or implement a hover-tap gesture recognizer which
// uses this.
public let kHoverTapTimeout = Duration.milliseconds(150)

/// Maximum distance between the down and up pointers for a tap. (Currently not
/// honored by the [TapGestureRecognizer]; [PrimaryPointerGestureRecognizer],
/// which TapGestureRecognizer inherits from, uses [kTouchSlop].)
// TODO(ianh): Remove this or implement it correctly.
public let kHoverTapSlop: Float = 20.0  // Logical pixels

/// The time before a long press gesture attempts to win.
public let kLongPressTimeout = Duration.milliseconds(500)

/// The maximum time from the start of the first tap to the start of the second
/// tap in a double-tap gesture.
// In Android, this is actually the time from the first's up event
// to the second's down event, according to the ViewConfiguration docs.
public let kDoubleTapTimeout = Duration.milliseconds(300)

/// The minimum time from the end of the first tap to the start of the second
/// tap in a double-tap gesture.
public let kDoubleTapMinTime = Duration.milliseconds(40)

/// The maximum distance that the first touch in a double-tap gesture can travel
/// before deciding that it is not part of a double-tap gesture.
/// DoubleTapGestureRecognizer also restricts the second touch to this distance.
public let kDoubleTapTouchSlop: Float = kTouchSlop  // Logical pixels

/// Distance between the initial position of the first touch and the start
/// position of a potential second touch for the second touch to be considered
/// the second touch of a double-tap gesture.
public let kDoubleTapSlop: Float = 100.0  // Logical pixels

/// The time for which zoom controls (e.g. in a map interface) are to be
/// displayed on the screen, from the moment they were last requested.
public let kZoomControlsTimeout = Duration.milliseconds(3000)

/// The distance a touch has to travel for the framework to be confident that
/// the gesture is a scroll gesture, or, inversely, the maximum distance that a
/// touch can travel before the framework becomes confident that it is not a
/// tap.
///
/// A total delta less than or equal to [kTouchSlop] is not considered to be a
/// drag, whereas if the delta is greater than [kTouchSlop] it is considered to
/// be a drag.
// This value was empirically derived. We started at 8.0 and increased it to
// 18.0 after getting complaints that it was too difficult to hit targets.
public let kTouchSlop: Float = 18.0  // Logical pixels

/// The distance a touch has to travel for the framework to be confident that
/// the gesture is a paging gesture. (Currently not used, because paging uses a
/// regular drag gesture, which uses kTouchSlop.)
// TODO(ianh): Create variants of HorizontalDragGestureRecognizer et al for
// paging, which use this constant.
public let kPagingTouchSlop: Float = kTouchSlop * 2.0  // Logical pixels

/// The distance a touch has to travel for the framework to be confident that
/// the gesture is a panning gesture.
public let kPanSlop: Float = kTouchSlop * 2.0  // Logical pixels

/// The distance a touch has to travel for the framework to be confident that
/// the gesture is a scale gesture.
public let kScaleSlop: Float = kTouchSlop  // Logical pixels

/// The margin around a dialog, popup menu, or other window-like widget inside
/// which we do not consider a tap to dismiss the widget. (Not currently used.)
// TODO(ianh): Make ModalBarrier support this.
public let kWindowTouchSlop: Float = 16.0  // Logical pixels

/// The minimum velocity for a touch to consider that touch to trigger a fling
/// gesture.
// TODO(ianh): Make sure nobody has their own version of this.
public let kMinFlingVelocity: Float = 50.0  // Logical pixels / second
// const Velocity kMinFlingVelocity = const Velocity(pixelsPerSecond: 50.0);

/// Drag gesture fling velocities are clipped to this value.
// TODO(ianh): Make sure nobody has their own version of this.
public let kMaxFlingVelocity: Float = 8000.0  // Logical pixels / second

/// The maximum time from the start of the first tap to the start of the second
/// tap in a jump-tap gesture.
// TODO(ianh): Implement jump-tap gestures.
public let kJumpTapTimeout = Duration.milliseconds(500)

/// Like [kTouchSlop], but for more precise pointers like mice and trackpads.
public let kPrecisePointerHitSlop: Float = 1.0  // Logical pixels;

/// Like [kPanSlop], but for more precise pointers like mice and trackpads.
public let kPrecisePointerPanSlop: Float = kPrecisePointerHitSlop * 2.0  // Logical pixels

/// Like [kScaleSlop], but for more precise pointers like mice and trackpads.
public let kPrecisePointerScaleSlop: Float = kPrecisePointerHitSlop  // Logical pixels
