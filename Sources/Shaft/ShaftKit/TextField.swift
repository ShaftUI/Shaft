public final class TextField: StatefulWidget {
    public init(
        key: (any Key)? = nil,
        autocorrect: Bool = false,
        autofocus: Bool = false,
        clearButtonSemanticLabel: String? = nil,
        clipBehavior: Clip = .hardEdge,
        controller: TextEditingController? = nil,
        cursorColor: Color? = nil,
        cursorHeight: Float? = nil,
        cursorOpacityAnimates: Bool = true,
        cursorRadius: Radius = .circular(2.0),
        cursorWidth: Float = 2.0,
        decoration: BoxDecoration? = nil,
        dragStartBehavior: DragStartBehavior = .start,
        enabled: Bool = true,
        enableIMEPersonalizedLearning: Bool = false,
        enableInteractiveSelection: Bool = true,
        enableSuggestions: Bool = false,
        expands: Bool = false,
        focusNode: FocusNode? = nil,
        maxLength: Int? = nil,
        maxLines: Int? = 1,
        minLines: Int? = nil,
        obscureText: Bool = false,
        obscuringCharacter: Character = "•",
        onChanged: ValueChanged<String>? = nil,
        onEditingComplete: VoidCallback? = nil,
        onSubmitted: ValueChanged<String>? = nil,
        onTap: GestureTapCallback? = nil,
        onTapOutside: TapRegionCallback? = nil,
        padding: any EdgeInsetsGeometry = .zero,
        placeholder: String? = nil,
        placeholderStyle: TextStyle? = nil,
        prefix: (any Widget)? = nil,
        readOnly: Bool = false,
        // restorationId: String? = nil,
        scribbleEnabled: Bool = false,
        scrollController: ScrollController? = nil,
        scrollPadding: EdgeInsets = .all(20.0),
        scrollPhysics: ScrollPhysics? = nil,
        selectionHeightStyle: BoxHeightStyle = .tight,
        selectionWidthStyle: BoxWidthStyle = .tight,
        showCursor: Bool? = nil,
        strutStyle: StrutStyle? = nil,
        style: TextStyle? = nil,
        textAlign: TextAlign = .start,
        textAlignVertical: TextAlignVertical? = nil,
        textDirection: TextDirection? = nil
    ) {
        self.key = key
        self.controller = controller
        self.focusNode = focusNode
        self.decoration = decoration
        self.padding = padding
        self.placeholder = placeholder
        self.placeholderStyle = placeholderStyle
        self.prefix = prefix
        self.clearButtonSemanticLabel = clearButtonSemanticLabel
        self.style = style
        self.strutStyle = strutStyle
        self.textAlign = textAlign
        self.textAlignVertical = textAlignVertical
        self.textDirection = textDirection
        self.readOnly = readOnly
        self.showCursor = showCursor
        self.autofocus = autofocus
        self.obscuringCharacter = obscuringCharacter
        self.obscureText = obscureText
        self.autocorrect = autocorrect
        self.enableSuggestions = enableSuggestions
        self.maxLines = maxLines
        self.minLines = minLines
        self.expands = expands
        self.maxLength = maxLength
        self.onChanged = onChanged
        self.onEditingComplete = onEditingComplete
        self.onSubmitted = onSubmitted
        self.onTapOutside = onTapOutside
        self.enabled = enabled
        self.cursorWidth = cursorWidth
        self.cursorHeight = cursorHeight
        self.cursorRadius = cursorRadius
        self.cursorOpacityAnimates = cursorOpacityAnimates
        self.cursorColor = cursorColor
        self.selectionHeightStyle = selectionHeightStyle
        self.selectionWidthStyle = selectionWidthStyle
        self.scrollPadding = scrollPadding
        self.enableInteractiveSelection = enableInteractiveSelection
        self.dragStartBehavior = dragStartBehavior
        self.scrollController = scrollController
        self.scrollPhysics = scrollPhysics
        self.onTap = onTap
        self.clipBehavior = clipBehavior
        // self.restorationId = restorationId
        self.scribbleEnabled = scribbleEnabled
        self.enableIMEPersonalizedLearning = enableIMEPersonalizedLearning
    }

    //   public let groupId: Object

    public let key: (any Key)?

    /// Controls the text being edited.
    ///
    /// If null, this widget will create its own [TextEditingController].
    public let controller: TextEditingController?

    public let focusNode: FocusNode?

    /// Controls the [BoxDecoration] of the box behind the text input.
    ///
    /// Defaults to having a rounded rectangle grey border and can be null to have
    /// no box decoration.
    public let decoration: BoxDecoration?

    /// Padding around the text entry area between the [prefix] and [suffix]
    /// or the clear button when [clearButtonMode] is not never.
    ///
    /// Defaults to a padding of 6 pixels on all sides and can be null.
    public let padding: EdgeInsetsGeometry

    /// A lighter colored placeholder hint that appears on the first line of the
    /// text field when the text entry is empty.
    ///
    /// Defaults to having no placeholder text.
    ///
    /// The text style of the placeholder text matches that of the text field's
    /// main text entry except a lighter font weight and a grey font color.
    public let placeholder: String?

    /// The style to use for the placeholder text.
    ///
    /// The [placeholderStyle] is merged with the [style] [TextStyle] when applied
    /// to the [placeholder] text. To avoid merging with [style], specify
    /// [TextStyle.inherit] as false.
    ///
    /// Defaults to the [style] property with w300 font weight and grey color.
    ///
    /// If specifically set to null, placeholder's style will be the same as [style].
    public let placeholderStyle: TextStyle?

    /// An optional [Widget] to display before the text.
    public let prefix: Widget?

    /// Controls the visibility of the [prefix] widget based on the state of
    /// text entry when the [prefix] argument is not null.
    ///
    /// Defaults to [OverlayVisibilityMode.always].
    ///
    /// Has no effect when [prefix] is null.
    // public let prefixMode: OverlayVisibilityMode

    /// An optional [Widget] to display after the text.
    // public let suffix: Widget?

    /// Controls the visibility of the [suffix] widget based on the state of
    /// text entry when the [suffix] argument is not null.
    ///
    /// Defaults to [OverlayVisibilityMode.always].
    ///
    /// Has no effect when [suffix] is null.
    // public let suffixMode: OverlayVisibilityMode

    /// Show an iOS-style clear button to clear the current text entry.
    ///
    /// Can be made to appear depending on various text states of the
    /// [TextEditingController].
    ///
    /// Will only appear if no [suffix] widget is appearing.
    ///
    /// Defaults to [OverlayVisibilityMode.never].
    // public let clearButtonMode: OverlayVisibilityMode

    /// The semantic label for the clear button used by screen readers.
    ///
    /// This will be used by screen reading software to identify the clear button
    /// widget. Defaults to "Clear".
    public let clearButtonSemanticLabel: String?

    // public let keyboardType: TextInputType

    /// The type of action button to use for the keyboard.
    ///
    /// Defaults to [TextInputAction.newline] if [keyboardType] is
    /// [TextInputType.multiline] and [TextInputAction.done] otherwise.
    // public let textInputAction: TextInputAction?

    // public let textCapitalization: TextCapitalization

    /// The style to use for the text being edited.
    ///
    /// Also serves as a base for the [placeholder] text's style.
    ///
    /// Defaults to the standard iOS font style from [CupertinoTheme] if null.
    public let style: TextStyle?

    public let strutStyle: StrutStyle?

    public let textAlign: TextAlign

    public let textAlignVertical: TextAlignVertical?

    public let textDirection: TextDirection?

    public let readOnly: Bool

    public let showCursor: Bool?

    public let autofocus: Bool

    public let obscuringCharacter: Character

    public let obscureText: Bool

    public let autocorrect: Bool

    // public let smartDashesType: SmartDashesType

    // public let smartQuotesType: SmartQuotesType

    public let enableSuggestions: Bool

    public let maxLines: Int?

    public let minLines: Int?

    public let expands: Bool

    /// The maximum number of characters (Unicode grapheme clusters) to allow in
    /// the text field.
    ///
    /// After [maxLength] characters have been input, additional input
    /// is ignored, unless [maxLengthEnforcement] is set to
    /// [MaxLengthEnforcement.none].
    ///
    /// The TextField enforces the length with a
    /// [LengthLimitingTextInputFormatter], which is evaluated after the supplied
    /// [inputFormatters], if any.
    ///
    /// This value must be either null or greater than zero. If set to null
    /// (the default), there is no limit to the number of characters allowed.
    ///
    /// Whitespace characters (e.g. newline, space, tab) are included in the
    /// character count.
    public let maxLength: Int?

    /// Determines how the [maxLength] limit should be enforced.
    ///
    /// If [MaxLengthEnforcement.none] is set, additional input beyond [maxLength]
    /// will not be enforced by the limit.
    // public let maxLengthEnforcement: MaxLengthEnforcement?

    public let onChanged: ValueChanged<String>?

    public let onEditingComplete: VoidCallback?

    ///
    /// See also:
    ///
    ///  * [TextInputAction.next] and [TextInputAction.previous], which
    ///    automatically shift the focus to the next/previous focusable item when
    ///    the user is done editing.
    public let onSubmitted: ValueChanged<String>?

    public let onTapOutside: TapRegionCallback?

    // public let inputFormatters: List<TextInputFormatter>?

    /// Disables the text field when false.
    ///
    /// Text fields in disabled states have a light grey background and don't
    /// respond to touch events including the [prefix], [suffix] and the clear
    /// button.
    ///
    /// Defaults to true.
    public let enabled: Bool

    public let cursorWidth: Float

    public let cursorHeight: Float?

    public let cursorRadius: Radius

    public let cursorOpacityAnimates: Bool

    /// The color to use when painting the cursor.
    ///
    /// Defaults to the [DefaultSelectionStyle.cursorColor]. If that color is
    /// null, it uses the [CupertinoThemeData.primaryColor] of the ambient theme,
    /// which itself defaults to [CupertinoColors.activeBlue] in the light theme
    /// and [CupertinoColors.activeOrange] in the dark theme.
    public let cursorColor: Color?

    /// Controls how tall the selection highlight boxes are computed to be.
    ///
    /// See [ui.BoxHeightStyle] for details on available styles.
    public let selectionHeightStyle: BoxHeightStyle

    /// Controls how wide the selection highlight boxes are computed to be.
    ///
    /// See [ui.BoxWidthStyle] for details on available styles.
    public let selectionWidthStyle: BoxWidthStyle

    /// The appearance of the keyboard.
    ///
    /// This setting is only honored on iOS devices.
    ///
    /// If null, defaults to [Brightness.light].
    // public let keyboardAppearance: Brightness?

    public let scrollPadding: EdgeInsets

    public let enableInteractiveSelection: Bool

    // public let selectionControls: TextSelectionControls?

    public let dragStartBehavior: DragStartBehavior

    public let scrollController: ScrollController?

    public let scrollPhysics: ScrollPhysics?

    public var selectionEnabled: Bool { enableInteractiveSelection }

    public let onTap: GestureTapCallback?

    // public let autofillHints: Iterable<String>?

    /// Defaults to [Clip.hardEdge].
    public let clipBehavior: Clip

    // public let restorationId: String?

    public let scribbleEnabled: Bool

    public let enableIMEPersonalizedLearning: Bool

    // public let contentInsertionConfiguration: ContentInsertionConfiguration?

    //   ///
    //   /// If not provided, will build a default menu based on the platform.
    //   ///
    //   /// See also:
    //   ///
    //   ///  * [CupertinoAdaptiveTextSelectionToolbar], which is built by default.
    //   final EditableTextContextMenuBuilder? contextMenuBuilder;

    //   static Widget _defaultContextMenuBuilder(BuildContext context, EditableTextState editableTextState) {
    //     return CupertinoAdaptiveTextSelectionToolbar.editableText(
    //       editableTextState: editableTextState,
    //     );
    //   }

    //   /// Configuration for the text field magnifier.
    //   ///
    //   /// By default (when this property is set to null), a [CupertinoTextMagnifier]
    //   /// is used on mobile platforms, and nothing on desktop platforms. To suppress
    //   /// the magnifier on all platforms, consider passing
    //   /// [TextMagnifierConfiguration.disabled] explicitly.
    //   ///
    //   ///
    //   /// {@tool dartpad}
    //   /// This sample demonstrates how to customize the magnifier that this text field uses.
    //   ///
    //   /// ** See code in examples/api/lib/widgets/text_magnifier/text_magnifier.0.dart **
    //   /// {@end-tool}
    //   final TextMagnifierConfiguration? magnifierConfiguration;

    //   ///
    //   /// If [SpellCheckConfiguration.misspelledTextStyle] is not specified in this
    //   /// configuration, then [cupertinoMisspelledTextStyle] is used by default.
    //   final SpellCheckConfiguration? spellCheckConfiguration;

    public func createState() -> some State<TextField> {
        TextFieldState()
    }

    public protocol Style {
        func build(context: StyleContext) -> Widget
    }

    public struct StyleContext {
        public let hasFocus: Bool

        public let child: Widget
    }
}

public final class TextFieldState: State<TextField>, TextSelectionGestureDetectorBuilder.Delegate {
    public var editableTextKey = StateGlobalKey<EditableTextState>()

    public var forcePressEnabled: Bool { true }

    public var selectionEnabled: Bool { true }

    private lazy var localFocusNode = FocusNode()
    private var effectiveFocusNode: FocusNode {
        widget.focusNode ?? localFocusNode
    }

    public var hasFocus: Bool {
        effectiveFocusNode.hasFocus
    }

    private lazy var localTextEditingController = TextEditingController()
    private var effectiveTextEditingController: TextEditingController {
        widget.controller ?? localTextEditingController
    }

    public override func initState() {
        super.initState()
        effectiveFocusNode.canRequestFocus = widget.enabled
        effectiveFocusNode.addListener(self, callback: handleFocusChanged)
    }

    public override func didUpdateWidget(_ oldWidget: TextField) {
        super.didUpdateWidget(oldWidget)
        if widget.focusNode != oldWidget.focusNode {
            oldWidget.focusNode?.removeListener(self)
            effectiveFocusNode.addListener(self, callback: handleFocusChanged)
        }
        effectiveFocusNode.canRequestFocus = widget.enabled
    }

    private func handleFocusChanged() {
        setState {}
    }

    private var showSelectionHandles: Bool {
        false
    }

    private func handleSelectionChanged(selection: TextSelection?, cause: SelectionChangedCause?) {
    }

    let style = TextStyle(
        color: .argb(255, 0, 0, 0),
        fontSize: 13,
        height: 1.25
    )

    public override func build(context: BuildContext) -> Widget {
        let gestureBuilder = TextSelectionGestureDetectorBuilder(delegate: self)
        let selectionColor: Color? = effectiveFocusNode.hasFocus ? .argb(100, 0, 122, 255) : nil
        let defaultTextStyle = style
        let cursorColor: Color = .argb(255, 0, 122, 255)
        let backgroundCursorColor: Color = Color(0xFFFF_FFEE)

        let editable: Widget = EditableText(
            key: editableTextKey,
            autocorrect: widget.autocorrect,
            autocorrectionTextRectColor: selectionColor,
            autofocus: widget.autofocus,
            backgroundCursorColor: backgroundCursorColor,
            clipBehavior: widget.clipBehavior,
            controller: effectiveTextEditingController,
            cursorColor: cursorColor,
            cursorHeight: widget.cursorHeight,
            // cursorOffset: widget.cursorOffset,
            cursorOpacityAnimates: widget.cursorOpacityAnimates,
            cursorRadius: widget.cursorRadius,
            cursorWidth: widget.cursorWidth,
            dragStartBehavior: widget.dragStartBehavior,
            enableInteractiveSelection: widget.enableInteractiveSelection,
            enableSuggestions: widget.enableSuggestions,
            expands: widget.expands,
            focusNode: effectiveFocusNode,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            obscureText: widget.obscureText,
            obscuringCharacter: widget.obscuringCharacter,
            onChanged: widget.onChanged,
            onEditingComplete: widget.onEditingComplete,
            onSelectionChanged: handleSelectionChanged,
            onTapOutside: widget.onTapOutside,
            paintCursorAboveText: true,
            readOnly: widget.readOnly,
            rendererIgnoresPointer: true,
            scribbleEnabled: widget.scribbleEnabled,
            scrollController: widget.scrollController,
            scrollPadding: widget.scrollPadding,
            scrollPhysics: widget.scrollPhysics,
            selectionColor: selectionColor,
            showCursor: widget.showCursor,
            showSelectionHandles: showSelectionHandles,
            strutStyle: widget.strutStyle,
            style: widget.style ?? defaultTextStyle,
            textAlign: widget.textAlign,
            textDirection: widget.textDirection
        )
        .padding(widget.padding)

        return gestureBuilder.buildGestureDetector(behavior: .translucent) {
            let style: TextField.Style = Inherited.valueOf(context) ?? .default
            style.build(context: .init(hasFocus: hasFocus, child: editable))
        }
    }
}

extension Widget {
    public func textFieldStyle(_ style: any TextField.Style) -> some Widget {
        Inherited(style) { self }
    }
}

public struct DefaultTextFieldStyle: TextField.Style {
    public init() {}

    public func build(context: TextField.StyleContext) -> Widget {
        var shadow: [BoxShadow] = [
            .init(
                color: .rgbo(0, 0, 0, 0.3),
                offset: .init(0, 0.5),
                blurRadius: 2.5,
                spreadRadius: 0,
                blurStyle: .outer
            ),
            .init(
                color: .rgbo(0, 0, 0, 0.05),
                offset: .zero,
                blurRadius: 0,
                spreadRadius: 0.5,
                blurStyle: .outer
            ),
        ]

        if context.hasFocus {
            shadow.append(
                .init(
                    color: .rgbo(0, 0x7A, 0xFF, 0.5),
                    offset: .zero,
                    blurRadius: 0,
                    spreadRadius: 3,
                    blurStyle: .outer
                )
            )
        }

        return context.child
            .padding(.symmetric(vertical: 3.0, horizontal: 7.0))
            .decoration(
                .box(
                    color: .init(0xFF_FFFFFF),
                    borderRadius: .circular(5.0),
                    boxShadow: shadow
                )
            )
    }
}

extension TextField.Style where Self == DefaultTextFieldStyle {
    public static var `default`: DefaultTextFieldStyle {
        DefaultTextFieldStyle()
    }
}
