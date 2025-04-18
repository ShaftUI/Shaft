import Foundation
import JavaScriptKit
import Shaft

let domDocument = JSObject.global.document

func buildCssFontString(
    fontStyle: FontStyle?,
    fontWeight: FontWeight?,
    fontSize: Float?,
    fontFamilies: [String]
) -> String {
    let cssFontStyle = fontStyle?.toCssString() ?? StyleManager.defaultFontStyle
    let cssFontWeight = fontWeight?.toCssString() ?? StyleManager.defaultFontWeight
    let cssFontSize = Int(floor(fontSize ?? StyleManager.defaultFontSize))
    let cssFontFamily = canonicalizeFontFamily(fontFamilies)

    return "\(cssFontStyle) \(cssFontWeight) \(cssFontSize)px \(cssFontFamily)"
}

/// Contains all styles that have an effect on the height of text.
///
/// This is useful as a cache key for [TextHeightRuler].
struct TextHeightStyle: Equatable, Hashable {
    let fontFamilies: [String]
    let fontSize: Float
    let height: Float?
    // let fontFeatures: [FontFeature]?
    // let fontVariations: [FontVariation]?

    init(
        fontFamilies: [String],
        fontSize: Float,
        height: Float?,
        // fontFeatures: [FontFeature]?,
        // fontVariations: [FontVariation]?
    ) {
        self.fontFamilies = fontFamilies
        self.fontSize = fontSize
        self.height = height
        // self.fontFeatures = fontFeatures
        // self.fontVariations = fontVariations
    }

}

/// Provides text dimensions found on [_element]. The idea behind this class is
/// to allow the [ParagraphRuler] to mutate multiple dom elements and allow
/// consumers to lazily read the measurements.
///
/// The [ParagraphRuler] would have multiple instances of [TextDimensions] with
/// different backing elements for different types of measurements. When a
/// measurement is needed, the [ParagraphRuler] would mutate all the backing
/// elements at once. The consumer of the ruler can later read those
/// measurements.
///
/// The rationale behind this is to minimize browser reflows by batching dom
/// writes first, then performing all the reads.
class TextDimensions {
    fileprivate var _element: JSObject
    private var _cachedBoundingClientRect: JSObject?

    init(_ element: JSObject) {
        self._element = element
    }

    private func _invalidateBoundsCache() {
        _cachedBoundingClientRect = nil
    }

    func forceSingleLine() {
        _element.style.object!.whiteSpace = "pre"
    }

    /// Sets text of contents to a single space character to measure empty text.
    func updateTextToSpace() {
        _invalidateBoundsCache()
        _element.textContent = " "
    }

    func applyHeightStyle(_ textHeightStyle: TextHeightStyle) {
        let fontFamilies = textHeightStyle.fontFamilies
        let fontSize = textHeightStyle.fontSize
        let style = _element.style.object!
        style.fontSize = .string("\(Int(floor(fontSize)))px")
        style.fontFamily = .string(canonicalizeFontFamily(fontFamilies))

        let height = textHeightStyle.height
        // Workaround the rounding introduced by https://github.com/flutter/flutter/issues/122066
        // in tests.
        let effectiveLineHeight = height ?? (fontFamilies.first == "FlutterTest" ? 1.0 : nil)
        if let effectiveLineHeight = effectiveLineHeight {
            style.lineHeight = .string(effectiveLineHeight.description)
        }
        _invalidateBoundsCache()
    }

    /// Appends element and probe to hostElement that is set up for a specific
    /// TextStyle.
    func appendToHost(_ hostElement: JSObject) {
        let _ = hostElement.append!(_element)
        _invalidateBoundsCache()
    }

    private func _readAndCacheMetrics() -> JSObject {
        if let cached = _cachedBoundingClientRect {
            return cached
        }
        let rect = _element.getBoundingClientRect!().object!
        _cachedBoundingClientRect = rect
        return rect
    }

    /// The height of the paragraph being measured.
    var height: Double {
        var cachedHeight = _readAndCacheMetrics().height.number!
        if browser.browserEngine == BrowserEngine.firefox {
            // See subpixel rounding bug :
            // https://bugzilla.mozilla.org/show_bug.cgi?id=442139
            // This causes bottom of letters such as 'y' to be cutoff and
            // incorrect rendering of double underlines.
            cachedHeight += 1.0
        }
        return cachedHeight
    }
}

/// Performs height measurement for the given [textHeightStyle].
///
/// The two results of this ruler's measurement are:
///
/// 1. [alphabeticBaseline].
/// 2. [height].
class TextHeightRuler {
    let textHeightStyle: TextHeightStyle
    let rulerHost: RulerHost

    // Elements used to measure the line-height metric.
    private lazy var _probe: JSObject = _createProbe()
    private lazy var _host: JSObject = _createHost()
    private let _dimensions = TextDimensions(
        JSObject.global.document.createElement("flt-paragraph").object!
    )

    /// The alphabetic baseline for this ruler's [textHeightStyle].
    lazy var alphabeticBaseline: Float = Float(
        _probe.getBoundingClientRect!().object!.bottom.number!
    )

    /// The height for this ruler's [textHeightStyle].
    lazy var height: Float = Float(_dimensions.height)

    init(_ textHeightStyle: TextHeightStyle, _ rulerHost: RulerHost) {
        self.textHeightStyle = textHeightStyle
        self.rulerHost = rulerHost
    }

    /// Disposes of this ruler and detaches it from the DOM tree.
    func dispose() {
        let _ = _host.remove!()
    }

    private func _createHost() -> JSObject {
        let host = createDomHTMLDivElement().object!
        let style = host.style.object!
        style.visibility = "hidden"
        style.position = "absolute"
        style.top = "0"
        style.left = "0"
        style.display = "flex"
        style.flexDirection = "row"
        style.alignItems = "baseline"
        style.margin = "0"
        style.border = "0"
        style.padding = "0"

        assert(
            {
                let _ = host.setAttribute!("data-ruler", "line-height")
                return true
            }()
        )

        _dimensions.applyHeightStyle(textHeightStyle)

        // Force single-line (even if wider than screen) and preserve whitespaces.
        _dimensions.forceSingleLine()

        // To measure line-height, all we need is a whitespace.
        _dimensions.updateTextToSpace()

        _dimensions.appendToHost(host)

        rulerHost.addElement(host)
        return host
    }

    private func _createProbe() -> JSObject {
        let probe = createDomHTMLDivElement().object!
        let _ = _host.append!(probe)
        return probe
    }
}
