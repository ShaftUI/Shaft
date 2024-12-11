// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Collections

/// A protocol that defines a clock used for sampling events.
public protocol SamplingClock {
    /// Returns current time.
    // func now() -> Date {
    //     return Date()
    // }

    /// Returns a new stopwatch that uses the current time as reported by `this`.
    ///
    /// See also:
    ///
    ///   * [GestureBinding.debugSamplingClock], which is used in tests and
    ///     debug builds to observe [FakeAsync].
    func stopwatch() -> Stopwatch
}

/// Class that implements clock used for sampling.
private class DefaultSamplingClock: SamplingClock {
    func stopwatch() -> Stopwatch {
        return ClockStopwatch(clock: ContinuousClock())
    }
}

public class GestureBinding: HitTestTarget {
    public static let shared = GestureBinding()

    private init() {
        backend.onPointerData = handlePointerData
    }

    /// A router that routes all pointer events received from the engine.
    public let pointerRouter = PointerRouter()

    /// The gesture arenas used for disambiguating the meaning of sequences of
    /// pointer events.
    public let gestureArena = GestureArenaManager()

    /// The resolver used for determining which widget handles a
    /// [PointerSignalEvent].
    public let pointerSignalResolver = PointerSignalResolver()

    private var pendingPointerEvents = Deque<PointerEvent>()

    func handlePointerData(_ pointerData: PointerData) {
        guard
            let event = PointerEventConverter.convert(
                pointerData,
                devicePixelRatioForView: { backend.view($0)?.devicePixelRatio }
            )
        else {
            return
        }

        pendingPointerEvents.append(event)

        // if !locked {
        flushPointerEventQueue()
        // }
    }

    private func flushPointerEventQueue() {
        while !pendingPointerEvents.isEmpty {
            handlePointerEvent(pendingPointerEvents.removeFirst())
        }
    }

    private var hitTests = [Int: HitTestResult]()

    func handlePointerEvent(_ event: PointerEvent) {
        // if (resamplingEnabled) {
        // _resampler.addOrDispatch(event);
        // _resampler.sample(samplingOffset, _samplingClock);
        // return;
        // }

        // // Stop resampler if resampling is not enabled. This is a no-op if
        // // resampling was never enabled.
        // _resampler.stop();
        handlePointerEventImmediately(event)
    }

    private func handlePointerEventImmediately(_ event: PointerEvent) {
        var hitTestResult: HitTestResult?

        if event is PointerDownEvent || event is PointerSignalEvent
            || event is PointerHoverEvent || event is PointerPanZoomStartEvent
        {
            hitTestResult = HitTestResult()
            hitTestInView(hitTestResult!, position: event.position, viewId: event.viewId)
            if event is PointerDownEvent || event is PointerPanZoomStartEvent {
                hitTests[event.pointer] = hitTestResult
            }
        } else if event is PointerUpEvent || event is PointerCancelEvent
            || event is PointerPanZoomEndEvent
        {
            hitTestResult = hitTests.removeValue(forKey: event.pointer)!
        } else if event.down || event is PointerPanZoomUpdateEvent {
            // Because events that occur with the pointer down (like
            // [PointerMoveEvent]s) should be dispatched to the same place that
            // their initial PointerDownEvent was, we want to re-use the path we
            // found when the pointer went down, rather than do hit detection
            // each time we get such an event.
            hitTestResult = hitTests[event.pointer]!
        }
        if hitTestResult !== nil || event is PointerAddedEvent || event is PointerRemovedEvent {
            dispatchEvent(event, hitTestResult: hitTestResult)
        }
    }

    var beforeDispatchEventCallbacks = CallbackList2<PointerEvent, HitTestResult?>()

    private func dispatchEvent(_ event: PointerEvent, hitTestResult: HitTestResult?) {
        beforeDispatchEventCallbacks.call(event, hitTestResult)

        // No hit test information implies that this is a [PointerAddedEvent] or
        // [PointerRemovedEvent]. These events are specially routed here; other
        // events will be routed through the `handleEvent` below.
        guard let hitTestResult else {
            assert(event is PointerAddedEvent || event is PointerRemovedEvent)
            pointerRouter.route(event)
            return
        }

        for entry in hitTestResult.path {
            let event =
                if let transform = entry.transform {
                    event.transformed(transform)
                } else {
                    event
                }
            entry.target.handleEvent(event, entry: entry)
        }
    }

    public var onHitTest: ((HitTestResult, Offset, Int) -> Void)?

    private func hitTestInView(_ result: HitTestResult, position: Offset, viewId: Int) {
        onHitTest?(result, position, viewId)
        result.add(HitTestEntry(self))
    }

    public func handleEvent(_ event: PointerEvent, entry: HitTestEntry) {
        pointerRouter.route(event)
        if event is PointerDownEvent || event is PointerPanZoomStartEvent {
            gestureArena.close(event.pointer)
        } else if event is PointerUpEvent || event is PointerPanZoomEndEvent {
            gestureArena.sweep(event.pointer)
        } else if let event = event as? PointerSignalEvent {
            pointerSignalResolver.resolve(event)
        }
    }

    /// Overrides the sampling clock for debugging and testing.
    ///
    /// This value is ignored in non-debug builds.
    public var debugSamplingClock: SamplingClock? {
        return nil
    }

    /// Provides access to the current [DateTime] and `StopWatch` objects for
    /// sampling.
    ///
    /// Overridden by [debugSamplingClock] for debug builds and testing. Using
    /// this object under test will maintain synchronization with [FakeAsync].
    var samplingClock: SamplingClock {
        var value: SamplingClock = DefaultSamplingClock()
        assert {
            if let debugValue = debugSamplingClock {
                value = debugValue
            }
            return true
        }
        return value
    }
}
