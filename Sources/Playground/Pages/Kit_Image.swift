import Foundation
import Shaft

final class Kit_Image: StatefulWidget {
    func createState() -> some State<Kit_Image> {
        Kit_ImageState()
    }
}

final class Kit_ImageState: State<Kit_Image> {
    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("Image")
                .textStyle(.playgroundTitle)

            Text("A widget that displays an image.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                To display an image, use the Image` widget. The image can be loaded \
                from a URL or from a local file.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                Image.network(url: URL(string: "https://cataas.com/cat")!)
                """
            )

            Image.network(url: URL(string: "https://cataas.com/cat")!)
        }
    }
}
