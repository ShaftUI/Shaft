// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A widget with the shortcuts used for the default text editing behavior.
///
/// This default behavior can be overridden by placing a [Shortcuts] widget
/// lower in the widget tree than this. See the [Action] class for an example
/// of remapping an [Intent] to a custom [Action].
///
/// The [Shortcuts] widget usually takes precedence over system keybindings.
/// Proceed with caution if the shortcut you wish to override is also used by
/// the system. For example, overriding [LogicalKeyboardKey.backspace] could
/// cause CJK input methods to discard more text than they should when the
/// backspace key is pressed during text composition on iOS.
///
/// See also:
///
///   * [WidgetsApp], which creates a DefaultTextEditingShortcuts.
public class DefaultTextEditingShortcuts: StatelessWidget {
    /// Creates a DefaultTextEditingShortcuts widget that provides the default text editing
    /// shortcuts on the current platform.
    public init(@WidgetBuilder child: () -> Widget) {
        self.child = child()
    }

    /// The widget below this widget in the tree.
    public let child: Widget

    // These shortcuts are shared between all platforms except Apple platforms,
    // because they use different modifier keys as the line/word modifier.
    // swift-format-ignore
    static let _commonShortcuts: [ActivatorIntentPair] = {
      // Delete Shortcuts.
      var shortcuts: [ActivatorIntentPair] = []
      for pressShift in [true, false] {
        shortcuts += [
          (SingleActivator(LogicalKeyboardKey.backspace, shift: pressShift), DeleteCharacterIntent(forward: false)),
          (SingleActivator(LogicalKeyboardKey.backspace, control: true, shift: pressShift), DeleteToNextWordBoundaryIntent(forward: false)),
          (SingleActivator(LogicalKeyboardKey.backspace, alt: true, shift: pressShift), DeleteToLineBreakIntent(forward: false)),
          (SingleActivator(LogicalKeyboardKey.delete, shift: pressShift), DeleteCharacterIntent(forward: true)),
          (SingleActivator(LogicalKeyboardKey.delete, control: true, shift: pressShift), DeleteToNextWordBoundaryIntent(forward: true)),
          (SingleActivator(LogicalKeyboardKey.delete, alt: true, shift: pressShift), DeleteToLineBreakIntent(forward: true))
        ]
      }

      shortcuts += [
        // Arrow: Move selection.
        (SingleActivator(LogicalKeyboardKey.arrowLeft), ExtendSelectionByCharacterIntent(forward: false, collapseSelection: true)),
        (SingleActivator(LogicalKeyboardKey.arrowRight), ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true)),
        (SingleActivator(LogicalKeyboardKey.arrowUp), ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: true)),
        (SingleActivator(LogicalKeyboardKey.arrowDown), ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: true)),

        // Shift + Arrow: Extend selection.
        (SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true), ExtendSelectionByCharacterIntent(forward: false, collapseSelection: false)),
        (SingleActivator(LogicalKeyboardKey.arrowRight, shift: true), ExtendSelectionByCharacterIntent(forward: true, collapseSelection: false)),
        (SingleActivator(LogicalKeyboardKey.arrowUp, shift: true), ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: false)),
        (SingleActivator(LogicalKeyboardKey.arrowDown, shift: true), ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: false)),

        (SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true), ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true)),
        (SingleActivator(LogicalKeyboardKey.arrowRight, alt: true), ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true)),
        (SingleActivator(LogicalKeyboardKey.arrowUp, alt: true), ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: true)),
        (SingleActivator(LogicalKeyboardKey.arrowDown, alt: true), ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: true)),

        (SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true, shift: true), ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false)),
        (SingleActivator(LogicalKeyboardKey.arrowRight, alt: true, shift: true), ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false)),
        (SingleActivator(LogicalKeyboardKey.arrowUp, alt: true, shift: true), ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: false)),
        (SingleActivator(LogicalKeyboardKey.arrowDown, alt: true, shift: true), ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: false)),

        (SingleActivator(LogicalKeyboardKey.arrowLeft, control: true), ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: true)),
        (SingleActivator(LogicalKeyboardKey.arrowRight, control: true), ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: true)),

        (SingleActivator(LogicalKeyboardKey.arrowLeft, control: true, shift: true), ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: false)),
        (SingleActivator(LogicalKeyboardKey.arrowRight, control: true, shift: true), ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: false)),

        (SingleActivator(LogicalKeyboardKey.arrowUp, control: true, shift: true), ExtendSelectionToNextParagraphBoundaryIntent(forward: false, collapseSelection: false)),
        (SingleActivator(LogicalKeyboardKey.arrowDown, control: true, shift: true), ExtendSelectionToNextParagraphBoundaryIntent(forward: true, collapseSelection: false)),

        // Page Up / Down: Move selection by page.
        (SingleActivator(LogicalKeyboardKey.pageUp), ExtendSelectionVerticallyToAdjacentPageIntent(forward: false, collapseSelection: true)),
        (SingleActivator(LogicalKeyboardKey.pageDown), ExtendSelectionVerticallyToAdjacentPageIntent(forward: true, collapseSelection: true)),

        // Shift + Page Up / Down: Extend selection by page.
        (SingleActivator(LogicalKeyboardKey.pageUp, shift: true), ExtendSelectionVerticallyToAdjacentPageIntent(forward: false, collapseSelection: false)),
        (SingleActivator(LogicalKeyboardKey.pageDown, shift: true), ExtendSelectionVerticallyToAdjacentPageIntent(forward: true, collapseSelection: false)),

        (SingleActivator(LogicalKeyboardKey.keyX, control: true), CopySelectionTextIntent.cut(SelectionChangedCause.keyboard)),
        (SingleActivator(LogicalKeyboardKey.keyC, control: true), CopySelectionTextIntent.copy),
        (SingleActivator(LogicalKeyboardKey.keyV, control: true), PasteTextIntent(SelectionChangedCause.keyboard)),
        (SingleActivator(LogicalKeyboardKey.keyA, control: true), SelectAllTextIntent(SelectionChangedCause.keyboard)),
        (SingleActivator(LogicalKeyboardKey.keyZ, control: true), UndoTextIntent(SelectionChangedCause.keyboard)),
        (SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true), RedoTextIntent(SelectionChangedCause.keyboard)),

        // These keys should go to the IME when a field is focused, not to other
        // Shortcuts.
        (SingleActivator(LogicalKeyboardKey.space), DoNothingAndStopPropagationTextIntent()),
        (SingleActivator(LogicalKeyboardKey.enter), DoNothingAndStopPropagationTextIntent()),
      ]

      return shortcuts
  }()

    // The following key combinations have no effect on text editing on this
    // platform:
    //   * End
    //   * Home
    //   * Meta + X
    //   * Meta + C
    //   * Meta + V
    //   * Meta + A
    //   * Meta + shift? + Z
    //   * Meta + shift? + arrow down
    //   * Meta + shift? + arrow left
    //   * Meta + shift? + arrow right
    //   * Meta + shift? + arrow up
    //   * Shift + end
    //   * Shift + home
    //   * Meta + shift? + delete
    //   * Meta + shift? + backspace
    static let _androidShortcuts: [ActivatorIntentPair] = _commonShortcuts

    static let _fuchsiaShortcuts: [ActivatorIntentPair] = _androidShortcuts

    //   static final List<ActivateIntentPair> _linuxNumpadShortcuts = <ActivateIntentPair>{
    //     // When numLock is on, numpad keys shortcuts require shift to be pressed too.
    //     const SingleActivator(LogicalKeyboardKey.numpad6, shift: true, numLock: LockState.locked): const ExtendSelectionByCharacterIntent(forward: true, collapseSelection: false),
    //     const SingleActivator(LogicalKeyboardKey.numpad4, shift: true, numLock: LockState.locked): const ExtendSelectionByCharacterIntent(forward: false, collapseSelection: false),
    //     const SingleActivator(LogicalKeyboardKey.numpad8, shift: true, numLock: LockState.locked): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: false),
    //     const SingleActivator(LogicalKeyboardKey.numpad2, shift: true, numLock: LockState.locked): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: false),

    //     const SingleActivator(LogicalKeyboardKey.numpad6, shift: true, control: true, numLock: LockState.locked): const ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: false),
    //     const SingleActivator(LogicalKeyboardKey.numpad4, shift: true, control: true, numLock: LockState.locked): const ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: false),
    //     const SingleActivator(LogicalKeyboardKey.numpad8, shift: true, control: true, numLock: LockState.locked): const ExtendSelectionToNextParagraphBoundaryIntent(forward: false, collapseSelection: false),
    //     const SingleActivator(LogicalKeyboardKey.numpad2, shift: true, control: true, numLock: LockState.locked): const ExtendSelectionToNextParagraphBoundaryIntent(forward: true, collapseSelection: false),

    //     const SingleActivator(LogicalKeyboardKey.numpad9, shift: true, numLock: LockState.locked): const ExtendSelectionVerticallyToAdjacentPageIntent(forward: false, collapseSelection: false),
    //     const SingleActivator(LogicalKeyboardKey.numpad3, shift: true, numLock: LockState.locked): const ExtendSelectionVerticallyToAdjacentPageIntent(forward: true, collapseSelection: false),

    //     const SingleActivator(LogicalKeyboardKey.numpad7, shift: true, numLock: LockState.locked): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: false),
    //     const SingleActivator(LogicalKeyboardKey.numpad1, shift: true, numLock: LockState.locked): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: false),

    //     const SingleActivator(LogicalKeyboardKey.numpadDecimal, shift: true, numLock: LockState.locked): const DeleteCharacterIntent(forward: true),
    //     const SingleActivator(LogicalKeyboardKey.numpadDecimal, shift: true, control: true, numLock: LockState.locked): const DeleteToNextWordBoundaryIntent(forward: true),

    //     // When numLock is off, numpad keys shortcuts require shift not to be pressed.
    //     const SingleActivator(LogicalKeyboardKey.numpad6, numLock: LockState.unlocked): const ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true),
    //     const SingleActivator(LogicalKeyboardKey.numpad4, numLock: LockState.unlocked): const ExtendSelectionByCharacterIntent(forward: false, collapseSelection: true),
    //     const SingleActivator(LogicalKeyboardKey.numpad8, numLock: LockState.unlocked): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: true),
    //     const SingleActivator(LogicalKeyboardKey.numpad2, numLock: LockState.unlocked): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: true),

    //     const SingleActivator(LogicalKeyboardKey.numpad6, control: true, numLock: LockState.unlocked): const ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: true),
    //     const SingleActivator(LogicalKeyboardKey.numpad4, control: true, numLock: LockState.unlocked): const ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: true),
    //     const SingleActivator(LogicalKeyboardKey.numpad8, control: true, numLock: LockState.unlocked): const ExtendSelectionToNextParagraphBoundaryIntent(forward: false, collapseSelection: true),
    //     const SingleActivator(LogicalKeyboardKey.numpad2, control: true, numLock: LockState.unlocked): const ExtendSelectionToNextParagraphBoundaryIntent(forward: true, collapseSelection: true),

    //     const SingleActivator(LogicalKeyboardKey.numpad9, numLock: LockState.unlocked): const ExtendSelectionVerticallyToAdjacentPageIntent(forward: false, collapseSelection: true),
    //     const SingleActivator(LogicalKeyboardKey.numpad3, numLock: LockState.unlocked): const ExtendSelectionVerticallyToAdjacentPageIntent(forward: true, collapseSelection: true),

    //     const SingleActivator(LogicalKeyboardKey.numpad7, numLock: LockState.unlocked): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: true),
    //     const SingleActivator(LogicalKeyboardKey.numpad1, numLock: LockState.unlocked): const ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: true),

    //     const SingleActivator(LogicalKeyboardKey.numpadDecimal, numLock: LockState.unlocked): const DeleteCharacterIntent(forward: true),
    //     const SingleActivator(LogicalKeyboardKey.numpadDecimal, control: true, numLock: LockState.unlocked): const DeleteToNextWordBoundaryIntent(forward: true),
    //   };

    //   static final List<ActivateIntentPair> _linuxShortcuts = <ActivateIntentPair>{
    //     ..._commonShortcuts,
    //     ..._linuxNumpadShortcuts,
    //     const SingleActivator(LogicalKeyboardKey.home): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true),
    //     const SingleActivator(LogicalKeyboardKey.end): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true),
    //     const SingleActivator(LogicalKeyboardKey.home, shift: true): const ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false),
    //     const SingleActivator(LogicalKeyboardKey.end, shift: true): const ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false),
    //     // The following key combinations have no effect on text editing on this
    //     // platform:
    //     //   * Control + shift? + end
    //     //   * Control + shift? + home
    //     //   * Meta + X
    //     //   * Meta + C
    //     //   * Meta + V
    //     //   * Meta + A
    //     //   * Meta + shift? + Z
    //     //   * Meta + shift? + arrow down
    //     //   * Meta + shift? + arrow left
    //     //   * Meta + shift? + arrow right
    //     //   * Meta + shift? + arrow up
    //     //   * Meta + shift? + delete
    //     //   * Meta + shift? + backspace
    //   };

    // macOS document shortcuts: https://support.apple.com/en-us/HT201236.
    // The macOS shortcuts uses different word/line modifiers than most other
    // platforms.
    // swift-format-ignore
    static let _macShortcuts: [ActivatorIntentPair] = {
        var shortcuts: [ActivatorIntentPair] = []
        for pressShift in [true, false] {
          shortcuts += [
            (SingleActivator(LogicalKeyboardKey.backspace, shift: pressShift), DeleteCharacterIntent(forward: false)),
            (SingleActivator(LogicalKeyboardKey.backspace, alt: true, shift: pressShift), DeleteToNextWordBoundaryIntent(forward: false)),
            (SingleActivator(LogicalKeyboardKey.backspace, meta: true, shift: pressShift), DeleteToLineBreakIntent(forward: false)),
            (SingleActivator(LogicalKeyboardKey.delete, shift: pressShift), DeleteCharacterIntent(forward: true)),
            (SingleActivator(LogicalKeyboardKey.delete, alt: true, shift: pressShift), DeleteToNextWordBoundaryIntent(forward: true)),
            (SingleActivator(LogicalKeyboardKey.delete, meta: true, shift: pressShift), DeleteToLineBreakIntent(forward: true))
          ]
        }

        shortcuts += [
          (SingleActivator(LogicalKeyboardKey.arrowLeft), ExtendSelectionByCharacterIntent(forward: false, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.arrowRight), ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.arrowUp), ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.arrowDown), ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: true)),

          // Shift + Arrow: Extend selection.
          (SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true), ExtendSelectionByCharacterIntent(forward: false, collapseSelection: false)),
          (SingleActivator(LogicalKeyboardKey.arrowRight, shift: true), ExtendSelectionByCharacterIntent(forward: true, collapseSelection: false)),
          (SingleActivator(LogicalKeyboardKey.arrowUp, shift: true), ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: false)),
          (SingleActivator(LogicalKeyboardKey.arrowDown, shift: true), ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: false)),

          (SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true), ExtendSelectionToNextWordBoundaryIntent(forward: false, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.arrowRight, alt: true), ExtendSelectionToNextWordBoundaryIntent(forward: true, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.arrowUp, alt: true), ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.arrowDown, alt: true), ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true)),

          (SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true, shift: true), ExtendSelectionToNextWordBoundaryOrCaretLocationIntent(forward: false)),
          (SingleActivator(LogicalKeyboardKey.arrowRight, alt: true, shift: true), ExtendSelectionToNextWordBoundaryOrCaretLocationIntent(forward: true)),
          (SingleActivator(LogicalKeyboardKey.arrowUp, alt: true, shift: true), ExtendSelectionToNextParagraphBoundaryOrCaretLocationIntent(forward: false)),
          (SingleActivator(LogicalKeyboardKey.arrowDown, alt: true, shift: true), ExtendSelectionToNextParagraphBoundaryOrCaretLocationIntent(forward: true)),

          (SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true), ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.arrowRight, meta: true), ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.arrowUp, meta: true), ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.arrowDown, meta: true), ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: true)),

          (SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true, shift: true), ExpandSelectionToLineBreakIntent(forward: false)),
          (SingleActivator(LogicalKeyboardKey.arrowRight, meta: true, shift: true), ExpandSelectionToLineBreakIntent(forward: true)),
          (SingleActivator(LogicalKeyboardKey.arrowUp, meta: true, shift: true), ExpandSelectionToDocumentBoundaryIntent(forward: false)),
          (SingleActivator(LogicalKeyboardKey.arrowDown, meta: true, shift: true), ExpandSelectionToDocumentBoundaryIntent(forward: true)),

          (SingleActivator(LogicalKeyboardKey.keyT, control: true), TransposeCharactersIntent()),

          (SingleActivator(LogicalKeyboardKey.home), ScrollToDocumentBoundaryIntent(forward: false)),
          (SingleActivator(LogicalKeyboardKey.end), ScrollToDocumentBoundaryIntent(forward: true)),
          (SingleActivator(LogicalKeyboardKey.home, shift: true), ExpandSelectionToDocumentBoundaryIntent(forward: false)),
          (SingleActivator(LogicalKeyboardKey.end, shift: true), ExpandSelectionToDocumentBoundaryIntent(forward: true)),

          (SingleActivator(LogicalKeyboardKey.pageUp), ScrollIntent(direction: .up, type: .page)),
          (SingleActivator(LogicalKeyboardKey.pageDown), ScrollIntent(direction: .down, type: .page)),
          (SingleActivator(LogicalKeyboardKey.pageUp, shift: true), ExtendSelectionVerticallyToAdjacentPageIntent(forward: false, collapseSelection: false)),
          (SingleActivator(LogicalKeyboardKey.pageDown, shift: true), ExtendSelectionVerticallyToAdjacentPageIntent(forward: true, collapseSelection: false)),

          (SingleActivator(LogicalKeyboardKey.keyX, meta: true), CopySelectionTextIntent.cut(.keyboard)),
          (SingleActivator(LogicalKeyboardKey.keyC, meta: true), CopySelectionTextIntent.copy),
          (SingleActivator(LogicalKeyboardKey.keyV, meta: true), PasteTextIntent(.keyboard)),
          (SingleActivator(LogicalKeyboardKey.keyA, meta: true), SelectAllTextIntent(.keyboard)),
          (SingleActivator(LogicalKeyboardKey.keyZ, meta: true), UndoTextIntent(.keyboard)),
          (SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true), RedoTextIntent(.keyboard)),
          (SingleActivator(LogicalKeyboardKey.keyE, control: true), ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.keyA, control: true), ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.keyF, control: true), ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.keyB, control: true), ExtendSelectionByCharacterIntent(forward: false, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.keyN, control: true), ExtendSelectionVerticallyToAdjacentLineIntent(forward: true, collapseSelection: true)),
          (SingleActivator(LogicalKeyboardKey.keyP, control: true), ExtendSelectionVerticallyToAdjacentLineIntent(forward: false, collapseSelection: true)),
          // These keys should go to the IME when a field is focused, not to other
          // Shortcuts.
          (SingleActivator(LogicalKeyboardKey.space), DoNothingAndStopPropagationTextIntent()),
          (SingleActivator(LogicalKeyboardKey.enter), DoNothingAndStopPropagationTextIntent())
        ]
        // The following key combinations have no effect on text editing on this
        // platform:
        //   * End
        //   * Home
        //   * Control + shift? + end
        //   * Control + shift? + home
        //   * Control + shift? + Z
        return shortcuts
      }()

    // There is no complete documentation of iOS shortcuts: use macOS ones.
    static let _iOSShortcuts = _macShortcuts

    // The following key combinations have no effect on text editing on this
    // platform:
    //   * Meta + X
    //   * Meta + C
    //   * Meta + V
    //   * Meta + A
    //   * Meta + shift? + arrow down
    //   * Meta + shift? + arrow left
    //   * Meta + shift? + arrow right
    //   * Meta + shift? + arrow up
    //   * Meta + delete
    //   * Meta + backspace
    static let _windowsShortcuts: [ActivatorIntentPair] = {
        var shortcuts = _commonShortcuts
        // shortcuts += [
        //   (SingleActivator(LogicalKeyboardKey.pageUp), ExtendSelectionVerticallyToAdjacentPageIntent(forward: false, collapseSelection: true)),
        //   (SingleActivator(LogicalKeyboardKey.pageDown), ExtendSelectionVerticallyToAdjacentPageIntent(forward: true, collapseSelection: true)),
        //   (SingleActivator(LogicalKeyboardKey.home), ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: true, continuesAtWrap: true)),
        //   (SingleActivator(LogicalKeyboardKey.end), ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: true, continuesAtWrap: true)),
        //   (SingleActivator(LogicalKeyboardKey.home, shift: true), ExtendSelectionToLineBreakIntent(forward: false, collapseSelection: false, continuesAtWrap: true)),
        //   (SingleActivator(LogicalKeyboardKey.end, shift: true), ExtendSelectionToLineBreakIntent(forward: true, collapseSelection: false, continuesAtWrap: true)),
        //   (SingleActivator(LogicalKeyboardKey.home, control: true), ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: true)),
        //   (SingleActivator(LogicalKeyboardKey.end, control: true), ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: true)),
        //   (SingleActivator(LogicalKeyboardKey.home, shift: true, control: true), ExtendSelectionToDocumentBoundaryIntent(forward: false, collapseSelection: false)),
        //   (SingleActivator(LogicalKeyboardKey.end, shift: true, control: true), ExtendSelectionToDocumentBoundaryIntent(forward: true, collapseSelection: false))
        // ]
        return shortcuts
    }()

    //   // Web handles its text selection natively and doesn't use any of these
    //   // shortcuts in Flutter.
    //   static final List<ActivateIntentPair> _webDisablingTextShortcuts = <ActivateIntentPair>{
    //     for (final bool pressShift in const <bool>[true, false])
    //       ...<SingleActivator, Intent>{
    //         SingleActivator(LogicalKeyboardKey.backspace, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
    //         SingleActivator(LogicalKeyboardKey.delete, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
    //         SingleActivator(LogicalKeyboardKey.backspace, alt: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
    //         SingleActivator(LogicalKeyboardKey.delete, alt: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
    //         SingleActivator(LogicalKeyboardKey.backspace, control: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
    //         SingleActivator(LogicalKeyboardKey.delete, control: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
    //         SingleActivator(LogicalKeyboardKey.backspace, meta: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
    //         SingleActivator(LogicalKeyboardKey.delete, meta: true, shift: pressShift): const DoNothingAndStopPropagationTextIntent(),
    //       },
    //     ..._commonDisablingTextShortcuts,
    //     const SingleActivator(LogicalKeyboardKey.keyX, control: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.keyX, meta: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.keyC, control: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.keyC, meta: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.keyV, control: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.keyV, meta: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.keyA, control: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.keyA, meta: true): const DoNothingAndStopPropagationTextIntent(),
    //   };

    //   static const List<ActivateIntentPair> _commonDisablingTextShortcuts = <ActivateIntentPair>{
    //     SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowDown, meta: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowRight, meta: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowUp, meta: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowDown): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowLeft): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowRight): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowUp): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowRight, control: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, control: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, control: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.space): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.enter): DoNothingAndStopPropagationTextIntent(),
    //   };

    //   static final List<ActivateIntentPair> _macDisablingTextShortcuts = <ActivateIntentPair>{
    //     ..._commonDisablingTextShortcuts,
    //     ..._iOSDisablingTextShortcuts,
    //     const SingleActivator(LogicalKeyboardKey.escape): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.tab): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.tab, shift: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true, alt: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true, alt: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, alt: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, alt: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true, meta: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true, meta: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.pageUp): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.pageDown): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.end): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.home): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.pageUp, shift: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.pageDown, shift: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.end, shift: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.home, shift: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.end, control: true): const DoNothingAndStopPropagationTextIntent(),
    //     const SingleActivator(LogicalKeyboardKey.home, control: true): const DoNothingAndStopPropagationTextIntent(),
    //   };

    //   // Hand backspace/delete events that do not depend on text layout (delete
    //   // character and delete to the next word) back to the IME to allow it to
    //   // update composing text properly.
    //   static const List<ActivateIntentPair> _iOSDisablingTextShortcuts = <ActivateIntentPair>{
    //     SingleActivator(LogicalKeyboardKey.backspace): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.backspace, shift: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.delete): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.delete, shift: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.backspace, alt: true, shift: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.backspace, alt: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.delete, alt: true, shift: true): DoNothingAndStopPropagationTextIntent(),
    //     SingleActivator(LogicalKeyboardKey.delete, alt: true): DoNothingAndStopPropagationTextIntent(),
    //   };

    static var shortcuts: [ActivatorIntentPair] {
        return switch backend.targetPlatform {
        case .android: _androidShortcuts
        case .fuchsia: _fuchsiaShortcuts
        case .iOS: _iOSShortcuts
        // case .linux:  _linuxShortcuts
        case .macOS: _macShortcuts
        case .windows: _windowsShortcuts
        default: _commonShortcuts
        }
    }

    func _getDisablingShortcut() -> [ActivatorIntentPair]? {
        // if kIsWeb {
        //     switch defaultTargetPlatform {
        //     case .linux:
        //         return [
        //             _webDisablingTextShortcuts,
        //             _linuxNumpadShortcuts.keys.reduce(into: [:]) { result, activator in
        //                 result[activator as! SingleActivator] =
        //                     DoNothingAndStopPropagationTextIntent()
        //             },
        //         ].reduce([:]) { $0.merging($1) { $1 } }
        //     case .android,
        //         .fuchsia,
        //         .windows,
        //         .iOS,
        //         .macOS:
        //         return _webDisablingTextShortcuts
        //     }
        // }
        // switch defaultTargetPlatform {
        // case .android,
        //     .fuchsia,
        //     .linux,
        //     .windows:
        //     return nil
        // case .iOS:
        //     return _iOSDisablingTextShortcuts
        // case .macOS:
        //     return _macDisablingTextShortcuts
        // }

        return nil
    }

    public func build(context: BuildContext) -> Widget {
        var result = child
        let disablingShortcut = _getDisablingShortcut()
        if let disablingShortcut {
            // These shortcuts make sure of the following:
            //
            // 1. Shortcuts fired when an EditableText is focused are ignored and
            //    forwarded to the platform by the EditableText's Actions, because it
            //    maps DoNothingAndStopPropagationTextIntent to DoNothingAction.
            // 2. Shortcuts fired when no EditableText is focused will still trigger
            //    _shortcuts assuming DoNothingAndStopPropagationTextIntent is
            //    unhandled elsewhere.
            result = Shortcuts(
                shortcuts: disablingShortcut,
                debugLabel: "<Web Disabling Text Editing Shortcuts>"
            ) {
                result
            }
        }
        return Shortcuts(
            shortcuts: Self.shortcuts,
            debugLabel: "<Default Text Editing Shortcuts>"
        ) {
            result
        }
    }
}
