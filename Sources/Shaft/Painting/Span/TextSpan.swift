// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An immutable span of text.
///
/// A [TextSpan] object can be styled using its [style] property. The style will
/// be applied to the [text] and the [children].
///
/// A [TextSpan] object can just have plain text, or it can have children
/// [TextSpan] objects with their own styles that (possibly only partially)
/// override the [style] of this object. If a [TextSpan] has both [text] and
/// [children], then the [text] is treated as if it was an un-styled [TextSpan]
/// at the start of the [children] list. Leaving the [TextSpan.text] field null
/// results in the [TextSpan] acting as an empty node in the [InlineSpan] tree
/// with a list of children.
///
/// To paint a [TextSpan] on a [Canvas], use a [TextPainter]. To display a text
/// span in a widget, use a [RichText]. For text with a single style, consider
/// using the [Text] widget.
public class TextSpan: InlineSpan {
    public init(
        text: String? = nil,
        children: [InlineSpan]? = nil,
        style: TextStyle? = nil,
        semanticsLabel: String? = nil,
        spellOut: Bool? = nil
    ) {
        self.text = text
        self.children = children
        self.style = style
        self.semanticsLabel = semanticsLabel
        self.spellOut = spellOut
    }

    public let style: TextStyle?

    /// The text contained in this span.
    ///
    /// If both [text] and [children] are non-null, the text will precede the
    /// children.
    ///
    /// This getter does not include the contents of its children.
    public let text: String?

    /// Additional spans to include as children.
    ///
    /// If both [text] and [children] are non-null, the text will precede the
    /// children.
    ///
    /// Modifying the list after the [TextSpan] has been created is not supported
    /// and may have unexpected results.
    ///
    /// The list must not contain any nulls.
    public let children: [InlineSpan]?

    /// A gesture recognizer that will receive events that hit this span.
    ///
    /// [InlineSpan] itself does not implement hit testing or event dispatch. The
    /// object that manages the [InlineSpan] painting is also responsible for
    /// dispatching events. In the rendering library, that is the
    /// [RenderParagraph] object, which corresponds to the [RichText] widget in
    /// the widgets layer; these objects do not bubble events in [InlineSpan]s,
    /// so a [recognizer] is only effective for events that directly hit the
    /// [text] of that [InlineSpan], not any of its [children].
    ///
    /// [InlineSpan] also does not manage the lifetime of the gesture recognizer.
    /// The code that owns the [GestureRecognizer] object must call
    /// [GestureRecognizer.dispose] when the [InlineSpan] object is no longer
    /// used.
    // public let recognizer: GestureRecognizer?

    /// Mouse cursor when the mouse hovers over this span.
    ///
    /// The default value is [SystemMouseCursors.click] if [recognizer] is not
    /// null, or [MouseCursor.defer] otherwise.
    ///
    /// [TextSpan] itself does not implement hit testing or cursor changing.
    /// The object that manages the [TextSpan] painting is responsible
    /// to return the [TextSpan] in its hit test, as well as providing the
    /// correct mouse cursor when the [TextSpan]'s mouse cursor is
    /// [MouseCursor.defer].
    // public let mouseCursor: MouseCursor

    /// Returns the value of [mouseCursor].
    ///
    /// This field, required by [MouseTrackerAnnotation], is hidden publicly to
    /// avoid the confusion as a text cursor.
    //   MouseCursor get cursor => mouseCursor;

    /// An alternative semantics label for this [TextSpan].
    ///
    /// If present, the semantics of this span will contain this value instead
    /// of the actual text.
    ///
    /// This is useful for replacing abbreviations or shorthands with the full
    /// text value:
    ///
    /// ```swift
    /// TextSpan(text: r'$$', semanticsLabel: 'Double dollars')
    /// ```
    public let semanticsLabel: String?

    /// The language of the text in this span and its span children.
    ///
    /// Setting the locale of this text span affects the way that assistive
    /// technologies, such as VoiceOver or TalkBack, pronounce the text.
    ///
    /// If this span contains other text span children, they also inherit the
    /// locale from this span unless explicitly set to different locales.
    // public let locale: ui.Locale?

    /// Whether the assistive technologies should spell out this text character
    /// by character.
    ///
    /// If the text is 'hello world', setting this to true causes the assistive
    /// technologies, such as VoiceOver or TalkBack, to pronounce
    /// 'h-e-l-l-o-space-w-o-r-l-d' instead of complete words. This is useful for
    /// texts, such as passwords or verification codes.
    ///
    /// If this span contains other text span children, they also inherit the
    /// property from this span unless explicitly set.
    ///
    /// If the property is not set, this text span inherits the spell out setting
    /// from its parent. If this text span does not have a parent or the parent
    /// does not have a spell out setting, this text span does not spell out the
    /// text by default.
    public let spellOut: Bool?

    public func build(
        builder: ParagraphBuilder,
        textScaler: any TextScaler,
        dimensions: [PlaceholderDimensions]
    ) {
        var hasStyle = false
        if let style {
            builder.pushStyle(style.toSpanStyle(textScaler: textScaler))
            hasStyle = true
        }
        if let text {
            builder.addText(text)
        }
        if let children {
            for child in children {
                child.build(builder: builder, textScaler: textScaler, dimensions: dimensions)
            }
        }
        if hasStyle {
            builder.pop()
        }
    }

    /// Walks this [TextSpan] and its descendants in pre-order and calls [visitor]
    /// for each span that has text.
    ///
    /// When `visitor` returns true, the walk will continue. When `visitor`
    /// returns false, then the walk will end.
    public func visitChildren(_ visitor: InlineSpanVisitor) -> Bool {
        if text != nil && !visitor(self) {
            return false
        }
        if let children {
            for child in children {
                if !child.visitChildren(visitor) {
                    return false
                }
            }
        }
        return true
    }

    public func visitDirectChildren(_ visitor: InlineSpanVisitor) -> Bool {
        if let children {
            for child in children {
                if !visitor(child) {
                    return false
                }
            }
        }
        return true
    }

    public func codeUnitAtVisitor(_ index: TextIndex, _ offset: inout TextIndex) -> Int? {
        guard let text else {
            return nil
        }
        let localOffset = index - offset
        assert(localOffset >= .zero)
        offset = offset.advanced(by: text.utf16.count)
        return localOffset.utf16Offset < text.utf16.count ? text.codeUnitAt(localOffset) : nil
    }

    public func compareTo(_ other: InlineSpan) -> RenderComparison {
        return RenderComparison.layout
    }

    public func getPlainText(
        buffer: StringBuilder,
        includeSemanticsLabels: Bool,
        includePlaceholders: Bool
    ) {
        if semanticsLabel != nil && includeSemanticsLabels {
            buffer.append(semanticsLabel!)
        } else if text != nil {
            buffer.append(text!)
        }
        if let children {
            for child in children {
                child.getPlainText(
                    buffer: buffer,
                    includeSemanticsLabels: includeSemanticsLabels,
                    includePlaceholders: includePlaceholders
                )
            }
        }
    }

}
