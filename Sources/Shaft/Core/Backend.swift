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
    var devicePixelRatio: Double { get }

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
}

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

    /// Schedule a frame to be rendered.
    func scheduleFrame()

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

/// Represents a platform specific mechanism for getting callbacks when a vsync
/// event happens.
protocol VsyncWaiter {
    /// Sets the callback that should be called when a vsync event happens.
    /// The callback may be called on a different thread.
    func setCallback(_ callback: @escaping VoidCallback)

    /// Requests the callback to be called on the next vsync event.
    func waitAsync()
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
