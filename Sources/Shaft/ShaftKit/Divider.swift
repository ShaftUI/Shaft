public final class HorizontalDivider: StatelessWidget {
    public init(padding: EdgeInsetsGeometry = EdgeInsets.zero) {
        self.padding = padding
    }

    public let padding: EdgeInsetsGeometry

    public func build(context: BuildContext) -> Widget {
        let style: any DividerStyle = Inherited.valueOf(context) ?? .default
        return style.build(
            context: .init(
                child: SizedBox(width: .infinity, height: 1)
            )
        )
        .padding(padding)
        .horizontalExpand()
    }
}

public final class VerticalDivider: StatelessWidget {
    public init(padding: EdgeInsetsGeometry = EdgeInsets.zero) {
        self.padding = padding
    }

    public let padding: EdgeInsetsGeometry

    public func build(context: BuildContext) -> Widget {
        let style: any DividerStyle = Inherited.valueOf(context) ?? .default
        return style.build(
            context: .init(
                child: SizedBox(width: 1, height: .infinity)
            )
        )
        .padding(padding)
        .verticalExpand()
    }
}

public protocol DividerStyle {
    func build(context: DividerStyleContext) -> Widget
}

public struct DividerStyleContext {
    public let child: Widget
}

extension Widget {
    public func dividerStyle(_ style: DividerStyle) -> Widget {
        Inherited(style) { self }
    }
}

public struct DefaultDividerStyle: DividerStyle {
    public func build(context: DividerStyleContext) -> Widget {
        context.child
            .decoration(.box(color: .init(0xFF_E0E0E0)))
    }
}

extension DividerStyle where Self == DefaultDividerStyle {
    public static var `default`: DefaultDividerStyle {
        DefaultDividerStyle()
    }
}
