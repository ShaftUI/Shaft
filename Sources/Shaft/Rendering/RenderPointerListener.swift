// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Signature for listening to [PointerDownEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
public typealias PointerDownEventListener = (_ event: PointerDownEvent) -> Void

/// Signature for listening to [PointerMoveEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
public typealias PointerMoveEventListener = (_ event: PointerMoveEvent) -> Void

/// Signature for listening to [PointerUpEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
public typealias PointerUpEventListener = (_ event: PointerUpEvent) -> Void

/// Signature for listening to [PointerCancelEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
public typealias PointerCancelEventListener = (_ event: PointerCancelEvent) -> Void

/// Signature for listening to [PointerPanZoomStartEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
public typealias PointerPanZoomStartEventListener = (_ event: PointerPanZoomStartEvent) -> Void

/// Signature for listening to [PointerPanZoomUpdateEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
public typealias PointerPanZoomUpdateEventListener = (_ event: PointerPanZoomUpdateEvent) -> Void

/// Signature for listening to [PointerPanZoomEndEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
public typealias PointerPanZoomEndEventListener = (_ event: PointerPanZoomEndEvent) -> Void

/// Signature for listening to [PointerSignalEvent] events.
///
/// Used by [Listener] and [RenderPointerListener].
public typealias PointerSignalEventListener = (_ event: PointerSignalEvent) -> Void

/// Calls callbacks in response to common pointer events.
///
/// It responds to events that can construct gestures, such as when the
/// pointer is pointer is pressed and moved, and then released or canceled.
///
/// It does not respond to events that are exclusive to mouse, such as when the
/// mouse enters and exits a region without pressing any buttons. For
/// these events, use [RenderMouseRegion].
///
/// If it has a child, defers to the child for sizing behavior.
///
/// If it does not have a child, grows to fit the parent-provided constraints.
public class RenderPointerListener: RenderProxyBoxWithHitTestBehavior {

    init(
        onPointerDown: PointerDownEventListener? = nil,
        onPointerMove: PointerMoveEventListener? = nil,
        onPointerUp: PointerUpEventListener? = nil,
        onPointerCancel: PointerCancelEventListener? = nil,
        onPointerPanZoomStart: PointerPanZoomStartEventListener? = nil,
        onPointerPanZoomUpdate: PointerPanZoomUpdateEventListener? = nil,
        onPointerPanZoomEnd: PointerPanZoomEndEventListener? = nil,
        onPointerSignal: PointerSignalEventListener? = nil,
        behavior: HitTestBehavior = .deferToChild,
        child: RenderBox? = nil
    ) {
        self.onPointerDown = onPointerDown
        self.onPointerMove = onPointerMove
        self.onPointerUp = onPointerUp
        self.onPointerCancel = onPointerCancel
        self.onPointerPanZoomStart = onPointerPanZoomStart
        self.onPointerPanZoomUpdate = onPointerPanZoomUpdate
        self.onPointerPanZoomEnd = onPointerPanZoomEnd
        self.onPointerSignal = onPointerSignal
        super.init(behavior: behavior, child: child)
    }

    /// Called when a pointer comes into contact with the screen (for touch
    /// pointers), or has its button pressed (for mouse pointers) at this widget's
    /// location.
    var onPointerDown: PointerDownEventListener?

    /// Called when a pointer that triggered an [onPointerDown] changes position.
    var onPointerMove: PointerMoveEventListener?

    /// Called when a pointer that triggered an [onPointerDown] is no longer in
    /// contact with the screen.
    var onPointerUp: PointerUpEventListener?

    /// Called when a pointer that has not an [onPointerDown] changes position.
    // var onPointerHover: PointerHoverEventListener?

    /// Called when the input from a pointer that triggered an [onPointerDown] is
    /// no longer directed towards this receiver.
    var onPointerCancel: PointerCancelEventListener?

    /// Called when a pan/zoom begins such as from a trackpad gesture.
    var onPointerPanZoomStart: PointerPanZoomStartEventListener?

    /// Called when a pan/zoom is updated.
    var onPointerPanZoomUpdate: PointerPanZoomUpdateEventListener?

    /// Called when a pan/zoom finishes.
    var onPointerPanZoomEnd: PointerPanZoomEndEventListener?

    /// Called when a pointer signal occurs over this object.
    var onPointerSignal: PointerSignalEventListener?

    override public func handleEvent(_ event: PointerEvent, entry: HitTestEntry) {
        switch event {
        case let event as PointerDownEvent:
            onPointerDown?(event)
        case let event as PointerMoveEvent:
            onPointerMove?(event)
        case let event as PointerUpEvent:
            onPointerUp?(event)
        case let event as PointerCancelEvent:
            onPointerCancel?(event)
        case let event as PointerPanZoomStartEvent:
            onPointerPanZoomStart?(event)
        case let event as PointerPanZoomUpdateEvent:
            onPointerPanZoomUpdate?(event)
        case let event as PointerPanZoomEndEvent:
            onPointerPanZoomEnd?(event)
        case let event as PointerSignalEvent:
            onPointerSignal?(event)
        default:
            break
        }
    }

    public override func performLayout() {
        if let child {
            child.layout(constraints, parentUsesSize: true)
            size = child.size
        } else {
            size = boxConstraint.smallest
        }
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        if let child {
            context.paintChild(child, offset: offset)
        }
    }
}
