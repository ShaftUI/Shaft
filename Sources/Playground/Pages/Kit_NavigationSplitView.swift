import Shaft

final class Kit_NavigationSplitView: StatefulWidget {
    func createState() -> some State<Kit_NavigationSplitView> {
        Kit_NavigationSplitViewState()
    }
}

final class Kit_NavigationSplitViewState: State<Kit_NavigationSplitView> {
    lazy var selectedPage = ValueNotifier("item-1")

    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("NavigationSplitView")
                .textStyle(.playgroundTitle)

            Text(
                """
                A widget that shows widgets in two separate panes. The selection \
                of the first pane controls the content of the second pane.
                """
            )
            .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                The `NavigationSplitView` widget is a layout widget that shows two \
                panes side by side. The first pane is a list of items, and the \
                second pane is a detail view that shows the content of the selected \
                item from the list.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                NavigationSplitView {
                    FixedListView(selection: selectedPage) {
                        Section {
                            Text("Section 1")
                        } content: {
                            ListTile("item-1") {
                                Text("Item 1")
                            }
                            ListTile("item-2") {
                                Text("Item 2")
                            }
                        }
                        Section {
                            Text("Section 2")
                        } content: {
                            ListTile("item-3") {
                                Text("Item 3")
                            }
                            ListTile("item-4") {
                                Text("Item 4")
                            }
                        }
                    }
                } detail: {
                    Text("Selected page: \(selectedPage.value)")
                        .center()
                }
                """
            )

            NavigationSplitView {
                FixedListView(selection: selectedPage) {
                    Section {
                        Text("Section 1")
                    } content: {
                        ListTile("item-1") {
                            Text("Item 1")
                        }
                        ListTile("item-2") {
                            Text("Item 2")
                        }
                    }
                    Section {
                        Text("Section 2")
                    } content: {
                        ListTile("item-3") {
                            Text("Item 3")
                        }
                        ListTile("item-4") {
                            Text("Item 4")
                        }
                    }
                }
            } detail: {
                Text("Selected page: \(selectedPage.value)")
                    .center()
            }
            .constrained(width: 500, height: 500)
            .decoration(
                .box(
                    border: .all(
                        .init(color: .init(0xA0_000000), width: 1.0)
                    )
                )
            )

            // MARK: - Styling

            Text("Styling")
                .textStyle(.playgroundHeading)

            Text(
                """
                The style of a NavigationSplitView can be customized by providing \
                a custom NavigationSplitView.Style:
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                """
                struct SimpleNavigationSplitViewStyle: NavigationSplitView.Style {
                    func build(context: any Context) -> any Widget {
                        Row(crossAxisAlignment: .start) {
                            Background {
                                context.sidebar
                                    .padding(.all(16))
                                    .sectionStyle(SectionStyle())
                            }
                            .constrained(width: 200)

                            Expanded {
                                context.detail
                            }
                        }
                    }

                    struct SectionStyle: Section.Style {
                        func build(context: any Context) -> any Shaft.Widget {
                            Column(mainAxisSize: .min, crossAxisAlignment: .start) {
                                if let header = context.header {
                                    header
                                }

                                Column {
                                    context.content
                                }
                            }
                            .padding(.all(8.0))
                        }
                    }
                }
                """
            )

            Text(
                """
                The `SimpleNavigationSplitViewStyle` above can be applied to a \
                widget subtree by calling the `navigationSplitViewStyle` method:
                """
            )

            CodeSection(
                """
                NavigationSplitView {
                    Column {
                        Section {
                            Text("Section")
                        } content: {
                            ListTile("item-1") {
                                Text("Item 1")
                            }
                            ListTile("item-2") {
                                Text("Item 2")
                            }
                        }
                    }
                } detail: {
                    Text("Detail")
                        .center()
                }
                .navigationSplitViewStyle(SimpleNavigationSplitViewStyle())
                """
            )

            NavigationSplitView {
                Column {
                    Section {
                        Text("Section")
                    } content: {
                        ListTile("item-1") {
                            Text("Item 1")
                        }
                        ListTile("item-2") {
                            Text("Item 2")
                        }
                    }
                }
            } detail: {
                Text("Detail")
                    .center()
            }
            .constrained(width: 500, height: 300)
            .navigationSplitViewStyle(SimpleNavigationSplitViewStyle())
            .decoration(
                .box(
                    border: .all(
                        .init(color: .init(0xA0_000000), width: 1.0)
                    )
                )
            )
        }
    }
}

struct SimpleNavigationSplitViewStyle: NavigationSplitView.Style {
    func build(context: any Context) -> any Widget {
        Row(crossAxisAlignment: .start) {
            Background {
                context.sidebar
                    .padding(.all(16))
                    .sectionStyle(SectionStyle())
            }
            .constrained(width: 200)

            Expanded {
                context.detail
            }
        }
    }

    struct SectionStyle: Section.Style {
        func build(context: any Context) -> any Shaft.Widget {
            Column(mainAxisSize: .min, crossAxisAlignment: .start) {
                if let header = context.header {
                    header
                }

                Column {
                    context.content
                }
            }
            .padding(.all(8.0))
        }
    }
}
