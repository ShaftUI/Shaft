// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import Shaft
import SwiftMath
import SwiftSDL3

/// A NativeView implementation that uses SDL window as backend and Metal for
/// rendering.
public class SDLView: NativeView {
    internal required init?(backend: SDLBackend) {
        let props = SDL_CreateProperties()
        defer { SDL_DestroyProperties(props) }
        SDL_SetBooleanProperty(props, SDL_PROP_WINDOW_CREATE_HIGH_PIXEL_DENSITY_BOOLEAN, true)
        SDL_SetBooleanProperty(props, SDL_PROP_WINDOW_CREATE_OPENGL_BOOLEAN, true)
        SDL_SetBooleanProperty(props, SDL_PROP_WINDOW_CREATE_RESIZABLE_BOOLEAN, true)

        guard
            let window = SDL_CreateWindowWithProperties(props)
        else {
            let error = SDL_GetError()
            mark("error:", String(cString: error!))
            return nil
        }
        self.sdlWindow = window
        self.viewID = Int(SDL_GetWindowID(window))

        let contentScale = SDL_GetDisplayContentScale(SDL_GetDisplayForWindow(window))
        SDL_SetWindowSize(window, Int32(800 * contentScale), Int32(600 * contentScale))

        self.backend = backend
        self.rasterThread = DispatchQueue(label: "raster-\(viewID)")
    }

    deinit {
        SDL_RemoveEventWatch(sdlEventWatcher, Unmanaged.passUnretained(self).toOpaque())
    }

    public let viewID: Int

    /// The backend that owns this view.
    internal weak var backend: SDLBackend?

    /// The SDL window that this view presents.
    internal let sdlWindow: OpaquePointer

    /// The thread dedicated to rasterizing this view.
    internal let rasterThread: DispatchQueue

    public func render(_ layerTree: LayerTree) {
        rasterThread.sync {
            self.performRender(layerTree)
        }
    }

    /// The actual rendering logic that runs on the raster thread.
    internal func performRender(_ layerTree: LayerTree) {
        shouldImplement()
    }

    public var logicalSize: ISize {
        var width: Int32 = 0
        var height: Int32 = 0
        SDL_GetWindowSize(sdlWindow, &width, &height)
        return ISize(
            Int(Float(width) / sdlContentScale),
            Int(Float(height) / sdlContentScale)
        )
    }

    public var physicalSize: ISize {
        var width: Int32 = 0
        var height: Int32 = 0
        SDL_GetWindowSizeInPixels(sdlWindow, &width, &height)
        return ISize(Int(width), Int(height))
    }

    public var devicePixelRatio: Float {
        return SDL_GetWindowDisplayScale(sdlWindow)
    }

    /// Retrieves the suggested amplification factor when drawing in native
    /// coordinates.
    internal var sdlContentScale: Float {
        return SDL_GetDisplayContentScale(SDL_GetDisplayForWindow(sdlWindow))
    }

    /// Retrieves how many addressable pixels correspond to one unit of native
    /// coordinates.
    internal var sdlPixelDensity: Float {
        return SDL_GetWindowPixelDensity(sdlWindow)
    }

    private func handleWindowResize(_ event: SDL_WindowEvent) {
        let viewID = Int(event.windowID)
        if viewID != self.viewID {
            return
        }

        backend?.onMetricsChanged?(viewID)
    }

    internal func onDpiChanged(xscale: Float, yscale: Float) {
        // assert(Thread.isMainThread)
        // backend?.onMetricsChanged?(viewID)
        // mark("dpi: \(xscale), \(yscale)")
        // onMetricsChanged?()
        // backend?.forceFrame()
    }

    internal func startResizeListener() {
        SDL_AddEventWatch(sdlEventWatcher, Unmanaged.passUnretained(self).toOpaque())
    }

    public func startTextInput() {
        SDL_StartTextInput(sdlWindow)
    }

    public func stopTextInput() {
        SDL_StopTextInput(sdlWindow)
    }

    private var _lastEditableSize: Shaft.Size?
    private var _lastEditableTransform: Matrix4x4f?

    public func setComposingRect(_ rect: Shaft.Rect) {
        guard let editableTransform = _lastEditableTransform else {
            return
        }

        let translatedRect = MatrixUtils.transformRect(editableTransform, rect)

        var sdlRect = SDL_Rect(
            x: Int32(translatedRect.left),
            y: Int32(translatedRect.top),
            w: Int32(translatedRect.width),
            h: Int32(translatedRect.height)
        )
        SDL_SetTextInputArea(sdlWindow, &sdlRect, 0)
    }

    public func setEditableSizeAndTransform(_ size: Shaft.Size, _ transform: Matrix4x4f) {
        _lastEditableSize = size
        _lastEditableTransform = transform
    }

    public var textInputActive: Bool {
        SDL_TextInputActive(sdlWindow)
    }

    /// It's the backend's responsibility to call this method when text editing
    /// events are received.
    public var onTextEditing: TextEditingCallback?

    /// It's the backend's responsibility to call this method when text composed
    /// events are received.
    public var onTextComposed: TextComposedCallback?

    fileprivate func handleEventSync(_ event: inout SDL_Event) -> Bool {
        switch SDL_EventType(event.type.cast()) {
        case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
            handleWindowResize(event.window)
            return false
        default:
            return true
        }
    }

    public internal(set) var hasFocus: Bool = false

    public internal(set) var isHidden: Bool = false

    public var title: String {
        get {
            return String(cString: SDL_GetWindowTitle(sdlWindow))
        }
        set {
            SDL_SetWindowTitle(sdlWindow, newValue)
        }
    }

    public var visible: Bool {
        get {
            return !isHidden
        }
        set {
            if newValue == true {
                SDL_ShowWindow(sdlWindow)
            } else {
                SDL_HideWindow(sdlWindow)
            }
        }
    }

    public var rawView: UnsafeMutableRawPointer? {
        nil
    }
}

extension SDLView: DesktopView {
    public var position: Offset {
        get {
            var x: Int32 = 0
            var y: Int32 = 0
            SDL_GetWindowPosition(sdlWindow, &x, &y)
            return Offset(Float(x), Float(y))
        }
        set {
            SDL_SetWindowPosition(sdlWindow, Int32(newValue.dx), Int32(newValue.dy))
        }
    }

    public var displayID: DisplayID {
        return DisplayID(SDL_GetDisplayForWindow(sdlWindow))
    }

    public var alwaysOnTop: Bool {
        get {
            let SDL_WINDOW_ALWAYS_ON_TOP: Uint64 = 0x0000_0000_0001_0000
            let flags = SDL_GetWindowFlags(sdlWindow)
            return (flags & SDL_WINDOW_ALWAYS_ON_TOP) != 0
        }
        set {
            SDL_SetWindowAlwaysOnTop(sdlWindow, newValue)
        }
    }
}

// typedef bool (SDLCALL * SDL_EventFilter) (void *userdata, SDL_Event * event);
private func sdlEventWatcher(
    userdata: UnsafeMutableRawPointer?,
    event: UnsafeMutablePointer<SDL_Event>?
) -> Bool {
    let view = Unmanaged<SDLView>.fromOpaque(userdata!).takeUnretainedValue()
    return view.handleEventSync(&event!.pointee)
}

#if canImport(AppKit)
    import AppKit

    extension SDLView: MacOSView {
        public var nsWindow: NSWindow? {
            let ptr = SDL_GetPointerProperty(
                SDL_GetWindowProperties(sdlWindow),
                SDL_PROP_WINDOW_COCOA_WINDOW_POINTER,
                nil
            )
            guard let ptr else {
                return nil
            }
            return Unmanaged<NSWindow>.fromOpaque(ptr).takeUnretainedValue()
        }
    }

#endif
