/// A scrollable, linear list of widgets.
public final class FixedListView: StatefulWidget {
    public init(
        @WidgetListBuilder children: () -> [Widget]
    ) {
        self.children = children()
        self.selectionDelegate = nil
    }

    public init<T: Hashable>(
        selection: ValueNotifier<T>? = nil,
        @WidgetListBuilder children: () -> [Widget]
    ) {
        if let selection = selection {
            self.selectionDelegate = SingleValueNotifierSelectionDelegate(selection: selection)
        } else {
            self.selectionDelegate = nil
        }
        self.children = children()
    }

    public init<T: Hashable>(
        selection: ValueNotifier<T?>? = nil,
        @WidgetListBuilder children: () -> [Widget]
    ) {
        if let selection = selection {
            self.selectionDelegate = OptionalValueNotifierSelectionDelegate(selection: selection)
        } else {
            self.selectionDelegate = nil
        }
        self.children = children()
    }

    public init<T: Hashable>(
        selection: ValueNotifier<Set<T>>? = nil,
        @WidgetListBuilder children: () -> [Widget]
    ) {
        if let selection = selection {
            self.selectionDelegate = ListValueNotifierSelectionDelegate<T>(selection: selection)
        } else {
            self.selectionDelegate = nil
        }
        self.children = children()
    }

    public let children: [Widget]

    public let selectionDelegate: (any ListSelectionDelegate)?

    public func createState() -> some State<FixedListView> {
        FixedListViewState()
    }
}

private class FixedListViewState: State<FixedListView>,
    FixedListViewStyleContext
{
    public var children: [Widget] {
        widget.children
    }

    public override func build(context: any BuildContext) -> any Widget {
        let style: any FixedListViewStyle = Inherited.valueOf(context) ?? .default
        return ListSelectionScope(selection: widget.selectionDelegate) {
            style.build(context: self)
        }
    }
}

public protocol ListSelectionDelegate<T>: AnyObject {
    associatedtype T: Hashable

    func addSelection(_ item: T)

    func removeSelection(_ item: T)

    func setSelection(_ items: [T])

    func isInSelection(_ item: T) -> Bool
}

public class SingleValueNotifierSelectionDelegate<T: Hashable>: ListSelectionDelegate {
    init(selection: ValueNotifier<T>) {
        self.selection = selection
    }

    let selection: ValueNotifier<T>

    public func addSelection(_ item: T) {
        selection.value = item
    }

    public func removeSelection(_ item: T) {
    }

    public func setSelection(_ items: [T]) {
        if let item = items.first {
            selection.value = item
        }
    }

    public func isInSelection(_ item: T) -> Bool {
        selection.value == item
    }
}

public class OptionalValueNotifierSelectionDelegate<T: Hashable>: ListSelectionDelegate {
    init(selection: ValueNotifier<T?>) {
        self.selection = selection
    }

    let selection: ValueNotifier<T?>

    public func addSelection(_ item: T) {
        selection.value = item
    }

    public func removeSelection(_ item: T) {
        selection.value = nil
    }

    public func setSelection(_ items: [T]) {
        selection.value = items.first
    }

    public func isInSelection(_ item: T) -> Bool {
        selection.value == item
    }
}

public class ListValueNotifierSelectionDelegate<T: Hashable>: ListSelectionDelegate {
    init(selection: ValueNotifier<Set<T>>) {
        self.selection = selection
    }

    let selection: ValueNotifier<Set<T>>

    public func addSelection(_ item: T) {
        selection.value.insert(item)
    }

    public func removeSelection(_ item: T) {
        selection.value.remove(item)
    }

    public func setSelection(_ items: [T]) {
        selection.value = Set(items)
    }

    public func isInSelection(_ item: T) -> Bool {
        selection.value.contains(item)
    }
}

public class ListSelectionScope: InheritedWidget {
    public init(
        selection: (any ListSelectionDelegate)? = nil,
        @WidgetBuilder child: () -> Widget
    ) {
        self.selection = selection
        self.child = child()
    }

    public let selection: (any ListSelectionDelegate)?

    public let child: Widget

    public func build(context: BuildContext) -> Widget {
        child
    }

    public func updateShouldNotify(_ oldWidget: ListSelectionScope) -> Bool {
        selection !== oldWidget.selection
    }
}

public protocol FixedListViewStyle: Equatable {
    func build(context: Context) -> Widget

    typealias Context = FixedListViewStyleContext
}

public protocol FixedListViewStyleContext {
    var children: [Widget] { get }
}

extension Widget {
    public func fixedListViewStyle(_ style: any FixedListViewStyle) -> some Widget {
        Inherited(style) { self }
    }
}

/// The default style implementation for `FixedListView`.
///
/// This style renders the list children in a vertical `Column` without any
/// additional decoration.
public struct DefaultFixedListViewStyle: FixedListViewStyle {
    public init() {}

    public func build(context: Context) -> Widget {
        return Column {
            context.children
        }
    }
}

extension FixedListViewStyle where Self == DefaultFixedListViewStyle {
    /// Returns the default implementation of `FixedListViewStyle`.
    public static var `default`: DefaultFixedListViewStyle {
        DefaultFixedListViewStyle()
    }
}
