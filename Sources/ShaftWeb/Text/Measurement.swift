// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import JavaScriptKit
import Shaft

// TODO(yjbanov): this is a hack we use to compute ideographic baseline; this
//                number is the ratio ideographic/alphabetic for font Ahem,
//                which matches the Flutter number. It may be completely wrong
//                for any other font. We'll need to eventually fix this. That
//                said Flutter doesn't seem to use ideographic baseline for
//                anything as of this writing.
let baselineRatioHack: Float = 1.1662499904632568

/// Hosts ruler DOM elements in a hidden container under [DomManager.renderingHost].
class RulerHost {
    init() {
        let style = _rulerHost.style.object!
        style.position = "fixed"
        style.visibility = "hidden"
        style.overflow = "hidden"
        style.top = "0"
        style.left = "0"
        style.width = "0"
        style.height = "0"

        // TODO(mdebbar): There could be multiple views with multiple rendering hosts.
        //                https://github.com/flutter/flutter/issues/137344
        // let renderingHost = EnginePlatformDispatcher.instance.implicitView!.dom.renderingHost
        let renderingHost = domDocument.body.object!
        let _ = renderingHost.appendChild!(_rulerHost)
        // registerHotRestartListener(dispose)
    }

    /// Hosts a cache of rulers that measure text.
    ///
    /// This element exists purely for organizational purposes. Otherwise the
    /// rulers would be attached to the `<body>` element polluting the element
    /// tree and making it hard to navigate. It does not serve any functional
    /// purpose.
    private let _rulerHost = domDocument.createElement("flt-ruler-host")

    /// Releases the resources used by this [RulerHost].
    ///
    /// After this is called, this object is no longer usable.
    func dispose() {
        let _ = _rulerHost.remove()
    }

    /// Adds an element used for measuring text as a child of [_rulerHost].
    func addElement(_ element: JSObject) {
        let _ = _rulerHost.append(element)
    }
}

// These global variables are used to memoize calls to [measureSubstring]. They
// are used to remember the last arguments passed to it, and the last return
// value.
// They are being initialized so that the compiler knows they'll never be null.
private var _lastStart = TextIndex(utf16Offset: -1)
private var _lastEnd = TextIndex(utf16Offset: -1)
private var _lastText = ""
private var _lastCssFont = ""
private var _lastWidth: Float = -1.0

/// Measures the width of the substring of [text] starting from the index
/// [start] (inclusive) to [end] (exclusive).
///
/// This method assumes that the correct font has already been set on
/// [canvasContext].
func measureSubstring(
    _ canvasContext: JSValue,
    _ text: String,
    _ start: TextIndex,
    _ end: TextIndex,
    letterSpacing: Float? = nil
) -> Float {
    assert(start >= .zero)
    assert(start <= end)
    assert(end <= TextIndex(utf16Offset: text.utf16.count))

    if start == end {
        return 0
    }

    let cssFont = canvasContext.font.string!
    var width: Float

    // TODO(mdebbar): Explore caching all widths in a map, not only the last one.
    if start == _lastStart && end == _lastEnd && text == _lastText && cssFont == _lastCssFont {
        // Reuse the previously calculated width if all factors that affect width
        // are unchanged. The only exception is letter-spacing. We always add
        // letter-spacing to the width later below.
        width = _lastWidth
    } else {
        let sub =
            start == .zero && end == TextIndex(utf16Offset: text.utf16.count)
            ? text
            : (start..<end).textInside(text)
        width = Float(canvasContext.measureText(sub).width.number!)
    }

    _lastStart = start
    _lastEnd = end
    _lastText = text
    _lastCssFont = cssFont
    _lastWidth = width

    // Now add letter spacing to the width.
    let effectiveLetterSpacing = letterSpacing ?? 0.0
    if effectiveLetterSpacing != 0.0 {
        width += effectiveLetterSpacing * Float((end - start).utf16Offset)
    }

    // What we are doing here is we are rounding to the nearest 2nd decimal
    // point. So 39.999423 becomes 40, and 11.243982 becomes 11.24.
    // The reason we are doing this is because we noticed that canvas API has a
    // ±0.001 error margin.
    return _roundWidth(width)
}

private func _roundWidth(_ width: Float) -> Float {
    return (width * 100).rounded() / 100
}
