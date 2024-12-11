// // Copyright 2013 The Flutter Authors. All rights reserved.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.
// //
// // Copyright 2024 The Shaft Authors.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.

// /// Builds a Widget when given a concrete value of a ValueListenable<T>.
// ///
// /// If the `child` parameter provided to the ValueListenableBuilder is not
// /// null, the same `child` widget is passed back to this ValueWidgetBuilder
// /// and should typically be incorporated in the returned widget tree.
// ///
// /// See also:
// ///
// ///  * ValueListenableBuilder, a widget which invokes this builder each time
// ///    a ValueListenable changes value.
// public typealias ValueWidgetBuilder<T> = (BuildContext, T, Widget?) -> Widget

// /// A widget whose content stays synced with a ValueListenable.
// ///
// /// Given a ValueListenable<T> and a builder which builds widgets from
// /// concrete values of `T`, this class will automatically register itself as a
// /// listener of the ValueListenable and call the builder with updated values
// /// when the value changes.
// public final class ValueListenableBuilder<T>: StatefulWidget {
//     /// Creates a ValueListenableBuilder.
//     ///
//     /// The child is optional but is good practice to use if part of the widget
//     /// subtree does not depend on the value of the valueListenable.
//     public init(
//         valueListenable: ValueListenable<T>,
//         builder: @escaping ValueWidgetBuilder<T>,
//         @OptionalWidgetBuilder child: () -> Widget? = voidBuilder
//     ) {
//         self.valueListenable = valueListenable
//         self.builder = builder
//         self.child = child()
//     }

//     /// The ValueListenable whose value you depend on in order to build.
//     ///
//     /// This widget does not ensure that the ValueListenable's value is not
//     /// null, therefore your builder may need to handle null values.
//     public let valueListenable: ValueListenable<T>

//     /// A ValueWidgetBuilder which builds a widget depending on the
//     /// valueListenable's value.
//     ///
//     /// Can incorporate a valueListenable value-independent widget subtree
//     /// from the child parameter into the returned widget tree.
//     public let builder: ValueWidgetBuilder<T>

//     /// A valueListenable-independent widget which is passed back to the
//     /// builder.
//     ///
//     /// This argument is optional and can be null if the entire widget subtree
//     /// the builder builds depends on the value of the valueListenable. For
//     /// example, in the case where the valueListenable is a String and the
//     /// builder returns a Text widget with the current String value, there would
//     /// be no useful child.
//     public let child: Widget?

//     public func createState() -> some State<ValueListenableBuilder<T>> {
//         return _ValueListenableBuilderState<T>()
//     }
// }

// class _ValueListenableBuilderState<T>: State<ValueListenableBuilder<T>> {
//     private var value: T!

//     override func initState() {
//         super.initState()
//         value = widget.valueListenable.wrappedValue
//         widget.valueListenable.addListener(self, callback: _valueChanged)
//     }

//     override func didUpdateWidget(_ oldWidget: ValueListenableBuilder<T>) {
//         super.didUpdateWidget(oldWidget)
//         if oldWidget.valueListenable !== widget.valueListenable {
//             oldWidget.valueListenable.removeListener(self)
//             value = widget.valueListenable.wrappedValue
//             widget.valueListenable.addListener(self, callback: _valueChanged)
//         }
//     }

//     override func dispose() {
//         widget.valueListenable.removeListener(self)
//         super.dispose()
//     }

//     private func _valueChanged() {
//         setState {
//             self.value = self.widget.valueListenable.wrappedValue
//         }
//     }

//     override func build(context: BuildContext) -> Widget {
//         return widget.builder(context, value, widget.child)
//     }
// }
