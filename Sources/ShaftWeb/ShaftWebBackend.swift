import Foundation
import JavaScriptKit
import Shaft
import SwiftMath

public class ShaftWebBackend: Backend {
    public init(onCreateElement: CreateCanvasCallback? = nil) {
        self.onCreateElement = onCreateElement
    }

    private var nextViewID = 0
    private var views: [Int: ShaftCanvasView] = [:]

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
        let _ = element.addEventListener(
            "pointerdown",
            JSClosure { args in
                let event = args[0]
                let data = pointerEventToPointerData(event, viewID: viewID, change: .down)
                self.onPointerData?(data)
                return .undefined
            }
        )
        let _ = element.addEventListener(
            "pointermove",
            JSClosure { args in
                let event = args[0]
                let data = pointerEventToPointerData(event, viewID: viewID, change: .hover)
                self.onPointerData?(data)
                return .undefined
            }
        )
        let _ = element.addEventListener(
            "pointerup",
            JSClosure { args in
                let event = args[0]
                let data = pointerEventToPointerData(event, viewID: viewID, change: .up)
                self.onPointerData?(data)
                return .undefined
            }
        )

        let passiveClause = JSObject.global.Object.function!.new()
        passiveClause.passive = .boolean(true)
        let _ = element.addEventListener(
            "wheel",
            JSClosure { args in
                let event = args[0]
                let data = scrollEventToPointerData(event, viewID: viewID)
                self.onPointerData?(data)
                return .undefined
            },
            passiveClause
        )
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
        let _ = JSObject.global.window.open!(url, "_blank")
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

    public func createTimer(_ delay: Duration, _ f: @escaping () -> Void) -> any Shaft.Timer {
        ShaftWebTimer(delay: delay, f: f)
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
