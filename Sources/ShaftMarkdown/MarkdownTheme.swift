import Shaft

public struct MarkdownTheme {
    // Heading styles
    public let heading1: TextStyle
    public let heading2: TextStyle
    public let heading3: TextStyle
    public let heading4: TextStyle
    public let heading5: TextStyle
    public let heading6: TextStyle

    // Inline text styles
    public let emphasis: TextStyle
    public let strong: TextStyle
    public let code: TextStyle
    public let link: TextStyle
    public let linkHover: TextStyle

    // Block element colors and styling
    public let codeBlockBackground: Color
    public let codeBlockBorder: Color
    public let blockQuoteBackground: Color
    public let blockQuoteBorder: Color
    public let thematicBreakColor: Color
    public let listBulletColor: Color

    public init(
        heading1: TextStyle = .init(fontSize: 32, fontWeight: .bold),
        heading2: TextStyle = .init(fontSize: 24, fontWeight: .bold),
        heading3: TextStyle = .init(fontSize: 20, fontWeight: .bold),
        heading4: TextStyle = .init(fontSize: 18, fontWeight: .bold),
        heading5: TextStyle = .init(fontSize: 16, fontWeight: .bold),
        heading6: TextStyle = .init(fontSize: 14, fontWeight: .bold),
        emphasis: TextStyle = .init(fontStyle: .italic),
        strong: TextStyle = .init(fontWeight: .bold),
        code: TextStyle = .init(
            fontFamily: "monospace",
            fontFamilyFallback: [
                "SF Mono", "Monaco", "Menlo",  // MacOS monospace
                "Cascadia Mono", "Consolas",  // Windows monospace
                "Courier New", "monospace",  // fallback
            ]
        ),
        link: TextStyle = .init(color: Color(0xFF00_7AFF), decoration: .underline),
        linkHover: TextStyle = .init(color: Color(0xFF00_51D5), decoration: .underline),
        codeBlockBackground: Color = Color(0xFFF6_F8FA),
        codeBlockBorder: Color = Color(0xFFE1_E4E8),
        blockQuoteBackground: Color = Color(0xFFF6_F8FA),
        blockQuoteBorder: Color = Color(0xFFDF_E2E5),
        thematicBreakColor: Color = Color(0xFFE1_E4E8),
        listBulletColor: Color = Color(0xFF58_6069)
    ) {
        self.heading1 = heading1
        self.heading2 = heading2
        self.heading3 = heading3
        self.heading4 = heading4
        self.heading5 = heading5
        self.heading6 = heading6
        self.emphasis = emphasis
        self.strong = strong
        self.code = code
        self.link = link
        self.linkHover = linkHover
        self.codeBlockBackground = codeBlockBackground
        self.codeBlockBorder = codeBlockBorder
        self.blockQuoteBackground = blockQuoteBackground
        self.blockQuoteBorder = blockQuoteBorder
        self.thematicBreakColor = thematicBreakColor
        self.listBulletColor = listBulletColor
    }

    public static var `default`: MarkdownTheme {
        MarkdownTheme()
    }

    public static var compact: MarkdownTheme {
        MarkdownTheme(
            heading1: .init(fontSize: 20, fontWeight: .bold),
            heading2: .init(fontSize: 18, fontWeight: .bold),
            heading3: .init(fontSize: 16, fontWeight: .bold),
            heading4: .init(fontSize: 15, fontWeight: .bold),
            heading5: .init(fontSize: 14, fontWeight: .bold),
            heading6: .init(fontSize: 13, fontWeight: .bold)
        )
    }

    public func heading(level: Int) -> TextStyle {
        switch level {
        case 1: return heading1
        case 2: return heading2
        case 3: return heading3
        case 4: return heading4
        case 5: return heading5
        case 6: return heading6
        default: return heading6
        }
    }
}
