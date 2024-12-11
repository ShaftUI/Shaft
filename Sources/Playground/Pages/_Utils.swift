import Shaft
import ShaftCodeHighlight

final class PageContent: StatelessWidget {
    init(@WidgetListBuilder content: () -> [Widget]) {
        self.content = content()
    }

    let content: [Widget]

    func build(context: BuildContext) -> Widget {
        SingleChildScrollView {
            Column(crossAxisAlignment: .start, spacing: 16) {
                content
            }
            .textStyle(.init(height: 1.5))
            .padding(.all(20))
        }

    }
}

final class CodeSection: StatelessWidget {
    init(_ code: String) {
        self.code = code
    }

    let code: String

    func build(context: BuildContext) -> Widget {
        SingleChildScrollView(scrollDirection: .horizontal) {
            CodeBlock(code: code)
        }
        .codeBlockStyle(CodeBlockStyle())
        .decoration(.box(color: .init(0xFF_F5F5F5), borderRadius: .circular(16.0)))
        .horizontalExpand()
    }
}

private struct CodeBlockStyle: CodeBlock.Style {
    func build(context: CodeBlock.StyleContext) -> Widget {
        context.child
            .padding(.all(20))
    }
}

extension TextStyle {
    static var playgroundTitle: TextStyle {
        .init(
            fontSize: 40,
            fontWeight: .w700,
            letterSpacing: -0.3
        )
    }

    static var playgroundAbstract: TextStyle {
        .init(
            fontSize: 21,
            fontWeight: .w500,
            letterSpacing: 0.2
        )
    }

    static var playgroundHeading: TextStyle {
        .init(
            fontSize: 32,
            fontWeight: .w600,
            letterSpacing: 0.1
        )
    }

    static var playgroundBody: TextStyle {
        .init(
            fontSize: 17,
            fontWeight: .w400,
            letterSpacing: -0.3,
            height: 1.5
        )
    }
}
