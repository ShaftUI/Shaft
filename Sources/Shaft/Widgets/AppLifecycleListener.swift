/// A listener that can be used to listen to changes in the application
/// lifecycle.
///
/// To listen for requests for the application to exit, and to decide whether or
/// not the application should exit when requested, create an
/// [AppLifecycleListener] and set the [onExitRequested] callback.
///
/// To listen for changes in the application lifecycle state, define an
/// [onStateChange] callback. See the [AppLifecycleState] enum for details on
/// the various states.
///
/// The [onStateChange] callback is called for each state change, and the
/// individual state transitions ([onResume], [onInactive], etc.) are also
/// called if the state transition they represent occurs.
///
/// State changes will occur in accordance with the state machine described by
/// this diagram:
///
/// ![Diagram of the application lifecycle defined by the AppLifecycleState enum](
/// https://flutter.github.io/assets-for-api-docs/assets/dart-ui/app_lifecycle.png)
///
/// The initial state of the state machine is the [AppLifecycleState.detached]
/// state, and the arrows describe valid state transitions. Transitions in blue
/// are transitions that only happen on iOS and Android.
///
/// See also:
///
/// * [ServicesBinding.exitApplication] for a function to call that will request
///   that the application exits.
/// * [WidgetsBindingObserver.didRequestAppExit] for the handler which this
///   class uses to receive exit requests.
/// * [WidgetsBindingObserver.didChangeAppLifecycleState] for the handler which
///   this class uses to receive lifecycle state changes.
public class AppLifecycleListener: WidgetsBindingObserver {
    /// The WidgetsBinding to listen to for application lifecycle events.
    ///
    /// Typically, this is set to WidgetsBinding.instance, but may be
    /// substituted for testing or other specialized bindings.
    ///
    /// Defaults to WidgetsBinding.instance.
    public let binding: WidgetsBinding

    /// Called anytime the state changes, passing the new state.
    public var onStateChange: ((AppLifecycleState) -> Void)?

    /// A callback that is called when the application loses input focus.
    ///
    /// On mobile platforms, this can be during a phone call or when a system
    /// dialog is visible.
    ///
    /// On desktop platforms, this is when all views in an application have lost
    /// input focus but at least one view of the application is still visible.
    ///
    /// On the web, this is when the window (or tab) has lost input focus.
    public var onInactive: VoidCallback?

    /// A callback that is called when a view in the application gains input
    /// focus.
    ///
    /// A call to this callback indicates that the application is entering a state
    /// where it is visible, active, and accepting user input.
    public var onResume: VoidCallback?

    /// A callback that is called when the application is hidden.
    ///
    /// On mobile platforms, this is usually just before the application is
    /// replaced by another application in the foreground.
    ///
    /// On desktop platforms, this is just before the application is hidden by
    /// being minimized or otherwise hiding all views of the application.
    ///
    /// On the web, this is just before a window (or tab) is hidden.
    public var onHide: VoidCallback?

    /// A callback that is called when the application is shown.
    ///
    /// On mobile platforms, this is usually just before the application replaces
    /// another application in the foreground.
    ///
    /// On desktop platforms, this is just before the application is shown after
    /// being minimized or otherwise made to show at least one view of the
    /// application.
    ///
    /// On the web, this is just before a window (or tab) is shown.
    public var onShow: VoidCallback?

    /// A callback that is called when the application is paused.
    ///
    /// On mobile platforms, this happens right before the application is replaced
    /// by another application.
    ///
    /// On desktop platforms and the web, this function is not called.
    public var onPause: VoidCallback?

    /// A callback that is called when the application is resumed after being
    /// paused.
    ///
    /// On mobile platforms, this happens just before this application takes over
    /// as the active application.
    ///
    /// On desktop platforms and the web, this function is not called.
    public var onRestart: VoidCallback?

    /// A callback used to ask the application if it will allow exiting the
    /// application for cases where the exit is cancelable.
    ///
    /// Exiting the application isn't always cancelable, but when it is, this
    /// function will be called before exit occurs.
    ///
    /// Responding AppExitResponse.exit will continue termination, and
    /// responding AppExitResponse.cancel will cancel it. If termination is not
    /// canceled, the application will immediately exit.
    // public var onExitRequested: (() -> AppExitResponse)?

    /// A callback that is called when an application has exited, and detached all
    /// host views from the engine.
    ///
    /// This callback is only called on iOS and Android.
    public var onDetach: VoidCallback?

    private var _lifecycleState: AppLifecycleState?
    private var _debugDisposed = false

    /// Creates an AppLifecycleListener.
    public init(
        binding: WidgetsBinding? = nil,
        onResume: VoidCallback? = nil,
        onInactive: VoidCallback? = nil,
        onHide: VoidCallback? = nil,
        onShow: VoidCallback? = nil,
        onPause: VoidCallback? = nil,
        onRestart: VoidCallback? = nil,
        onDetach: VoidCallback? = nil,
        // onExitRequested: (() -> AppExitResponse)? = nil,
        onStateChange: ((AppLifecycleState) -> Void)? = nil
    ) {
        self.binding = binding ?? WidgetsBinding.shared
        self._lifecycleState = backend.lifecycleState
        self.onResume = onResume
        self.onInactive = onInactive
        self.onHide = onHide
        self.onShow = onShow
        self.onPause = onPause
        self.onRestart = onRestart
        self.onDetach = onDetach
        // self.onExitRequested = onExitRequested
        self.onStateChange = onStateChange
        self.binding.addObserver(self)
    }

    public func dispose() {
        binding.removeObserver(self)
    }

    // override public func didRequestAppExit() async -> AppExitResponse {
    //     if let onExitRequested = onExitRequested {
    //         return onExitRequested()
    //     }
    //     return .exit
    // }

    public func didChangeAppLifecycleState(state: AppLifecycleState) {
        let previousState = _lifecycleState
        if state == previousState {
            // Transitioning to the same state twice doesn't produce any
            // notifications (but also won't actually occur).
            return
        }
        _lifecycleState = state
        switch state {
        case .resumed:
            assert(
                previousState == nil || previousState == .inactive || previousState == .detached,
                "Invalid state transition from \(String(describing: previousState)) to \(state)"
            )
            onResume?()
        case .inactive:
            assert(
                previousState == nil || previousState == .hidden || previousState == .resumed,
                "Invalid state transition from \(String(describing: previousState)) to \(state)"
            )
            if previousState == .hidden {
                onShow?()
            } else if previousState == nil || previousState == .resumed {
                onInactive?()
            }
        case .hidden:
            assert(
                previousState == nil || previousState == .paused || previousState == .inactive,
                "Invalid state transition from \(String(describing: previousState)) to \(state)"
            )
            if previousState == .paused {
                onRestart?()
            } else if previousState == nil || previousState == .inactive {
                onHide?()
            }
        case .paused:
            assert(
                previousState == nil || previousState == .hidden,
                "Invalid state transition from \(String(describing: previousState)) to \(state)"
            )
            if previousState == nil || previousState == .hidden {
                onPause?()
            }
        case .detached:
            assert(
                previousState == nil || previousState == .paused,
                "Invalid state transition from \(String(describing: previousState)) to \(state)"
            )
            onDetach?()
        }
        // At this point, it can't be null anymore.
        onStateChange?(_lifecycleState!)
    }
}

private final class AppLifecycleListenerWidget: StatefulWidget {
    public init(
        onResume: VoidCallback? = nil,
        onInactive: VoidCallback? = nil,
        onHide: VoidCallback? = nil,
        onShow: VoidCallback? = nil,
        onPause: VoidCallback? = nil,
        onRestart: VoidCallback? = nil,
        onDetach: VoidCallback? = nil,
        // onExitRequested: (() -> AppExitResponse)? = nil,
        child: Widget
    ) {
        self.onResume = onResume
        self.onInactive = onInactive
        self.onHide = onHide
        self.onShow = onShow
        self.onPause = onPause
        self.onRestart = onRestart
        self.onDetach = onDetach
        self.child = child
    }

    let onResume: VoidCallback?
    let onInactive: VoidCallback?
    let onHide: VoidCallback?
    let onShow: VoidCallback?
    let onPause: VoidCallback?
    let onRestart: VoidCallback?
    let onDetach: VoidCallback?
    let child: Widget

    public func createState() -> some State<AppLifecycleListenerWidget> {
        return AppLifecycleListenerWidgetState()
    }
}

private final class AppLifecycleListenerWidgetState: State<AppLifecycleListenerWidget> {
    private var listener: AppLifecycleListener?

    override func initState() {
        super.initState()
        listener = AppLifecycleListener(
            onResume: widget.onResume,
            onInactive: widget.onInactive,
            onHide: widget.onHide,
            onShow: widget.onShow,
            onPause: widget.onPause,
            onRestart: widget.onRestart,
            onDetach: widget.onDetach
        )
    }

    override func didUpdateWidget(_ oldWidget: AppLifecycleListenerWidget) {
        super.didUpdateWidget(oldWidget)
        listener?.onResume = widget.onResume
        listener?.onInactive = widget.onInactive
        listener?.onHide = widget.onHide
        listener?.onShow = widget.onShow
        listener?.onPause = widget.onPause
        listener?.onRestart = widget.onRestart
        listener?.onDetach = widget.onDetach
    }

    override func dispose() {
        super.dispose()
        listener?.dispose()
        listener = nil
    }

    override func build(context: BuildContext) -> Widget {
        return widget.child
    }
}

extension Widget {
    /// Adds lifecycle event callbacks to this widget.
    ///
    /// This method allows you to register callbacks for various application lifecycle events:
    /// - `onResume`: Called when the application gains input focus
    /// - `onInactive`: Called when the application loses input focus
    /// - `onHide`: Called when the application is hidden
    /// - `onShow`: Called when the application is shown
    /// - `onPause`: Called when the application is paused (mobile platforms only)
    /// - `onRestart`: Called when the application is resumed after being paused (mobile platforms only)
    /// - `onDetach`: Called when the application is detached
    ///
    /// See [AppLifecycleState] for more details about the application lifecycle states.
    public func onAppLifecycle(
        onResume: VoidCallback? = nil,
        onInactive: VoidCallback? = nil,
        onHide: VoidCallback? = nil,
        onShow: VoidCallback? = nil,
        onPause: VoidCallback? = nil,
        onRestart: VoidCallback? = nil,
        onDetach: VoidCallback? = nil
    ) -> Widget {
        return AppLifecycleListenerWidget(
            onResume: onResume,
            onInactive: onInactive,
            onHide: onHide,
            onShow: onShow,
            onPause: onPause,
            onRestart: onRestart,
            onDetach: onDetach,
            child: self
        )
    }
}
