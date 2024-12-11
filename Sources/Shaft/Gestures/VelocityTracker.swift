// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A velocity in two dimensions.
public struct Velocity: Equatable {
    /// Creates a [Velocity].
    public init(pixelsPerSecond: Offset) {
        self.pixelsPerSecond = pixelsPerSecond
    }

    /// A velocity that isn't moving at all.
    public static let zero = Velocity(pixelsPerSecond: .zero)

    /// The number of pixels per second of velocity in the x and y directions.
    public let pixelsPerSecond: Offset

    /// Return the negation of a velocity.
    public static prefix func - (velocity: Velocity) -> Velocity {
        return Velocity(
            pixelsPerSecond: -velocity.pixelsPerSecond
        )
    }

    /// Return the difference of two velocities.
    public static func - (lhs: Velocity, rhs: Velocity) -> Velocity {
        return Velocity(
            pixelsPerSecond: lhs.pixelsPerSecond - rhs.pixelsPerSecond
        )
    }

    /// Return the sum of two velocities.
    public static func + (lhs: Velocity, rhs: Velocity) -> Velocity {
        return Velocity(
            pixelsPerSecond: lhs.pixelsPerSecond + rhs.pixelsPerSecond
        )
    }

    /// Return a velocity whose magnitude has been clamped to [minValue]
    /// and [maxValue].
    ///
    /// If the magnitude of this Velocity is less than minValue then return a new
    /// Velocity with the same direction and with magnitude [minValue]. Similarly,
    /// if the magnitude of this Velocity is greater than maxValue then return a
    /// new Velocity with the same direction and magnitude [maxValue].
    ///
    /// If the magnitude of this Velocity is within the specified bounds then
    /// just return this.
    public func clampMagnitude(minValue: Float, maxValue: Float) -> Velocity {
        assert(minValue >= 0.0)
        assert(maxValue >= 0.0 && maxValue >= minValue)
        let valueSquared = pixelsPerSecond.distanceSquared
        if valueSquared > maxValue * maxValue {
            return Velocity(
                pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * maxValue
            )
        }
        if valueSquared < minValue * minValue {
            return Velocity(
                pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * minValue
            )
        }
        return self
    }

    public static func == (lhs: Velocity, rhs: Velocity) -> Bool {
        return lhs.pixelsPerSecond == rhs.pixelsPerSecond
    }

    public var description: String {
        return "Velocity(\(pixelsPerSecond.dx), \(pixelsPerSecond.dy))"
    }
}

/// A two dimensional velocity estimate.
///
/// VelocityEstimates are computed by VelocityTracker.getVelocityEstimate. An
/// estimate's confidence measures how well the velocity tracker's position
/// data fit a straight line, duration is the time that elapsed between the
/// first and last position sample used to compute the velocity, and offset
/// is similarly the difference between the first and last positions.
///
/// See also:
///
///  * VelocityTracker, which computes VelocityEstimates.
///  * Velocity, which encapsulates (just) a velocity vector and provides some
///    useful velocity operations.
public struct VelocityEstimate {
    /// Creates a dimensional velocity estimate.
    public init(pixelsPerSecond: Offset, confidence: Double, duration: Duration, offset: Offset) {
        self.pixelsPerSecond = pixelsPerSecond
        self.confidence = confidence
        self.duration = duration
        self.offset = offset
    }

    /// The number of pixels per second of velocity in the x and y directions.
    public let pixelsPerSecond: Offset

    /// A value between 0.0 and 1.0 that indicates how well VelocityTracker
    /// was able to fit a straight line to its position data.
    ///
    /// The value of this property is 1.0 for a perfect fit, 0.0 for a poor fit.
    public let confidence: Double

    /// The time that elapsed between the first and last position sample used
    /// to compute pixelsPerSecond.
    public let duration: Duration

    /// The difference between the first and last position sample used
    /// to compute pixelsPerSecond.
    public let offset: Offset
}

/// A point in time and its associated position.
///
/// This struct represents a position at a specific point in time, used by the
/// `VelocityTracker` to compute velocity estimates.
private struct PointAtTime {
    /// The time at which the position was recorded.
    let time: Duration

    /// The position at the recorded time.
    let point: Offset
}

/// Computes a pointer's velocity based on data from [PointerMoveEvent]s.
///
/// The input data is provided by calling [addPosition]. Adding data is cheap.
///
/// To obtain a velocity, call [getVelocity] or [getVelocityEstimate]. This will
/// compute the velocity based on the data added so far. Only call these when
/// you need to use the velocity, as they are comparatively expensive.
///
/// The quality of the velocity estimation will be better if more data points
/// have been received.
public class VelocityTracker {
    /// Create a new velocity tracker for a pointer kind.
    public init(kind: PointerDeviceKind) {
        self.kind = kind
    }

    static private let assumePointerMoveStoppedMilliseconds = 40
    static private let historySize = 20
    static private let horizonMilliseconds = 100
    static private let minSampleSize = 3

    /// The kind of pointer this tracker is for.
    let kind: PointerDeviceKind

    // Time difference since the last sample was added
    lazy var sinceLastSample: Stopwatch = {
        return GestureBinding.shared.samplingClock.stopwatch()
    }()

    // Circular buffer; current sample at _index.
    private var samples: [PointAtTime?] = Array(repeating: nil, count: historySize)
    private var index = 0

    /// Adds a position as the given time to the tracker.
    public func addPosition(_ time: Duration, _ position: Offset) {
        sinceLastSample.start()
        sinceLastSample.reset()
        index += 1
        if index == Self.historySize {
            index = 0
        }
        samples[index] = PointAtTime(time: time, point: position)
    }

    /// Returns an estimate of the velocity of the object being tracked by the
    /// tracker given the current information available to the tracker.
    ///
    /// Information is added using [addPosition].
    ///
    /// Returns nil if there is no data on which to base an estimate.
    public func getVelocityEstimate() -> VelocityEstimate? {
        // Has user recently moved since last sample?
        if sinceLastSample.elapsedMilliseconds
            > Self.assumePointerMoveStoppedMilliseconds
        {
            mark(sinceLastSample.elapsedMilliseconds)

            return VelocityEstimate(
                pixelsPerSecond: .zero,
                confidence: 1.0,
                duration: .zero,
                offset: .zero
            )
        }

        var x: [Double] = []
        var y: [Double] = []
        var w: [Double] = []
        var time: [Double] = []
        var sampleCount = 0
        var currentIndex = index

        guard let newestSample = samples[currentIndex] else {
            return nil
        }

        var previousSample = newestSample
        var oldestSample = newestSample

        // Starting with the most recent PointAtTime sample, iterate backwards while
        // the samples represent continuous motion.
        repeat {
            guard let sample = samples[currentIndex] else {
                break
            }

            let age = Double((newestSample.time - sample.time).inMicroseconds) / 1000.0
            let delta =
                Double((sample.time - previousSample.time).inMicroseconds).magnitude / 1000.0
            previousSample = sample
            if age > Double(Self.horizonMilliseconds)
                || delta > Double(Self.assumePointerMoveStoppedMilliseconds)
            {
                break
            }

            oldestSample = sample
            let position = sample.point
            x.append(Double(position.dx))
            y.append(Double(position.dy))
            w.append(1.0)
            time.append(-age)
            currentIndex = (currentIndex == 0 ? Self.historySize : currentIndex) - 1

            sampleCount += 1
        } while sampleCount < Self.historySize

        if sampleCount >= Self.minSampleSize {
            let xSolver = LeastSquaresSolver(x: time, y: x, w: w)
            if let xFit = xSolver.solve(degree: 2) {
                let ySolver = LeastSquaresSolver(x: time, y: y, w: w)
                if let yFit = ySolver.solve(degree: 2) {
                    return VelocityEstimate(  // convert from pixels/ms to pixels/s
                        pixelsPerSecond: Offset(
                            Float(xFit.coefficients[1]) * 1000,
                            Float(yFit.coefficients[1]) * 1000
                        ),
                        confidence: xFit.confidence * yFit.confidence,
                        duration: newestSample.time - oldestSample.time,
                        offset: newestSample.point - oldestSample.point
                    )
                }
            }
        }

        // We're unable to make a velocity estimate but we did have at least one
        // valid pointer position.
        return VelocityEstimate(
            pixelsPerSecond: .zero,
            confidence: 1.0,
            duration: newestSample.time - oldestSample.time,
            offset: newestSample.point - oldestSample.point
        )
    }

    /// Computes the velocity of the pointer at the time of the last
    /// provided data point.
    ///
    /// This can be expensive. Only call this when you need the velocity.
    ///
    /// Returns [Velocity.zero] if there is no data from which to compute an
    /// estimate or if the estimated velocity is zero.
    public func getVelocity() -> Velocity {
        guard let estimate = getVelocityEstimate(), estimate.pixelsPerSecond != .zero else {
            return .zero
        }
        return Velocity(pixelsPerSecond: estimate.pixelsPerSecond)
    }
}

// /// A [VelocityTracker] subclass that provides a close approximation of iOS
// /// scroll view's velocity estimation strategy.
// ///
// /// The estimated velocity reported by this class is a close approximation of
// /// the velocity an iOS scroll view would report with the same
// /// [PointerMoveEvent]s, when the touch that initiates a fling is released.
// ///
// /// This class differs from the [VelocityTracker] class in that it uses weighted
// /// average of the latest few velocity samples of the tracked pointer, instead
// /// of doing a linear regression on a relatively large amount of data points, to
// /// estimate the velocity of the tracked pointer. Adding data points and
// /// estimating the velocity are both cheap.
// ///
// /// To obtain a velocity, call [getVelocity] or [getVelocityEstimate]. The
// /// estimated velocity is typically used as the initial flinging velocity of a
// /// `Scrollable`, when its drag gesture ends.
// ///
// /// See also:
// ///
// /// * [scrollViewWillEndDragging(_:withVelocity:targetContentOffset:)](https://developer.apple.com/documentation/uikit/uiscrollviewdelegate/1619385-scrollviewwillenddragging),
// ///   the iOS method that reports the fling velocity when the touch is released.
// class IOSScrollViewFlingVelocityTracker extends VelocityTracker {
//   /// Create a new IOSScrollViewFlingVelocityTracker.
//   IOSScrollViewFlingVelocityTracker(super.kind) : super.withKind();

//   /// The velocity estimation uses at most 4 `PointAtTime` samples. The extra
//   /// samples are there to make the `VelocityEstimate.offset` sufficiently large
//   /// to be recognized as a fling. See
//   /// `VerticalDragGestureRecognizer.isFlingGesture`.
//   static const int _sampleSize = 20;

//   final List<PointAtTime?> _touchSamples = List<PointAtTime?>.filled(_sampleSize, null);

//   @override
//   void addPosition(Duration time, Offset position) {
//     _sinceLastSample.start();
//     _sinceLastSample.reset();
//     assert(() {
//       final PointAtTime? previousPoint = _touchSamples[_index];
//       if (previousPoint == null || previousPoint.time <= time) {
//         return true;
//       }
//       throw FlutterError(
//         'The position being added ($position) has a smaller timestamp ($time) '
//         'than its predecessor: $previousPoint.',
//       );
//     }());
//     _index = (_index + 1) % _sampleSize;
//     _touchSamples[_index] = PointAtTime(position, time);
//   }

//   // Computes the velocity using 2 adjacent points in history. When index = 0,
//   // it uses the latest point recorded and the point recorded immediately before
//   // it. The smaller index is, the earlier in history the points used are.
//   Offset _previousVelocityAt(int index) {
//     final int endIndex = (_index + index) % _sampleSize;
//     final int startIndex = (_index + index - 1) % _sampleSize;
//     final PointAtTime? end = _touchSamples[endIndex];
//     final PointAtTime? start = _touchSamples[startIndex];

//     if (end == null || start == null) {
//       return Offset.zero;
//     }

//     final int dt = (end.time - start.time).inMicroseconds;
//     assert(dt >= 0);

//     return dt > 0
//       // Convert dt to milliseconds to preserve floating point precision.
//       ? (end.point - start.point) * 1000 / (dt.toDouble() / 1000)
//       : Offset.zero;
//   }

//   @override
//   VelocityEstimate getVelocityEstimate() {
//     // Has user recently moved since last sample?
//     if (_sinceLastSample.elapsedMilliseconds > VelocityTracker._assumePointerMoveStoppedMilliseconds) {
//       return const VelocityEstimate(
//         pixelsPerSecond: Offset.zero,
//         confidence: 1.0,
//         duration: Duration.zero,
//         offset: Offset.zero,
//       );
//     }

//     // The velocity estimated using this expression is an approximation of the
//     // scroll velocity of an iOS scroll view at the moment the user touch was
//     // released, not the final velocity of the iOS pan gesture recognizer
//     // installed on the scroll view would report. Typically in an iOS scroll
//     // view the velocity values are different between the two, because the
//     // scroll view usually slows down when the touch is released.
//     final Offset estimatedVelocity = _previousVelocityAt(-2) * 0.6
//                                    + _previousVelocityAt(-1) * 0.35
//                                    + _previousVelocityAt(0) * 0.05;

//     final PointAtTime? newestSample = _touchSamples[_index];
//     PointAtTime? oldestNonNullSample;

//     for (int i = 1; i <= _sampleSize; i += 1) {
//       oldestNonNullSample = _touchSamples[(_index + i) % _sampleSize];
//       if (oldestNonNullSample != null) {
//         break;
//       }
//     }

//     if (oldestNonNullSample == null || newestSample == null) {
//       assert(false, 'There must be at least 1 point in _touchSamples: $_touchSamples');
//       return const VelocityEstimate(
//         pixelsPerSecond: Offset.zero,
//         confidence: 0.0,
//         duration: Duration.zero,
//         offset: Offset.zero,
//       );
//     } else {
//       return VelocityEstimate(
//         pixelsPerSecond: estimatedVelocity,
//         confidence: 1.0,
//         duration: newestSample.time - oldestNonNullSample.time,
//         offset: newestSample.point - oldestNonNullSample.point,
//       );
//     }
//   }
// }

// /// A [VelocityTracker] subclass that provides a close approximation of macOS
// /// scroll view's velocity estimation strategy.
// ///
// /// The estimated velocity reported by this class is a close approximation of
// /// the velocity a macOS scroll view would report with the same
// /// [PointerMoveEvent]s, when the touch that initiates a fling is released.
// ///
// /// This class differs from the [VelocityTracker] class in that it uses weighted
// /// average of the latest few velocity samples of the tracked pointer, instead
// /// of doing a linear regression on a relatively large amount of data points, to
// /// estimate the velocity of the tracked pointer. Adding data points and
// /// estimating the velocity are both cheap.
// ///
// /// To obtain a velocity, call [getVelocity] or [getVelocityEstimate]. The
// /// estimated velocity is typically used as the initial flinging velocity of a
// /// `Scrollable`, when its drag gesture ends.
// class MacOSScrollViewFlingVelocityTracker extends IOSScrollViewFlingVelocityTracker {
//   /// Create a new MacOSScrollViewFlingVelocityTracker.
//   MacOSScrollViewFlingVelocityTracker(super.kind);

//   @override
//   VelocityEstimate getVelocityEstimate() {
//     // Has user recently moved since last sample?
//     if (_sinceLastSample.elapsedMilliseconds > VelocityTracker._assumePointerMoveStoppedMilliseconds) {
//       return const VelocityEstimate(
//         pixelsPerSecond: Offset.zero,
//         confidence: 1.0,
//         duration: Duration.zero,
//         offset: Offset.zero,
//       );
//     }

//     // The velocity estimated using this expression is an approximation of the
//     // scroll velocity of a macOS scroll view at the moment the user touch was
//     // released.
//     final Offset estimatedVelocity = _previousVelocityAt(-2) * 0.15
//                                    + _previousVelocityAt(-1) * 0.65
//                                    + _previousVelocityAt(0) * 0.2;

//     final PointAtTime? newestSample = _touchSamples[_index];
//     PointAtTime? oldestNonNullSample;

//     for (int i = 1; i <= IOSScrollViewFlingVelocityTracker._sampleSize; i += 1) {
//       oldestNonNullSample = _touchSamples[(_index + i) % IOSScrollViewFlingVelocityTracker._sampleSize];
//       if (oldestNonNullSample != null) {
//         break;
//       }
//     }

//     if (oldestNonNullSample == null || newestSample == null) {
//       assert(false, 'There must be at least 1 point in _touchSamples: $_touchSamples');
//       return const VelocityEstimate(
//         pixelsPerSecond: Offset.zero,
//         confidence: 0.0,
//         duration: Duration.zero,
//         offset: Offset.zero,
//       );
//     } else {
//       return VelocityEstimate(
//         pixelsPerSecond: estimatedVelocity,
//         confidence: 1.0,
//         duration: newestSample.time - oldestNonNullSample.time,
//         offset: newestSample.point - oldestNonNullSample.point,
//       );
//     }
//   }
// }
