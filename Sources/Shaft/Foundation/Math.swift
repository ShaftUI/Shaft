// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

struct Math {
    /// Base of the natural logarithms.
    ///
    /// Typically written as "e".
    static let e = 2.718281828459045

    /// Natural logarithm of 10.
    ///
    /// The natural logarithm of 10 is the number such that `pow(E, LN10) == 10`.
    /// This value is not exact, but it is the closest representable double to the
    /// exact mathematical value.
    static let ln10 = 2.302585092994046

    /// Natural logarithm of 2.
    ///
    /// The natural logarithm of 2 is the number such that `pow(E, LN2) == 2`.
    /// This value is not exact, but it is the closest representable double to the
    /// exact mathematical value.
    static let ln2 = 0.6931471805599453

    /// Base-2 logarithm of ``e``.
    static let log2e = 1.4426950408889634

    /// Base-10 logarithm of ``e``.
    static let log10e = 0.4342944819032518

    /// The PI constant.
    static let pi = 3.1415926535897932

    /// Square root of 1/2.
    static let sqrt1_2 = 0.7071067811865476

    /// Square root of 2.
    static let sqrt2 = 1.4142135623730951
}

extension Comparable {
    /// Returns a value clamped to a given range.
    public func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension BinaryFloatingPoint {
    public func floor<T: BinaryInteger>() -> T {
        return T(Foundation.floor(self))
    }

    public func ceil<T: BinaryInteger>() -> T {
        return T(Foundation.ceil(self))
    }
}

extension Float {
    /// The sign of the double's numerical value.
    ///
    /// Returns -1.0 if the value is less than zero,
    /// +1.0 if the value is greater than zero,
    /// and the value itself if it is -0.0, 0.0 or NaN.
    public var signValue: Float {
        return self >= 0 ? (self > 0 ? 1 : 1) : -1
    }
}

extension Int {
    /// Returns the sign of this integer.
    ///
    /// Returns 0 for zero, -1 for values less than zero and
    /// +1 for values greater than zero.
    public var signValue: Int {
        return self >= 0 ? (self > 0 ? 1 : 1) : -1
    }

    public var isOdd: Bool {
        return !isMultiple(of: 2)
    }
}

/// Linearly interpolate between two numbers, `a` and `b`, by an extrapolation
/// factor `t`.
///
/// When `a` and `b` are equal or both NaN, `a` is returned.  Otherwise,
/// `a`, `b`, and `t` are required to be finite or null, and the result of `a +
/// (b - a) * t` is returned, where nulls are defaulted to 0.0.
internal func lerpDouble(_ a: Double, _ b: Double, t: Double) -> Double {
    if a == b || (a.isNaN && b.isNaN) {
        return a
    }
    assert(a.isFinite, "Cannot interpolate between finite and non-finite values")
    assert(b.isFinite, "Cannot interpolate between finite and non-finite values")
    assert(t.isFinite, "t must be finite when interpolating between values")
    return a * (1.0 - t) + b * t
}

/// Linearly interpolate between two floating point numbers, `a` and `b`, by an
/// extrapolation factor `t`.
internal func lerpFloat(_ a: Float, _ b: Float, t: Float) -> Float {
    if a == b || (a.isNaN && b.isNaN) {
        return a
    }
    assert(a.isFinite, "Cannot interpolate between finite and non-finite values")
    assert(b.isFinite, "Cannot interpolate between finite and non-finite values")
    assert(t.isFinite, "t must be finite when interpolating between values")
    return a * (1.0 - t) + b * t
}

/// Linearly interpolate between two integers.
///
/// Same as ``lerpDouble`` but specialized for non-null `int` type.
internal func lerpInt<T: FixedWidthInteger>(_ a: T, _ b: T, t: Float) -> Float {
    return Float(a) + Float(b - a) * t
}

/// Same as ``num/clamp`` but specialized for non-null ``int``.
internal func clampInt<T: FixedWidthInteger>(_ value: T, _ min: T, _ max: T) -> T {
    assert(min <= max)
    if value < min {
        return min
    } else if value > max {
        return max
    } else {
        return value
    }
}

internal func ceilToInt(_ value: Float) -> Int {
    return value.ceil()
}
