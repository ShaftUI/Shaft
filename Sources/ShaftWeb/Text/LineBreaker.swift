// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Shaft

let _kNewlines: Set<UInt32> = [
    0x000A,  // LF
    0x000B,  // BK
    0x000C,  // BK
    0x000D,  // CR
    0x0085,  // NL
    0x2028,  // BK
    0x2029,  // BK
]

let _kSpaces: Set<UInt32> = [
    0x0020,  // SP
    0x200B,  // ZW
]

/// Various types of line breaks as defined by the Unicode spec.
enum LineBreakType {
    /// Indicates that a line break is possible but not mandatory.
    case opportunity

    /// Indicates that a line break isn't possible.
    case prohibited

    /// Indicates that this is a hard line break that can't be skipped.
    case mandatory

    /// Indicates the end of the text (which is also considered a line break in
    /// the Unicode spec). This is the same as [mandatory] but it's needed in our
    /// implementation to distinguish between the universal [endOfText] and the
    /// line break caused by "\n" at the end of the text.
    case endOfText
}

/// Splits [text] into fragments based on line breaks.
protocol LineBreakFragmenter: TextFragmenter {
    func fragment() -> [LineBreakFragment]
}

/// Factory method to create the appropriate LineBreakFragmenter
func createLineBreakFragmenter(text: String) -> any LineBreakFragmenter {
    // if domIntl.v8BreakIterator != nil {
    //     return V8LineBreakFragmenter(text: text)
    // }
    return FWLineBreakFragmenter(text: text)
}

/// Flutter web's custom implementation of [LineBreakFragmenter].
class FWLineBreakFragmenter: LineBreakFragmenter {
    typealias FragmentType = LineBreakFragment

    let text: String

    init(text: String) {
        self.text = text
    }

    func fragment() -> [LineBreakFragment] {
        return _computeLineBreakFragments(text)
    }
}

// /// An implementation of [LineBreakFragmenter] that uses V8's
// /// `v8BreakIterator` API to find line breaks in the given [text].
// class V8LineBreakFragmenter: TextFragmenter, LineBreakFragmenter {
//     init(text: String) {
//         super.init(text: text)
//         assert(domIntl.v8BreakIterator != nil)
//     }

//     private let _v8BreakIterator = createV8BreakIterator()

//     func fragment() -> [LineBreakFragment] {
//         return breakLinesUsingV8BreakIterator(
//             text: text,
//             jsText: text.toJS,
//             iterator: _v8BreakIterator
//         )
//     }
// }

// func breakLinesUsingV8BreakIterator(text: String, jsText: JSString, iterator: DomV8BreakIterator)
//     -> [LineBreakFragment]
// {
//     var breaks: [LineBreakFragment] = []
//     var fragmentStart = 0

//     iterator.adoptText(jsText)
//     iterator.first()
//     while iterator.next() != -1 {
//         let fragmentEnd = iterator.current().toInt()
//         var trailingNewlines = 0
//         var trailingSpaces = 0

//         // Calculate trailing newlines and spaces.
//         for i in fragmentStart..<fragmentEnd {
//             let codeUnit = text.codeUnitAt(i)
//             if _kNewlines.contains(codeUnit) {
//                 trailingNewlines += 1
//                 trailingSpaces += 1
//             } else if _kSpaces.contains(codeUnit) {
//                 trailingSpaces += 1
//             } else {
//                 // Always break after a sequence of spaces.
//                 if trailingSpaces > 0 {
//                     breaks.append(
//                         LineBreakFragment(
//                             fragmentStart,
//                             i,
//                             .opportunity,
//                             trailingNewlines: trailingNewlines,
//                             trailingSpaces: trailingSpaces
//                         )
//                     )
//                     fragmentStart = i
//                     trailingNewlines = 0
//                     trailingSpaces = 0
//                 }
//             }
//         }

//         let type: LineBreakType
//         if trailingNewlines > 0 {
//             type = .mandatory
//         } else if fragmentEnd == text.count {
//             type = .endOfText
//         } else {
//             type = .opportunity
//         }

//         breaks.append(
//             LineBreakFragment(
//                 fragmentStart,
//                 fragmentEnd,
//                 type,
//                 trailingNewlines: trailingNewlines,
//                 trailingSpaces: trailingSpaces
//             )
//         )
//         fragmentStart = fragmentEnd
//     }

//     if breaks.isEmpty || breaks.last?.type == .mandatory {
//         breaks.append(
//             LineBreakFragment(
//                 text.count,
//                 text.count,
//                 .endOfText,
//                 trailingNewlines: 0,
//                 trailingSpaces: 0
//             )
//         )
//     }

//     return breaks
// }

struct LineBreakFragment: TextFragment {
    let start: TextIndex
    let end: TextIndex
    let type: LineBreakType
    let trailingNewlines: TextIndex
    let trailingSpaces: TextIndex

    init(
        _ start: TextIndex,
        _ end: TextIndex,
        _ type: LineBreakType,
        trailingNewlines: TextIndex,
        trailingSpaces: TextIndex
    ) {
        self.start = start
        self.end = end
        self.type = type
        self.trailingNewlines = trailingNewlines
        self.trailingSpaces = trailingSpaces
    }
}

func _isHardBreak(_ prop: LineCharProperty?) -> Bool {
    // No need to check for NL because it's already normalized to BK.
    return prop == .LF || prop == .BK
}

func _isALorHL(_ prop: LineCharProperty?) -> Bool {
    return prop == .AL || prop == .HL
}

/// Whether the given property is part of a Korean Syllable block.
///
/// See:
/// - https://unicode.org/reports/tr14/tr14-45.html#LB27
func _isKoreanSyllable(_ prop: LineCharProperty?) -> Bool {
    return prop == .JL || prop == .JV || prop == .JT || prop == .H2 || prop == .H3
}

/// Whether the given char code has an Eastern Asian width property of F, W or H.
///
/// See:
/// - https://www.unicode.org/reports/tr14/tr14-45.html#LB30
/// - https://www.unicode.org/Public/13.0.0/ucd/EastAsianWidth.txt
func _hasEastAsianWidthFWH(_ charCode: Int) -> Bool {
    return charCode == 0x2329 || (charCode >= 0x3008 && charCode <= 0x301D)
        || (charCode >= 0xFE17 && charCode <= 0xFF62)
}

func _isSurrogatePair(_ codePoint: Int?) -> Bool {
    return codePoint != nil && codePoint! > 0xFFFF
}

/// Finds the next line break in the given text starting from the specified index.
///
/// We think about indices as pointing between characters, and they go all the
/// way from 0 to the string length. For example, here are the indices for the
/// string "foo bar":
///
/// ```none
///   f   o   o       b   a   r
/// ^   ^   ^   ^   ^   ^   ^   ^
/// 0   1   2   3   4   5   6   7
/// ```
///
/// This way the indices work well with string substring operations.
///
/// Useful resources:
///
/// * https://www.unicode.org/reports/tr14/tr14-45.html#Algorithm
/// * https://www.unicode.org/Public/11.0.0/ucd/LineBreak.txt
func _computeLineBreakFragments(_ text: String) -> [LineBreakFragment] {
    var fragments: [LineBreakFragment] = []

    // Keeps track of the character two positions behind.
    var prev2: LineCharProperty?
    var prev1: LineCharProperty?

    var codePoint: Int? = Int(text.unicodeScalars.first?.value ?? 0)
    var curr = lineLookup.findForChar(codePoint)

    // When there's a sequence of combining marks, this variable contains the base
    // property i.e. the property of the character preceding the sequence.
    var baseOfCombiningMarks: LineCharProperty = .AL

    var index = TextIndex.zero
    var trailingNewlines = TextIndex.zero
    var trailingSpaces = TextIndex.zero

    var fragmentStart = TextIndex.zero

    func setBreak(_ type: LineBreakType, _ debugRuleNumber: Int) {
        let fragmentEnd = type == .endOfText ? TextIndex(utf16Offset: text.utf16.count) : index
        assert(fragmentEnd >= fragmentStart)

        // Uncomment the following line to help debug line breaking.
        // print("\(fragmentStart):\(fragmentEnd) [\(debugRuleNumber)] -- \(type)")

        if prev1 == .SP {
            trailingSpaces = trailingSpaces.advanced(by: 1)
        } else if _isHardBreak(prev1) || prev1 == .CR {
            trailingNewlines = trailingNewlines.advanced(by: 1)
            trailingSpaces = trailingSpaces.advanced(by: 1)
        }

        if type == .prohibited {
            // Don't create a fragment.
            return
        }

        fragments.append(
            LineBreakFragment(
                fragmentStart,
                fragmentEnd,
                type,
                trailingNewlines: trailingNewlines,
                trailingSpaces: trailingSpaces
            )
        )

        fragmentStart = index

        // Reset trailing spaces/newlines counter after a new fragment.
        trailingNewlines = .zero
        trailingSpaces = .zero

        prev1 = nil
        prev2 = nil
    }

    // Never break at the start of text.
    // LB2: sot ×
    setBreak(.prohibited, 2)

    // Never break at the start of text.
    // LB2: sot ×
    //
    // Skip index 0 because a line break can't exist at the start of text.
    index = index.advanced(by: 1)

    var regionalIndicatorCount = 0

    // We need to go until `text.count` in order to handle the case where the
    // paragraph ends with a hard break. In this case, there will be an empty line
    // at the end.
    while index <= TextIndex(utf16Offset: text.utf16.count) {
        prev2 = prev1
        prev1 = curr

        if _isSurrogatePair(codePoint) {
            // Can't break in the middle of a surrogate pair.
            setBreak(.prohibited, -1)
            // Advance `index` one extra step to skip the tail of the surrogate pair.
            index = index.advanced(by: 1)
        }

        codePoint = getCodePoint(text, index)
        curr = lineLookup.findForChar(codePoint)

        // Keep count of the RI (regional indicator) sequence.
        if prev1 == .RI {
            regionalIndicatorCount += 1
        } else {
            regionalIndicatorCount = 0
        }

        // Always break after hard line breaks.
        // LB4: BK !
        //
        // Treat CR followed by LF, as well as CR, LF, and NL as hard line breaks.
        // LB5: LF !
        //      NL !
        if _isHardBreak(prev1) {
            setBreak(.mandatory, 5)
            index = index.advanced(by: 1)
            continue
        }

        if prev1 == .CR {
            if curr == .LF {
                // LB5: CR × LF
                setBreak(.prohibited, 5)
            } else {
                // LB5: CR !
                setBreak(.mandatory, 5)
            }
            index = index.advanced(by: 1)
            continue
        }

        // Do not break before hard line breaks.
        // LB6: × ( BK | CR | LF | NL )
        if _isHardBreak(curr) || curr == .CR {
            setBreak(.prohibited, 6)
            index = index.advanced(by: 1)
            continue
        }

        if index >= TextIndex(utf16Offset: text.utf16.count) {
            break
        }

        // Do not break before spaces or zero width space.
        // LB7: × SP
        //      × ZW
        if curr == .SP || curr == .ZW {
            setBreak(.prohibited, 7)
            index = index.advanced(by: 1)
            continue
        }

        // Break after spaces.
        // LB18: SP ÷
        if prev1 == .SP {
            setBreak(.opportunity, 18)
            index = index.advanced(by: 1)
            continue
        }

        // Break before any character following a zero-width space, even if one or
        // more spaces intervene.
        // LB8: ZW SP* ÷
        if prev1 == .ZW {
            setBreak(.opportunity, 8)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break after a zero width joiner.
        // LB8a: ZWJ ×
        if prev1 == .ZWJ {
            setBreak(.prohibited, 8)
            index = index.advanced(by: 1)
            continue
        }

        // Establish the base for the sequences of combining marks.
        if prev1 != .CM && prev1 != .ZWJ {
            baseOfCombiningMarks = prev1 ?? .AL
        }

        // Do not break a combining character sequence; treat it as if it has the
        // line breaking class of the base character in all of the following rules.
        // Treat ZWJ as if it were CM.
        if curr == .CM || curr == .ZWJ {
            if baseOfCombiningMarks == .SP {
                // LB10: Treat any remaining combining mark or ZWJ as AL.
                curr = .AL
            } else {
                // LB9: Treat X (CM | ZWJ)* as if it were X
                //      where X is any line break class except BK, NL, LF, CR, SP, or ZW.
                curr = baseOfCombiningMarks
                if curr == .RI {
                    // Prevent the previous RI from being double-counted.
                    regionalIndicatorCount -= 1
                }
                setBreak(.prohibited, 9)
                index = index.advanced(by: 1)
                continue
            }
        }
        // In certain situations (e.g. CM immediately following a hard break), we
        // need to also check if the previous character was CM/ZWJ. That's because
        // hard breaks caused the previous iteration to short-circuit, which leads
        // to `baseOfCombiningMarks` not being updated properly.
        if prev1 == .CM || prev1 == .ZWJ {
            prev1 = baseOfCombiningMarks
        }

        // Do not break before or after Word joiner and related characters.
        // LB11: × WJ
        //       WJ ×
        if curr == .WJ || prev1 == .WJ {
            setBreak(.prohibited, 11)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break after NBSP and related characters.
        // LB12: GL ×
        if prev1 == .GL {
            setBreak(.prohibited, 12)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break before NBSP and related characters, except after spaces and
        // hyphens.
        // LB12a: [^SP BA HY] × GL
        if !(prev1 == .SP || prev1 == .BA || prev1 == .HY) && curr == .GL {
            setBreak(.prohibited, 12)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break before ']' or '!' or ';' or '/', even after spaces.
        // LB13: × CL
        //       × CP
        //       × EX
        //       × IS
        //       × SY
        //
        // The above is a quote from unicode.org. In our implementation, we did the
        // following modification: When there are spaces present, we consider it a
        // line break opportunity.
        //
        // We made this modification to match the browser behavior.
        if prev1 != .SP && (curr == .CL || curr == .CP || curr == .EX || curr == .IS || curr == .SY)
        {
            setBreak(.prohibited, 13)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break after '[', even after spaces.
        // LB14: OP SP* ×
        //
        // The above is a quote from unicode.org. In our implementation, we did the
        // following modification: Allow breaks when there are spaces.
        //
        // We made this modification to match the browser behavior.
        if prev1 == .OP {
            setBreak(.prohibited, 14)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break within '"[', even with intervening spaces.
        // LB15: QU SP* × OP
        //
        // The above is a quote from unicode.org. In our implementation, we did the
        // following modification: Allow breaks when there are spaces.
        //
        // We made this modification to match the browser behavior.
        if prev1 == .QU && curr == .OP {
            setBreak(.prohibited, 15)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break between closing punctuation and a nonstarter, even with
        // intervening spaces.
        // LB16: (CL | CP) SP* × NS
        //
        // The above is a quote from unicode.org. In our implementation, we did the
        // following modification: Allow breaks when there are spaces.
        //
        // We made this modification to match the browser behavior.
        if (prev1 == .CL || prev1 == .CP) && curr == .NS {
            setBreak(.prohibited, 16)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break within '——', even with intervening spaces.
        // LB17: B2 SP* × B2
        //
        // The above is a quote from unicode.org. In our implementation, we did the
        // following modification: Allow breaks when there are spaces.
        //
        // We made this modification to match the browser behavior.
        if prev1 == .B2 && curr == .B2 {
            setBreak(.prohibited, 17)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break before or after quotation marks, such as '"'.
        // LB19: × QU
        //       QU ×
        if prev1 == .QU || curr == .QU {
            setBreak(.prohibited, 19)
            index = index.advanced(by: 1)
            continue
        }

        // Break before and after unresolved CB.
        // LB20: ÷ CB
        //       CB ÷
        //
        // In flutter web, we use this as an object-replacement character for
        // placeholders.
        if prev1 == .CB || curr == .CB {
            setBreak(.opportunity, 20)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break before hyphen-minus, other hyphens, fixed-width spaces,
        // small kana, and other non-starters, or after acute accents.
        // LB21: × BA
        //       × HY
        //       × NS
        //       BB ×
        if curr == .BA || curr == .HY || curr == .NS || prev1 == .BB {
            setBreak(.prohibited, 21)
            index = index.advanced(by: 1)
            continue
        }

        // Don't break after Hebrew + Hyphen.
        // LB21a: HL (HY | BA) ×
        if prev2 == .HL && (prev1 == .HY || prev1 == .BA) {
            setBreak(.prohibited, 21)
            index = index.advanced(by: 1)
            continue
        }

        // Don't break between Solidus and Hebrew letters.
        // LB21b: SY × HL
        if prev1 == .SY && curr == .HL {
            setBreak(.prohibited, 21)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break before ellipses.
        // LB22: × IN
        if curr == .IN {
            setBreak(.prohibited, 22)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break between digits and letters.
        // LB23: (AL | HL) × NU
        //       NU × (AL | HL)
        if (_isALorHL(prev1) && curr == .NU) || (prev1 == .NU && _isALorHL(curr)) {
            setBreak(.prohibited, 23)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break between numeric prefixes and ideographs, or between
        // ideographs and numeric postfixes.
        // LB23a: PR × (ID | EB | EM)
        if prev1 == .PR && (curr == .ID || curr == .EB || curr == .EM) {
            setBreak(.prohibited, 23)
            index = index.advanced(by: 1)
            continue
        }
        // LB23a: (ID | EB | EM) × PO
        if (prev1 == .ID || prev1 == .EB || prev1 == .EM) && curr == .PO {
            setBreak(.prohibited, 23)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break between numeric prefix/postfix and letters, or between
        // letters and prefix/postfix.
        // LB24: (PR | PO) × (AL | HL)
        if (prev1 == .PR || prev1 == .PO) && _isALorHL(curr) {
            setBreak(.prohibited, 24)
            index = index.advanced(by: 1)
            continue
        }
        // LB24: (AL | HL) × (PR | PO)
        if _isALorHL(prev1) && (curr == .PR || curr == .PO) {
            setBreak(.prohibited, 24)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break between the following pairs of classes relevant to numbers.
        // LB25: (CL | CP | NU) × (PO | PR)
        if (prev1 == .CL || prev1 == .CP || prev1 == .NU) && (curr == .PO || curr == .PR) {
            setBreak(.prohibited, 25)
            index = index.advanced(by: 1)
            continue
        }
        // LB25: (PO | PR) × OP
        if (prev1 == .PO || prev1 == .PR) && curr == .OP {
            setBreak(.prohibited, 25)
            index = index.advanced(by: 1)
            continue
        }
        // LB25: (PO | PR | HY | IS | NU | SY) × NU
        if (prev1 == .PO || prev1 == .PR || prev1 == .HY || prev1 == .IS || prev1 == .NU
            || prev1 == .SY) && curr == .NU
        {
            setBreak(.prohibited, 25)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break a Korean syllable.
        // LB26: JL × (JL | JV | H2 | H3)
        if prev1 == .JL && (curr == .JL || curr == .JV || curr == .H2 || curr == .H3) {
            setBreak(.prohibited, 26)
            index = index.advanced(by: 1)
            continue
        }
        // LB26: (JV | H2) × (JV | JT)
        if (prev1 == .JV || prev1 == .H2) && (curr == .JV || curr == .JT) {
            setBreak(.prohibited, 26)
            index = index.advanced(by: 1)
            continue
        }
        // LB26: (JT | H3) × JT
        if (prev1 == .JT || prev1 == .H3) && curr == .JT {
            setBreak(.prohibited, 26)
            index = index.advanced(by: 1)
            continue
        }

        // Treat a Korean Syllable Block the same as ID.
        // LB27: (JL | JV | JT | H2 | H3) × PO
        if _isKoreanSyllable(prev1) && curr == .PO {
            setBreak(.prohibited, 27)
            index = index.advanced(by: 1)
            continue
        }
        // LB27: PR × (JL | JV | JT | H2 | H3)
        if prev1 == .PR && _isKoreanSyllable(curr) {
            setBreak(.prohibited, 27)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break between alphabetics.
        // LB28: (AL | HL) × (AL | HL)
        if _isALorHL(prev1) && _isALorHL(curr) {
            setBreak(.prohibited, 28)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break between numeric punctuation and alphabetics ("e.g.").
        // LB29: IS × (AL | HL)
        if prev1 == .IS && _isALorHL(curr) {
            setBreak(.prohibited, 29)
            index = index.advanced(by: 1)
            continue
        }

        // Do not break between letters, numbers, or ordinary symbols and opening or
        // closing parentheses.
        // LB30: (AL | HL | NU) × OP
        //
        // LB30 requires that we exclude characters that have an Eastern Asian width
        // property of value F, W or H classes.
        if (_isALorHL(prev1) || prev1 == .NU) && curr == .OP
            && !_hasEastAsianWidthFWH(index.codePoint(in: text))
        {
            setBreak(.prohibited, 30)
            index = index.advanced(by: 1)
            continue
        }
        // LB30: CP × (AL | HL | NU)
        if prev1 == .CP
            && !_hasEastAsianWidthFWH(
                index.advanced(by: -1).codePoint(in: text)
            ) && (_isALorHL(curr) || curr == .NU)
        {
            setBreak(.prohibited, 30)
            index = index.advanced(by: 1)
            continue
        }

        // Break between two regional indicator symbols if and only if there are an
        // even number of regional indicators preceding the position of the break.
        // LB30a: sot (RI RI)* RI × RI
        //        [^RI] (RI RI)* RI × RI
        if curr == .RI {
            if regionalIndicatorCount % 2 == 1 {
                setBreak(.prohibited, 30)
            } else {
                setBreak(.opportunity, 30)
            }
            index = index.advanced(by: 1)
            continue
        }

        // Do not break between an emoji base and an emoji modifier.
        // LB30b: EB × EM
        if prev1 == .EB && curr == .EM {
            setBreak(.prohibited, 30)
            index = index.advanced(by: 1)
            continue
        }

        // Break everywhere else.
        // LB31: ALL ÷
        //       ÷ ALL
        setBreak(.opportunity, 31)
        index = index.advanced(by: 1)
    }

    // Always break at the end of text.
    // LB3: ! eot
    setBreak(.endOfText, 3)

    return fragments
}
