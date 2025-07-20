// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

public protocol NativeView: AnyObject {
    /// ID for this view, unique within a certain backend.
    var viewID: Int { get }

    /// The dimensions of the rectangle into which the scene rendered in this view
    /// will be drawn on the screen, in physical pixels.
    var physicalSize: ISize { get }

    /// The number of device pixels for each logical pixel for the screen this
    /// view is displayed on.
    ///
    /// This number might not be a power of two. Indeed, it might not even be an
    /// integer. For example, the Nexus 6 has a device pixel ratio of 3.5.
    ///
    /// Device pixels are also referred to as physical pixels. Logical pixels are
    /// also referred to as device-independent or resolution-independent pixels.
    var devicePixelRatio: Float { get }

    /// Updates the view's rendering on the GPU with the newly provided [Scene].
    func render(_ layerTree: LayerTree)

    /// Activates the text input connection with the platform. After this is
    /// called, the platform will send text editing and text input events via
    /// the ``onTextEditing`` and ``onTextComposed`` callbacks. To deactivate
    /// the text input connection, call ``stopTextInput``.
    func startTextInput()

    /// Deactivates the text input connection with the platform. After this is
    /// called, the platform will no longer send text editing and text input
    /// events.
    func stopTextInput()

    /// Sets the rectangle that covers the text in the client that's currently
    /// being composed.
    ///
    /// The given rectangle is in logical pixels relative to the view's origin.
    func setComposingRect(_ rect: Rect)

    /// Informs the text input control about client position changes.
    ///
    /// This method is called on when the input control should position itself in
    /// relation to the attached input client.
    func setEditableSizeAndTransform(_ size: Size, _ transform: Matrix4x4f)

    /// Whether the text input connection is currently active.
    var textInputActive: Bool { get }

    /// A callback that is invoked when the text being edited changes. Call
    /// ``startTextInput`` to activate the text input connection and begin
    /// receiving these events.
    var onTextEditing: TextEditingCallback? { get set }

    /// A callback that is invoked when the text has been composed and
    /// committed. Call ``startTextInput`` to activate the text input connection
    /// and begin receiving these events.
    var onTextComposed: TextComposedCallback? { get set }

    /// Getting/Setting the title of the view if possible.
    var title: String { get set }

    /// A raw pointer to the underlying view object that this NativeView wraps.
    ///
    /// - On MacOS, this is an pointer to a `NSView`.
    /// - On iOS/tvOS, this is a pointer to a `UIView`.
    ///
    /// This is an optional property, and it is not guaranteed to be implemented
    /// on all platforms.
    var rawView: UnsafeMutableRawPointer? { get }
}

extension NativeView {
    /// Returns the logical size of the view, which is the physical size divided
    /// by the device pixel ratio.
    ///
    /// This is a convenience property that calculates the logical size from the
    /// physical size and device pixel ratio, which are required properties of
    /// the NativeView protocol.
    public var logicalSize: Size {
        physicalSize / devicePixelRatio
    }
}

extension NativeView {
    public var rawView: UnsafeMutableRawPointer? { nil }
}

/// An identifier for a display (monitor).
public typealias DisplayID = UInt32

/// A protocol that represents a native view on desktop platforms.
public protocol DesktopView: NativeView {
    /// The position of the view's top-left corner in screen coordinates.
    var position: Offset { get set }

    /// The size of the view.
    var size: Size { get set }

    /// The display ID of the display that the view is on.
    var displayID: DisplayID { get }

    /// Whether the view is always on top of other views.
    var alwaysOnTop: Bool { get set }

    /// Whether the view is visible.
    var visible: Bool { get set }

    /// Whether the view has focus.
    var hasFocus: Bool { get }
}

public enum MenuEntry {
    case item(title: String, isSelected: Bool = false, action: () -> Void)

    /// A separator line.
    case separator
}

public protocol NativeViewWithMenu: NativeView {
    func openMenu(_ menu: [MenuEntry], at point: Offset)
}

#if canImport(AppKit)
    import AppKit

    public protocol MacOSView: DesktopView, NativeViewWithMenu {
        var nsWindow: NSWindow? { get }
    }
#else

    public protocol MacOSView: DesktopView {}

#endif

/// A protocol that represents a native mouse cursor. Can be used to set the
/// cursor appearance when the mouse pointer is over a view.
///
/// After activated, the cursor must be retained by the caller until it is
/// deactivated. Otherwise, the cursor will be deactivated automatically.
public protocol NativeMouseCursor: AnyObject {
    /// Sets the current active mouse cursor to this cursor.
    func activate()
}

/// A collection of system [MouseCursor]s.
///
/// System cursors are standard mouse cursors that are provided by the current
/// platform. They don't require external resources.
///
/// [SystemMouseCursors] is a superset of the system cursors of every platform
/// that Flutter supports, therefore some of these objects might map to the same
/// result, or fallback to the [basic] arrow. This mapping is defined by the
/// Flutter engine.
///
/// The cursors should be named based on the cursors' use cases instead of their
/// appearance, because different platforms might (although not commonly) use
/// different shapes for the same use case.
public enum SystemMouseCursor {
    case basic
    case click
    case forbidden
    case wait
    case progress
    case contextMenu
    case help
    case text
    case verticalText
    case cell
    case precise
    case move
    case grab
    case grabbing
    case noDrop
    case alias
    case copy
    case disappearing
    case allScroll
    case resizeLeftRight
    case resizeUpDown
    case resizeUpLeftDownRight
    case resizeUpRightDownLeft
    case resizeUp
    case resizeDown
    case resizeLeft
    case resizeRight
    case resizeUpLeft
    case resizeUpRight
    case resizeDownLeft
    case resizeDownRight
    case resizeColumn
    case resizeRow
    case zoomIn
    case zoomOut
}

public typealias PointerDataCallback = (PointerData) -> Void

public typealias MetricsChangedCallback = (_ viewID: Int) -> Void

public typealias KeyEventCallback = (KeyEvent) -> Bool

public typealias TextEditingCallback = (TextEditingDelta) -> Void

public typealias TextComposedCallback = (String) -> Void

public protocol Backend: AnyObject {
    /// Creates a new view to render the scene on.
    func createView() -> NativeView?

    /// Returns the view with the given ID, or nil if no such view exists.
    func view(_ viewId: Int) -> NativeView?

    /// The renderer used by the views created by this backend to render their
    /// scenes.
    var renderer: Renderer { get }

    /// A callback that is invoked when pointer data is available.
    var onPointerData: PointerDataCallback? { get set }

    /// A callback that is invoked when a key event has been received from the
    /// system.
    var onKeyEvent: KeyEventCallback? { get set }

    /// Get a snapshot of the current state of the keyboard. Returns a map of
    /// keys that are pressed, mapped to the logical key that was pressed. nil
    /// if the backend does not support this.
    func getKeyboardState() -> [PhysicalKeyboardKey: LogicalKeyboardKey]?

    /// A callback that is invoked whenever the [ViewConfiguration] of the view
    /// with the given ID changes.
    ///
    /// For example when the device is rotated or when the application is resized
    /// (e.g. when showing applications side-by-side on Android),
    /// `onMetricsChanged` is called.
    ///
    /// The framework registers with this callback and updates the layout
    /// appropriately.
    var onMetricsChanged: MetricsChangedCallback? { get set }

    /// A callback invoked when any view begins a frame.
    ///
    /// A callback that is invoked to notify the application that it is an
    /// appropriate time to provide a scene using the [NativeView.render] method.
    var onBeginFrame: FrameCallback? { get set }

    /// A callback that is invoked for each frame after [onBeginFrame] has
    /// completed and after the microtask queue has been drained.
    ///
    /// This can be used to implement a second phase of frame rendering that
    /// happens after any deferred work queued by the [onBeginFrame] phase.
    var onDrawFrame: VoidCallback? { get set }

    /// A callback that is invoked when hot reload happens and the application
    /// needs to reassemble the current view.
    var onReassemble: VoidCallback? { get set }

    /// Whether the application is visible, and if so, whether it is currently
    /// interactive.
    var lifecycleState: AppLifecycleState { get }

    /// A callback that is invoked when the application lifecycle state changes.
    var onAppLifecycleStateChanged: AppLifecycleStateCallback? { get set }

    /// Schedule a frame to be rendered.
    func scheduleFrame()

    /// Schedule a reassemble immediately. This causes the [onReassemble]
    /// callback to be called as soon as possible if supported by the backend.
    func scheduleReassemble()

    /// Enter the event loop. Blocks until the application is ready to exit.
    func run()

    /// Exit the event loop.
    func stop()

    /// Returns a Boolean value that indicates whether the current thread is the
    /// thread that is running the application's main event loop.
    var isMainThread: Bool { get }

    /// Sends a function to be executed in the run loop.
    func postTask(_ f: @escaping () -> Void)

    /// Creates a new timer that will execute the given callback function after
    /// the specified delay.
    ///
    /// The timer will be executed on the main thread, even if the current
    /// thread is not the main thread.
    ///
    /// The returned `Timer` object can be used to cancel the timer before it
    /// executes.
    func createTimer(_ delay: Duration, _ f: @escaping () -> Void) -> Timer

    /// Get the platform that the application is running on.
    var targetPlatform: TargetPlatform? { get }

    /// Creates a new native mouse cursor from the given system cursor.
    ///
    /// This method allows creating a native mouse cursor that can be used to
    /// set the cursor appearance when the mouse pointer is over a view.
    ///
    /// Not all system cursors types are supported on all platforms. If the
    /// given cursor type is not supported, this method will return nil.
    func createCursor(_ cursor: SystemMouseCursor) -> NativeMouseCursor?
}

extension Backend {
    /// A helper method that runs the given function on the ui thread. The
    /// function is executed immediately if the current thread is the ui thread.
    /// Otherwise, the function is posted to the ui thread's event queue.
    public func runOnMainThread(_ fn: @escaping () -> Void) {
        if isMainThread {
            fn()
        } else {
            postTask(fn)
        }
    }

    public var onReassemble: VoidCallback? {
        get { nil }
        set {}
    }

    public func scheduleReassemble() {}
}

public protocol Timer {
    /// Cancels the timer.
    ///
    /// Once a [Timer] has been canceled, the callback function will not be called
    /// by the timer. Calling [cancel] more than once on a [Timer] is allowed, and
    /// will have no further effect.
    ///
    /// Example:
    ///
    /// ```
    /// let timer = backend.createTimer(Duration.seconds(1)) { _ in print("Timer finished") }
    /// // Cancel timer, callback never called.
    /// timer.cancel()
    /// ````
    func cancel()

    /// Returns whether the timer is still active.
    ///
    /// A timer is active if the callback has not been executed,
    /// and the timer has not been canceled.
    var isActive: Bool { get }
}

/// A callback function that is invoked when the application's lifecycle state
/// changes.
///
/// The callback receives the new [AppLifecycleState] as its parameter, allowing
/// applications to respond to changes in the application's lifecycle, such as
/// when the app is sent to the background or brought back to the foreground.
///
/// This callback can be used to pause animations, release resources when the
/// app is not visible, or resume operations when the app becomes active again.
public typealias AppLifecycleStateCallback = (AppLifecycleState) -> Void

/// States that an application can be in once it is running.
///
/// States not supported on a platform will be synthesized by the framework when
/// transitioning between states which are supported, so that all
/// implementations share the same state machine.
///
/// The initial value for the state is the [detached] state, updated to the
/// current state (usually [resumed]) as soon as the first lifecycle update is
/// received from the platform.
///
/// For historical and name collision reasons, Flutter's application state names
/// do not correspond one to one with the state names on all platforms. On
/// Android, for instance, when the OS calls
/// [`Activity.onPause`](https://developer.android.com/reference/android/app/Activity#onPause()),
/// Flutter will enter the [inactive] state, but when Android calls
/// [`Activity.onStop`](https://developer.android.com/reference/android/app/Activity#onStop()),
/// Flutter enters the [paused] state. See the individual state's documentation
/// for descriptions of what they mean on each platform.
///
/// The current application state can be obtained from
/// [SchedulerBinding.instance.lifecycleState], and changes to the state can be
/// observed by creating an [AppLifecycleListener], or by using a
/// [WidgetsBindingObserver] by overriding the
/// [WidgetsBindingObserver.didChangeAppLifecycleState] method.
///
/// Applications should not rely on always receiving all possible notifications.
///
/// For example, if the application is killed with a task manager, a kill
/// signal, the user pulls the power from the device, or there is a rapid
/// unscheduled disassembly of the device, no notification will be sent before
/// the application is suddenly terminated, and some states may be skipped.
///
/// See also:
///
/// * [AppLifecycleListener], an object used observe the lifecycle state that
///   provides state transition callbacks.
/// * [WidgetsBindingObserver], for a mechanism to observe the lifecycle state
///   from the widgets layer.
/// * iOS's [UIKit activity
///   lifecycle](https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle?language=objc)
///   documentation.
/// * Android's [activity
///   lifecycle](https://developer.android.com/guide/components/activities/activity-lifecycle)
///   documentation.
/// * macOS's [AppKit activity
///   lifecycle](https://developer.apple.com/documentation/appkit/nsapplicationdelegate?language=objc)
///   documentation.
public enum AppLifecycleState {
    /// The application is still hosted by a Flutter engine but is detached from
    /// any host views.
    ///
    /// The application defaults to this state before it initializes, and can be
    /// in this state (applicable on Android, iOS, and web) after all views have been
    /// detached.
    ///
    /// When the application is in this state, the engine is running without a
    /// view.
    ///
    /// This state is only entered on iOS, Android, and web, although on all platforms
    /// it is the default state before the application begins running.
    case detached

    /// On all platforms, this state indicates that the application is in the
    /// default running mode for a running application that has input focus and is
    /// visible.
    ///
    /// On Android, this state corresponds to the Flutter host view having focus
    /// ([`Activity.onWindowFocusChanged`](https://developer.android.com/reference/android/app/Activity#onWindowFocusChanged(boolean))
    /// was called with true) while in Android's "resumed" state. It is possible
    /// for the Flutter app to be in the [inactive] state while still being in
    /// Android's
    /// ["onResume"](https://developer.android.com/guide/components/activities/activity-lifecycle)
    /// state if the app has lost focus
    /// ([`Activity.onWindowFocusChanged`](https://developer.android.com/reference/android/app/Activity#onWindowFocusChanged(boolean))
    /// was called with false), but hasn't had
    /// [`Activity.onPause`](https://developer.android.com/reference/android/app/Activity#onPause())
    /// called on it.
    ///
    /// On iOS and macOS, this corresponds to the app running in the foreground
    /// active state.
    case resumed

    /// At least one view of the application is visible, but none have input
    /// focus. The application is otherwise running normally.
    ///
    /// On non-web desktop platforms, this corresponds to an application that is
    /// not in the foreground, but still has visible windows.
    ///
    /// On the web, this corresponds to an application that is running in a
    /// window or tab that does not have input focus.
    ///
    /// On iOS and macOS, this state corresponds to the Flutter host view running in the
    /// foreground inactive state. Apps transition to this state when in a phone
    /// call, when responding to a TouchID request, when entering the app switcher
    /// or the control center, or when the UIViewController hosting the Flutter
    /// app is transitioning.
    ///
    /// On Android, this corresponds to the Flutter host view running in Android's
    /// paused state (i.e.
    /// [`Activity.onPause`](https://developer.android.com/reference/android/app/Activity#onPause())
    /// has been called), or in Android's "resumed" state (i.e.
    /// [`Activity.onResume`](https://developer.android.com/reference/android/app/Activity#onResume())
    /// has been called) but does not have window focus. Examples of when apps
    /// transition to this state include when the app is partially obscured or
    /// another activity is focused, a app running in a split screen that isn't
    /// the current app, an app interrupted by a phone call, a picture-in-picture
    /// app, a system dialog, another view. It will also be inactive when the
    /// notification window shade is down, or the application switcher is visible.
    ///
    /// On Android and iOS, apps in this state should assume that they may be
    /// [hidden] and [paused] at any time.
    case inactive

    /// All views of an application are hidden, either because the application is
    /// about to be paused (on iOS and Android), or because it has been minimized
    /// or placed on a desktop that is no longer visible (on non-web desktop), or
    /// is running in a window or tab that is no longer visible (on the web).
    ///
    /// On iOS and Android, in order to keep the state machine the same on all
    /// platforms, a transition to this state is synthesized before the [paused]
    /// state is entered when coming from [inactive], and before the [inactive]
    /// state is entered when coming from [paused]. This allows cross-platform
    /// implementations that want to know when an app is conceptually "hidden" to
    /// only write one handler.
    case hidden

    /// The application is not currently visible to the user, and not responding
    /// to user input.
    ///
    /// When the application is in this state, the engine will not call the
    /// [PlatformDispatcher.onBeginFrame] and [PlatformDispatcher.onDrawFrame]
    /// callbacks.
    ///
    /// This state is only entered on iOS and Android.
    case paused
}
