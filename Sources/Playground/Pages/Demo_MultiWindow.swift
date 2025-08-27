import Shaft

final class Demo_MultiWindow: StatelessWidget {
    func build(context: BuildContext) -> Widget {
        Column {
            Expanded {
                buildPageContent(context: context)
            }
            buildSubWindow(context: context)
        }
    }

    func buildSubWindow(context: BuildContext) -> Widget {
        SubWindow(
            onWindowCreated: { view in
                if let view = view as? DesktopView {
                    view.title = "My Window"
                    view.size = .init(400, 400)
                }
            },
        ) {
            Text("Sub Window 1")
                .center()
                .background(.init(0xFFFF_FFFF))
        }

    }

    func buildPageContent(context: BuildContext) -> Widget {
        PageContent {

            Text("Multi Window")
                .textStyle(.playgroundTitle)

            Text("Create separate native windows that run independently.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                The SubWindow widget creates a new native window when rendered. \
                Each window runs independently with its own widget hierarchy.
                """
            )
            .textStyle(.playgroundBody)

            Text("Basic Usage")
                .textStyle(.playgroundHeading)

            Text(
                """
                Create a sub-window by wrapping your content with the SubWindow widget. \
                You can configure the window through callback functions:
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                #"""
                SubWindow(
                    onWindowCreated: { view in
                        view.title = "My Sub Window"
                        // Configure window properties
                    },
                    onWindowDestroyed: { view in
                        print("Window closed")
                        // Cleanup when window closes
                    }
                ) {
                    // Your window content goes here
                    Text("Hello from sub-window!")
                }
                """#
            )

            Text("Window Callbacks")
                .textStyle(.playgroundHeading)

            Text(
                """
                Configure window creation and destruction with callback functions:
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                #"""
                SubWindow(
                    onWindowCreated: { view in
                        view.title = "My Window"
                    },
                    onWindowDestroyed: { view in
                        print("Window closed")
                    }
                ) {
                    Text("Window content")
                }
                """#
            )

        }
    }
}
