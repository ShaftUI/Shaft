import Shaft

final class Kit_ListView: StatefulWidget {
    func createState() -> some State<Kit_ListView> {
        Kit_ListViewState()
    }
}

final class Kit_ListViewState: State<Kit_ListView> {
    let selected = ValueNotifier(0)

    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("ListView")
                .textStyle(.playgroundTitle)

            Text(
                "A scrollable list of widgets, optionally with the ability to select one or more items."
            )
            .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                A ListView is a scrollable list of widgets. It can be used to display \
                a collection of items, such as text, images, or other widgets.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                FixedListView {
                    Text("Item 1")
                    Text("Item 2")
                    Text("Item 3")
                }
                """
            )

            FixedListView {
                Text("Item 1")
                Text("Item 2")
                Text("Item 3")
            }

            // MARK: - Selection

            Text("Selection")
                .textStyle(.playgroundHeading)

            Text(
                """
                A ListView can be configured to allow users to select one or more items. \
                The selection can be controlled by providing a valueNotifier:
                """
            )

            CodeSection(
                #"""
                let selected = ValueNotifier(0)

                FixedListView(selection: selected) {
                    for i in 0..<5 {
                        ListTile(i) {
                            Text("Item \(i)")
                        }
                    }
                }

                Button {
                    selected.value += 1
                } child: {
                    Text("Select next item")
                }
                """#
            )

            FixedListView(selection: selected) {
                for i in 0..<5 {
                    ListTile(i) {
                        Text("Item \(i)")
                    }
                }
            }

            Button {
                self.selected.value += 1
            } child: {
                Text("Select next item")
            }

            // MARK: - Styling

            Text("Styling")
                .textStyle(.playgroundHeading)

            Text(
                """
                The style of a FixedListView can be customized by providing a FixedListViewStyle:
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                #"""
                struct SimpleListViewStyle: FixedListViewStyle {
                    func build(context: FixedListViewStyleContext) -> Widget {
                        Column {
                            context.children
                                .separated(by: HorizontalDivider(padding: .all(4.0)))
                        }
                    }
                }

                FixedListView {
                    for i in 0..<5 {
                        ListTile(i) {
                            Text("Item \(i)")
                        }
                    }
                }
                .fixedListViewStyle(SimpleListViewStyle())
                """#
            )

            SizedBox(width: 300) {
                FixedListView {
                    for i in 0..<5 {
                        ListTile(i) {
                            Text("Item \(i)")
                        }
                    }
                }
                .fixedListViewStyle(SimpleListViewStyle())
            }
        }
    }
}

struct SimpleListViewStyle: FixedListViewStyle {
    func build(context: FixedListViewStyleContext) -> Widget {
        Column {
            context.children
                .separated(by: HorizontalDivider(padding: .all(4.0)))
        }
    }
}
