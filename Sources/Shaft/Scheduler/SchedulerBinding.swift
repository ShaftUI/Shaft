// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The various phases that a [SchedulerBinding] goes through during
/// [SchedulerBinding.handleBeginFrame].
///
/// This is exposed by [SchedulerBinding.schedulerPhase].
///
/// The values of this enum are ordered in the same order as the phases occur,
/// so their relative index values can be compared to each other.
public enum SchedulerPhase: Comparable {
    /// No frame is being processed.
    case idle

    /// The transient callbacks are currently executing.
    case transientCallbacks

    /// Microtasks scheduled during the processing of transient callbacks are
    /// current executing. **This phase is currently unused.**
    case midFrameMicrotasks

    /// The persistent callbacks are currently executing.
    case persistentCallbacks

    /// The post-frame callbacks are currently executing.
    case postFrameCallbacks
}

public class SchedulerBinding {
    public static let shared = SchedulerBinding()

    private init() {}

    // MARK: - Frame Scheduling

    /// The phase that the scheduler is currently operating under.
    public private(set) var schedulerPhase = SchedulerPhase.idle

    /// Whether this scheduler has requested that [handleBeginFrame] be called soon.
    public private(set) var hasScheduledFrame = false

    /// Whether frames are currently being scheduled when [scheduleFrame] is called.
    ///
    /// This value depends on the value of the [lifecycleState].
    public private(set) var framesEnabled = true

    private var warmUpFrame = false

    // Whether the current engine frame needs to be postponed till after the
    // warm-up frame.
    //
    // Engine may begin a frame in the middle of the warm-up frame because the
    // warm-up frame is scheduled by timers while the engine frame is scheduled
    // by platform specific frame scheduler (e.g. `requestAnimationFrame` on the
    // web). When this happens, we let the warm-up frame finish, and postpone the
    // engine frame.
    private var rescheduleAfterWarmUpFrame = false

    /// Schedules a new frame using [scheduleFrame] if this object is not
    /// currently producing a frame.
    ///
    /// Calling this method ensures that [handleDrawFrame] will eventually be
    /// called, unless it's already in progress.
    public func ensureVisualUpdate() {
        switch schedulerPhase {
        case .idle, .postFrameCallbacks:
            scheduleFrame()
            return
        case .transientCallbacks, .midFrameMicrotasks, .persistentCallbacks:
            return
        }
    }

    public func scheduleFrame() {
        if hasScheduledFrame || !framesEnabled {
            return
        }
        ensureFrameCallbacksRegistered()
        backend.scheduleFrame()
        hasScheduledFrame = true
    }

    /// Ensures callbacks for [PlatformDispatcher.onBeginFrame] and
    /// [PlatformDispatcher.onDrawFrame] are registered.
    private func ensureFrameCallbacksRegistered() {
        backend.onBeginFrame = handleBeginFrame
        backend.onDrawFrame = handleDrawFrame
    }

    /// Slows down animations by this factor to help in development.
    public var timeDilation: Double = 1.0 {
        didSet {
            assert(timeDilation > 0.0)
            if timeDilation == oldValue {
                return
            }
            // If the binding has been created, we need to resetEpoch first so that we
            // capture start of the epoch with the current time dilation.
            resetEpoch()
        }
    }

    /// The raw time stamp as provided by the engine to
    /// [dart:ui.PlatformDispatcher.onBeginFrame] for the frame currently being
    /// processed.
    ///
    /// Unlike [currentFrameTimeStamp], this time stamp is neither adjusted to
    /// offset when the epoch started nor scaled to reflect the [timeDilation] in
    /// the current epoch.
    ///
    /// On most platforms, this is a more or less arbitrary value, and should
    /// generally be ignored. On Fuchsia, this corresponds to the system-provided
    /// presentation time, and can be used to ensure that animations running in
    /// different processes are synchronized.
    public var currentSystemFrameTimeStamp: Duration {
        return lastRawTimeStamp
    }

    /// The time stamp for the frame currently being processed.
    ///
    /// This is only valid while between the start of [handleBeginFrame] and the
    /// end of the corresponding [handleDrawFrame], i.e. while a frame is being
    /// produced.
    public private(set) var currentFrameTimeStamp: Duration!

    private var firstRawTimeStampInEpoch: Duration?
    private var epochStart: Duration = .zero
    private var lastRawTimeStamp: Duration = .zero

    /// Prepares the scheduler for a non-monotonic change to how time stamps are
    /// calculated.
    ///
    /// Callbacks received from the scheduler assume that their time stamps are
    /// monotonically increasing. The raw time stamp passed to [handleBeginFrame]
    /// is monotonic, but the scheduler might adjust those time stamps to provide
    /// [timeDilation]. Without careful handling, these adjusts could cause time
    /// to appear to run backwards.
    ///
    /// The [resetEpoch] function ensures that the time stamps are monotonic by
    /// resetting the base time stamp used for future time stamp adjustments to the
    /// current value. For example, if the [timeDilation] decreases, rather than
    /// scaling down the [Duration] since the beginning of time, [resetEpoch] will
    /// ensure that we only scale down the duration since [resetEpoch] was called.
    ///
    /// Setting [timeDilation] calls [resetEpoch] automatically. You don't need to
    /// call [resetEpoch] yourself.
    private func resetEpoch() {
        epochStart = adjustForEpoch(lastRawTimeStamp)
        firstRawTimeStampInEpoch = nil
    }

    /// Adjusts the given time stamp into the current epoch.
    ///
    /// This both offsets the time stamp to account for when the epoch started
    /// (both in raw time and in the epoch's own time line) and scales the time
    /// stamp to reflect the time dilation in the current epoch.
    ///
    /// These mechanisms together combine to ensure that the durations we give
    /// during frame callbacks are monotonically increasing.
    private func adjustForEpoch(_ rawTimeStamp: Duration) -> Duration {
        let rawDurationSinceEpoch =
            firstRawTimeStampInEpoch == nil
            ? Duration.zero : rawTimeStamp - firstRawTimeStampInEpoch!
        return Duration.microseconds(
            Int64(
                (Double(rawDurationSinceEpoch.inMicroseconds) / timeDilation).rounded()
            ) + epochStart.inMicroseconds
        )
    }

    /// Called by the engine to prepare the framework to produce a new frame.
    ///
    /// This function calls all the transient frame callbacks registered by
    /// [scheduleFrameCallback].
    private func handleBeginFrame(timeStamp: Duration?) {

        firstRawTimeStampInEpoch = firstRawTimeStampInEpoch ?? timeStamp
        currentFrameTimeStamp = adjustForEpoch(timeStamp ?? lastRawTimeStamp)
        if let timeStamp {
            lastRawTimeStamp = timeStamp
        }
        if warmUpFrame {
            assert(!rescheduleAfterWarmUpFrame)
            rescheduleAfterWarmUpFrame = true
            return
        }

        assert(schedulerPhase == .idle)
        hasScheduledFrame = false

        schedulerPhase = .transientCallbacks
        let localTransientCallbacks = transientCallbacks.values
        transientCallbacks.removeAll()
        for callback in localTransientCallbacks {
            callback(currentFrameTimeStamp)
        }

        schedulerPhase = .midFrameMicrotasks
    }

    /// Called by the engine to produce a new frame.
    ///
    /// This method is called immediately after [handleBeginFrame]. It calls all
    /// the callbacks registered by [addPersistentFrameCallback], which typically
    /// drive the rendering pipeline, and then calls the callbacks registered by
    /// [addPostFrameCallback].
    private func handleDrawFrame() {
        if rescheduleAfterWarmUpFrame {
            rescheduleAfterWarmUpFrame = false
            // Reschedule in a post-frame callback to allow the draw-frame phase
            // of the warm-up frame to finish.
            addPostFrameCallback { [weak self] _ in
                // Force an engine frame.
                //
                // We need to reset _hasScheduledFrame here because we cancelled
                // the original engine frame, and therefore did not run
                // handleBeginFrame who is responsible for resetting it. So if a
                // frame callback set this to true in the "begin frame" part of
                // the warm-up frame, it will still be true here and cause us to
                // skip scheduling an engine frame.
                self?.hasScheduledFrame = false
                self?.scheduleFrame()
            }
            return
        }
        assert(schedulerPhase == .midFrameMicrotasks)

        schedulerPhase = .persistentCallbacks
        let localPersistentCallbacks = persistentCallbacks
        for callback in localPersistentCallbacks {
            callback(currentFrameTimeStamp)
        }

        schedulerPhase = .postFrameCallbacks
        let localPostFrameCallbacks = postFrameCallbacks
        postFrameCallbacks.removeAll()
        for callback in localPostFrameCallbacks {
            callback(currentFrameTimeStamp)
        }

        schedulerPhase = .idle
    }

    // MARK: - Frame Callbacks

    private var nextFrameCallbackId = 0
    private var transientCallbacks = [Int: FrameCallback]()

    /// Schedules the given transient frame callback.
    ///
    /// Adds the given callback to the list of frame callbacks and ensures that a
    /// frame is scheduled.
    public func scheduleFrameCallback(_ callback: @escaping FrameCallback) -> Int {
        scheduleFrame()
        nextFrameCallbackId += 1
        transientCallbacks[nextFrameCallbackId] = callback
        return nextFrameCallbackId
    }

    /// Cancels the transient frame callback with the given [id].
    ///
    /// Removes the given callback from the list of frame callbacks. If a frame
    /// has been requested, this does not also cancel that request.
    ///
    /// Transient frame callbacks are those registered using
    /// [scheduleFrameCallback].
    public func cancelFrameCallbackWithId(_ id: Int) {
        assert(id > 0)
        transientCallbacks.removeValue(forKey: id)
    }

    private var persistentCallbacks = [FrameCallback]()

    /// Adds a persistent frame callback.
    ///
    /// Persistent callbacks are called after transient (non-persistent) frame
    /// callbacks.
    public func addPersistentFrameCallback(_ callback: @escaping FrameCallback) {
        persistentCallbacks.append(callback)
    }

    private var postFrameCallbacks = [FrameCallback]()

    /// Schedule a callback for the end of this frame.
    ///
    /// The provided callback is run immediately after a frame, just after the
    /// persistent frame callbacks (which is when the main rendering pipeline has
    /// been flushed).
    public func addPostFrameCallback(_ callback: @escaping FrameCallback) {
        postFrameCallbacks.append(callback)
    }

}
