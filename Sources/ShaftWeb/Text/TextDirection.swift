// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Shaft

enum FragmentFlow {
    /// The fragment flows from left to right regardless of its surroundings.
    case ltr
    /// The fragment flows from right to left regardless of its surroundings.
    case rtl
    /// The fragment flows the same as the previous fragment.
    ///
    /// If it's the first fragment in a line, then it flows the same as the
    /// paragraph direction.
    ///
    /// E.g. digits.
    case previous
    /// If the previous and next fragments flow in the same direction, then this
    /// fragment flows in that same direction. Otherwise, it flows the same as the
    /// paragraph direction.
    ///
    /// E.g. spaces, symbols.
    case sandwich
}

/// Splits [text] into fragments based on directionality.
class BidiFragmenter: TextFragmenter {
    init(_ text: String) {
        self.text = text
    }

    let text: String

    func fragment() -> [BidiFragment] {
        return _computeBidiFragments(text)
    }
}

class BidiFragment: TextFragment {
    init(
        _ start: TextIndex,
        _ end: TextIndex,
        _ textDirection: TextDirection?,
        _ fragmentFlow: FragmentFlow
    ) {
        self.textDirection = textDirection
        self.fragmentFlow = fragmentFlow
        self.start = start
        self.end = end
    }

    let start: TextIndex
    let end: TextIndex
    let textDirection: TextDirection?
    let fragmentFlow: FragmentFlow
}

// This data was taken from the source code of the Closure library:
//
// - https://github.com/google/closure-library/blob/9d24a6c1809a671c2e54c328897ebeae15a6d172/closure/goog/i18n/bidi.js#L203-L234
let _textDirectionLookup: UnicodePropertyLookup<TextDirection?> = {
    let ranges: [UnicodeRange<TextDirection?>] = [
        // LTR
        UnicodeRange(0x41, 0x5A, .ltr),  // A-Z
        UnicodeRange(0x61, 0x7A, .ltr),  // a-z
        UnicodeRange(0x00C0, 0x00D6, .ltr),
        UnicodeRange(0x00D8, 0x00F6, .ltr),
        UnicodeRange(0x00F8, 0x02B8, .ltr),
        UnicodeRange(0x0300, 0x0590, .ltr),
        // RTL
        UnicodeRange(0x0591, 0x06EF, .rtl),
        UnicodeRange(0x06FA, 0x08FF, .rtl),
        // LTR
        UnicodeRange(0x0900, 0x1FFF, .ltr),
        UnicodeRange(0x200E, 0x200E, .ltr),
        // RTL
        UnicodeRange(0x200F, 0x200F, .rtl),
        // LTR
        UnicodeRange(0x2C00, 0xD801, .ltr),
        // RTL
        UnicodeRange(0xD802, 0xD803, .rtl),
        // LTR
        UnicodeRange(0xD804, 0xD839, .ltr),
        // RTL
        UnicodeRange(0xD83A, 0xD83B, .rtl),
        // LTR
        UnicodeRange(0xD83C, 0xDBFF, .ltr),
        UnicodeRange(0xF900, 0xFB1C, .ltr),
        // RTL
        UnicodeRange(0xFB1D, 0xFDFF, .rtl),
        // LTR
        UnicodeRange(0xFE00, 0xFE6F, .ltr),
        // RTL
        UnicodeRange(0xFE70, 0xFEFC, .rtl),
        // LTR
        UnicodeRange(0xFEFD, 0xFFFF, .ltr),
    ]
    return UnicodePropertyLookup(ranges, nil)
}()

func _computeBidiFragments(_ text: String) -> [BidiFragment] {
    var fragments = [BidiFragment]()

    if text.isEmpty {
        fragments.append(
            BidiFragment(
                .zero,
                .zero,
                nil,
                .previous
            )
        )
        return fragments
    }

    var fragmentStart = TextIndex.zero
    var textDirection = _getTextDirection(text, .zero)
    var fragmentFlow = _getFragmentFlow(text, .zero)

    for i in 1..<text.utf16.count {
        let charTextDirection = _getTextDirection(text, TextIndex(utf16Offset: i))

        if charTextDirection != textDirection {
            // We've reached the end of a text direction fragment.
            fragments.append(
                BidiFragment(
                    fragmentStart,
                    TextIndex(utf16Offset: i),
                    textDirection,
                    fragmentFlow
                )
            )
            fragmentStart = TextIndex(utf16Offset: i)
            textDirection = charTextDirection

            fragmentFlow = _getFragmentFlow(text, TextIndex(utf16Offset: i))
        } else {
            // This code handles the case of a sequence of digits followed by a sequence
            // of LTR characters with no space in between.
            if fragmentFlow == .previous {
                fragmentFlow = _getFragmentFlow(text, TextIndex(utf16Offset: i))
            }
        }
    }

    fragments.append(
        BidiFragment(
            fragmentStart,
            TextIndex(utf16Offset: text.utf16.count),
            textDirection,
            fragmentFlow
        )
    )
    return fragments
}

func _getTextDirection(_ text: String, _ i: TextIndex) -> TextDirection? {
    let codePoint = getCodePoint(text, i)!
    if _isDigit(codePoint) || _isMashriqiDigit(codePoint) {
        // A sequence of regular digits or Mashriqi digits always goes from left to right
        // regardless of their fragment flow direction.
        return .ltr
    }

    let textDirection = _textDirectionLookup.findForChar(codePoint)
    if textDirection != nil {
        return textDirection
    }

    return nil
}

func _getFragmentFlow(_ text: String, _ i: TextIndex) -> FragmentFlow {
    let codePoint = getCodePoint(text, i)!
    if _isDigit(codePoint) {
        return .previous
    }
    if _isMashriqiDigit(codePoint) {
        return .rtl
    }

    let textDirection = _textDirectionLookup.findForChar(codePoint)
    switch textDirection {
    case .ltr:
        return .ltr
    case .rtl:
        return .rtl
    case nil:
        return .sandwich
    }
}

func _isDigit(_ codePoint: Int) -> Bool {
    return codePoint >= kChar_0 && codePoint <= kChar_9
}

func _isMashriqiDigit(_ codePoint: Int) -> Bool {
    return codePoint >= kMashriqi_0 && codePoint <= kMashriqi_9
}
