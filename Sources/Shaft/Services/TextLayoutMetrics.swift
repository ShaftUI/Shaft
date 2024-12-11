// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A read-only interface for accessing visual information about the
/// implementing text.
public protocol TextLayoutMetrics {
    /// Return a [TextSelection] containing the line of the given [TextPosition].
    func getLineAtOffset(_ position: TextPosition) -> TextRange?

    /// Returns the [TextRange] of the word at the given [TextPosition].
    func getWordBoundary(_ position: TextPosition) -> TextRange

    /// Returns the TextPosition above the given offset into the text.
    ///
    /// If the offset is already on the first line, the given offset will be
    /// returned.
    func getTextPositionAbove(_ position: TextPosition) -> TextPosition

    /// Returns the TextPosition below the given offset into the text.
    ///
    /// If the offset is already on the last line, the given offset will be
    /// returned.
    func getTextPositionBelow(_ position: TextPosition) -> TextPosition
}

// TODO(gspencergoog): replace when we expose this ICU information.
/// Check if the given code unit is a white space or separator
/// character.
///
/// Includes newline characters from ASCII and separators from the
/// [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
internal func isWhitespace(_ codeUnit: Int) -> Bool {
    switch codeUnit {
    case 0x9,  // horizontal tab
        0xA,  // line feed
        0xB,  // vertical tab
        0xC,  // form feed
        0xD,  // carriage return
        0x1C,  // file separator
        0x1D,  // group separator
        0x1E,  // record separator
        0x1F,  // unit separator
        0x20,  // space
        0xA0,  // no-break space
        0x1680,  // ogham space mark
        0x2000,  // en quad
        0x2001,  // em quad
        0x2002,  // en space
        0x2003,  // em space
        0x2004,  // three-per-em space
        0x2005,  // four-er-em space
        0x2006,  // six-per-em space
        0x2007,  // figure space
        0x2008,  // punctuation space
        0x2009,  // thin space
        0x200A,  // hair space
        0x202F,  // narrow no-break space
        0x205F,  // medium mathematical space
        0x3000:  // ideographic space
        return true
    default:
        return false
    }
}

/// Check if the given code unit is a line terminator character.
///
/// Includes newline characters from ASCII
/// (https://www.unicode.org/standard/reports/tr13/tr13-5.html).
internal func isLineTerminator(_ codeUnit: Int) -> Bool {
    switch codeUnit {
    case 0x0A,  // line feed
        0x0B,  // vertical feed
        0x0C,  // form feed
        0x0D,  // carriage return
        0x85,  // new line
        0x2028,  // line separator
        0x2029:  // paragraph separator
        return true
    default:
        return false
    }
}
