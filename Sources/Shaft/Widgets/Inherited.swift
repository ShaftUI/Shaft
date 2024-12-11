public final class Inherited<T>: InheritedWidget {
    public init(
        _ value: T,
        @WidgetBuilder child: () -> Widget
    ) {
        self.value = value
        self.child = child()
    }

    /// The style for buttons within this view.
    public let value: T

    public let child: any Widget

    public static func valueOf(_ context: BuildContext) -> T? {
        maybeOf(context)?.value
    }

    public func updateShouldNotify(_ oldWidget: Inherited) -> Bool {
        compare(value, oldWidget.value) == false
    }

    private func compare<T1, T2>(_ a: T1, _ b: T2) -> Bool {
        if let a = a as? (any Equatable), let b = b as? (any Equatable) {
            return isEqual(a, b)
        } else {
            return false
        }
    }
}
