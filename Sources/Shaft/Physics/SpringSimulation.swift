import Foundation

/// Structure that describes a spring's constants.
///
/// Used to configure a ``SpringSimulation``.
public struct SpringDescription {
    /// Creates a spring given the mass, stiffness, and the damping coefficient.
    ///
    /// See ``mass``, ``stiffness``, and ``damping`` for the units of the arguments.
    public init(mass: Double, stiffness: Double, damping: Double) {
        self.mass = mass
        self.stiffness = stiffness
        self.damping = damping
    }

    /// Creates a spring given the mass (m), stiffness (k), and damping ratio (ζ).
    /// The damping ratio describes a gradual reduction in a spring oscillation.
    /// By using the damping ratio, you can define how rapidly the oscillations
    /// decay from one bounce to the next.
    ///
    /// The damping ratio is especially useful when trying to determining the type
    /// of spring to create. A ratio of 1.0 creates a critically damped
    /// spring, > 1.0 creates an overdamped spring and < 1.0 an underdamped one.
    ///
    /// See ``mass`` and ``stiffness`` for the units for those arguments. The damping
    /// ratio is unitless.
    public static func withDampingRatio(mass: Double, stiffness: Double, ratio: Double = 1.0)
        -> SpringDescription
    {
        return SpringDescription(
            mass: mass,
            stiffness: stiffness,
            damping: ratio * 2.0 * (mass * stiffness).squareRoot()
        )
    }

    /// The mass of the spring (m).
    ///
    /// The units are arbitrary, but all springs within a system should use
    /// the same mass units.
    ///
    /// The greater the mass, the larger the amplitude of oscillation,
    /// and the longer the time to return to the equilibrium position.
    public let mass: Double

    /// The spring constant (k).
    ///
    /// The units of stiffness are M/T², where M is the mass unit used for the
    /// value of the ``mass`` property, and T is the time unit used for driving
    /// the ``SpringSimulation``.
    ///
    /// Stiffness defines the spring constant, which measures the strength of
    /// the spring. A stiff spring applies more force to the object that is
    /// attached for some deviation from the rest position.
    public let stiffness: Double

    /// The damping coefficient (c).
    ///
    /// It is a pure number without physical meaning and describes the oscillation
    /// and decay of a system after being disturbed. The larger the damping,
    /// the fewer oscillations and smaller the amplitude of the elastic motion.
    ///
    /// Do not confuse the damping _coefficient_ (c) with the damping _ratio_ (ζ).
    /// To create a ``SpringDescription`` with a damping ratio, use the [
    /// SpringDescription.withDampingRatio] constructor.
    ///
    /// The units of the damping coefficient are M/T, where M is the mass unit
    /// used for the value of the ``mass`` property, and T is the time unit used for
    /// driving the ``SpringSimulation``.
    public let damping: Double
}

/// The kind of spring solution that the ``SpringSimulation`` is using to simulate the spring.
///
/// See ``SpringSimulation/type``.
public enum SpringType {
    /// A spring that does not bounce and returns to its rest position in the
    /// shortest possible time.
    case criticallyDamped

    /// A spring that bounces.
    case underDamped

    /// A spring that does not bounce but takes longer to return to its rest
    /// position than a ``criticallyDamped`` one.
    case overDamped
}

/// A spring simulation.
///
/// Models a particle attached to a spring that follows Hooke's law.
///
/// This ``AnimationController`` could be used with an ``AnimatedBuilder`` to
/// animate the position of a child as if it were attached to a spring.
public struct SpringSimulation: Simulation {
    /// Creates a spring simulation from the provided spring description, start
    /// distance, end distance, and initial velocity.
    ///
    /// The units for the start and end distance arguments are arbitrary, but must
    /// be consistent with the units used for other lengths in the system.
    ///
    /// The units for the velocity are L/T, where L is the aforementioned
    /// arbitrary unit of length, and T is the time unit used for driving the
    /// ``SpringSimulation``.
    public init(
        spring: SpringDescription,
        start: Double,
        end: Double,
        velocity: Double,
        tolerance: Tolerance = .defaultTolerance
    ) {
        self.tolerance = tolerance
        self._endPosition = end
        self._solution = _createSpringSolution(
            spring: spring,
            initialPosition: start - end,
            initialVelocity: velocity
        )
    }

    private let _endPosition: Double
    private let _solution: _SpringSolution

    /// The kind of spring being simulated, for debugging purposes.
    ///
    /// This is derived from the ``SpringDescription`` provided to the [
    /// SpringSimulation] constructor.
    public var type: SpringType { _solution.type }

    public var tolerance: Tolerance

    public func x(_ time: Double) -> Double {
        return _endPosition + _solution.x(time)
    }

    public func dx(_ time: Double) -> Double {
        return _solution.dx(time)
    }

    public func isDone(_ time: Double) -> Bool {
        return nearZero(_solution.x(time), tolerance.distance)
            && nearZero(_solution.dx(time), tolerance.velocity)
    }
}

// /// A ``SpringSimulation`` where the value of ``x`` is guaranteed to have exactly the
// /// end value when the simulation ``isDone``.
// class ScrollSpringSimulation: SpringSimulation {
//     /// Creates a spring simulation from the provided spring description, start
//     /// distance, end distance, and initial velocity.
//     ///
//     /// See the ``SpringSimulation/new`` constructor on the superclass for a
//     /// discussion of the arguments' units.
//     init(
//         spring: SpringDescription,
//         start: Double,
//         end: Double,
//         velocity: Double,
//         tolerance: Tolerance? = nil
//     ) {
//         super.init(spring: spring, start: start, end: end, velocity: velocity, tolerance: tolerance)
//     }

//     override func x(_ time: Double) -> Double {
//         return isDone(time) ? _endPosition : super.x(time)
//     }
// }

// MARK: - SPRING IMPLEMENTATIONS

private protocol _SpringSolution {
    func x(_ time: Double) -> Double

    func dx(_ time: Double) -> Double

    var type: SpringType { get }
}

private func _createSpringSolution(
    spring: SpringDescription,
    initialPosition: Double,
    initialVelocity: Double
) -> _SpringSolution {
    return switch spring.damping * spring.damping - 4 * spring.mass * spring.stiffness {
    case let cmk where cmk > 0.0:
        _OverdampedSolution(spring: spring, distance: initialPosition, velocity: initialVelocity)
    case let cmk where cmk < 0.0:
        _UnderdampedSolution(spring: spring, distance: initialPosition, velocity: initialVelocity)
    default:
        _CriticalSolution(spring: spring, distance: initialPosition, velocity: initialVelocity)
    }
}

private struct _CriticalSolution: _SpringSolution {
    init(spring: SpringDescription, distance: Double, velocity: Double) {
        let r = -spring.damping / (2.0 * spring.mass)
        let c1 = distance
        let c2 = velocity - (r * distance)
        self.init(r: r, c1: c1, c2: c2)
    }

    init(r: Double, c1: Double, c2: Double) {
        self._r = r
        self._c1 = c1
        self._c2 = c2
    }

    private let _r: Double
    private let _c1: Double
    private let _c2: Double

    func x(_ time: Double) -> Double {
        return (_c1 + _c2 * time) * pow(Math.e, _r * time)
    }

    func dx(_ time: Double) -> Double {
        let power = pow(Math.e, _r * time)
        return _r * (_c1 + _c2 * time) * power + _c2 * power
    }

    var type: SpringType { .criticallyDamped }
}

private struct _OverdampedSolution: _SpringSolution {
    init(spring: SpringDescription, distance: Double, velocity: Double) {
        let cmk = spring.damping * spring.damping - 4 * spring.mass * spring.stiffness
        let r1 = (-spring.damping - sqrt(cmk)) / (2.0 * spring.mass)
        let r2 = (-spring.damping + sqrt(cmk)) / (2.0 * spring.mass)
        let c2 = (velocity - r1 * distance) / (r2 - r1)
        let c1 = distance - c2
        self.init(r1: r1, r2: r2, c1: c1, c2: c2)
    }

    init(r1: Double, r2: Double, c1: Double, c2: Double) {
        self._r1 = r1
        self._r2 = r2
        self._c1 = c1
        self._c2 = c2
    }

    private let _r1: Double
    private let _r2: Double
    private let _c1: Double
    private let _c2: Double

    func x(_ time: Double) -> Double {
        return _c1 * pow(Math.e, _r1 * time) + _c2 * pow(Math.e, _r2 * time)
    }

    func dx(_ time: Double) -> Double {
        return _c1 * _r1 * pow(Math.e, _r1 * time) + _c2 * _r2 * pow(Math.e, _r2 * time)
    }

    var type: SpringType { .overDamped }
}

private struct _UnderdampedSolution: _SpringSolution {
    init(spring: SpringDescription, distance: Double, velocity: Double) {
        let w =
            sqrt(4.0 * spring.mass * spring.stiffness - spring.damping * spring.damping)
            / (2.0 * spring.mass)
        let r = -(spring.damping / 2.0 * spring.mass)
        let c1 = distance
        let c2 = (velocity - r * distance) / w
        self.init(w: w, r: r, c1: c1, c2: c2)
    }

    init(w: Double, r: Double, c1: Double, c2: Double) {
        self._w = w
        self._r = r
        self._c1 = c1
        self._c2 = c2
    }

    private let _w: Double
    private let _r: Double
    private let _c1: Double
    private let _c2: Double

    func x(_ time: Double) -> Double {
        return pow(Math.e, _r * time) * (_c1 * cos(_w * time) + _c2 * sin(_w * time))
    }

    func dx(_ time: Double) -> Double {
        let power = pow(Math.e, _r * time)
        let cosine = cos(_w * time)
        let sine = sin(_w * time)
        return power * (_c2 * _w * cosine - _c1 * _w * sine) + _r * power
            * (_c2 * sine + _c1 * cosine)
    }

    var type: SpringType { .underDamped }
}
