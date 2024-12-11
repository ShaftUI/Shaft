// // Copyright 2013 The Flutter Authors. All rights reserved.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.
// //
// // Copyright 2024 The Shaft Authors.
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.

// @propertyWrapper public struct Inherited<Value: InheritedWidget> {
//     public init() {}

//     public static subscript<EnclosingSelf: StateProtocol>(
//         _enclosingInstance instance: EnclosingSelf,
//         wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
//         storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
//     ) -> Value {
//         get {
//             instance.context.dependOnInheritedWidgetOfExactType(Value.self)!
//         }
//         set {}
//     }

//     public static subscript<EnclosingSelf: StateProtocol>(
//         _enclosingInstance instance: EnclosingSelf,
//         projected wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value?>,
//         storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
//     ) -> Value? {
//         get {
//             instance.context.dependOnInheritedWidgetOfExactType(Value.self)
//         }
//         set {}
//     }

//     @available(*, unavailable, message: "@Inherited can only be applied to classes")
//     /// The wrapped property can not be directly used.
//     ///
//     /// You don't access`wrappedValue` directly.
//     public var wrappedValue: Value {
//         get { fatalError() }
//         set { fatalError() }
//     }

//     public var projectedValue: Value? {
//         get { fatalError("called projectedValue getter") }
//         set { fatalError("called projectedValue setter") }
//     }
// }
