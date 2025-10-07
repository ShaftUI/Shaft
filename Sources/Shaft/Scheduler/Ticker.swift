/// Signature for the callback passed to the ``Ticker`` class's constructor.
///
/// The argument is the time that the object had spent enabled so far
/// at the time of the callback being called.
public typealias TickerCallback = (Duration) -> Void

/// An interface implemented by classes that can vend ``Ticker`` objects.
///
/// Tickers can be used by any object that wants to be notified whenever a frame
/// triggers, but are most commonly used indirectly via an
/// ``AnimationController``. ``AnimationController``s need a ``TickerProvider`` to
/// obtain their ``Ticker``. If you are creating an ``AnimationController`` from a
/// ``State``, then you can use the ``TickerProviderStateMixin`` and
/// ``SingleTickerProviderStateMixin`` classes to obtain a suitable
/// ``TickerProvider``. The widget test framework ``WidgetTester`` object can be
/// used as a ticker provider in the context of tests. In other contexts, you
/// will have to either pass a ``TickerProvider`` from a higher level (e.g.
/// indirectly from a ``State`` that mixes in ``TickerProviderStateMixin``), or
/// create a custom ``TickerProvider`` subclass.
public protocol TickerProvider {
    /// Creates a ticker with the given callback.
    ///
    /// The kind of ticker provided depends on the kind of ticker provider.
    func createTicker(_ onTick: @escaping TickerCallback) -> Ticker
}

/// Calls its callback once per animation frame.
///
/// When created, a ticker is initially disabled. Call [start] to
/// enable the ticker.
///
/// A ``Ticker`` can be silenced by setting [muted] to true. While silenced, time
/// still elapses, and [start] and [stop] can still be called, but no callbacks
/// are called.
///
/// By convention, the [start] and [stop] methods are used by the ticker's
/// consumer, and the [muted] property is controlled by the ``TickerProvider``
/// that created the ticker.
///
/// Tickers are driven by the [SchedulerBinding]. See
/// [SchedulerBinding.scheduleFrameCallback].
public class Ticker {
    /// Creates a ticker that will call the provided callback once per frame while
    /// running.
    ///
    /// An optional label can be provided for debugging purposes. That label
    /// will appear in the [toString] output in debug builds.
    public init(_ onTick: @escaping TickerCallback) {
        _onTick = onTick
    }

    /// Whether this ticker has been silenced.
    ///
    /// While silenced, a ticker's clock can still run, but the callback will not
    /// be called.
    public var muted: Bool = false {
        didSet {
            if oldValue == muted {
                return
            }
            if muted {
                unscheduleTick()
            } else if shouldScheduleTick {
                scheduleTick()
            }
        }
    }

    /// Whether this ``Ticker`` has scheduled a call to call its callback
    /// on the next frame.
    ///
    /// A ticker that is [muted] can be active (see [isActive]) yet not be
    /// ticking. In that case, the ticker will not call its callback, and
    /// [isTicking] will be false, but time will still be progressing.
    ///
    /// This will return false if the [SchedulerBinding.lifecycleState] is one
    /// that indicates the application is not currently visible (e.g. if the
    /// device's screen is turned off).
    public var isTicking: Bool {
        if muted {
            return false
        }
        if SchedulerBinding.shared.framesEnabled {
            return true
        }
        if SchedulerBinding.shared.schedulerPhase != .idle {
            return true
        }  // for example, we might be in a warm-up frame or forced frame
        return false
    }

    private var _future: TickerFuture?

    /// Whether time is elapsing for this ``Ticker``. Becomes true when [start] is
    /// called and false when [stop] is called.
    ///
    /// A ticker can be active yet not be actually ticking (i.e. not be calling
    /// the callback). To determine if a ticker is actually ticking, use
    /// [isTicking].
    //   bool get isActive => _future != null;
    public var isActive: Bool {
        _future != nil
    }

    private var _startTime: Duration?

    /// Starts the clock for this ``Ticker``. If the ticker is not [muted], then this
    /// also starts calling the ticker's callback once per animation frame.
    ///
    /// The returned future resolves once the ticker [stop]s ticking. If the
    /// ticker is disposed, the future does not resolve. A derivative future is
    /// available from the returned [TickerFuture] object that resolves with an
    /// error in that case, via [TickerFuture.orCancel].
    ///
    /// Calling this sets [isActive] to true.
    ///
    /// This method cannot be called while the ticker is active. To restart the
    /// ticker, first [stop] it.
    ///
    /// By convention, this method is used by the object that receives the ticks
    /// (as opposed to the ``TickerProvider`` which created the ticker).
    public func start() -> TickerFuture {
        assert(!isActive, "A ticker cannot be started twice.")
        assert(_startTime == nil)
        _future = TickerFuture()
        if shouldScheduleTick {
            scheduleTick()
        }
        if SchedulerBinding.shared.schedulerPhase > .idle
            && SchedulerBinding.shared.schedulerPhase < .postFrameCallbacks
        {
            _startTime = SchedulerBinding.shared.currentFrameTimeStamp
        }
        return _future!
    }

    /// Stops calling this ``Ticker``'s callback.
    ///
    /// If called with the `canceled` argument set to false (the default), causes
    /// the future returned by [start] to resolve. If called with the `canceled`
    /// argument set to true, the future does not resolve, and the future obtained
    /// from [TickerFuture.orCancel], if any, resolves with a [TickerCanceled]
    /// error.
    ///
    /// Calling this sets [isActive] to false.
    ///
    /// This method does nothing if called when the ticker is inactive.
    ///
    /// By convention, this method is used by the object that receives the ticks
    /// (as opposed to the ``TickerProvider`` which created the ticker).
    public func stop(canceled: Bool = false) {
        if !isActive {
            return
        }

        // We take the _future into a local variable so that isTicking is false
        // when we actually complete the future (isTicking uses _future to
        // determine its state).
        let localFuture = _future!
        _future = nil
        _startTime = nil
        assert(!isActive)

        unscheduleTick()
        if canceled {
            localFuture._cancel(self)
        } else {
            localFuture._complete()
        }
    }

    private let _onTick: TickerCallback

    private var _animationId: Int?

    /// Whether this ``Ticker`` has already scheduled a frame callback.
    var scheduled: Bool {
        _animationId != nil
    }

    /// Whether a tick should be scheduled.
    ///
    /// If this is true, then calling [scheduleTick] should succeed.
    ///
    /// Reasons why a tick should not be scheduled include:
    ///
    /// * A tick has already been scheduled for the coming frame.
    /// * The ticker is not active ([start] has not been called).
    /// * The ticker is not ticking, e.g. because it is [muted] (see [isTicking]).
    var shouldScheduleTick: Bool {
        !muted && isActive && !scheduled
    }

    private func _tick(_ timeStamp: Duration) {
        assert(isTicking)
        assert(scheduled)
        _animationId = nil

        if _startTime == nil {
            _startTime = timeStamp
        }
        _onTick(timeStamp - _startTime!)

        // The onTick callback may have scheduled another tick already, for
        // example by calling stop then start again.
        if shouldScheduleTick {
            scheduleTick(rescheduling: true)
        }
    }

    /// Schedules a tick for the next frame.
    ///
    /// This should only be called if [shouldScheduleTick] is true.
    private func scheduleTick(rescheduling: Bool = false) {
        assert(!scheduled)
        assert(shouldScheduleTick)
        _animationId = SchedulerBinding.shared.scheduleFrameCallback(_tick)
    }

    /// Cancels the frame callback that was requested by [scheduleTick], if any.
    ///
    /// Calling this method when no tick is [scheduled] is harmless.
    ///
    /// This method should not be called when [shouldScheduleTick] would return
    /// true if no tick was scheduled.
    private func unscheduleTick() {
        if scheduled {
            SchedulerBinding.shared.cancelFrameCallbackWithId(_animationId!)
            _animationId = nil
        }
        assert(!shouldScheduleTick)
    }

    /// Makes this ``Ticker`` take the state of another ticker, and disposes the
    /// other ticker.
    ///
    /// This is useful if an object with a ``Ticker`` is given a new
    /// ``TickerProvider`` but needs to maintain continuity. In particular, this
    /// maintains the identity of the [TickerFuture] returned by the [start]
    /// function of the original ``Ticker`` if the original ticker is active.
    ///
    /// This ticker must not be active when this method is called.
    public func absorbTicker(_ originalTicker: Ticker) {
        assert(!isActive)
        assert(_future == nil)
        assert(_startTime == nil)
        assert(_animationId == nil)
        assert(
            (originalTicker._future == nil) == (originalTicker._startTime == nil),
            "Cannot absorb Ticker after it has been disposed."
        )
        if originalTicker._future != nil {
            _future = originalTicker._future
            _startTime = originalTicker._startTime
            if shouldScheduleTick {
                scheduleTick()
            }
            originalTicker._future = nil  // so that it doesn't get disposed when we dispose of originalTicker
            originalTicker.unscheduleTick()
        }
        originalTicker.dispose()
    }

    /// Release the resources used by this object. The object is no longer usable
    /// after this method is called.
    ///
    /// It is legal to call this method while [isActive] is true, in which case:
    ///
    ///  * The frame callback that was requested by [scheduleTick], if any, is
    ///    canceled.
    ///  * The future that was returned by [start] does not resolve.
    ///  * The future obtained from [TickerFuture.orCancel], if any, resolves
    ///    with a [TickerCanceled] error.
    public func dispose() {
        if let localFuture = _future {
            _future = nil
            assert(!isActive)
            unscheduleTick()
            localFuture._cancel(self)
        }
        assert {
            // We intentionally don't null out _startTime. This means that if start()
            // was ever called, the object is now in a bogus state. This weakly helps
            // catch cases of use-after-dispose.
            _startTime = .zero
            return true
        }
    }
}

/// An object representing an ongoing ``Ticker`` sequence.
///
/// The [Ticker.start] method returns a [TickerFuture]. The [TickerFuture] will
/// complete successfully if the ``Ticker`` is stopped using [Ticker.stop] with
/// the `canceled` argument set to false (the default).
///
/// If the ``Ticker`` is disposed without being stopped, or if it is stopped with
/// `canceled` set to true, then this Future will never complete.
///
/// This class works like a normal [Future], but has an additional property,
/// [orCancel], which returns a derivative [Future] that completes with an error
/// if the ``Ticker`` that returned the [TickerFuture] was stopped with `canceled`
/// set to true, or if it was disposed without being stopped.
///
/// To run a callback when either this future resolves or when the ticker is
/// canceled, use [whenCompleteOrCancel].
public class TickerFuture {
    static func complete() -> TickerFuture {
        TickerFuture()
    }

    private var _callbacks: [() -> Void] = []

    func whenComplete(_ callback: @escaping () -> Void) {
        _callbacks.append(callback)
    }

    func _complete() {
        let localCallbacks = _callbacks
        _callbacks = []
        for callback in localCallbacks {
            callback()
        }
    }

    func _cancel(_ ticker: Ticker) {

    }
}
