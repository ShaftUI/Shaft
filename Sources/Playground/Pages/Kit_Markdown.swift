import Shaft
import ShaftMarkdown

final class Kit_Markdown: StatefulWidget {
    func createState() -> some State<Kit_Markdown> {
        Kit_MarkdownState()
    }
}

final class Kit_MarkdownState: State<Kit_Markdown> {
    private var selectedMarkdown = 0
    private var linkTapped: String? = nil
    private var useCompactTheme = false

    private let markdownSamples = [
        """
        # Welcome to *Markdown*

        This is a **comprehensive** demonstration of *markdown* rendering in `Shaft`.

        ## Features

        - **Bold text** and *italic text*
        - `Inline code` with monospace font
        - [Interactive links](https://github.com/ShaftUI/Shaft)
        - Lists and quotes

        ### Code Blocks

        ```swift
        let markdown = MarkdownView("# Hello World\\nThis is **markdown**!")
        ```

        > This is a blockquote with some **bold** text and a [link](https://example.com).
        > 
        > It can span multiple lines and contain other markdown elements.

        ---

        1. First ordered item
        2. Second ordered item
           - Nested unordered item
           - Another nested item
        3. Third ordered item

        That's all for now!
        """,

        """
        # Typography Showcase

        ## Heading Level 2
        ### Heading Level 3
        #### Heading Level 4
        ##### Heading Level 5
        ###### Heading Level 6

        Regular paragraph text with **bold**, *italic*, and `code` elements.

        Here's a [link to Shaft](https://github.com/ShaftUI/Shaft) and another [broken link](invalid://example).

        ## Lists

        ### Unordered List
        - First item
        - Second item with **bold text**
        - Third item with *italic text*
        - Fourth item with `inline code`

        ### Ordered List
        1. Learn Shaft basics
        2. Build your first app
        3. Add markdown support
        4. Deploy to production

        ## Code Examples

        ```swift
        // Simple markdown usage
        MarkdownView("# Hello **World**!")

        // With custom theme
        MarkdownView(
            "Your *markdown* here",
            theme: MarkdownTheme(
                heading1: TextStyle(fontSize: 28, fontWeight: .bold)
            )
        )
        ```

        > **Note:** This markdown renderer supports most common markdown elements with beautiful styling.
        """,

        """
        # Interactive Demo

        Click on any [link](https://shaft-ui.dev) to see the link handler in action!

        ## Various Links

        - [Shaft Repository](https://github.com/ShaftUI/Shaft)
        - [Swift.org](https://swift.org)
        - [Apple Developer](https://developer.apple.com)
        - [Invalid Link](invalid://test)

        ## Mixed Content

        This paragraph contains **bold text**, *italic text*, `inline code`, and a [link](https://example.com) all together.

        ```json
        {
          "framework": "Shaft",
          "language": "Swift",
          "features": ["Cross-platform", "Native performance", "Hot reload"]
        }
        ```

        ### Task List Style

        1. ✅ Implement basic markdown rendering
        2. ✅ Add styling and themes
        3. ✅ Support interactive links
        4. 🚧 Add table support
        5. 📋 Add image support

        ---

        *Happy coding with Shaft!* 🚀
        """,
    ]

    private let sampleTitles = [
        "Basic Demo",
        "Typography",
        "Interactive",
    ]

    override func build(context: BuildContext) -> Widget {
        return PageContent {
            Text("Markdown")
                .textStyle(.playgroundTitle)

            Text("Rich text rendering with markdown syntax.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                Shaft includes a powerful markdown rendering system that supports \
                headings, text formatting, links, lists, code blocks, and more. \
                The renderer is highly customizable with themes and link handling.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                import ShaftMarkdown

                MarkdownView(\"\"\"
                    # Hello World
                    This is **bold** and *italic* text.
                    [Visit Shaft](https://shaft-ui.dev)
                \"\"\")
                """
            )

            // MARK: - Sample Selector

            Text("Sample")
                .textStyle(.playgroundHeading)

            Row(spacing: 8) {
                Button {
                    self.selectedMarkdown = 0
                    self.setState {}
                } child: {
                    Text("Basic Demo")
                }
                Button {
                    self.selectedMarkdown = 1
                    self.setState {}
                } child: {
                    Text("Typography")
                }
                Button {
                    self.selectedMarkdown = 2
                    self.setState {}
                } child: {
                    Text("Interactive")
                }
            }

            // MARK: - Theme Selector

            Text("Theme")
                .textStyle(.playgroundHeading)

            Row(spacing: 8) {
                Button {
                    self.useCompactTheme = false
                    self.setState {}
                } child: {
                    Text("Default")
                }
                Button {
                    self.useCompactTheme = true
                    self.setState {}
                } child: {
                    Text("Compact")
                }
            }

            // MARK: - Link Status

            if let linkTapped = linkTapped {
                DecoratedBox(
                    decoration: BoxDecoration(
                        color: Color(0x1A00_7AFF),
                        borderRadius: BorderRadius.circular(8)
                    )
                ) {
                    Padding(.all(12)) {
                        Row {
                            Text("🔗 Link tapped: \(linkTapped)")
                                .textStyle(.callout)

                            SizedBox(width: 16)

                            Button {
                                self.linkTapped = nil
                                self.setState {}
                            } child: {
                                Text("Clear")
                            }
                        }
                    }
                }
            }

            // MARK: - Markdown Demo

            Text("Live Preview")
                .textStyle(.playgroundHeading)

            DecoratedBox(
                decoration: BoxDecoration(
                    color: Color(0xFFF8_F9FA),
                    border: Border.all(color: Color(0xFFE1_E4E8)),
                    borderRadius: BorderRadius.circular(8)
                )
            ) {
                SizedBox(height: 400) {
                    SingleChildScrollView(padding: .all(16)) {
                        MarkdownView(
                            markdownSamples[selectedMarkdown],
                            theme: useCompactTheme ? .compact : .default,
                            onLinkTap: { url in
                                self.linkTapped = url
                                self.setState {}
                            }
                        )
                    }
                }
            }

            // MARK: - Customization

            Text("Customization")
                .textStyle(.playgroundHeading)

            Text(
                """
                The markdown renderer supports custom themes, link handlers, \
                and styling. You can customize colors, fonts, spacing, and more. \
                Built-in themes include `.default` and `.compact` (smaller headings).
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                // Use built-in themes
                MarkdownView(content, theme: .default)
                MarkdownView(content, theme: .compact)
                
                // Create custom theme
                let customTheme = MarkdownTheme(
                    heading1: TextStyle(fontSize: 20, fontWeight: .bold, color: .purple),
                    emphasis: TextStyle(fontStyle: .italic, color: .blue),
                    strong: TextStyle(fontWeight: .bold, color: .red),
                    link: TextStyle(color: .green, decoration: .underline)
                )

                MarkdownView(
                    myMarkdown,
                    theme: customTheme,
                    onLinkTap: { url in
                        print("User tapped: \\(url)")
                    }
                )
                """
            )
        }
    }
}
