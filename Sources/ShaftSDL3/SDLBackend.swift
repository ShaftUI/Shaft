// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import Shaft
import SwiftMath
import SwiftSDL3

public class SDLBackend: Backend {
    private let tasks = TaskQueue()

    public let renderer: Renderer

    public init(renderer: Renderer) {
        assert(Thread.isMainThread)
        self.renderer = renderer
        SDL_SetHint("SDL_WINDOWS_DPI_AWARENESS", "permonitorv2")
        SDL_SetHint(SDL_HINT_MAC_SCROLL_MOMENTUM, "1")
        guard SDL_Init(SDL_INIT_VIDEO) else {
            fatalError("SDL could not initialize! SDL_Error: \(String(cString: SDL_GetError()))")
        }
    }

    deinit {
        assert(Thread.isMainThread)
        SDL_Quit()
    }

    // MARK: - Threading

    public var isMainThread: Bool {
        return Thread.isMainThread
    }

    /// Whether a runloop exit has been requested but not yet processed.
    private var shouldStop = false

    public func run() {
        assert(Thread.isMainThread)
        shouldStop = false

        while true {
            // process all pending events in the queue
            var event = SDL_Event()
            if SDL_WaitEvent(&event) {
                // mark("backend event:", String(format: "0x%02X", event.type))
                handleEvent(&event)
            }

            // run all tasks
            while let task = tasks.pop() {
                task()
            }

            // check if we should stop
            if shouldStop {
                shouldStop = false
                break
            }
        }
    }

    public func stop() {
        shouldStop = true
        wake()
    }

    private func handleEvent(_ event: inout SDL_Event) {
        switch SDL_EventType(event.type.cast()) {
        case SDL_EVENT_QUIT:
            shouldStop = true
        case SDL_EVENT_DID_ENTER_FOREGROUND:
            updateAppLifecycleState()
        case SDL_EVENT_DID_ENTER_BACKGROUND:
            updateAppLifecycleState()
        case SDL_EVENT_WINDOW_FOCUS_GAINED:
            onWindowFocusGained(event.window)
        case SDL_EVENT_WINDOW_FOCUS_LOST:
            onWindowFocusLost(event.window)
        case SDL_EVENT_WINDOW_HIDDEN:
            onWindowHidden(event.window)
        case SDL_EVENT_WINDOW_SHOWN:
            onWindowShown(event.window)
        case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
            onWindowCloseRequested(event.window)
        case SDL_EVENT_MOUSE_MOTION:
            onMouseMotion(event.motion)
        case SDL_EVENT_MOUSE_BUTTON_UP:
            onMouseButton(event.button, isDown: false)
        case SDL_EVENT_MOUSE_BUTTON_DOWN:
            onMouseButton(event.button, isDown: true)
        case SDL_EVENT_MOUSE_WHEEL:
            onMouseWheel(event.wheel)
        // case SDL_EVENT_WINDOWEVENT:
        //     switch SDL_WindowEventID(Uint32(event.window.event)) {
        //     case SDL_EVENT_WINDOWEVENT_RESIZED:
        //         // onWindowResize(event.window)
        //         mark("resized")
        //     case SDL_EVENT_WINDOWEVENT_SIZE_CHANGED:
        //         onWindowResize(event.window)
        //     // mark("size changed")
        //     case SDL_EVENT_WINDOWEVENT_CLOSE:
        //         mark("close")
        //     case SDL_EVENT_WINDOWEVENT_SHOWN:
        //         mark("shown")
        //     case SDL_EVENT_WINDOWEVENT_HIDDEN:
        //         mark("hidden")
        //     case SDL_EVENT_WINDOWEVENT_EXPOSED:
        //         mark("exposed")
        //     case SDL_EVENT_WINDOWEVENT_MOVED:
        //         mark("moved")
        //     default:
        //         mark("unknown window event:", event.window.event)
        //     }
        case SDL_EVENT_FINGER_DOWN:
            _ = event.tfinger
        // mark("fingerdown")
        case SDL_EVENT_FINGER_UP:
            _ = event.tfinger
        // mark("fingerup")
        case SDL_EVENT_FINGER_MOTION:
            _ = event.tfinger
        // mark("fingermotion")
        case SDL_EVENT_TEXT_EDITING:
            let event = event.edit
            handleTextEditing(event)
        case SDL_EVENT_TEXT_INPUT:
            let event = event.text
            handleTextComposed(event)
        case SDL_EVENT_KEY_DOWN:
            let event = event.key
            // mark("keydown")
            onKeyEvent(event)
        case SDL_EVENT_KEY_UP:
            let event = event.key
            // mark("keyup")
            onKeyEvent(event)
        default:
            ()
        // mark("unknown event:", SDL_EventType(event.type.cast()))
        }
    }

    public func postTask(_ task: @escaping () -> Void) {
        tasks.add(task)
        wake()
    }

    public func createTimer(_ delay: Duration, _ f: @escaping () -> Void) -> any Shaft.Timer {
        return SDLTimerManager.shared.createTimer(delay, f)
    }

    // const Uint32 myEventType = SDL_RegisterEvents(1);
    static let wakeEvent = SDL_RegisterEvents(1)

    private func wake() {
        var event = SDL_Event()
        event.type = Self.wakeEvent
        SDL_PushEvent(&event)
    }

    // MARK: - App Lifecycle

    public var onAppLifecycleStateChanged: AppLifecycleStateCallback?

    public private(set) var lifecycleState: AppLifecycleState = .detached

    private func updateAppLifecycleState() {
        let state: AppLifecycleState =
            if viewByID.values.allSatisfy({ $0.isHidden }) {
                // If all views are hidden, the app is considered hidden.
                .hidden
            } else if viewByID.values.allSatisfy({ !$0.hasFocus }) {
                // If all views are inactive, the app is considered inactive.
                .inactive
            } else {
                // Otherwise, the app is considered resumed.
                .resumed
            }

        if state != lifecycleState {
            // The state transition from resumed to hidden requires inactive
            // state in between.
            if lifecycleState == .resumed && state == .hidden {
                onAppLifecycleStateChanged?(.inactive)
            }

            if lifecycleState == .hidden && state == .resumed {
                onAppLifecycleStateChanged?(.inactive)
            }

            lifecycleState = state
            onAppLifecycleStateChanged?(state)
        }
    }

    // MARK: - View Management

    private static let viewTypes: [TargetPlatform: SDLView.Type] = {
        var types: [TargetPlatform: SDLView.Type] = [:]
        #if canImport(Metal)
            types[.macOS] = SDLMetalView.self
            types[.iOS] = SDLMetalView.self
        #endif
        types[.windows] = SDLOpenGLView.self
        types[.linux] = SDLOpenGLView.self
        types[.android] = SDLOpenGLView.self
        return types
    }()

    private var viewByID: [Int: SDLView] = [:]

    public func createView() -> NativeView? {
        assert(Thread.isMainThread)

        guard let view = Self.viewTypes[targetPlatform!]!.init(backend: self) else {
            return nil
        }

        viewByID[view.viewID] = view
        return view
    }

    /// Create a view from a raw view pointer.
    ///
    /// This method is used to create a view by wrapping an existing native view
    /// object. The raw view pointer should be a valid native view object for
    /// the target platform.
    public func createView(rawView: UnsafeMutableRawPointer) -> NativeView? {
        assert(Thread.isMainThread)

        guard let view = Self.viewTypes[targetPlatform!]!.init(backend: self, rawView: rawView)
        else {
            return nil
        }

        viewByID[view.viewID] = view
        return view
    }

    public func view(_ id: Int) -> NativeView? {
        return viewByID[id]
    }

    public func destroyView(_ view: NativeView) {
        if let view = viewByID.removeValue(forKey: view.viewID) {
            view.destroy()
        }
    }

    // MARK: - Vsync

    private var vsync = SDLVsyncWaiter(frameRate: 60)
    private let uiThread: DispatchQueue = DispatchQueue(label: "ui")

    public var onBeginFrame: FrameCallback?
    public var onDrawFrame: VoidCallback?

    public func scheduleFrame() {
        vsync.setCallback(handleVsync)
        vsync.waitAsync()
    }

    private func handleVsync() {
        postTask {
            let timestamp = Duration.milliseconds(SDL_GetTicks())
            self.onBeginFrame?(timestamp)
            self.onDrawFrame?()
        }
    }

    // MARK: - Hot Reload

    public var onReassemble: VoidCallback?

    public func scheduleReassemble() {
        runOnMainThread {
            self.onReassemble?()
        }
    }

    // MARK: - Event Handlers

    public var onPointerData: PointerDataCallback?

    private var pointerIdentifier = 0

    /// Bitfield of currently pressed buttons.
    private var buttonState = PointerButtons()

    /// Update the button state based on the given SDL button event.
    private func updateButtonState(_ sdlButton: Uint8, isDown: Bool) {
        let button =
            switch Int32(sdlButton) {
            case SDL_BUTTON_LEFT: PointerButtons.primaryMouseButton
            case SDL_BUTTON_MIDDLE: PointerButtons.middleMouseButton
            case SDL_BUTTON_RIGHT: PointerButtons.secondaryMouseButton
            case SDL_BUTTON_X1: PointerButtons.backMouseButton
            case SDL_BUTTON_X2: PointerButtons.forwardMouseButton
            default: fatalError()
            }

        if isDown {
            buttonState.insert(button)
        } else {
            buttonState.remove(button)
        }
    }

    /// Fires ``onPointerData``
    private func onMouseMotion(_ event: SDL_MouseMotionEvent) {
        let buttonPressed = event.state != 0  // non-zero SDL_MouseButtonFlags
        // SDL2 reports logical coordinates even in high DPI mode. So we need to
        // convert them back to physical coordinates.
        let sdlPixelDensity = viewByID[Int(event.windowID)]!.sdlPixelDensity
        let packet = PointerData(
            viewId: Int(event.windowID),
            timeStamp: Duration.milliseconds(event.timestamp),
            change: buttonPressed ? .move : .hover,
            kind: .mouse,
            device: Int(event.which),
            pointerIdentifier: buttonPressed ? pointerIdentifier : 0,
            physicalX: Int(Float(event.x) * sdlPixelDensity),
            physicalY: Int(Float(event.y) * sdlPixelDensity),
            physicalDeltaX: Int(Float(event.xrel) * sdlPixelDensity),
            physicalDeltaY: Int(Float(event.yrel) * sdlPixelDensity),
            buttons: buttonState
        )
        onPointerData?(packet)
    }

    /// Fires ``onPointerData``
    private func onMouseButton(_ event: SDL_MouseButtonEvent, isDown: Bool) {
        if isDown {
            pointerIdentifier += 1
        }

        updateButtonState(event.button, isDown: true)

        guard let view = viewByID[Int(event.windowID)] else {
            // When a button is pressed outside of any view, 0 is used as the
            // view id. Otherwise it's considered as an error.
            assert(event.windowID == 0, "Unknown window ID: \(event.windowID)")
            return
        }

        // SDL2 reports logical coordinates even in high DPI mode. So we need to
        // convert them back to physical coordinates.
        let sdlPixelDensity = view.sdlPixelDensity
        let packet = PointerData(
            viewId: Int(event.windowID),
            timeStamp: Duration.milliseconds(event.timestamp),
            change: isDown ? .down : .up,
            kind: .mouse,
            device: Int(event.which),
            pointerIdentifier: pointerIdentifier,
            physicalX: Int(Float(event.x) * sdlPixelDensity),
            physicalY: Int(Float(event.y) * sdlPixelDensity),
            physicalDeltaX: 0,
            physicalDeltaY: 0,
            buttons: buttonState
        )
        onPointerData?(packet)
    }

    /// Fires ``onPointerData``
    private func onMouseWheel(_ event: SDL_MouseWheelEvent) {
        let touchMouseID = Uint32(bitPattern: -1)
        if event.which == touchMouseID {
            return
        }

        // SDL2 reports logical coordinates even in high DPI mode. So we need to
        // convert them back to physical coordinates.
        let sdlPixelDensity = viewByID[Int(event.windowID)]!.sdlPixelDensity
        // let flipped = event.direction == SDL_MOUSEWHEEL_FLIPPED
        let scrollDeltaX = event.x
        let scrollDeltaY = -event.y
        let packet = PointerData(
            viewId: Int(event.windowID),
            timeStamp: Duration.milliseconds(event.timestamp),
            change: .none,
            kind: .mouse,
            signalKind: .scroll,
            device: Int(event.which),
            pointerIdentifier: 0,
            physicalX: Int(Float(event.mouse_x) * sdlPixelDensity),
            physicalY: Int(Float(event.mouse_y) * sdlPixelDensity),
            buttons: buttonState,
            scrollDeltaX: Double(Float(scrollDeltaX) * sdlPixelDensity),
            scrollDeltaY: Double(Float(scrollDeltaY) * sdlPixelDensity)
        )
        onPointerData?(packet)
    }

    /// Currently, it's the view's responsibility to call this method when the
    /// window is resized.
    public var onMetricsChanged: MetricsChangedCallback?

    public var onKeyEvent: KeyEventCallback?

    /// Fires ``onKeyEvent``
    private func onKeyEvent(_ event: SDL_KeyboardEvent) {
        let physicalKey = mapSDLScancode(event.scancode)
        let logicalKey = mapSDLKeycode(event.key)
        guard let physicalKey, let logicalKey else {
            return
        }
        let keyEvent = KeyEvent(
            type: event.repeat == true
                ? .repeating : event.type == SDL_EVENT_KEY_DOWN ? .down : .up,
            physicalKey: physicalKey,
            logicalKey: logicalKey
        )
        _ = onKeyEvent?(keyEvent)
    }

    public func getKeyboardState() -> [PhysicalKeyboardKey: LogicalKeyboardKey]? {
        var numKeys: Int32 = 0
        let state = SDL_GetKeyboardState(&numKeys)

        guard numKeys > 0 else {
            return nil
        }
        guard let state else {
            return nil
        }

        var pressedKeys = [PhysicalKeyboardKey: LogicalKeyboardKey]()
        for i in 0..<numKeys {
            let pressed = state.advanced(by: Int(i)).pointee == true
            if !pressed {
                continue
            }

            let physicalKey = mapSDLScancode(SDL_Scancode(i.cast()))
            let logicalKey = mapSDLKeycode(
                SDL_GetKeyFromScancode(SDL_Scancode(i.cast()), 0, false)
            )
            guard let physicalKey, let logicalKey else {
                continue
            }

            pressedKeys[physicalKey] = logicalKey
        }

        return pressedKeys
    }

    /// The id of the view that is currently editing text, updated by the view
    /// when it requests text input.
    internal var textEditingView: Int?

    /// Fires ``onTextEditing``
    private func handleTextEditing(_ event: SDL_TextEditingEvent) {
        let text = String(cString: event.text)

        let delta = TextEditingDeltaComposing(
            text: text,
            // SDL sends the editing range in UTF-16 code units, though the text is in UTF-8.
            range: .init(
                start: .init(utf16Offset: Int(event.start)),
                end: .init(utf16Offset: Int(event.start + event.length))
            )
        )

        if let view = viewByID[Int(event.windowID)] {
            view.onTextEditing?(delta)
        }
    }

    /// Fires ``onTextComposed``
    private func handleTextComposed(_ event: SDL_TextInputEvent) {
        let text = String(cString: event.text)

        let delta = TextEditingDeltaCommit(text: text)

        if let view = viewByID[Int(event.windowID)] {
            view.onTextEditing?(delta)
            view.onTextComposed?(text)
        }
    }

    private func onWindowFocusGained(_ event: SDL_WindowEvent) {
        let view = viewByID[Int(event.windowID)]
        guard let view else {
            return
        }
        view.hasFocus = true
        updateAppLifecycleState()
    }

    private func onWindowFocusLost(_ event: SDL_WindowEvent) {
        let view = viewByID[Int(event.windowID)]
        guard let view else {
            return
        }
        view.hasFocus = false
        updateAppLifecycleState()
    }

    private func onWindowHidden(_ event: SDL_WindowEvent) {
        let view = viewByID[Int(event.windowID)]
        guard let view else {
            return
        }
        view.isHidden = true
        updateAppLifecycleState()
    }

    private func onWindowShown(_ event: SDL_WindowEvent) {
        let view = viewByID[Int(event.windowID)]
        guard let view else {
            return
        }
        view.isHidden = false
        updateAppLifecycleState()
    }

    private func onWindowCloseRequested(_ event: SDL_WindowEvent) {
        destroyView(viewByID[Int(event.windowID)]!)
    }

    public var targetPlatform: TargetPlatform? {
        let platform = SDL_GetPlatform()
        let name = String(cString: platform!)
        return switch name {
        case "Windows": .windows
        case "macOS": .macOS
        case "Linux": .linux
        case "iOS": .iOS
        case "Android": .android
        default: nil
        }
    }

    public func createCursor(_ cursor: SystemMouseCursor) -> (any NativeMouseCursor)? {
        return SDLCursor(fromSystem: cursor)
    }

    public var locales: [Shaft.Locale] {
        var count: Int32 = 0
        let locales = SDL_GetPreferredLocales(&count)
        guard let locales else {
            return []
        }
        // return (0..<count).map { Locale(languageCode: String(cString: locales[$0].language)) }
        var result = [Shaft.Locale]()
        for i in 0..<Int(count) {
            let locale = locales[i]
            let language = String(cString: locale.pointee.language)
            let country =
                locale.pointee.country != nil ? String(cString: locale.pointee.country) : nil
            result.append(Shaft.Locale(language, countryCode: country))
        }
        return result
    }
}

/// A timer-based vsync implementation with fixed frame rate.
public class SDLVsyncWaiter {
    init(frameRate: Int) {
        self.targetFrameRate = frameRate
    }

    /// The target frame rate to simulate.
    let targetFrameRate: Int

    fileprivate var vsyncCallback: (() -> Void)?

    func setCallback(_ callback: @escaping VoidCallback) {
        vsyncCallback = callback
    }

    func waitAsync() {
        let now = SDL_GetTicks()
        let interval = 1.0 / Double(targetFrameRate) * 1000
        let delay = Self.intervalToNextFrameTime(now, interval: interval)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        SDL_AddTimer(Uint32(delay), onVsyncTimer, selfPtr)
    }

    /// Return the amount of time to wait until the next frame in milliseconds.
    private static func intervalToNextFrameTime(_ now: Uint64, interval: Double) -> Double {
        let timeSinceLastFrame = Double(now).truncatingRemainder(dividingBy: interval)
        return interval - timeSinceLastFrame
    }
}

/// Static callback to receive timer events from [SDLVsyncWaiter].
///
/// Self is a pointer to the [SDLVsyncWaiter] instance.
private func onVsyncTimer(param: UnsafeMutableRawPointer?, timerID: SDL_TimerID, interval: Uint32)
    -> Uint32
{
    let waiter = Unmanaged<SDLVsyncWaiter>.fromOpaque(param!).takeUnretainedValue()
    waiter.vsyncCallback?()

    // Stop the timer
    return 0
}

private class TaskQueue {
    private var tasks: [() -> Void] = []
    private var lock = NSLock()

    func add(_ task: @escaping () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        tasks.append(task)
    }

    func pop() -> (() -> Void)? {
        lock.lock()
        defer { lock.unlock() }
        return tasks.popLast()
    }

    // func isEmpty() -> Bool {
    //     lock.lock()
    //     defer { lock.unlock() }
    //     return tasks.isEmpty
    // }
}

private class SDLTimerManager {
    public static let shared = SDLTimerManager()

    private var callbackByTimerID: [SDL_TimerID: VoidCallback] = [:]

    public func createTimer(_ delay: Duration, _ callback: @escaping VoidCallback) -> SDLTimer {
        assert(backend.isMainThread)
        let timerID = SDL_AddTimer(Uint32(delay.inMilliseconds), sdlTimerCallback, nil)
        let timer = SDLTimer(timerID)
        callbackByTimerID[timer.timerID] = callback
        return timer
    }

    public func cancelTimer(_ timerID: SDL_TimerID) {
        assert(backend.isMainThread)
        SDL_RemoveTimer(timerID)
        callbackByTimerID.removeValue(forKey: timerID)
    }

    public func hasTimer(_ timerID: SDL_TimerID) -> Bool {
        return callbackByTimerID[timerID] != nil
    }

    fileprivate func fireTimer(_ timerID: SDL_TimerID) {
        backend.runOnMainThread {
            self.fireTimerInner(timerID)
        }
    }

    private func fireTimerInner(_ timerID: SDL_TimerID) {
        assert(backend.isMainThread)
        if let callback = callbackByTimerID[timerID] {
            callbackByTimerID.removeValue(forKey: timerID)
            callback()
        }
    }
}

private func sdlTimerCallback(
    param: UnsafeMutableRawPointer?,
    timerID: SDL_TimerID,
    interval: Uint32
)
    -> Uint32
{
    let manager = SDLTimerManager.shared
    manager.fireTimer(timerID)
    return 0
}

private class SDLTimer: Shaft.Timer {
    public let timerID: SDL_TimerID

    public init(_ timerID: SDL_TimerID) {
        self.timerID = timerID
    }

    public func cancel() {
        SDLTimerManager.shared.cancelTimer(timerID)
    }

    public var isActive: Bool {
        return SDLTimerManager.shared.hasTimer(timerID)
    }
}
