/// The status of an animation.
public enum AnimationStatus {
    /// The animation is stopped at the beginning.
    case dismissed

    /// The animation is running from beginning to end.
    case forward

    /// The animation is running backwards, from end to beginning.
    case reverse

    /// The animation is stopped at the end.
    case completed

    /// Whether the animation is stopped at the beginning.
    var isDismissed: Bool { self == .dismissed }

    /// Whether the animation is stopped at the end.
    var isCompleted: Bool { self == .completed }

    /// Whether the animation is running in either direction.
    var isAnimating: Bool {
        switch self {
        case .forward, .reverse: return true
        case .completed, .dismissed: return false
        }
    }

    /// Whether the current aim of the animation is toward completion.
    ///
    /// Specifically, returns `true` for ``AnimationStatus/forward`` or
    /// ``AnimationStatus/completed``, and `false` for
    /// ``AnimationStatus/reverse`` or ``AnimationStatus/dismissed``.
    var isForwardOrCompleted: Bool {
        switch self {
        case .forward, .completed: return true
        case .reverse, .dismissed: return false
        }
    }
}

/// Signature for listeners attached using ``Animation/addStatusListener``.
public typealias AnimationStatusListener = (AnimationStatus) -> Void

/// Signature for method used to transform values in ``Animation/fromValueListenable``.
public typealias ValueListenableTransformer<T> = (T) -> T

/// An animation with a value of type `T`.
///
/// An animation consists of a value (of type `T`) together with a status. The
/// status indicates whether the animation is conceptually running from
/// beginning to end or from the end back to the beginning, although the actual
/// value of the animation might not change monotonically (e.g., if the
/// animation uses a curve that bounces).
///
/// Animations also let other objects listen for changes to either their value
/// or their status. These callbacks are called during the "animation" phase of
/// the pipeline, just prior to rebuilding widgets.
///
/// To create a new animation that you can run forward and backward, consider
/// using ``AnimationController``.
///
/// See also:
///
///  * ``Tween``, which can be used to create ``Animation`` subclasses that
///    convert `Animation<double>`s into other kinds of ``Animation``s.
public protocol Animation<Value>: Listenable, ValueListenable {
    associatedtype Value

    /// Create a new animation from a ``ValueListenable``.
    ///
    /// The returned animation will always have an animations status of
    /// ``AnimationStatus/forward``. The value of the provided listenable can be
    /// optionally transformed using the ``transformer`` function.
    // static func fromValueListenable(
    //     _ listenable: any ValueListenable<Value>,
    //     transformer: ValueListenableTransformer<Value>?
    // ) -> any Animation

    /// Calls listener every time the status of the animation changes.
    ///
    /// Listeners can be removed with ``removeStatusListener``.
    func addStatusListener(_ listener: AnyObject, callback: @escaping AnimationStatusListener)

    /// Stops calling the listener every time the status of the animation
    /// changes.
    ///
    /// If `listener` is not currently registered as a status listener, this
    /// method does nothing.
    ///
    /// Listeners can be added with ``addStatusListener``.
    func removeStatusListener(_ listener: AnyObject)

    /// The current status of this animation.
    var status: AnimationStatus { get }

    /// The current value of the animation.
    var value: Value { get }

    /// Chains a ``Tween`` (or ``CurveTween``) to this ``Animation``.
    ///
    /// This method is only valid for `Animation<double>` instances (i.e. when `T`
    /// is `double`). This means, for instance, that it can be called on
    /// ``AnimationController`` objects, as well as ``CurvedAnimation``s,
    /// ``ProxyAnimation``s, ``ReverseAnimation``s, ``TrainHoppingAnimation``s, etc.
    ///
    /// It returns an ``Animation`` specialized to the same type, `U`, as the
    /// argument to the method (`child`), whose value is derived by applying the
    /// given ``Tween`` to the value of this ``Animation``.
    // func drive<U>(_ child: any Animatable<U>) -> any Animation<U>

    /// Provides a string describing the status of this object, but not
    /// including information about the object itself.
    ///
    /// This function is used by ``Animation/toString`` so that ``Animation``
    /// subclasses can provide additional details while ensuring all ``Animation``
    /// subclasses have a consistent ``toString`` style.
    func toStringDetails() -> String
}

extension Animation {
    /// Whether this animation is stopped at the beginning.
    var isDismissed: Bool { status.isDismissed }

    /// Whether this animation is stopped at the end.
    var isCompleted: Bool { status.isCompleted }

    /// Whether this animation is running in either direction.
    var isAnimating: Bool { status.isAnimating }

    /// Whether the current aim of the animation is toward completion.
    var isForwardOrCompleted: Bool { status.isForwardOrCompleted }

    public func toStringDetails() -> String {
        switch status {
        case .forward: return "\u{25B6}"  // >
        case .reverse: return "\u{25C0}"  // <
        case .completed: return "\u{23ED}"  // >>|
        case .dismissed: return "\u{23EE}"  // |<<
        }
    }
}
