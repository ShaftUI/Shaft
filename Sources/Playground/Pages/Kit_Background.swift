import Shaft

final class Kit_Background: StatefulWidget {
    func createState() -> some State<Kit_Background> {
        Kit_BackgroundState()
    }
}

final class Kit_BackgroundState: State<Kit_Background> {
    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("Background")
                .textStyle(.playgroundTitle)

            Text("A container that paints its child with a background color.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                The Background widget is a container that paints its child with \
                a background color. The default implementation determines the \
                color based on the current hierarchy:
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                Background {
                    Background {
                        Text("Hello, World!")
                            .padding(.all(20.0))
                    }
                    .padding(.all(20.0))
                }
                """
            )

            Background {
                Background {
                    Text("Hello, World!")
                        .padding(.all(20.0))
                }
                .padding(.all(20.0))
            }

            // MARK: - Styling

            Text("Styling")
                .textStyle(.playgroundHeading)

            Text(
                """
                The style of Background can be customized by providing a custom \
                Background.Style:
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                struct SimpleBackgroundStyle: Background.Style {
                    func build(context: Context) -> any Widget {
                        context.child
                            .decoration(.box(color: .init(0xFF_EEEEEE), borderRadius: .all(.circular(16))))
                    }
                }


                Background {
                    Text("Customized background")
                        .padding(.all(20.0))
                }
                .backgroundStyle(SimpleBackgroundStyle())
                """
            )

            Background {
                Text("Customized background")
                    .padding(.all(20.0))
            }
            .backgroundStyle(SimpleBackgroundStyle())
        }
    }
}

struct SimpleBackgroundStyle: Background.Style {
    func build(context: Context) -> any Widget {
        context.child
            .decoration(.box(color: .init(0xFF_EEEEEE), borderRadius: .all(.circular(16))))
    }
}
