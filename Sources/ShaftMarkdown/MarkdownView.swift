import Markdown
import Shaft

// InlineContent enum removed - we now use pure TextSpan trees for proper text flow and wrapping

/// A callback type for handling link taps in markdown content.
public typealias MarkdownLinkHandler = (String) -> Void

/// A widget that displays markdown content with customizable styling.
public final class MarkdownView: StatefulWidget {
    public enum Content {
        case text(String)
        case document(Document)
    }

    public let content: Content

    public let theme: MarkdownTheme
    public let onLinkTap: MarkdownLinkHandler?

    public init(
        _ content: Content,
        theme: MarkdownTheme = .init(),
        onLinkTap: MarkdownLinkHandler? = nil
    ) {
        self.content = content
        self.theme = theme
        self.onLinkTap = onLinkTap
    }

    public init(
        _ text: String,
        theme: MarkdownTheme = .init(),
        onLinkTap: MarkdownLinkHandler? = nil
    ) {
        self.content = .text(text)
        self.theme = theme
        self.onLinkTap = onLinkTap
    }

    public init(
        _ document: Document,
        theme: MarkdownTheme = .init(),
        onLinkTap: MarkdownLinkHandler? = nil
    ) {
        self.content = .document(document)
        self.theme = theme
        self.onLinkTap = onLinkTap
    }

    public func createState() -> State<MarkdownView> { MarkdownViewState() }

    public protocol StyleContext {
        var theme: MarkdownTheme { get }

        func pushStyle(_ style: TextStyle)

        func popStyle()

        var currentStyle: TextStyle { get }

        func pushRecognizer(_ recognizer: GestureRecognizer)

        func popRecognizer()

        var currentRecognizer: GestureRecognizer? { get }

        func handleLinkTap(_ url: String)
    }

    public protocol Style {
        func buildDocument(
            context: StyleContext,
            buildChildren: (StyleContext) -> [Widget]
        ) -> Widget

        func buildHeading(
            context: StyleContext,
            level: Int,
            buildChildren: (StyleContext) -> [InlineSpan]
        ) -> Widget

        func buildParagraph(
            context: StyleContext,
            buildChildren: (StyleContext) -> [InlineSpan]
        ) -> Widget

        func buildCodeBlock(
            context: StyleContext,
            code: String,
            language: String?
        ) -> Widget

        func buildBlockQuote(
            context: StyleContext,
            buildChildren: (StyleContext) -> [Widget]
        ) -> Widget

        func buildUnorderedList(
            context: StyleContext,
            buildItems: (StyleContext) -> [Widget]
        ) -> Widget

        func buildOrderedList(
            context: StyleContext,
            buildItems: (StyleContext) -> [Widget]
        ) -> Widget

        func buildListItem(
            context: StyleContext,
            buildChildren: (StyleContext) -> [Widget],
            index: Int?,
            isOrdered: Bool
        ) -> Widget

        func buildThematicBreak(context: StyleContext) -> Widget

        // Inline elements
        func buildText(context: StyleContext, text: String) -> InlineSpan

        func buildEmphasis(context: StyleContext, buildChildren: (StyleContext) -> [InlineSpan])
            -> InlineSpan

        func buildStrong(context: StyleContext, buildChildren: (StyleContext) -> [InlineSpan])
            -> InlineSpan

        func buildCode(context: StyleContext, code: String) -> InlineSpan

        func buildLink(
            context: StyleContext,
            destination: String?,
            buildChildren: (StyleContext) -> [InlineSpan]
        ) -> InlineSpan

        func buildSoftBreak(context: StyleContext) -> InlineSpan

        func buildLineBreak(context: StyleContext) -> InlineSpan
    }
}

public class MarkdownViewState: State<MarkdownView>, MarkdownView.StyleContext {
    public var theme: MarkdownTheme {
        widget.theme
    }

    private var styleStack = StyleStack()

    public func pushStyle(_ style: TextStyle) {
        styleStack.push(merge: style)
    }

    public func popStyle() {
        styleStack.pop()
    }

    public var currentStyle: TextStyle {
        styleStack.current
    }

    private var recognizerStack = [GestureRecognizer]()

    public func pushRecognizer(_ recognizer: GestureRecognizer) {
        recognizerStack.append(recognizer)
    }

    public func popRecognizer() {
        let _ = recognizerStack.popLast()
    }

    public var currentRecognizer: GestureRecognizer? {
        recognizerStack.last
    }

    public func handleLinkTap(_ url: String) {
        if let onLinkTap = widget.onLinkTap {
            onLinkTap(url)
        } else {
            let _ = backend.launchUrl(url)
        }
    }

    public override func initState() {
        super.initState()
        styleStack.setBase(DefaultTextStyle.of(context).style)
    }

    public override func didChangeDependencies() {
        super.didChangeDependencies()
        styleStack.setBase(DefaultTextStyle.of(context).style)
    }

    /// Resolves the document from the widget's content.
    private func resolveDocument() -> Document {
        switch widget.content {
        case .text(let text):
            return Document(parsing: text)
        case .document(let document):
            return document
        }
    }

    public override func build(context: BuildContext) -> Widget {
        let document = resolveDocument()
        let style: any MarkdownView.Style = Inherited.valueOf(context) ?? .default
        return renderDocument(document, style: style)
    }

    private func renderDocument(_ document: Document, style: MarkdownView.Style) -> Widget {
        return style.buildDocument(
            context: self,
            buildChildren: { context in
                document.blockChildren.map { renderBlock($0, style: style) } as [Widget]
            }
        )
    }

    private func renderBlock(_ block: BlockMarkup, style: MarkdownView.Style) -> Widget {
        switch block {
        case let heading as Heading:
            return style.buildHeading(
                context: self,
                level: heading.level,
                buildChildren: { context in
                    heading.inlineChildren.map { renderInline($0, style: style) } as [InlineSpan]
                }
            )
        case let paragraph as Markdown.Paragraph:
            return style.buildParagraph(
                context: self,
                buildChildren: { context in
                    paragraph.inlineChildren.map { renderInline($0, style: style) } as [InlineSpan]
                }
            )
        case let codeBlock as CodeBlock:
            return style.buildCodeBlock(
                context: self,
                code: codeBlock.code.trimmingCharacters(in: .whitespacesAndNewlines),
                language: codeBlock.language
            )
        case let blockQuote as BlockQuote:
            return style.buildBlockQuote(
                context: self,
                buildChildren: { context in
                    blockQuote.blockChildren.map { renderBlock($0, style: style) } as [Widget]
                }
            )
        case let unorderedList as UnorderedList:
            return style.buildUnorderedList(
                context: self,
                buildItems: { context in
                    unorderedList.listItems.enumerated().map { (_, listItem) in
                        style.buildListItem(
                            context: context,
                            buildChildren: { context in
                                listItem.blockChildren.map { renderBlock($0, style: style) }
                                    as [Widget]
                            },
                            index: nil,
                            isOrdered: false
                        )
                    } as [Widget]
                }
            )
        case let orderedList as OrderedList:
            return style.buildOrderedList(
                context: self,
                buildItems: { context in
                    orderedList.listItems.enumerated().map { (index, listItem) in
                        style.buildListItem(
                            context: context,
                            buildChildren: { context in
                                listItem.blockChildren.map { renderBlock($0, style: style) }
                                    as [Widget]
                            },
                            index: index + 1,
                            isOrdered: true
                        )
                    } as [Widget]
                }
            )
        case _ as ThematicBreak:
            return style.buildThematicBreak(context: self)
        default:
            return SizedBox()
        }
    }

    private func renderInline(_ inline: InlineMarkup, style: MarkdownView.Style) -> InlineSpan {
        switch inline {
        case let text as Markdown.Text:
            return style.buildText(context: self, text: text.string)
        case let emphasis as Emphasis:
            return style.buildEmphasis(
                context: self,
                buildChildren: { context in
                    emphasis.inlineChildren.map { renderInline($0, style: style) } as [InlineSpan]
                }
            )
        case let strong as Strong:
            return style.buildStrong(
                context: self,
                buildChildren: { context in
                    strong.inlineChildren.map { renderInline($0, style: style) } as [InlineSpan]
                }
            )
        case let inlineCode as InlineCode:
            return style.buildCode(context: self, code: inlineCode.code)
        case let link as Link:
            return style.buildLink(
                context: self,
                destination: link.destination,
                buildChildren: { context in
                    link.inlineChildren.map { renderInline($0, style: style) } as [InlineSpan]
                }
            )
        case _ as SoftBreak:
            return style.buildSoftBreak(context: self)
        case _ as LineBreak:
            return style.buildLineBreak(context: self)
        default:
            return TextSpan()
        }
    }
}
