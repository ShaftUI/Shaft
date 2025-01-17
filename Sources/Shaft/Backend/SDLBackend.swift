// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import SwiftMath
import SwiftSDL3

#if canImport(Metal)
    import Metal
    private func createDefaultRenderer() -> Renderer {
        let metalDevice = MTLCreateSystemDefaultDevice()!
        let metalCommandQueue = metalDevice.makeCommandQueue()!
        return SkiaMetalRenderer(
            device: metalDevice,
            queue: metalCommandQueue
        )
    }
#else
    private func createDefaultRenderer() -> Renderer {
        return SkiaGLRenderer()
    }
#endif

public class SDLBackend: Backend {
    public static let shared = SDLBackend()

    private let tasks = TaskQueue()

    public let renderer: Renderer

    private init(renderer: Renderer? = nil) {
        assert(Thread.isMainThread)
        self.renderer = renderer ?? createDefaultRenderer()
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
        // mark("unknown event type:", event.type)
        }
    }

    public func postTask(_ task: @escaping () -> Void) {
        tasks.add(task)
        wake()
    }

    public func createTimer(_ delay: Duration, _ f: @escaping () -> Void) -> any Timer {
        return SDLTimerManager.shared.createTimer(delay, f)
    }

    // const Uint32 myEventType = SDL_RegisterEvents(1);
    static let wakeEvent = SDL_RegisterEvents(1)

    private func wake() {
        var event = SDL_Event()
        event.type = Self.wakeEvent
        SDL_PushEvent(&event)
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

    public func view(_ id: Int) -> NativeView? {
        return viewByID[id]
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
}

/// A timer-based vsync implementation with fixed frame rate.
public class SDLVsyncWaiter: VsyncWaiter {
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
        let timerID = SDL_AddTimer(Uint32(delay.inMilliseconds), sdlTimerCallback, nil)
        let timer = SDLTimer(timerID)
        callbackByTimerID[timer.timerID] = callback
        return timer
    }

    public func cancelTimer(_ timerID: SDL_TimerID) {
        SDL_RemoveTimer(timerID)
        callbackByTimerID.removeValue(forKey: timerID)
    }

    public func hasTimer(_ timerID: SDL_TimerID) -> Bool {
        return callbackByTimerID[timerID] != nil
    }

    public func fireTimer(_ timerID: SDL_TimerID) {
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

private class SDLTimer: Timer {
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
