import JavaScriptKit

func createDomHTMLDivElement() -> JSValue {
    return JSObject.global.document.createElement("div")
}

func createDomCanvasElement(width: Int, height: Int) -> JSValue {
    var canvas = JSObject.global.document.createElement("canvas")
    canvas.width = .number(Double(width))
    canvas.height = .number(Double(height))
    return canvas
}
