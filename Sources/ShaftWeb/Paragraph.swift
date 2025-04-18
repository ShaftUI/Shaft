import Shaft

extension FontStyle {
    /// Converts a FontStyle value to its CSS equivalent.
    func toCssString() -> String {
        return self == .normal ? "normal" : "italic"
    }
}

extension FontWeight {
    /// Converts a FontWeight value to its CSS equivalent.
    func toCssString() -> String {
        return fontWeightIndexToCss(fontWeightIndex: index)
    }
}

extension SpanStyle {
    var effectiveFontFamily: [String] {
        if let fontFamilies, !fontFamilies.isEmpty {
            return fontFamilies
        }
        return [StyleManager.defaultFontFamily]
    }

    /// Font string to be used in CSS.
    ///
    /// See <https://developer.mozilla.org/en-US/docs/Web/CSS/font>.
    var cssFontString: String {
        return buildCssFontString(
            fontStyle: fontStyle,
            fontWeight: fontWeight,
            fontSize: fontSize,
            fontFamilies: effectiveFontFamily
        )
    }

    /// The height style for this span.
    var heightStyle: TextHeightStyle {
        return TextHeightStyle(
            fontFamilies: effectiveFontFamily,
            fontSize: fontSize ?? StyleManager.defaultFontSize,
            height: height
                // TODO: Add font features and variations when supported
        )
    }

}

func fontWeightIndexToCss(fontWeightIndex: Int = 3) -> String {
    switch fontWeightIndex {
    case 0:
        return "100"
    case 1:
        return "200"
    case 2:
        return "300"
    case 3:
        return "normal"
    case 4:
        return "500"
    case 5:
        return "600"
    case 6:
        return "bold"
    case 7:
        return "800"
    case 8:
        return "900"
    default:
        assertionFailure("Failed to convert font weight \(fontWeightIndex) to CSS.")
        return ""
    }
}
