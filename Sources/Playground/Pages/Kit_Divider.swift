import Shaft

final class Kit_Divider: StatefulWidget {
    func createState() -> some State<Kit_Divider> {
        Kit_DividerState()
    }
}

final class Kit_DividerState: State<Kit_Divider> {
    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("Divider")
                .textStyle(.playgroundTitle)

            Text("A line that separates content.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                The Divider widget is a line that separates content. There are \
                two types of dividers: horizontal and vertical.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                for _ in 0..<5 {
                    HorizontalDivider()
                }

                for _ in 0..<5 {
                    VerticalDivider()
                }
                """
            )

            SizedBox(width: 200) {
                Column(spacing: 20) {
                    for _ in 0..<5 {
                        HorizontalDivider()
                    }
                }
            }

            SizedBox(height: 100) {
                Row(spacing: 20) {
                    for _ in 0..<5 {
                        VerticalDivider()
                    }
                }
            }

            // MARK: - Styling

            Text("Styling")
                .textStyle(.playgroundHeading)

            Text(
                """
                The style of a Divider can be customized by providing a custom \
                style:
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                struct SimpleDividerStyle: DividerStyle {
                    func build(context: DividerStyleContext) -> Widget {
                        context.child
                            .background(.init(0xFF_000000))
                    }
                }


                Column(spacing: 20) {
                    for _ in 0..<5 {
                        HorizontalDivider()
                    }
                }
                .dividerStyle(SimpleDividerStyle())
                """
            )

            SizedBox(width: 200) {
                Column(spacing: 20) {
                    for _ in 0..<5 {
                        HorizontalDivider()
                    }
                }
            }
            .dividerStyle(SimpleDividerStyle())
        }
    }
}

struct SimpleDividerStyle: DividerStyle {
    func build(context: DividerStyleContext) -> Widget {
        context.child
            .background(.init(0xFF_000000))
    }
}
