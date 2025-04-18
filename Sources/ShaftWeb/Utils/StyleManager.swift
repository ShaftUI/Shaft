// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import JavaScriptKit
import Shaft

/// Manages the CSS styles of the Flutter View.
class StyleManager {
    static let defaultFontStyle = "normal"
    static let defaultFontWeight = "normal"
    static let defaultFontSize = Float(14.0)
    static let defaultFontFamily = "sans-serif"
    static let defaultCssFont =
        "\(defaultFontStyle) \(defaultFontWeight) \(Int(defaultFontSize))px \(defaultFontFamily)"

    //     static func attachGlobalStyles(
    //         node: DomNode,
    //         styleId: String,
    //         styleNonce: String?,
    //         cssSelectorPrefix: String
    //     ) {
    //         let styleElement = createDomHTMLStyleElement(styleNonce)
    //         styleElement.id = styleId
    //         // The style element must be appended to the DOM, or its `sheet` will be null later.
    //         node.appendChild(styleElement)
    //         applyGlobalCssRulesToSheet(
    //             styleElement,
    //             defaultCssFont: StyleManager.defaultCssFont,
    //             cssSelectorPrefix: cssSelectorPrefix
    //         )
    //     }

    //     static func styleSceneHost(
    //         _ sceneHost: DomElement,
    //         debugShowSemanticsNodes: Bool = false
    //     ) {
    //         assert(sceneHost.tagName.toLowerCase() == DomManager.sceneHostTagName.toLowerCase())
    //         // Don't allow the scene to receive pointer events.
    //         sceneHost.style.pointerEvents = "none"
    //         // When debugging semantics, make the scene semi-transparent so that the
    //         // semantics tree is more prominent.
    //         if debugShowSemanticsNodes {
    //             sceneHost.style.opacity = "0.3"
    //         }
    //     }

    //     static func styleSemanticsHost(
    //         _ semanticsHost: DomElement,
    //         _ devicePixelRatio: Double
    //     ) {
    //         assert(semanticsHost.tagName.toLowerCase() == DomManager.semanticsHostTagName.toLowerCase())
    //         semanticsHost.style.position = "absolute"
    //         semanticsHost.style.transformOrigin = "0 0 0"
    //         scaleSemanticsHost(semanticsHost, devicePixelRatio)
    //     }

    //     /// The framework specifies semantics in physical pixels, but CSS uses
    //     /// logical pixels. To compensate, an inverse scale is injected at the root
    //     /// level.
    //     static func scaleSemanticsHost(
    //         _ semanticsHost: DomElement,
    //         _ devicePixelRatio: Double
    //     ) {
    //         assert(semanticsHost.tagName.toLowerCase() == DomManager.semanticsHostTagName.toLowerCase())
    //         semanticsHost.style.transform = "scale(\(1 / devicePixelRatio))"
    //     }
    // }

    // /// Applies the required global CSS to an incoming [DomCSSStyleSheet] `sheet`.
    // @visibleForTesting
    // func applyGlobalCssRulesToSheet(
    //     _ styleElement: DomHTMLStyleElement,
    //     cssSelectorPrefix: String = "",
    //     defaultCssFont: String
    // ) {
    //     styleElement.appendText(
    //         // Fixes #115216 by ensuring that our parameters only affect the flt-scene-host children.
    //         "\(cssSelectorPrefix) \(DomManager.sceneHostTagName) {" + "  font: \(defaultCssFont);" + "}"

    //             // This undoes browser's default painting and layout attributes of range
    //             // input, which is used in semantics.
    //             + "\(cssSelectorPrefix) flt-semantics input[type=range] {" + "  appearance: none;"
    //             + "  -webkit-appearance: none;" + "  width: 100%;" + "  position: absolute;"
    //             + "  border: none;" + "  top: 0;" + "  right: 0;" + "  bottom: 0;" + "  left: 0;" + "}"

    //             // The invisible semantic text field may have a visible cursor and selection
    //             // highlight. The following 2 CSS rules force everything to be transparent.
    //             + "\(cssSelectorPrefix) input::selection {" + "  background-color: transparent;" + "}"
    //             + "\(cssSelectorPrefix) textarea::selection {" + "  background-color: transparent;"
    //             + "}" +

    //             "\(cssSelectorPrefix) flt-semantics input,"
    //             + "\(cssSelectorPrefix) flt-semantics textarea,"
    //             + "\(cssSelectorPrefix) flt-semantics [contentEditable=\"true\"] {"
    //             + "  caret-color: transparent;" + "}"

    //             // Hide placeholder text
    //             + "\(cssSelectorPrefix) .flt-text-editing::placeholder {" + "  opacity: 0;" + "}"

    //             // Hide outline when the flutter-view root element is focused.
    //             + "\(cssSelectorPrefix):focus {" + " outline: none;" + "}"
    //     )

    //     // By default on iOS, Safari would highlight the element that's being tapped
    //     // on using gray background. This CSS rule disables that.
    //     if isSafari {
    //         styleElement.appendText(
    //             "\(cssSelectorPrefix) * {" + "  -webkit-tap-highlight-color: transparent;" + "}" +

    //                 "\(cssSelectorPrefix) flt-semantics input[type=range]::-webkit-slider-thumb {"
    //                 + "  -webkit-appearance: none;" + "}"
    //         )
    //     }

    //     if isFirefox {
    //         // For firefox set line-height, otherwise text at same font-size will
    //         // measure differently in ruler.
    //         //
    //         // - See: https://github.com/flutter/flutter/issues/44803
    //         styleElement.appendText(
    //             "\(cssSelectorPrefix) flt-paragraph," + "\(cssSelectorPrefix) flt-span {"
    //                 + "  line-height: 100%;" + "}"
    //         )
    //     }

    //     // This CSS makes the autofill overlay transparent in order to prevent it
    //     // from overlaying on top of Flutter-rendered text inputs.
    //     // See: https://github.com/flutter/flutter/issues/118337.
    //     if browserHasAutofillOverlay() {
    //         styleElement.appendText(
    //             "\(cssSelectorPrefix) .transparentTextEditing:-webkit-autofill,"
    //                 + "\(cssSelectorPrefix) .transparentTextEditing:-webkit-autofill:hover,"
    //                 + "\(cssSelectorPrefix) .transparentTextEditing:-webkit-autofill:focus,"
    //                 + "\(cssSelectorPrefix) .transparentTextEditing:-webkit-autofill:active {"
    //                 + "  opacity: 0 !important;" + "}"
    //         )
    //     }

    //     // Removes password reveal icon for text inputs in Edge browsers.
    //     // Non-Edge browsers will crash trying to parse -ms-reveal CSS selector,
    //     // so we guard it behind an isEdge check.
    //     // Fixes: https://github.com/flutter/flutter/issues/83695
    //     if isEdge {
    //         // We try-catch this, because in testing, we fake Edge via the UserAgent,
    //         // so the below will throw an exception (because only real Edge understands
    //         // the ::-ms-reveal pseudo-selector).
    //         do {
    //             styleElement.appendText(
    //                 "\(cssSelectorPrefix) input::-ms-reveal {" + "  display: none;" + "}"
    //             )
    //         } catch let e as DomException {
    //             // Browsers that don't understand ::-ms-reveal throw a DOMException
    //             // of type SyntaxError.
    //             domWindow.console.warn(e)
    //             // Add a fake rule if our code failed because we're under testing
    //             assert(
    //                 {
    //                     styleElement.appendText(
    //                         "\(cssSelectorPrefix) input.fallback-for-fakey-browser-in-ci {"
    //                             + "  display: none;" + "}"
    //                     )
    //                     return true
    //                 }()
    //             )
    //         }
    //     }
}
