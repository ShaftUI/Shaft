import Shaft

final class Concept_ShaftKit: StatefulWidget {
    func createState() -> some State<Concept_ShaftKit> {
        Concept_ShaftKitState()
    }
}

final class Concept_ShaftKitState: State<Concept_ShaftKit> {
    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("ShaftKit")
                .textStyle(.playgroundTitle)

            Text("ShaffKit is the built-in widget library for Shaft.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                The Shaft framework and ShaftKit provide different types of \
                widgets to build user interfaces. The Shaft framework includes \
                basic building blocks like Row, Column, BoxDecoration, \
                and Text, while ShaftKit provides widgets with semantics like \
                Button, Slider, and TextField.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                Column {                            // From Shaft framework
                    SizedBox(height: 20) {          // From Shaft framework
                        Text("Hello, ShaftKit!")    // From Shaft framework
                    }
                    Button { } child: {             // From ShaftKit
                        Text("Click me")
                    }
                }
                .textStyle(.init(...))              // From Shaft framework
                .buttonStyle(.default)              // From ShaftKit
                """
            )

            Text(
                """
                What sets ShaftKit apart is its powerful customization system. Every widget \
                in ShaftKit follows a clear two-part architecture: the widget component and \
                its style definition. The widget component, like Button, defines the core \
                functionality and behavior. The style component, such as Button.Style, \
                completely controls the visual appearance and interactive behaviors, enabling \
                unlimited customization possibilities.
                """
            )

            CodeSection(
                """
                Column {
                    Button { } child: { 
                        Text("Click me")
                    }
                }
                .buttonStyle(.default)
                """
            )

            Column {
                Button {
                } child: {
                    Text("Click me")
                }
            }
            .buttonStyle(.default)

            Text(
                """
                ShaftKit widgets are designed with a clear separation of concerns. Each widget \
                implements only the core functionality specific to its type. For instance, \
                a Button widget handles essential interactions like clicks and focus management, \
                while remaining visually neutral. The widget's appearance and styling are \
                determined by the closest Button.Style in the widget tree, enabling \
                flexible and contextual styling.
                """
            )

            CodeSection(
                """
                struct RedButtonStyle: Button.Style {
                    func build(context: any Context) -> any Widget {
                        context.child
                            .padding(.all(8.0))
                            .decoration(.box(color: .argb(255, 255, 69, 58), borderRadius: .all(.circular(8.0))))
                    }
                }

                struct BlueLongButtonStyle: Button.Style {
                    func build(context: any Context) -> any Widget {
                        context.child
                            .padding(.symmetric(vertical: 8.0, horizontal: 32.0))
                            .decoration(.box(color: .argb(255, 53, 199, 89), borderRadius: .all(.circular(4.0))))
                    }
                }
                """
            )

            Text(
                """
                The code above shows two custom Button styles. The RedButtonStyle \
                and BlueLongButtonStyle. To apply a style to a sub-tree of widgets, \
                use the convenience method .buttonStyle(_:):
                """
            )

            CodeSection(
                """
                Button { } child: {
                    Text("Button 1")
                }
                .buttonStyle(RedButtonStyle())

                Button { } child: {
                    Text("Button 2")
                }
                .buttonStyle(BlueLongButtonStyle())
                """
            )

            Button {
            } child: {
                Text("Button 1")
            }
            .buttonStyle(RedButtonStyle())

            Button {
            } child: {
                Text("Button 2")
            }
            .buttonStyle(BlueLongButtonStyle())

            Text(
                """
                What makes this style inheritance system powerful is its ability to dynamically \
                adapt a widget's appearance based on its context in the widget tree, while \
                maintaining a consistent widget type and behavior:
                """
            )

            CodeSection(
                """
                class ButtonRow: StatelessWidget {
                    init(@WidgetListBuilder children: () -> [Widget]) {
                        self.children = children()
                    }

                    let children: [Widget]

                    func build(context: BuildContext) -> Widget {
                        Row(spacing: 1) {
                            for (index, child) in children.enumerated() {
                                child
                                    .buttonStyle(
                                        ButtonStyle(
                                            isFirst: index == 0,
                                            isLast: index == children.count - 1
                                        )
                                    )
                            }
                        }
                    }

                    struct ButtonStyle: Button.Style {
                        let isFirst: Bool
                        let isLast: Bool

                        var borderRadius: BorderRadius {
                            BorderRadius(
                                topLeft: isFirst ? .circular(8.0) : .zero,
                                topRight: isLast ? .circular(8.0) : .zero,
                                bottomLeft: isFirst ? .circular(8.0) : .zero,
                                bottomRight: isLast ? .circular(8.0) : .zero
                            )
                        }

                        func build(context: any Context) -> any Widget {
                            return context.child
                                .padding(.symmetric(vertical: 4.0, horizontal: 8.0))
                                .textStyle(.init(color: .init(0xFF_FFFFFF)))
                                .decoration(
                                    .box(color: .argb(255, 0, 122, 255), borderRadius: borderRadius)
                                )
                        }
                    }
                }
                """
            )

            Text(
                """
                In this example, ButtonRow is a custom widget that creates a unified row \
                of connected buttons. Each button's visual style adapts dynamically based on its \
                position - whether it's first, middle, or last in the row. While ButtonRow acts \
                as a layout container, the individual buttons receive their unique styling through \
                the ButtonStyle system, creating a seamless segmented control appearance:
                """
            )

            CodeSection(
                """
                ButtonRow {
                    Button { } child: {
                        Text("First")
                    }

                    Button { } child: {
                        Text("Middle")
                    }

                    Button { } child: {
                        Text("Last")
                    }
                }
                """
            )

            ButtonRow {
                Button {
                } child: {
                    Text("First")
                }

                Button {
                } child: {
                    Text("Middle")
                }

                Button {
                } child: {
                    Text("Last")
                }
            }
        }
    }
}

struct RedButtonStyle: Button.Style {
    func build(context: any Context) -> any Widget {
        context.child
            .padding(.all(8.0))
            .decoration(.box(color: .argb(255, 255, 69, 58), borderRadius: .all(.circular(8.0))))
    }
}

struct BlueLongButtonStyle: Button.Style {
    func build(context: any Context) -> any Widget {
        context.child
            .padding(.symmetric(vertical: 8.0, horizontal: 32.0))
            .decoration(.box(color: .argb(255, 53, 199, 89), borderRadius: .all(.circular(4.0))))
    }
}

class ButtonRow: StatelessWidget {
    init(@WidgetListBuilder children: () -> [Widget]) {
        self.children = children()
    }

    let children: [Widget]

    func build(context: BuildContext) -> Widget {
        Row(spacing: 1) {
            for (index, child) in children.enumerated() {
                child
                    .buttonStyle(
                        ButtonStyle(
                            isFirst: index == 0,
                            isLast: index == children.count - 1
                        )
                    )
            }
        }
    }

    struct ButtonStyle: Button.Style {
        let isFirst: Bool
        let isLast: Bool

        var borderRadius: BorderRadius {
            BorderRadius(
                topLeft: isFirst ? .circular(8.0) : .zero,
                topRight: isLast ? .circular(8.0) : .zero,
                bottomLeft: isFirst ? .circular(8.0) : .zero,
                bottomRight: isLast ? .circular(8.0) : .zero
            )
        }

        func build(context: any Context) -> any Widget {
            return context.child
                .padding(.symmetric(vertical: 4.0, horizontal: 8.0))
                .textStyle(.init(color: .init(0xFF_FFFFFF)))
                .decoration(
                    .box(color: .argb(255, 0, 122, 255), borderRadius: borderRadius)
                )
        }
    }
}
