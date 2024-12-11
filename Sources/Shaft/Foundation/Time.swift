// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extension Duration {
    /// Returns the duration in milliseconds.
    var inMilliseconds: Int64 {
        return Int64(
            self.components.seconds * 1000 + self.components.attoseconds / 1_000_000_000_000_000
        )
    }

    /// Returns the duration in microseconds.
    var inMicroseconds: Int64 {
        return Int64(
            self.components.seconds * 1_000_000 + self.components.attoseconds / 1_000_000_000_000
        )
    }

    /// The number of microseconds per millisecond.
    static var microsecondsPerMillisecond = 1000

    /// The number of milliseconds per second.
    static var millisecondsPerSecond = 1000

    /// The number of seconds per minute.
    ///
    /// Notice that some minutes of official clock time might
    /// differ in length because of leap seconds.
    /// The [Duration] and [DateTime] classes ignore leap seconds
    /// and consider all minutes to have 60 seconds.
    static var secondsPerMinute = 60

    /// The number of minutes per hour.
    static var minutesPerHour = 60

    /// The number of hours per day.
    ///
    /// Notice that some days may differ in length because
    /// of time zone changes due to daylight saving.
    /// The [Duration] class is time zone agnostic and
    /// considers all days to have 24 hours.
    static var hoursPerDay = 24

    static var microsecondsPerSecond: Int64 {
        return 1_000_000
    }
}
