import Shaft

/// The default implementation of the `MarkdownView.Style` protocol. Users can
/// override this to customize the styling of the markdown content.
open class DefaultMarkdownStyle: MarkdownView.Style {
    open func buildDocument(
        context: any MarkdownView.StyleContext,
        buildChildren: (any MarkdownView.StyleContext) -> [any Shaft.Widget]
    ) -> any Shaft.Widget {
        Column(crossAxisAlignment: .stretch) {
            buildChildren(context)
        }
    }

    open func buildHeading(
        context: any MarkdownView.StyleContext,
        level: Int,
        buildChildren: (any MarkdownView.StyleContext) -> [any Shaft.InlineSpan]
    ) -> any Shaft.Widget {
        context.pushStyle(context.theme.heading(level: level))
        defer { context.popStyle() }
        return Padding(.only(bottom: 12)) {
            RichText(
                text: TextSpan(children: buildChildren(context), style: context.currentStyle)
            )
        }
    }

    open func buildParagraph(
        context: any MarkdownView.StyleContext,
        buildChildren: (any MarkdownView.StyleContext) -> [any Shaft.InlineSpan]
    ) -> any Shaft.Widget {
        Padding(.only(bottom: 8)) {
            RichText(
                text: TextSpan(children: buildChildren(context), style: context.currentStyle)
            )
        }
    }

    open func buildCodeBlock(
        context: any MarkdownView.StyleContext,
        code: String,
        language: String?
    ) -> any Shaft.Widget {
        Padding(.only(bottom: 12)) {
            DecoratedBox(
                decoration: BoxDecoration(
                    color: context.theme.codeBlockBackground,
                    border: Border.all(color: context.theme.codeBlockBorder),
                    borderRadius: BorderRadius.circular(6)
                )
            ) {
                Padding(.all(12)) {
                    Text(
                        code,
                        style: context.theme.code.copyWith(fontSize: 14)
                    )
                }
            }
        }
    }

    open func buildBlockQuote(
        context: any MarkdownView.StyleContext,
        buildChildren: (any MarkdownView.StyleContext) -> [any Shaft.Widget]
    ) -> any Shaft.Widget {
        Padding(.only(bottom: 12)) {
            DecoratedBox(
                decoration: BoxDecoration(
                    color: context.theme.blockQuoteBackground,
                    border: Border(
                        left: BorderSide(color: context.theme.blockQuoteBorder, width: 4)
                    ),
                    borderRadius: BorderRadius.circular(4)
                )
            ) {
                Padding(.symmetric(vertical: 10, horizontal: 12)) {
                    Column(crossAxisAlignment: .stretch) {
                        buildChildren(context)
                    }
                }
            }
        }
    }

    open func buildUnorderedList(
        context: any MarkdownView.StyleContext,
        buildItems: (any MarkdownView.StyleContext) -> [any Shaft.Widget]
    ) -> any Shaft.Widget {
        Padding(.only(bottom: 12)) {
            Column(crossAxisAlignment: .stretch) {
                buildItems(context)
            }
        }
    }

    open func buildOrderedList(
        context: any MarkdownView.StyleContext,
        buildItems: (any MarkdownView.StyleContext) -> [any Shaft.Widget]
    ) -> any Shaft.Widget {
        Padding(.only(bottom: 12)) {
            Column(crossAxisAlignment: .stretch) {
                buildItems(context)
            }
        }
    }

    open func buildListItem(
        context: any MarkdownView.StyleContext,
        buildChildren: (any MarkdownView.StyleContext) -> [any Shaft.Widget],
        index: Int?,
        isOrdered: Bool
    ) -> any Shaft.Widget {
        let bullet = isOrdered ? "\(index ?? 1)." : "•"
        return Padding(.only(left: 16, bottom: 2)) {
            Row(crossAxisAlignment: .start) {
                Padding(.only(top: 1, right: 6)) {
                    SizedBox(width: 16) {
                        Text(
                            bullet,
                            style: TextStyle(color: context.theme.listBulletColor, fontSize: 14)
                        )
                    }
                }
                Expanded {
                    Column(crossAxisAlignment: .stretch) {
                        buildChildren(context)
                    }
                }
            }
        }
    }

    open func buildThematicBreak(context: any MarkdownView.StyleContext) -> any Shaft.Widget {
        Padding(.symmetric(vertical: 12)) {
            SizedBox(height: 1) {
                DecoratedBox(
                    decoration: BoxDecoration(color: context.theme.thematicBreakColor)
                )
            }
        }
    }

    // Inline elements
    open func buildText(
        context: any MarkdownView.StyleContext,
        text: String
    ) -> any Shaft.InlineSpan {
        TextSpan(text: text, style: context.currentStyle, recognizer: context.currentRecognizer)
    }

    open func buildEmphasis(
        context: any MarkdownView.StyleContext,
        buildChildren: (any MarkdownView.StyleContext) -> [any Shaft.InlineSpan]
    ) -> any Shaft.InlineSpan {
        context.pushStyle(context.theme.emphasis)
        defer { context.popStyle() }
        return TextSpan(
            children: buildChildren(context),
            style: context.currentStyle,
            recognizer: context.currentRecognizer
        )
    }

    open func buildStrong(
        context: any MarkdownView.StyleContext,
        buildChildren: (any MarkdownView.StyleContext) -> [any Shaft.InlineSpan]
    ) -> any Shaft.InlineSpan {
        context.pushStyle(context.theme.strong)
        defer { context.popStyle() }
        return TextSpan(
            children: buildChildren(context),
            style: context.currentStyle,
            recognizer: context.currentRecognizer
        )
    }

    open func buildCode(
        context: any MarkdownView.StyleContext,
        code: String
    ) -> any Shaft.InlineSpan {
        context.pushStyle(context.theme.code)
        defer { context.popStyle() }
        return TextSpan(
            text: code,
            style: context.currentStyle,
            recognizer: context.currentRecognizer
        )
    }

    open func buildLink(
        context: any MarkdownView.StyleContext,
        destination: String?,
        buildChildren: (any MarkdownView.StyleContext) -> [any Shaft.InlineSpan]
    ) -> any Shaft.InlineSpan {
        let recognizer = TapGestureRecognizer()
        if let destination = destination {
            recognizer.onTap = {
                context.handleLinkTap(destination)
            }
        }

        context.pushRecognizer(recognizer)
        defer { context.popRecognizer() }

        context.pushStyle(context.theme.link)
        defer { context.popStyle() }

        return TextSpan(
            children: buildChildren(context),
            style: context.currentStyle,
            recognizer: recognizer,
            mouseCursor: .system(.click),
        )
    }

    open func buildSoftBreak(context: any MarkdownView.StyleContext) -> any Shaft.InlineSpan {
        TextSpan(
            text: " ",
            style: context.currentStyle,
            recognizer: context.currentRecognizer,
        )
    }

    open func buildLineBreak(context: any MarkdownView.StyleContext) -> any Shaft.InlineSpan {
        TextSpan(
            text: "\n",
            style: context.currentStyle,
            recognizer: context.currentRecognizer,
        )
    }
}

extension MarkdownView.Style where Self == DefaultMarkdownStyle {
    public static var `default`: DefaultMarkdownStyle { DefaultMarkdownStyle() }
}
