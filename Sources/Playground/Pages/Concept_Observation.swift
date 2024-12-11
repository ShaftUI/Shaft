import Observation
import Shaft

final class Concept_Observation: StatefulWidget {
    func createState() -> some State<Concept_Observation> {
        Concept_ObservationState()
    }
}

final class Concept_ObservationState: State<Concept_Observation> {
    override func build(context: BuildContext) -> Widget {

        return PageContent {
            Text("Observation")
                .textStyle(.playgroundTitle)

            Text("Keep UI in sync with underlying data without manual configuration.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            // MARK: - Overview

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                Shaft leverages Swift's Observation framework as its core mechanism for \
                updating widgets in response to data changes. This efficient approach \
                minimizes boilerplate code and helps prevent UI synchronization issues.

                To make data observable, simply annotate it with the \
                `@Observable` macro:
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                #"""
                @Observable class Counter {
                    var count = 0
                }

                let counter = Counter()

                class CounterView: StatelessWidget {
                    func build(context: any BuildContext) -> any Widget {
                        Column {
                            Text("Count: \(counter.count)")
                            Button {
                                counter.count += 1
                            } child: {
                                Text("Increment")
                            }
                        }
                    }
                }
                """#
            )

            CounterView()

            Text(
                """
                What's happening internally is that during the build phase, reading \
                @Observable data automatically establishes a widget-object \
                dependency. When observed values change, the widget is marked dirty \
                and rebuilds in the next frame, similar to setState.
                """
            )
            .textStyle(.playgroundBody)

            Text("Example")
                .textStyle(.playgroundHeading)

            Text(
                """
                The following code shows a slightly more complex example of a \
                shopping list with a total count and an editor to add new items:
                """
            )

            CodeSection(
                #"""
                @Observable class ShoppingList {
                    var items: [Entry] = []

                    var total: Int {
                        items.reduce(0) { $0 + $1.quantity }
                    }

                    @Observable class Entry {
                        init(name: String, quantity: Int) {
                            self.name = name
                            self.quantity = quantity
                        }

                        var name: String
                        var quantity: Int
                    }
                }

                let shoppingList = ShoppingList()
                """#
            )

            Text(
                """
                Notice that reading nested properties of the ShoppingList object \
                also works, as long as the nested object is also marked as @Observable.
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                #"""
                class ShoppingListView: StatelessWidget {
                    func build(context: any BuildContext) -> any Widget {
                        Column(spacing: 2.0) {
                            for item in shoppingList.items {
                                ShoppingListEntryView(item: item)
                            }
                        }
                    }

                }

                class ShoppingListEntryView: StatelessWidget {
                    init(item: ShoppingList.Entry) {
                        self.item = item
                    }

                    let item: ShoppingList.Entry

                    func build(context: any BuildContext) -> any Widget {
                        Row(spacing: 8) {
                            Expanded {
                                Text(item.name)
                            }

                            Text("x\(item.quantity)")

                            Button(onPressed: incrementQuantity) {
                                Text("+")
                            }

                            Button(onPressed: decrementQuantity) {
                                Text("-")
                            }
                        }
                    }

                    func incrementQuantity() {
                        item.quantity += 1
                    }

                    func decrementQuantity() {
                        item.quantity -= 1

                        if item.quantity == 0 {
                            shoppingList.items.removeAll { $0 === item }
                        }
                    }
                }
                """#
            )

            Text(
                """
                Reading computed properties of the ShoppingList object can \
                also establish a dependency, since computed properties eventually \
                read stored properties of the object:
                """
            )
            .textStyle(.playgroundBody)

            CodeSection(
                #"""
                class ShoppingListTotalView: StatelessWidget {
                    func build(context: any BuildContext) -> any Widget {
                        Text("Total: \(shoppingList.total) items")
                    }
                }
                """#
            )

            Text(
                """
                Manipulating list items will also trigger the rebuild of the \
                `ShoppingListView` widget:
                """
            )

            CodeSection(
                #"""
                final class ShoppingListEditor: StatefulWidget {
                    func createState() -> some State<ShoppingListEditor> {
                        ShoppingListEditorState()
                    }
                }

                class ShoppingListEditorState: State<ShoppingListEditor> {
                    var name = TextEditingController()

                    override func build(context: any BuildContext) -> any Widget {
                        Row(spacing: 8) {
                            Expanded {
                                TextField(controller: name)
                            }

                            Button(onPressed: addListEntry) {
                                Text("Add")
                            }
                        }
                    }

                    func addListEntry() {
                        shoppingList.items.append(
                            ShoppingList.Entry(name: name.text, quantity: 1)
                        )
                        name.text = ""
                    }
                }
                """#
            )

            SizedBox(width: 500) {
                Column(crossAxisAlignment: .start) {
                    ShoppingListView()

                    HorizontalDivider(padding: .symmetric(vertical: 8))

                    ShoppingListTotalView()

                    ShoppingListEditor()
                }
            }
        }
    }
}

@Observable
class Counter {
    var count = 0
}

let counter = Counter()

class CounterView: StatelessWidget {
    func build(context: any BuildContext) -> any Widget {
        Column(crossAxisAlignment: .start) {
            Text("Count: \(counter.count)")
            Button {
                counter.count += 1
            } child: {
                Text("Increment")
            }
        }
    }
}

@Observable
class ShoppingList {
    var items: [Entry] = [
        Entry(name: "Milk", quantity: 1),
        Entry(name: "Eggs", quantity: 12),
        Entry(name: "Bread", quantity: 2),
    ]

    var total: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    @Observable
    class Entry {
        init(name: String, quantity: Int) {
            self.name = name
            self.quantity = quantity
        }

        var name: String
        var quantity: Int
    }
}

let shoppingList = ShoppingList()

class ShoppingListView: StatelessWidget {
    func build(context: any BuildContext) -> any Widget {
        Column(spacing: 2.0) {
            for item in shoppingList.items {
                ShoppingListEntryView(item: item)
            }
        }
    }

}

class ShoppingListEntryView: StatelessWidget {
    init(item: ShoppingList.Entry) {
        self.item = item
    }

    let item: ShoppingList.Entry

    func build(context: any BuildContext) -> any Widget {
        Row(spacing: 8) {
            Expanded {
                Text(item.name)
            }

            Text("x\(item.quantity)")

            Button(onPressed: incrementQuantity) {
                Text("+")
            }

            Button(onPressed: decrementQuantity) {
                Text("-")
            }
        }
    }

    func incrementQuantity() {
        item.quantity += 1
    }

    func decrementQuantity() {
        item.quantity -= 1

        if item.quantity == 0 {
            shoppingList.items.removeAll { $0 === item }
        }
    }
}

class ShoppingListTotalView: StatelessWidget {
    func build(context: any BuildContext) -> any Widget {
        Text("Total: \(shoppingList.total) items")
    }
}

final class ShoppingListEditor: StatefulWidget {
    func createState() -> some State<ShoppingListEditor> {
        ShoppingListEditorState()
    }
}

class ShoppingListEditorState: State<ShoppingListEditor> {
    var name = TextEditingController()

    override func build(context: any BuildContext) -> any Widget {
        Row(spacing: 8) {
            Expanded {
                TextField(controller: name)
            }

            Button(onPressed: addListEntry) {
                Text("Add")
            }
        }
    }

    func addListEntry() {
        shoppingList.items.append(
            ShoppingList.Entry(name: name.text, quantity: 1)
        )
        name.text = ""
    }
}
