import Shaft

final class Page_Template: StatefulWidget {
    func createState() -> some State<Page_Template> {
        Page_TemplateState()
    }
}

final class Page_TemplateState: State<Page_Template> {
    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("Template")
                .textStyle(.playgroundTitle)

            Text("Brief description of the concept.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                Overview of the concept.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                Example code snippet.
                """
            )
        }
    }
}
