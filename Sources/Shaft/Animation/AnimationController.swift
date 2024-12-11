/// The direction in which an animation is running.
private enum _AnimationDirection {
    /// The animation is running from beginning to end.
    case forward

    /// The animation is running backwards, from end to beginning.
    case reverse
}

private let _kFlingSpringDescription = SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 500.0
)

private let _kFlingTolerance = Tolerance(
    distance: 0.01,
    velocity: Double.infinity
)

/// Configures how an [AnimationController] behaves when animations are
/// disabled.
///
/// When [AccessibilityFeatures.disableAnimations] is true, the device is asking
/// Flutter to reduce or disable animations as much as possible. To honor this,
/// we reduce the duration and the corresponding number of frames for
/// animations. This enum is used to allow certain [AnimationController]s to opt
/// out of this behavior.
///
/// For example, the [AnimationController] which controls the physics simulation
/// for a scrollable list will have [AnimationBehavior.preserve], so that when
/// a user attempts to scroll it does not jump to the end/beginning too quickly.
public enum AnimationBehavior {
    /// The [AnimationController] will reduce its duration when
    /// [AccessibilityFeatures.disableAnimations] is true.
    case normal

    /// The [AnimationController] will preserve its behavior.
    ///
    /// This is the default for repeating animations in order to prevent them from
    /// flashing rapidly on the screen if the widget does not take the
    /// [AccessibilityFeatures.disableAnimations] flag into account.
    case preserve
}

/// A controller for an animation.
///
/// This class lets you perform tasks such as:
///
/// * Play an animation [forward] or in [reverse], or [stop] an animation.
/// * Set the animation to a specific [value].
/// * Define the [upperBound] and [lowerBound] values of an animation.
/// * Create a [fling] animation effect using a physics simulation.
///
/// By default, an [AnimationController] linearly produces values that range
/// from 0.0 to 1.0, during a given duration. The animation controller generates
/// a new value whenever the device running your app is ready to display a new
/// frame (typically, this rate is around 60 values per second).
///
/// ## Ticker providers
///
/// An [AnimationController] needs a [TickerProvider], which is configured using
/// the `vsync` argument on the constructor.
///
/// The [TickerProvider] interface describes a factory for [Ticker] objects. A
/// [Ticker] is an object that knows how to register itself with the
/// [SchedulerBinding] and fires a callback every frame. The
/// [AnimationController] class uses a [Ticker] to step through the animation
/// that it controls.
///
/// If an [AnimationController] is being created from a [State], then the State
/// can use the [TickerProviderStateMixin] and [SingleTickerProviderStateMixin]
/// classes to implement the [TickerProvider] interface. The
/// [TickerProviderStateMixin] class always works for this purpose; the
/// [SingleTickerProviderStateMixin] is slightly more efficient in the case of
/// the class only ever needing one [Ticker] (e.g. if the class creates only a
/// single [AnimationController] during its entire lifetime).
///
/// The widget test framework [WidgetTester] object can be used as a ticker
/// provider in the context of tests. In other contexts, you will have to either
/// pass a [TickerProvider] from a higher level (e.g. indirectly from a [State]
/// that mixes in [TickerProviderStateMixin]), or create a custom
/// [TickerProvider] subclass.
///
/// ## Life cycle
///
/// An [AnimationController] should be [dispose]d when it is no longer needed.
/// This reduces the likelihood of leaks. When used with a [StatefulWidget], it
/// is common for an [AnimationController] to be created in the
/// [State.initState] method and then disposed in the [State.dispose] method.
///
/// ## Using [Future]s with [AnimationController]
///
/// The methods that start animations return a [TickerFuture] object which
/// completes when the animation completes successfully, and never throws an
/// error; if the animation is canceled, the future never completes. This object
/// also has a [TickerFuture.orCancel] property which returns a future that
/// completes when the animation completes successfully, and completes with an
/// error when the animation is aborted.
///
/// This can be used to write code such as the `fadeOutAndUpdateState` method
/// below.
///
/// See also:
///
///  * [Tween], the base class for converting an [AnimationController] to a
///    range of values of other types.
public class AnimationController: AnimationBase, Animation  //   with AnimationEagerListenerMixin, AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin
{
    /// Creates an animation controller.
    ///
    /// * `value` is the initial value of the animation. If defaults to the lower
    ///   bound.
    ///
    /// * [duration] is the length of time this animation should last.
    ///
    /// * [debugLabel] is a string to help identify this animation during
    ///   debugging (used by [toString]).
    ///
    /// * [lowerBound] is the smallest value this animation can obtain and the
    ///   value at which this animation is deemed to be dismissed. It cannot be
    ///   null.
    ///
    /// * [upperBound] is the largest value this animation can obtain and the
    ///   value at which this animation is deemed to be completed. It cannot be
    ///   null.
    ///
    /// * `vsync` is the required [TickerProvider] for the current context. It can
    ///   be changed by calling [resync]. See [TickerProvider] for advice on
    ///   obtaining a ticker provider.
    public init(
        value: Double? = nil,
        duration: Duration? = nil,
        reverseDuration: Duration? = nil,
        debugLabel: String? = nil,
        lowerBound: Double = 0.0,
        upperBound: Double = 1.0,
        animationBehavior: AnimationBehavior = .normal,
        vsync: TickerProvider
    ) {
        assert(upperBound >= lowerBound)
        self.duration = duration
        self.reverseDuration = reverseDuration
        self.debugLabel = debugLabel
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.animationBehavior = animationBehavior
        self._direction = .forward

        super.init()

        _ticker = vsync.createTicker(_tick)
        _internalSetValue(value ?? lowerBound)
    }

    /// Creates an animation controller with no upper or lower bound for its
    /// value.
    ///
    /// * [value] is the initial value of the animation.
    ///
    /// * [duration] is the length of time this animation should last.
    ///
    /// * [debugLabel] is a string to help identify this animation during
    ///   debugging (used by [toString]).
    ///
    /// * `vsync` is the required [TickerProvider] for the current context. It can
    ///   be changed by calling [resync]. See [TickerProvider] for advice on
    ///   obtaining a ticker provider.
    ///
    /// This constructor is most useful for animations that will be driven using a
    /// physics simulation, especially when the physics simulation has no
    /// pre-determined bounds.
    public static func unbounded(
        value: Double? = nil,
        duration: Duration? = nil,
        reverseDuration: Duration? = nil,
        debugLabel: String? = nil,
        animationBehavior: AnimationBehavior = .preserve,
        vsync: TickerProvider
    ) -> AnimationController {
        return AnimationController(
            value: value,
            duration: duration,
            reverseDuration: reverseDuration,
            debugLabel: debugLabel,
            lowerBound: -.infinity,
            upperBound: .infinity,
            animationBehavior: animationBehavior,
            vsync: vsync
        )
    }

    /// The value at which this animation is deemed to be dismissed.
    public let lowerBound: Double

    /// The value at which this animation is deemed to be completed.
    public let upperBound: Double

    /// A label that is used in the [toString] output. Intended to aid with
    /// identifying animation controller instances in debug output.
    public let debugLabel: String?

    /// The behavior of the controller when [AccessibilityFeatures.disableAnimations]
    /// is true.
    ///
    /// Defaults to [AnimationBehavior.normal] for the [AnimationController.new]
    /// constructor, and [AnimationBehavior.preserve] for the
    /// [AnimationController.unbounded] constructor.
    public let animationBehavior: AnimationBehavior

    /// Returns an [Animation<double>] for this animation controller, so that a
    /// pointer to this object can be passed around without allowing users of that
    /// pointer to mutate the [AnimationController] state.
    public var view: any Animation<Double> { return self }

    /// The length of time this animation should last.
    ///
    /// If [reverseDuration] is specified, then [duration] is only used when going
    /// [forward]. Otherwise, it specifies the duration going in both directions.
    public var duration: Duration?

    /// The length of time this animation should last when going in [reverse].
    ///
    /// The value of [duration] is used if [reverseDuration] is not specified or
    /// set to null.
    public var reverseDuration: Duration?

    var _ticker: Ticker?

    /// Recreates the [Ticker] with the new [TickerProvider].
    func resync(_ vsync: TickerProvider) {
        let oldTicker = _ticker!
        _ticker = vsync.createTicker(_tick)
        _ticker!.absorbTicker(oldTicker)
    }

    var _simulation: Simulation?

    /// The current value of the animation.
    ///
    /// Setting this value notifies all the listeners that the value
    /// changed.
    ///
    /// Setting this value also stops the controller if it is currently
    /// running; if this happens, it also notifies all the status
    /// listeners.
    public var value: Double {
        get { return _value }
        set {
            stop()
            _internalSetValue(newValue)
            notifyListeners()
            _checkStatusChanged()
        }
    }
    private var _value: Double = 0.0

    /// Sets the controller's value to [lowerBound], stopping the animation (if
    /// in progress), and resetting to its beginning point, or dismissed state.
    ///
    /// The most recently returned [TickerFuture], if any, is marked as having been
    /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
    /// derivative future completes with a [TickerCanceled] error.
    ///
    /// See also:
    ///
    ///  * [value], which can be explicitly set to a specific value as desired.
    ///  * [forward], which starts the animation in the forward direction.
    ///  * [stop], which aborts the animation without changing its value or status
    ///    and without dispatching any notifications other than completing or
    ///    canceling the [TickerFuture].
    public func reset() {
        value = lowerBound
    }

    /// The rate of change of [value] per second.
    ///
    /// If [isAnimating] is false, then [value] is not changing and the rate of
    /// change is zero.
    public var velocity: Double {
        if !isAnimating {
            return 0.0
        }
        return _simulation!.dx(
            Double(lastElapsedDuration!.inMicroseconds) / Double(Duration.microsecondsPerSecond)
        )
    }

    func _internalSetValue(_ newValue: Double) {
        _value = newValue.clamped(to: lowerBound...upperBound)
        if _value == lowerBound {
            status = .dismissed
        } else if _value == upperBound {
            status = .completed
        } else {
            status =
                switch _direction {
                case .forward: .forward
                case .reverse: .reverse
                }
        }
    }

    /// The amount of time that has passed between the time the animation started
    /// and the most recent tick of the animation.
    ///
    /// If the controller is not animating, the last elapsed duration is null.
    public private(set) var lastElapsedDuration: Duration?

    /// Whether this animation is currently animating in either the forward or reverse direction.
    ///
    /// This is separate from whether it is actively ticking. An animation
    /// controller's ticker might get muted, in which case the animation
    /// controller's callbacks will no longer fire even though time is continuing
    /// to pass. See [Ticker.muted] and [TickerMode].
    public var isAnimating: Bool {
        return _ticker != nil && _ticker!.isActive
    }

    private var _direction: _AnimationDirection

    public private(set) var status: AnimationStatus = .dismissed

    /// Starts running this animation forwards (towards the end).
    ///
    /// Returns a [TickerFuture] that completes when the animation is complete.
    ///
    /// If [from] is non-null, it will be set as the current [value] before running
    /// the animation.
    ///
    /// The most recently returned [TickerFuture], if any, is marked as having been
    /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
    /// derivative future completes with a [TickerCanceled] error.
    ///
    /// During the animation, [status] is reported as [AnimationStatus.forward],
    /// which switches to [AnimationStatus.completed] when [upperBound] is
    /// reached at the end of the animation.
    public func forward(from: Double? = nil) -> TickerFuture {
        assert(
            duration != nil,
            "AnimationController.forward() called with no default duration.\nThe \"duration\" property should be set, either in the constructor or later, before calling the forward() function."
        )

        assert(
            _ticker != nil,
            "AnimationController.forward() called after AnimationController.dispose()\nAnimationController methods should not be used after calling dispose."
        )

        _direction = .forward
        if let from = from {
            value = from
        }
        return _animateToInternal(upperBound)
    }

    /// Starts running this animation in reverse (towards the beginning).
    ///
    /// Returns a [TickerFuture] that completes when the animation is dismissed.
    ///
    /// If [from] is non-null, it will be set as the current [value] before running
    /// the animation.
    ///
    /// The most recently returned [TickerFuture], if any, is marked as having been
    /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
    /// derivative future completes with a [TickerCanceled] error.
    ///
    /// During the animation, [status] is reported as [AnimationStatus.reverse],
    /// which switches to [AnimationStatus.dismissed] when [lowerBound] is
    /// reached at the end of the animation.
    public func reverse(from: Double? = nil) -> TickerFuture {
        assert(
            duration != nil || reverseDuration != nil,
            "AnimationController.reverse() called with no default duration or reverseDuration.\nThe \"duration\" or \"reverseDuration\" property should be set, either in the constructor or later, before calling the reverse() function."
        )

        assert(
            _ticker != nil,
            "AnimationController.reverse() called after AnimationController.dispose()\nAnimationController methods should not be used after calling dispose."
        )

        _direction = .reverse
        if let from = from {
            value = from
        }
        return _animateToInternal(lowerBound)
    }

    /// Toggles the direction of this animation, based on whether it [isForwardOrCompleted].
    ///
    /// Specifically, this function acts the same way as [reverse] if the [status] is
    /// either [AnimationStatus.forward] or [AnimationStatus.completed], and acts as
    /// [forward] for [AnimationStatus.reverse] or [AnimationStatus.dismissed].
    ///
    /// If [from] is non-null, it will be set as the current [value] before running
    /// the animation.
    ///
    /// The most recently returned [TickerFuture], if any, is marked as having been
    /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
    /// derivative future completes with a [TickerCanceled] error.
    public func toggle(from: Double? = nil) -> TickerFuture {
        assert(
            duration != nil,
            "AnimationController.toggle() called with no default duration.\nThe \"duration\" property should be set, either in the constructor or later, before calling the toggle() function."
        )

        assert(
            _ticker != nil,
            "AnimationController.toggle() called after AnimationController.dispose()\nAnimationController methods should not be used after calling dispose."
        )

        _direction = isForwardOrCompleted ? .reverse : .forward
        if let from = from {
            value = from
        }
        return _animateToInternal(
            _direction == .forward ? upperBound : lowerBound
        )
    }

    /// Drives the animation from its current value to target.
    ///
    /// Returns a [TickerFuture] that completes when the animation is complete.
    ///
    /// The most recently returned [TickerFuture], if any, is marked as having been
    /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
    /// derivative future completes with a [TickerCanceled] error.
    ///
    /// During the animation, [status] is reported as [AnimationStatus.forward]
    /// regardless of whether `target` > [value] or not. At the end of the
    /// animation, when `target` is reached, [status] is reported as
    /// [AnimationStatus.completed].
    ///
    /// If the `target` argument is the same as the current [value] of the
    /// animation, then this won't animate, and the returned [TickerFuture] will
    /// be already complete.
    public func animateTo(_ target: Double, duration: Duration? = nil, curve: Curve = Curves.linear)
        -> TickerFuture
    {
        assert(
            self.duration != nil || duration != nil,
            "AnimationController.animateTo() called with no explicit duration and no default duration.\n"
                + "Either the \"duration\" argument to the animateTo() method should be provided, or the "
                + "\"duration\" property should be set, either in the constructor or later, before "
                + "calling the animateTo() function."

        )

        assert(
            _ticker != nil,
            "AnimationController.animateTo() called after AnimationController.dispose()\n"
                + "AnimationController methods should not be used after calling dispose."
        )

        _direction = .forward
        return _animateToInternal(target, duration: duration, curve: curve)
    }

    /// Drives the animation from its current value to target.
    ///
    /// Returns a [TickerFuture] that completes when the animation is complete.
    ///
    /// The most recently returned [TickerFuture], if any, is marked as having been
    /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
    /// derivative future completes with a [TickerCanceled] error.
    ///
    /// During the animation, [status] is reported as [AnimationStatus.reverse]
    /// regardless of whether `target` < [value] or not. At the end of the
    /// animation, when `target` is reached, [status] is reported as
    /// [AnimationStatus.dismissed].
    public func animateBack(
        _ target: Double,
        duration: Duration? = nil,
        curve: Curve = Curves.linear
    )
        -> TickerFuture
    {

        assert(
            self.duration != nil || duration != nil,
            "AnimationController.animateBack() called with no explicit duration and no default duration.\n"
                + "Either the \"duration\" argument to the animateBack() method should be provided, or the "
                + "\"duration\" property should be set, either in the constructor or later, before "
                + "calling the animateBack() function."
        )

        assert(
            _ticker != nil,
            "AnimationController.animateBack() called after AnimationController.dispose()\n"
                + "AnimationController methods should not be used after calling dispose."
        )

        _direction = .reverse
        return _animateToInternal(target, duration: duration, curve: curve)
    }
    private func _animateToInternal(
        _ target: Double,
        duration: Duration? = nil,
        curve: Curve = Curves.linear
    ) -> TickerFuture {
        let scale: Double =
            switch animationBehavior {
            // case .normal where SemanticsBinding.instance.disableAnimations:
            //     0.05
            case .normal, .preserve:
                1.0
            }

        var simulationDuration = duration
        if simulationDuration == nil {
            assert(!(self.duration == nil && _direction == .forward))
            assert(!(self.duration == nil && _direction == .reverse && reverseDuration == nil))
            let range = upperBound - lowerBound
            let remainingFraction = range.isFinite ? abs(target - _value) / range : 1.0
            let directionDuration =
                (_direction == .reverse && reverseDuration != nil)
                ? reverseDuration!
                : self.duration!
            simulationDuration = directionDuration * remainingFraction
        } else if target == value {
            simulationDuration = .zero
        }

        stop()
        if simulationDuration == .zero {
            if value != target {
                _value = target.clamped(to: lowerBound...upperBound)
                notifyListeners()
            }
            status = (_direction == .forward) ? .completed : .dismissed
            _checkStatusChanged()
            return TickerFuture.complete()
        }

        assert(simulationDuration! > .zero)
        assert(!isAnimating)
        return _startSimulation(
            _InterpolationSimulation(
                begin: _value,
                end: target,
                duration: simulationDuration!,
                curve: curve,
                scale: scale
            )
        )
    }

    /// Starts running this animation in the forward direction, and
    /// restarts the animation when it completes.
    ///
    /// Defaults to repeating between the [lowerBound] and [upperBound] of the
    /// [AnimationController] when no explicit value is set for [min] and [max].
    ///
    /// With [reverse] set to true, instead of always starting over at [min]
    /// the starting value will alternate between [min] and [max] values on each
    /// repeat. The [status] will be reported as [AnimationStatus.reverse] when
    /// the animation runs from [max] to [min].
    ///
    /// Each run of the animation will have a duration of `period`. If `period` is not
    /// provided, [duration] will be used instead, which has to be set before [repeat] is
    /// called either in the constructor or later by using the [duration] setter.
    ///
    /// Returns a [TickerFuture] that never completes. The [TickerFuture.orCancel] future
    /// completes with an error when the animation is stopped (e.g. with [stop]).
    ///
    /// The most recently returned [TickerFuture], if any, is marked as having been
    /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
    /// derivative future completes with a [TickerCanceled] error.
    public func `repeat`(
        min: Double? = nil,
        max: Double? = nil,
        reverse: Bool = false,
        period: Duration? = nil
    ) -> TickerFuture {
        let minValue = min ?? lowerBound
        let maxValue = max ?? upperBound
        let periodValue = period ?? duration

        assert(
            periodValue != nil,
            "AnimationController.repeat() called without an explicit period and with no default Duration.\n"
                + "Either the \"period\" argument to the repeat() method should be provided, or the "
                + "\"duration\" property should be set, either in the constructor or later, before "
                + "calling the repeat() function."
        )

        assert(maxValue >= minValue)
        assert(maxValue <= upperBound && minValue >= lowerBound)
        stop()
        return _startSimulation(
            _RepeatingSimulation(
                initialValue: _value,
                min: minValue,
                max: maxValue,
                reverse: reverse,
                period: periodValue!,
                directionSetter: _directionSetter
            )
        )
    }

    private func _directionSetter(_ direction: _AnimationDirection) {
        _direction = direction
        status = (_direction == _AnimationDirection.forward) ? .forward : .reverse
        _checkStatusChanged()
    }

    /// Drives the animation with a spring (within [lowerBound] and [upperBound])
    /// and initial velocity.
    ///
    /// If velocity is positive, the animation will complete, otherwise it will
    /// dismiss. The velocity is specified in units per second. If the
    /// [SemanticsBinding.disableAnimations] flag is set, the velocity is somewhat
    /// arbitrarily multiplied by 200.
    ///
    /// The [springDescription] parameter can be used to specify a custom
    /// [SpringType.criticallyDamped] or [SpringType.overDamped] spring with which
    /// to drive the animation. By default, a [SpringType.criticallyDamped] spring
    /// is used. See [SpringDescription.withDampingRatio] for how to create a
    /// suitable [SpringDescription].
    ///
    /// The resulting spring simulation cannot be of type [SpringType.underDamped];
    /// such a spring would oscillate rather than fling.
    ///
    /// Returns a [TickerFuture] that completes when the animation is complete.
    ///
    /// The most recently returned [TickerFuture], if any, is marked as having been
    /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
    /// derivative future completes with a [TickerCanceled] error.
    func fling(
        velocity: Double = 1.0,
        springDescription: SpringDescription? = nil,
        animationBehavior: AnimationBehavior? = nil
    ) -> TickerFuture {
        let springDesc = springDescription ?? _kFlingSpringDescription
        _direction = velocity < 0.0 ? .reverse : .forward
        let target =
            velocity < 0.0
            ? lowerBound - _kFlingTolerance.distance
            : upperBound + _kFlingTolerance.distance
        let behavior = animationBehavior ?? self.animationBehavior
        let scale =
            switch behavior {
            // // This is arbitrary (it was chosen because it worked for the drawer widget).
            // case .normal where SemanticsBinding.instance.disableAnimations:
            //     200.0
            case .normal, .preserve:
                1.0
            }
        let simulation = SpringSimulation(
            spring: springDesc,
            start: value,
            end: target,
            velocity: velocity * scale,
            tolerance: _kFlingTolerance
        )
        assert(
            simulation.type != .underDamped,
            "The specified spring simulation is of type SpringType.underDamped.\n"
                + "An underdamped spring results in oscillation rather than a fling. "
                + "Consider specifying a different springDescription, or use animateWith() "
                + "with an explicit SpringSimulation if an underdamped spring is intentional."
        )
        stop()
        return _startSimulation(simulation)
    }

    /// Drives the animation according to the given simulation.
    ///
    /// The values from the simulation are clamped to the [lowerBound] and
    /// [upperBound]. To avoid this, consider creating the [AnimationController]
    /// using the [AnimationController.unbounded] constructor.
    ///
    /// Returns a [TickerFuture] that completes when the animation is complete.
    ///
    /// The most recently returned [TickerFuture], if any, is marked as having been
    /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
    /// derivative future completes with a [TickerCanceled] error.
    ///
    /// The [status] is always [AnimationStatus.forward] for the entire duration
    /// of the simulation.
    func animateWith(_ simulation: Simulation) -> TickerFuture {
        assert(
            _ticker != nil,
            "AnimationController.animateWith() called after AnimationController.dispose()\n"
                + "AnimationController methods should not be used after calling dispose."
        )
        stop()
        _direction = .forward
        return _startSimulation(simulation)
    }
    func _startSimulation(_ simulation: Simulation) -> TickerFuture {
        assert(!isAnimating)
        _simulation = simulation
        lastElapsedDuration = .zero
        _value = simulation.x(0.0).clamped(to: lowerBound...upperBound)
        let result = _ticker!.start()
        status = (_direction == .forward) ? .forward : .reverse
        _checkStatusChanged()
        return result
    }

    /// Stops running this animation.
    ///
    /// This does not trigger any notifications. The animation stops in its
    /// current state.
    ///
    /// By default, the most recently returned [TickerFuture] is marked as having
    /// been canceled, meaning the future never completes and its
    /// [TickerFuture.orCancel] derivative future completes with a [TickerCanceled]
    /// error. By passing the `canceled` argument with the value false, this is
    /// reversed, and the futures complete successfully.
    ///
    /// See also:
    ///
    ///  * [reset], which stops the animation and resets it to the [lowerBound],
    ///    and which does send notifications.
    ///  * [forward], [reverse], [animateTo], [animateWith], [fling], and [repeat],
    ///    which restart the animation controller.
    func stop(canceled: Bool = true) {
        assert(
            _ticker != nil,
            "AnimationController.stop() called after AnimationController.dispose()\n"
                + "AnimationController methods should not be used after calling dispose."
        )
        _simulation = nil
        lastElapsedDuration = nil
        _ticker!.stop(canceled: canceled)
    }

    /// Release the resources used by this object. The object is no longer usable
    /// after this method is called.
    ///
    /// The most recently returned [TickerFuture], if any, is marked as having been
    /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
    /// derivative future completes with a [TickerCanceled] error.
    func dispose() {
        assert(
            _ticker != nil,
            "AnimationController.dispose() called more than once."
        )

        _ticker!.dispose()
        _ticker = nil
        clearStatusListeners()
        clearListeners()
    }

    private var _lastReportedStatus: AnimationStatus = .dismissed

    private func _checkStatusChanged() {
        let newStatus = status
        if _lastReportedStatus != newStatus {
            _lastReportedStatus = newStatus
            notifyStatusListeners(status: newStatus)
        }
    }

    private func _tick(_ elapsed: Duration) {
        lastElapsedDuration = elapsed
        let elapsedInSeconds =
            Double(elapsed.inMicroseconds) / Double(Duration.microsecondsPerSecond)
        assert(elapsedInSeconds >= 0.0)
        _value = _simulation!.x(elapsedInSeconds).clamped(to: lowerBound...upperBound)
        if _simulation!.isDone(elapsedInSeconds) {
            status = (_direction == .forward) ? .completed : .dismissed
            stop(canceled: false)
        }
        notifyListeners()
        _checkStatusChanged()
    }
}

extension AnimationController: CustomStringConvertible {
    public var description: String {
        let paused = isAnimating ? "" : "; paused"
        let ticker = _ticker == nil ? "; DISPOSED" : (_ticker!.muted ? "; silenced" : "")
        let label = debugLabel != nil ? "; for \(debugLabel!)" : ""
        return "AnimationController\(_value)\(paused)\(ticker)\(label)"
    }
}

private struct _InterpolationSimulation: Simulation {
    private let durationInSeconds: Double
    private let begin: Double
    private let end: Double
    private let curve: Curve

    init(begin: Double, end: Double, duration: Duration, curve: Curve, scale: Double) {
        assert(duration.inMicroseconds > 0)
        self.durationInSeconds =
            Double(duration.inMicroseconds) * scale / Double(Duration.microsecondsPerSecond)
        self.begin = begin
        self.end = end
        self.curve = curve
    }

    func x(_ timeInSeconds: Double) -> Double {
        let t = timeInSeconds / durationInSeconds.clamped(to: 0.0...1.0)
        switch t {
        case 0.0:
            return begin
        case 1.0:
            return end
        default:
            return begin + (end - begin) * curve.transform(t)
        }
    }

    func dx(_ timeInSeconds: Double) -> Double {
        let epsilon = tolerance.time
        return (x(timeInSeconds + epsilon) - x(timeInSeconds - epsilon)) / (2 * epsilon)
    }

    func isDone(_ timeInSeconds: Double) -> Bool {
        return timeInSeconds > durationInSeconds
    }

    var tolerance: Tolerance = .defaultTolerance
}

private typealias _DirectionSetter = (_AnimationDirection) -> Void

private struct _RepeatingSimulation: Simulation {
    let min: Double
    let max: Double
    let reverse: Bool
    let directionSetter: _DirectionSetter

    private let periodInSeconds: Double
    private let initialT: Double

    init(
        initialValue: Double,
        min: Double,
        max: Double,
        reverse: Bool,
        period: Duration,
        directionSetter: @escaping _DirectionSetter
    ) {
        self.min = min
        self.max = max
        self.reverse = reverse
        self.directionSetter = directionSetter

        self.periodInSeconds =
            Double(period.inMicroseconds) / Double(Duration.microsecondsPerSecond)
        self.initialT =
            (max == min)
            ? 0.0
            : ((initialValue.clamped(to: min...max) - min) / (max - min))
                * Double(period.inMicroseconds) / Double(Duration.microsecondsPerSecond)

        assert(periodInSeconds > 0.0)
        assert(initialT >= 0.0)
    }

    var tolerance: Tolerance = .defaultTolerance

    func x(_ timeInSeconds: Double) -> Double {
        assert(timeInSeconds >= 0.0)

        let totalTimeInSeconds = timeInSeconds + initialT
        let t = (totalTimeInSeconds / periodInSeconds).truncatingRemainder(dividingBy: 1.0)
        let isPlayingReverse = Int(totalTimeInSeconds / periodInSeconds).isOdd

        if reverse && isPlayingReverse {
            directionSetter(_AnimationDirection.reverse)
            return lerpDouble(max, min, t: t)
        } else {
            directionSetter(_AnimationDirection.forward)
            return lerpDouble(min, max, t: t)
        }
    }

    func dx(_ timeInSeconds: Double) -> Double {
        return (max - min) / periodInSeconds
    }

    func isDone(_ timeInSeconds: Double) -> Bool {
        return false
    }
}
