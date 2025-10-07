// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
public typealias SelectionChangedCallback = (TextSelection?, SelectionChangedCause?) -> Void

/// Signature for the callback that reports the app private command results.
public typealias AppPrivateCommandCallback = (String, [String: Any]) -> Void

// The time it takes for the cursor to fade from fully opaque to fully
// transparent and vice versa. A full cursor blink, from transparent to opaque
// to transparent, is twice this duration.
// const Duration kCursorBlinkHalfPeriod = Duration(milliseconds: 500);
private let kCursorBlinkHalfPeriod = Duration.microseconds(500)

// Number of cursor ticks during which the most recently entered character
// is shown in an obscured text field.
private let kObscureShowLatestCharCursorTicks = 3

/// A controller for an editable text field.
///
/// Whenever the user modifies a text field with an associated
/// [TextEditingController], the text field updates [value] and the controller
/// notifies its listeners. Listeners can then read the [text] and [selection]
/// properties to learn what the user has typed or how the selection has been
/// updated.
///
/// Similarly, if you modify the [text] or [selection] properties, the text
/// field will be notified and will update itself appropriately.
///
/// A [TextEditingController] can also be used to provide an initial value for a
/// text field. If you build a text field with a controller that already has
///
/// The [value] (as well as [text] and [selection]) of this controller can be
/// updated from within a listener added to this controller. Be aware of
/// infinite loops since the listener will also be notified of the changes made
/// from within itself. Modifying the composing region from within a listener
/// can also have a bad interaction with some input methods. Gboard, for
/// example, will try to restore the composing region of the text if it was
/// modified programmatically, creating an infinite loop of communications
/// between the framework and the input method. Consider using
/// [TextInputFormatter]s instead for as-you-type text modification.
///
/// If both the [text] and [selection] properties need to be changed, set the
/// controller's [value] instead.
///
/// Remember to [dispose] of the [TextEditingController] when it is no longer
/// needed. This will ensure we discard any resources used by the object.
///
/// See also:
///
///  * [TextField], which is a Material Design text field that can be controlled
///    with a [TextEditingController].
///  * [EditableText], which is a raw region of editable text that can be
///    controlled with a [TextEditingController].
///  * Learn how to use a [TextEditingController] in one of our [cookbook
///    recipes](https://flutter.dev/docs/cookbook/forms/text-field-changes#2-use-a-texteditingcontroller).
open class TextEditingController: ChangeNotifier {
    public var value: TextEditingValue = .empty {
        didSet {
            notifyListeners()
        }
    }

    /// The current string the user is editing.
    ///
    /// Setting this will notify all the listeners of this
    /// [TextEditingController] that they need to update (it calls
    /// [notifyListeners]). For this reason, this value should only be set
    /// between frames, e.g. in response to user actions, not during the build,
    /// layout, or paint phases.
    ///
    /// This property can be set from a listener added to this
    /// [TextEditingController]; **however, one should not also set [selection]
    /// in a separate statement. To change both the [text] and the [selection]
    /// change the controller's [value].**
    public var text: String {
        get {
            value.text
        }
        set {
            value = TextEditingValue(
                text: newValue,
                selection: nil,
                composing: nil
            )
        }
    }

    /// The currently selected range within [text].
    ///
    /// If the selection is collapsed, then this property gives the offset of
    /// the cursor within the text.
    ///
    /// Setting this will notify all the listeners of this
    /// [TextEditingController] that they need to update (it calls
    /// [notifyListeners]). For this reason, this value should only be set
    /// between frames, e.g. in response to user actions, not during the build,
    /// layout, or paint phases.
    ///
    /// This property can be set from a listener added to this
    /// [TextEditingController]; however, one should not also set [text] in a
    /// separate statement. To change both the [text] and the [selection] change
    /// the controller's [value].
    ///
    /// If the new selection is outside the composing range, the composing range
    /// is cleared.
    public var selection: TextSelection? {
        get {
            value.selection
        }
        set {
            if let selection = newValue, !isSelectionWithinTextBounds(selection) {
                assertionFailure("invalid text selection: \(selection)")
            }

            let newComposing: TextRange? =
                if let newValue = newValue, isSelectionWithinComposingRange(newValue) {
                    value.composing
                } else {
                    nil
                }

            value = TextEditingValue(
                text: value.text,
                selection: newValue,
                composing: newComposing
            )
        }
    }

    /// Builds [TextSpan] from current editing value.
    ///
    /// By default makes text in composing range appear as underlined. Descendants
    /// can override this method to customize appearance of text.
    open func buildTextSpan(context: BuildContext, style: TextStyle?, withComposing: Bool)
        -> TextSpan
    {
        assert(value.composing == nil || !withComposing || value.isComposingRangeValid)

        // If the composing range is out of range for the current text, ignore it to
        // preserve the tree integrity, otherwise in release mode a RangeError will
        // be thrown and this EditableText will be built with a broken subtree.
        let composingRegionOutOfRange = !value.isComposingRangeValid || !withComposing

        if composingRegionOutOfRange {
            return TextSpan(text: text, style: style)
        }

        let composingStyle =
            style?.merge(TextStyle(decoration: .underline)) ?? TextStyle(decoration: .underline)
        return TextSpan(
            children: [
                TextSpan(text: value.composing!.textBefore(value.text)),
                TextSpan(text: value.composing!.textInside(value.text), style: composingStyle),
                TextSpan(text: value.composing!.textAfter(value.text)),
            ],
            style: style
        )
    }

    /// Set the [value] to empty.
    ///
    /// After calling this function, [text] will be the empty string and the
    /// selection will be collapsed at zero offset.
    ///
    /// Calling this will notify all the listeners of this
    /// [TextEditingController] that they need to update (it calls
    /// [notifyListeners]). For this reason, this method should only be called
    /// between frames, e.g. in response to user actions, not during the build,
    /// layout, or paint phases.
    public func clear() {
        value = TextEditingValue(selection: .collapsed(offset: .zero))
    }

    /// Set the composing region to an empty range.
    ///
    /// The composing region is the range of text that is still being composed.
    /// Calling this function indicates that the user is done composing that
    /// region.
    ///
    /// Calling this will notify all the listeners of this
    /// [TextEditingController] that they need to update (it calls
    /// [notifyListeners]). For this reason, this method should only be called
    /// between frames, e.g. in response to user actions, not during the build,
    /// layout, or paint phases.
    public func clearComposing() {
        value = value.copyWith(composing: nil)
    }

    /// Check that the [selection] is inside of the bounds of [text].
    private func isSelectionWithinTextBounds(_ selection: TextSelection) -> Bool {
        selection.range.start.utf16Offset <= text.utf16.count
            && selection.range.end.utf16Offset <= text.utf16.count
    }

    /// Check that the [selection] is inside of the composing range.
    private func isSelectionWithinComposingRange(_ selection: TextSelection) -> Bool {
        guard let composing = value.composing else {
            return false
        }
        return selection.range.start >= composing.start && selection.range.end <= composing.end
    }
}

/// A basic text input field.
///
/// This widget interacts with the [TextInput] service to let the user edit the
/// text it contains. It also provides scrolling, selection, and cursor
/// movement.
///
/// The [EditableText] widget is a low-level widget that is intended as a
/// building block for custom widget sets. For a complete user experience,
/// consider using a [TextField] or [CupertinoTextField].
public final class EditableText: StatefulWidget {
    /// Creates a basic text input control.
    ///
    /// The [maxLines] property can be set to null to remove the restriction on
    /// the number of lines. By default, it is one, meaning this is a
    /// single-line text field. [maxLines] must be null or greater than zero.
    ///
    /// If [keyboardType] is not set or is null, its value will be inferred from
    /// [autofillHints], if [autofillHints] is not empty. Otherwise it defaults
    /// to [TextInputType.text] if [maxLines] is exactly one, and
    /// [TextInputType.multiline] if [maxLines] is null or greater than one.
    ///
    /// The text cursor is not shown if [showCursor] is false or if [showCursor]
    /// is null (the default) and [readOnly] is true.
    public init(
        key: (any Key)? = nil,
        autocorrect: Bool = false,
        autocorrectionTextRectColor: Color? = nil,
        autofocus: Bool = false,
        backgroundCursorColor: Color,
        clipBehavior: Clip = Clip.hardEdge,
        controller: TextEditingController,
        cursorColor: Color,
        cursorHeight: Float? = nil,
        cursorOffset: Offset? = nil,
        cursorOpacityAnimates: Bool = true,
        cursorRadius: Radius? = nil,
        cursorWidth: Float = 2.0,
        dragStartBehavior: DragStartBehavior = .start,
        enableInteractiveSelection: Bool = true,
        enableSuggestions: Bool = false,
        expands: Bool = false,
        focusNode: FocusNode,
        forceLine: Bool = true,
        maxLines: Int? = 1,
        minLines: Int? = nil,
        mouseCursor: MouseCursor? = nil,
        obscureText: Bool = false,
        obscuringCharacter: Character = "•",
        onChanged: ValueChanged<String>? = nil,
        onEditingComplete: VoidCallback? = nil,
        onSelectionChanged: SelectionChangedCallback? = nil,
        onSelectionHandleTapped: VoidCallback? = nil,
        onTapOutside: TapRegionCallback? = nil,
        paintCursorAboveText: Bool = false,
        readOnly: Bool = false,
        rendererIgnoresPointer: Bool = false,
        scribbleEnabled: Bool = true,
        scrollBehavior: ScrollBehavior? = nil,
        scrollController: ScrollController? = nil,
        scrollPadding: EdgeInsets = EdgeInsets.all(20.0),
        scrollPhysics: ScrollPhysics? = nil,
        selectionColor: Color? = nil,
        showCursor: Bool? = nil,
        showSelectionHandles: Bool = false,
        strutStyle: StrutStyle? = nil,
        style: TextStyle,
        textAlign: TextAlign = .start,
        textDirection: TextDirection? = nil,
        textHeightBehavior: TextHeightBehavior? = nil,
        textScaler: (any TextScaler)? = nil,
        textWidthBasis: TextWidthBasis = .parent
    ) {
        self.key = key
        self.autocorrect = autocorrect
        self.autocorrectionTextRectColor = autocorrectionTextRectColor
        self.autofocus = autofocus
        self.backgroundCursorColor = backgroundCursorColor
        self.clipBehavior = clipBehavior
        self.controller = controller
        self.cursorColor = cursorColor
        self.cursorHeight = cursorHeight
        self.cursorOffset = cursorOffset
        self.cursorOpacityAnimates = cursorOpacityAnimates
        self.cursorRadius = cursorRadius
        self.cursorWidth = cursorWidth
        self.dragStartBehavior = dragStartBehavior
        self.enableInteractiveSelection = enableInteractiveSelection
        self.enableSuggestions = enableSuggestions
        self.expands = expands
        self.focusNode = focusNode
        self.forceLine = forceLine
        self.maxLines = maxLines
        self.minLines = minLines
        self.mouseCursor = mouseCursor
        self.obscureText = obscureText
        self.obscuringCharacter = obscuringCharacter
        self.onChanged = onChanged
        self.onEditingComplete = onEditingComplete
        self.onSelectionChanged = onSelectionChanged
        self.onSelectionHandleTapped = onSelectionHandleTapped
        self.onTapOutside = onTapOutside
        self.paintCursorAboveText = paintCursorAboveText
        self.readOnly = readOnly
        self.rendererIgnoresPointer = rendererIgnoresPointer
        self.scribbleEnabled = scribbleEnabled
        self.scrollBehavior = scrollBehavior
        self.scrollController = scrollController
        self.scrollPadding = scrollPadding
        self.scrollPhysics = scrollPhysics
        self.selectionColor = selectionColor
        self.showCursor = showCursor ?? !readOnly
        self.showSelectionHandles = showSelectionHandles
        self.strutStyle = strutStyle
        self.style = style
        self.textAlign = textAlign
        self.textDirection = textDirection
        self.textHeightBehavior = textHeightBehavior
        self.textScaler = textScaler
        self.textWidthBasis = textWidthBasis
    }

    public let key: (any Key)?

    /// Controls the text being edited.
    public let controller: TextEditingController

    /// Controls whether this widget has keyboard focus.
    public let focusNode: FocusNode

    /// Character used for obscuring text if [obscureText] is true.
    ///
    /// Must be only a single character.
    ///
    /// Defaults to the character U+2022 BULLET (•).
    public let obscuringCharacter: Character

    /// Whether to hide the text being edited (e.g., for passwords).
    ///
    /// When this is set to true, all the characters in the text field are
    /// replaced by [obscuringCharacter], and the text in the field cannot be
    /// copied with copy or cut. If [readOnly] is also true, then the text cannot
    /// be selected.
    ///
    /// Defaults to false.
    public let obscureText: Bool

    /// See: ``TextHeightBehavior``
    public let textHeightBehavior: TextHeightBehavior?

    /// See: ``TextWidthBasis``
    public let textWidthBasis: TextWidthBasis

    /// Whether the text can be changed.
    ///
    /// When this is set to true, the text cannot be modified
    /// by any shortcut or keyboard operation. The text is still selectable.
    ///
    /// Defaults to false.
    public let readOnly: Bool

    /// Whether the text will take the full width regardless of the text width.
    ///
    /// When this is set to false, the width will be based on text width, which
    /// will also be affected by [textWidthBasis].
    ///
    /// Defaults to true.
    ///
    /// See also:
    ///
    ///  * [textWidthBasis], which controls the calculation of text width.
    public let forceLine: Bool

    /// Configuration of toolbar options.
    ///
    /// By default, all options are enabled. If [readOnly] is true, paste and cut
    /// will be disabled regardless. If [obscureText] is true, cut and copy will
    /// be disabled regardless. If [readOnly] and [obscureText] are both true,
    /// select all will also be disabled.
    //   public let toolbarOptions: ToolbarOptions

    /// Whether to show selection handles.
    ///
    /// When a selection is active, there will be two handles at each side of
    /// boundary, or one handle if the selection is collapsed. The handles can be
    /// dragged to adjust the selection.
    ///
    /// See also:
    ///
    ///  * [showCursor], which controls the visibility of the cursor.
    public let showSelectionHandles: Bool

    /// Whether to show cursor.
    ///
    /// The cursor refers to the blinking caret when the [EditableText] is focused.
    ///
    /// See also:
    ///
    ///  * [showSelectionHandles], which controls the visibility of the selection handles.
    public let showCursor: Bool

    /// Whether to enable autocorrection.
    ///
    /// Defaults to true.
    public let autocorrect: Bool

    /// See: ``TextInputConfiguration.smartDashesType``
    // public let smartDashesType: SmartDashesType

    /// See: ``TextInputConfiguration.smartQuotesType``
    // public let smartQuotesType: SmartQuotesType

    /// See: ``TextInputConfiguration.enableSuggestions``
    public let enableSuggestions: Bool

    /// The text style to use for the editable text.
    public let style: TextStyle

    /// Controls the undo state of the current editable text.
    ///
    /// If null, this widget will create its own [UndoHistoryController].
    //   public let undoController: UndoHistoryController?

    /// The strut style used for the vertical layout.
    ///
    /// [StrutStyle] is used to establish a predictable vertical layout. Since
    /// fonts may vary depending on user input and due to font fallback,
    /// [StrutStyle.forceStrutHeight] is enabled by default to lock all lines to
    /// the height of the base [TextStyle], provided by [style]. This ensures
    /// the typed text fits within the allotted space.
    ///
    /// If null, the strut used will inherit values from the [style] and will
    /// have [StrutStyle.forceStrutHeight] set to true. When no [style] is
    /// passed, the theme's [TextStyle] will be used to generate [strutStyle]
    /// instead.
    ///
    /// To disable strut-based vertical alignment and allow dynamic vertical
    /// layout based on the glyphs typed, use [StrutStyle.disabled].
    ///
    /// Flutter's strut is based on [typesetting
    /// strut](https://en.wikipedia.org/wiki/Strut_(typesetting)) and CSS's
    /// [line-height](https://www.w3.org/TR/CSS2/visudet.html#line-height).
    ///
    /// Within editable text and text fields, [StrutStyle] will not use its
    /// standalone default values, and will instead inherit omitted/null
    /// properties from the [TextStyle] instead. See
    /// [StrutStyle.inheritFromTextStyle].
    public let strutStyle: StrutStyle?

    /// How the text should be aligned horizontally.
    ///
    /// Defaults to [TextAlign.start].
    public let textAlign: TextAlign

    /// The directionality of the text.
    ///
    /// This decides how [textAlign] values like [TextAlign.start] and
    /// [TextAlign.end] are interpreted.
    ///
    /// This is also used to disambiguate how to render bidirectional text. For
    /// example, if the text is an English phrase followed by a Hebrew phrase,
    /// in a [TextDirection.ltr] context the English phrase will be on the left
    /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
    /// context, the English phrase will be on the right and the Hebrew phrase on
    /// its left.
    ///
    /// Defaults to the ambient [Directionality], if any.
    public let textDirection: TextDirection?

    /// Configures how the platform keyboard will select an uppercase or
    /// lowercase keyboard.
    ///
    /// Only supports text keyboards, other keyboard types will ignore this
    /// configuration. Capitalization is locale-aware.
    ///
    /// Defaults to [TextCapitalization.none].
    ///
    /// See also:
    ///
    ///  * [TextCapitalization], for a description of each capitalization behavior.
    ///
    // public let textCapitalization: TextCapitalization

    /// Used to select a font when the same Unicode character can
    /// be rendered differently, depending on the locale.
    ///
    /// It's rarely necessary to set this property. By default its value
    /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
    ///
    /// See [RenderEditable.locale] for more information.
    //   public let locale: Locale?

    /// See: ``TextScaler``
    public let textScaler: (any TextScaler)?

    /// The color to use when painting the cursor.
    public let cursorColor: Color

    /// The color to use when painting the autocorrection Rect.
    ///
    /// For [CupertinoTextField]s, the value is set to the ambient
    /// [CupertinoThemeData.primaryColor] with 20% opacity. For [TextField]s, the
    /// value is null on non-iOS platforms and the same color used in [CupertinoTextField]
    /// on iOS.
    ///
    /// Currently the autocorrection Rect only appears on iOS.
    ///
    /// Defaults to null, which disables autocorrection Rect painting.
    public let autocorrectionTextRectColor: Color?

    /// The color to use when painting the background cursor aligned with the text
    /// while rendering the floating cursor.
    ///
    /// Typically this would be set to [CupertinoColors.inactiveGray].
    ///
    /// See also:
    ///
    ///  * [FloatingCursorDragState], which explains the floating cursor feature
    ///    in detail.
    public let backgroundCursorColor: Color

    /// The maximum number of lines to show at one time, wrapping if necessary.
    ///
    /// This affects the height of the field itself and does not limit the
    /// number of lines that can be entered into the field.
    ///
    /// If this is 1 (the default), the text will not wrap, but will scroll
    /// horizontally instead.
    ///
    /// If this is null, there is no limit to the number of lines, and the text
    /// container will start with enough vertical space for one line and
    /// automatically grow to accommodate additional lines as they are entered,
    /// up to the height of its constraints.
    ///
    /// If this is not null, the value must be greater than zero, and it will
    /// lock the input to the given number of lines and take up enough
    /// horizontal space to accommodate that number of lines. Setting [minLines]
    /// as well allows the input to grow and shrink between the indicated range.
    ///
    /// The full set of behaviors possible with [minLines] and [maxLines] are as
    /// follows. These examples apply equally to [TextField], [TextFormField],
    /// [CupertinoTextField], and [EditableText].
    ///
    /// Input that occupies a single line and scrolls horizontally as needed.
    /// ```swift
    /// TextField()
    /// ```
    ///
    /// Input whose height grows from one line up to as many lines as needed for
    /// the text that was entered. If a height limit is imposed by its parent,
    /// it will scroll vertically when its height reaches that limit.
    /// ```swift
    /// TextField(maxLines: null)
    /// ```
    ///
    /// The input's height is large enough for the given number of lines. If
    /// additional lines are entered the input scrolls vertically.
    /// ```swift
    /// TextField(maxLines: 2)
    /// ```
    ///
    /// Input whose height grows with content between a min and max. An infinite
    /// max is possible with `maxLines: null`.
    /// ```swift
    /// TextField(minLines: 2, maxLines: 4)
    /// ```
    ///
    /// See also:
    ///
    ///  * [minLines], which sets the minimum number of lines visible.
    ///  * [expands], which determines whether the field should fill the height
    ///    of its parent.
    public let maxLines: Int?

    /// The minimum number of lines to occupy when the content spans fewer lines.
    ///
    /// This affects the height of the field itself and does not limit the number
    /// of lines that can be entered into the field.
    ///
    /// If this is null (default), text container starts with enough vertical space
    /// for one line and grows to accommodate additional lines as they are entered.
    ///
    /// This can be used in combination with [maxLines] for a varying set of behaviors.
    ///
    /// If the value is set, it must be greater than zero. If the value is greater
    /// than 1, [maxLines] should also be set to either null or greater than
    /// this value.
    ///
    /// When [maxLines] is set as well, the height will grow between the indicated
    /// range of lines. When [maxLines] is null, it will grow as high as needed,
    /// starting from [minLines].
    ///
    /// A few examples of behaviors possible with [minLines] and [maxLines] are as follows.
    /// These apply equally to [TextField], [TextFormField], [CupertinoTextField],
    /// and [EditableText].
    ///
    /// Input that always occupies at least 2 lines and has an infinite max.
    /// Expands vertically as needed.
    /// ```swift
    /// TextField(minLines: 2)
    /// ```
    ///
    /// Input whose height starts from 2 lines and grows up to 4 lines at which
    /// point the height limit is reached. If additional lines are entered it will
    /// scroll vertically.
    /// ```swift
    /// const TextField(minLines:2, maxLines: 4)
    /// ```
    ///
    /// Defaults to null.
    ///
    /// See also:
    ///
    ///  * [maxLines], which sets the maximum number of lines visible, and has
    ///    several examples of how minLines and maxLines interact to produce
    ///    various behaviors.
    ///  * [expands], which determines whether the field should fill the height of
    ///    its parent.
    public let minLines: Int?

    /// Whether this widget's height will be sized to fill its parent.
    ///
    /// If set to true and wrapped in a parent widget like [Expanded] or
    /// [SizedBox], the input will expand to fill the parent.
    ///
    /// [maxLines] and [minLines] must both be null when this is set to true,
    /// otherwise an error is thrown.
    ///
    /// Defaults to false.
    ///
    /// See the examples in [maxLines] for the complete picture of how
    /// [maxLines], [minLines], and [expands] interact to produce various
    /// behaviors.
    ///
    /// Input that matches the height of its parent:
    /// ```swift
    /// Expanded {
    ///   TextField(maxLines: null, expands: true),
    /// }
    /// ```
    public let expands: Bool

    /// Whether this text field should focus itself if nothing else is already
    /// focused.
    ///
    /// If true, the keyboard will open as soon as this text field obtains
    /// focus. Otherwise, the keyboard is only shown after the user taps the
    /// text field.
    ///
    /// Defaults to false.
    public let autofocus: Bool

    /// The color to use when painting the selection.
    ///
    /// If this property is null, this widget gets the selection color from the
    /// [DefaultSelectionStyle].
    ///
    /// For [CupertinoTextField]s, the value is set to the ambient
    /// [CupertinoThemeData.primaryColor] with 20% opacity. For [TextField]s,
    /// the value is set to the ambient [TextSelectionThemeData.selectionColor].
    public let selectionColor: Color?

    /// Optional delegate for building the text selection handles.
    ///
    /// Historically, this field also controlled the toolbar. This is now handled
    /// by [contextMenuBuilder] instead. However, for backwards compatibility, when
    /// [selectionControls] is set to an object that does not mix in
    /// [TextSelectionHandleControls], [contextMenuBuilder] is ignored and the
    /// [TextSelectionControls.buildToolbar] method is used instead.
    ///
    /// See also:
    ///
    ///  * [CupertinoTextField], which wraps an [EditableText] and which shows the
    ///    selection toolbar upon user events that are appropriate on the iOS
    ///    platform.
    ///  * [TextField], a Material Design themed wrapper of [EditableText], which
    ///    shows the selection toolbar upon appropriate user events based on the
    ///    user's platform set in [ThemeData.platform].
    //   public let selectionControls: TextSelectionControls?

    /// The type of keyboard to use for editing the text.
    ///
    /// Defaults to [TextInputType.text] if [maxLines] is one and
    /// [TextInputType.multiline] otherwise.
    //   public let keyboardType: TextInputType

    /// The type of action button to use with the soft keyboard.
    //   public let textInputAction: TextInputAction?

    /// Called when the user initiates a change to the TextField's value: when
    /// they have inserted or deleted text.
    ///
    /// This callback doesn't run when the TextField's text is changed
    /// programmatically, via the TextField's [controller]. Typically it isn't
    /// necessary to be notified of such changes, since they're initiated by the
    /// app itself.
    ///
    /// To be notified of all changes to the TextField's text, cursor, and
    /// selection, one can add a listener to its [controller] with
    /// [TextEditingController.addListener].
    ///
    /// [onChanged] is called before [onSubmitted] when user indicates
    /// completion of editing, such as when pressing the "done" button on the
    /// keyboard. That default behavior can be overridden. See
    /// [onEditingComplete] for details.
    ///
    /// ## Handling emojis and other complex characters
    /// It's important to always use
    /// [characters](https://pub.dev/packages/characters) when dealing with user
    /// input text that may contain complex characters. This will ensure that
    /// extended grapheme clusters and surrogate pairs are treated as single
    /// characters, as they appear to the user.
    ///
    /// For example, when finding the length of some user input, use
    /// `string.characters.length`. Do NOT use `string.length` or even
    /// `string.runes.length`. For the complex character "👨‍👩‍👦", this
    /// appears to the user as a single character, and
    /// `string.characters.length` intuitively returns 1. On the other hand,
    /// `string.length` returns 8, and `string.runes.length` returns 5!
    ///
    /// See also:
    ///
    ///  * [inputFormatters], which are called before [onChanged] runs and can
    ///    validate and change ("format") the input value.
    ///  * [onEditingComplete], [onSubmitted], [onSelectionChanged]: which are
    ///    more specialized input change notifications.
    ///  * [TextEditingController], which implements the [Listenable] interface
    ///    and notifies its listeners on [TextEditingValue] changes.
    public let onChanged: ValueChanged<String>?

    /// Called when the user submits editable content (e.g., user presses the "done"
    /// button on the keyboard).
    ///
    /// The default implementation of [onEditingComplete] executes 2 different
    /// behaviors based on the situation:
    ///
    ///  - When a completion action is pressed, such as "done", "go", "send", or
    ///    "search", the user's content is submitted to the [controller] and then
    ///    focus is given up.
    ///
    ///  - When a non-completion action is pressed, such as "next" or "previous",
    ///    the user's content is submitted to the [controller], but focus is not
    ///    given up because developers may want to immediately move focus to
    ///    another input widget within [onSubmitted].
    ///
    /// Providing [onEditingComplete] prevents the aforementioned default behavior.
    public let onEditingComplete: VoidCallback?

    /// Called when the user indicates that they are done editing the text in the
    /// field.
    ///
    /// By default, [onSubmitted] is called after [onChanged] when the user
    /// has finalized editing; or, if the default behavior has been overridden,
    /// after [onEditingComplete]. See [onEditingComplete] for details.
    ///
    /// ## Testing
    /// The following is the recommended way to trigger [onSubmitted] in a test:
    ///
    /// ```swift
    /// await tester.testTextInput.receiveAction(TextInputAction.done)
    /// ```
    ///
    /// Sending a `LogicalKeyboardKey.enter` via `tester.sendKeyEvent` will not
    /// trigger [onSubmitted]. This is because on a real device, the engine
    /// translates the enter key to a done action, but `tester.sendKeyEvent` sends
    /// the key to the framework only.
    //   public let onSubmitted: ValueChanged<String>?

    /// This is used to receive a private command from the input method.
    ///
    /// Called when the result of [TextInputClient.performPrivateCommand] is
    /// received.
    ///
    /// This can be used to provide domain-specific features that are only known
    /// between certain input methods and their clients.
    ///
    /// See also:
    ///   * [performPrivateCommand](https://developer.android.com/reference/android/view/inputmethod/InputConnection#performPrivateCommand\(java.lang.String,%20android.os.Bundle\)),
    ///     which is the Android documentation for performPrivateCommand, used to
    ///     send a command from the input method.
    ///   * [sendAppPrivateCommand](https://developer.android.com/reference/android/view/inputmethod/InputMethodManager#sendAppPrivateCommand),
    ///     which is the Android documentation for sendAppPrivateCommand, used to
    ///     send a command to the input method.
    //   public let onAppPrivateCommand: AppPrivateCommandCallback?

    /// Called when the user changes the selection of text (including the cursor
    /// location).
    public let onSelectionChanged: SelectionChangedCallback?

    /// See: ``SelectionOverlay.onSelectionHandleTapped``
    public let onSelectionHandleTapped: VoidCallback?

    /// Called for each tap that occurs outside of the[TextFieldTapRegion] group
    /// when the text field is focused.
    ///
    /// If this is null, [FocusNode.unfocus] will be called on the [focusNode] for
    /// this text field when a [PointerDownEvent] is received on another part of
    /// the UI. However, it will not unfocus as a result of mobile application
    /// touch events (which does not include mouse clicks), to conform with the
    /// platform conventions. To change this behavior, a callback may be set here
    /// that operates differently from the default.
    ///
    /// When adding additional controls to a text field (for example, a spinner, a
    /// button that copies the selected text, or modifies formatting), it is
    /// helpful if tapping on that control doesn't unfocus the text field. In
    /// order for an external widget to be considered as part of the text field
    /// for the purposes of tapping "outside" of the field, wrap the control in a
    /// [TextFieldTapRegion].
    ///
    /// The [PointerDownEvent] passed to the function is the event that caused the
    /// notification. It is possible that the event may occur outside of the
    /// immediate bounding box defined by the text field, although it will be
    /// within the bounding box of a [TextFieldTapRegion] member.
    ///
    /// See also:
    ///
    ///  * [TapRegion] for how the region group is determined.
    public let onTapOutside: TapRegionCallback?

    /// Optional input validation and formatting overrides.
    ///
    /// Formatters are run in the provided order when the user changes the text
    /// this widget contains. When this parameter changes, the new formatters will
    /// not be applied until the next time the user inserts or deletes text.
    /// Similar to the [onChanged] callback, formatters don't run when the text is
    /// changed programmatically via [controller].
    ///
    /// See also:
    ///
    ///  * [TextEditingController], which implements the [Listenable] interface
    ///    and notifies its listeners on [TextEditingValue] changes.
    //   public let inputFormatters: List<TextInputFormatter>?

    /// The cursor for a mouse pointer when it enters or is hovering over the
    /// widget.
    ///
    /// If this property is null, [SystemMouseCursors.text] will be used.
    ///
    /// The [mouseCursor] is the only property of [EditableText] that controls the
    /// appearance of the mouse pointer. All other properties related to "cursor"
    /// stands for the text cursor, which is usually a blinking vertical line at
    /// the editing position.
    public let mouseCursor: MouseCursor?

    /// Whether the caller will provide gesture handling (true), or if the
    /// [EditableText] is expected to handle basic gestures (false).
    ///
    /// When this is false, the [EditableText] (or more specifically, the
    /// [RenderEditable]) enables some rudimentary gestures (tap to position the
    /// cursor, long-press to select all, and some scrolling behavior).
    ///
    /// These behaviors are sufficient for debugging purposes but are inadequate
    /// for user-facing applications. To enable platform-specific behaviors, use
    /// a [TextSelectionGestureDetectorBuilder] to wrap the [EditableText], and
    /// set [rendererIgnoresPointer] to true.
    ///
    /// When [rendererIgnoresPointer] is true true, the [RenderEditable] created
    /// by this widget will not handle pointer events.
    ///
    /// This property is false by default.
    ///
    /// See also:
    ///
    ///  * [RenderEditable.ignorePointer], which implements this feature.
    ///  * [TextSelectionGestureDetectorBuilder], which implements
    ///    platform-specific gestures and behaviors.
    public let rendererIgnoresPointer: Bool

    /// How thick the cursor will be.
    ///
    /// Defaults to 2.0.
    ///
    /// The cursor will draw under the text. The cursor width will extend
    /// to the right of the boundary between characters for left-to-right text
    /// and to the left for right-to-left text. This corresponds to extending
    /// downstream relative to the selected position. Negative values may be used
    /// to reverse this behavior.
    public let cursorWidth: Float

    /// How tall the cursor will be.
    ///
    /// If this property is null, [RenderEditable.preferredLineHeight] will be
    /// used.
    public let cursorHeight: Float?

    /// How rounded the corners of the cursor should be.
    ///
    /// By default, the cursor has no radius.
    public let cursorRadius: Radius?

    /// Whether the cursor will animate from fully transparent to fully opaque
    /// during each cursor blink.
    ///
    /// By default, the cursor opacity will animate on iOS platforms and will not
    /// animate on Android platforms.
    public let cursorOpacityAnimates: Bool

    /// See: ``RenderEditable.cursorOffset``
    public let cursorOffset: Offset?

    /// See: ``RenderEditable.paintCursorAboveText``
    public let paintCursorAboveText: Bool

    /// Controls how tall the selection highlight boxes are computed to be.
    ///
    /// See [BoxHeightStyle] for details on available styles.
    // public let selectionHeightStyle: BoxHeightStyle

    /// Controls how wide the selection highlight boxes are computed to be.
    ///
    /// See [BoxWidthStyle] for details on available styles.
    //   public let selectionWidthStyle: BoxWidthStyle

    /// The appearance of the keyboard.
    ///
    /// This setting is only honored on iOS devices.
    ///
    /// Defaults to [Brightness.light].
    //   public let keyboardAppearance: Brightness

    /// Configures padding to edges surrounding a [Scrollable] when the
    /// Textfield scrolls into view.
    ///
    /// When this widget receives focus and is not completely visible (for
    /// example scrolled partially off the screen or overlapped by the keyboard)
    /// then it will attempt to make itself visible by scrolling a surrounding
    /// [Scrollable], if one is present. This value controls how far from the
    /// edges of a [Scrollable] the TextField will be positioned after the
    /// scroll.
    ///
    /// Defaults to EdgeInsets.all(20.0).
    public let scrollPadding: EdgeInsets

    /// Whether to enable user interface affordances for changing the text
    /// selection.
    ///
    /// For example, setting this to true will enable features such as
    /// long-pressing the TextField to select text and show the cut/copy/paste
    /// menu, and tapping to move the text caret.
    ///
    /// When this is false, the text selection cannot be adjusted by the user,
    /// text cannot be copied, and the user cannot paste into the text field
    /// from the clipboard.
    ///
    /// Defaults to true.
    public let enableInteractiveSelection: Bool

    /// See: ``DragStartBehavior``
    public let dragStartBehavior: DragStartBehavior

    /// The [ScrollController] to use when vertically scrolling the input.
    ///
    /// If null, it will instantiate a new ScrollController.
    ///
    /// See [Scrollable.controller].
    public let scrollController: ScrollController?

    /// The [ScrollPhysics] to use when vertically scrolling the input.
    ///
    /// If not specified, it will behave according to the current platform.
    ///
    /// See [Scrollable.physics].
    ///
    /// If an explicit [ScrollBehavior] is provided to [scrollBehavior], the
    /// [ScrollPhysics] provided by that behavior will take precedence after
    /// [scrollPhysics].
    public let scrollPhysics: ScrollPhysics?

    /// Whether iOS 14 Scribble features are enabled for this widget.
    ///
    /// Only available on iPads.
    ///
    /// Defaults to true.
    public let scribbleEnabled: Bool

    /// Same as [enableInteractiveSelection].
    ///
    /// This getter exists primarily for consistency with
    /// [RenderEditable.selectionEnabled].
    public var selectionEnabled: Bool { enableInteractiveSelection }

    /// A list of strings that helps the autofill service identify the type of this
    /// text input.
    ///
    /// When set to null, this text input will not send its autofill information
    /// to the platform, preventing it from participating in autofills triggered
    /// by a different [AutofillClient], even if they're in the same
    /// [AutofillScope]. Additionally, on Android and web, setting this to null
    /// will disable autofill for this text field.
    ///
    /// The minimum platform SDK version that supports Autofill is API level 26
    /// for Android, and iOS 10.0 for iOS.
    ///
    /// Defaults to an empty list.
    ///
    /// ### Setting up iOS autofill:
    ///
    /// To provide the best user experience and ensure your app fully supports
    /// password autofill on iOS, follow these steps:
    ///
    /// * Set up your iOS app's
    ///   [associated domains](https://developer.apple.com/documentation/safariservices/supporting_associated_domains_in_your_app).
    /// * Some autofill hints only work with specific [keyboardType]s. For example,
    ///   [AutofillHints.name] requires [TextInputType.name] and [AutofillHints.email]
    ///   works only with [TextInputType.emailAddress]. Make sure the input field has a
    ///   compatible [keyboardType]. Empirically, [TextInputType.name] works well
    ///   with many autofill hints that are predefined on iOS.
    ///
    /// ### Troubleshooting Autofill
    ///
    /// Autofill service providers rely heavily on [autofillHints]. Make sure the
    /// entries in [autofillHints] are supported by the autofill service currently
    /// in use (the name of the service can typically be found in your mobile
    /// device's system settings).
    ///
    /// #### Autofill UI refuses to show up when I tap on the text field
    ///
    /// Check the device's system settings and make sure autofill is turned on,
    /// and there are available credentials stored in the autofill service.
    ///
    /// * iOS password autofill: Go to Settings -> Password, turn on "Autofill
    ///   Passwords", and add new passwords for testing by pressing the top right
    ///   "+" button. Use an arbitrary "website" if you don't have associated
    ///   domains set up for your app. As long as there's at least one password
    ///   stored, you should be able to see a key-shaped icon in the quick type
    ///   bar on the software keyboard, when a password related field is focused.
    ///
    /// * iOS contact information autofill: iOS seems to pull contact info from
    ///   the Apple ID currently associated with the device. Go to Settings ->
    ///   Apple ID (usually the first entry, or "Sign in to your iPhone" if you
    ///   haven't set up one on the device), and fill out the relevant fields. If
    ///   you wish to test more contact info types, try adding them in Contacts ->
    ///   My Card.
    ///
    /// * Android autofill: Go to Settings -> System -> Languages & input ->
    ///   Autofill service. Enable the autofill service of your choice, and make
    ///   sure there are available credentials associated with your app.
    ///
    /// #### I called `TextInput.finishAutofillContext` but the autofill save
    /// prompt isn't showing
    ///
    /// * iOS: iOS may not show a prompt or any other visual indication when it
    ///   saves user password. Go to Settings -> Password and check if your new
    ///   password is saved. Neither saving password nor auto-generating strong
    ///   password works without properly setting up associated domains in your
    ///   app. To set up associated domains, follow the instructions in
    ///   <https://developer.apple.com/documentation/safariservices/supporting_associated_domains_in_your_app>.
    ///
    //   public let autofillHints: Iterable<String>?

    /// The [AutofillClient] that controls this input field's autofill behavior.
    ///
    /// When null, this widget's [EditableTextState] will be used as the
    /// [AutofillClient]. This property may override [autofillHints].
    // public let autofillClient: AutofillClient?

    /// Defaults to [Clip.hardEdge].
    public let clipBehavior: Clip

    /// Restoration ID to save and restore the scroll offset of the
    /// [EditableText].
    ///
    /// If a restoration id is provided, the [EditableText] will persist its
    /// current scroll offset and restore it during state restoration.
    ///
    /// The scroll offset is persisted in a [RestorationBucket] claimed from
    /// the surrounding [RestorationScope] using the provided restoration ID.
    ///
    /// Persisting and restoring the content of the [EditableText] is the
    /// responsibility of the owner of the [controller], who may use a
    /// [RestorableTextEditingController] for that purpose.
    ///
    /// See also:
    ///
    ///  * [RestorationManager], which explains how state restoration works in
    ///    Flutter.
    //   public let restorationId: String?

    /// A [ScrollBehavior] that will be applied to this widget individually.
    ///
    /// Defaults to null, wherein the inherited [ScrollBehavior] is copied and
    /// modified to alter the viewport decoration, like [Scrollbar]s.
    ///
    /// [ScrollBehavior]s also provide [ScrollPhysics]. If an explicit
    /// [ScrollPhysics] is provided in [scrollPhysics], it will take precedence,
    /// followed by [scrollBehavior], and then the inherited ancestor
    /// [ScrollBehavior].
    ///
    /// The [ScrollBehavior] of the inherited [ScrollConfiguration] will be
    /// modified by default to only apply a [Scrollbar] if [maxLines] is greater
    /// than 1.
    public let scrollBehavior: ScrollBehavior?

    //   public let enableIMEPersonalizedLearning: Bool

    /// Configuration of handler for media content inserted via the system input
    /// method.
    ///
    /// Defaults to null in which case media content insertion will be disabled,
    /// and the system will display a message informing the user that the text field
    /// does not support inserting media content.
    ///
    /// Set [ContentInsertionConfiguration.onContentInserted] to provide a handler.
    /// Additionally, set [ContentInsertionConfiguration.allowedMimeTypes]
    /// to limit the allowable mime types for inserted content.
    ///
    /// If [contentInsertionConfiguration] is not provided, by default
    /// an empty list of mime types will be sent to the Flutter Engine.
    /// A handler function must be provided in order to customize the allowable
    /// mime types for inserted content.
    ///
    /// If rich content is inserted without a handler, the system will display
    /// a message informing the user that the current text input does not support
    /// inserting rich content.
    //   public let contentInsertionConfiguration: ContentInsertionConfiguration?

    /// Builds the text selection toolbar when requested by the user.
    ///
    /// The context menu is built when [EditableTextState.showToolbar] is called,
    /// typically by one of the callbacks installed by the widget created by
    /// [TextSelectionGestureDetectorBuilder.buildGestureDetector]. The widget
    /// returned by [contextMenuBuilder] is passed to a [ContextMenuController].
    ///
    /// If no callback is provided, no context menu will be shown.
    ///
    /// The [EditableTextContextMenuBuilder] signature used by the
    /// [contextMenuBuilder] callback has two parameters, the [BuildContext] of
    /// the [EditableText] and the [EditableTextState] of the [EditableText].
    ///
    /// The [EditableTextState] has two properties that are especially useful when
    /// building the widgets for the context menu:
    ///
    /// * [EditableTextState.contextMenuAnchors] specifies the desired anchor
    ///   position for the context menu.
    ///
    /// * [EditableTextState.contextMenuButtonItems] represents the buttons that
    ///   should typically be built for this widget (e.g. cut, copy, paste).
    ///
    /// The [TextSelectionToolbarLayoutDelegate] class may be particularly useful
    /// in honoring the preferred anchor positions.
    ///
    /// For backwards compatibility, when [selectionControls] is set to an object
    /// that does not mix in [TextSelectionHandleControls], [contextMenuBuilder]
    /// is ignored and the [TextSelectionControls.buildToolbar] method is used
    /// instead.
    ///
    /// See also:
    ///   * [AdaptiveTextSelectionToolbar], which builds the default text selection
    ///     toolbar for the current platform, but allows customization of the
    ///     buttons.
    ///   * [AdaptiveTextSelectionToolbar.getAdaptiveButtons], which builds the
    ///     button Widgets for the current platform given
    ///     [ContextMenuButtonItem]s.
    ///   * [BrowserContextMenu], which allows the browser's context menu on web
    ///     to be disabled and Flutter-rendered context menus to appear.
    //   public let contextMenuBuilder: EditableTextContextMenuBuilder?

    /// Configuration that details how spell check should be performed.
    ///
    /// Specifies the [SpellCheckService] used to spell check text input and the
    /// [TextStyle] used to style text with misspelled words.
    ///
    /// If the [SpellCheckService] is left null, spell check is disabled by
    /// default unless the [DefaultSpellCheckService] is supported, in which case
    /// it is used. It is currently supported only on Android and iOS.
    ///
    /// If this configuration is left null, then spell check is disabled by default.
    //   public let spellCheckConfiguration: SpellCheckConfiguration?

    /// The configuration for the magnifier to use with selections in this text
    /// field.
    ///
    //   public let magnifierConfiguration: TextMagnifierConfiguration

    /// Setting this property to true makes the cursor stop blinking or fading
    /// on and off once the cursor appears on focus. This property is useful for
    /// testing purposes.
    ///
    /// It does not affect the necessity to focus the EditableText for the cursor
    /// to appear in the first place.
    ///
    /// Defaults to false, resulting in a typical blinking cursor.
    public static var debugDeterministicCursor = false

    public func createState() -> EditableTextState {
        EditableTextState()
    }
}

public final class EditableTextState: State<EditableText>, TextSelectionDelegate, TextInputClient {
    public required init() {
        super.init()
        registerMixin(tickerProvider)
    }

    private var tickerProvider = TickerProviderStateMixin()

    public func onTextEditing(delta: any TextEditingDelta) {
        // This method handles text editing state updates from the platform text
        // input plugin. The [EditableText] may not have the focus or an open input
        // connection, as autofill can update a disconnected [EditableText].

        var newValue = delta.apply(to: value)

        // Since we still have to support keyboard select, this is the best place
        // to disable text updating.
        if !shouldCreateInputConnection {
            return
        }

        if checkNeedsAdjustAffinity(newValue) {
            newValue = newValue.copyWith(
                selection: newValue.selection?.copyWith(affinity: value.selection?.affinity)
            )
        }

        if widget.readOnly {
            // In the read-only case, we only care about selection changes, and reject
            // everything else.
            newValue = value.copyWith(selection: newValue.selection)
        }

        if newValue == value {
            // This is possible, for example, when the numeric keyboard is input,
            // the engine will notify twice for the same value.
            // Track at https://github.com/flutter/flutter/issues/65811
            return
        }

        if newValue.text == value.text && newValue.composing == value.composing {
            // `selection` is the only change.
            //   var cause: SelectionChangedCause
            //   if textInputConnection?.scribbleInProgress ?? false {
            //       cause = .scribble
            //   } else if pointOffsetOrigin != nil {
            //       // For floating cursor selection when force pressing the space bar.
            //       cause = .forcePress
            //   } else {
            //       cause = .keyboard
            //   }
            let cause = SelectionChangedCause.keyboard
            handleSelectionChanged(value.selection, cause)
        } else {
            if newValue.text != value.text {
                // Hide the toolbar if the text was changed, but only hide the toolbar
                // overlay; the selection handle's visibility will be handled
                // by `handleSelectionChanged`. https://github.com/flutter/flutter/issues/108673
                hideToolbar(hideHandles: false)
            }
            // currentPromptRectRange = nil

            // let revealObscuredInput =
            //     hasInputConnection
            //     && widget.obscureText
            //     && WidgetsBinding.shared.platformDispatcher.brieflyShowPassword
            //     && value.text.count == value.text.count + 1

            // obscureShowCharTicksPending =
            //     revealObscuredInput ? kObscureShowLatestCharCursorTicks : 0
            // obscureLatestCharIndex = revealObscuredInput ? value.selection?.baseOffset : nil
            formatAndSetValue(newValue, .keyboard)
        }

        if showBlinkingCursor && cursorBlinkOpacityController.isAnimating {
            // To keep the cursor from blinking while typing, restart the timer here.
            stopCursorBlink(resetCharTicks: false)
            startCursorBlink()
        }

        // Wherever the value is changed by the user, schedule a showCaretOnScreen
        // to make sure the user can see the changes they just made. Programmatic
        // changes to `textEditingValue` do not trigger the behavior even if the
        // text field is focused.
        // scheduleShowCaretOnScreen(withAnimation: true)
    }

    private func checkNeedsAdjustAffinity(_ value: TextEditingValue) -> Bool {
        // Trust the engine affinity if the text changes or selection changes.
        return value.text == self.value.text
            && value.selection?.range.isCollapsed == self.value.selection?.range.isCollapsed
            && value.selection?.range.start == self.value.selection?.range.start
            && value.selection?.affinity != self.value.selection?.affinity
    }

    public func onTextComposed(text: String) {
        // no-op
    }

    public func onTextInputClosed() {
        if hasInputConnection {
            textInputConnection = nil
            widget.focusNode.unfocus()
        }
    }

    /// Sends the current composing rect to the embedder's text input plugin.
    ///
    /// In cases where the composing rect hasn't been updated in the embedder due
    /// to the lag of asynchronous messages over the channel, the position of the
    /// current caret rect is used instead.
    ///
    /// See: [_updateCaretRectIfNeeded]
    private func updateComposingRectIfNeeded() {
        let composingRange = value.composing
        assert(mounted)

        if let composingRange {
            if let composingRect = renderEditable.getRectForComposingRange(composingRange) {
                textInputConnection?.setComposingRect(composingRect)
                return
            }
        }

        // Send the caret location instead if there's no marked text yet.
        let offset = value.selection?.range.start ?? .zero
        let composingRect = renderEditable.getLocalRectForCaret(TextPosition(offset: offset))
        textInputConnection?.setComposingRect(composingRect)
    }

    // Must be called after layout.
    // See https://github.com/flutter/flutter/issues/126312
    private func updateSizeAndTransform() {
        let size = renderEditable.size!
        let transform = renderEditable.getTransformTo(nil)
        textInputConnection?.setEditableSizeAndTransform(size, transform)
    }

    private func schedulePeriodicPostFrameCallbacks(timeStamp: Duration? = nil) {
        if !hasInputConnection {
            return
        }
        updateSizeAndTransform()
        // updateSelectionRects()
        updateComposingRectIfNeeded()
        // updateCaretRectIfNeeded()
        SchedulerBinding.shared.addPostFrameCallback(schedulePeriodicPostFrameCallbacks)
    }

    fileprivate var value: TextEditingValue {
        get { widget.controller.value }
        set { widget.controller.value = newValue }
    }

    public var textEditingValue: TextEditingValue {
        value
    }

    public func userUpdateTextEditingValue(_ value: TextEditingValue, cause: SelectionChangedCause?)
    {
        // Compare the current TextEditingValue with the pre-format new
        // TextEditingValue value, in case the formatter would reject the change.
        // let shouldShowCaret =
        //     widget.readOnly
        //     ? value.selection != value.selection
        //     : value != value

        // if shouldShowCaret {
        //     scheduleShowCaretOnScreen(withAnimation: true)
        // }

        // Even if the value doesn't change, it may be necessary to focus and build
        // the selection overlay. For example, this happens when right clicking an
        // unfocused field that previously had a selection in the same spot.
        if value == textEditingValue {
            if !widget.focusNode.hasFocus {
                flagInternalFocus()
                widget.focusNode.requestFocus()
                // selectionOverlay = selectionOverlay ?? createSelectionOverlay()
            }
            return
        }

        formatAndSetValue(value, cause, userInteraction: true)
    }

    private func performSpellCheck(_ text: String) async throws {
        // let localeForSpellChecking = widget.locale ?? Localizations.maybeLocaleOf(context)

        // assert(
        //     localeForSpellChecking != nil,
        //     "Locale must be specified in widget or Localization widget must be in scope"
        // )

        // let suggestions = try await spellCheckConfiguration
        //     .spellCheckService?
        //     .fetchSpellCheckSuggestions(localeForSpellChecking!, text)

        // if suggestions == nil {
        //     // The request to fetch spell check suggestions was canceled due to ongoing request.
        //     return
        // }

        // spellCheckResults = SpellCheckResults(text, suggestions!)
        // renderEditable.text = buildTextSpan()
    }

    private func formatAndSetValue(
        _ value: TextEditingValue,
        _ cause: SelectionChangedCause?,
        userInteraction: Bool = false
    ) {
        let oldValue = self.value
        let textChanged = oldValue.text != value.text
        let textCommitted =
            !(oldValue.composing?.isCollapsed == true) && (value.composing?.isCollapsed == true)
        let selectionChanged = oldValue.selection != value.selection

        if textChanged || textCommitted {
            // Only apply input formatters if the text has changed (including uncommitted
            // text in the composing region), or when the user committed the composing
            // text.
            // Gboard is very persistent in restoring the composing region. Applying
            // input formatters on composing-region-only changes (except clearing the
            // current composing region) is very infinite-loop-prone: the formatters
            // will keep trying to modify the composing region while Gboard will keep
            // trying to restore the original composing region.
            // let formattedValue =
            //     widget.inputFormatters?.reduce(value) { newValue, formatter in
            //         formatter.formatEditUpdate(self.value, newValue)
            //     } ?? value

            // if spellCheckEnabled && !formattedValue.text.isEmpty
            //     && self.value.text != formattedValue.text
            // {
            //      performSpellCheck(formattedValue.text)
            // }
        }

        let oldTextSelection = textEditingValue.selection

        self.value = value
        // Changes made by the keyboard can sometimes be "out of band" for listening
        // components, so always send those events, even if we didn't think it
        // changed. Also, the user long pressing should always send a selection change
        // as well.
        if selectionChanged || (userInteraction && (cause == .longPress || cause == .keyboard)) {
            handleSelectionChanged(self.value.selection, cause)
            bringIntoViewBySelectionState(oldTextSelection, value.selection, cause)
        }

        let currentText = self.value.text
        if oldValue.text != currentText {
            widget.onChanged?(currentText)
        }
    }

    private func handleSelectionChanged(
        _ selection: TextSelection?,
        _ cause: SelectionChangedCause?
    ) {
        // We return early if the selection is not valid. This can happen when the
        // text of [EditableText] is updated at the same time as the selection is
        // changed by a gesture event.
        let text = widget.controller.value.text
        if let selection,
            text.utf16.count < selection.range.end.utf16Offset
                || text.utf16.count < selection.range.start.utf16Offset
        {
            return
        }

        widget.controller.selection = selection

        // This will show the keyboard for all selection changes on the
        // EditableText except for those triggered by a keyboard input.
        // Typically EditableText shouldn't take user keyboard input if
        // it's not focused already. If the EditableText is being
        // autofilled it shouldn't request focus.
        switch cause {
        case .doubleTap, .drag, .forcePress, .longPress, .scribble, .tap, .toolbar, nil:
            requestKeyboard()
        case .keyboard:
            if hasFocus {
                requestKeyboard()
            }
        }

        // if widget.selectionControls == nil && widget.contextMenuBuilder == nil {
        //     selectionOverlay?.dispose()
        //     selectionOverlay = nil
        // } else {
        //     if selectionOverlay == nil {
        //         selectionOverlay = createSelectionOverlay()
        //     } else {
        //         selectionOverlay?.update(value)
        //     }
        //     selectionOverlay?.handlesVisible = widget.showSelectionHandles
        //     selectionOverlay?.showHandles()
        // }

        // TODO(chunhtai): we should make sure selection actually changed before
        // we call the onSelectionChanged.
        // https://github.com/flutter/flutter/issues/76349.
        widget.onSelectionChanged?(selection, cause)

        // To keep the cursor from blinking while it moves, restart the timer here.
        if showBlinkingCursor && cursorBlinkOpacityController.isAnimating {
            stopCursorBlink(resetCharTicks: false)
            startCursorBlink()
        }
    }

    private func bringIntoViewBySelectionState(
        _ oldSelection: TextSelection?,
        _ newSelection: TextSelection?,
        _ cause: SelectionChangedCause?
    ) {
        guard let newSelection else {
            return
        }
        switch backend.targetPlatform {
        case .iOS, .macOS:
            if cause == .longPress || cause == .drag {
                bringIntoView(newSelection.extent)
            }
        case .linux, .windows, .fuchsia, .android, nil:
            if cause == .drag {
                if oldSelection?.baseOffset != newSelection.baseOffset {
                    bringIntoView(newSelection.base)
                } else if oldSelection?.extentOffset != newSelection.extentOffset {
                    bringIntoView(newSelection.extent)
                }
            }
        }
    }

    func bringIntoView(_ position: TextPosition) {
        // let localRect = renderEditable.getLocalRectForCaret(position)
        // let targetOffset = getOffsetToRevealCaret(localRect)

        // scrollController.jumpTo(targetOffset.offset)
        // renderEditable.showOnScreen(rect: targetOffset.rect)
    }

    private let editableKey = GlobalKey()

    /// The renderer for this widget's descendant.
    ///
    /// This property is typically used to notify the renderer of input gestures
    /// when RenderEditable.ignorePointer is true.
    lazy var renderEditable: RenderEditable = {
        editableKey.currentContext!.findRenderObject() as! RenderEditable
    }()

    /// Shows the selection toolbar at the location of the current cursor.
    ///
    /// Returns `false` if a toolbar couldn't be shown, such as when the toolbar
    /// is already shown, or when no text selection currently exists.
    func showToolbar() -> Bool {
        return false

        // // Web is using native dom elements to enable clipboard functionality of the
        // // context menu: copy, paste, select, cut. It might also provide additional
        // // functionality depending on the browser (such as translate). Due to this,
        // // we should not show a Flutter toolbar for the editable text elements
        // // unless the browser's context menu is explicitly disabled.
        // if _webContextMenuEnabled {
        //     return false
        // }

        // if _selectionOverlay == nil {
        //     return false
        // }
        // _liveTextInputStatus?.update()
        // clipboardStatus.update()
        // _selectionOverlay!.showToolbar()
        // // Listen to parent scroll events when the toolbar is visible so it can be
        // // hidden during a scroll on supported platforms.
        // if _platformSupportsFadeOnScroll {
        //     _listeningToScrollNotificationObserver = true
        //     _scrollNotificationObserver?.removeListener(_handleContextMenuOnParentScroll)
        //     _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context)
        //     _scrollNotificationObserver?.addListener(_handleContextMenuOnParentScroll)
        // }
        // return true
    }

    func hideToolbar(hideHandles: Bool = true) {
        // // Stop listening to parent scroll events when toolbar is hidden.
        // _disposeScrollNotificationObserver()
        // if hideHandles {
        //     // Hide the handles and the toolbar.
        //     _selectionOverlay?.hide()
        // } else if _selectionOverlay?.toolbarIsVisible ?? false {
        //     // Hide only the toolbar but not the handles.
        //     _selectionOverlay?.hideToolbar()
        // }
    }

    /// Toggles the visibility of the toolbar.
    func toggleToolbar(hideHandles: Bool = true) {
        // let selectionOverlay = _selectionOverlay ?? _createSelectionOverlay()
        // if selectionOverlay.toolbarIsVisible {
        //     hideToolbar(hideHandles: hideHandles)
        // } else {
        //     showToolbar()
        // }
    }

    private var isMultiline: Bool {
        widget.maxLines != 1
    }

    private var cursorColor: Color {
        let effectiveOpacity = min(
            Float(widget.cursorColor.alpha) / 255.0,
            Float(cursorBlinkOpacityController.value)
        )
        return widget.cursorColor.withOpacity(effectiveOpacity)
    }

    private var effectiveTextScaler: any TextScaler {
        return widget.textScaler ?? .noScaling  // ?? MediaQuery.textScalerOf(context),
    }

    private var textDirection: TextDirection {
        widget.textDirection ?? .ltr  // Directionality.of(context)
    }

    private var devicePixelRatio: Float {
        1  // MediaQuery.devicePixelRatioOf(context)
    }

    private func didChangeTextEditingValue() {
        // _updateRemoteEditingValueIfNeeded()
        startOrStopCursorTimerIfNeeded()
        // _updateOrDisposeSelectionOverlayIfNeeded()
        setState { /* We use widget.controller.value in build(). */  }
        // _verticalSelectionUpdateAction.stopCurrentVerticalRunIfSelectionChanges()
    }

    // MARK: - Blinking Cursor

    // Whether `TickerMode.of(context)` is true and animations (like blinking the
    // cursor) are supposed to run.
    private var tickersEnabled = true

    private lazy var cursorBlinkOpacityController: AnimationController = {
        let controller = AnimationController(vsync: tickerProvider)
        controller.addListener(self, callback: onCursorColorTick)
        return controller
    }()

    private lazy var _iosBlinkCursorSimulation = _DiscreteKeyFrameSimulation.iOSBlinkingCaret()

    private func startCursorBlink() {
        assert(!cursorBlinkOpacityController.isAnimating)
        if !widget.showCursor {
            return
        }
        if !tickersEnabled {
            return
        }
        cursorBlinkOpacityController.value = 1.0
        if EditableText.debugDeterministicCursor {
            return
        }

        if widget.cursorOpacityAnimates {
            cursorBlinkOpacityController.animateWith(_iosBlinkCursorSimulation)
                .whenComplete(onCursorTick)
        }
    }

    private func onCursorTick() {
        // if obscureShowCharTicksPending > 0 {
        //     obscureShowCharTicksPending =
        //         WidgetsBinding.shared.platformDispatcher.brieflyShowPassword
        //         ? obscureShowCharTicksPending - 1
        //         : 0
        //     if obscureShowCharTicksPending == 0 {
        //         setState {}
        //     }
        // }

        if widget.cursorOpacityAnimates {
            // // Schedule this as an async task to avoid blocking tester.pumpAndSettle
            // // indefinitely.
            // cursorTimer = Timer(timeInterval: .zero) { [weak self] _ in
            //     self?.cursorBlinkOpacityController.animateWith(self?._iosBlinkCursorSimulation)
            //         .whenComplete(self?.onCursorTick)
            // }
            cursorBlinkOpacityController.animateWith(_iosBlinkCursorSimulation)
                .whenComplete(onCursorTick)
        }
    }

    private func stopCursorBlink(resetCharTicks: Bool = true) {
        // If the cursor is animating, stop the animation, and we always
        // want the cursor to be visible when the floating cursor is enabled.
        cursorBlinkOpacityController.value = renderEditable.floatingCursorOn ? 1.0 : 0.0
        // if resetCharTicks {
        //     obscureShowCharTicksPending = 0
        // }
    }

    private func startOrStopCursorTimerIfNeeded() {
        if !showBlinkingCursor {
            stopCursorBlink()
        } else if !cursorBlinkOpacityController.isAnimating {
            startCursorBlink()
        }
    }

    private func onCursorColorTick() {
        renderEditable.cursorColor = cursorColor
        renderEditable.showCursor =
            widget.showCursor
            && (EditableText.debugDeterministicCursor || cursorBlinkOpacityController.value > 0)
    }

    private var showBlinkingCursor: Bool {
        hasFocus && value.selection?.range.isCollapsed == true && widget.showCursor
            && tickersEnabled
            && !renderEditable.floatingCursorOn
    }

    /// Whether the blinking cursor is actually visible at this precise moment
    /// (it's hidden half the time, since it blinks).
    var cursorCurrentlyVisible: Bool {
        cursorBlinkOpacityController.value > 0
    }

    /// The cursor blink interval (the amount of time the cursor is in the "on"
    /// state or the "off" state). A complete cursor blink period is twice this
    /// value (half on, half off).
    var cursorBlinkInterval: Duration {
        kCursorBlinkHalfPeriod
    }

    // MARK: - Input Connection

    /// Whether to create an input connection with the platform for text editing
    /// or not.
    ///
    /// Read-only input fields do not need a connection with the platform since
    /// there's no need for text editing capabilities (e.g. virtual keyboard).
    ///
    /// On the web, we always need a connection because we want some browser
    /// functionalities to continue to work on read-only input fields like:
    ///
    /// - Relevant context menu.
    /// - cmd/ctrl+c shortcut to copy.
    /// - cmd/ctrl+a to select all.
    /// - Changing the selection using a physical keyboard.
    private var shouldCreateInputConnection: Bool {
        // kIsWeb || !widget.readOnly
        !widget.readOnly
    }

    private var textInputConnection: TextInputConnection?
    private var hasInputConnection: Bool { textInputConnection?.isActive ?? false }

    private func openOrCloseInputConnectionIfNeeded() {
        if hasFocus && widget.focusNode.consumeKeyboardToken() {
            openInputConnection()
        } else if !hasFocus {
            closeInputConnectionIfNeeded()
            widget.controller.clearComposing()
        }
    }

    // Must be called after layout.
    // See https://github.com/flutter/flutter/issues/126312
    private func openInputConnection() {
        if !shouldCreateInputConnection {
            return
        }
        if !hasInputConnection {
            textInputConnection = TextInputScope.maybeOf(context)?.textInput.attach(self)
            schedulePeriodicPostFrameCallbacks()
        } else {
            // textInputConnection!.show()
        }
    }

    // MARK: - Focus Handling

    private var hasFocus: Bool {
        widget.focusNode.hasFocus
    }

    private func handleFocusChanged() {
        openOrCloseInputConnectionIfNeeded()
        startOrStopCursorTimerIfNeeded()
        //     _updateOrDisposeSelectionOverlayIfNeeded();
        if hasFocus {
            //       // Listen for changing viewInsets, which indicates keyboard showing up.
            //       WidgetsBinding.instance.addObserver(this);
            //       _lastBottomViewInset = View.of(context).viewInsets.bottom;
            //       if (!widget.readOnly) {
            //         _scheduleShowCaretOnScreen(withAnimation: true);
            //       }
            //       final TextSelection? updatedSelection = _adjustedSelectionWhenFocused();
            //       if (updatedSelection != null) {
            //         _handleSelectionChanged(updatedSelection, null);
            //       }
        } else {
            //   WidgetsBinding.instance.removeObserver(this);
            // _currentPromptRectRange = null;
            setState {}
        }
        //     updateKeepAlive();
    }

    private func _adjustedSelectionWhenFocused() -> TextSelection? {
        var selection: TextSelection?
        let shouldSelectAll =
            widget.selectionEnabled
            && !isMultiline && !nextFocusChangeIsInternal
        if shouldSelectAll {
            // On native web, single line <input> tags select all when receiving
            // focus.
            selection = TextSelection(
                baseOffset: .zero,
                extentOffset: .init(utf16Offset: value.text.utf16.count)
            )
        }
        return selection
    }
    private func closeInputConnectionIfNeeded() {
        if hasInputConnection {
            textInputConnection!.close()
            textInputConnection = nil
            // scribbleCacheKey = nil
            // removeTextPlaceholder()
        }
    }

    /// Indicates that a call to _handleFocusChanged originated within
    /// EditableText, allowing it to distinguish between internal and external
    /// focus changes.
    private var nextFocusChangeIsInternal = false

    /// Sets ``nextFocusChangeIsInternal`` to true only until any subsequent focus
    /// change happens.
    private func flagInternalFocus() {
        nextFocusChangeIsInternal = true
        FocusManager.shared.addListener(self, callback: unflagInternalFocus)
    }

    private func unflagInternalFocus() {
        nextFocusChangeIsInternal = false
        FocusManager.shared.removeListener(self)
    }

    /// Express interest in interacting with the keyboard.
    ///
    /// If this control is already attached to the keyboard, this function will
    /// request that the keyboard become visible. Otherwise, this function will
    /// ask the focus system that it become focused. If successful in acquiring
    /// focus, the control will then attach to the keyboard and request that the
    /// keyboard become visible.
    public func requestKeyboard() {
        if hasFocus {
            openInputConnection()
        } else {
            flagInternalFocus()
            widget.focusNode.requestFocus()  // This eventually calls _openInputConnection also, see _handleFocusChanged.
        }
    }

    public override func initState() {
        widget.controller.addListener(self, callback: didChangeTextEditingValue)
        widget.focusNode.addListener(self, callback: handleFocusChanged)
    }

    public override func didUpdateWidget(_ oldWidget: EditableText) {
        super.didUpdateWidget(oldWidget)
        if widget.controller !== oldWidget.controller {
            oldWidget.controller.removeListener(self)
            widget.controller.addListener(self, callback: didChangeTextEditingValue)
            // _updateRemoteEditingValueIfNeeded()
        }

        if widget.focusNode != oldWidget.focusNode {
            oldWidget.focusNode.removeListener(self)
            widget.focusNode.addListener(self, callback: handleFocusChanged)
            // updateKeepAlive()
        }

        if !shouldCreateInputConnection {
            closeInputConnectionIfNeeded()
        } else if oldWidget.readOnly && hasFocus {
            // _openInputConnection must be called after layout information is available.
            // See https://github.com/flutter/flutter/issues/126312
            SchedulerBinding.shared.addPostFrameCallback { _ in
                self.openInputConnection()
            }
        }
        if widget.showCursor != oldWidget.showCursor {
            startOrStopCursorTimerIfNeeded()
        }
    }

    public override func dispose() {
        widget.controller.removeListener(self)
        widget.focusNode.removeListener(self)
        closeInputConnectionIfNeeded()
        cursorBlinkOpacityController.dispose()
        assert(!hasInputConnection)
        FocusManager.shared.removeListener(self)
        super.dispose()
    }

    // MARK: - Text Editing Actions

    fileprivate func characterBoundary() -> TextBoundary {
        widget.obscureText ? _CodePointBoundary(value.text) : CharacterBoundary(value.text)
    }

    fileprivate func nextWordBoundary() -> TextBoundary {
        widget.obscureText ? documentBoundary() : renderEditable.wordBoundaries.moveByWordBoundary
    }

    fileprivate func linebreak() -> TextBoundary {
        widget.obscureText ? documentBoundary() : LineBoundary(renderEditable)
    }

    fileprivate func paragraphBoundary() -> TextBoundary {
        ParagraphBoundary(value.text)
    }

    fileprivate func documentBoundary() -> TextBoundary {
        DocumentBoundary(value.text)
    }

    fileprivate func makeOverridable<T: Intent>(_ defaultAction: Action<T>) -> Action<T> {
        // Action<T>.overridable(context: context, defaultAction: defaultAction)
        return defaultAction
    }

    private func replaceText(_ intent: ReplaceTextIntent) {
        let oldValue = value
        let newValue = intent.currentTextEditingValue.replaced(
            intent.replacementRange,
            intent.replacementText
        )
        userUpdateTextEditingValue(newValue, cause: intent.cause)

        // If there's no change in text and selection (e.g. when selecting and
        // pasting identical text), the widget won't be rebuilt on value update.
        // Handle this by calling _didChangeTextEditingValue() so caret and scroll
        // updates can happen.
        if newValue == oldValue {
            didChangeTextEditingValue()
        }
    }

    private func updateSelection(_ intent: UpdateSelectionIntent) {
        assert(
            intent.newSelection.range.start.utf16Offset
                <= intent.currentTextEditingValue.text.utf16.count,
            "invalid selection: \(intent.newSelection): it must not exceed the current text length \(intent.currentTextEditingValue.text.utf16.count)"
        )
        assert(
            intent.newSelection.range.end.utf16Offset
                <= intent.currentTextEditingValue.text.utf16.count,
            "invalid selection: \(intent.newSelection): it must not exceed the current text length \(intent.currentTextEditingValue.text.utf16.count)"
        )

        bringIntoView(intent.newSelection.extent)
        userUpdateTextEditingValue(
            intent.currentTextEditingValue.copyWith(selection: intent.newSelection),
            cause: intent.cause
        )
    }

    /// Returns the closest boundary location to `extent` but not including `extent`
    /// itself (unless already at the start/end of the text), in the direction
    /// specified by `forward`.
    private func moveBeyondTextBoundary(
        _ extent: TextPosition,
        _ forward: Bool,
        _ textBoundary: TextBoundary
    ) -> TextPosition {
        assert(extent.offset >= .zero)
        let newOffset =
            forward
            ? textBoundary.getTrailingTextBoundaryAt(extent.offset)
                ?? .init(utf16Offset: value.text.utf16.count)
            // if x is a boundary defined by `textBoundary`, most textBoundaries (except
            // LineBreaker) guarantees `x == textBoundary.getLeadingTextBoundaryAt(x)`.
            // Use x - 1 here to make sure we don't get stuck at the fixed point x.
            : textBoundary.getLeadingTextBoundaryAt(extent.offset.advanced(by: -1)) ?? .zero
        return TextPosition(offset: newOffset)
    }

    /// Returns the closest boundary location to `extent`, including `extent`
    /// itself, in the direction specified by `forward`.
    ///
    /// This method returns a fixed point of itself: applying `_toTextBoundary`
    /// again on the returned TextPosition gives the same TextPosition. It's used
    /// exclusively for handling line boundaries, since performing "move to line
    /// start" more than once usually doesn't move you to the previous line.
    private func moveToTextBoundary(
        _ extent: TextPosition,
        _ forward: Bool,
        _ textBoundary: TextBoundary
    ) -> TextPosition {
        assert(extent.offset >= .zero)
        var caretOffset: TextIndex
        switch extent.affinity {
        case .upstream:
            if extent.offset < .one && !forward {
                assert(extent.offset == .zero)
                return TextPosition(offset: .zero)
            }
            // When the text affinity is upstream, the caret is associated with the
            // grapheme before the code unit at `extent.offset`.
            // TODO(LongCatIsLooong): don't assume extent.offset is at a grapheme
            // boundary, and do this instead:
            // let graphemeStart = CharacterRange.at(string, extent.offset).stringBeforeLength - 1
            caretOffset = max(.zero, extent.offset.advanced(by: -1))
        case .downstream:
            caretOffset = extent.offset
        }
        // The line boundary range does not include some control characters
        // (most notably, Line Feed), in which case there's
        // `x ∉ getTextBoundaryAt(x)`. In case `caretOffset` points to one such
        // control character, we define that these control characters themselves are
        // still part of the previous line, but also exclude them from the
        // line boundary range since they're non-printing. IOW, no additional
        // processing needed since the LineBoundary class does exactly that.
        return forward
            ? TextPosition(
                offset: textBoundary.getTrailingTextBoundaryAt(caretOffset)
                    ?? .init(utf16Offset: value.text.utf16.count),
                affinity: .upstream
            )
            : TextPosition(offset: textBoundary.getLeadingTextBoundaryAt(caretOffset) ?? .zero)
    }

    // private let _verticalSelectionUpdateAction =
    //     _UpdateTextSelectionVerticallyAction<DirectionalCaretMovementIntent>(self)

    // swift-format-ignore
    private lazy var _actions: [any ActionProtocol] = [
        // DoNothingAction(consumesKey: false),
        CallbackAction<ReplaceTextIntent>(onInvoke: replaceText),
        CallbackAction<UpdateSelectionIntent>(onInvoke: updateSelection),
        // DirectionalFocusAction.forTextField(),
        // CallbackAction<DismissIntent>(onInvoke: _hideToolbarIfVisible),

        // // Delete
        makeOverridable(_DeleteTextAction<DeleteCharacterIntent>(self, characterBoundary, moveBeyondTextBoundary)),
        makeOverridable(_DeleteTextAction<DeleteToNextWordBoundaryIntent>(self, nextWordBoundary, moveBeyondTextBoundary)),
        makeOverridable(_DeleteTextAction<DeleteToLineBreakIntent>(self, linebreak, moveToTextBoundary)),

        // // Extend/Move Selection
        makeOverridable(_UpdateTextSelectionAction<ExtendSelectionByCharacterIntent>(self, characterBoundary, moveBeyondTextBoundary, ignoreNonCollapsedSelection: false)),
        // makeOverridable(CallbackAction<ExtendSelectionByPageIntent>(onInvoke: _extendSelectionByPage)),
        makeOverridable(_UpdateTextSelectionAction<ExtendSelectionToNextWordBoundaryIntent>(self, nextWordBoundary, moveBeyondTextBoundary, ignoreNonCollapsedSelection: true)),
        makeOverridable(_UpdateTextSelectionAction<ExtendSelectionToNextParagraphBoundaryIntent>(self, paragraphBoundary, moveBeyondTextBoundary, ignoreNonCollapsedSelection: true)),
        makeOverridable(_UpdateTextSelectionAction<ExtendSelectionToLineBreakIntent>(self, linebreak, moveToTextBoundary, ignoreNonCollapsedSelection: true)),
        // makeOverridable(_verticalSelectionUpdateAction),
        // makeOverridable(_verticalSelectionUpdateAction),
        makeOverridable(_UpdateTextSelectionAction<ExtendSelectionToNextParagraphBoundaryOrCaretLocationIntent>(self, paragraphBoundary, moveBeyondTextBoundary, ignoreNonCollapsedSelection: true)),
        makeOverridable(_UpdateTextSelectionAction<ExtendSelectionToDocumentBoundaryIntent>(self, documentBoundary, moveBeyondTextBoundary, ignoreNonCollapsedSelection: true)),
        makeOverridable(_UpdateTextSelectionAction<ExtendSelectionToNextWordBoundaryOrCaretLocationIntent>(self, nextWordBoundary, moveBeyondTextBoundary, ignoreNonCollapsedSelection: true)),
        // makeOverridable(CallbackAction<ScrollToDocumentBoundaryIntent>(onInvoke: _scrollToDocumentBoundary)),
        // CallbackAction<ScrollIntent>(onInvoke: _scroll),

        // // Expand Selection
        makeOverridable(_UpdateTextSelectionAction<ExpandSelectionToLineBreakIntent>(self, linebreak, moveToTextBoundary, ignoreNonCollapsedSelection: true, isExpand: true)),
        makeOverridable(_UpdateTextSelectionAction<ExpandSelectionToDocumentBoundaryIntent>(self, documentBoundary, moveToTextBoundary, ignoreNonCollapsedSelection: true, isExpand: true, extentAtIndex: true)),

        // // Copy Paste
        makeOverridable(_SelectAllAction(self)),
        makeOverridable(_CopySelectionAction(self)),
        // makeOverridable(CallbackAction<PasteTextIntent>(onInvoke: (PasteTextIntent intent) => pasteText(intent.cause))),

        // makeOverridable(_transposeCharactersAction),
    ]

    public override func build(context: BuildContext) -> Widget {
        return Actions(actions: _actions) {
            Focus(focusNode: widget.focusNode) {
                Scrollable(
                    axisDirection: isMultiline ? .down : .right,
                    controller: widget.scrollController,
                    physics: widget.scrollPhysics,
                    dragStartBehavior: widget.dragStartBehavior
                        // scrollBehavior: widget.scrollBehavior,
                ) { [self] context, offset in
                    Editable(
                        key: editableKey,
                        // startHandleLayerLink: _startHandleLayerLink,
                        // endHandleLayerLink: _endHandleLayerLink,
                        inlineSpan: buildTextSpan(),
                        value: value,
                        cursorColor: cursorColor,
                        backgroundCursorColor: widget.backgroundCursorColor,
                        showCursor: false,
                        // showCursor: _cursorVisibilityNotifier,
                        forceLine: widget.forceLine,
                        readOnly: widget.readOnly,
                        textWidthBasis: widget.textWidthBasis,
                        hasFocus: hasFocus,
                        maxLines: widget.maxLines,
                        minLines: widget.minLines,
                        expands: widget.expands,
                        strutStyle: widget.strutStyle,
                        selectionColor:
                            // _selectionOverlay?.spellCheckToolbarIsVisible ?? false
                            // ? _spellCheckConfiguration.misspelledSelectionColor ?? widget.selectionColor :
                            widget.selectionColor,
                        textScaler: effectiveTextScaler,
                        textAlign: widget.textAlign,
                        textDirection: textDirection,
                        // locale: widget.locale,
                        // textHeightBehavior: widget.textHeightBehavior ?? DefaultTextHeightBehavior.maybeOf(context),
                        obscuringCharacter: widget.obscuringCharacter,
                        obscureText: widget.obscureText,
                        offset: offset,
                        rendererIgnoresPointer: widget.rendererIgnoresPointer,
                        cursorWidth: widget.cursorWidth,
                        cursorHeight: widget.cursorHeight,
                        cursorRadius: widget.cursorRadius,
                        cursorOffset: widget.cursorOffset ?? Offset.zero,
                        // selectionHeightStyle: widget.selectionHeightStyle,
                        // selectionWidthStyle: widget.selectionWidthStyle,
                        paintCursorAboveText: widget.paintCursorAboveText,
                        // enableInteractiveSelection: widget._userSelectionEnabled,
                        textSelectionDelegate: self,
                        devicePixelRatio: devicePixelRatio,
                        promptRectRange: nil,  // _currentPromptRectRange,
                        promptRectColor: widget.autocorrectionTextRectColor,
                        clipBehavior: widget.clipBehavior
                    )
                }
            }
        }
    }

    /// Builds [TextSpan] from current editing value.
    ///
    /// By default makes text in composing range appear as underlined.
    /// Descendants can override this method to customize appearance of text.
    func buildTextSpan() -> TextSpan {

        if widget.obscureText {
            var text = value.text
            text = String(repeating: widget.obscuringCharacter, count: text.count)

            // Reveal the latest character in an obscured field only on mobile.
            // Newer versions of iOS (iOS 15+) no longer reveal the most recently
            // entered character.
            // let mobilePlatforms: Set<TargetPlatform?> = [.android, .fuchsia]
            // let brieflyShowPassword =
            //     WidgetsBinding.instance.platformDispatcher.brieflyShowPassword
            //     && mobilePlatforms.contains(backend.targetPlatform)

            // if brieflyShowPassword {
            //     if let o = obscureShowCharTicksPending > 0 ? obscureLatestCharIndex : nil,
            //         o >= 0 && o < text.count
            //     {
            //         let index = text.index(text.startIndex, offsetBy: o)
            //         text.replaceSubrange(index...index, with: String(value.text[index]))
            //     }
            // }
            return TextSpan(text: text, style: widget.style)
        }
        // if (_placeholderLocation >= 0 && _placeholderLocation <= _value.text.length) {
        //   final List<_ScribblePlaceholder> placeholders = <_ScribblePlaceholder>[];
        //   final int placeholderLocation = _value.text.length - _placeholderLocation;
        //   if (_isMultiline) {
        //     // The zero size placeholder here allows the line to break and keep the caret on the first line.
        //     placeholders.add(const _ScribblePlaceholder(child: SizedBox.shrink(), size: Size.zero));
        //     placeholders.add(_ScribblePlaceholder(child: const SizedBox.shrink(), size: Size(renderEditable.size.width, 0.0)));
        //   } else {
        //     placeholders.add(const _ScribblePlaceholder(child: SizedBox.shrink(), size: Size(100.0, 0.0)));
        //   }
        //   return TextSpan(style: _style, children: <InlineSpan>[
        //       TextSpan(text: _value.text.substring(0, placeholderLocation)),
        //       ...placeholders,
        //       TextSpan(text: _value.text.substring(placeholderLocation)),
        //     ],
        //   );
        // }
        let withComposing = !widget.readOnly && hasFocus
        // if (_spellCheckResultsReceived) {
        //   // If the composing range is out of range for the current text, ignore it to
        //   // preserve the tree integrity, otherwise in release mode a RangeError will
        //   // be thrown and this EditableText will be built with a broken subtree.
        //   assert(!_value.composing.isValid || !withComposing || _value.isComposingRangeValid);

        //   final bool composingRegionOutOfRange = !_value.isComposingRangeValid || !withComposing;

        //   return buildTextSpanWithSpellCheckSuggestions(
        //     _value,
        //     composingRegionOutOfRange,
        //     _style,
        //     _spellCheckConfiguration.misspelledTextStyle!,
        //     spellCheckResults!,
        //   );
        // }

        // // Read only mode should not paint text composing.
        return widget.controller.buildTextSpan(
            context: context,
            style: widget.style,
            withComposing: withComposing
        )
    }
}

private class Editable: MultiChildRenderObjectWidget {
    init(
        key: (any Key)? = nil,
        inlineSpan: InlineSpan,
        value: TextEditingValue,
        // startHandleLayerLink: LayerLink,
        // endHandleLayerLink: LayerLink,
        cursorColor: Color? = nil,
        backgroundCursorColor: Color? = nil,
        showCursor: Bool,
        forceLine: Bool,
        readOnly: Bool,
        textHeightBehavior: TextHeightBehavior? = nil,
        textWidthBasis: TextWidthBasis,
        hasFocus: Bool,
        maxLines: Int?,
        minLines: Int? = nil,
        expands: Bool,
        strutStyle: StrutStyle? = nil,
        selectionColor: Color? = nil,
        textScaler: any TextScaler,
        textAlign: TextAlign,
        textDirection: TextDirection,
        // locale: Locale? = nil,
        obscuringCharacter: Character,
        obscureText: Bool,
        offset: ViewportOffset,
        rendererIgnoresPointer: Bool = false,
        cursorWidth: Float,
        cursorHeight: Float? = nil,
        cursorRadius: Radius? = nil,
        cursorOffset: Offset,
        paintCursorAboveText: Bool,
        selectionHeightStyle: BoxHeightStyle = .tight,
        selectionWidthStyle: BoxWidthStyle = .tight,
        enableInteractiveSelection: Bool = true,
        textSelectionDelegate: TextSelectionDelegate,
        devicePixelRatio: Float,
        promptRectRange: TextRange? = nil,
        promptRectColor: Color? = nil,
        clipBehavior: Clip
    ) {
        self.key = key
        self.inlineSpan = inlineSpan
        self.value = value
        // self.startHandleLayerLink = startHandleLayerLink
        // self.endHandleLayerLink = endHandleLayerLink
        self.cursorColor = cursorColor
        self.backgroundCursorColor = backgroundCursorColor
        self.showCursor = showCursor
        self.forceLine = forceLine
        self.readOnly = readOnly
        self.textHeightBehavior = textHeightBehavior
        self.textWidthBasis = textWidthBasis
        self.hasFocus = hasFocus
        self.maxLines = maxLines
        self.minLines = minLines
        self.expands = expands
        self.strutStyle = strutStyle
        self.selectionColor = selectionColor
        self.textScaler = textScaler
        self.textAlign = textAlign
        self.textDirection = textDirection
        // self.locale = locale
        self.obscuringCharacter = obscuringCharacter
        self.obscureText = obscureText
        self.offset = offset
        self.rendererIgnoresPointer = rendererIgnoresPointer
        self.cursorWidth = cursorWidth
        self.cursorHeight = cursorHeight
        self.cursorRadius = cursorRadius
        self.cursorOffset = cursorOffset
        self.paintCursorAboveText = paintCursorAboveText
        self.selectionHeightStyle = selectionHeightStyle
        self.selectionWidthStyle = selectionWidthStyle
        self.enableInteractiveSelection = enableInteractiveSelection
        self.textSelectionDelegate = textSelectionDelegate
        self.devicePixelRatio = devicePixelRatio
        self.promptRectRange = promptRectRange
        self.promptRectColor = promptRectColor
        self.clipBehavior = clipBehavior

        // super.init(children: WidgetSpan.extractFromInlineSpan(inlineSpan, textScaler))
    }

    let key: (any Key)?

    let inlineSpan: InlineSpan
    let value: TextEditingValue
    let cursorColor: Color?
    // let startHandleLayerLink: LayerLink
    // let endHandleLayerLink: LayerLink
    let backgroundCursorColor: Color?
    let showCursor: Bool
    let forceLine: Bool
    let readOnly: Bool
    let hasFocus: Bool
    let maxLines: Int?
    let minLines: Int?
    let expands: Bool
    let strutStyle: StrutStyle?
    let selectionColor: Color?
    let textScaler: any TextScaler
    let textAlign: TextAlign
    let textDirection: TextDirection
    // let locale: Locale?
    let obscuringCharacter: Character
    let obscureText: Bool
    let textHeightBehavior: TextHeightBehavior?
    let textWidthBasis: TextWidthBasis
    let offset: ViewportOffset
    let rendererIgnoresPointer: Bool
    let cursorWidth: Float
    let cursorHeight: Float?
    let cursorRadius: Radius?
    let cursorOffset: Offset
    let paintCursorAboveText: Bool
    let selectionHeightStyle: BoxHeightStyle
    let selectionWidthStyle: BoxWidthStyle
    let enableInteractiveSelection: Bool
    let textSelectionDelegate: TextSelectionDelegate
    let devicePixelRatio: Float
    let promptRectRange: TextRange?
    let promptRectColor: Color?
    let clipBehavior: Clip

    let children: [any Widget] = []

    func createRenderObject(context: BuildContext) -> RenderEditable {
        return RenderEditable(
            text: inlineSpan,
            textDirection: textDirection,
            textAlign: textAlign,
            cursorColor: cursorColor,
            // startHandleLayerLink: startHandleLayerLink,
            // endHandleLayerLink: endHandleLayerLink,
            backgroundCursorColor: backgroundCursorColor,
            showCursor: showCursor,
            hasFocus: hasFocus,
            maxLines: maxLines,
            minLines: minLines,
            expands: expands,
            strutStyle: strutStyle,
            selectionColor: selectionColor,
            textScaler: textScaler,
            // locale: locale ?? Localizations.maybeLocaleOf(context),
            selection: value.selection,
            offset: offset,
            ignorePointer: rendererIgnoresPointer,
            readOnly: readOnly,
            forceLine: forceLine,
            textHeightBehavior: textHeightBehavior,
            textWidthBasis: textWidthBasis,
            obscuringCharacter: obscuringCharacter,
            obscureText: obscureText,
            cursorWidth: cursorWidth,
            cursorHeight: cursorHeight,
            cursorRadius: cursorRadius,
            paintCursorAboveText: paintCursorAboveText,
            cursorOffset: cursorOffset,
            devicePixelRatio: devicePixelRatio,
            selectionHeightStyle: selectionHeightStyle,
            selectionWidthStyle: selectionWidthStyle,
            enableInteractiveSelection: enableInteractiveSelection,
            floatingCursorAddedMargin: .zero,
            promptRectRange: promptRectRange,
            promptRectColor: promptRectColor,
            clipBehavior: clipBehavior,
            textSelectionDelegate: textSelectionDelegate,
            children: []
        )
    }

    func updateRenderObject(context: BuildContext, renderObject: RenderEditable) {
        renderObject.text = inlineSpan
        renderObject.cursorColor = cursorColor
        // renderObject.startHandleLayerLink = startHandleLayerLink
        // renderObject.endHandleLayerLink = endHandleLayerLink
        renderObject.backgroundCursorColor = backgroundCursorColor
        renderObject.showCursor = showCursor
        renderObject.forceLine = forceLine
        renderObject.readOnly = readOnly
        renderObject.hasFocus = hasFocus
        renderObject.maxLines = maxLines
        renderObject.minLines = minLines
        renderObject.expands = expands
        renderObject.strutStyle = strutStyle
        renderObject.selectionColor = selectionColor
        renderObject.textScaler = textScaler
        renderObject.textAlign = textAlign
        renderObject.textDirection = textDirection
        // renderObject.locale = locale ?? Localizations.maybeLocaleOf(context)
        renderObject.selection = value.selection
        renderObject.offset = offset
        renderObject.ignorePointer = rendererIgnoresPointer
        // renderObject.textHeightBehavior = textHeightBehavior
        // renderObject.textWidthBasis = textWidthBasis
        renderObject.obscuringCharacter = obscuringCharacter
        renderObject.obscureText = obscureText
        renderObject.cursorWidth = cursorWidth
        renderObject.cursorHeight = cursorHeight
        renderObject.cursorRadius = cursorRadius
        renderObject.cursorOffset = cursorOffset
        // renderObject.selectionHeightStyle = selectionHeightStyle
        // renderObject.selectionWidthStyle = selectionWidthStyle
        // renderObject.enableInteractiveSelection = enableInteractiveSelection
        renderObject.textSelectionDelegate = textSelectionDelegate
        // renderObject.devicePixelRatio = devicePixelRatio
        renderObject.paintCursorAboveText = paintCursorAboveText
        // renderObject.promptRectColor = promptRectColor
        renderObject.clipBehavior = clipBehavior
        // renderObject.setPromptRectRange(promptRectRange)
    }
}

// MARK: -  Text Actions

/// A text boundary that uses code points as logical boundaries.
///
/// A code point represents a single character. This may be smaller than what is
/// represented by a user-perceived character, or grapheme. For example, a
/// single grapheme (in this case a Unicode extended grapheme cluster) like
/// "👨‍👩‍👦" consists of five code points: the man emoji, a zero width joiner,
/// the woman emoji, another zero width joiner, and the boy emoji. The [String]
/// has a length of eight because each emoji consists of two code units.
///
/// Code units are the units by which Dart's String class is measured, which is
/// encoded in UTF-16.
///
/// See also:
///
///  * [String.runes], which deals with code points like this class.
///  * [String.characters], which deals with graphemes.
///  * [CharacterBoundary], which is a [TextBoundary] like this class, but whose
///    boundaries are graphemes instead of code points.
private class _CodePointBoundary: TextBoundary {
    init(_ text: String) {
        self._text = text
    }

    let _text: String

    // Returns true if the given position falls in the center of a surrogate pair.
    private func _breaksSurrogatePair(_ position: TextIndex) -> Bool {
        assert(
            position > .zero && position.utf16Offset < _text.utf16.count && _text.utf16.count > 1
        )
        return TextPainter.isHighSurrogate(_text.codeUnitAt(position.advanced(by: -1)))
            && TextPainter.isLowSurrogate(_text.codeUnitAt(position))
    }

    func getLeadingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        if _text.isEmpty || position < .zero {
            return nil
        }
        if position == .zero {
            return .zero
        }
        if position.utf16Offset >= _text.utf16.count {
            return .init(utf16Offset: _text.utf16.count)
        }
        if _text.utf16.count <= 1 {
            return position
        }

        return _breaksSurrogatePair(position)
            ? position.advanced(by: -1)
            : position
    }

    func getTrailingTextBoundaryAt(_ position: TextIndex) -> TextIndex? {
        if _text.isEmpty || position.utf16Offset >= _text.utf16.count {
            return nil
        }
        if position < .zero {
            return .zero
        }
        if position.utf16Offset == _text.utf16.count - 1 {
            return .init(utf16Offset: _text.utf16.count)
        }
        if _text.utf16.count <= 1 {
            return position
        }

        return _breaksSurrogatePair(position.advanced(by: 1))
            ? position.advanced(by: 2)
            : position.advanced(by: 1)
    }
}

// Signature for a function that determines the target location of the given
// [TextPosition] after applying the given [TextBoundary].
typealias _ApplyTextBoundary = (TextPosition, Bool, TextBoundary) -> TextPosition

private class _DeleteTextAction<T: DirectionalTextEditingIntent>: Action<T> {
    init(
        _ state: EditableTextState,
        _ getTextBoundary: @escaping () -> TextBoundary,
        _ applyTextBoundary: @escaping _ApplyTextBoundary
    ) {
        self.state = state
        self.getTextBoundary = getTextBoundary
        self._applyTextBoundary = applyTextBoundary
    }

    weak var state: EditableTextState?
    let getTextBoundary: () -> TextBoundary
    let _applyTextBoundary: _ApplyTextBoundary

    override func invoke(_ intent: T, context: BuildContext? = nil) -> Any? {
        guard let state else {
            return nil
        }
        let selection = state.value.selection
        guard let selection else {
            return nil
        }
        // Expands the selection to ensure the range covers full graphemes.
        let atomicBoundary = state.characterBoundary()
        if !selection.range.isCollapsed {
            // Expands the selection to ensure the range covers full graphemes.
            let range = TextRange(
                start: atomicBoundary.getLeadingTextBoundaryAt(selection.range.start)
                    ?? .init(utf16Offset: state.value.text.utf16.count),
                end: atomicBoundary.getTrailingTextBoundaryAt(selection.range.end.advanced(by: -1))
                    ?? .zero
            )
            return Actions.invoke(
                context!,
                ReplaceTextIntent(state.value, "", range, .keyboard)
            )
        }

        let target = _applyTextBoundary(selection.base, intent.forward, getTextBoundary()).offset

        let rangeToDelete = TextSelection(
            baseOffset: intent.forward
                ? atomicBoundary.getLeadingTextBoundaryAt(selection.baseOffset)
                    ?? .init(utf16Offset: state.value.text.count)
                : atomicBoundary.getTrailingTextBoundaryAt(selection.baseOffset.advanced(by: -1))
                    ?? .zero,
            extentOffset: target
        )
        return Actions.invoke(
            context!,
            ReplaceTextIntent(state.value, "", rangeToDelete.range, .keyboard)
        )
    }

    override var isActionEnabled: Bool {
        !state!.widget.readOnly && state!.value.selection != nil
    }
}

private let kNewLineCodeUnit = 10

private class _UpdateTextSelectionAction<T: DirectionalCaretMovementIntent>: Action<T> {
    init(
        _ state: EditableTextState,
        _ getTextBoundary: @escaping () -> TextBoundary,
        _ applyTextBoundary: @escaping _ApplyTextBoundary,
        ignoreNonCollapsedSelection: Bool,
        isExpand: Bool = false,
        extentAtIndex: Bool = false
    ) {
        self.state = state
        self.ignoreNonCollapsedSelection = ignoreNonCollapsedSelection
        self.isExpand = isExpand
        self.extentAtIndex = extentAtIndex
        self.getTextBoundary = getTextBoundary
        self.applyTextBoundary = applyTextBoundary
    }

    weak var state: EditableTextState?
    let ignoreNonCollapsedSelection: Bool
    let isExpand: Bool
    let extentAtIndex: Bool
    let getTextBoundary: () -> TextBoundary
    let applyTextBoundary: _ApplyTextBoundary

    // Returns true if the given position is at a wordwrap boundary in the
    // upstream position.
    private func _isAtWordwrapUpstream(_ position: TextPosition) -> Bool {
        let end = TextPosition(
            offset: state!.renderEditable.getLineAtOffset(position)!.end,
            affinity: .upstream
        )
        return end == position && end.offset.utf16Offset != state!.value.text.utf16.count
            && state!.value.text.codeUnitAt(position.offset) != kNewLineCodeUnit
    }

    // Returns true if the given position at a wordwrap boundary in the
    // downstream position.
    private func _isAtWordwrapDownstream(_ position: TextPosition) -> Bool {
        let start = TextPosition(
            offset: state!.renderEditable.getLineAtOffset(position)!.start
        )
        return start == position && start.offset != .zero
            && state!.value.text.codeUnitAt(position.offset.advanced(by: -1)) != kNewLineCodeUnit
    }

    override func invoke(_ intent: T, context: BuildContext? = nil) -> Any? {
        let selection = state!.value.selection
        assert(selection != nil)

        let collapseSelection = intent.collapseSelection || !state!.widget.selectionEnabled
        if let selection,
            !selection.range.isCollapsed && !ignoreNonCollapsedSelection && collapseSelection
        {
            return Actions.invoke(
                context!,
                UpdateSelectionIntent(
                    state!.value,
                    TextSelection.collapsed(
                        offset: intent.forward ? selection.range.end : selection.range.start
                    ),
                    .keyboard
                )
            )
        }

        var extent = selection!.extent
        // If continuesAtWrap is true extent and is at the relevant wordwrap, then
        // move it just to the other side of the wordwrap.
        if intent.continuesAtWrap {
            if intent.forward && _isAtWordwrapUpstream(extent) {
                extent = TextPosition(
                    offset: extent.offset
                )
            } else if !intent.forward && _isAtWordwrapDownstream(extent) {
                extent = TextPosition(
                    offset: extent.offset,
                    affinity: .upstream
                )
            }
        }

        let shouldTargetBase =
            isExpand
            && (intent.forward
                ? selection!.baseOffset > selection!.extentOffset
                : selection!.baseOffset < selection!.extentOffset)
        let newExtent = applyTextBoundary(
            shouldTargetBase ? selection!.base : extent,
            intent.forward,
            getTextBoundary()
        )
        let newSelection =
            collapseSelection || (!isExpand && newExtent.offset == selection!.baseOffset)
            ? TextSelection.fromPosition(newExtent)
            : isExpand
                ? selection!.expandTo(
                    newExtent,
                    extentAtIndex: extentAtIndex || selection!.range.isCollapsed
                )
                : selection!.extendTo(newExtent)

        let shouldCollapseToBase =
            intent.collapseAtReversal
            && (selection!.baseOffset - selection!.extentOffset).utf16Offset
                * (selection!.baseOffset - newSelection.extentOffset).utf16Offset < 0
        let newRange =
            shouldCollapseToBase ? TextSelection.fromPosition(selection!.base) : newSelection
        return Actions.invoke(context!, UpdateSelectionIntent(state!.value, newRange, .keyboard))
    }

    override var isActionEnabled: Bool {
        state!.value.selection != nil
    }
}

// private class _UpdateTextSelectionVerticallyAction<T: DirectionalCaretMovementIntent>: Action<T> {
//   init(_ state: EditableTextState) {
//       self.state = state
//   }

//   weak var state: EditableTextState?

//   private var _verticalMovementRun: VerticalCaretMovementRun?
//   private var _runSelection: TextSelection?

//   func stopCurrentVerticalRunIfSelectionChanges() {
//       let runSelection = _runSelection
//       if runSelection == nil {
//           assert(_verticalMovementRun == nil)
//           return
//       }
//       _runSelection = state!.value.selection
//       let currentSelection = state!.widget.controller.selection
//       let continueCurrentRun = currentSelection != nil && currentSelection!.range.isCollapsed
//           && currentSelection!.baseOffset == runSelection!.baseOffset
//           && currentSelection!.extentOffset == runSelection!.extentOffset
//       if !continueCurrentRun {
//           _verticalMovementRun = nil
//           _runSelection = nil
//       }
//   }

//   override func invoke(_ intent: T, context: BuildContext?) -> Any? {
//       assert(state!.value.selection!.isValid)

//       let collapseSelection = intent.collapseSelection || !state!.widget.selectionEnabled
//       let value = state!.textEditingValueforTextLayoutMetrics
//       if !value.selection!.isValid {
//           return nil
//       }

//       if _verticalMovementRun?.isValid == false {
//           _verticalMovementRun = nil
//           _runSelection = nil
//       }

//       let currentRun = _verticalMovementRun
//           ?? state!.renderEditable.startVerticalCaretMovement(state!.renderEditable.selection!.extent)

//       let shouldMove = intent is ExtendSelectionVerticallyToAdjacentPageIntent
//           ? currentRun.moveByOffset((intent.forward ? 1.0 : -1.0) * state!.renderEditable.size!.height)
//           : intent.forward ? currentRun.moveNext() : currentRun.movePrevious()
//       let newExtent = shouldMove
//           ? currentRun.current
//           : intent.forward ? TextPosition(offset: .init(utf16Offset: value.text.utf16.count)) : TextPosition(offset: .zero)
//       let newSelection = collapseSelection
//           ? TextSelection.fromPosition(newExtent)
//           : value.selection!.extendTo(newExtent)

//       Actions.invoke(
//           context!,
//           UpdateSelectionIntent(value, newSelection, .keyboard)
//       )
//       if state!.value.selection == newSelection {
//           _verticalMovementRun = currentRun
//           _runSelection = newSelection
//       }
//       return nil
//   }

//   override var isActionEnabled: Bool {
//       state!.value.selection? != nil
//   }
// }

private class _SelectAllAction: Action<SelectAllTextIntent> {
    init(_ state: EditableTextState) {
        self.state = state
    }

    weak var state: EditableTextState?

    override func invoke(_ intent: SelectAllTextIntent, context: BuildContext? = nil) -> Any? {
        return Actions.invoke(
            context!,
            UpdateSelectionIntent(
                state!.value,
                TextSelection(
                    baseOffset: .zero,
                    extentOffset: .init(utf16Offset: state!.value.text.utf16.count)
                ),
                intent.cause
            )
        )
    }

    override var isActionEnabled: Bool {
        state!.widget.selectionEnabled
    }
}

private class _CopySelectionAction: Action<CopySelectionTextIntent> {
    init(_ state: EditableTextState) {
        self.state = state
    }

    weak var state: EditableTextState?

    override func invoke(_ intent: CopySelectionTextIntent, context: BuildContext? = nil) -> Any? {
        // if intent.collapseSelection {
        //     state!.cutSelection(intent.cause)
        // } else {
        //     state!.copySelection(intent.cause)
        // }
        return nil
    }

    override var isActionEnabled: Bool {
        state!.value.selection != nil
            && !state!.value.selection!.range.isCollapsed
    }
}

// A time-value pair that represents a key frame in an animation.
private struct _KeyFrame {
    init(_ time: Double, _ value: Double) {
        self.time = time
        self.value = value
    }

    // Values extracted from iOS 15.4 UIKit.
    static let iOSBlinkingCaretKeyFrames: [_KeyFrame] = [
        _KeyFrame(0, 1),  // 0
        _KeyFrame(0.5, 1),  // 1
        _KeyFrame(0.5375, 0.75),  // 2
        _KeyFrame(0.575, 0.5),  // 3
        _KeyFrame(0.6125, 0.25),  // 4
        _KeyFrame(0.65, 0),  // 5
        _KeyFrame(0.85, 0),  // 6
        _KeyFrame(0.8875, 0.25),  // 7
        _KeyFrame(0.925, 0.5),  // 8
        _KeyFrame(0.9625, 0.75),  // 9
        _KeyFrame(1, 1),  // 10
    ]

    // The timing, in seconds, of the specified animation `value`.
    let time: Double
    let value: Double
}

private class _DiscreteKeyFrameSimulation: Simulation {
    static func iOSBlinkingCaret() -> _DiscreteKeyFrameSimulation {
        _DiscreteKeyFrameSimulation(_KeyFrame.iOSBlinkingCaretKeyFrames, 1)
    }

    init(_ keyFrames: [_KeyFrame], _ maxDuration: Double) {
        assert(!keyFrames.isEmpty)
        assert(keyFrames.last!.time <= maxDuration)
        assert(
            {
                for i in 0..<keyFrames.count - 1 {
                    if keyFrames[i].time > keyFrames[i + 1].time {
                        return false
                    }
                }
                return true
            }(),
            "The key frame sequence must be sorted by time."
        )

        self.maxDuration = maxDuration
        self._keyFrames = keyFrames
    }

    let maxDuration: Double
    let _keyFrames: [_KeyFrame]
    let tolerance: Tolerance = .defaultTolerance

    func dx(_ time: Double) -> Double { 0 }

    func isDone(_ time: Double) -> Bool { time >= maxDuration }

    // The index of the KeyFrame corresponds to the most recent input `time`.
    private var _lastKeyFrameIndex = 0

    func x(_ time: Double) -> Double {
        let length = _keyFrames.count

        // Perform a linear search in the sorted key frame list, starting from the
        // last key frame found, since the input `time` usually monotonically
        // increases by a small amount.
        var searchIndex: Int
        let endIndex: Int
        if _keyFrames[_lastKeyFrameIndex].time > time {
            // The simulation may have restarted. Search within the index range
            // [0, _lastKeyFrameIndex).
            searchIndex = 0
            endIndex = _lastKeyFrameIndex
        } else {
            searchIndex = _lastKeyFrameIndex
            endIndex = length
        }

        // Find the target key frame. Don't have to check (endIndex - 1): if
        // (endIndex - 2) doesn't work we'll have to pick (endIndex - 1) anyways.
        while searchIndex < endIndex - 1 {
            assert(_keyFrames[searchIndex].time <= time)
            let next = _keyFrames[searchIndex + 1]
            if time < next.time {
                break
            }
            searchIndex += 1
        }

        _lastKeyFrameIndex = searchIndex
        return _keyFrames[_lastKeyFrameIndex].value
    }
}
