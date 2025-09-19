import Markdown
import Shaft

// InlineContent enum removed - we now use pure TextSpan trees for proper text flow and wrapping

/// A callback type for handling link taps in markdown content.
public typealias MarkdownLinkHandler = (String) -> Void

/// A widget that displays markdown content with customizable styling.
public final class MarkdownView: StatefulWidget {
    /// The content source for the markdown view.
    public enum Content {
        case text(String)
        case document(Document)
    }

    public let content: Content
    public let onLinkTap: MarkdownLinkHandler?

    public init(
        _ content: Content,
        onLinkTap: MarkdownLinkHandler? = nil
    ) {
        self.content = content
        self.onLinkTap = onLinkTap
    }

    public init(
        _ text: String,
        onLinkTap: MarkdownLinkHandler? = nil
    ) {
        self.content = .text(text)
        self.onLinkTap = onLinkTap
    }

    public init(
        _ document: Document,
        onLinkTap: MarkdownLinkHandler? = nil
    ) {
        self.content = .document(document)
        self.onLinkTap = onLinkTap
    }

    // Legacy initializers for backward compatibility
    public init(content: Content) {
        self.content = content
        self.onLinkTap = nil
    }

    public init(text: String) {
        self.content = .text(text)
        self.onLinkTap = nil
    }

    public init(document: Document) {
        self.content = .document(document)
        self.onLinkTap = nil
    }

    public func createState() -> State<MarkdownView> {
        return MarkdownViewState()
    }

    /// A type that applies custom appearance to markdown elements within a view hierarchy.
    public protocol Style: Equatable {
        /// The color theme to use for markdown elements.
        var theme: MarkdownTheme { get }

        /// Builds the root container for all markdown content.
        func build(children: [Widget]) -> Widget

        /// Builds a heading widget with the specified level and text.
        func buildHeading(level: Int, text: String) -> Widget

        /// Builds a paragraph widget with the specified text.
        func buildParagraph(text: String) -> Widget

        /// Builds a paragraph widget with rich text formatting using TextSpan array.
        func buildParagraph(spans: [TextSpan]) -> Widget

        /// Builds a paragraph widget with rich inline content using a single InlineSpan tree.
        func buildParagraph(content: InlineSpan) -> Widget

        /// Builds a code block widget with syntax highlighting support.
        func buildCodeBlock(code: String, language: String?) -> Widget

        /// Builds a list container widget.
        func buildList(items: [Widget], isOrdered: Bool) -> Widget

        /// Builds a list item widget.
        func buildListItem(content: [Widget], isOrdered: Bool) -> Widget

        /// Builds a block quote widget.
        func buildBlockQuote(content: [Widget]) -> Widget

        /// Builds a thematic break (horizontal rule) widget.
        func buildThematicBreak() -> Widget

        // Link handling removed from Style - now handled by MarkdownView.onLinkTap
    }
}

/// A color theme for markdown elements.
public struct MarkdownTheme: Equatable {
    /// The primary text color.
    public let text: Color

    /// The background color for code elements.
    public let codeBackground: Color

    /// The background color for block quotes.
    public let blockQuoteBackground: Color

    /// The border color for block quotes.
    public let blockQuoteBorder: Color

    /// The color for links.
    public let link: Color

    /// The color for thematic breaks (horizontal rules).
    public let rule: Color

    /// Creates a markdown theme with the specified colors.
    public init(
        text: Color = .init(0xFF00_0000),
        codeBackground: Color = .init(0xFFF5_F5F5),
        blockQuoteBackground: Color = .init(0xFFF8_F8F8),
        blockQuoteBorder: Color = .init(0xFFE1_E1E1),
        link: Color = .init(0xFF00_66CC),
        rule: Color = .init(0xFFE1_E1E1)
    ) {
        self.text = text
        self.codeBackground = codeBackground
        self.blockQuoteBackground = blockQuoteBackground
        self.blockQuoteBorder = blockQuoteBorder
        self.link = link
        self.rule = rule
    }

    /// A light theme with standard markdown colors.
    public static let light = MarkdownTheme()

    /// A dark theme suitable for dark mode interfaces.
    public static let dark = MarkdownTheme(
        text: .init(0xFFFF_FFFF),
        codeBackground: .init(0xFF2D_2D2D),
        blockQuoteBackground: .init(0xFF1E_1E1E),
        blockQuoteBorder: .init(0xFF44_4444),
        link: .init(0xFF66_B3FF),
        rule: .init(0xFF44_4444)
    )
}

/// Default implementation of MarkdownView.Style providing basic styling.
/// Uses the specified theme for colors and provides sensible defaults for layout.
public struct DefaultMarkdownStyle: MarkdownView.Style {
    public let theme: MarkdownTheme

    /// Creates a default markdown style with the specified theme.
    public init(theme: MarkdownTheme = .light) {
        self.theme = theme
    }

    public func build(children: [Widget]) -> Widget {
        Column(crossAxisAlignment: .stretch) {
            children
        }
    }

    public func buildHeading(level: Int, text: String) -> Widget {
        let fontSize: Float =
            switch level {
            case 1: 32
            case 2: 24
            case 3: 20
            case 4: 18
            case 5: 16
            case 6: 14
            default: 16
            }

        return Padding(.symmetric(vertical: 8)) {
            Text(
                text,
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: .bold
                )
            )
        }
    }

    public func buildParagraph(text: String) -> Widget {
        return Padding(.symmetric(vertical: 4)) {
            Text(text)
        }
    }

    public func buildParagraph(spans: [TextSpan]) -> Widget {
        return Padding(.symmetric(vertical: 4)) {
            RichText(
                text: TextSpan(
                    children: spans,
                    style: .init(color: theme.text, fontSize: 16)
                )
            )
        }
    }

    public func buildParagraph(content: InlineSpan) -> Widget {
        return Padding(.symmetric(vertical: 4)) {
            RichText(text: content)
        }
    }

    public func buildCodeBlock(code: String, language: String?) -> Widget {
        return DecoratedBox(
            decoration: BoxDecoration(
                color: theme.codeBackground,
                borderRadius: BorderRadius.circular(4)
            )
        ) {
            Padding(.all(12)) {
                Text(
                    code,
                    style: TextStyle(fontFamily: "monospace")
                )
            }
        }
    }

    public func buildList(items: [Widget], isOrdered: Bool) -> Widget {
        return Padding(.symmetric(vertical: 4)) {
            Column(crossAxisAlignment: .start) {
                items
            }
        }
    }

    public func buildListItem(content: [Widget], isOrdered: Bool) -> Widget {
        let bullet = isOrdered ? "• " : "• "
        return Padding(.only(left: 16, bottom: 2)) {
            Row(crossAxisAlignment: .start) {
                Text(bullet)
                Expanded {
                    Column(crossAxisAlignment: .stretch) {
                        content
                    }
                }
            }
        }
    }

    public func buildBlockQuote(content: [Widget]) -> Widget {
        return DecoratedBox(
            decoration: BoxDecoration(
                color: theme.blockQuoteBackground,
                border: Border(left: BorderSide(color: theme.blockQuoteBorder, width: 4))
            )
        ) {
            Padding(.all(12)) {
                Column(crossAxisAlignment: .start) {
                    content
                }
            }
        }
    }

    public func buildThematicBreak() -> Widget {
        return Padding(.symmetric(vertical: 8)) {
            HorizontalDivider()
        }
    }

    // Link handling removed from DefaultMarkdownStyle - now handled by MarkdownView.onLinkTap
}

/// The state object for a MarkdownView widget.
/// Handles parsing markdown content and rendering it as Shaft widgets.
public class MarkdownViewState: State<MarkdownView> {

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
        return render(document: document, context: context)
    }

    private func render(document: Document, context: BuildContext) -> Widget {
        let style = DefaultMarkdownStyle()
        var children: [Widget] = []

        for child in document.children {
            if let widget = renderMarkupElement(child, style: style) {
                children.append(widget)
            }
        }

        return style.build(children: children)
    }

    private func renderInlineElements(_ inlineElements: [Markup], style: DefaultMarkdownStyle)
        -> InlineSpan
    {
        var spans: [InlineSpan] = []

        // Seed base style from theme so leaf spans inherit correct defaults.
        var stack = StyleStack(base: TextStyle(color: style.theme.text, fontSize: 16))

        func visit(_ node: Markup, _ recognizer: GestureRecognizer?) {
            switch node {
            case let text as Markdown.Text:
                spans.append(
                    TextSpan(text: text.string, style: stack.current, recognizer: recognizer)
                )

            case let strong as Strong:
                stack.push { current in current.copyWith(fontWeight: .bold) }
                for child in strong.children { visit(child, recognizer) }
                stack.pop()

            case let emphasis as Emphasis:
                stack.push { current in current.copyWith(fontStyle: .italic) }
                for child in emphasis.children { visit(child, recognizer) }
                stack.pop()

            case let inlineCode as InlineCode:
                // Inline code cancels italic/bold and applies monospaced face and code background.
                let codeStyle = stack.current
                    .copyWith(
                        backgroundColor: style.theme.codeBackground,
                        fontFamily: "monospace",
                        fontFamilyFallback: [
                            "SF Mono", "Monaco", "Menlo",  // MacOS monospace
                            "Cascadia Mono", "Consolas",  // Windows monospace
                            "Courier New", "monospace",  // fallback
                        ],
                        fontWeight: .normal,
                        fontStyle: .normal
                    )
                spans.append(
                    TextSpan(text: inlineCode.code, style: codeStyle, recognizer: recognizer)
                )

            case let link as Link:
                // Apply link styling
                stack.pushLinkContext { current in
                    current
                        .copyWith(color: style.theme.link)
                        .withAddedDecoration(.underline)
                }

                // Create a TextSpan with gesture recognizer for the link
                let recognizer = TapGestureRecognizer()
                recognizer.onTap = { [weak self] in
                    guard let destination = link.destination else { return }
                    self?.handleLinkTap(destination: destination)
                }

                var linkChildren: [InlineSpan] = []
                let savedSpans = spans
                spans = []

                // Recursively visit children to preserve formatting within the link
                for child in link.children {
                    visit(child, recognizer)
                }

                linkChildren = spans
                spans = savedSpans
                stack.pop()

                let linkSpan = TextSpan(
                    children: linkChildren,
                    style: TextStyle(color: style.theme.link).withAddedDecoration(.underline),
                    recognizer: recognizer
                )
                spans.append(linkSpan)

            default:
                // Traverse children by default to preserve content order.
                for child in node.children { visit(child, recognizer) }
            }
        }

        for element in inlineElements { visit(element, nil) }

        // Return a single TextSpan containing all the inline content
        return TextSpan(children: spans)
    }

    /// Handles link tap events by delegating to the widget's onLinkTap callback.
    private func handleLinkTap(destination: String) {
        if let onLinkTap = widget.onLinkTap {
            onLinkTap(destination)
        } else {
            let _ = backend.launchUrl(destination)
        }
    }

    private func renderMarkupElement(_ element: Markup, style: DefaultMarkdownStyle) -> Widget? {
        switch element {
        case let heading as Heading:
            return style.buildHeading(level: heading.level, text: heading.plainText)

        case let paragraph as Markdown.Paragraph:
            let content = renderInlineElements(Array(paragraph.children), style: style)
            return style.buildParagraph(content: content)

        case let codeBlock as CodeBlock:
            return style.buildCodeBlock(code: codeBlock.code, language: codeBlock.language)

        case let list as UnorderedList:
            let items = list.children.compactMap { item -> Widget? in
                guard let listItem = item as? ListItem else { return nil }
                let itemContent = listItem.children.compactMap { child in
                    renderMarkupElement(child, style: style)
                }
                return style.buildListItem(content: itemContent, isOrdered: false)
            }
            return style.buildList(items: items, isOrdered: false)

        case let list as OrderedList:
            let items = list.children.compactMap { item -> Widget? in
                guard let listItem = item as? ListItem else { return nil }
                let itemContent = listItem.children.compactMap { child in
                    renderMarkupElement(child, style: style)
                }
                return style.buildListItem(content: itemContent, isOrdered: true)
            }
            return style.buildList(items: items, isOrdered: true)

        case let blockQuote as BlockQuote:
            let quoteContent = blockQuote.children.compactMap { child in
                renderMarkupElement(child, style: style)
            }
            return style.buildBlockQuote(content: quoteContent)

        case is ThematicBreak:
            return style.buildThematicBreak()

        default:
            // Handle unknown or unsupported elements as plain text
            return style.buildParagraph(text: "Unsupported element")
        }
    }
}

extension Widget {
    /// Sets the style for markdown views within this view hierarchy.
    public func markdownViewStyle(_ style: any MarkdownView.Style) -> some Widget {
        Inherited(style) { self }
    }
}
