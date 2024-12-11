import Shaft

final class Kit_TextField: StatefulWidget {
    func createState() -> some State<Kit_TextField> {
        Kit_TextFieldState()
    }
}
final class Kit_TextFieldState: State<Kit_TextField> {
    let controller = TextEditingController()

    override func initState() {
        controller.text = "Hello, world!"
    }

    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("TextField")
                .textStyle(.playgroundTitle)

            Text("A widget that allows the user to enter text.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            Text("Overview")
                .textStyle(.playgroundHeading)

            // Creation of ``TextField`` widget
            Text(
                """
                A TextField widget can be created by calling the `TextField` \
                initializer, with an optional controller to modify the text \
                being edited.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                TextField()
                """
            )

            TextField(
                placeholder: "Enter some text"
            )

            CodeSection(
                """
                let controller = TextEditingController()
                controller.text = "Hello, world!"

                TextField(
                    controller: controller
                )

                Button { 
                    controller.text = ""
                } child: {
                    Text("Clear")
                }
                """
            )

            TextField(
                controller: controller
            )

            Button { [self] in
                controller.text = ""
            } child: {
                Text("Clear")
            }

            // Use .buttonStyle to set the style of the button
            Text("Styling")
                .textStyle(.playgroundHeading)

            Text(
                """
                The style of the text field can be completely customized \
                with the `.textFieldStyle` modifier.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                struct TextFieldStyle: TextField.Style {
                    func build(context: TextField.StyleContext) -> any Shaft.Widget {
                        context.child
                            .padding(.all(4))
                            .decoration(.box(border: .all(.init(color: .init(0xFF_000000), width: 1))))
                    }
                }

                TextField()
                    .textFieldStyle(TextFieldStyle())
                """
            )

            TextField()
                .textFieldStyle(TextFieldStyle())
        }
    }
}

struct TextFieldStyle: TextField.Style {
    func build(context: TextField.StyleContext) -> any Shaft.Widget {
        context.child
            .padding(.all(4))
            .decoration(.box(border: .all(.init(color: .init(0xFF_000000), width: 1))))
    }
}
