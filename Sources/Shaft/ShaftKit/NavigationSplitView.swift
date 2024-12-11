/// A view that presents views in two or three columns, where selections in
/// leading columns control presentations in subsequent columns.
public final class NavigationSplitView: StatelessWidget, NavigationSplitViewStyleContext {
    public init(
        @WidgetBuilder sidebar: () -> Widget,
        @WidgetBuilder detail: () -> Widget
    ) {
        self.sidebar = sidebar()
        self.detail = detail()
    }

    public let sidebar: any Widget

    public let detail: any Widget

    public func build(context: any BuildContext) -> any Widget {
        let style: any NavigationSplitView.Style = Inherited.valueOf(context) ?? .default
        return style.build(context: self)
    }

    /// A type that applies custom interaction behavior and a custom appearance to
    /// ``NavigationSplitView`` instances within a view hierarchy.
    public protocol Style: Equatable {
        /// Creates a widget that represents the body of a button.
        func build(context: Self.Context) -> Widget

        typealias Context = NavigationSplitViewStyleContext
    }

}

/// The properties necessary to build a ``NavigationSplitView``.
public protocol NavigationSplitViewStyleContext {
    /// The view to show in the leading column.
    var sidebar: Widget { get }

    /// The view to show in the detail column.
    var detail: Widget { get }
}

extension Widget {
    /// Sets the style for ``NavigationSplitView``s within this view.
    public func navigationSplitViewStyle(_ style: any NavigationSplitView.Style) -> some Widget {
        Inherited(style) { self }
    }
}

/// The built-in style for ``NavigationSplitView``s that displays the sidebar
/// and detail views in a row.
public struct DefaultNavigationSplitViewStyle: NavigationSplitView.Style {
    public init() {}

    public func build(context: NavigationSplitViewStyleContext) -> Widget {
        Resizable {
            SingleChildScrollView {
                context.sidebar
                    .listTileStyle(ListTileStyle())
                    .sectionStyle(SectionStyle())
                    .padding(.all(10))
            }
            .background(Color(0xFF_F5F5F5))
        } right: {
            Background {
                context.detail
            }
        }
    }

    struct ListTileStyle: Shaft.ListTileStyle {
        func build(context: ListTileStyleContext) -> Widget {
            let color =
                context.isSelected || context.isHovered
                ? Color(0xFF_E8E8E8)
                : Color(0x00)

            let textStyle =
                context.isSelected
                ? TextStyle(color: Color(0xFF_090909), fontSize: 14, fontWeight: .w500)
                : TextStyle(color: Color(0xFF_090909), fontSize: 14)

            return Row {
                context.children
            }
            .padding(.all(8))
            .decoration(.box(color: color, borderRadius: .all(.circular(5))))
            .textStyle(textStyle)
        }
    }

    struct SectionStyle: Section.Style {
        func build(context: SectionStyleContext) -> Widget {
            Column(crossAxisAlignment: .start) {
                if let header = context.header {
                    header
                        .padding(.ltrb(8, 8, 8, 12))
                        .textStyle(
                            .init(
                                color: .init(0xFF_090909),
                                fontSize: 14,
                                fontWeight: .w700
                            )
                        )
                }

                context.content

                if let footer = context.footer {
                    footer
                        .padding(.all(8))
                }
            }
            .padding(.only(bottom: 16))
        }
    }
}

extension NavigationSplitView.Style where Self == DefaultNavigationSplitViewStyle {
    /// The built-in style for ``NavigationSplitView``s.
    public static var `default`: DefaultNavigationSplitViewStyle {
        DefaultNavigationSplitViewStyle()
    }
}
