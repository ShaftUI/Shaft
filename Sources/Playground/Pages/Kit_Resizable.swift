import Shaft

final class Kit_Resizable: StatefulWidget {
    func createState() -> some State<Kit_Resizable> {
        Kit_ResizableState()
    }
}

final class Kit_ResizableState: State<Kit_Resizable> {
    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("Resizable")
                .textStyle(.playgroundTitle)

            Text("A container with two child widgets that can be resized by dragging a handle.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                The Resizable widget is a layout widget that shows two child widgets side by side. \
                The size of the first child widget can be resized by dragging a handle between the two \
                child widgets.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                Resizable {
                    Background {
                        Text("Left")
                            .center()
                    }
                } right: {
                    Text("Right")
                        .center()

                }
                """
            )

            Resizable {
                Background {
                    Text("Left")
                        .center()
                }
            } right: {
                Text("Right")
                    .center()

            }
            .constrained(width: 400, height: 200)

        }
    }
}
