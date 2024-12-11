// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An Intent to send the event straight to the engine.
///
/// See also:
///
///   * DefaultTextEditingShortcuts, which triggers this Intent.
public struct DoNothingAndStopPropagationTextIntent: Intent {
    /// Creates an instance of DoNothingAndStopPropagationTextIntent.
    public init() {}
}

/// A text editing related Intent that performs an operation towards a given
/// direction of the current caret location.
public class DirectionalTextEditingIntent: Intent {
    /// Creates a DirectionalTextEditingIntent.
    public init(forward: Bool) {
        self.forward = forward
    }

    /// Whether the input field, if applicable, should perform the text editing
    /// operation from the current caret location towards the end of the document.
    ///
    /// Unless otherwise specified by the recipient of this intent, this parameter
    /// uses the logical order of characters in the string to determine the
    /// direction, and is not affected by the writing direction of the text.
    var forward: Bool
}

/// Deletes the character before or after the caret location, based on whether
/// `forward` is true.
///
/// Typically a text field will not respond to this intent if it has no active
/// caret (TextSelection.isValid is false for the current selection).
public class DeleteCharacterIntent: DirectionalTextEditingIntent {
    /// Creates a DeleteCharacterIntent.
    public override init(forward: Bool) {
        super.init(forward: forward)
    }
}

/// Deletes from the current caret location to the previous or next word
/// boundary, based on whether `forward` is true.
public class DeleteToNextWordBoundaryIntent: DirectionalTextEditingIntent {
    /// Creates a DeleteToNextWordBoundaryIntent.
    public override init(forward: Bool) {
        super.init(forward: forward)
    }
}

/// Deletes from the current caret location to the previous or next soft or hard
/// line break, based on whether `forward` is true.
public class DeleteToLineBreakIntent: DirectionalTextEditingIntent {
    /// Creates a DeleteToLineBreakIntent.
    public override init(forward: Bool) {
        super.init(forward: forward)
    }
}

/// A DirectionalTextEditingIntent that moves the caret or the selection to a
/// new location.
public class DirectionalCaretMovementIntent: DirectionalTextEditingIntent {
    /// Creates a DirectionalCaretMovementIntent.
    public init(
        forward: Bool,
        collapseSelection: Bool,
        collapseAtReversal: Bool = false,
        continuesAtWrap: Bool = false
    ) {
        assert(!collapseSelection || !collapseAtReversal)
        self.collapseSelection = collapseSelection
        self.collapseAtReversal = collapseAtReversal
        self.continuesAtWrap = continuesAtWrap
        super.init(forward: forward)
    }

    /// Whether this Intent should make the selection collapsed (so it becomes a
    /// caret), after the movement.
    ///
    /// When collapseSelection is false, the input field typically only moves
    /// the current TextSelection.extent to the new location, while maintains
    /// the current TextSelection.base location.
    ///
    /// When collapseSelection is true, the input field typically should move
    /// both the TextSelection.base and the TextSelection.extent to the new
    /// location.
    public let collapseSelection: Bool

    /// Whether to collapse the selection when it would otherwise reverse order.
    ///
    /// For example, consider when forward is true and the extent is before the
    /// base. If collapseAtReversal is true, then this will cause the selection to
    /// collapse at the base. If it's false, then the extent will be placed at the
    /// linebreak, reversing the order of base and offset.
    ///
    /// Cannot be true when collapseSelection is true.
    public let collapseAtReversal: Bool

    /// Whether or not to continue to the next line at a wordwrap.
    ///
    /// If true, when an Intent to go to the beginning/end of a wordwrapped line
    /// is received and the selection is already at the beginning/end of the line,
    /// then the selection will be moved to the next/previous line. If false, the
    /// selection will remain at the wordwrap.
    public let continuesAtWrap: Bool
}

/// Extends, or moves the current selection from the current
/// TextSelection.extent position to the previous or the next character
/// boundary.
public class ExtendSelectionByCharacterIntent: DirectionalCaretMovementIntent {
    /// Creates an ExtendSelectionByCharacterIntent.
    public init(forward: Bool, collapseSelection: Bool) {
        super.init(forward: forward, collapseSelection: collapseSelection)
    }
}

/// Extends, or moves the current selection from the current
/// TextSelection.extent position to the previous or the next word
/// boundary.
public class ExtendSelectionToNextWordBoundaryIntent: DirectionalCaretMovementIntent {
    /// Creates an ExtendSelectionToNextWordBoundaryIntent.
    public init(forward: Bool, collapseSelection: Bool) {
        super.init(forward: forward, collapseSelection: collapseSelection)
    }
}

/// Extends, or moves the current selection from the current
/// TextSelection.extent position to the previous or the next word
/// boundary, or the TextSelection.base position if it's closer in the move
/// direction.
///
/// This Intent typically has the same effect as an
/// ExtendSelectionToNextWordBoundaryIntent, except it collapses the selection
/// when the order of TextSelection.base and TextSelection.extent would
/// reverse.
///
/// This is typically only used on MacOS.
public class ExtendSelectionToNextWordBoundaryOrCaretLocationIntent: DirectionalCaretMovementIntent
{
    /// Creates an ExtendSelectionToNextWordBoundaryOrCaretLocationIntent.
    public init(forward: Bool) {
        super.init(forward: forward, collapseSelection: false, collapseAtReversal: true)
    }
}

/// Expands the current selection to the document boundary in the direction
/// given by forward.
///
/// Unlike ExpandSelectionToLineBreakIntent, the extent will be moved, which
/// matches the behavior on MacOS.
///
/// See also:
///
///   ExtendSelectionToDocumentBoundaryIntent, which is similar but always
///   moves the extent.
public class ExpandSelectionToDocumentBoundaryIntent: DirectionalCaretMovementIntent {
    /// Creates an ExpandSelectionToDocumentBoundaryIntent.
    public init(forward: Bool) {
        super.init(forward: forward, collapseSelection: false)
    }
}

/// Expands the current selection to the closest line break in the direction
/// given by forward.
///
/// Either the base or extent can move, whichever is closer to the line break.
/// The selection will never shrink.
///
/// This behavior is common on MacOS.
///
/// See also:
///
///   ExtendSelectionToLineBreakIntent, which is similar but always moves the
///   extent.
public class ExpandSelectionToLineBreakIntent: DirectionalCaretMovementIntent {
    /// Creates an ExpandSelectionToLineBreakIntent.
    public init(forward: Bool) {
        super.init(forward: forward, collapseSelection: false)
    }
}

/// Extends, or moves the current selection from the current
/// TextSelection.extent position to the closest line break in the direction
/// given by forward.
///
/// See also:
///
///   ExpandSelectionToLineBreakIntent, which is similar but always increases
///   the size of the selection.
public class ExtendSelectionToLineBreakIntent: DirectionalCaretMovementIntent {
    /// Creates an ExtendSelectionToLineBreakIntent.
    public override init(
        forward: Bool,
        collapseSelection: Bool,
        collapseAtReversal: Bool = false,
        continuesAtWrap: Bool = false
    ) {
        assert(!collapseSelection || !collapseAtReversal)
        super.init(
            forward: forward,
            collapseSelection: collapseSelection,
            collapseAtReversal: collapseAtReversal,
            continuesAtWrap: continuesAtWrap
        )
    }
}

/// Extends, or moves the current selection from the current
/// TextSelection.extent position to the closest position on the adjacent
/// line.
public class ExtendSelectionVerticallyToAdjacentLineIntent: DirectionalCaretMovementIntent {
    /// Creates an ExtendSelectionVerticallyToAdjacentLineIntent.
    public init(forward: Bool, collapseSelection: Bool) {
        super.init(forward: forward, collapseSelection: collapseSelection)
    }
}

/// Expands, or moves the current selection from the current
/// TextSelection.extent position to the closest position on the adjacent
/// page.
public class ExtendSelectionVerticallyToAdjacentPageIntent: DirectionalCaretMovementIntent {
    /// Creates an ExtendSelectionVerticallyToAdjacentPageIntent.
    public init(forward: Bool, collapseSelection: Bool) {
        super.init(forward: forward, collapseSelection: collapseSelection)
    }
}

/// Extends, or moves the current selection from the current
/// TextSelection.extent position to the previous or the next paragraph
/// boundary.
public class ExtendSelectionToNextParagraphBoundaryIntent: DirectionalCaretMovementIntent {
    /// Creates an ExtendSelectionToNextParagraphBoundaryIntent.
    public init(forward: Bool, collapseSelection: Bool) {
        super.init(forward: forward, collapseSelection: collapseSelection)
    }
}

/// Extends, or moves the current selection from the current
/// TextSelection.extent position to the previous or the next paragraph
/// boundary depending on the forward parameter.
///
/// This Intent typically has the same effect as an
/// ExtendSelectionToNextParagraphBoundaryIntent, except it collapses the selection
/// when the order of TextSelection.base and TextSelection.extent would
/// reverse.
///
/// This is typically only used on MacOS.
public class ExtendSelectionToNextParagraphBoundaryOrCaretLocationIntent:
    DirectionalCaretMovementIntent
{
    /// Creates an ExtendSelectionToNextParagraphBoundaryOrCaretLocationIntent.
    public init(forward: Bool) {
        super.init(forward: forward, collapseSelection: false, collapseAtReversal: true)
    }
}

/// Extends, or moves the current selection from the current
/// TextSelection.extent position to the start or the end of the document.
///
/// See also:
///
///   ExtendSelectionToDocumentBoundaryIntent, which is similar but always
///   increases the size of the selection.
public class ExtendSelectionToDocumentBoundaryIntent: DirectionalCaretMovementIntent {
    /// Creates an ExtendSelectionToDocumentBoundaryIntent.
    public init(forward: Bool, collapseSelection: Bool) {
        super.init(forward: forward, collapseSelection: collapseSelection)
    }
}

/// Scrolls to the beginning or end of the document depending on the forward
/// parameter.
public class ScrollToDocumentBoundaryIntent: DirectionalTextEditingIntent {
    /// Creates a ScrollToDocumentBoundaryIntent.
    public override init(forward: Bool) {
        super.init(forward: forward)
    }
}

/// Scrolls up or down by page depending on the forward parameter.
/// Extends the selection up or down by page based on the forward parameter.
public class ExtendSelectionByPageIntent: DirectionalTextEditingIntent {
    /// Creates a ExtendSelectionByPageIntent.
    public override init(forward: Bool) {
        super.init(forward: forward)
    }
}

/// An Intent to select everything in the field.
public struct SelectAllTextIntent: Intent {
    /// Creates an instance of SelectAllTextIntent.
    public init(_ cause: SelectionChangedCause) {
        self.cause = cause
    }

    /// The SelectionChangedCause that triggered the intent.
    public let cause: SelectionChangedCause
}

/// An Intent that represents a user interaction that attempts to copy or cut
/// the current selection in the field.
public struct CopySelectionTextIntent: Intent {
    private init(_ cause: SelectionChangedCause, _ collapseSelection: Bool) {
        self.cause = cause
        self.collapseSelection = collapseSelection
    }

    /// Creates an Intent that represents a user interaction that attempts to
    /// cut the current selection in the field.
    public static func cut(_ cause: SelectionChangedCause) -> CopySelectionTextIntent {
        return CopySelectionTextIntent(cause, true)
    }

    /// An Intent that represents a user interaction that attempts to copy the
    /// current selection in the field.
    public static let copy = CopySelectionTextIntent(.keyboard, false)

    /// The SelectionChangedCause that triggered the intent.
    public let cause: SelectionChangedCause

    /// Whether the original text needs to be removed from the input field if the
    /// copy action was successful.
    public let collapseSelection: Bool
}

/// An Intent to paste text from Clipboard to the field.
public class PasteTextIntent: Intent {
    /// Creates an instance of PasteTextIntent.
    public init(_ cause: SelectionChangedCause) {
        self.cause = cause
    }

    /// The SelectionChangedCause that triggered the intent.
    public let cause: SelectionChangedCause
}

/// An Intent that represents a user interaction that attempts to go back to
/// the previous editing state.
public struct RedoTextIntent: Intent {
    /// Creates a RedoTextIntent.
    public init(_ cause: SelectionChangedCause) {
        self.cause = cause
    }

    /// The SelectionChangedCause that triggered the intent.
    public let cause: SelectionChangedCause
}

/// An Intent that represents a user interaction that attempts to modify the
/// current TextEditingValue in an input field.
public struct ReplaceTextIntent: Intent {
    /// Creates a ReplaceTextIntent.
    public init(
        _ currentTextEditingValue: TextEditingValue,
        _ replacementText: String,
        _ replacementRange: TextRange,
        _ cause: SelectionChangedCause
    ) {
        self.currentTextEditingValue = currentTextEditingValue
        self.replacementText = replacementText
        self.replacementRange = replacementRange
        self.cause = cause
    }

    /// The TextEditingValue that this Intent's action should perform on.
    public let currentTextEditingValue: TextEditingValue

    /// The text to replace the original text within the replacementRange with.
    public let replacementText: String

    /// The range of text in currentTextEditingValue that needs to be replaced.
    public let replacementRange: TextRange

    /// The SelectionChangedCause that triggered the intent.
    public let cause: SelectionChangedCause
}

/// An Intent that represents a user interaction that attempts to go back to
/// the previous editing state.
public struct UndoTextIntent: Intent {
    /// Creates an UndoTextIntent.
    public init(_ cause: SelectionChangedCause) {
        self.cause = cause
    }

    /// The SelectionChangedCause that triggered the intent.
    public let cause: SelectionChangedCause
}

/// An Intent that represents a user interaction that attempts to change the
/// selection in an input field.
public struct UpdateSelectionIntent: Intent {
    /// Creates an UpdateSelectionIntent.
    public init(
        _ currentTextEditingValue: TextEditingValue,
        _ newSelection: TextSelection,
        _ cause: SelectionChangedCause
    ) {
        self.currentTextEditingValue = currentTextEditingValue
        self.newSelection = newSelection
        self.cause = cause
    }

    /// The TextEditingValue that this Intent's action should perform on.
    public let currentTextEditingValue: TextEditingValue

    /// The new TextSelection the input field should adopt.
    public let newSelection: TextSelection

    /// The SelectionChangedCause that triggered the intent.
    public let cause: SelectionChangedCause
}

/// An Intent that represents a user interaction that attempts to swap the
/// characters immediately around the cursor.
public struct TransposeCharactersIntent: Intent {
    /// Creates a TransposeCharactersIntent.
    public init() {}
}
