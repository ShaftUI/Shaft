// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The callback to register with a [PointerSignalResolver] to express
/// interest in a pointer signal event.
public typealias PointerSignalResolvedCallback = (PointerSignalEvent) -> Void

/// Mediates disputes over which listener should handle pointer signal events
/// when multiple listeners wish to handle those events.
///
/// Pointer signals (such as [PointerScrollEvent]) are immediate, so unlike
/// events that participate in the gesture arena, pointer signals always resolve
/// at the end of event dispatch. Yet if objects interested in handling these
/// signal events were to handle them directly, it would cause issues such as
/// multiple [Scrollable] widgets in the widget hierarchy responding to the same
/// mouse wheel event. Using this class, these events will only be dispatched to
/// the first registered handler, which will in turn correspond to the widget
/// that's deepest in the widget hierarchy.
public class PointerSignalResolver {
    //   PointerSignalResolvedCallback? _firstRegisteredCallback;
    private var firstRegisteredCallback: PointerSignalResolvedCallback?

    //   PointerSignalEvent? _currentEvent;
    private var currentEvent: PointerSignalEvent?

    /// Registers interest in handling [event].
    ///
    /// This method may be called multiple times (typically from different parts
    /// of the widget hierarchy) for the same `event`, with differenet
    /// `callback`s, as the event is being dispatched across the tree. Once the
    /// dispatching is complete, the [GestureBinding] calls [resolve], and the
    /// first registered callback is called.
    ///
    /// The `callback` is invoked with one argument, the `event`.
    ///
    /// Once the [register] method has been called with a particular `event`, it
    /// must not be called for other `event`s until after [resolve] has been
    /// called. Only one event disambiguation can be in flight at a time. In
    /// normal use this is achieved by only registering callbacks for an event
    /// as it is actively being dispatched (for example, in
    /// [Listener.onPointerSignal]).
    ///
    /// See the documentation for the [PointerSignalResolver] class for an
    /// example of using this method.
    public func register(
        _ event: PointerSignalEvent,
        _ callback: @escaping PointerSignalResolvedCallback
    ) {
        if firstRegisteredCallback != nil {
            return
        }
        currentEvent = event
        firstRegisteredCallback = callback
    }

    /// Resolves the event, calling the first registered callback if there was
    /// one.
    ///
    /// This is called by the [GestureBinding] after the framework has finished
    /// dispatching the pointer signal event.
    public func resolve(_ event: PointerSignalEvent) {
        if firstRegisteredCallback == nil {
            assert(currentEvent == nil)
            return
        }
        firstRegisteredCallback!(event)
        firstRegisteredCallback = nil
        currentEvent = nil
    }
}
