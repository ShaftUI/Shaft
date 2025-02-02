// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// public protocol Curve {
//     func transform(_ t: Double) -> Double
// }

/// An abstract class providing an interface for evaluating a parametric curve.
///
/// A parametric curve transforms a parameter (hence the name) `t` along a curve
/// to the value of the curve at that value of `t`. The curve can be of
/// arbitrary dimension, but is typically a 1D, 2D, or 3D curve.
///
/// See also:
///
///  * [Curve], a 1D animation easing curve that starts at 0.0 and ends at 1.0.
///  * [Curve2D], a parametric curve that transforms the parameter to a 2D point.
open class ParametricCurve<T> {
    /// Returns the value of the curve at point `t`.
    ///
    /// This method asserts that t is between 0 and 1 before delegating to
    /// [transformInternal].
    ///
    /// It is recommended that subclasses override [transformInternal] instead of
    /// this function, as the above case is already handled in the default
    /// implementation of [transform], which delegates the remaining logic to
    /// [transformInternal].
    public func transform(_ t: Double) -> T {
        assert(t >= 0.0 && t <= 1.0, "parametric value \(t) is outside of [0, 1] range.")
        return transformInternal(t)
    }

    /// Returns the value of the curve at point `t`.
    ///
    /// The given parametric value `t` will be between 0.0 and 1.0, inclusive.
    open func transformInternal(_ t: Double) -> T {
        shouldImplement()
    }
}

/// An parametric animation easing curve, i.e. a mapping of the unit interval to
/// the unit interval.
///
/// Easing curves are used to adjust the rate of change of an animation over
/// time, allowing them to speed up and slow down, rather than moving at a
/// constant rate.
///
/// A [Curve] must map t=0.0 to 0.0 and t=1.0 to 1.0.
///
/// See also:
///
///  * [Curves], a collection of common animation easing curves.
///  * [CurveTween], which can be used to apply a [Curve] to an [Animation].
///  * [Canvas.drawArc], which draws an arc, and has nothing to do with easing
///    curves.
///  * [Animatable], for a more flexible interface that maps fractions to
///    arbitrary values.
open class Curve: ParametricCurve<Double> {
    /// Returns the value of the curve at point `t`.
    ///
    /// This function must ensure the following:
    /// - The value of `t` must be between 0.0 and 1.0
    /// - Values of `t`=0.0 and `t`=1.0 must be mapped to 0.0 and 1.0,
    /// respectively.
    ///
    /// It is recommended that subclasses override [transformInternal] instead of
    /// this function, as the above cases are already handled in the default
    /// implementation of [transform], which delegates the remaining logic to
    /// [transformInternal].
    public override func transform(_ t: Double) -> Double {
        if t == 0.0 || t == 1.0 {
            return t
        }
        return super.transform(t)
    }
}

/// The identity map over the unit interval.
///
/// See [Curves.linear] for an instance of this class.
class _Linear: Curve {
    override func transformInternal(_ t: Double) -> Double {
        return t
    }
}

public struct Curves {
    /// A linear animation curve.
    ///
    /// This is the identity map over the unit interval: its [Curve.transform]
    /// method returns its input unmodified. This is useful as a default curve for
    /// cases where a [Curve] is required but no actual curve is desired.
    ///
    /// {@animation 464 192 https://flutter.github.io/assets-for-api-docs/assets/animation/curve_linear.mp4}
    public static let linear: Curve = _Linear()
}
