import Markdown
import Shaft

// InlineContent enum removed - we now use pure TextSpan trees for proper text flow and wrapping

/// A callback type for handling link taps in markdown content.
public typealias MarkdownLinkHandler = (String) -> Void

/// A widget that renders markdown content with customizable styling and themes.
///
/// `MarkdownView` supports standard markdown elements including headings, lists,
/// links, emphasis, code blocks, and more. It provides interactive links with
/// tap handling and customizable themes.
///
/// Example usage:
/// ```swift
/// MarkdownView("# Hello **World**!")
///
/// MarkdownView(
///     myMarkdown,
///     theme: .compact,
///     onLinkTap: { url in print("Tapped: \(url)") }
/// )
/// ```
public final class MarkdownView: StatefulWidget {
    /// The type of content to render.
    public enum Content {
        /// Raw markdown text that will be parsed.
        case text(String)
        /// Pre-parsed markdown document.
        case document(Document)
    }

    /// The markdown content to render.
    public let content: Content

    /// The visual theme controlling colors, fonts, and spacing.
    public let theme: MarkdownTheme

    /// Optional callback for handling link taps.
    public let onLinkTap: MarkdownLinkHandler?

    /// Creates a markdown view with content, theme, and optional link handling.
    public init(
        _ content: Content,
        theme: MarkdownTheme = .init(),
        onLinkTap: MarkdownLinkHandler? = nil
    ) {
        self.content = content
        self.theme = theme
        self.onLinkTap = onLinkTap
    }

    /// Creates a markdown view from a text string.
    public init(
        _ text: String,
        theme: MarkdownTheme = .init(),
        onLinkTap: MarkdownLinkHandler? = nil
    ) {
        self.content = .text(text)
        self.theme = theme
        self.onLinkTap = onLinkTap
    }

    /// Creates a markdown view from a pre-parsed document.
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

    /// Context passed to style implementations containing theme and style state.
    public protocol StyleContext {
        /// The active theme providing colors, fonts, and styling.
        var theme: MarkdownTheme { get }

        /// Push a text style onto the style stack for nested elements.
        func pushStyle(_ style: TextStyle)

        /// Pop the most recent style from the stack.
        func popStyle()

        /// The current effective text style from the style stack.
        var currentStyle: TextStyle { get }

        /// Push a gesture recognizer onto the recognizer stack.
        func pushRecognizer(_ recognizer: GestureRecognizer)

        /// Pop the most recent gesture recognizer from the stack.
        func popRecognizer()

        /// The current active gesture recognizer, if any.
        var currentRecognizer: GestureRecognizer? { get }

        /// Handle a link tap with the given URL.
        func handleLinkTap(_ url: String)

        /// Mark that the view needs to be re-rendered.
        func markNeedsRender()
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

    public func markNeedsRender() {
        setState {}
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
