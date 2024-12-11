import Shaft

final class Kit_Typography: StatefulWidget {
    func createState() -> some State<Kit_Typography> {
        Kit_TypographyState()
    }
}

final class Kit_TypographyState: State<Kit_Typography> {
    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("Typography")
                .textStyle(.playgroundTitle)

            Text("Text styles and fonts.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                ShaftKit comes with a predefined set of text styles that can be \
                used to style text in your app.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                Text("Some text")
                    .textStyle(.headline)

                Text("Some bold text")
                    .bold(.w700)
                    .textStyle(.headline)
                """
            )

            TextDemo("LargeTitle", style: .largeTitle)
            TextDemo("Title", style: .title)
            TextDemo("Title2", style: .title2)
            TextDemo("Title3", style: .title3)
            TextDemo("Headline", style: .headline)
            TextDemo("Body", style: .body)
            TextDemo("Callout", style: .callout)
            TextDemo("Subheadline", style: .subheadline)
            TextDemo("Footnote", style: .footnote)
            TextDemo("Caption1", style: .caption1)
            TextDemo("Caption2", style: .caption2)

        }
    }
}

private class TextDemo: StatelessWidget {
    let text: String
    let style: TextStyle

    init(_ text: String, style: TextStyle) {
        self.text = text
        self.style = style
    }

    func build(context: BuildContext) -> Widget {
        Column(crossAxisAlignment: .start) {
            Text(text)
                .textStyle(style)
            Text(text)
                .bold(.w700)
                .textStyle(style)
        }
    }
}
