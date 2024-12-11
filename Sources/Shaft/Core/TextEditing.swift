// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Indicates what triggered the change in selected text (including changes to
/// the cursor location).
public enum SelectionChangedCause {
    /// The user tapped on the text and that caused the selection (or the location
    /// of the cursor) to change.
    case tap

    /// The user tapped twice in quick succession on the text and that caused
    /// the selection (or the location of the cursor) to change.
    case doubleTap

    /// The user long-pressed the text and that caused the selection (or the
    /// location of the cursor) to change.
    case longPress

    /// The user force-pressed the text and that caused the selection (or the
    /// location of the cursor) to change.
    case forcePress

    /// The user used the keyboard to change the selection or the location of the
    /// cursor.
    ///
    /// Keyboard-triggered selection changes may be caused by the IME as well as
    /// by accessibility tools (e.g. TalkBack on Android).
    case keyboard

    /// The user used the selection toolbar to change the selection or the
    /// location of the cursor.
    ///
    /// An example is when the user taps on select all in the tool bar.
    case toolbar

    /// The user used the mouse to change the selection by dragging over a piece
    /// of text.
    case drag

    /// The user used iPadOS 14+ Scribble to change the selection.
    case scribble
}

/// The current text, selection, and composing state for editing a run of text.
public struct TextEditingValue: Equatable {
    public init(text: String = "", selection: TextSelection? = nil, composing: TextRange? = nil) {
        self.text = text
        self.selection = selection
        self.composing = composing
    }

    /// A value that corresponds to the empty string with no selection and no
    /// composing range.
    public static let empty = TextEditingValue(
        text: "",
        selection: nil,
        composing: nil
    )

    /// The current text being edited.
    public let text: String

    /// The range of text that is currently selected.
    ///
    /// When [selection] is a [TextSelection] that has the same non-negative
    /// `baseOffset` and `extentOffset`, the [selection] property represents the
    /// caret position.
    ///
    /// If the current [selection] is ``nil``, then the text currently does not
    /// have a selection or a caret location, and most text editing operations
    /// that rely on the current selection (for instance, insert a character at
    /// the caret location) will do nothing.
    public let selection: TextSelection?

    /// The range of text that is still being composed.
    ///
    /// Composing regions are created by input methods (IMEs) to indicate the
    /// text within a certain range is provisional. For instance, the Android
    /// Gboard app's English keyboard puts the current word under the caret into
    /// a composing region to indicate the word is subject to autocorrect or
    /// prediction changes.
    ///
    /// Composing regions can also be used for performing multistage input,
    /// which is typically used by IMEs designed for phonetic keyboard to enter
    /// ideographic symbols. As an example, many CJK keyboards require the user
    /// to enter a Latin alphabet sequence and then convert it to CJK
    /// characters. On iOS, the default software keyboards do not have a
    /// dedicated view to show the unfinished Latin sequence, so it's displayed
    /// directly in the text field, inside of a composing region.
    ///
    /// The composing region should typically only be changed by the IME, or the
    /// user via interacting with the IME.
    ///
    /// If the range represented by this property is [TextRange.empty], then the
    /// text is not currently being composed.
    public let composing: TextRange?

    /// Whether the [composing] range is a valid range within [text].
    ///
    /// Returns true if and only if the [composing] range is normalized, its start
    /// is greater than or equal to 0, and its end is less than or equal to
    /// [text]'s length.
    ///
    /// If this property is false while the [composing] range's `isValid` is true,
    /// it usually indicates the current [composing] range is invalid because of a
    /// programming error.
    var isComposingRangeValid: Bool {
        composing != nil && composing!.isNormalized
            && composing!.end.utf16Offset <= text.utf16.count
    }

    /// Returns a new [TextEditingValue], which is this [TextEditingValue] with
    /// its [text] partially replaced by the `replacementString`.
    ///
    /// The `replacementRange` parameter specifies the range of the
    /// [TextEditingValue.text] that needs to be replaced.
    ///
    /// The `replacementString` parameter specifies the string to replace the
    /// given range of text with.
    ///
    /// This method also adjusts the selection range and the composing range of the
    /// resulting [TextEditingValue], such that they point to the same substrings
    /// as the corresponding ranges in the original [TextEditingValue]. For
    /// example, if the original [TextEditingValue] is "Hello world" with the word
    /// "world" selected, replacing "Hello" with a different string using this
    /// method will not change the selected word.
    ///
    /// This method does nothing if the given `replacementRange` is not
    /// [TextRange.isValid].
    public func replaced(_ replacementRange: TextRange, _ replacementString: String)
        -> TextEditingValue
    {
        if !replacementRange.isValid {
            return self
        }
        let newText = text.replacingCharacters(
            in: replacementRange.start.index(in: text)..<replacementRange.end.index(in: text),
            with: replacementString
        )

        if (replacementRange.end - replacementRange.start).utf16Offset
            == replacementString.utf16.count
        {
            return copyWith(text: newText)
        }

        func adjustIndex(_ originalIndex: TextIndex) -> TextIndex {
            // The length added by adding the replacementString
            let replacedLength =
                originalIndex <= replacementRange.start && originalIndex < replacementRange.end
                ? TextIndex.zero : .init(utf16Offset: replacementString.utf16.count)
            // The length removed by removing the replacementRange
            let removedLength =
                min(max(originalIndex, replacementRange.start), replacementRange.end)
                - replacementRange.start
            return originalIndex + replacedLength - removedLength
        }

        let adjustedSelection = TextSelection(
            baseOffset: adjustIndex(selection?.baseOffset ?? .zero),
            extentOffset: adjustIndex(selection?.extentOffset ?? .zero)
        )
        let adjustedComposing = TextRange(
            start: adjustIndex(composing?.start ?? .zero),
            end: adjustIndex(composing?.end ?? .zero)
        )

        return TextEditingValue(
            text: newText,
            selection: adjustedSelection,
            composing: adjustedComposing
        )
    }

    /// Creates a new [TextEditingValue] with the given properties, or with the
    /// properties of this [TextEditingValue] if the corresponding parameter is
    /// null.
    public func copyWith(
        text: String? = nil,
        selection: TextSelection? = nil,
        composing: TextRange? = nil
    ) -> TextEditingValue {
        return TextEditingValue(
            text: text ?? self.text,
            selection: selection ?? self.selection,
            composing: composing ?? self.composing
        )
    }
}

/// A structure representing a granular change that has occurred to the editing
/// state as a result of text editing.
public protocol TextEditingDelta {
    /// Get a copy of the given [value] with the change applied to it.
    func apply(to value: TextEditingValue) -> TextEditingValue
}

/// A change to the text being composed.
public struct TextEditingDeltaComposing: TextEditingDelta {
    public init(text: String, range: TextRange) {
        self.text = text
        self.range = range
    }

    /// The te
    public let text: String

    public let range: TextRange

    public func apply(to value: TextEditingValue) -> TextEditingValue {
        if let composing = value.composing {
            let range =
                composing.start.index(in: value.text)..<composing.end.index(in: value.text)
            return .init(
                text: value.text.replacingCharacters(in: range, with: text),
                selection: .init(
                    baseOffset: composing.start + self.range.start,
                    extentOffset: composing.start + self.range.end
                ),
                composing: text.isEmpty
                    ? nil
                    : .init(
                        start: composing.start,
                        end: composing.start.advanced(by: self.text.utf16.count)
                    )
            )
        }
        if let selection = value.selection {
            let range =
                selection.range.start.index(
                    in: value.text
                )..<selection.range.end.index(in: value.text)
            return .init(
                text: value.text.replacingCharacters(in: range, with: text),
                selection: .init(
                    baseOffset: selection.range.start + self.range.start,
                    extentOffset: selection.range.start + self.range.end
                ),
                composing: text.isEmpty
                    ? nil
                    : .init(
                        start: selection.range.start,
                        end: selection.range.start.advanced(by: self.text.utf16.count)
                    )
            )
        }

        return value
    }
}

public struct TextEditingDeltaCommit: TextEditingDelta {
    public init(text: String) {
        self.text = text
    }

    public let text: String

    public func apply(to value: TextEditingValue) -> TextEditingValue {
        // return value.copyWith(text: text, composing: nil)
        if let composing = value.composing {
            let range =
                composing.start.index(in: value.text)..<composing.end.index(in: value.text)
            return .init(
                text: value.text.replacingCharacters(in: range, with: text),
                selection: .collapsed(offset: composing.start.advanced(by: text.utf16.count)),
                composing: nil
            )
        }
        if let selection = value.selection {
            let range =
                selection.range.start.index(
                    in: value.text
                )..<selection.range.end.index(in: value.text)
            return .init(
                text: value.text.replacingCharacters(in: range, with: text),
                selection: .collapsed(offset: selection.range.start.advanced(by: text.utf16.count)),
                composing: nil
            )
        }
        return value
    }
}

/// A range of text that represents a selection.
public struct TextSelection: Equatable {
    /// Creates a text selection.
    public init(
        baseOffset: TextIndex,
        extentOffset: TextIndex,
        affinity: TextAffinity = .downstream,
        isDirectional: Bool = false
    ) {
        self.baseOffset = baseOffset
        self.extentOffset = extentOffset
        self.affinity = affinity
        self.isDirectional = isDirectional
        self.range = TextRange(
            start: min(baseOffset, extentOffset),
            end: max(baseOffset, extentOffset)
        )
    }

    /// Creates a collapsed selection at the given offset.
    ///
    /// A collapsed selection starts and ends at the same offset, which means it
    /// contains zero characters but instead serves as an insertion point in the
    /// text.
    public static func collapsed(offset: TextIndex, affinity: TextAffinity = .downstream)
        -> TextSelection
    {
        return TextSelection(
            baseOffset: offset,
            extentOffset: offset,
            affinity: affinity
        )
    }

    /// Creates a collapsed selection at the given text position.
    ///
    /// A collapsed selection starts and ends at the same offset, which means it
    /// contains zero characters but instead serves as an insertion point in the
    /// text.
    public static func fromPosition(_ position: TextPosition) -> TextSelection {
        return TextSelection(
            baseOffset: position.offset,
            extentOffset: position.offset,
            affinity: position.affinity,
            isDirectional: false
        )
    }
    /// The range of text that is currently selected. Guaranteed to be
    /// normalized.
    public let range: TextRange

    /// The offset at which the selection originates.
    ///
    /// Might be larger than, smaller than, or equal to extent.
    public let baseOffset: TextIndex

    /// The offset at which the selection terminates.
    ///
    /// When the user uses the arrow keys to adjust the selection, this is the
    /// value that changes. Similarly, if the current theme paints a caret on one
    /// side of the selection, this is the location at which to paint the caret.
    ///
    /// Might be larger than, smaller than, or equal to base.
    public let extentOffset: TextIndex

    /// If the text range is collapsed and has more than one visual location
    /// (e.g., occurs at a line break), which of the two locations to use when
    /// painting the caret.
    public let affinity: TextAffinity

    /// Whether this selection has disambiguated its base and extent.
    ///
    /// On some platforms, the base and extent are not disambiguated until the
    /// first time the user adjusts the selection. At that point, either the start
    /// or the end of the selection becomes the base and the other one becomes the
    /// extent and is adjusted.
    public let isDirectional: Bool

    /// The position at which the selection originates.
    ///
    /// The TextAffinity of the resulting TextPosition is based on the
    /// relative logical position in the text to the other selection endpoint:
    ///  * if baseOffset < extentOffset, base will have
    ///    TextAffinity.downstream and extent will have
    ///    TextAffinity.upstream.
    ///  * if baseOffset > extentOffset, base will have
    ///    TextAffinity.upstream and extent will have
    ///    TextAffinity.downstream.
    ///  * if baseOffset == extentOffset, base and extent will both have
    ///    the collapsed selection's affinity.
    ///
    /// Might be larger than, smaller than, or equal to extent.
    public var base: TextPosition {
        let affinity: TextAffinity
        if baseOffset == extentOffset {
            affinity = self.affinity
        } else if baseOffset < extentOffset {
            affinity = .downstream
        } else {
            affinity = .upstream
        }
        return TextPosition(offset: baseOffset, affinity: affinity)
    }

    /// The position at which the selection terminates.
    ///
    /// When the user uses the arrow keys to adjust the selection, this is the
    /// value that changes. Similarly, if the current theme paints a caret on one
    /// side of the selection, this is the location at which to paint the caret.
    ///
    /// Might be larger than, smaller than, or equal to base.
    public var extent: TextPosition {
        let affinity: TextAffinity
        if baseOffset == extentOffset {
            affinity = self.affinity
        } else if baseOffset < extentOffset {
            affinity = .upstream
        } else {
            affinity = .downstream
        }
        return TextPosition(offset: extentOffset, affinity: affinity)
    }

    /// Creates a new [TextSelection] based on the current selection, with the
    /// provided parameters overridden.
    public func copyWith(
        baseOffset: TextIndex? = nil,
        extentOffset: TextIndex? = nil,
        affinity: TextAffinity? = nil,
        isDirectional: Bool? = nil
    ) -> TextSelection {
        return TextSelection(
            baseOffset: baseOffset ?? self.baseOffset,
            extentOffset: extentOffset ?? self.extentOffset,
            affinity: affinity ?? self.affinity,
            isDirectional: isDirectional ?? self.isDirectional
        )
    }

    /// Returns the smallest [TextSelection] that this could expand to in order to
    /// include the given [TextPosition].
    ///
    /// If the given [TextPosition] is already inside of the selection, then
    /// returns `self` without change.
    ///
    /// The returned selection will always be a strict superset of the current
    /// selection. In other words, the selection grows to include the given
    /// [TextPosition].
    ///
    /// If extentAtIndex is true, then the [TextSelection.extentOffset] will be
    /// placed at the given index regardless of the original order of it and
    /// [TextSelection.baseOffset]. Otherwise, their order will be preserved.
    ///
    /// ## Difference with [extendTo]
    /// In contrast with this method, [extendTo] is a pivot; it holds
    /// [TextSelection.baseOffset] fixed while moving [TextSelection.extentOffset]
    /// to the given [TextPosition]. It doesn't strictly grow the selection and
    /// may collapse it or flip its order.
    public func expandTo(_ position: TextPosition, extentAtIndex: Bool = false) -> TextSelection {
        // If position is already within in the selection, there's nothing to do.
        if position.offset >= range.start && position.offset <= range.end {
            return self
        }

        let normalized = baseOffset <= extentOffset
        if position.offset <= range.start {
            // Here the position is somewhere before the selection: ..|..[...]....
            if extentAtIndex {
                return copyWith(
                    baseOffset: range.end,
                    extentOffset: position.offset,
                    affinity: position.affinity
                )
            }
            return copyWith(
                baseOffset: normalized ? position.offset : baseOffset,
                extentOffset: normalized ? extentOffset : position.offset
            )
        }
        // Here the position is somewhere after the selection: ....[...]..|..
        if extentAtIndex {
            return copyWith(
                baseOffset: range.start,
                extentOffset: position.offset,
                affinity: position.affinity
            )
        }
        return copyWith(
            baseOffset: normalized ? baseOffset : position.offset,
            extentOffset: normalized ? position.offset : extentOffset
        )
    }

    /// Keeping the selection's [TextSelection.baseOffset] fixed, pivot the
    /// [TextSelection.extentOffset] to the given [TextPosition].
    ///
    /// In some cases, the [TextSelection.baseOffset] and
    /// [TextSelection.extentOffset] may flip during this operation, and/or the
    /// size of the selection may shrink.
    ///
    /// ## Difference with [expandTo]
    /// In contrast with this method, [expandTo] is strictly growth; the
    /// selection is grown to include the given [TextPosition] and will never
    /// shrink.
    public func extendTo(_ position: TextPosition) -> TextSelection {
        // If the selection's extent is at the position already, then nothing
        // happens.
        if extent == position {
            return self
        }

        return copyWith(
            extentOffset: position.offset,
            affinity: position.affinity
        )
    }
}

/// A mixin for manipulating the selection, provided for toolbar or shortcut
/// keys.
public protocol TextSelectionDelegate {
    /// Gets the current text input.
    var textEditingValue: TextEditingValue { get }

    /// Indicates that the user has requested the delegate to replace its current
    /// text editing state with [value].
    ///
    /// The new [value] is treated as user input and thus may subject to input
    /// formatting.
    ///
    /// See also:
    ///
    /// * [EditableTextState.userUpdateTextEditingValue]: an implementation that
    ///   applies additional pre-processing to the specified [value], before
    ///   updating the text editing state.
    func userUpdateTextEditingValue(_ value: TextEditingValue, cause: SelectionChangedCause?)
}
