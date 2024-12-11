// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A stopwatch which measures time while it's running.
///
/// A stopwatch is either running or stopped.
/// It measures the elapsed time that passes while the stopwatch is running.
///
/// When a stopwatch is initially created, it is stopped and has measured no
/// elapsed time.
///
/// The elapsed time can be accessed in various formats using
/// `elapsed`, `elapsedMilliseconds`, `elapsedMicroseconds` or `elapsedTicks`.
///
/// The stopwatch is started by calling `start`.
///
/// Example:
///
/// let stopwatch = Stopwatch.continuous
/// print(stopwatch.elapsedMilliseconds) // 0
/// print(stopwatch.isRunning) // false
/// stopwatch.start()
/// print(stopwatch.isRunning) // true
///
/// To stop or pause the stopwatch, use `stop`.
/// Use `start` to continue again when only pausing temporarily.
///
/// stopwatch.stop()
/// print(stopwatch.isRunning) // false
/// let elapsed = stopwatch.elapsed
/// DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
///     assert(stopwatch.elapsed == elapsed) // No measured time elapsed.
///     stopwatch.start() // Continue measuring.
/// }
///
/// The `reset` method sets the elapsed time back to zero.
/// It can be called whether the stopwatch is running or not,
/// and doesn't change whether it's running.
///
/// // Do some work.
/// stopwatch.stop()
/// print(stopwatch.elapsedMilliseconds) // Likely > 0.
/// stopwatch.reset()
/// print(stopwatch.elapsedMilliseconds) // 0
///
public protocol Stopwatch {
    /// Starts the `Stopwatch`.
    ///
    /// The `elapsed` count increases monotonically. If the `Stopwatch` has
    /// been stopped, then calling start again restarts it without resetting the
    /// `elapsed` count.
    ///
    /// If the `Stopwatch` is currently running, then calling start does nothing.
    mutating func start()

    /// Stops the `Stopwatch`.
    ///
    /// The `elapsedTicks` count stops increasing after this call. If the
    /// `Stopwatch` is currently not running, then calling this method has no
    /// effect.
    mutating func stop()

    /// Resets the `elapsed` count to zero.
    ///
    /// This method does not stop or start the `Stopwatch`.
    mutating func reset()

    /// The `elapsedTicks` counter converted to a `TimeInterval`.
    var elapsed: Duration { get }

    /// The `elapsedTicks` counter converted to microseconds.
    var elapsedMicroseconds: Int { get }

    /// The `elapsedTicks` counter converted to milliseconds.
    var elapsedMilliseconds: Int { get }

    /// Whether the `Stopwatch` is currently running.
    var isRunning: Bool { get }
}

extension Stopwatch {
    public var elapsedMicroseconds: Int {
        Int(elapsed.inMicroseconds)
    }

    public var elapsedMilliseconds: Int {
        Int(elapsed.inMilliseconds)
    }
}

public struct ClockStopwatch<ClockType: Clock>: Stopwatch
where ClockType.Instant.Duration == Duration {
    public let clock: ClockType

    /// Initializes a new `Stopwatch` instance with the specified `Clock`.
    ///
    /// The `Clock` is used to measure the elapsed time when the stopwatch is running.
    public init(clock: ClockType) {
        self.clock = clock
    }

    // The start and stop fields capture the time when `start` and `stop`
    // are called respectively.
    private var startInstant: ClockType.Instant?
    private var stopInstant: ClockType.Instant?

    public mutating func start() {
        startInstant = clock.now
        stopInstant = nil
    }

    public mutating func stop() {
        stopInstant = stopInstant ?? clock.now
    }

    public mutating func reset() {
        startInstant = clock.now
        stopInstant = nil
    }

    public var elapsed: Duration {
        if let startInstant {
            if let stopInstant {
                return startInstant.duration(to: stopInstant)
            } else {
                return startInstant.duration(to: clock.now)
            }
        } else {
            return Duration.zero
        }
    }

    public var isRunning: Bool {
        return startInstant != nil && stopInstant == nil
    }
}
