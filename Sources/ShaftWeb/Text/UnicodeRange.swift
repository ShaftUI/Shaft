// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import Shaft

let kChar_0 = 48
let kChar_9 = kChar_0 + 9
let kChar_A = 65
let kChar_Z = 90
let kChar_a = 97
let kChar_z = 122
let kCharBang = 33
let kMashriqi_0 = 0x660
let kMashriqi_9 = kMashriqi_0 + 9

enum ComparisonResult {
    case inside
    case higher
    case lower
}

/// Each instance of UnicodeRange represents a range of unicode characters
/// that are assigned a CharProperty. For example, the following snippet:
///
/// ```swift
/// UnicodeRange(0x0041, 0x005A, CharProperty.ALetter)
/// ```
///
/// is saying that all characters between 0x0041 ("A") and 0x005A ("Z") are
/// assigned the property CharProperty.ALetter.
///
/// Note that the Unicode spec uses inclusive ranges and we are doing the
/// same here.
class UnicodeRange<P> {
    let start: Int
    let end: Int
    let property: P

    init(_ start: Int, _ end: Int, _ property: P) {
        self.start = start
        self.end = end
        self.property = property
    }

    /// Compare a value to this range.
    ///
    /// The return value is either:
    /// - lower: The value is lower than the range.
    /// - higher: The value is higher than the range
    /// - inside: The value is within the range.
    func compare(_ value: Int) -> ComparisonResult {
        if value < start {
            return .lower
        }
        if value > end {
            return .higher
        }
        return .inside
    }
}

/// Checks whether the given char code is a UTF-16 surrogate.
///
/// See:
/// - http://www.unicode.org/faq//utf_bom.html#utf16-2
func isUtf16Surrogate(_ char: Int) -> Bool {
    return char & 0xF800 == 0xD800
}

/// Combines a pair of UTF-16 surrogate into a single character code point.
///
/// The surrogate pair is expected to start at index in the text.
///
/// See:
/// - http://www.unicode.org/faq//utf_bom.html#utf16-3
func combineSurrogatePair(_ text: String, _ index: TextIndex) -> Int {
    let hi = Int(text.utf16[index.index(in: text)])
    let lo = Int(text.utf16[index.advanced(by: 1).index(in: text)])

    let x = (hi & ((1 << 6) - 1)) << 10 | lo & ((1 << 10) - 1)
    let w = (hi >> 6) & ((1 << 5) - 1)
    let u = w + 1
    return u << 16 | x
}

/// Returns the code point from text at index and handles surrogate pairs
/// for cases that involve two UTF-16 codes.
func getCodePoint(_ text: String, _ index: TextIndex) -> Int? {
    if index < .zero || index >= TextIndex(utf16Offset: text.utf16.count) {
        return nil
    }

    let char = Int(text.utf16[index.index(in: text)])
    if isUtf16Surrogate(char) && index < TextIndex(utf16Offset: text.utf16.count - 1) {
        return combineSurrogatePair(text, index)
    }
    return char
}

/// Given a list of UnicodeRanges, this class performs efficient lookup
/// to find which range a value falls into.
///
/// The lookup algorithm expects the ranges to have the following constraints:
/// - Be sorted.
/// - No overlap between the ranges.
/// - Gaps between ranges are ok.
///
/// This is used in the context of unicode to find out what property a letter
/// has. The properties are then used to decide word boundaries, line break
/// opportunities, etc.
class UnicodePropertyLookup<P> {
    /// The list of unicode ranges and their associated properties.
    let ranges: [UnicodeRange<P>]

    /// The default property to use when a character doesn't belong in any
    /// known range.
    let defaultProperty: P

    /// Cache for lookup results.
    private var cache = [Int: P]()

    init(_ ranges: [UnicodeRange<P>], _ defaultProperty: P) {
        self.ranges = ranges
        self.defaultProperty = defaultProperty
    }

    /// Creates a UnicodePropertyLookup from packed line break data.
    static func fromPackedData(
        _ packedData: String,
        _ singleRangesCount: Int,
        _ propertyEnumValues: [P],
        _ defaultProperty: P
    ) -> UnicodePropertyLookup<P> {
        return UnicodePropertyLookup<P>(
            unpackProperties(packedData, singleRangesCount, propertyEnumValues),
            defaultProperty
        )
    }

    /// Take a text and an index, and returns the property of the character
    /// located at that index.
    ///
    /// If the index is out of range, nil will be returned.
    func find(_ text: String, _ index: TextIndex) -> P {
        guard let codePoint = getCodePoint(text, index) else {
            return defaultProperty
        }
        return findForChar(codePoint)
    }

    /// Takes one character as an integer code unit and returns its property.
    ///
    /// If a property can't be found for the given character, then the default
    /// property will be returned.
    func findForChar(_ char: Int?) -> P {
        guard let char = char else {
            return defaultProperty
        }

        if let cacheHit = cache[char] {
            return cacheHit
        }

        let rangeIndex = binarySearch(char)
        let result = rangeIndex == -1 ? defaultProperty : ranges[rangeIndex].property
        // Cache the result.
        cache[char] = result
        return result
    }

    private func binarySearch(_ value: Int) -> Int {
        var min = 0
        var max = ranges.count
        while min < max {
            let mid = min + ((max - min) >> 1)
            let range = ranges[mid]
            switch range.compare(value) {
            case .higher:
                min = mid + 1
            case .lower:
                max = mid
            case .inside:
                return mid
            }
        }
        return -1
    }
}

func unpackProperties<P>(
    _ packedData: String,
    _ singleRangesCount: Int,
    _ propertyEnumValues: [P]
) -> [UnicodeRange<P>] {
    // Packed data is mostly structured in chunks of 9 characters each:
    //
    // * [0..3]: Range start, encoded as a base36 integer.
    // * [4..7]: Range end, encoded as a base36 integer.
    // * [8]: Index of the property enum value, encoded as a single letter.
    //
    // When the range is a single number (i.e. range start == range end), it gets
    // packed more efficiently in a chunk of 6 characters:
    //
    // * [0..3]: Range start (and range end), encoded as a base 36 integer.
    // * [4]: "!" to indicate that there's no range end.
    // * [5]: Index of the property enum value, encoded as a single letter.

    // `packedData.length + singleRangesCount * 3` would have been the size of the
    // packed data if the efficient packing of single-range items wasn't applied.
    assert((packedData.count + singleRangesCount * 3) % 9 == 0)

    var ranges = [UnicodeRange<P>]()
    let dataLength = packedData.count
    var i = 0
    while i < dataLength {
        let rangeStart = consumeInt(packedData, i)
        i += 4

        var rangeEnd: Int
        if Int(packedData.utf16[packedData.utf16.index(packedData.utf16.startIndex, offsetBy: i)])
            == kCharBang
        {
            rangeEnd = rangeStart
            i += 1
        } else {
            rangeEnd = consumeInt(packedData, i)
            i += 4
        }
        let charCode = Int(
            packedData.utf16[packedData.utf16.index(packedData.utf16.startIndex, offsetBy: i)]
        )
        let property = propertyEnumValues[getEnumIndexFromPackedValue(charCode)]
        i += 1

        ranges.append(UnicodeRange<P>(rangeStart, rangeEnd, property))
    }
    return ranges
}

func getEnumIndexFromPackedValue(_ charCode: Int) -> Int {
    // This has to stay in sync with [EnumValue.serialized] in
    // `tool/unicode_sync_script.dart`.

    assert(
        (charCode >= kChar_A && charCode <= kChar_Z) || (charCode >= kChar_a && charCode <= kChar_z)
    )

    // Uppercase letters were assigned to the first 26 enum values.
    if charCode <= kChar_Z {
        return charCode - kChar_A
    }
    // Lowercase letters were assigned to enum values above 26.
    return 26 + charCode - kChar_a
}

func consumeInt(_ packedData: String, _ index: Int) -> Int {
    // The implementation is equivalent to:
    //
    // ```swift
    // return Int(packedData.substring(from: index, to: index + 4), radix: 36)
    // ```
    //
    // But using substring is slow when called too many times. This custom
    // implementation makes the unpacking 25%-45% faster than using substring.
    let digit0 = getIntFromCharCode(
        Int(
            packedData.utf16[
                packedData.utf16.index(packedData.utf16.startIndex, offsetBy: index + 3)
            ]
        )
    )
    let digit1 = getIntFromCharCode(
        Int(
            packedData.utf16[
                packedData.utf16.index(packedData.utf16.startIndex, offsetBy: index + 2)
            ]
        )
    )
    let digit2 = getIntFromCharCode(
        Int(
            packedData.utf16[
                packedData.utf16.index(packedData.utf16.startIndex, offsetBy: index + 1)
            ]
        )
    )
    let digit3 = getIntFromCharCode(
        Int(packedData.utf16[packedData.utf16.index(packedData.utf16.startIndex, offsetBy: index)])
    )
    return digit0 + (digit1 * 36) + (digit2 * 36 * 36) + (digit3 * 36 * 36 * 36)
}

/// Does the same thing as Int.parse(str, 36) but takes only a single
/// character as a charCode integer.
func getIntFromCharCode(_ charCode: Int) -> Int {
    assert(
        (charCode >= kChar_0 && charCode <= kChar_9) || (charCode >= kChar_a && charCode <= kChar_z)
    )

    if charCode <= kChar_9 {
        return charCode - kChar_0
    }
    // "a" starts from 10 and remaining letters go up from there.
    return charCode - kChar_a + 10
}
