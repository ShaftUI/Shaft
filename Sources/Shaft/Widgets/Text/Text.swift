// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A run of text with a single style.
///
/// The [Text] widget displays a string of text with single style. The string
/// might break across multiple lines or might all be displayed on the same line
/// depending on the layout constraints.
///
/// The [style] argument is optional. When omitted, the text will use the style
/// from the closest enclosing [DefaultTextStyle]. If the given style's
/// [TextStyle.inherit] property is true (the default), the given style will
/// be merged with the closest enclosing [DefaultTextStyle]. This merging
/// behavior is useful, for example, to make the text bold while using the
/// default font family and size.
public class Text: StatelessWidget {
    public init(
        _ data: String? = nil,
        textSpan: InlineSpan? = nil,
        style: TextStyle? = nil,
        strutStyle: StrutStyle? = nil,
        textAlign: TextAlign? = nil,
        textDirection: TextDirection? = nil,
        softWrap: Bool? = nil,
        overflow: TextOverflow? = nil,
        textScaler: (any TextScaler)? = nil,
        maxLines: Int? = nil,
        semanticsLabel: String? = nil,
        textWidthBasis: TextWidthBasis? = nil,
        textHeightBehavior: TextHeightBehavior? = nil,
        selectionColor: Color? = nil
    ) {
        self.data = data
        self.textSpan = textSpan
        self.style = style
        self.strutStyle = strutStyle
        self.textAlign = textAlign
        self.textDirection = textDirection
        self.softWrap = softWrap
        self.overflow = overflow
        self.textScaler = textScaler
        self.maxLines = maxLines
        self.semanticsLabel = semanticsLabel
        self.textWidthBasis = textWidthBasis
        self.textHeightBehavior = textHeightBehavior
        self.selectionColor = selectionColor
    }

    /// The text to display.
    ///
    /// This will be null if a [textSpan] is provided instead.
    let data: String?

    /// The text to display as a [InlineSpan].
    ///
    /// This will be null if [data] is provided instead.
    let textSpan: InlineSpan?

    /// If non-null, the style to use for this text.
    ///
    /// If the style's "inherit" property is true, the style will be merged with
    /// the closest enclosing [DefaultTextStyle]. Otherwise, the style will
    /// replace the closest enclosing [DefaultTextStyle].
    let style: TextStyle?

    let strutStyle: StrutStyle?

    /// How the text should be aligned horizontally.
    let textAlign: TextAlign?

    /// The directionality of the text.
    ///
    /// This decides how [textAlign] values like [TextAlign.start] and
    /// [TextAlign.end] are interpreted.
    ///
    /// This is also used to disambiguate how to render bidirectional text. For
    /// example, if the [data] is an English phrase followed by a Hebrew phrase,
    /// in a [TextDirection.ltr] context the English phrase will be on the left
    /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
    /// context, the English phrase will be on the right and the Hebrew phrase on
    /// its left.
    ///
    /// Defaults to the ambient [Directionality], if any.
    let textDirection: TextDirection?

    /// Used to select a font when the same Unicode character can
    /// be rendered differently, depending on the locale.
    ///
    /// It's rarely necessary to set this property. By default its value
    /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
    ///
    /// See [RenderParagraph.locale] for more information.
    // let locale: Locale?

    /// Whether the text should break at soft line breaks.
    ///
    /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
    let softWrap: Bool?

    /// How visual overflow should be handled.
    ///
    /// If this is null [TextStyle.overflow] will be used, otherwise the value
    /// from the nearest [DefaultTextStyle] ancestor will be used.
    let overflow: TextOverflow?

    /// {@macro flutter.painting.textPainter.textScaler}
    let textScaler: (any TextScaler)?

    /// An optional maximum number of lines for the text to span, wrapping if necessary.
    /// If the text exceeds the given number of lines, it will be truncated according
    /// to [overflow].
    ///
    /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
    /// edge of the box.
    ///
    /// If this is null, but there is an ambient [DefaultTextStyle] that specifies
    /// an explicit number for its [DefaultTextStyle.maxLines], then the
    /// [DefaultTextStyle] value will take precedence. You can use a [RichText]
    /// widget directly to entirely override the [DefaultTextStyle].
    let maxLines: Int?

    /// An alternative semantics label for this text.
    ///
    /// If present, the semantics of this widget will contain this value instead
    /// of the actual text. This will overwrite any of the semantics labels applied
    /// directly to the [TextSpan]s.
    let semanticsLabel: String?

    let textWidthBasis: TextWidthBasis?

    let textHeightBehavior: TextHeightBehavior?

    /// The color to use when painting the selection.
    ///
    /// This is ignored if [SelectionContainer.maybeOf] returns null
    /// in the [BuildContext] of the [Text] widget.
    ///
    /// If null, the ambient [DefaultSelectionStyle] is used (if any); failing
    /// that, the selection color defaults to [DefaultSelectionStyle.defaultColor]
    /// (semi-transparent grey).
    let selectionColor: Color?

    public func build(context: BuildContext) -> Widget {
        let defaultTextStyle = DefaultTextStyle.of(context)

        var effectiveTextStyle = style
        if style == nil || style!.inherit {
            effectiveTextStyle = defaultTextStyle.style.merge(style)
        }

        // if (MediaQuery.boldTextOf(context)) {
        // effectiveTextStyle = effectiveTextStyle!.merge(const TextStyle(fontWeight: FontWeight.bold));
        // }

        // final SelectionRegistrar? registrar = SelectionContainer.maybeOf(context);
        // final TextScaler textScaler = switch ((this.textScaler, textScaleFactor)) {
        // (final TextScaler textScaler, _)     => textScaler,
        // // For unmigrated apps, fall back to textScaleFactor.
        // (null, final double textScaleFactor) => TextScaler.linear(textScaleFactor),
        // (null, null)                         => MediaQuery.textScalerOf(context),
        // };

        let result: Widget = RichText(
            text: TextSpan(
                text: data,
                style: effectiveTextStyle
                    // children: textSpan != null ? <InlineSpan>[textSpan!] : null,
            ),
            textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
            textDirection: textDirection,  // RichText uses Directionality.of to obtain a default if this is null.
            //   locale: locale, // RichText uses Localizations.localeOf to obtain a default if this is null
            softWrap: softWrap ?? defaultTextStyle.softWrap,
            overflow: overflow ?? effectiveTextStyle?.overflow ?? defaultTextStyle.overflow,
            textScaler: textScaler ?? .noScaling,
            maxLines: maxLines ?? defaultTextStyle.maxLines,
            strutStyle: strutStyle,
            textWidthBasis: textWidthBasis ?? defaultTextStyle.textWidthBasis,
            //   textHeightBehavior: textHeightBehavior ?? defaultTextStyle.textHeightBehavior ?? DefaultTextHeightBehavior.maybeOf(context),
            textHeightBehavior: textHeightBehavior ?? defaultTextStyle.textHeightBehavior
                //   selectionRegistrar: registrar,
                //   selectionColor: selectionColor ?? DefaultSelectionStyle.of(context).selectionColor ?? DefaultSelectionStyle.defaultColor,

        )

        // if (registrar != null) {
        //   result = MouseRegion(
        //     cursor: DefaultSelectionStyle.of(context).mouseCursor ?? SystemMouseCursors.text,
        //     child: result,
        //   );
        // }

        // if (semanticsLabel != null) {
        //   result = Semantics(
        //     textDirection: textDirection,
        //     label: semanticsLabel,
        //     child: ExcludeSemantics(
        //       child: result,
        //     ),
        //   );
        // }

        return result
    }

}

/// The text style to apply to descendant [Text] widgets which don't have an
/// explicit style.
public final class DefaultTextStyle: InheritedWidget {
    public init(
        style: TextStyle,
        textAlign: TextAlign? = nil,
        softWrap: Bool = true,
        overflow: TextOverflow = .clip,
        maxLines: Int? = nil,
        textWidthBasis: TextWidthBasis = .parent,
        textHeightBehavior: TextHeightBehavior? = nil,
        @WidgetBuilder child: () -> Widget
    ) {
        self.style = style
        self.textAlign = textAlign
        self.softWrap = softWrap
        self.overflow = overflow
        self.maxLines = maxLines
        self.textWidthBasis = textWidthBasis
        self.textHeightBehavior = textHeightBehavior
        self.child = child()
    }

    public static let fallback = DefaultTextStyle(
        style: TextStyle(),
        textAlign: nil,
        softWrap: true,
        overflow: .clip,
        maxLines: nil,
        textWidthBasis: .parent,
        textHeightBehavior: nil
    ) {
        NullWidget.shared
    }

    /// The text style to apply.
    let style: TextStyle

    /// How each line of text in the Text widget should be aligned horizontally.
    let textAlign: TextAlign?

    /// Whether the text should break at soft line breaks.
    ///
    /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
    ///
    /// This also decides the [overflow] property's behavior. If this is true or null,
    /// the glyph causing overflow, and those that follow, will not be rendered.
    let softWrap: Bool

    /// How visual overflow should be handled.
    ///
    /// If [softWrap] is true or null, the glyph causing overflow, and those that follow,
    /// will not be rendered. Otherwise, it will be shown with the given overflow option.
    let overflow: TextOverflow

    /// An optional maximum number of lines for the text to span, wrapping if necessary.
    /// If the text exceeds the given number of lines, it will be truncated according
    /// to [overflow].
    ///
    /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
    /// edge of the box.
    ///
    /// If this is non-null, it will override even explicit null values of
    /// [Text.maxLines].
    let maxLines: Int?

    /// The strategy to use when calculating the width of the Text.
    ///
    /// See [TextWidthBasis] for possible values and their implications.
    let textWidthBasis: TextWidthBasis

    /// Defines how to apply [TextStyle.height] over and under text.
    let textHeightBehavior: TextHeightBehavior?

    public var child: any Widget

    public func updateShouldNotify(_ oldWidget: DefaultTextStyle) -> Bool {
        return style != oldWidget.style || textAlign != oldWidget.textAlign
            || softWrap != oldWidget.softWrap || overflow != oldWidget.overflow
            || maxLines != oldWidget.maxLines || textWidthBasis != oldWidget.textWidthBasis
            || textHeightBehavior != oldWidget.textHeightBehavior
    }

    public static func of(_ context: BuildContext) -> DefaultTextStyle {
        return maybeOf(context) ?? .fallback
    }

    /// Creates a default text style that overrides the text styles in scope at
    /// this point in the widget tree.
    ///
    /// The given [style] is merged with the [style] from the default text style
    /// for the [BuildContext] where the widget is inserted, and any of the other
    /// arguments that are not null replace the corresponding properties on that
    /// same default text style.
    ///
    /// This constructor cannot be used to override the [maxLines] property of the
    /// ancestor with the value null, since null here is used to mean "defer to
    /// ancestor". To replace a non-null [maxLines] from an ancestor with the null
    /// value (to remove the restriction on number of lines), manually obtain the
    /// ambient [DefaultTextStyle] using [DefaultTextStyle.of], then create a new
    /// [DefaultTextStyle] using the [DefaultTextStyle.new] constructor directly.
    /// See the source below for an example of how to do this (since that's
    /// essentially what this constructor does).
    public static func merge(
        style: TextStyle? = nil,
        textAlign: TextAlign? = nil,
        softWrap: Bool? = nil,
        overflow: TextOverflow? = nil,
        maxLines: Int? = nil,
        textWidthBasis: TextWidthBasis? = nil,
        textHeightBehavior: TextHeightBehavior? = nil,
        @WidgetBuilder child: @escaping () -> Widget
    ) -> some Widget {
        return Builder { context in
            let parent = DefaultTextStyle.of(context)
            return DefaultTextStyle(
                style: parent.style.merge(style),
                textAlign: textAlign ?? parent.textAlign,
                softWrap: softWrap ?? parent.softWrap,
                overflow: overflow ?? parent.overflow,
                maxLines: maxLines ?? parent.maxLines,
                textWidthBasis: textWidthBasis ?? parent.textWidthBasis,
                textHeightBehavior: textHeightBehavior ?? parent.textHeightBehavior
            ) {
                child()
            }
        }
    }
}

extension Widget {
    /// Sets the default style for ``Text``s within this view.
    public func textStyle(
        _ style: TextStyle,
        textAlign: TextAlign? = nil,
        softWrap: Bool = true,
        overflow: TextOverflow = .clip,
        maxLines: Int? = nil,
        textWidthBasis: TextWidthBasis = .parent,
        textHeightBehavior: TextHeightBehavior? = nil
    ) -> some Widget {
        return DefaultTextStyle.merge(
            style: style,
            textAlign: textAlign,
            softWrap: softWrap,
            overflow: overflow,
            maxLines: maxLines,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior
        ) {
            self
        }
    }

    /// Sets the text style to bold, using the specified `FontWeight`. Defaults
    /// to `.bold`.
    public func bold(_ weight: FontWeight = .bold) -> some Widget {
        return textStyle(.init(fontWeight: weight))
    }
}

private class NullWidget: StatelessWidget {
    private init() {}

    static let shared = NullWidget()

    func build(context: BuildContext) -> Widget {
        fatalError(
            "A DefaultTextStyle constructed with DefaultTextStyle.fallback cannot be incorporated into the widget tree, "
                + "it is meant only to provide a fallback value returned by DefaultTextStyle.of() "
                + "when no enclosing default text style is present in a BuildContext."
        )
    }
}
