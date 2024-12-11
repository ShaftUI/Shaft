/// A stateless widget that represents a section with a header, content, and
/// optional footer. The section's appearance is determined by the provided
/// `Section.Style`.
public final class Section: StatelessWidget, SectionStyleContext {
    public init(
        @OptionalWidgetBuilder header: () -> Widget? = voidBuilder,
        @OptionalWidgetBuilder footer: () -> Widget? = voidBuilder,
        @WidgetListBuilder content: () -> [Widget]
    ) {
        self.header = header()
        self.content = content()
        self.footer = footer()
    }

    public let header: Widget?

    public let content: [Widget]

    public let footer: Widget?

    public func build(context: BuildContext) -> Widget {
        let style: any Section.Style = Inherited.valueOf(context) ?? .default
        return style.build(context: self)
    }

    /// A protocol that defines the appearance of a `Section` widget.
    /// Implementations of this protocol are responsible for building the header,
    /// content, and optional footer of the section.
    public protocol Style {
        func build(context: Context) -> Widget

        typealias Context = SectionStyleContext
    }
}

public protocol SectionStyleContext {
    /// A widget to use as the section’s header.

    var header: Widget? { get }
    /// The section’s content.
    var content: [Widget] { get }

    /// A widget to use as the section’s footer.
    var footer: Widget? { get }
}

extension Widget {
    public func sectionStyle(_ style: any Section.Style) -> some Widget {
        Inherited(style) { self }
    }
}

/// The built-in style for `Section` widgets that simply displays the header,
/// content, and footer in a column.
public struct DefaultSectionStyle: Section.Style {
    public init() {}

    public func build(context: SectionStyleContext) -> Widget {
        Column(crossAxisAlignment: .start) {
            if let header = context.header {
                header
            }

            context.content

            if let footer = context.footer {
                footer
            }
        }
    }
}

extension Section.Style where Self == DefaultSectionStyle {
    /// The default style for `Section` widgets.
    public static var `default`: DefaultSectionStyle {
        DefaultSectionStyle()
    }
}
