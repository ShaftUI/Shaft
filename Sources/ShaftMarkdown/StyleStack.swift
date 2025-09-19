import Shaft

/// Internal style stack used by Markdown inline rendering to support inheritance.
/// Applies style transformations on push and restores on pop.
struct StyleStack {
    private var stack: [TextStyle]
    private var linkContextStack: [Bool] = [false]

    init(base: TextStyle) {
        self.stack = [base]
    }

    var current: TextStyle { stack.last! }
    var isInLinkContext: Bool { linkContextStack.last! }

    mutating func push(_ transform: (TextStyle) -> TextStyle) {
        let next = transform(current)
        stack.append(next)
        linkContextStack.append(linkContextStack.last!)
    }

    mutating func push(merge other: TextStyle) {
        // Default merge semantics: other inherits from current when inherit=true.
        stack.append(current.merge(other))
        linkContextStack.append(linkContextStack.last!)
    }

    mutating func pushLinkContext(_ transform: (TextStyle) -> TextStyle) {
        let next = transform(current)
        stack.append(next)
        linkContextStack.append(true)
    }

    mutating func pop() {
        _ = stack.popLast()
        _ = linkContextStack.popLast()
        assert(!stack.isEmpty, "StyleStack underflow: popped base style")
        assert(!linkContextStack.isEmpty, "LinkContextStack underflow")
    }
}

extension TextStyle {
    /// Returns a copy with decorations additively merged with existing ones.
    func withAddedDecoration(_ added: TextDecoration?) -> TextStyle {
        guard let added else { return self }
        let combined: TextDecoration = {
            if let existing = self.decoration {
                return TextDecoration(rawValue: existing.rawValue | added.rawValue)
            }
            return added
        }()
        return copyWith(decoration: combined)
    }
}
