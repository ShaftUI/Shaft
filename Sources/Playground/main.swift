import Foundation
import Shaft
import ShaftCodeHighlight
import ShaftSetup

ShaftSetup.useDefault()

#if DEBUG && canImport(SwiftReload)
    import SwiftReload
    LocalSwiftReloader(onReload: backend.scheduleReassemble).start()
#endif

runApp(
    Playground()
)

final class Playground: StatefulWidget {
    func createState() -> PlaygroundState {
        PlaygroundState()
    }
}

final class PlaygroundState: State<Playground> {
    let pageByTitle: [String: Widget] = [
        "Observation": Concept_Observation(),
        "ShaftKit": Concept_ShaftKit(),
        "Backend": Concept_Backend(),
        "Background": Kit_Background(),
        "Button": Kit_Button(),
        "Divider": Kit_Divider(),
        "Image": Kit_Image(),
        "Icons": Kit_Icons(),
        "ListView": Kit_ListView(),
        "Markdown": Kit_Markdown(),
        "NavigationSplitView": Kit_NavigationSplitView(),
        "Resizable": Kit_Resizable(),
        "TextField": Kit_TextField(),
        "Typography": Kit_Typography(),
        "Hacker News": HackerNewsApp(),
        "3D Cube": Demo_Cube(),
        "Multi Window": Demo_MultiWindow(),
            // "Text Field": TextFieldPage.init,
    ]

    lazy var selectedPage = ValueNotifier("Observation")

    override func initState() {
        super.initState()
        updateTitle()
        selectedPage.addListener(self, callback: handleSelectedPageChanged)
    }

    override func dispose() {
        selectedPage.removeListener(self)
        super.dispose()
    }

    private func handleSelectedPageChanged() {
        updateTitle()
    }

    private func updateTitle() {
        View.maybeOf(context)?.title = "Playground - \(selectedPage.wrappedValue)"

    }

    override func build(context: BuildContext) -> Widget {
        NavigationSplitView {
            FixedListView(selection: selectedPage) {
                Section {
                    Text("Concepts")
                } content: {
                    MenuTile("Observation")
                    MenuTile("ShaftKit")
                    MenuTile("Backend")
                }
                Section {
                    Text("Controls")
                } content: {
                    MenuTile("Background")
                    MenuTile("Button")
                    MenuTile("Divider")
                    MenuTile("Image")
                    MenuTile("Icons")
                    MenuTile("ListView")
                    MenuTile("NavigationSplitView")
                    MenuTile("Resizable")
                    MenuTile("TextField")
                    MenuTile("Typography")
                    MenuTile("Markdown")
                }
                Section {
                    Text("Demos")
                } content: {
                    MenuTile("Hacker News")
                    MenuTile("3D Cube")
                    MenuTile("Multi Window")
                    MenuTile("Video Codec")
                }
            }
        } detail: {
            let page = pageByTitle[selectedPage.wrappedValue]
            page ?? Text("Under construction").padding(.all(20))
        }
    }
}

final class MenuTile: StatelessWidget {
    init(_ title: String) {
        self.title = title
    }

    let title: String

    func build(context: any BuildContext) -> any Widget {
        ListTile(title) {
            Text(title)
        }
    }
}
