// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Signature for listening to [PointerEnterEvent] events.
///
/// Used by [MouseTrackerAnnotation], [MouseRegion] and [RenderMouseRegion].
public typealias PointerEnterEventListener = (PointerEnterEvent) -> Void

/// Signature for listening to [PointerExitEvent] events.
///
/// Used by [MouseTrackerAnnotation], [MouseRegion] and [RenderMouseRegion].
public typealias PointerExitEventListener = (PointerExitEvent) -> Void

/// Signature for listening to [PointerHoverEvent] events.
///
/// Used by [MouseTrackerAnnotation], [MouseRegion] and [RenderMouseRegion].
public typealias PointerHoverEventListener = (PointerHoverEvent) -> Void

/// The annotation object used to annotate regions that are interested in mouse
/// movements.
///
/// To use an annotation, return this object as a [HitTestEntry] in a hit test.
/// Typically this is implemented by making a [RenderBox] implement this class
/// (see [RenderMouseRegion]).
///
/// [MouseTracker] uses this class as a label to filter the hit test results. Hit
/// test entries that are also [MouseTrackerAnnotation]s are considered as valid
/// targets in terms of computing mouse related effects, such as enter events,
/// exit events, and mouse cursor events.
///
/// See also:
///
///  * [MouseTracker], which uses [MouseTrackerAnnotation].
public protocol MouseTrackerAnnotation: AnyObject {
    /// Triggered when a mouse pointer, with or without buttons pressed, has
    /// entered the region and [validForMouseTracker] is true.
    ///
    /// This callback is triggered when the pointer has started to be contained by
    /// the region, either due to a pointer event, or due to the movement or
    /// disappearance of the region. This method is always matched by a later
    /// [onExit].
    ///
    /// See also:
    ///
    ///  * [onExit], which is triggered when a mouse pointer exits the region.
    ///  * [MouseRegion.onEnter], which uses this callback.
    var onEnter: PointerEnterEventListener? { get }

    /// Triggered when a mouse pointer, with or without buttons pressed, has
    /// exited the region and [validForMouseTracker] is true.
    ///
    /// This callback is triggered when the pointer has stopped being contained
    /// by the region, either due to a pointer event, or due to the movement or
    /// disappearance of the region. This method always matches an earlier
    /// [onEnter].
    ///
    /// See also:
    ///
    ///  * [onEnter], which is triggered when a mouse pointer enters the region.
    ///  * [MouseRegion.onExit], which uses this callback, but is not triggered in
    ///    certain cases and does not always match its earlier [MouseRegion.onEnter].
    var onExit: PointerExitEventListener? { get }

    /// The mouse cursor for mouse pointers that are hovering over the region.
    ///
    /// When a mouse enters the region, its cursor will be changed to the [cursor].
    /// When the mouse leaves the region, the cursor will be set by the region
    /// found at the new location.
    ///
    /// Defaults to [MouseCursor.defer], deferring the choice of cursor to the next
    /// region behind it in hit-test order.
    ///
    /// See also:
    ///
    ///  * [MouseRegion.cursor], which provide values to this field.
    var cursor: MouseCursor { get }

    /// Whether this is included when [MouseTracker] collects the list of
    /// annotations.
    ///
    /// If [validForMouseTracker] is false, this object is excluded from the
    /// current annotation list even if it's included in the hit test, affecting
    /// mouse-related behavior such as enter events, exit events, and mouse
    /// cursors. The [validForMouseTracker] does not affect hit testing.
    var validForMouseTracker: Bool { get }
}

/// A type-erased [MouseTrackerAnnotation].
public struct AnyMouseTrackerAnnotation: Hashable {
    public init(_ value: MouseTrackerAnnotation) {
        self.value = value
    }

    public let value: MouseTrackerAnnotation

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(value))
    }

    public static func == (lhs: AnyMouseTrackerAnnotation, rhs: AnyMouseTrackerAnnotation) -> Bool {
        return ObjectIdentifier(lhs.value) == ObjectIdentifier(rhs.value)
    }
}
