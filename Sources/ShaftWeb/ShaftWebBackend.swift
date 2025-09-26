import Foundation
import JavaScriptKit
import Shaft
import SwiftMath

public class ShaftWebBackend: Backend {
    private enum KeyEventPhase {
        case down
        case up
    }

    private struct KeyMetadata {
        let physical: Shaft.PhysicalKeyboardKey
        let logical: Shaft.LogicalKeyboardKey
    }

    public func destroyView(_ view: any Shaft.NativeView) {
        guard let canvasView = view as? ShaftCanvasView else { return }
        guard let removed = views.removeValue(forKey: canvasView.viewID) else { return }
        removeEventListeners(for: removed.viewID)
        removed.markDestroyed()
        let canvas = removed.canvasElement
        let _ = canvas.parentNode.object?.removeChild?(canvas)
    }

    public private(set) var lifecycleState: Shaft.AppLifecycleState = .resumed

    public var onAppLifecycleStateChanged: Shaft.AppLifecycleStateCallback?

    public var locales: [Shaft.Locale] {
        if let languages = JSObject.global.navigator.languages.object {
            var result: [Shaft.Locale] = []
            let length = Int(languages.length.number ?? 0)
            for index in 0..<length {
                guard let languageTag = languages[index].string else { continue }
                if let locale = Self.locale(from: languageTag) {
                    result.append(locale)
                }
            }

            if !result.isEmpty {
                return result
            }
        }

        if let language = JSObject.global.navigator.language.string,
            let locale = Self.locale(from: language)
        {
            return [locale]
        }

        return []
    }

    public init(onCreateElement: CreateCanvasCallback? = nil) {
        self.onCreateElement = onCreateElement
        registerVisibilityHandlers()
    }
    deinit {
        unregisterVisibilityHandlers()
    }

    private var nextViewID = 0
    private var views: [Int: ShaftCanvasView] = [:]
    private var pointerEventClosures: [Int: [String: JSClosure]] = [:]
    private var visibilityChangeClosure: JSClosure?
    private var focusClosure: JSClosure?
    private var blurClosure: JSClosure?
    private var keyDownClosure: JSClosure?
    private var keyUpClosure: JSClosure?

    public typealias CreateCanvasCallback = (Int) -> JSValue

    public let onCreateElement: CreateCanvasCallback?

    public func createView() -> (any Shaft.NativeView)? {
        let canvas = createCanvasElement()
        let view = ShaftCanvasView(
            viewID: nextViewID,
            canvasElement: canvas
        )

        nextViewID += 1
        views[view.viewID] = view
        addEventListeners(viewID: view.viewID, element: canvas)

        return view
    }

    private static func locale(from languageTag: String) -> Shaft.Locale? {
        let segments = languageTag.split(separator: "-")
        guard !segments.isEmpty else { return nil }
        let language = String(segments[0])
        var script: String?
        var region: String?

        if segments.count == 2 {
            let second = segments[1]
            if second.count == 4 {
                script = String(second)
            } else {
                region = String(second)
            }
        } else if segments.count >= 3 {
            script = String(segments[1])
            region = String(segments[2])
        }

        return Shaft.Locale(languageCode: language, scriptCode: script, countryCode: region)
    }

    private func createCanvasElement() -> JSValue {
        if let onCreateElement {
            return onCreateElement(nextViewID)
        }

        let document = JSObject.global.document
        let canvas = document.createElement("canvas")
        let _ = document.body.appendChild(canvas)
        return canvas
    }

    private func addEventListeners(viewID: Int, element: JSValue) {
        var closures: [String: JSClosure] = [:]

        let pointerDown = JSClosure { args in
            let event = args[0]
            let data = pointerEventToPointerData(event, viewID: viewID, change: .down)
            self.onPointerData?(data)
            return .undefined
        }
        closures["pointerdown"] = pointerDown
        let _ = element.addEventListener("pointerdown", pointerDown)

        let pointerMove = JSClosure { args in
            let event = args[0]
            let change: PointerChange =
                event.buttons.number == 0 ? .hover : .move
            let data = pointerEventToPointerData(event, viewID: viewID, change: change)
            self.onPointerData?(data)
            return .undefined
        }
        closures["pointermove"] = pointerMove
        let _ = element.addEventListener("pointermove", pointerMove)

        let pointerUp = JSClosure { args in
            let event = args[0]
            let data = pointerEventToPointerData(event, viewID: viewID, change: .up)
            self.onPointerData?(data)
            return .undefined
        }
        closures["pointerup"] = pointerUp
        let _ = element.addEventListener("pointerup", pointerUp)

        let passiveClause = JSObject.global.Object.function!.new()
        passiveClause.passive = .boolean(true)
        let wheel = JSClosure { args in
            let event = args[0]
            let data = scrollEventToPointerData(event, viewID: viewID)
            self.onPointerData?(data)
            return .undefined
        }
        closures["wheel"] = wheel
        let _ = element.addEventListener("wheel", wheel, passiveClause)

        pointerEventClosures[viewID] = closures
        ensureGlobalKeyboardHandlers()
    }

    private func removeEventListeners(for viewID: Int) {
        if let closures = pointerEventClosures.removeValue(forKey: viewID) {
            if let element = views[viewID]?.canvasElement {
                for (event, closure) in closures {
                    let _ = element.removeEventListener(event, closure)
                }
            }
        }

        if views.isEmpty {
            tearDownGlobalKeyboardHandlers()
        }
    }

    private func registerVisibilityHandlers() {
        let document = JSObject.global.document
        let window = JSObject.global.window

        visibilityChangeClosure = JSClosure { _ in
            self.handleVisibilityChange()
            return .undefined
        }
        if let visibilityChangeClosure {
            let _ = document.addEventListener("visibilitychange", visibilityChangeClosure)
        }

        focusClosure = JSClosure { _ in
            self.updateLifecycleState(.resumed)
            return .undefined
        }
        if let focusClosure {
            let _ = window.addEventListener("focus", focusClosure)
        }

        blurClosure = JSClosure { _ in
            self.updateLifecycleState(.inactive)
            return .undefined
        }
        if let blurClosure {
            let _ = window.addEventListener("blur", blurClosure)
        }
    }

    private func unregisterVisibilityHandlers() {
        let document = JSObject.global.document
        let window = JSObject.global.window

        if let visibilityChangeClosure {
            let _ = document.removeEventListener("visibilitychange", visibilityChangeClosure)
            self.visibilityChangeClosure = nil
        }

        if let focusClosure {
            let _ = window.removeEventListener("focus", focusClosure)
            self.focusClosure = nil
        }

        if let blurClosure {
            let _ = window.removeEventListener("blur", blurClosure)
            self.blurClosure = nil
        }

        tearDownGlobalKeyboardHandlers()
    }

    private func handleVisibilityChange() {
        guard let hidden = JSObject.global.document.hidden.boolean else { return }
        updateLifecycleState(hidden ? .hidden : .resumed)
    }

    private func ensureGlobalKeyboardHandlers() {
        guard keyDownClosure == nil && keyUpClosure == nil else { return }

        let keyDown = JSClosure { args in
            guard let event = args.first else { return .undefined }
            if self.dispatchKeyEvent(event, phase: .down) {
                let _ = event.preventDefault()
            }
            return .undefined
        }
        keyDownClosure = keyDown
        let _ = JSObject.global.window.addEventListener("keydown", keyDown)

        let keyUp = JSClosure { args in
            guard let event = args.first else { return .undefined }
            if self.dispatchKeyEvent(event, phase: .up) {
                let _ = event.preventDefault()
            }
            return .undefined
        }
        keyUpClosure = keyUp
        let _ = JSObject.global.window.addEventListener("keyup", keyUp)
    }

    private func tearDownGlobalKeyboardHandlers() {
        let window = JSObject.global.window

        if let keyDownClosure {
            let _ = window.removeEventListener("keydown", keyDownClosure)
            self.keyDownClosure = nil
        }

        if let keyUpClosure {
            let _ = window.removeEventListener("keyup", keyUpClosure)
            self.keyUpClosure = nil
        }
    }

    private func dispatchKeyEvent(_ event: JSValue, phase: KeyEventPhase) -> Bool {
        guard let keyEvent = keyEventFromJS(event, phase: phase) else { return false }
        return onKeyEvent?(keyEvent) ?? false
    }

    private func keyEventFromJS(_ event: JSValue, phase: KeyEventPhase) -> Shaft.KeyEvent? {
        guard let meta = Self.lookupKeyMetadata(event) else { return nil }

        let type: Shaft.KeyEventType =
            switch phase {
            case .down: .down
            case .up: .up
            }

        return Shaft.KeyEvent(
            type: type,
            physicalKey: meta.physical,
            logicalKey: meta.logical
        )
    }

    private static func lookupKeyMetadata(_ event: JSValue) -> KeyMetadata? {
        guard let code = event.code.string else { return nil }

        if let cached = keyCache[code] {
            return cached
        }

        if let mapping = codeToKeys[code] {
            keyCache[code] = mapping
            return mapping
        }

        if let key = event.key.string?.lowercased(), let mapping = keyToLogical[key] {
            keyCache[code] = mapping
            return mapping
        }

        return nil
    }

    private static let codeToKeys: [String: KeyMetadata] = {
        var mapping: [String: KeyMetadata] = [:]

        func add(
            _ code: String,
            _ physical: Shaft.PhysicalKeyboardKey,
            _ logical: Shaft.LogicalKeyboardKey
        ) {
            mapping[code] = KeyMetadata(physical: physical, logical: logical)
        }

        let letters: [(String, Shaft.PhysicalKeyboardKey, Shaft.LogicalKeyboardKey)] = [
            ("KeyA", .keyA, .keyA), ("KeyB", .keyB, .keyB), ("KeyC", .keyC, .keyC),
            ("KeyD", .keyD, .keyD), ("KeyE", .keyE, .keyE), ("KeyF", .keyF, .keyF),
            ("KeyG", .keyG, .keyG), ("KeyH", .keyH, .keyH), ("KeyI", .keyI, .keyI),
            ("KeyJ", .keyJ, .keyJ), ("KeyK", .keyK, .keyK), ("KeyL", .keyL, .keyL),
            ("KeyM", .keyM, .keyM), ("KeyN", .keyN, .keyN), ("KeyO", .keyO, .keyO),
            ("KeyP", .keyP, .keyP), ("KeyQ", .keyQ, .keyQ), ("KeyR", .keyR, .keyR),
            ("KeyS", .keyS, .keyS), ("KeyT", .keyT, .keyT), ("KeyU", .keyU, .keyU),
            ("KeyV", .keyV, .keyV), ("KeyW", .keyW, .keyW), ("KeyX", .keyX, .keyX),
            ("KeyY", .keyY, .keyY), ("KeyZ", .keyZ, .keyZ),
        ]

        for entry in letters { add(entry.0, entry.1, entry.2) }

        let digits: [(String, Shaft.PhysicalKeyboardKey, Shaft.LogicalKeyboardKey)] = [
            ("Digit0", .digit0, .digit0), ("Digit1", .digit1, .digit1),
            ("Digit2", .digit2, .digit2), ("Digit3", .digit3, .digit3),
            ("Digit4", .digit4, .digit4), ("Digit5", .digit5, .digit5),
            ("Digit6", .digit6, .digit6), ("Digit7", .digit7, .digit7),
            ("Digit8", .digit8, .digit8), ("Digit9", .digit9, .digit9),
        ]

        for entry in digits { add(entry.0, entry.1, entry.2) }

        let navigation: [(String, Shaft.PhysicalKeyboardKey, Shaft.LogicalKeyboardKey)] = [
            ("Enter", .enter, .enter), ("Space", .space, .space),
            ("Backspace", .backspace, .backspace), ("Tab", .tab, .tab),
            ("Escape", .escape, .escape), ("ArrowUp", .arrowUp, .arrowUp),
            ("ArrowDown", .arrowDown, .arrowDown), ("ArrowLeft", .arrowLeft, .arrowLeft),
            ("ArrowRight", .arrowRight, .arrowRight), ("Home", .home, .home),
            ("End", .end, .end), ("PageUp", .pageUp, .pageUp),
            ("PageDown", .pageDown, .pageDown), ("Delete", .delete, .delete),
            ("Insert", .insert, .insert),
        ]

        for entry in navigation { add(entry.0, entry.1, entry.2) }

        let modifiers: [(String, Shaft.PhysicalKeyboardKey, Shaft.LogicalKeyboardKey)] = [
            ("ShiftLeft", .shiftLeft, .shiftLeft), ("ShiftRight", .shiftRight, .shiftRight),
            ("ControlLeft", .controlLeft, .controlLeft),
            ("ControlRight", .controlRight, .controlRight), ("AltLeft", .altLeft, .altLeft),
            ("AltRight", .altRight, .altRight), ("MetaLeft", .metaLeft, .metaLeft),
            ("MetaRight", .metaRight, .metaRight), ("CapsLock", .capsLock, .capsLock),
        ]

        for entry in modifiers { add(entry.0, entry.1, entry.2) }

        let symbols: [(String, Shaft.PhysicalKeyboardKey, Shaft.LogicalKeyboardKey)] = [
            ("Minus", .minus, .minus), ("Equal", .equal, .equal),
            ("BracketLeft", .bracketLeft, .bracketLeft),
            ("BracketRight", .bracketRight, .bracketRight),
            ("Backslash", .backslash, .backslash), ("Semicolon", .semicolon, .semicolon),
            ("Quote", .quote, .quote), ("Backquote", .backquote, .backquote),
            ("Comma", .comma, .comma), ("Period", .period, .period),
            ("Slash", .slash, .slash),
        ]

        for entry in symbols { add(entry.0, entry.1, entry.2) }

        let numpad: [(String, Shaft.PhysicalKeyboardKey, Shaft.LogicalKeyboardKey)] = [
            ("NumpadEnter", .numpadEnter, .numpadEnter), ("NumpadAdd", .numpadAdd, .numpadAdd),
            ("NumpadSubtract", .numpadSubtract, .numpadSubtract),
            ("NumpadMultiply", .numpadMultiply, .numpadMultiply),
            ("NumpadDivide", .numpadDivide, .numpadDivide),
            ("NumpadDecimal", .numpadDecimal, .numpadDecimal),
            ("Numpad0", .numpad0, .numpad0), ("Numpad1", .numpad1, .numpad1),
            ("Numpad2", .numpad2, .numpad2), ("Numpad3", .numpad3, .numpad3),
            ("Numpad4", .numpad4, .numpad4), ("Numpad5", .numpad5, .numpad5),
            ("Numpad6", .numpad6, .numpad6), ("Numpad7", .numpad7, .numpad7),
            ("Numpad8", .numpad8, .numpad8), ("Numpad9", .numpad9, .numpad9),
        ]

        for entry in numpad { add(entry.0, entry.1, entry.2) }

        return mapping
    }()

    private static let keyToLogical: [String: KeyMetadata] = {
        var mapping: [String: KeyMetadata] = [:]

        func add(
            _ key: String,
            _ physical: Shaft.PhysicalKeyboardKey,
            _ logical: Shaft.LogicalKeyboardKey
        ) {
            mapping[key] = KeyMetadata(physical: physical, logical: logical)
        }

        let singleChars: [(String, Shaft.PhysicalKeyboardKey, Shaft.LogicalKeyboardKey)] = [
            (" ", .space, .space), ("-", .minus, .minus), ("=", .equal, .equal),
            (",", .comma, .comma), (".", .period, .period), (";", .semicolon, .semicolon),
            ("'", .quote, .quote), ("/", .slash, .slash), ("\\", .backslash, .backslash),
            ("[", .bracketLeft, .bracketLeft), ("]", .bracketRight, .bracketRight),
            ("`", .backquote, .backquote),
        ]

        for entry in singleChars { add(entry.0, entry.1, entry.2) }

        let namedKeys: [(String, Shaft.PhysicalKeyboardKey, Shaft.LogicalKeyboardKey)] = [
            ("enter", .enter, .enter), ("backspace", .backspace, .backspace), ("tab", .tab, .tab),
            ("escape", .escape, .escape), ("delete", .delete, .delete), ("home", .home, .home),
            ("end", .end, .end), ("pageup", .pageUp, .pageUp), ("pagedown", .pageDown, .pageDown),
            ("insert", .insert, .insert), ("arrowup", .arrowUp, .arrowUp),
            ("arrowdown", .arrowDown, .arrowDown),
            ("arrowleft", .arrowLeft, .arrowLeft), ("arrowright", .arrowRight, .arrowRight),
        ]

        for entry in namedKeys { add(entry.0, entry.1, entry.2) }

        return mapping
    }()

    private static var keyCache: [String: KeyMetadata] = [:]

    private func updateLifecycleState(_ newState: Shaft.AppLifecycleState) {
        guard lifecycleState != newState else { return }
        lifecycleState = newState
        onAppLifecycleStateChanged?(newState)
    }

    public func view(_ viewId: Int) -> (any Shaft.NativeView)? {
        views[viewId]
    }

    public var renderer: any Shaft.Renderer { ShaftCanvas2DRenderer.shared }

    public var onPointerData: Shaft.PointerDataCallback?

    public var onKeyEvent: Shaft.KeyEventCallback?

    public func getKeyboardState() -> [Shaft.PhysicalKeyboardKey: Shaft.LogicalKeyboardKey]? {
        nil
    }

    public func launchUrl(_ url: String) -> Bool {
        let _ = JSObject.global.window.open(url, "_blank")
        return true
    }

    public var onMetricsChanged: Shaft.MetricsChangedCallback?

    public var onBeginFrame: Shaft.FrameCallback?

    public var onDrawFrame: Shaft.VoidCallback?

    public func scheduleFrame() {
        let _ = JSObject.global.requestAnimationFrame!(
            JSClosure { args in
                let elapsed = args[0].number!
                self.onBeginFrame?(Duration.milliseconds(elapsed))
                self.onDrawFrame?()
                return .undefined
            }
        )
    }

    public func scheduleReassemble() {
        updateLifecycleState(.resumed)
        onReassemble?()
    }

    public func run() {
        // no-op
    }

    public func stop() {
        // no-op
    }

    public var isMainThread: Bool {
        true
    }

    public func postTask(_ f: @escaping () -> Void) {
        let _ = JSObject.global.setTimeout!(
            JSClosure { _ in
                f()
                return .undefined
            },
            0
        )
    }

    public func createTimer(
        _ delay: Duration,
        repeat shouldRepeat: Bool,
        callback: @escaping () -> Void
    )
        -> any Shaft.Timer
    {
        ShaftWebTimer(delay: delay, repeats: shouldRepeat, callback: callback)
    }

    public var targetPlatform: Shaft.TargetPlatform? {
        nil
    }

    public func createCursor(_ cursor: Shaft.SystemMouseCursor) -> (any Shaft.NativeMouseCursor)? {
        nil
    }
}

public class ShaftCanvas2DRenderer: Renderer {
    public static let shared = ShaftCanvas2DRenderer()

    public func createParagraphBuilder(_ style: Shaft.ParagraphStyle) -> any Shaft.ParagraphBuilder
    {
        Canvas2DParagraphBuilder(style: style)
    }

    public func createTextBlob(
        _ glyphs: [Shaft.GlyphID],
        positions: [Shaft.Offset],
        font: any Shaft.Font
    ) -> any Shaft.TextBlob {
        shouldImplement()
    }

    public func decodeImageFromData(_ data: Data) -> (any Shaft.AnimatedImage)? {
        shouldImplement()

    }

    public func createPath() -> any Shaft.Path {
        shouldImplement()
    }

    public var fontCollection: any Shaft.FontCollection { ShaftWebFontCollection.shared }
}

private func pointerEventToPointerData(
    _ event: JSValue,
    viewID: Int,
    change: PointerChange = .none
)
    -> Shaft.PointerData
{
    let dpi = JSObject.global.devicePixelRatio.number!
    let x = event.offsetX.number!
    let y = event.offsetY.number!
    let kind: PointerDeviceKind =
        switch event.pointerType.string! {
        case "mouse": .mouse
        case "pen": .stylus
        case "touch": .touch
        default: .mouse
        }
    let button: PointerButtons =
        switch event.button.number! {
        case 0: .primaryButton
        case 1: .middleMouseButton
        case 2: .secondaryButton
        default: .primaryButton
        }
    return Shaft.PointerData(
        viewId: viewID,
        timeStamp: Duration.milliseconds(event.timeStamp.number!),
        change: change,
        kind: kind,
        device: Int(event.persistentDeviceId.number ?? 0),
        pointerIdentifier: Int(event.pointerId.number!),
        physicalX: Int(x * dpi),
        physicalY: Int(y * dpi),
        buttons: button,
    )
}

private func scrollEventToPointerData(
    _ event: JSValue,
    viewID: Int
) -> Shaft.PointerData {
    let dpi = JSObject.global.devicePixelRatio.number!
    let x = event.offsetX.number!
    let y = event.offsetY.number!
    let deltaX = event.deltaX.number!
    let deltaY = event.deltaY.number!

    return Shaft.PointerData(
        viewId: viewID,
        timeStamp: Duration.milliseconds(event.timeStamp.number!),
        change: .none,
        kind: .mouse,
        signalKind: .scroll,
        device: 0,
        pointerIdentifier: 0,
        physicalX: Int(x * dpi),
        physicalY: Int(y * dpi),
        buttons: .init(),
        scrollDeltaX: deltaX * dpi,
        scrollDeltaY: deltaY * dpi
    )
}
