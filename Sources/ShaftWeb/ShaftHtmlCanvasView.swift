import JavaScriptKit
import Shaft
import SwiftMath

public class ShaftCanvasView: Shaft.NativeView {
    public init(viewID: Int, canvasElement: JSValue) {
        self.viewID = viewID
        self.canvasElement = canvasElement
    }

    public let viewID: Int

    public var devicePixelRatio: Float {
        Float(JSObject.global.window.devicePixelRatio.number!)
    }

    public var canvasElement: JSValue

    public var physicalSize: Shaft.ISize {
        let width = canvasElement.width.number!
        let height = canvasElement.height.number!
        return Shaft.ISize(Int(width), Int(height))
    }

    lazy private var context = canvasElement.getContext("2d")
    lazy private var canvas = Canvas2DCanvas(context)

    public func render(_ layerTree: Shaft.LayerTree) {
        // dump(layerTree)

        let _ = context.setTransform(1, 0, 0, 1, 0, 0)
        let _ = context.clearRect(0, 0, canvasElement.width, canvasElement.height)

        layerTree.paint(
            context: LayerPaintContext(canvas: canvas)
        )
    }

    public func startTextInput() {

    }

    public func stopTextInput() {

    }

    public func setComposingRect(_ rect: Shaft.Rect) {

    }

    public func setEditableSizeAndTransform(_ size: Shaft.Size, _ transform: SwiftMath.Matrix4x4f) {

    }

    public var textInputActive: Bool { false }

    public var onTextEditing: Shaft.TextEditingCallback?

    public var onTextComposed: Shaft.TextComposedCallback?

    public var title: String {
        get { "" }
        set {}
    }
}

class Canvas2DCanvas: Canvas {
    public init(_ renderingContext2D: JSValue) {
        self.renderingContext2D = renderingContext2D
        JSObject.global.console.log(renderingContext2D)
    }

    public var renderingContext2D: JSValue

    private var saveCount = 0

    func applyPaint(_ paint: Shaft.Paint) {
        renderingContext2D.strokeStyle = .string(paint.color.toCSS())
        renderingContext2D.fillStyle = .string(paint.color.toCSS())
        renderingContext2D.lineWidth = .number(Double(paint.strokeWidth))
        renderingContext2D.filter = .string(paint.maskFilter?.toCSS() ?? "")
    }

    func getSaveCount() -> Int {
        saveCount
    }

    func save() {
        saveCount += 1
        let _ = renderingContext2D.save()
    }

    func saveLayer(_ bounds: Shaft.Rect, paint: Shaft.Paint?) {
        saveCount += 1
        save()
    }

    func restore() {
        saveCount -= 1
        let _ = renderingContext2D.restore()
        cachedLastCssFont = nil
    }

    func translate(_ dx: Float, _ dy: Float) {
        let _ = renderingContext2D.translate(dx, dy)
    }

    func scale(_ sx: Float, _ sy: Float) {
        let _ = renderingContext2D.scale(sx, sy)
    }

    func transform(_ transform: SwiftMath.Matrix4x4f) {
        let _ = renderingContext2D.transform(
            transform[0, 0],
            transform[1, 0],
            transform[0, 1],
            transform[1, 1],
            transform[0, 3],
            transform[1, 3]
        )
    }

    func clipRect(_ rect: Shaft.Rect, _ clipOp: Shaft.ClipOp, _ doAntiAlias: Bool) {
        let _ = renderingContext2D.beginPath()
        let _ = renderingContext2D.rect(rect.left, rect.top, rect.width, rect.height)
        let _ = renderingContext2D.clip()
    }

    func clipRRect(_ rrect: Shaft.RRect, _ doAntiAlias: Bool) {
        // let _ = renderingContext2D.beginPath()
        // let _ = renderingContext2D.clip()
    }

    func drawLine(_ p0: Shaft.Offset, _ p1: Shaft.Offset, _ paint: Shaft.Paint) {
        applyPaint(paint)
        let _ = renderingContext2D.beginPath()
        let _ = renderingContext2D.moveTo(p0.dx, p0.dy)
        let _ = renderingContext2D.lineTo(p1.dx, p1.dy)
        let _ = renderingContext2D.stroke()
    }

    func drawRect(_ rect: Shaft.Rect, _ paint: Shaft.Paint) {
        applyPaint(paint)

        if paint.style == .fill {
            let _ = renderingContext2D.fillRect(rect.left, rect.top, rect.width, rect.height)
        } else {
            let _ = renderingContext2D.strokeRect(rect.left, rect.top, rect.width, rect.height)
        }
    }

    func drawRRect(_ rrect: Shaft.RRect, _ paint: Shaft.Paint) {
        applyPaint(paint)

        let _ = renderingContext2D.beginPath()
        let _ = renderingContext2D.moveTo(rrect.left + rrect.tlRadiusX, rrect.top)
        let _ = renderingContext2D.lineTo(rrect.right - rrect.trRadiusX, rrect.top)
        let _ = renderingContext2D.arcTo(
            rrect.right,
            rrect.top,
            rrect.right,
            rrect.top + rrect.trRadiusY,
            rrect.trRadiusX
        )
        let _ = renderingContext2D.lineTo(rrect.right, rrect.bottom - rrect.brRadiusY)
        let _ = renderingContext2D.arcTo(
            rrect.right,
            rrect.bottom,
            rrect.right - rrect.brRadiusX,
            rrect.bottom,
            rrect.brRadiusY
        )
        let _ = renderingContext2D.lineTo(rrect.left + rrect.blRadiusX, rrect.bottom)
        let _ = renderingContext2D.arcTo(
            rrect.left,
            rrect.bottom,
            rrect.left,
            rrect.bottom - rrect.blRadiusY,
            rrect.blRadiusX
        )
        let _ = renderingContext2D.lineTo(rrect.left, rrect.top + rrect.tlRadiusY)
        let _ = renderingContext2D.arcTo(
            rrect.left,
            rrect.top,
            rrect.left + rrect.tlRadiusX,
            rrect.top,
            rrect.tlRadiusY
        )

        if paint.style == .fill {
            let _ = renderingContext2D.fill()
        } else {
            let _ = renderingContext2D.stroke()
        }

    }

    func drawDRRect(_ outer: Shaft.RRect, _ inner: Shaft.RRect, _ paint: Shaft.Paint) {

    }

    func drawCircle(_ center: Shaft.Offset, _ radius: Float, _ paint: Shaft.Paint) {
        applyPaint(paint)
        let _ = renderingContext2D.beginPath()
        let _ = renderingContext2D.arc(center.dx, center.dy, radius, 0, 2 * Double.pi)
        let _ = renderingContext2D.stroke()
    }

    func drawPath(_ path: any Shaft.Path, _ paint: Shaft.Paint) {

    }

    func drawImage(_ image: any Shaft.NativeImage, _ offset: Shaft.Offset, _ paint: Shaft.Paint) {
        // let _ = renderingContext2D.drawImage(image, offset.dx, offset.dy)
    }

    func drawImageRect(
        _ image: any Shaft.NativeImage,
        _ src: Shaft.Rect,
        _ dst: Shaft.Rect,
        _ paint: Shaft.Paint
    ) {

    }

    func drawImageNine(
        _ image: any Shaft.NativeImage,
        _ center: Shaft.Rect,
        _ dst: Shaft.Rect,
        _ paint: Shaft.Paint
    ) {

    }

    func drawParagraph(_ paragraph: any Shaft.Paragraph, _ offset: Shaft.Offset) {
        guard let paragraph = paragraph as? CanvasParagraph else {
            return
        }

        paragraph.paint(self, offset)
    }

    func drawTextBlob(_ blob: any Shaft.TextBlob, _ offset: Shaft.Offset, _ paint: Shaft.Paint) {

    }

    func clear(color: Shaft.Color) {
        let canvas = renderingContext2D.canvas.object!
        let _ = renderingContext2D.clearRect(0, 0, canvas.width, canvas.height)
    }

    private var cachedLastCssFont: String?

    func setCssFont(_ cssFont: String, textDirection: Shaft.TextDirection) {
        var ctx = renderingContext2D
        ctx.direction = .string(textDirection == .ltr ? "ltr" : "rtl")

        if cssFont != cachedLastCssFont {
            ctx.font = .string(cssFont)
            cachedLastCssFont = cssFont
        }
    }

    /// Draws text to the canvas starting at coordinate ([x], [y]).
    ///
    /// The text is drawn starting at coordinates ([x], [y]). It uses the current
    /// font set by the most recent call to [setCssFont].
    func drawText(
        _ text: String,
        _ x: Float,
        _ y: Float,
        style: Shaft.PaintingStyle? = nil,
        shadows: [Shaft.Shadow]? = nil
    ) {
        var ctx = renderingContext2D

        if let shadows = shadows {
            let _ = ctx.save()
            for shadow in shadows {
                ctx.shadowColor = .string(shadow.color.toCSS())
                ctx.shadowBlur = .number(Double(shadow.blurRadius))
                ctx.shadowOffsetX = .number(Double(shadow.offset.dx))
                ctx.shadowOffsetY = .number(Double(shadow.offset.dy))

                if style == .stroke {
                    let _ = ctx.strokeText(text, x, y)
                } else {
                    let _ = ctx.fillText(text, x, y)
                }
            }
            let _ = ctx.restore()
        }

        if style == .stroke {
            let _ = ctx.strokeText(text, x, y)
        } else {
            let _ = ctx.fillText(text, x, y)
        }
    }
}

extension Shaft.Color {
    func toCSS() -> String {
        "rgba(\(red), \(green), \(blue), \(Double(alpha) / 255))"
    }
}

extension Shaft.MaskFilter {
    func toCSS() -> String {
        return "blur(\(sigma * 2)px)"
    }
}
