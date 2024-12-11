// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Builds a [TextSelectionGestureDetector] to wrap an [EditableText].
///
/// The class implements sensible defaults for many user interactions
/// with an [EditableText] (see the documentation of the various gesture handler
/// methods, e.g. [onTapDown], [onForcePressStart], etc.). Subclasses of
/// [TextSelectionGestureDetectorBuilder] can change the behavior performed in
/// responds to these gesture events by overriding the corresponding handler
/// methods of this class.
///
/// The resulting [TextSelectionGestureDetector] to wrap an [EditableText] is
/// obtained by calling [buildGestureDetector].
///
/// A [TextSelectionGestureDetectorBuilder] must be provided a
/// [TextSelectionGestureDetectorBuilderDelegate], from which information about
/// the [EditableText] may be obtained. Typically, the [State] of the widget
/// that builds the [EditableText] implements this interface, and then passes
/// itself as the [delegate].
///
/// See also:
///
///  * [TextField], which uses a subclass to implement the Material-specific
///    gesture logic of an [EditableText].
///  * [CupertinoTextField], which uses a subclass to implement the
///    Cupertino-specific gesture logic of an [EditableText].
public class TextSelectionGestureDetectorBuilder {
    /// Delegate interface for the [TextSelectionGestureDetectorBuilder].
    ///
    /// The interface is usually implemented by the [State] of text field
    /// implementations wrapping [EditableText], so that they can use a
    /// [TextSelectionGestureDetectorBuilder] to build a
    /// [TextSelectionGestureDetector] for their [EditableText]. The delegate
    /// provides the builder with information about the current state of the text
    /// field. Based on that information, the builder adds the correct gesture
    /// handlers to the gesture detector.
    ///
    /// See also:
    ///
    ///  * [TextField], which implements this delegate for the Material text field.
    ///  * [CupertinoTextField], which implements this delegate for the Cupertino
    ///    text field.
    public protocol Delegate: AnyObject {
        /// [GlobalKey] to the [EditableText] for which the
        /// [TextSelectionGestureDetectorBuilder] will build a [TextSelectionGestureDetector].
        var editableTextKey: StateGlobalKey<EditableTextState> { get }

        /// Whether the text field should respond to force presses.
        var forcePressEnabled: Bool { get }

        /// Whether the user may select text in the text field.
        var selectionEnabled: Bool { get }
    }

    /// Creates a [TextSelectionGestureDetectorBuilder].

    public init(delegate: Delegate) {
        self.delegate = delegate
    }

    /// The delegate for this [TextSelectionGestureDetectorBuilder].
    ///
    /// The delegate provides the builder with ∆information about what actions can
    /// currently be performed on the text field. Based on this, the builder adds
    /// the correct gesture handlers to the gesture detector.
    ///
    /// Typically implemented by a [State] of a widget that builds an
    /// [EditableText].
    public weak var delegate: Delegate!

    /// Shows the magnifier on supported platforms at the given offset, currently
    /// only Android and iOS.
    private func showMagnifierIfSupportedByPlatform(at positionToShow: Offset) {
        switch backend.targetPlatform {
        case .android, .iOS:
            // editableText.showMagnifier(at: positionToShow)
            ()
        default:
            break
        }
    }

    /// Hides the magnifier on supported platforms, currently only Android and iOS.
    private func hideMagnifierIfSupportedByPlatform() {
        switch backend.targetPlatform {
        case .android, .iOS:
            // editableText.hideMagnifier()
            ()
        default:
            break
        }
    }

    //   /// Returns true if lastSecondaryTapDownPosition was on selection.
    //   bool get _lastSecondaryTapWasOnSelection {
    //     assert(renderEditable.lastSecondaryTapDownPosition != null);
    //     if (renderEditable.selection == null) {
    //       return false;
    //     }

    //     final TextPosition textPosition = renderEditable.getPositionForPoint(
    //       renderEditable.lastSecondaryTapDownPosition!,
    //     );

    //     return renderEditable.selection!.start <= textPosition.offset
    //         && renderEditable.selection!.end >= textPosition.offset;
    //   }

    //   bool _positionWasOnSelectionExclusive(TextPosition textPosition) {
    //     final TextSelection? selection = renderEditable.selection;
    //     if (selection == null) {
    //       return false;
    //     }

    //     return selection.start < textPosition.offset
    //         && selection.end > textPosition.offset;
    //   }

    //   bool _positionWasOnSelectionInclusive(TextPosition textPosition) {
    //     final TextSelection? selection = renderEditable.selection;
    //     if (selection == null) {
    //       return false;
    //     }

    //     return selection.start <= textPosition.offset
    //         && selection.end >= textPosition.offset;
    //   }

    //   // Expand the selection to the given global position.
    //   //
    //   // Either base or extent will be moved to the last tapped position, whichever
    //   // is closest. The selection will never shrink or pivot, only grow.
    //   //
    //   // If fromSelection is given, will expand from that selection instead of the
    //   // current selection in renderEditable.
    //   //
    //   // See also:
    //   //
    //   //   * [extendSelection], which is similar but pivots the selection around
    //   //     the base.
    //   void expandSelection(Offset offset, SelectionChangedCause cause, [TextSelection? fromSelection]) {
    //     assert(renderEditable.selection?.baseOffset != null);

    //     final TextPosition tappedPosition = renderEditable.getPositionForPoint(offset);
    //     final TextSelection selection = fromSelection ?? renderEditable.selection!;
    //     final bool baseIsCloser =
    //         (tappedPosition.offset - selection.baseOffset).abs()
    //         < (tappedPosition.offset - selection.extentOffset).abs();
    //     final TextSelection nextSelection = selection.copyWith(
    //       baseOffset: baseIsCloser ? selection.extentOffset : selection.baseOffset,
    //       extentOffset: tappedPosition.offset,
    //     );

    //     editableText.userUpdateTextEditingValue(
    //       editableText.textEditingValue.copyWith(
    //         selection: nextSelection,
    //       ),
    //       cause,
    //     );
    //   }

    // Expand the selection to the given global position.
    //
    // Either base or extent will be moved to the last tapped position, whichever
    // is closest. The selection will never shrink or pivot, only grow.
    //
    // If fromSelection is given, will expand from that selection instead of the
    // current selection in renderEditable.
    //
    // See also:
    //
    //   * [_extendSelection], which is similar but pivots the selection around
    //     the base.
    private func expandSelection(
        _ offset: Offset,
        cause: SelectionChangedCause,
        fromSelection: TextSelection? = nil
    ) {
        assert(renderEditable.selection?.baseOffset != nil)

        let tappedPosition = renderEditable.getPositionForPoint(offset)
        let selection = fromSelection ?? renderEditable.selection!
        let baseIsCloser =
            (tappedPosition.offset.utf16Offset - selection.baseOffset.utf16Offset).magnitude
            < (tappedPosition.offset.utf16Offset - selection.extentOffset.utf16Offset).magnitude
        let nextSelection = selection.copyWith(
            baseOffset: baseIsCloser ? selection.extentOffset : selection.baseOffset,
            extentOffset: tappedPosition.offset
        )

        editableText.userUpdateTextEditingValue(
            editableText.textEditingValue.copyWith(
                selection: nextSelection
            ),
            cause: cause
        )
    }

    // Extend the selection to the given global position.
    //
    // Holds the base in place and moves the extent.
    //
    // See also:
    //
    //   * [expandSelection], which is similar but always increases the size of
    //     the selection.
    private func extendSelection(_ offset: Offset, cause: SelectionChangedCause) {
        assert(renderEditable.selection?.baseOffset != nil)

        let tappedPosition = renderEditable.getPositionForPoint(offset)
        let selection = renderEditable.selection!
        let nextSelection = selection.copyWith(
            extentOffset: tappedPosition.offset
        )

        editableText.userUpdateTextEditingValue(
            editableText.textEditingValue.copyWith(
                selection: nextSelection
            ),
            cause: cause
        )
    }

    /// Whether to show the selection toolbar.
    ///
    /// It is based on the signal source when a [onTapDown] is called. This getter
    /// will return true if current [onTapDown] event is triggered by a touch or
    /// a stylus.
    private(set) var shouldShowSelectionToolbar = true

    /// The [State] of the [EditableText] for which the builder will provide a
    /// [TextSelectionGestureDetector].
    var editableText: EditableTextState { delegate.editableTextKey.getState()! }

    /// The [RenderObject] of the [EditableText] for which the builder will
    /// provide a [TextSelectionGestureDetector].
    var renderEditable: RenderEditable { editableText.renderEditable }

    /// Whether the Shift key was pressed when the most recent [PointerDownEvent]
    /// was tracked by the [BaseTapAndDragGestureRecognizer].
    private var isShiftPressed = false

    /// The viewport offset pixels of any [Scrollable] containing the
    /// [RenderEditable] at the last drag start.
    private var dragStartScrollOffset: Float = 0.0

    /// The viewport offset pixels of the [RenderEditable] at the last drag start.
    private var dragStartViewportOffset: Float = 0.0

    private var scrollPosition: Float {
        let scrollableState =
            delegate.editableTextKey.currentContext == nil
            ? nil
            : Scrollable.maybeOf(delegate.editableTextKey.currentContext!)
        return scrollableState == nil
            ? 0.0
            : scrollableState!.position.pixels
    }

    private var scrollDirection: AxisDirection? {
        let scrollableState =
            delegate.editableTextKey.currentContext == nil
            ? nil
            : Scrollable.maybeOf(delegate.editableTextKey.currentContext!)
        return scrollableState?.axisDirection
    }

    //   // For a shift + tap + drag gesture, the TextSelection at the point of the
    //   // tap. Mac uses this value to reset to the original selection when an
    //   // inversion of the base and offset happens.
    private var dragStartSelection: TextSelection?

    //   // For iOS long press behavior when the field is not focused. iOS uses this value
    //   // to determine if a long press began on a field that was not focused.
    //   //
    //   // If the field was not focused when the long press began, a long press will select
    //   // the word and a long press move will select word-by-word. If the field was
    //   // focused, the cursor moves to the long press position.
    //   bool _longPressStartedWithoutFocus = false;

    // Selects the set of paragraphs in a document that intersect a given range of
    // global positions.
    private func selectParagraphsInRange(from: Offset, to: Offset?, cause: SelectionChangedCause?) {
        let paragraphBoundary = ParagraphBoundary(editableText.textEditingValue.text)
        selectTextBoundariesInRange(boundary: paragraphBoundary, from: from, to: to, cause: cause)
    }

    // Selects the set of lines in a document that intersect a given range of
    // global positions.
    private func selectLinesInRange(from: Offset, to: Offset?, cause: SelectionChangedCause?) {
        let lineBoundary = LineBoundary(renderEditable)
        selectTextBoundariesInRange(boundary: lineBoundary, from: from, to: to, cause: cause)
    }

    // Returns the location of a text boundary at `extent`. When `extent` is at
    // the end of the text, returns the previous text boundary's location.
    private func moveToTextBoundary(_ extent: TextPosition, _ textBoundary: TextBoundary)
        -> TextRange
    {
        assert(extent.offset >= .zero)
        // Use extent.offset - 1 when `extent` is at the end of the text to retrieve
        // the previous text boundary's location.
        let start =
            textBoundary.getLeadingTextBoundaryAt(
                extent.offset.utf16Offset == editableText.textEditingValue.text.utf16.count
                    ? extent.offset.advanced(by: -1) : extent.offset
            ) ?? .zero
        let end =
            textBoundary.getTrailingTextBoundaryAt(extent.offset)
            ?? .init(utf16Offset: editableText.textEditingValue.text.utf16.count)
        return TextRange(start: start, end: end)
    }

    // Selects the set of text boundaries in a document that intersect a given
    // range of global positions.
    //
    // The set of text boundaries selected are not strictly bounded by the range
    // of global positions.
    //
    // The first and last endpoints of the selection will always be at the
    // beginning and end of a text boundary respectively.
    private func selectTextBoundariesInRange(
        boundary: TextBoundary,
        from: Offset,
        to: Offset?,
        cause: SelectionChangedCause?
    ) {
        let fromPosition = renderEditable.getPositionForPoint(from)
        let fromRange = moveToTextBoundary(fromPosition, boundary)
        let toPosition = to == nil ? fromPosition : renderEditable.getPositionForPoint(to!)
        let toRange =
            toPosition == fromPosition ? fromRange : moveToTextBoundary(toPosition, boundary)
        let isFromBoundaryBeforeToBoundary = fromRange.start < toRange.end

        let newSelection =
            isFromBoundaryBeforeToBoundary
            ? TextSelection(baseOffset: fromRange.start, extentOffset: toRange.end)
            : TextSelection(baseOffset: fromRange.end, extentOffset: toRange.start)

        editableText.userUpdateTextEditingValue(
            editableText.textEditingValue.copyWith(selection: newSelection),
            cause: cause
        )
    }

    /// Handler for [TextSelectionGestureDetector.onTapTrackStart].
    ///
    /// See also:
    ///
    ///  * [TextSelectionGestureDetector.onTapTrackStart], which triggers this
    ///    callback.
    func onTapTrackStart() {
        isShiftPressed =
            HardwareKeyboard.shared.logicalKeysPressed
            .intersection([LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight])
            .isNotEmpty
    }

    /// Handler for [TextSelectionGestureDetector.onTapTrackReset].
    ///
    /// See also:
    ///
    ///  * [TextSelectionGestureDetector.onTapTrackReset], which triggers this
    ///    callback.
    func onTapTrackReset() {
        isShiftPressed = false
    }

    /// Handler for [TextSelectionGestureDetector.onTapDown].
    ///
    /// By default, it forwards the tap to [RenderEditable.handleTapDown] and sets
    /// [shouldShowSelectionToolbar] to true if the tap was initiated by a finger or stylus.
    ///
    /// See also:
    ///
    ///  * [TextSelectionGestureDetector.onTapDown], which triggers this callback.
    func onTapDown(_ details: TapDragDownDetails) {
        if !delegate.selectionEnabled {
            return
        }
        // TODO(Renzo-Olivares): Migrate text selection gestures away from saving state
        // in renderEditable. The gesture callbacks can use the details objects directly
        // in callbacks variants that provide them [TapGestureRecognizer.onSecondaryTap]
        // vs [TapGestureRecognizer.onSecondaryTapUp] instead of having to track state in
        // renderEditable. When this migration is complete we should remove this hack.
        // See https://github.com/flutter/flutter/issues/115130.
        renderEditable.handleTapDown(event: TapDownDetails(globalPosition: details.globalPosition))
        // The selection overlay should only be shown when the user is interacting
        // through a touch screen (via either a finger or a stylus). A mouse shouldn't
        // trigger the selection overlay.
        // For backwards-compatibility, we treat a null kind the same as touch.
        let kind = details.kind
        // TODO(justinmc): Should a desktop platform show its selection toolbar when
        // receiving a tap event?  Say a Windows device with a touchscreen.
        // https://github.com/flutter/flutter/issues/106586
        shouldShowSelectionToolbar =
            kind == nil
            || kind == .touch
            || kind == .stylus

        // It is impossible to extend the selection when the shift key is pressed, if the
        // renderEditable.selection is invalid.
        let isShiftPressedValid = isShiftPressed && renderEditable.selection?.baseOffset != nil
        switch backend.targetPlatform {
        case .android, .fuchsia, .iOS:
            // On mobile platforms the selection is set on tap up.
            break
        case .macOS:
            editableText.hideToolbar()
            // On macOS, a shift-tapped unfocused field expands from 0, not from the
            // previous selection.
            if isShiftPressedValid {
                let fromSelection =
                    renderEditable.hasFocus
                    ? nil
                    : TextSelection.collapsed(offset: .zero)
                expandSelection(
                    details.globalPosition,
                    cause: .tap,
                    fromSelection: fromSelection
                )
                return
            }
            // On macOS, a tap/click places the selection in a precise position.
            // This differs from iOS/iPadOS, where if the gesture is done by a touch
            // then the selection moves to the closest word edge, instead of a
            // precise position.
            renderEditable.selectPosition(cause: .tap)
        case .linux, .windows, nil:
            editableText.hideToolbar()
            if isShiftPressedValid {
                extendSelection(details.globalPosition, cause: .tap)
                return
            }
            renderEditable.selectPosition(cause: .tap)
        }
    }

    //   /// Handler for [TextSelectionGestureDetector.onForcePressStart].
    //   ///
    //   /// By default, it selects the word at the position of the force press,
    //   /// if selection is enabled.
    //   ///
    //   /// This callback is only applicable when force press is enabled.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [TextSelectionGestureDetector.onForcePressStart], which triggers this
    //   ///    callback.
    //   @protected
    //   void onForcePressStart(ForcePressDetails details) {
    //     assert(delegate.forcePressEnabled);
    //     shouldShowSelectionToolbar = true;
    //     if (delegate.selectionEnabled) {
    //       renderEditable.selectWordsInRange(
    //         from: details.globalPosition,
    //         cause: SelectionChangedCause.forcePress,
    //       );
    //     }
    //   }

    //   /// Handler for [TextSelectionGestureDetector.onForcePressEnd].
    //   ///
    //   /// By default, it selects words in the range specified in [details] and shows
    //   /// toolbar if it is necessary.
    //   ///
    //   /// This callback is only applicable when force press is enabled.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [TextSelectionGestureDetector.onForcePressEnd], which triggers this
    //   ///    callback.
    //   @protected
    //   void onForcePressEnd(ForcePressDetails details) {
    //     assert(delegate.forcePressEnabled);
    //     renderEditable.selectWordsInRange(
    //       from: details.globalPosition,
    //       cause: SelectionChangedCause.forcePress,
    //     );
    //     if (shouldShowSelectionToolbar) {
    //       editableText.showToolbar();
    //     }
    //   }

    //   /// Whether the provided [onUserTap] callback should be dispatched on every
    //   /// tap or only non-consecutive taps.
    //   ///
    //   /// Defaults to false.
    //   @protected
    //   bool get onUserTapAlwaysCalled => false;

    //   /// Handler for [TextSelectionGestureDetector.onUserTap].
    //   ///
    //   /// By default, it serves as placeholder to enable subclass override.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [TextSelectionGestureDetector.onUserTap], which triggers this
    //   ///    callback.
    //   ///  * [TextSelectionGestureDetector.onUserTapAlwaysCalled], which controls
    //   ///     whether this callback is called only on the first tap in a series
    //   ///     of taps.
    //   @protected
    //   void onUserTap() { /* Subclass should override this method if needed. */ }

    //   /// Handler for [TextSelectionGestureDetector.onSingleTapUp].
    //   ///
    //   /// By default, it selects word edge if selection is enabled.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [TextSelectionGestureDetector.onSingleTapUp], which triggers
    //   ///    this callback.
    //   @protected
    //   void onSingleTapUp(TapDragUpDetails details) {
    //     if (delegate.selectionEnabled) {
    //       // It is impossible to extend the selection when the shift key is pressed, if the
    //       // renderEditable.selection is invalid.
    //       final bool isShiftPressedValid = isShiftPressed && renderEditable.selection?.baseOffset != null;
    //       switch (defaultTargetPlatform) {
    //         case TargetPlatform.linux:
    //         case TargetPlatform.macOS:
    //         case TargetPlatform.windows:
    //           break;
    //           // On desktop platforms the selection is set on tap down.
    //         case TargetPlatform.android:
    //           editableText.hideToolbar(false);
    //           if (isShiftPressedValid) {
    //             extendSelection(details.globalPosition, SelectionChangedCause.tap);
    //             return;
    //           }
    //           renderEditable.selectPosition(cause: SelectionChangedCause.tap);
    //           editableText.showSpellCheckSuggestionsToolbar();
    //         case TargetPlatform.fuchsia:
    //           editableText.hideToolbar(false);
    //           if (isShiftPressedValid) {
    //             extendSelection(details.globalPosition, SelectionChangedCause.tap);
    //             return;
    //           }
    //           renderEditable.selectPosition(cause: SelectionChangedCause.tap);
    //         case TargetPlatform.iOS:
    //           if (isShiftPressedValid) {
    //             // On iOS, a shift-tapped unfocused field expands from 0, not from
    //             // the previous selection.
    //             final TextSelection? fromSelection = renderEditable.hasFocus
    //                 ? null
    //                 : const TextSelection.collapsed(offset: 0);
    //             expandSelection(
    //               details.globalPosition,
    //               SelectionChangedCause.tap,
    //               fromSelection,
    //             );
    //             return;
    //           }
    //           switch (details.kind) {
    //             case PointerDeviceKind.mouse:
    //             case PointerDeviceKind.trackpad:
    //             case PointerDeviceKind.stylus:
    //             case PointerDeviceKind.invertedStylus:
    //               // TODO(camsim99): Determine spell check toolbar behavior in these cases:
    //               // https://github.com/flutter/flutter/issues/119573.
    //               // Precise devices should place the cursor at a precise position if the
    //               // word at the text position is not misspelled.
    //               renderEditable.selectPosition(cause: SelectionChangedCause.tap);
    //             case PointerDeviceKind.touch:
    //             case PointerDeviceKind.unknown:
    //               // If the word that was tapped is misspelled, select the word and show the spell check suggestions
    //               // toolbar once. If additional taps are made on a misspelled word, toggle the toolbar. If the word
    //               // is not misspelled, default to the following behavior:
    //               //
    //               // Toggle the toolbar if the `previousSelection` is collapsed, the tap is on the selection, the
    //               // TextAffinity remains the same, and the editable is focused. The TextAffinity is important when the
    //               // cursor is on the boundary of a line wrap, if the affinity is different (i.e. it is downstream), the
    //               // selection should move to the following line and not toggle the toolbar.
    //               //
    //               // Toggle the toolbar when the tap is exclusively within the bounds of a non-collapsed `previousSelection`,
    //               // and the editable is focused.
    //               //
    //               // Selects the word edge closest to the tap when the editable is not focused, or if the tap was neither exclusively
    //               // or inclusively on `previousSelection`. If the selection remains the same after selecting the word edge, then we
    //               // toggle the toolbar. If the selection changes then we hide the toolbar.
    //               final TextSelection previousSelection = renderEditable.selection ?? editableText.textEditingValue.selection;
    //               final TextPosition textPosition = renderEditable.getPositionForPoint(details.globalPosition);
    //               final bool isAffinityTheSame = textPosition.affinity == previousSelection.affinity;
    //               final bool wordAtCursorIndexIsMisspelled = editableText.findSuggestionSpanAtCursorIndex(textPosition.offset) != null;

    //               if (wordAtCursorIndexIsMisspelled) {
    //                 renderEditable.selectWord(cause: SelectionChangedCause.tap);
    //                 if (previousSelection != editableText.textEditingValue.selection) {
    //                   editableText.showSpellCheckSuggestionsToolbar();
    //                 } else {
    //                   editableText.toggleToolbar(false);
    //                 }
    //               } else if (((_positionWasOnSelectionExclusive(textPosition) && !previousSelection.isCollapsed) || (_positionWasOnSelectionInclusive(textPosition) && previousSelection.isCollapsed && isAffinityTheSame)) && renderEditable.hasFocus) {
    //                 editableText.toggleToolbar(false);
    //               } else {
    //                 renderEditable.selectWordEdge(cause: SelectionChangedCause.tap);
    //                 if (previousSelection == editableText.textEditingValue.selection && renderEditable.hasFocus) {
    //                   editableText.toggleToolbar(false);
    //                 } else {
    //                   editableText.hideToolbar(false);
    //                 }
    //               }
    //           }
    //       }
    //     }
    //     editableText.requestKeyboard();
    //   }

    //   /// Handler for [TextSelectionGestureDetector.onSingleTapCancel].
    //   ///
    //   /// By default, it serves as placeholder to enable subclass override.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [TextSelectionGestureDetector.onSingleTapCancel], which triggers
    //   ///    this callback.
    //   @protected
    //   void onSingleTapCancel() { /* Subclass should override this method if needed. */ }

    //   /// Handler for [TextSelectionGestureDetector.onSingleLongTapStart].
    //   ///
    //   /// By default, it selects text position specified in [details] if selection
    //   /// is enabled.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [TextSelectionGestureDetector.onSingleLongTapStart], which triggers
    //   ///    this callback.
    //   @protected
    //   void onSingleLongTapStart(LongPressStartDetails details) {
    //     if (delegate.selectionEnabled) {
    //       switch (defaultTargetPlatform) {
    //         case TargetPlatform.iOS:
    //         case TargetPlatform.macOS:
    //           if (!renderEditable.hasFocus) {
    //             _longPressStartedWithoutFocus = true;
    //             renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    //           } else {
    //             renderEditable.selectPositionAt(
    //               from: details.globalPosition,
    //               cause: SelectionChangedCause.longPress,
    //             );
    //             // Show the floating cursor.
    //             final RawFloatingCursorPoint cursorPoint = RawFloatingCursorPoint(
    //               state: FloatingCursorDragState.Start,
    //               startLocation: (
    //                 renderEditable.globalToLocal(details.globalPosition),
    //                 TextPosition(
    //                   offset: editableText.textEditingValue.selection.baseOffset,
    //                   affinity: editableText.textEditingValue.selection.affinity,
    //                 ),
    //               ),
    //               offset: Offset.zero,
    //             );
    //             editableText.updateFloatingCursor(cursorPoint);
    //           }
    //         case TargetPlatform.android:
    //         case TargetPlatform.fuchsia:
    //         case TargetPlatform.linux:
    //         case TargetPlatform.windows:
    //           renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    //       }

    //       showMagnifierIfSupportedByPlatform(details.globalPosition);

    //       dragStartViewportOffset = renderEditable.offset.pixels;
    //       dragStartScrollOffset = scrollPosition;
    //     }
    //   }

    //   /// Handler for [TextSelectionGestureDetector.onSingleLongTapMoveUpdate].
    //   ///
    //   /// By default, it updates the selection location specified in [details] if
    //   /// selection is enabled.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [TextSelectionGestureDetector.onSingleLongTapMoveUpdate], which
    //   ///    triggers this callback.
    //   @protected
    //   void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    //     if (delegate.selectionEnabled) {
    //       // Adjust the drag start offset for possible viewport offset changes.
    //       final Offset editableOffset = renderEditable.maxLines == 1
    //           ? Offset(renderEditable.offset.pixels - dragStartViewportOffset, 0.0)
    //           : Offset(0.0, renderEditable.offset.pixels - dragStartViewportOffset);
    //       final Offset scrollableOffset = switch (axisDirectionToAxis(scrollDirection ?? AxisDirection.left)) {
    //         Axis.horizontal => Offset(scrollPosition - dragStartScrollOffset, 0.0),
    //         Axis.vertical   => Offset(0.0, scrollPosition - dragStartScrollOffset),
    //       };
    //       switch (defaultTargetPlatform) {
    //         case TargetPlatform.iOS:
    //         case TargetPlatform.macOS:
    //           if (_longPressStartedWithoutFocus) {
    //             renderEditable.selectWordsInRange(
    //               from: details.globalPosition - details.offsetFromOrigin - editableOffset - scrollableOffset,
    //               to: details.globalPosition,
    //               cause: SelectionChangedCause.longPress,
    //             );
    //           } else {
    //             renderEditable.selectPositionAt(
    //               from: details.globalPosition,
    //               cause: SelectionChangedCause.longPress,
    //             );
    //             // Update the floating cursor.
    //             final RawFloatingCursorPoint cursorPoint = RawFloatingCursorPoint(
    //               state: FloatingCursorDragState.Update,
    //               offset: details.offsetFromOrigin,
    //             );
    //             editableText.updateFloatingCursor(cursorPoint);
    //           }
    //         case TargetPlatform.android:
    //         case TargetPlatform.fuchsia:
    //         case TargetPlatform.linux:
    //         case TargetPlatform.windows:
    //           renderEditable.selectWordsInRange(
    //             from: details.globalPosition - details.offsetFromOrigin - editableOffset - scrollableOffset,
    //             to: details.globalPosition,
    //             cause: SelectionChangedCause.longPress,
    //           );
    //       }

    //       showMagnifierIfSupportedByPlatform(details.globalPosition);
    //     }
    //   }

    //   /// Handler for [TextSelectionGestureDetector.onSingleLongTapEnd].
    //   ///
    //   /// By default, it shows toolbar if necessary.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [TextSelectionGestureDetector.onSingleLongTapEnd], which triggers this
    //   ///    callback.
    //   @protected
    //   void onSingleLongTapEnd(LongPressEndDetails details) {
    //     _hideMagnifierIfSupportedByPlatform();
    //     if (shouldShowSelectionToolbar) {
    //       editableText.showToolbar();
    //     }
    //     _longPressStartedWithoutFocus = false;
    //     dragStartViewportOffset = 0.0;
    //     dragStartScrollOffset = 0.0;
    //     if (defaultTargetPlatform == TargetPlatform.iOS && delegate.selectionEnabled && editableText.textEditingValue.selection.isCollapsed) {
    //       // Update the floating cursor.
    //       final RawFloatingCursorPoint cursorPoint = RawFloatingCursorPoint(
    //         state: FloatingCursorDragState.End
    //       );
    //       editableText.updateFloatingCursor(cursorPoint);
    //     }
    //   }

    //   /// Handler for [TextSelectionGestureDetector.onSecondaryTap].
    //   ///
    //   /// By default, selects the word if possible and shows the toolbar.
    //   @protected
    //   void onSecondaryTap() {
    //     if (!delegate.selectionEnabled) {
    //       return;
    //     }
    //     switch (defaultTargetPlatform) {
    //       case TargetPlatform.iOS:
    //       case TargetPlatform.macOS:
    //         if (!_lastSecondaryTapWasOnSelection || !renderEditable.hasFocus) {
    //           renderEditable.selectWord(cause: SelectionChangedCause.tap);
    //         }
    //         if (shouldShowSelectionToolbar) {
    //           editableText.hideToolbar();
    //           editableText.showToolbar();
    //         }
    //       case TargetPlatform.android:
    //       case TargetPlatform.fuchsia:
    //       case TargetPlatform.linux:
    //       case TargetPlatform.windows:
    //         if (!renderEditable.hasFocus) {
    //           renderEditable.selectPosition(cause: SelectionChangedCause.tap);
    //         }
    //         editableText.toggleToolbar();
    //     }
    //   }

    //   /// Handler for [TextSelectionGestureDetector.onSecondaryTapDown].
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [TextSelectionGestureDetector.onSecondaryTapDown], which triggers this
    //   ///    callback.
    //   ///  * [onSecondaryTap], which is typically called after this.
    //   @protected
    //   void onSecondaryTapDown(TapDownDetails details) {
    //     // TODO(Renzo-Olivares): Migrate text selection gestures away from saving state
    //     // in renderEditable. The gesture callbacks can use the details objects directly
    //     // in callbacks variants that provide them [TapGestureRecognizer.onSecondaryTap]
    //     // vs [TapGestureRecognizer.onSecondaryTapUp] instead of having to track state in
    //     // renderEditable. When this migration is complete we should remove this hack.
    //     // See https://github.com/flutter/flutter/issues/115130.
    //     renderEditable.handleSecondaryTapDown(TapDownDetails(globalPosition: details.globalPosition));
    //     shouldShowSelectionToolbar = true;
    //   }

    //   /// Handler for [TextSelectionGestureDetector.onDoubleTapDown].
    //   ///
    //   /// By default, it selects a word through [RenderEditable.selectWord] if
    //   /// selectionEnabled and shows toolbar if necessary.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [TextSelectionGestureDetector.onDoubleTapDown], which triggers this
    //   ///    callback.
    //   @protected
    //   void onDoubleTapDown(TapDragDownDetails details) {
    //     if (delegate.selectionEnabled) {
    //       renderEditable.selectWord(cause: SelectionChangedCause.doubleTap);
    //       if (shouldShowSelectionToolbar) {
    //         editableText.showToolbar();
    //       }
    //     }
    //   }

    //   // Selects the set of paragraphs in a document that intersect a given range of
    //   // global positions.
    //   void selectParagraphsInRange({required Offset from, Offset? to, SelectionChangedCause? cause}) {
    //     final TextBoundary paragraphBoundary = ParagraphBoundary(editableText.textEditingValue.text);
    //     selectTextBoundariesInRange(boundary: paragraphBoundary, from: from, to: to, cause: cause);
    //   }

    //   // Selects the set of lines in a document that intersect a given range of
    //   // global positions.
    //   void selectLinesInRange({required Offset from, Offset? to, SelectionChangedCause? cause}) {
    //     final TextBoundary lineBoundary = LineBoundary(renderEditable);
    //     selectTextBoundariesInRange(boundary: lineBoundary, from: from, to: to, cause: cause);
    //   }

    //   // Returns the location of a text boundary at `extent`. When `extent` is at
    //   // the end of the text, returns the previous text boundary's location.
    //   TextRange moveToTextBoundary(TextPosition extent, TextBoundary textBoundary) {
    //     assert(extent.offset >= 0);
    //     // Use extent.offset - 1 when `extent` is at the end of the text to retrieve
    //     // the previous text boundary's location.
    //     final int start = textBoundary.getLeadingTextBoundaryAt(extent.offset == editableText.textEditingValue.text.length ? extent.offset - 1 : extent.offset) ?? 0;
    //     final int end = textBoundary.getTrailingTextBoundaryAt(extent.offset) ?? editableText.textEditingValue.text.length;
    //     return TextRange(start: start, end: end);
    //   }

    //   // Selects the set of text boundaries in a document that intersect a given
    //   // range of global positions.
    //   //
    //   // The set of text boundaries selected are not strictly bounded by the range
    //   // of global positions.
    //   //
    //   // The first and last endpoints of the selection will always be at the
    //   // beginning and end of a text boundary respectively.
    //   void selectTextBoundariesInRange({required TextBoundary boundary, required Offset from, Offset? to, SelectionChangedCause? cause}) {
    //     final TextPosition fromPosition = renderEditable.getPositionForPoint(from);
    //     final TextRange fromRange = moveToTextBoundary(fromPosition, boundary);
    //     final TextPosition toPosition = to == null
    //         ? fromPosition
    //         : renderEditable.getPositionForPoint(to);
    //     final TextRange toRange = toPosition == fromPosition
    //         ? fromRange
    //         : moveToTextBoundary(toPosition, boundary);
    //     final bool isFromBoundaryBeforeToBoundary = fromRange.start < toRange.end;

    //     final TextSelection newSelection = isFromBoundaryBeforeToBoundary
    //         ? TextSelection(baseOffset: fromRange.start, extentOffset: toRange.end)
    //         : TextSelection(baseOffset: fromRange.end, extentOffset: toRange.start);

    //     editableText.userUpdateTextEditingValue(
    //       editableText.textEditingValue.copyWith(selection: newSelection),
    //       cause,
    //     );
    //   }

    //   /// Handler for [TextSelectionGestureDetector.onTripleTapDown].
    //   ///
    //   /// By default, it selects a paragraph if
    //   /// [TextSelectionGestureDetectorBuilderDelegate.selectionEnabled] is true
    //   /// and shows the toolbar if necessary.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [TextSelectionGestureDetector.onTripleTapDown], which triggers this
    //   ///    callback.
    //   @protected
    //   void onTripleTapDown(TapDragDownDetails details) {
    //     if (!delegate.selectionEnabled) {
    //       return;
    //     }
    //     if (renderEditable.maxLines == 1) {
    //       editableText.selectAll(SelectionChangedCause.tap);
    //     } else {
    //       switch (defaultTargetPlatform) {
    //         case TargetPlatform.android:
    //         case TargetPlatform.fuchsia:
    //         case TargetPlatform.iOS:
    //         case TargetPlatform.macOS:
    //         case TargetPlatform.windows:
    //           selectParagraphsInRange(from: details.globalPosition, cause: SelectionChangedCause.tap);
    //         case TargetPlatform.linux:
    //           selectLinesInRange(from: details.globalPosition, cause: SelectionChangedCause.tap);
    //       }
    //     }
    //     if (shouldShowSelectionToolbar) {
    //       editableText.showToolbar();
    //     }
    //   }

    /// Handler for [TextSelectionGestureDetector.onDragSelectionStart].
    ///
    /// By default, it selects a text position specified in [details].
    ///
    /// See also:
    ///
    ///  * [TextSelectionGestureDetector.onDragSelectionStart], which triggers
    ///    this callback.
    func onDragSelectionStart(_ details: TapDragStartDetails) {
        if !delegate.selectionEnabled {
            return
        }
        let kind = details.kind
        shouldShowSelectionToolbar =
            kind == nil
            || kind == .touch
            || kind == .stylus

        dragStartSelection = renderEditable.selection
        dragStartScrollOffset = scrollPosition
        dragStartViewportOffset = renderEditable.offset.pixels

        if _TextSelectionGestureDetectorState.getEffectiveConsecutiveTapCount(
            details.consecutiveTapCount
        ) > 1 {
            // Do not set the selection on a consecutive tap and drag.
            return
        }

        if isShiftPressed && renderEditable.selection != nil {
            switch backend.targetPlatform {
            case .iOS, .macOS:
                expandSelection(details.globalPosition, cause: .drag)
            case .android, .fuchsia, .linux, .windows, nil:
                extendSelection(details.globalPosition, cause: .drag)
            }
        } else {
            switch backend.targetPlatform {
            case .iOS:
                switch details.kind {
                case .mouse, .trackpad:
                    renderEditable.selectPositionAt(
                        from: details.globalPosition,
                        cause: .drag
                    )
                case .stylus, .invertedStylus, .touch, nil:
                    break
                }
            case .android, .fuchsia:
                switch details.kind {
                case .mouse, .trackpad:
                    renderEditable.selectPositionAt(
                        from: details.globalPosition,
                        cause: .drag
                    )
                case .stylus, .invertedStylus, .touch:
                    // For Android, Fuchsia, and iOS platforms, a touch drag
                    // does not initiate unless the editable has focus.
                    if renderEditable.hasFocus {
                        renderEditable.selectPositionAt(
                            from: details.globalPosition,
                            cause: .drag
                        )
                        showMagnifierIfSupportedByPlatform(at: details.globalPosition)
                    }
                case nil:
                    break
                }
            case .linux, .macOS, .windows, nil:
                renderEditable.selectPositionAt(
                    from: details.globalPosition,
                    cause: .drag
                )
            }
        }
    }

    /// Handler for [TextSelectionGestureDetector.onDragSelectionUpdate].
    ///
    /// By default, it updates the selection location specified in the provided
    /// details objects.
    ///
    /// See also:
    ///
    ///  * [TextSelectionGestureDetector.onDragSelectionUpdate], which triggers
    ///    this callback.
    func onDragSelectionUpdate(_ details: TapDragUpdateDetails) {
        if !delegate.selectionEnabled {
            return
        }

        if !isShiftPressed {
            // Adjust the drag start offset for possible viewport offset changes.
            let editableOffset =
                renderEditable.maxLines == 1
                ? Offset(renderEditable.offset.pixels - dragStartViewportOffset, 0.0)
                : Offset(0.0, renderEditable.offset.pixels - dragStartViewportOffset)
            let scrollableOffset =
                switch (scrollDirection ?? .left).axis {
                case .horizontal:
                    Offset(scrollPosition - dragStartScrollOffset, 0.0)
                case .vertical:
                    Offset(0.0, scrollPosition - dragStartScrollOffset)
                }
            let dragStartGlobalPosition = details.globalPosition - details.offsetFromOrigin

            // Select word by word.
            if _TextSelectionGestureDetectorState.getEffectiveConsecutiveTapCount(
                details.consecutiveTapCount
            ) == 2 {
                renderEditable.selectWordsInRange(
                    from: dragStartGlobalPosition - editableOffset - scrollableOffset,
                    to: details.globalPosition,
                    cause: .drag
                )

                switch details.kind {
                case .stylus, .invertedStylus, .touch:
                    return showMagnifierIfSupportedByPlatform(at: details.globalPosition)
                case .mouse, .trackpad, nil:
                    return
                }
            }

            // Select paragraph-by-paragraph.
            if _TextSelectionGestureDetectorState.getEffectiveConsecutiveTapCount(
                details.consecutiveTapCount
            ) == 3 {
                switch backend.targetPlatform {
                case .android, .fuchsia, .iOS:
                    switch details.kind {
                    case .mouse, .trackpad:
                        return selectParagraphsInRange(
                            from: dragStartGlobalPosition - editableOffset - scrollableOffset,
                            to: details.globalPosition,
                            cause: .drag
                        )
                    case .stylus, .invertedStylus, .touch, nil:
                        // Triple tap to drag is not present on these platforms when using
                        // non-precise pointer devices at the moment.
                        break
                    }
                    return
                case .linux:
                    return selectLinesInRange(
                        from: dragStartGlobalPosition - editableOffset - scrollableOffset,
                        to: details.globalPosition,
                        cause: .drag
                    )
                case .windows, .macOS, nil:
                    return selectParagraphsInRange(
                        from: dragStartGlobalPosition - editableOffset - scrollableOffset,
                        to: details.globalPosition,
                        cause: .drag
                    )
                }
            }

            switch backend.targetPlatform {
            case .iOS:
                // With a mouse device, a drag should select the range from the origin of the drag
                // to the current position of the drag.
                //
                // With a touch device, nothing should happen.
                switch details.kind {
                case .mouse, .trackpad:
                    return renderEditable.selectPositionAt(
                        from: dragStartGlobalPosition - editableOffset - scrollableOffset,
                        to: details.globalPosition,
                        cause: .drag
                    )
                case .stylus, .invertedStylus, .touch, nil:
                    break
                }
                return
            case .android, .fuchsia:
                // With a precise pointer device, such as a mouse, trackpad, or stylus,
                // the drag will select the text spanning the origin of the drag to the end of the drag.
                // With a touch device, the cursor should move with the drag.
                switch details.kind {
                case .mouse, .trackpad, .stylus, .invertedStylus:
                    return renderEditable.selectPositionAt(
                        from: dragStartGlobalPosition - editableOffset - scrollableOffset,
                        to: details.globalPosition,
                        cause: .drag
                    )
                case .touch:
                    if renderEditable.hasFocus {
                        renderEditable.selectPositionAt(
                            from: details.globalPosition,
                            cause: .drag
                        )
                        return showMagnifierIfSupportedByPlatform(at: details.globalPosition)
                    }
                case nil:
                    break
                }
                return
            case .macOS, .linux, .windows, nil:
                return renderEditable.selectPositionAt(
                    from: dragStartGlobalPosition - editableOffset - scrollableOffset,
                    to: details.globalPosition,
                    cause: .drag
                )
            }
        }

        if dragStartSelection!.range.isCollapsed
            || (backend.targetPlatform != .iOS
                && backend.targetPlatform != .macOS)
        {
            return extendSelection(details.globalPosition, cause: .drag)
        }

        // If the drag inverts the selection, Mac and iOS revert to the initial
        // selection.
        let selection = editableText.textEditingValue.selection
        let nextExtent = renderEditable.getPositionForPoint(details.globalPosition)
        let isShiftTapDragSelectionForward =
            dragStartSelection!.baseOffset < dragStartSelection!.extentOffset
        let isInverted =
            isShiftTapDragSelectionForward
            ? nextExtent.offset < dragStartSelection!.baseOffset
            : nextExtent.offset > dragStartSelection!.baseOffset
        if let selection, isInverted && selection.baseOffset == dragStartSelection!.baseOffset {
            editableText.userUpdateTextEditingValue(
                editableText.textEditingValue.copyWith(
                    selection: TextSelection(
                        baseOffset: dragStartSelection!.extentOffset,
                        extentOffset: nextExtent.offset
                    )
                ),
                cause: .drag
            )
        } else if let selection,
            !isInverted
                && nextExtent.offset != dragStartSelection!.baseOffset
                && selection.baseOffset != dragStartSelection!.baseOffset
        {
            editableText.userUpdateTextEditingValue(
                editableText.textEditingValue.copyWith(
                    selection: TextSelection(
                        baseOffset: dragStartSelection!.baseOffset,
                        extentOffset: nextExtent.offset
                    )
                ),
                cause: .drag
            )
        } else {
            extendSelection(details.globalPosition, cause: .drag)
        }
    }

    /// Handler for [TextSelectionGestureDetector.onDragSelectionEnd].
    ///
    /// By default, it cleans up the state used for handling certain
    /// built-in behaviors.
    ///
    /// See also:
    ///
    ///  * [TextSelectionGestureDetector.onDragSelectionEnd], which triggers this
    ///    callback.
    func onDragSelectionEnd(_ details: TapDragEndDetails) {
        if shouldShowSelectionToolbar
            && _TextSelectionGestureDetectorState.getEffectiveConsecutiveTapCount(
                details.consecutiveTapCount
            ) == 2
        {
            _ = editableText.showToolbar()
        }

        if isShiftPressed {
            dragStartSelection = nil
        }

        hideMagnifierIfSupportedByPlatform()
    }

    /// Returns a `TextSelectionGestureDetector` configured with the handlers
    /// provided by this builder.
    ///
    /// The `child` or its subtree should contain an `EditableText` whose key is
    /// the GlobalKey provided by the delegate's `Delegate.editableTextKey`.
    public func buildGestureDetector(
        // key: Key? = nil,
        behavior: HitTestBehavior? = nil,
        // child: Widget
        @WidgetBuilder child: () -> Widget
    ) -> Widget {
        return TextSelectionGestureDetector(
            // key: key,
            onTapTrackStart: onTapTrackStart,
            onTapTrackReset: onTapTrackReset,
            onTapDown: onTapDown,
            // onForcePressStart: delegate.forcePressEnabled ? onForcePressStart : nil,
            // onForcePressEnd: delegate.forcePressEnabled ? onForcePressEnd : nil,
            // onSecondaryTap: onSecondaryTap,
            // onSecondaryTapDown: onSecondaryTapDown,
            // onSingleTapUp: onSingleTapUp,
            // onSingleTapCancel: onSingleTapCancel,
            // onUserTap: onUserTap,
            // onSingleLongTapStart: onSingleLongTapStart,
            // onSingleLongTapMoveUpdate: onSingleLongTapMoveUpdate,
            // onSingleLongTapEnd: onSingleLongTapEnd,
            // onDoubleTapDown: onDoubleTapDown,
            // onTripleTapDown: onTripleTapDown,
            onDragSelectionStart: onDragSelectionStart,
            onDragSelectionUpdate: onDragSelectionUpdate,
            onDragSelectionEnd: onDragSelectionEnd,
            // onUserTapAlwaysCalled: onUserTapAlwaysCalled,
            behavior: behavior,
            child: child()
        )
    }
}

/// A gesture detector to respond to non-exclusive event chains for a text field.
///
/// An ordinary [GestureDetector] configured to handle events like tap and
/// double tap will only recognize one or the other. This widget detects both:
/// the first tap and then any subsequent taps that occurs within a time limit
/// after the first.
///
/// See also:
///
///  * [TextField], a Material text field which uses this gesture detector.
///  * [CupertinoTextField], a Cupertino text field which uses this gesture
///    detector.
final class TextSelectionGestureDetector: StatefulWidget {
    /// Create a TextSelectionGestureDetector.
    ///
    /// Multiple callbacks can be called for one sequence of input gesture.
    init(
        onTapTrackStart: VoidCallback? = nil,
        onTapTrackReset: VoidCallback? = nil,
        onTapDown: GestureTapDragDownCallback? = nil,
        // onForcePressStart: GestureForcePressStartCallback? = nil,
        // onForcePressEnd: GestureForcePressEndCallback? = nil,
        onSecondaryTap: GestureTapCallback? = nil,
        onSecondaryTapDown: GestureTapDownCallback? = nil,
        onSingleTapUp: GestureTapDragUpCallback? = nil,
        onSingleTapCancel: GestureCancelCallback? = nil,
        onUserTap: GestureTapCallback? = nil,
        onSingleLongTapStart: GestureLongPressStartCallback? = nil,
        onSingleLongTapMoveUpdate: GestureLongPressMoveUpdateCallback? = nil,
        onSingleLongTapEnd: GestureLongPressEndCallback? = nil,
        onDoubleTapDown: GestureTapDragDownCallback? = nil,
        onTripleTapDown: GestureTapDragDownCallback? = nil,
        onDragSelectionStart: GestureTapDragStartCallback? = nil,
        onDragSelectionUpdate: GestureTapDragUpdateCallback? = nil,
        onDragSelectionEnd: GestureTapDragEndCallback? = nil,
        onUserTapAlwaysCalled: Bool = false,
        behavior: HitTestBehavior? = nil,
        child: Widget
    ) {
        self.onTapTrackStart = onTapTrackStart
        self.onTapTrackReset = onTapTrackReset
        self.onTapDown = onTapDown
        // self.onForcePressStart = onForcePressStart
        // self.onForcePressEnd = onForcePressEnd
        self.onSecondaryTap = onSecondaryTap
        self.onSecondaryTapDown = onSecondaryTapDown
        self.onSingleTapUp = onSingleTapUp
        self.onSingleTapCancel = onSingleTapCancel
        self.onUserTap = onUserTap
        self.onSingleLongTapStart = onSingleLongTapStart
        self.onSingleLongTapMoveUpdate = onSingleLongTapMoveUpdate
        self.onSingleLongTapEnd = onSingleLongTapEnd
        self.onDoubleTapDown = onDoubleTapDown
        self.onTripleTapDown = onTripleTapDown
        self.onDragSelectionStart = onDragSelectionStart
        self.onDragSelectionUpdate = onDragSelectionUpdate
        self.onDragSelectionEnd = onDragSelectionEnd
        self.onUserTapAlwaysCalled = onUserTapAlwaysCalled
        self.behavior = behavior
        self.child = child
    }

    public let onTapTrackStart: VoidCallback?

    public let onTapTrackReset: VoidCallback?

    /// Called for every tap down including every tap down that's part of a
    /// double click or a long press, except touches that include enough movement
    /// to not qualify as taps (e.g. pans and flings).
    public let onTapDown: GestureTapDragDownCallback?

    /// Called when a pointer has tapped down and the force of the pointer has
    /// just become greater than [ForcePressGestureRecognizer.startPressure].
    // public let onForcePressStart: GestureForcePressStartCallback?

    /// Called when a pointer that had previously triggered [onForcePressStart] is
    /// lifted off the screen.
    // public let onForcePressEnd: GestureForcePressEndCallback?

    /// Called for a tap event with the secondary mouse button.
    public let onSecondaryTap: GestureTapCallback?

    /// Called for a tap down event with the secondary mouse button.
    public let onSecondaryTapDown: GestureTapDownCallback?

    /// Called for the first tap in a series of taps, consecutive taps do not call
    /// this method.
    ///
    /// For example, if the detector was configured with [onTapDown] and
    /// [onDoubleTapDown], three quick taps would be recognized as a single tap
    /// down, followed by a tap up, then a double tap down, followed by a single tap down.
    public let onSingleTapUp: GestureTapDragUpCallback?

    /// Called for each touch that becomes recognized as a gesture that is not a
    /// short tap, such as a long tap or drag. It is called at the moment when
    /// another gesture from the touch is recognized.
    public let onSingleTapCancel: GestureCancelCallback?

    /// Called for the first tap in a series of taps when [onUserTapAlwaysCalled] is
    /// disabled, which is the default behavior.
    ///
    /// When [onUserTapAlwaysCalled] is enabled, this is called for every tap,
    /// including consecutive taps.
    public let onUserTap: GestureTapCallback?

    /// Called for a single long tap that's sustained for longer than
    /// [kLongPressTimeout] but not necessarily lifted. Not called for a
    /// double-tap-hold, which calls [onDoubleTapDown] instead.
    public let onSingleLongTapStart: GestureLongPressStartCallback?

    /// Called after [onSingleLongTapStart] when the pointer is dragged.
    public let onSingleLongTapMoveUpdate: GestureLongPressMoveUpdateCallback?

    /// Called after [onSingleLongTapStart] when the pointer is lifted.
    public let onSingleLongTapEnd: GestureLongPressEndCallback?

    /// Called after a momentary hold or a short tap that is close in space and
    /// time (within [kDoubleTapTimeout]) to a previous short tap.
    public let onDoubleTapDown: GestureTapDragDownCallback?

    /// Called after a momentary hold or a short tap that is close in space and
    /// time (within [kDoubleTapTimeout]) to a previous double-tap.
    public let onTripleTapDown: GestureTapDragDownCallback?

    /// Called when a mouse starts dragging to select text.
    public let onDragSelectionStart: GestureTapDragStartCallback?

    /// Called repeatedly as a mouse moves while dragging.
    public let onDragSelectionUpdate: GestureTapDragUpdateCallback?

    /// Called when a mouse that was previously dragging is released.
    public let onDragSelectionEnd: GestureTapDragEndCallback?

    /// Whether [onUserTap] will be called for all taps including consecutive taps.
    ///
    /// Defaults to false, so [onUserTap] is only called for each distinct tap.
    public let onUserTapAlwaysCalled: Bool

    /// How this gesture detector should behave during hit testing.
    ///
    /// This defaults to [HitTestBehavior.deferToChild].
    public let behavior: HitTestBehavior?

    /// Child below this widget.
    public let child: Widget

    func createState() -> some State<TextSelectionGestureDetector> {
        _TextSelectionGestureDetectorState()
    }
}

class _TextSelectionGestureDetectorState: State<TextSelectionGestureDetector> {

    // Converts the details.consecutiveTapCount from a TapAndDrag*Details object,
    // which can grow to be infinitely large, to a value between 1 and 3. The value
    // that the raw count is converted to is based on the default observed behavior
    // on the native platforms.
    //
    // This method should be used in all instances when details.consecutiveTapCount
    // would be used.
    static func getEffectiveConsecutiveTapCount(_ rawCount: Int) -> Int {
        switch backend.targetPlatform {
        case .android, .fuchsia, .linux, nil:
            // From observation, these platform's reset their tap count to 0 when
            // the number of consecutive taps exceeds 3. For example on Debian Linux
            // with GTK, when going past a triple click, on the fourth click the
            // selection is moved to the precise click position, on the fifth click
            // the word at the position is selected, and on the sixth click the
            // paragraph at the position is selected.
            return rawCount <= 3 ? rawCount : (rawCount % 3 == 0 ? 3 : rawCount % 3)
        case .iOS, .macOS:
            // From observation, these platform's either hold their tap count at 3.
            // For example on macOS, when going past a triple click, the selection
            // should be retained at the paragraph that was first selected on triple
            // click.
            return min(rawCount, 3)
        case .windows:
            // From observation, this platform's consecutive tap actions alternate
            // between double click and triple click actions. For example, after a
            // triple click has selected a paragraph, on the next click the word at
            // the clicked position will be selected, and on the next click the
            // paragraph at the position is selected.
            return rawCount < 2 ? rawCount : 2 + rawCount % 2
        }
    }

    func handleTapTrackStart() {
        widget.onTapTrackStart?()
    }

    func handleTapTrackReset() {
        widget.onTapTrackReset?()
    }

    // The down handler is force-run on success of a single tap and optimistically
    // run before a long press success.
    func handleTapDown(_ details: TapDragDownDetails) {
        widget.onTapDown?(details)
        // This isn't detected as a double tap gesture in the gesture recognizer
        // because it's 2 single taps, each of which may do different things depending
        // on whether it's a single tap, the first tap of a double tap, the second
        // tap held down, a clean double tap etc.
        if Self.getEffectiveConsecutiveTapCount(details.consecutiveTapCount) == 2 {
            widget.onDoubleTapDown?(details)
            return
        }

        if Self.getEffectiveConsecutiveTapCount(details.consecutiveTapCount) == 3 {
            widget.onTripleTapDown?(details)
            return
        }
    }

    func handleTapUp(_ details: TapDragUpDetails) {
        if Self.getEffectiveConsecutiveTapCount(details.consecutiveTapCount) == 1 {
            widget.onSingleTapUp?(details)
            widget.onUserTap?()
        } else if widget.onUserTapAlwaysCalled {
            widget.onUserTap?()
        }
    }

    func handleTapCancel() {
        widget.onSingleTapCancel?()
    }

    func handleDragStart(_ details: TapDragStartDetails) {
        widget.onDragSelectionStart?(details)
    }

    func handleDragUpdate(_ details: TapDragUpdateDetails) {
        widget.onDragSelectionUpdate?(details)
    }

    func handleDragEnd(_ details: TapDragEndDetails) {
        widget.onDragSelectionEnd?(details)
    }

    // func _forcePressStarted(_ details: ForcePressDetails) {
    //     widget.onForcePressStart?(details)
    // }

    // func _forcePressEnded(_ details: ForcePressDetails) {
    //     widget.onForcePressEnd?(details)
    // }

    func handleLongPressStart(_ details: LongPressStartDetails) {
        if let onSingleLongTapStart = widget.onSingleLongTapStart {
            onSingleLongTapStart(details)
        }
    }

    func handleLongPressMoveUpdate(_ details: LongPressMoveUpdateDetails) {
        if let onSingleLongTapMoveUpdate = widget.onSingleLongTapMoveUpdate {
            onSingleLongTapMoveUpdate(details)
        }
    }

    func handleLongPressEnd(_ details: LongPressEndDetails) {
        if let onSingleLongTapEnd = widget.onSingleLongTapEnd {
            onSingleLongTapEnd(details)
        }
    }

    override func build(context: BuildContext) -> Widget {
        var gestures: [GestureRecognizerFactory] = []

        gestures.append(
            CallbackGestureRecognizerFactory {
                TapGestureRecognizer(debugOwner: self)
            } initializer: { [self] instance in
                instance.onSecondaryTap = widget.onSecondaryTap
                instance.onSecondaryTapDown = widget.onSecondaryTapDown
            }
        )

        if widget.onSingleLongTapStart != nil || widget.onSingleLongTapMoveUpdate != nil
            || widget.onSingleLongTapEnd != nil
        {
            gestures.append(
                CallbackGestureRecognizerFactory {
                    LongPressGestureRecognizer(supportedDevices: [.touch], debugOwner: self)
                } initializer: { [self] instance in
                    instance.onLongPressStart = handleLongPressStart
                    instance.onLongPressMoveUpdate = handleLongPressMoveUpdate
                    instance.onLongPressEnd = handleLongPressEnd
                }
            )
        }

        if widget.onDragSelectionStart != nil || widget.onDragSelectionUpdate != nil
            || widget.onDragSelectionEnd != nil
        {
            switch backend.targetPlatform {
            case .android, .fuchsia, .iOS:
                gestures.append(
                    CallbackGestureRecognizerFactory {
                        TapAndHorizontalDragGestureRecognizer(debugOwner: self)
                    } initializer: { [self] instance in
                        // Text selection should start from the position of the first pointer
                        // down event.
                        instance.dragStartBehavior = .down
                        instance.eagerVictoryOnDrag = backend.targetPlatform != .iOS
                        instance.onTapTrackStart = handleTapTrackStart
                        instance.onTapTrackReset = handleTapTrackReset
                        instance.onTapDown = handleTapDown
                        instance.onDragStart = handleDragStart
                        instance.onDragUpdate = handleDragUpdate
                        instance.onDragEnd = handleDragEnd
                        instance.onTapUp = handleTapUp
                        instance.onCancel = handleTapCancel
                    }
                )
            case .linux, .macOS, .windows, nil:
                gestures.append(
                    CallbackGestureRecognizerFactory {
                        TapAndPanGestureRecognizer(debugOwner: self)
                    } initializer: { [self] instance in
                        // Text selection should start from the position of the first pointer
                        // down event.
                        instance.dragStartBehavior = .down
                        instance.onTapTrackStart = handleTapTrackStart
                        instance.onTapTrackReset = handleTapTrackReset
                        instance.onTapDown = handleTapDown
                        instance.onDragStart = handleDragStart
                        instance.onDragUpdate = handleDragUpdate
                        instance.onDragEnd = handleDragEnd
                        instance.onTapUp = handleTapUp
                        instance.onCancel = handleTapCancel
                    }
                )
            }
        }

        // if widget.onForcePressStart != nil || widget.onForcePressEnd != nil {
        //     gestures[ObjectIdentifier(ForcePressGestureRecognizer.self)] =
        //         CallbackGestureRecognizerFactory(
        //             constructor: { ForcePressGestureRecognizer(debugOwner: self) },
        //             initializer: { instance in
        //                 instance.onStart =
        //                     widget.onForcePressStart != nil ? self._forcePressStarted : nil
        //                 instance.onEnd = widget.onForcePressEnd != nil ? self._forcePressEnded : nil
        //             }
        //         )
        // }

        return RawGestureDetector(
            gestures: gestures,
            // excludeFromSemantics: true,
            behavior: widget.behavior
        ) {
            widget.child
        }
    }
}
