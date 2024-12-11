import Shaft
import Splash

/// Example:
/// ```swift
/// highlight(
///     """
///     func hello() -> String {
///         return "Hello, World!"
///     }
///     """
/// )
/// ```
public func highlight(_ code: String, theme: Theme = LightTheme()) -> TextSpan {
    let highlighter = SyntaxHighlighter(format: TextSpanOutputFormat(theme: theme))
    return highlighter.highlight(code)
}

private struct TextSpanOutputFormat: OutputFormat {
    let theme: Theme

    func makeBuilder() -> TextSpanOutputBuilder {
        TextSpanOutputBuilder(theme: theme)
    }

    struct TextSpanOutputBuilder: OutputBuilder {
        init(theme: Theme) {
            self.theme = theme
        }

        typealias Output = TextSpan

        let theme: Theme

        private var spans: [TextSpan] = []

        private let fontFamily = [
            "SF Mono", "Monaco", "Menlo",  // MacOS monospace
            "Cascadia Mono", "Consolas", // Windows monospace
            "Courier New", "monospace",  // fallback
        ]

        mutating func addToken(_ token: String, ofType type: Splash.TokenType) {
            spans.append(
                TextSpan(
                    text: token,
                    style: theme.getTokenStyle(type)
                        .copyWith(fontFamilyFallback: fontFamily)
                )
            )
        }

        mutating func addPlainText(_ text: String) {
            spans.append(TextSpan(text: text))
        }

        mutating func addWhitespace(_ whitespace: String) {
            spans.append(TextSpan(text: whitespace))
        }

        mutating func build() -> Shaft.TextSpan {
            return TextSpan(
                children: spans,
                style: theme.getTextStyle().copyWith(
                    fontFamilyFallback: fontFamily
                )
            )
        }
    }
}

public protocol Theme {
    func getTextStyle() -> TextStyle

    func getTokenStyle(_ type: Splash.TokenType) -> TextStyle
}

public struct DarkTheme: Theme {
    public init() {}

    public func getTextStyle() -> TextStyle {
        TextStyle(color: .init(0xFF_FFFFFF))
    }

    public func getTokenStyle(_ type: Splash.TokenType) -> TextStyle {
        return switch type {
        case .keyword:
            TextStyle(color: .init(0xFF_e73289))
        case .type:
            TextStyle(color: .init(0xFF_8281ca))
        case .call:
            TextStyle(color: .init(0xFF_348fe5))
        case .property:
            TextStyle(color: .init(0xFF_21ab9d))
        case .number:
            TextStyle(color: .init(0xFF_db6f57))
        case .string:
            TextStyle(color: .init(0xFF_fa641e))
        case .comment:
            TextStyle(color: .init(0xFF_6b8a94))
        case .dotAccess:
            TextStyle(color: .init(0xFF_92b300))
        case .preprocessing:
            TextStyle(color: .init(0xFF_b68a00))
        default:
            TextStyle(color: .init(0xFF_000000))
        }
    }
}

public struct LightTheme: Theme {
    public init() {}

    public func getTextStyle() -> TextStyle {
        TextStyle(color: .init(0xFF_000000))
    }

    public func getTokenStyle(_ type: Splash.TokenType) -> TextStyle {
        return switch type {
        case .keyword:
            TextStyle(color: .init(0xFF_b41f62))
        case .type:
            TextStyle(color: .init(0xFF_703daa))
        case .call:
            TextStyle(color: .init(0xFF_448a93))
        case .property:
            TextStyle(color: .init(0xFF_448a93))
        case .number:
            TextStyle(color: .init(0xFF_002bff))
        case .string:
            TextStyle(color: .init(0xFF_d12f1b))
        case .comment:
            TextStyle(color: .init(0xFF_56606b))
        case .dotAccess:
            TextStyle(color: .init(0xFF_448a93))
        case .preprocessing:
            TextStyle(color: .init(0xFF_6e2014))
        default:
            TextStyle(color: .init(0xFF_000000))
        }
    }
}
