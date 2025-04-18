// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Shaft

enum _FindBreakDirection {
    case forward
    case backward

    var step: Int {
        switch self {
        case .forward: return 1
        case .backward: return -1
        }
    }
}

/// [WordBreaker] exposes static methods to identify word boundaries.
final class WordBreaker {
    /// It starts from [index] and tries to find the next word boundary in [text].
    static func nextBreakIndex(text: String, index: TextIndex) -> TextIndex {
        return _findBreakIndex(direction: .forward, text: text, index: index)
    }

    /// It starts from [index] and tries to find the previous word boundary in
    /// [text].
    static func prevBreakIndex(text: String, index: TextIndex) -> TextIndex {
        return _findBreakIndex(direction: .backward, text: text, index: index)
    }

    static func _findBreakIndex(
        direction: _FindBreakDirection,
        text: String,
        index: TextIndex
    ) -> TextIndex {
        var i = index
        while i >= .zero && i <= TextIndex(utf16Offset: text.utf16.count) {
            i = i + TextIndex(utf16Offset: direction.step)
            if _isBreak(text: text, index: i) {
                break
            }
        }
        return i.clamped(to: .zero...TextIndex(utf16Offset: text.utf16.count))
    }

    /// Find out if there's a word break between [index - 1] and [index].
    /// http://unicode.org/reports/tr29/#Word_Boundary_Rules
    static func _isBreak(text: String?, index: TextIndex) -> Bool {
        // Break at the start and end of text.
        // WB1: sot ÷ Any
        // WB2: Any ÷ eot
        if index <= .zero || index >= TextIndex(utf16Offset: text!.utf16.count) {
            return true
        }

        // Do not break inside surrogate pair
        if _isUtf16Surrogate(index.codeUnit(in: text!)) {
            return false
        }

        let immediateRight = wordLookup.find(text!, index)
        var immediateLeft = wordLookup.find(text!, index.advanced(by: -1))

        // Do not break within CRLF.
        // WB3: CR × LF
        if immediateLeft == .CR && immediateRight == .LF {
            return false
        }

        // Otherwise break before and after Newlines (including CR and LF)
        // WB3a: (Newline | CR | LF) ÷
        if _oneOf(
            value: immediateLeft,
            choice1: .Newline,
            choice2: .CR,
            choice3: .LF
        ) {
            return true
        }

        // WB3b: ÷ (Newline | CR | LF)
        if _oneOf(
            value: immediateRight,
            choice1: .Newline,
            choice2: .CR,
            choice3: .LF
        ) {
            return true
        }

        // WB3c: ZWJ	×	\p{Extended_Pictographic}
        // TODO(mdebbar): What's the right way to implement this?

        // Keep horizontal whitespace together.
        // WB3d: WSegSpace × WSegSpace
        if immediateLeft == .WSegSpace && immediateRight == .WSegSpace {
            return false
        }

        // Ignore Format and Extend characters, except after sot, CR, LF, and
        // Newline.
        // WB4: X (Extend | Format | ZWJ)* → X
        if _oneOf(
            value: immediateRight,
            choice1: .Extend,
            choice2: .Format,
            choice3: .ZWJ
        ) {
            // The Extend|Format|ZWJ character is to the right, so it is attached
            // to a character to the left, don't split here
            return false
        }

        // We've reached the end of an Extend|Format|ZWJ sequence, collapse it.
        var l = 0
        while _oneOf(
            value: immediateLeft,
            choice1: .Extend,
            choice2: .Format,
            choice3: .ZWJ
        ) {
            l += 1
            if index.advanced(by: -l - 1) <= .zero {
                // Reached the beginning of text.
                return true
            }
            immediateLeft = wordLookup.find(text!, index.advanced(by: -l - 1))
        }

        // Do not break between most letters.
        // WB5: (ALetter | Hebrew_Letter) × (ALetter | Hebrew_Letter)
        if _isAHLetter(property: immediateLeft) && _isAHLetter(property: immediateRight) {
            return false
        }

        // Some tests beyond this point require more context. We need to get that
        // context while also respecting rule WB4. So ignore Format, Extend and ZWJ.

        // Skip all Format, Extend and ZWJ to the right.
        var r = 0
        var nextRight: WordCharProperty?
        repeat {
            r += 1
            nextRight = wordLookup.find(text!, index.advanced(by: r))
        } while _oneOf(
            value: nextRight,
            choice1: .Extend,
            choice2: .Format,
            choice3: .ZWJ
        )

        // Skip all Format, Extend and ZWJ to the left.
        var nextLeft: WordCharProperty?
        repeat {
            l += 1
            nextLeft = wordLookup.find(text!, index.advanced(by: -l - 1))
        } while _oneOf(
            value: nextLeft,
            choice1: .Extend,
            choice2: .Format,
            choice3: .ZWJ
        )

        // Do not break letters across certain punctuation.
        // WB6: (AHLetter) × (MidLetter | MidNumLet | Single_Quote) (AHLetter)
        if _isAHLetter(property: immediateLeft)
            && _oneOf(
                value: immediateRight,
                choice1: .MidLetter,
                choice2: .MidNumLet,
                choice3: .SingleQuote
            ) && _isAHLetter(property: nextRight)
        {
            return false
        }

        // WB7: (AHLetter) (MidLetter | MidNumLet | Single_Quote) × (AHLetter)
        if _isAHLetter(property: nextLeft)
            && _oneOf(
                value: immediateLeft,
                choice1: .MidLetter,
                choice2: .MidNumLet,
                choice3: .SingleQuote
            ) && _isAHLetter(property: immediateRight)
        {
            return false
        }

        // WB7a: Hebrew_Letter × Single_Quote
        if immediateLeft == .HebrewLetter && immediateRight == .SingleQuote {
            return false
        }

        // WB7b: Hebrew_Letter × Double_Quote Hebrew_Letter
        if immediateLeft == .HebrewLetter && immediateRight == .DoubleQuote
            && nextRight == .HebrewLetter
        {
            return false
        }

        // WB7c: Hebrew_Letter Double_Quote × Hebrew_Letter
        if nextLeft == .HebrewLetter && immediateLeft == .DoubleQuote
            && immediateRight == .HebrewLetter
        {
            return false
        }

        // Do not break within sequences of digits, or digits adjacent to letters
        // ("3a", or "A3").
        // WB8: Numeric × Numeric
        if immediateLeft == .Numeric && immediateRight == .Numeric {
            return false
        }

        // WB9: AHLetter × Numeric
        if _isAHLetter(property: immediateLeft) && immediateRight == .Numeric {
            return false
        }

        // WB10: Numeric × AHLetter
        if immediateLeft == .Numeric && _isAHLetter(property: immediateRight) {
            return false
        }

        // Do not break within sequences, such as "3.2" or "3,456.789".
        // WB11: Numeric (MidNum | MidNumLet | Single_Quote) × Numeric
        if nextLeft == .Numeric
            && _oneOf(
                value: immediateLeft,
                choice1: .MidNum,
                choice2: .MidNumLet,
                choice3: .SingleQuote
            ) && immediateRight == .Numeric
        {
            return false
        }

        // WB12: Numeric × (MidNum | MidNumLet | Single_Quote) Numeric
        if immediateLeft == .Numeric
            && _oneOf(
                value: immediateRight,
                choice1: .MidNum,
                choice2: .MidNumLet,
                choice3: .SingleQuote
            ) && nextRight == .Numeric
        {
            return false
        }

        // Do not break between Katakana.
        // WB13: Katakana × Katakana
        if immediateLeft == .Katakana && immediateRight == .Katakana {
            return false
        }

        // Do not break from extenders.
        // WB13a: (AHLetter | Numeric | Katakana | ExtendNumLet) × ExtendNumLet
        if _oneOf(
            value: immediateLeft,
            choice1: .ALetter,
            choice2: .HebrewLetter,
            choice3: .Numeric,
            choice4: .Katakana,
            choice5: .ExtendNumLet
        ) && immediateRight == .ExtendNumLet {
            return false
        }

        // WB13b: ExtendNumLet × (AHLetter | Numeric | Katakana)
        if immediateLeft == .ExtendNumLet
            && _oneOf(
                value: immediateRight,
                choice1: .ALetter,
                choice2: .HebrewLetter,
                choice3: .Numeric,
                choice4: .Katakana
            )
        {
            return false
        }

        // Do not break within emoji flag sequences. That is, do not break between
        // regional indicator (RI) symbols if there is an odd number of RI
        // characters before the break point.
        // WB15: sot (RI RI)* RI × RI
        // TODO(mdebbar): implement this.

        // WB16: [^RI] (RI RI)* RI × RI
        // TODO(mdebbar): implement this.

        // Otherwise, break everywhere (including around ideographs).
        // WB999: Any ÷ Any
        return true
    }

    static func _isUtf16Surrogate(_ value: UInt16) -> Bool {
        return (value & 0xF800) == 0xD800
    }

    static func _oneOf(
        value: WordCharProperty?,
        choice1: WordCharProperty,
        choice2: WordCharProperty,
        choice3: WordCharProperty? = nil,
        choice4: WordCharProperty? = nil,
        choice5: WordCharProperty? = nil
    ) -> Bool {
        if value == choice1 {
            return true
        }
        if value == choice2 {
            return true
        }
        if let choice3 = choice3, value == choice3 {
            return true
        }
        if let choice4 = choice4, value == choice4 {
            return true
        }
        if let choice5 = choice5, value == choice5 {
            return true
        }
        return false
    }

    static func _isAHLetter(property: WordCharProperty?) -> Bool {
        return _oneOf(value: property, choice1: .ALetter, choice2: .HebrewLetter)
    }
}
