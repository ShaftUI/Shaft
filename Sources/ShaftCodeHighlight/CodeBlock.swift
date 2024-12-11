import Shaft

/// A widget that displays a block of code with syntax highlighting.
public final class CodeBlock: StatelessWidget {
    public init(code: String) {
        self.code = code
    }

    public let code: String

    public func build(context: any BuildContext) -> any Widget {
        let text = RichText(
            text: highlight(code),
            textAlign: .start,
            softWrap: true,
            overflow: .clip,
            textScaler: .noScaling,
            textWidthBasis: .longestLine
        )

        let style: Style = Inherited.valueOf(context) ?? .default

        return style.build(context: .init(child: text))
    }

    public protocol Style {
        func build(context: StyleContext) -> Widget
    }

    public struct StyleContext {
        public let child: Widget
    }
}

extension Widget {
    public func codeBlockStyle(_ style: CodeBlock.Style) -> some Widget {
        Inherited(style) { self }
    }
}

public struct DefaultCodeBlockStyle: CodeBlock.Style {
    public func build(context: CodeBlock.StyleContext) -> Widget {
        context.child
            .padding(.all(20))
            .decoration(.box(color: .init(0xFF_F5F5F5), borderRadius: .circular(16.0)))
    }
}

extension CodeBlock.Style where Self == DefaultCodeBlockStyle {
    public static var `default`: DefaultCodeBlockStyle { DefaultCodeBlockStyle() }
}
