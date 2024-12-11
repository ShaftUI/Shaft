import Shaft

final class Kit_Button: StatelessWidget {
    func build(context: BuildContext) -> Widget {
        PageContent {
            Text("Button")
                .textStyle(.playgroundTitle)

            Text("A button is a control that a user can tap to trigger an action.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            Text("Overview")
                .textStyle(.playgroundHeading)

            // Creation of ``Button`` widget
            Text(
                """
                A Button widget can be created with a closure that is called \
                when the button is pressed, and a child widget that represents \
                the button's body.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                Button {
                    print("Button pressed")
                } child: {
                    Text("Click me")
                }
                """
            )

            // Use .controlSize to set the size of the button
            Text(
                """
                The size of the button can be specified with the `.controlSize` \
                modifier.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                #"""
                for size in ControlSize.allCases {
                    Button {
                    } child: {
                        Text("\(size)")
                    }
                    .controlSize(size)
                }
                """#
            )

            Row(crossAxisAlignment: .end, spacing: 8) {
                for size in ControlSize.allCases {
                    Button {
                        print("Button pressed")
                    } child: {
                        Text("\(size)")
                    }
                    .controlSize(size)
                }
            }

            // Use .buttonStyle to set the style of the button
            Text("Styling")
                .textStyle(.playgroundHeading)

            Text(
                """
                The style of the button can be completely customized \
                with the `.buttonStyle` modifier.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                struct ButtonStyle: Button.Style {
                    func build(context: any Context) -> any Shaft.Widget {
                        context.child
                            .padding(.all(8))
                            .decoration(.box(color: .argb(UInt8(context.isPressed ? 0x80 : 0xFF), 235, 100, 50)))
                            .textStyle(.init(color: .init(0xFFFF_FFFF)))
                    }
                }

                Button { } child: {
                    Text("Customized button")
                }
                .buttonStyle(ButtonStyle())
                """
            )

            Button {
            } child: {
                Text("Customized button")
            }
            .buttonStyle(ButtonStyle())
        }
    }
}

struct ButtonStyle: Button.Style {
    func build(context: any Context) -> any Shaft.Widget {
        context.child
            .padding(.all(8))
            .decoration(.box(color: .argb(UInt8(context.isPressed ? 0x80 : 0xFF), 235, 100, 50)))
            .textStyle(.init(color: .init(0xFFFF_FFFF)))
    }
}
