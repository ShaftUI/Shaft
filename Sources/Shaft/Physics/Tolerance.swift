/// Structure that specifies maximum allowable magnitudes for distances,
/// durations, and velocity differences to be considered equal.
public struct Tolerance: Hashable {
    /// Creates a Tolerance object. By default, the distance, time, and velocity
    /// tolerances are all ±0.001; the constructor arguments override this.
    ///
    /// The arguments should all be positive values.
    public init(
        distance: Double = _epsilonDefault,
        time: Double = _epsilonDefault,
        velocity: Double = _epsilonDefault
    ) {
        self.distance = distance
        self.time = time
        self.velocity = velocity
    }

    public static let _epsilonDefault: Double = 1e-3

    /// A default tolerance of 0.001 for all three values.
    public static let defaultTolerance = Tolerance()

    /// The magnitude of the maximum distance between two points for them to be
    /// considered within tolerance.
    ///
    /// The units for the distance tolerance must be the same as the units used
    /// for the distances that are to be compared to this tolerance.
    public let distance: Double

    /// The magnitude of the maximum duration between two times for them to be
    /// considered within tolerance.
    ///
    /// The units for the time tolerance must be the same as the units used
    /// for the times that are to be compared to this tolerance.
    public let time: Double

    /// The magnitude of the maximum difference between two velocities for them to
    /// be considered within tolerance.
    ///
    /// The units for the velocity tolerance must be the same as the units used
    /// for the velocities that are to be compared to this tolerance.
    public let velocity: Double

}

extension Tolerance: CustomStringConvertible {
    public var description: String {
        "Tolerance(distance: \(distance), time: \(time), velocity: \(velocity))"
    }
}
