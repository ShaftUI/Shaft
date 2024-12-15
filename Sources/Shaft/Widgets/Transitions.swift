/// A widget that rebuilds when the given [Listenable] changes value.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=LKKgYpC-EPQ}
///
/// [AnimatedWidget] is most commonly used with [Animation] objects, which are
/// [Listenable], but it can be used with any [Listenable], including
/// [ChangeNotifier] and [ValueNotifier].
///
/// [AnimatedWidget] is most useful for widgets that are otherwise stateless. To
/// use [AnimatedWidget], subclass it and implement the build function.
///
/// For more complex case involving additional state, consider using
/// [AnimatedBuilder] or [ListenableBuilder].
///
/// ## Relationship to [ImplicitlyAnimatedWidget]s
///
/// [AnimatedWidget]s (and their subclasses) take an explicit [Listenable] as
/// argument, which is usually an [Animation] derived from an
/// [AnimationController]. In most cases, the lifecycle of that
/// [AnimationController] has to be managed manually by the developer.
/// In contrast to that, [ImplicitlyAnimatedWidget]s (and their subclasses)
/// automatically manage their own internal [AnimationController] making those
/// classes easier to use as no external [Animation] has to be provided by the
/// developer. If you only need to set a target value for the animation and
/// configure its duration/curve, consider using (a subclass of)
/// [ImplicitlyAnimatedWidget]s instead of (a subclass of) this class.
///
/// ## Common animated widgets
///
/// A number of animated widgets ship with the framework. They are usually named
/// `FooTransition`, where `Foo` is the name of the non-animated
/// version of that widget. The subclasses of this class should not be confused
/// with subclasses of [ImplicitlyAnimatedWidget] (see above), which are usually
/// named `AnimatedFoo`. Commonly used animated widgets include:
///
///  * [ListenableBuilder], which uses a builder pattern that is useful for
///    complex [Listenable] use cases.
///  * [AnimatedBuilder], which uses a builder pattern that is useful for
///    complex [Animation] use cases.
///  * [AlignTransition], which is an animated version of [Align].
///  * [DecoratedBoxTransition], which is an animated version of [DecoratedBox].
///  * [DefaultTextStyleTransition], which is an animated version of
///    [DefaultTextStyle].
///  * [PositionedTransition], which is an animated version of [Positioned].
///  * [RelativePositionedTransition], which is an animated version of
///    [Positioned].
///  * [RotationTransition], which animates the rotation of a widget.
///  * [ScaleTransition], which animates the scale of a widget.
///  * [SizeTransition], which animates its own size.
///  * [SlideTransition], which animates the position of a widget relative to
///    its normal position.
///  * [FadeTransition], which is an animated version of [Opacity].
///  * [AnimatedModalBarrier], which is an animated version of [ModalBarrier].
public final class AnimatedWidget: StatefulWidget {
    /// Creates a widget that rebuilds when the given listenable changes.
    ///
    /// The [listenable] argument is required.
    public init(listenable: Listenable) {
        self.listenable = listenable
    }

    /// The [Listenable] to which this widget is listening.
    ///
    /// Commonly an [Animation] or a [ChangeNotifier].
    public let listenable: Listenable

    /// Override this method to build widgets that depend on the state of the
    /// listenable (e.g., the current value of the animation).
    func build(context: BuildContext) -> Widget {
        fatalError("Subclasses must override this method")
    }

    /// Subclasses typically do not override this method.
    public func createState() -> State<AnimatedWidget> {
        AnimatedState()
    }
}

private class AnimatedState: State<AnimatedWidget> {
    override func initState() {
        super.initState()
        widget.listenable.addListener(self, callback: handleChange)
    }

    override func didUpdateWidget(_ oldWidget: AnimatedWidget) {
        super.didUpdateWidget(oldWidget)
        if widget.listenable !== oldWidget.listenable {
            oldWidget.listenable.removeListener(self)
            widget.listenable.addListener(self, callback: handleChange)
        }
    }

    override func dispose() {
        widget.listenable.removeListener(self)
        super.dispose()
    }

    private func handleChange() {
        if !mounted {
            return
        }
        setState {
            // The listenable's state is our build state, and it changed already.
        }
    }

    override func build(context: BuildContext) -> Widget {
        return widget.build(context: context)
    }
}
