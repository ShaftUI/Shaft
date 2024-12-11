// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

let kEllipsis = "\u{2026}"

/// Parent data used by [RenderParagraph] and [RenderEditable] to annotate
/// inline contents (such as [WidgetSpan]s) with.
public class TextParentData: ParentData, ContainerParentData {
    public typealias ChildType = RenderBox

    public var nextSibling: RenderBox?

    public var previousSibling: RenderBox?

    /// The offset at which to paint the child in the parent's coordinate
    /// system.
    ///
    /// A `null` value indicates this inline widget is not laid out. For
    /// instance, when the inline widget has never been laid out, or the inline
    /// widget is ellipsized away.
    public private(set) var offset: Offset? = nil

    /// The [PlaceholderSpan] associated with this render child.
    ///
    /// This field is usually set by a [ParentDataWidget], and is typically not
    /// null when `performLayout` is called.
    var span: PlaceholderSpan? = nil
}

extension TextParentData: CustomStringConvertible {
    public var description: String {
        "widget: \(String(describing: span)), \(offset == nil ? "not laid out" : "offset: \(offset!)")"
    }
}

/// A render object that displays a paragraph of text.
public class RenderParagraph: RenderBox, RenderObjectWithChildren {
    /// Creates a paragraph render object.
    ///
    /// The [maxLines] property may be null (and indeed defaults to null), but
    /// if it is not null, it must be greater than zero.
    public init(
        _ text: InlineSpan,
        textAlign: TextAlign = .start,
        textDirection: TextDirection,
        softWrap: Bool = true,
        overflow: TextOverflow = .clip,
        textScaler: any TextScaler = .noScaling,
        maxLines: Int? = nil,
        // locale: Locale? = nil,
        strutStyle: StrutStyle? = nil,
        textWidthBasis: TextWidthBasis = .parent,
        textHeightBehavior: TextHeightBehavior? = nil,
        children: [RenderBox] = [],
        selectionColor: Color? = nil
            // registrar: SelectionRegistrar? = nil
    ) {
        assert(maxLines == nil || maxLines! > 0)
        textPainter = TextPainter(
            text: text,
            textAlign: textAlign,
            textDirection: textDirection,
            textScaler: textScaler,
            ellipsis: overflow == .ellipsis ? kEllipsis : nil,
            maxLines: maxLines,
            // locale: locale,
            strutStyle: strutStyle,
            textHeightBehavior: textHeightBehavior,
            textWidthBasis: textWidthBasis
        )
        self.softWrap = softWrap
        self.overflow = overflow
        super.init()
        self.text = text
        self.textAlign = textAlign
        self.textDirection = textDirection
        self.textScaler = textScaler
        self.maxLines = maxLines
        // this.locale = locale
        self.strutStyle = strutStyle
        self.textWidthBasis = textWidthBasis
        self.textHeightBehavior = textHeightBehavior
        // addAll(children)
        // this.registrar = registrar
    }

    public typealias ChildType = RenderBox
    public typealias ParentDataType = TextParentData
    public var childMixin = RenderContainerMixin<RenderBox>()

    private var textPainter: TextPainter

    var cachedAttributedLabels: [Int]?  // [AttributedString]?

    var cachedCombinedSemanticsInfos: [Int]?  // [InlineSpanSemanticsInformation]?

    /// The text to display.
    public var text: InlineSpan {
        get {
            textPainter.text!
        }
        set {
            switch textPainter.text!.compareTo(newValue) {
            case .identical:
                return
            case .metadata:
                textPainter.text = newValue
                cachedCombinedSemanticsInfos = nil
                markNeedsSemanticsUpdate()
            case RenderComparison.paint:
                textPainter.text = newValue
                cachedAttributedLabels = nil
                canComputeIntrinsicsCached = nil
                cachedCombinedSemanticsInfos = nil
                markNeedsPaint()
                markNeedsSemanticsUpdate()
            case RenderComparison.layout:
                textPainter.text = newValue
                overflowShader = nil
                cachedAttributedLabels = nil
                cachedCombinedSemanticsInfos = nil
                canComputeIntrinsicsCached = nil
                markNeedsLayout()
            // removeSelectionRegistrarSubscription()
            // disposeSelectableFragments()
            // updateSelectionRegistrarSubscription()
            }
        }
    }

    /// How the text should be aligned horizontally.
    public var textAlign: TextAlign {
        get {
            textPainter.textAlign
        }
        set {
            if textPainter.textAlign == newValue {
                return
            }
            textPainter.textAlign = newValue
            markNeedsPaint()
        }
    }

    /// The directionality of the text.
    ///
    /// This decides how the [TextAlign.start], [TextAlign.end], and
    /// [TextAlign.justify] values of [textAlign] are interpreted.
    ///
    /// This is also used to disambiguate how to render bidirectional text. For
    /// example, if the [text] is an English phrase followed by a Hebrew phrase,
    /// in a [TextDirection.ltr] context the English phrase will be on the left
    /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
    /// context, the English phrase will be on the right and the Hebrew phrase on
    /// its left.
    public var textDirection: TextDirection {
        get {
            textPainter.textDirection!
        }
        set {
            if textPainter.textDirection == newValue {
                return
            }
            textPainter.textDirection = newValue
            markNeedsLayout()
        }
    }

    /// Whether the text should break at soft line breaks.
    ///
    /// If false, the glyphs in the text will be positioned as if there was
    /// unlimited horizontal space.
    ///
    /// If [softWrap] is false, [overflow] and [textAlign] may have unexpected
    /// effects.
    public var softWrap: Bool {
        didSet {
            if softWrap != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// How visual overflow should be handled.
    public var overflow: TextOverflow {
        didSet {
            if overflow != oldValue {
                textPainter.ellipsis = overflow == .ellipsis ? kEllipsis : nil
                markNeedsLayout()
            }
        }
    }

    /// How textual contents should be scaled for better readability.
    public var textScaler: any TextScaler {
        get {
            textPainter.textScaler
        }
        set {
            if textScaler.isEqualTo(newValue) {
                return
            }
            textPainter.textScaler = newValue
            overflowShader = nil
            markNeedsLayout()
        }
    }

    /// An optional maximum number of lines for the text to span, wrapping if
    /// necessary. If the text exceeds the given number of lines, it will be
    /// truncated according to [overflow] and [softWrap].
    public var maxLines: Int? {
        get {
            textPainter.maxLines
        }
        set {
            if textPainter.maxLines == newValue {
                return
            }
            textPainter.maxLines = newValue
            overflowShader = nil
            markNeedsLayout()
        }
    }

    /// Used by this paragraph's internal [TextPainter] to select a
    /// locale-specific font.
    ///
    /// In some cases, the same Unicode character may be rendered differently
    /// depending on the locale. For example, the '骨' character is rendered
    /// differently in the Chinese and Japanese locales. In these cases, the
    /// [locale] may be used to select a locale-specific font.
    //   Locale? get locale => _textPainter.locale;
    //   /// The value may be null.
    //   set locale(Locale? value) {
    //     if (_textPainter.locale == value) {
    //       return;
    //     }
    //     _textPainter.locale = value;
    //     _overflowShader = null;
    //     markNeedsLayout();
    //   }

    /// Defines the strut, which sets the minimum height a line can be relative
    /// to the baseline.
    public var strutStyle: StrutStyle? {
        get {
            textPainter.strutStyle
        }
        set {
            if textPainter.strutStyle == newValue {
                return
            }
            textPainter.strutStyle = newValue
            overflowShader = nil
            markNeedsLayout()
        }
    }

    /// The different ways of measuring the width of one or more lines of text.
    public var textWidthBasis: TextWidthBasis {
        get {
            textPainter.textWidthBasis
        }
        set {
            if textPainter.textWidthBasis == newValue {
                return
            }
            textPainter.textWidthBasis = newValue
            overflowShader = nil
            markNeedsLayout()
        }
    }

    /// Defines how to apply [TextStyle.height] over and under text.
    public var textHeightBehavior: TextHeightBehavior? {
        get {
            textPainter.textHeightBehavior
        }
        set {
            if textPainter.textHeightBehavior == newValue {
                return
            }
            textPainter.textHeightBehavior = newValue
            overflowShader = nil
            markNeedsLayout()
        }
    }

    private var canComputeIntrinsicsCached: Bool? = nil

    private var needsClipping = false
    private var overflowShader: Int? = 0  // Shader?

    private func markNeedsSemanticsUpdate() {}

    private func layoutTextWithConstraints(_ constraints: BoxConstraints) {
        // textPainter.setPlaceholderDimensions(_placeholderDimensions)
        layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth)
    }

    private func layoutText(minWidth: Float = 0.0, maxWidth: Float = .infinity) {
        let widthMatters = softWrap || overflow == .ellipsis
        textPainter.layout(minWidth: minWidth, maxWidth: widthMatters ? maxWidth : .infinity)
    }

    public override func performLayout() {
        // placeholderDimensions = layoutInlineChildren(
        //     constraints.maxWidth,
        //     ChildLayoutHelper.layoutChild
        // )
        layoutTextWithConstraints(boxConstraint)
        // positionInlineChildren(_textPainter.inlinePlaceholderBoxes!)

        // We grab _textPainter.size and _textPainter.didExceedMaxLines here because
        // assigning to `size` will trigger us to validate our intrinsic sizes,
        // which will change _textPainter's layout because the intrinsic size
        // calculations are destructive. Other _textPainter state will also be
        // affected. See also RenderEditable which has a similar issue.
        let textSize = textPainter.size
        let textDidExceedMaxLines = textPainter.didExceedMaxLines
        size = boxConstraint.constrain(textSize)

        let didOverflowHeight = size.height < textSize.height || textDidExceedMaxLines
        let didOverflowWidth = size.width < textSize.width
        let hasVisualOverflow = didOverflowWidth || didOverflowHeight
        if hasVisualOverflow {
            switch overflow {
            case .visible:
                needsClipping = false
                overflowShader = nil
            case .clip, .ellipsis:
                needsClipping = true
                overflowShader = nil
            case .fade:
                needsClipping = true
                let fadeSizePainter = TextPainter(
                    text: TextSpan(text: "\u{2026}", style: textPainter.text!.style),
                    textDirection: textDirection,
                    textScaler: textScaler
                        // locale: locale,
                )
                fadeSizePainter.layout()
                if didOverflowWidth {
                    // var fadeEnd: Float
                    // var fadeStart: Float
                    // switch textDirection {
                    // case TextDirection.rtl:
                    //     fadeEnd = 0.0
                    //     fadeStart = fadeSizePainter.width
                    // case TextDirection.ltr:
                    //     fadeEnd = size.width
                    //     fadeStart = fadeEnd - fadeSizePainter.width
                    // }
                    // overflowShader = ui.Gradient.linear(
                    //   Offset(fadeStart, 0.0),
                    //   Offset(fadeEnd, 0.0),
                    //   <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
                    // );
                } else {
                    // let fadeEnd = size.height
                    // let fadeStart = fadeEnd - fadeSizePainter.height / 2.0
                    // overflowShader = ui.Gradient.linear(
                    //   Offset(0.0, fadeStart),
                    //   Offset(0.0, fadeEnd),
                    //   <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
                    // );
                }
            }
        } else {
            needsClipping = false
            overflowShader = nil
        }
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        // Ideally we could compute the min/max intrinsic width/height with a
        // non-destructive operation. However, currently, computing these values
        // will destroy state inside the painter. If that happens, we need to
        // get back the correct state by calling _layout again.
        //
        // If you remove this call, make sure that changing the textAlign still
        // works properly.
        layoutTextWithConstraints(boxConstraint)

        // if needsClipping {
        //     let bounds = offset & size
        //     if let overflowShader {
        //         // This layer limits what the shader below blends with to be just the
        //         // text (as opposed to the text and its background).
        //         context.canvas.saveLayer(bounds, Paint())
        //     } else {
        //         context.canvas.save()
        //     }
        //     context.canvas.clipRect(bounds)
        // }

        // if let lastSelectableFragments {
        //     for fragment in lastSelectableFragments {
        //         fragment.paint(context, offset)
        //     }
        // }

        textPainter.paint(context.canvas, offset: offset)

        // paintInlineChildren(context, offset);

        // if needsClipping {
        //     if let overflowShader {
        //         context.canvas.translate(offset.dx, offset.dy)
        //         let paint = Paint()
        //         paint.blendMode = BlendMode.modulate
        //         paint.shader = _overflowShader
        //         context.canvas.drawRect(Offset.zero & size, paint)
        //     }
        //     context.canvas.restore()
        // }
    }

    public override func hitTestSelf(_ position: Offset) -> Bool {
        true
    }

    //       @override
    //   bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    //     final TextPosition textPosition = _textPainter.getPositionForOffset(position);
    //     switch (_textPainter.text!.getSpanForPosition(textPosition)) {
    //       case final HitTestTarget span:
    //         result.add(HitTestEntry(span));
    //         return true;
    //       case _:
    //         return hitTestInlineChildren(result, position);
    //     }
    //   }

}
