// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Examples can assume:
// late var textLayout: TextLayoutMetrics
// late var text: TextSpan
// func isWhitespace(_ codeUnit: Int?) -> Bool { return true }

/// Signature for a predicate that takes an offset into a UTF-16 string, and a
/// boolean that indicates the search direction.
typealias UntilPredicate = (Int, Bool) -> Bool

/// An interface for retrieving the logical text boundary (as opposed to the
/// visual boundary) at a given code unit offset in a document.
///
/// Either the `getTextBoundaryAt` method, or both the
/// `getLeadingTextBoundaryAt` method and the `getTrailingTextBoundaryAt` method
/// must be implemented.
public protocol TextBoundary {
    /// Returns the offset of the closest text boundary before or at the given
    /// `position`, or nil if no boundaries can be found.
    ///
    /// The return value, if not nil, is usually less than or equal to `position`.
    ///
    /// The range of the return value is given by the closed interval
    /// `[0, string.length]`.
    func getLeadingTextBoundaryAt(_ position: TextIndex) -> TextIndex?

    /// Returns the offset of the closest text boundary after the given
    /// `position`, or nil if there is no boundary can be found after `position`.
    ///
    /// The return value, if not nil, is usually greater than `position`.
    ///
    /// The range of the return value is given by the closed interval
    /// `[0, string.length]`.
    func getTrailingTextBoundaryAt(_ position: TextIndex) -> TextIndex?

    /// Returns the text boundary range that encloses the input position.
    ///
    /// The returned `TextRange` may contain `-1`, which indicates no boundaries
    /// can be found in that direction.
    func getTextBoundaryAt(_ position: TextIndex) -> TextRange?
}

extension TextBoundary {
    public func getLeadingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        if position < .zero {
            return nil
        }
        let start = getTextBoundaryAt(position)?.start
        guard let start else {
            return nil
        }
        return start >= .zero ? start : nil
    }

    public func getTrailingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        let end = getTextBoundaryAt(max(.zero, position))?.end
        guard let end else {
            return nil
        }
        return end >= .zero ? end : nil
    }

    public func getTextBoundaryAt(_ position: TextIndex) -> TextRange? {
        let start = getLeadingTextBoundaryAt(position) ?? nil
        let end = getTrailingTextBoundaryAt(position) ?? nil
        if let start, let end {
            return TextRange(start: start, end: end)
        }
        return nil
    }
}

/// A `TextBoundary` subclass for retrieving the range of the grapheme the given
/// `position` is in.
public struct CharacterBoundary: TextBoundary {
    /// Creates a `CharacterBoundary` with the text.
    public init(_ text: String) {
        self.text = text
    }

    public let text: String

    public func getLeadingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        if position < .zero {
            return nil
        }
        if position.utf16Offset >= text.utf16.count {
            return .init(utf16Offset: text.utf16.count)
        }
        let graphemeRange = text.rangeOfComposedCharacterSequence(
            at: position.index(in: text)
        )
        return .init(from: graphemeRange.lowerBound, in: text)
    }

    public func getTrailingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        if position.utf16Offset >= text.utf16.count {
            return nil
        }
        if position < .zero {
            return .zero
        }
        let graphemeRange = text.rangeOfComposedCharacterSequence(
            at: position.index(in: text)
        )
        return .init(from: graphemeRange.upperBound, in: text)
    }

    public func getTextBoundaryAt(_ position: TextIndex) -> TextRange? {
        if position < .zero || position.utf16Offset >= text.utf16.count {
            return nil
        }
        let graphemeRange = text.rangeOfComposedCharacterSequence(
            at: position.index(in: text)
        )
        return TextRange(
            start: .init(from: graphemeRange.lowerBound, in: text),
            end: .init(from: graphemeRange.upperBound, in: text)
        )
    }
}

/// A `TextBoundary` subclass for locating closest line breaks to a given
/// `position`.
///
/// When the given `position` points to a hard line break, the returned range
/// is the line's content range before the hard line break, and does not contain
/// the given `position`. For instance, the line breaks at `position = 1` for
/// "a\nb" is `[0, 1)`, which does not contain the position `1`.
public struct LineBoundary: TextBoundary {
    /// Creates a `LineBoundary` with the text and layout information.
    public init(_ textLayout: TextLayoutMetrics) {
        self.textLayout = textLayout
    }

    private let textLayout: TextLayoutMetrics

    public func getTextBoundaryAt(_ position: TextIndex) -> TextRange? {
        let range = textLayout.getLineAtOffset(TextPosition(offset: max(position, .zero)))
        guard let range else {
            return nil
        }
        return range
    }
}

/// A text boundary that uses paragraphs as logical boundaries.
///
/// A paragraph is defined as the range between line terminators. If no
/// line terminators exist then the paragraph boundary is the entire document.
public struct ParagraphBoundary: TextBoundary {
    /// Creates a `ParagraphBoundary` with the text.
    public init(_ text: String) {
        self.text = text
    }

    private let text: String

    /// Returns the `TextIndex` representing the start position of the paragraph that
    /// bounds the given `position`. The returned `TextIndex` is the position of the code unit
    /// that follows the line terminator that encloses the desired paragraph.
    public func getLeadingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        if position < .zero || text.isEmpty {
            return nil
        }

        if position.utf16Offset >= text.utf16.count {
            return .init(utf16Offset: text.utf16.count)
        }

        if position == .zero {
            return .zero
        }

        var index = position

        if index.utf16Offset > 1 && text.codeUnitAt(index) == 0x0A
            && text.codeUnitAt(index.advanced(by: -1)) == 0x0D
        {
            index = index.advanced(by: -2)
        } else if isLineTerminator(text.codeUnitAt(index)) {
            index = index.advanced(by: -1)
        }

        while index > .zero {
            if isLineTerminator(text.codeUnitAt(index)) {
                return index.advanced(by: 1)
            }
            index = index.advanced(by: -1)
        }

        return max(index, .zero)
    }

    /// Returns the `TextIndex` representing the end position of the paragraph that
    /// bounds the given `position`. The returned `TextIndex` is the position of the
    /// code unit representing the trailing line terminator that encloses the
    /// desired paragraph.
    public func getTrailingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        if position.utf16Offset >= text.utf16.count || text.isEmpty {
            return nil
        }

        if position < .zero {
            return .zero
        }

        var index = position

        while !isLineTerminator(text.codeUnitAt(index)) {
            index = index.advanced(by: 1)
            if index.utf16Offset == text.utf16.count {
                return index
            }
        }

        return index.utf16Offset < text.utf16.count - 1
            && text.codeUnitAt(index) == 0x0D
            && text.codeUnitAt(index.advanced(by: 1)) == 0x0A
            ? index.advanced(by: 2)
            : index.advanced(by: 1)
    }
}

/// A text boundary that uses the entire document as logical boundary.
public struct DocumentBoundary: TextBoundary {
    /// Creates a `DocumentBoundary` with the text.
    public init(_ text: String) {
        self.text = text
    }

    private let text: String

    public func getLeadingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        return position < .zero ? nil : .zero
    }

    public func getTrailingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        return position.utf16Offset >= text.utf16.count ? nil : .init(utf16Offset: text.utf16.count)
    }
}
