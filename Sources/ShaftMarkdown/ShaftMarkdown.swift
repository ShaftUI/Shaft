import Markdown
import Shaft

public struct MarkdownView: StatefulWidget {
    public init() {}

    public enum Content {
        case text(String)
        case document(Document)
    }

    public var content: Content

    public init(content: Content) {
        self.content = content
    }

    public init(text: String) {
        self.content = .text(text)
    }

    public init(document: Document) {
        self.content = .document(document)
    }

    public func createState() -> State<MarkdownView> {
        return MarkdownViewState()
    }
}

public class MarkdownViewState: State<MarkdownView> {

    private func resolveDocument() -> Document {
        switch widget.content {
        case .text(let text):
            return Document(parsing: text)
        case .document(let document):
            return document
        }
    }

    public func build(context: Context) -> Widget {
    }
}
