/// A typedef used by [Animatable.fromCallback] to create an [Animatable]
/// from a callback.
public typealias AnimatableCallback<T> = (Double) -> T

/// An object that can produce a value of type `T` given an [Animation<double>]
/// as input.
///
/// Typically, the values of the input animation are nominally in the range 0.0
/// to 1.0. In principle, however, any value could be provided.
///
/// The main subclass of [Animatable] is [Tween].
public protocol Animatable<Value> {
    associatedtype Value

    /// Returns the value of the object at point `t`.
    ///
    /// The value of `t` is nominally a fraction in the range 0.0 to 1.0, though
    /// in practice it may extend outside this range.
    ///
    /// See also:
    ///
    ///  * [evaluate], which is a shorthand for applying [transform] to the value
    ///    of an [Animation].
    ///  * [Curve.transform], a similar method for easing curves.
    func transform(_ t: Double) -> Value

    /// The current value of this object for the given [Animation].
    ///
    /// This function is implemented by deferring to [transform]. Subclasses that
    /// want to provide custom behavior should override [transform], not
    /// [evaluate].
    ///
    /// See also:
    ///
    ///  * [transform], which is similar but takes a `t` value directly instead of
    ///    an [Animation].
    ///  * [animate], which creates an [Animation] out of this object, continually
    ///    applying [evaluate].
    func evaluate(_ animation: any Animation<Double>) -> Value
}

// extension Animatable {
//     /// Create a new [Animatable] from the provided [callback].
//     ///
//     /// See also:
//     ///
//     ///  * [Animation.drive], which provides an example for how this can be
//     ///    used.
//     static func fromCallback(_ callback: @escaping AnimatableCallback<T>) -> Animatable<T> {

//     }

//     /// Returns a new [Animation] that is driven by the given animation but that
//     /// takes on values determined by this object.
//     ///
//     /// Essentially this returns an [Animation] that automatically applies the
//     /// [evaluate] method to the parent's value.
//     ///
//     /// See also:
//     ///
//     ///  * [AnimationController.drive], which does the same thing from the
//     ///    opposite starting point.
//     func animate(_ parent: Animation<Double>) -> Animation<T> {

//     }

//     /// Returns a new [Animatable] whose value is determined by first evaluating
//     /// the given parent and then evaluating this object.
//     ///
//     /// This allows [Tween]s to be chained before obtaining an [Animation].
//     func chain(_ parent: Animatable<Double>) -> Animatable<T> {

//     }

// }
