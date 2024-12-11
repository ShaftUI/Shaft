import Shaft

final class Concept_Backend: StatefulWidget {
    func createState() -> some State<Concept_Backend> {
        Concept_BackendState()
    }
}

final class Concept_BackendState: State<Concept_Backend> {
    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("Backend")
                .textStyle(.playgroundTitle)

            Text("The single protocol that provides everything Shaft needs to run.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                The only dependency that Shaft has on the platform is the Backend \
                protocol. This protocol provides everything Shaft needs to run, \
                including the event loop, event handling, text editing, and rendering.

                SDLBackend is the default implementation of this protocol, \
                which works on a really wide range of platforms, but you can always \
                provide your own implementation for specific needs.

                The Backend protocol is designed to be simple and it should not \
                require a lot of effort to implement it for a new platform. Here is \
                a quick preview of what the Backend protocol looks like:
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                public protocol Backend: AnyObject {
                    func createView() -> NativeView?

                    var onPointerData: PointerDataCallback? { get set }

                    var onKeyEvent: KeyEventCallback? { get set }
                    ...
                """
            )

            Text(
                """
                To use a custom backend instead of the default one, you can simply \
                create a new instance of the backend and set it to the [Shaft.backend] \
                global variable. This will make Shaft use your custom backend instead \
                of the default one.
                """
            )

            CodeSection(
                """
                let customBackend = MyCustomBackend()
                Shaft.backend = customBackend
                """
            )
        }
    }
}
