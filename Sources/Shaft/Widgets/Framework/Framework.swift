// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Observation

public protocol Key: Hashable {
    func isEqualTo(_ other: (any Key)?) -> Bool
}

/// A type erased [Key].
public struct AnyKey: Hashable {
    public let value: any Key

    public init(_ value: any Key) {
        self.value = value
    }

    public func isEqualTo(_ other: (any Key)?) -> Bool {
        value.isEqualTo(other)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public static func == (lhs: AnyKey, rhs: AnyKey) -> Bool {
        lhs.value.isEqualTo(rhs.value)
    }
}

/// A key that is unique across the entire app.
///
/// Global keys uniquely identify elements. Global keys provide access to other
/// objects that are associated with those elements, such as [BuildContext].
/// For [StatefulWidget]s, global keys also provide access to [State].
///
/// Widgets that have global keys reparent their subtrees when they are moved
/// from one location in the tree to another location in the tree. In order to
/// reparent its subtree, a widget must arrive at its new location in the tree
/// in the same animation frame in which it was removed from its old location in
/// the tree.
///
/// Reparenting an [Element] using a global key is relatively expensive, as
/// this operation will trigger a call to [State.deactivate] on the associated
/// [State] and all of its descendants; then force all widgets that depends
/// on an [InheritedWidget] to rebuild.
///
/// If you don't need any of the features listed above, consider using a [Key],
/// [ValueKey], [ObjectKey], or [UniqueKey] instead.
///
/// You cannot simultaneously include two widgets in the tree with the same
/// global key. Attempting to do so will assert at runtime.
///
/// ## Pitfalls
///
/// GlobalKeys should not be re-created on every build. They should usually be
/// long-lived objects owned by a [State] object, for example.
///
/// Creating a new GlobalKey on every build will throw away the state of the
/// subtree associated with the old key and create a new fresh subtree for the
/// new key. Besides harming performance, this can also cause unexpected
/// behavior in widgets in the subtree. For example, a [GestureDetector] in the
/// subtree will be unable to track ongoing gestures since it will be recreated
/// on each build.
///
/// Instead, a good practice is to let a State object own the GlobalKey, and
/// instantiate it outside the build method, such as in [State.initState].
///
/// See also:
///
///  * The discussion at [Widget.key] for more information about how widgets use
///    keys.
public class GlobalKey: Key, HashableObject {
    public init() {}

    public func isEqualTo(_ other: (any Key)?) -> Bool {
        other is GlobalKey && other as! GlobalKey === self
    }

    fileprivate var currentElement: Element? {
        WidgetsBinding.shared.buildOwner.globalKeyRegistry[self]
    }

    /// The build context in which the widget with this key builds.
    ///
    /// The current context is null if there is no widget in the tree that matches
    /// this global key.
    public var currentContext: BuildContext? { currentElement }

    /// The widget in the tree that currently has this global key.
    ///
    /// The current widget is null if there is no widget in the tree that matches
    /// this global key.
    public var currentWidget: Widget? { currentElement?.widget }
}

/// A variant of ``GlobalKey`` for ``StatefulWidget``s that allows access to the
/// associated ``State`` object.
public class StateGlobalKey<StateType: StateProtocol>: GlobalKey {
    /// The [State] for the widget in the tree that currently has this global key.
    ///
    /// The current state is null if (1) there is no widget in the tree that
    /// matches this global key, (2) that widget is not a [StatefulWidget], or the
    /// associated [State] object is not a subtype of `T`.
    public func getState() -> StateType? {
        if let element = currentElement as? StatefulElement<StateType.WidgetType> {
            return element.state as? StateType
        }
        return nil
    }
}

/// A key that takes its identity from the object used as its value.
///
/// Used to tie the identity of a widget to the identity of an object used to
/// generate that widget.
///
/// See also:
///
///  * [Key], the base class for all keys.
///  * The discussion at [Widget.key] for more information about how widgets use
///    keys.
public class ObjectKey: Key {
    /// Creates a key that uses `===` on `value` for its `==` operator.
    public init(_ value: AnyObject) {
        self.value = value
    }

    /// The object whose identity is used by this key's `==` operator.
    public let value: AnyObject

    public static func == (lhs: ObjectKey, rhs: ObjectKey) -> Bool {
        return lhs.value === rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(value))
    }

    public func isEqualTo(_ other: (any Key)?) -> Bool {
        guard let other = other as? ObjectKey else { return false }
        return self.value === other.value
    }
}

/// A key that uses a value of a particular type to identify itself.
///
/// A `ValueKey<T>` is equal to another `ValueKey<T>` if, and only if, their
/// values are `==`.
///
/// This class can be subclassed to create value keys that will not be equal to
/// other value keys that happen to use the same value. If the subclass is
/// private, this results in a value key type that cannot collide with keys from
/// other sources, which could be useful, for example, if the keys are being
/// used as fallbacks in the same scope as keys supplied from another widget.
///
/// See also:
///
///  * `Widget.key`, which discusses how widgets use keys.
public class ValueKey<T: Hashable>: Key {
    /// Creates a key that delegates its `==` to the given value.
    public init(_ value: T) {
        self.value = value
    }

    /// The value to which this key delegates its `==`
    public let value: T

    public static func == (lhs: ValueKey<T>, rhs: ValueKey<T>) -> Bool {
        return lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public func isEqualTo(_ other: (any Key)?) -> Bool {
        guard let other = other as? ValueKey<T> else { return false }
        return self.value == other.value
    }
}

/// Describes the configuration for an [Element].
///
/// Widgets are the central class hierarchy in the Flutter framework. A widget
/// is an immutable description of part of a user interface. Widgets can be
/// inflated into elements, which manage the underlying render tree.
public protocol Widget: AnyObject {
    /// Controls how one widget replaces another widget in the tree.
    ///
    /// If the [runtimeType] and [key] properties of the two widgets are
    /// [operator==], respectively, then the new widget replaces the old widget by
    /// updating the underlying element (i.e., by calling [Element.update] with the
    /// new widget). Otherwise, the old element is removed from the tree, the new
    /// widget is inflated into an element, and the new element is inserted into the
    /// tree.
    var key: (any Key)? { get }

    /// Inflates this configuration to a concrete instance.
    ///
    /// A given widget can be included in the tree zero or more times. In particular
    /// a given widget can be placed in the tree multiple times. Each time a widget
    /// is placed in the tree, it is inflated into an [Element], which means a
    /// widget that is incorporated into the tree multiple times will be inflated
    /// multiple times.
    func createElement() -> Element
}

extension Widget {
    /// A widget has no key by default.
    public var key: (any Key)? { nil }

    /// Whether the `newWidget` can be used to update an [Element] that currently
    /// has the `oldWidget` as its configuration.
    ///
    /// An element that uses a given widget as its configuration can be updated to
    /// use another widget as its configuration if, and only if, the two widgets
    /// have [runtimeType] and [key] properties that are [operator==].
    ///
    /// If the widgets have no key (their key is null), then they are considered a
    /// match if they have the same type, even if their children are completely
    /// different.
    func canUpdate(_ other: Widget) -> Bool {
        return type(of: self) == type(of: other)
            && (key?.isEqualTo(other.key) ?? true)
    }
}

/// A handle to the location of a widget in the widget tree.
///
/// This class presents a set of methods that can be used from
/// [StatelessWidget.build] methods and from methods on [State] objects.
///
/// [BuildContext] objects are passed to [WidgetBuilder] functions (such as
/// [StatelessWidget.build]), and are available from the [State.context] member.
/// Some static functions (e.g. [showDialog], [Theme.of], and so forth) also
/// take build contexts so that they can act on behalf of the calling widget, or
/// obtain data specifically for the given context.
///
/// Each widget has its own [BuildContext], which becomes the parent of the
/// widget returned by the [StatelessWidget.build] or [State.build] function.
/// (And similarly, the parent of any children for [RenderObjectWidget]s.)
public protocol BuildContext: AnyObject {
    /// The current configuration of the [Element] that is this [BuildContext].
    var widget: Widget! { get }

    /// The [BuildOwner] for this context. The [BuildOwner] is in charge of
    /// managing the rendering pipeline for this context.
    var owner: BuildOwner? { get }

    /// Whether the [Widget] this context is associated with is currently
    /// mounted in the widget tree.
    ///
    /// Accessing the properties of the [BuildContext] or calling any methods on
    /// it is only valid while mounted is true. If mounted is false, assertions
    /// will trigger.
    ///
    /// Once unmounted, a given [BuildContext] will never become mounted again.
    var mounted: Bool { get }

    /// The current [RenderObject] for the widget. If the widget is a
    /// [RenderObjectWidget], this is the render object that the widget created
    /// for itself. Otherwise, it is the render object of the first descendant
    /// [RenderObjectWidget].
    ///
    /// This method will only return a valid result after the build phase is
    /// complete. It is therefore not valid to call this from a build method. It
    /// should only be called from interaction event handlers (e.g. gesture
    /// callbacks) or layout or paint callbacks. It is also not valid to call if
    /// [State.mounted] returns false.
    ///
    /// If the render object is a [RenderBox], which is the common case, then
    /// the size of the render object can be obtained from the [size] getter.
    /// This is only valid after the layout phase, and should therefore only be
    /// examined from paint callbacks or interaction event handlers (e.g.
    /// gesture callbacks).
    ///
    /// For details on the different phases of a frame, see the discussion at
    /// [WidgetsBinding.drawFrame].
    ///
    /// Calling this method is theoretically relatively expensive (O(N) in the
    /// depth of the tree), but in practice is usually cheap because the tree
    /// usually has many render objects and therefore the distance to the
    /// nearest render object is usually short.
    func findRenderObject() -> RenderObject?

    /// The size of the [RenderBox] returned by [findRenderObject].
    ///
    /// This getter will only return a valid result after the layout phase is
    /// complete. It is therefore not valid to call this from a build method.
    /// It should only be called from paint callbacks or interaction event
    /// handlers (e.g. gesture callbacks).
    ///
    /// For details on the different phases of a frame, see the discussion at
    /// [WidgetsBinding.drawFrame].
    ///
    /// This getter will only return a valid result if [findRenderObject] actually
    /// returns a [RenderBox]. If [findRenderObject] returns a render object that
    /// is not a subtype of [RenderBox] (e.g., [RenderView]), this getter will
    /// throw an exception in debug mode and will return null in release mode.
    ///
    /// Calling this getter is theoretically relatively expensive (O(N) in the
    /// depth of the tree), but in practice is usually cheap because the tree
    /// usually has many render objects and therefore the distance to the nearest
    /// render object is usually short.
    var size: Size? { get }

    /// Registers this build context with [ancestor] such that when
    /// [ancestor]'s widget changes this build context is rebuilt.
    ///
    /// Returns `ancestor.widget`.
    ///
    /// This method is rarely called directly. Most applications should use
    /// [dependOnInheritedWidgetOfExactType], which calls this method after finding
    /// the appropriate [InheritedElement] ancestor.
    ///
    /// All of the qualifications about when [dependOnInheritedWidgetOfExactType] can
    /// be called apply to this method as well.
    func dependOnInheritedElement(_ ancestor: InheritedElement, aspect: Any?)
        -> any InheritedWidget

    /// Returns the nearest widget of the given type `T` and creates a dependency
    /// on it, or null if no appropriate widget is found.
    ///
    /// The widget found will be a concrete [InheritedWidget] subclass, and
    /// calling [dependOnInheritedWidgetOfExactType] registers this build context
    /// with the returned widget. When that widget changes (or a new widget of
    /// that type is introduced, or the widget goes away), this build context is
    /// rebuilt so that it can obtain new values from that widget.
    ///
    /// This is typically called implicitly from `of()` static methods, e.g.
    /// [Theme.of].
    ///
    /// This method should not be called from widget constructors or from
    /// [State.initState] methods, because those methods would not get called
    /// again if the inherited value were to change. To ensure that the widget
    /// correctly updates itself when the inherited value changes, only call this
    /// (directly or indirectly) from build methods, layout and paint callbacks,
    /// or from [State.didChangeDependencies] (which is called immediately after
    /// [State.initState]).
    ///
    /// This method should not be called from [State.dispose] because the element
    /// tree is no longer stable at that time. To refer to an ancestor from that
    /// method, save a reference to the ancestor in [State.didChangeDependencies].
    /// It is safe to use this method from [State.deactivate], which is called
    /// whenever the widget is removed from the tree.
    ///
    /// It is also possible to call this method from interaction event handlers
    /// (e.g. gesture callbacks) or timers, to obtain a value once, as long as
    /// that value is not cached and/or reused later.
    ///
    /// Calling this method is O(1) with a small constant factor, but will lead to
    /// the widget being rebuilt more often.
    ///
    /// Once a widget registers a dependency on a particular type by calling this
    /// method, it will be rebuilt, and [State.didChangeDependencies] will be
    /// called, whenever changes occur relating to that widget until the next time
    /// the widget or one of its ancestors is moved (for example, because an
    /// ancestor is added or removed).
    ///
    /// The [aspect] parameter is only used when `T` is an
    /// [InheritedWidget] subclasses that supports partial updates, like
    /// [InheritedModel]. It specifies what "aspect" of the inherited
    /// widget this context depends on.
    func dependOnInheritedWidgetOfExactType<T: InheritedWidget>(_ type: T.Type, aspect: AnyObject?)
        -> T?

    /// Returns the nearest widget of the given [InheritedWidget] subclass `T`
    /// or null if an appropriate ancestor is not found.
    ///
    /// This method does not introduce a dependency the way that the more
    /// typical [dependOnInheritedWidgetOfExactType] does, so this context will
    /// not be rebuilt if the [InheritedWidget] changes. This function is meant
    /// for those uncommon use cases where a dependency is undesirable.
    ///
    /// This method should not be called from [State.dispose] because the
    /// element tree is no longer stable at that time. To refer to an ancestor
    /// from that method, save a reference to the ancestor in
    /// [State.didChangeDependencies]. It is safe to use this method from
    /// [State.deactivate], which is called whenever the widget is removed from
    /// the tree.
    ///
    /// It is also possible to call this method from interaction event handlers
    /// (e.g. gesture callbacks) or timers, to obtain a value once, as long as
    /// that value is not cached and/or reused later.
    ///
    /// Calling this method is O(1) with a small constant factor.
    func getInheritedWidgetOfExactType<T: InheritedWidget>(_ type: T.Type) -> T?

    /// Obtains the element corresponding to the nearest widget of the given
    /// type `T`, which must be the type of a concrete [InheritedWidget]
    /// subclass.
    ///
    /// Returns null if no such element is found.
    ///
    /// Calling this method is O(1) with a small constant factor.
    ///
    /// This method does not establish a relationship with the target in the way
    /// that [dependOnInheritedWidgetOfExactType] does.
    ///
    /// This method should not be called from [State.dispose] because the
    /// element tree is no longer stable at that time. To refer to an ancestor
    /// from that method, save a reference to the ancestor by calling
    /// [dependOnInheritedWidgetOfExactType] in [State.didChangeDependencies].
    /// It is safe to use this method from [State.deactivate], which is called
    /// whenever the widget is removed from the tree.
    func getElementForInheritedWidgetOfExactType(_ type: AnyObject.Type)
        -> InheritedElement?

    /// Returns the nearest ancestor widget of the given type `T`, which must be the
    /// type of a concrete [Widget] subclass.
    ///
    /// In general, [dependOnInheritedWidgetOfExactType] is more useful, since
    /// inherited widgets will trigger consumers to rebuild when they change. This
    /// method is appropriate when used in interaction event handlers (e.g.
    /// gesture callbacks) or for performing one-off tasks such as asserting that
    /// you have or don't have a widget of a specific type as an ancestor. The
    /// return value of a Widget's build method should not depend on the value
    /// returned by this method, because the build context will not rebuild if the
    /// return value of this method changes. This could lead to a situation where
    /// data used in the build method changes, but the widget is not rebuilt.
    ///
    /// Calling this method is relatively expensive (O(N) in the depth of the
    /// tree). Only call this method if the distance from this widget to the
    /// desired ancestor is known to be small and bounded.
    ///
    /// This method should not be called from [State.deactivate] or [State.dispose]
    /// because the widget tree is no longer stable at that time. To refer to
    /// an ancestor from one of those methods, save a reference to the ancestor
    /// by calling [findAncestorWidgetOfExactType] in [State.didChangeDependencies].
    ///
    /// Returns null if a widget of the requested type does not appear in the
    /// ancestors of this context.
    // func findAncestorWidgetOfExactType<T: Widget>(_ type: T.Type) -> T?

    /// Returns the [State] object of the nearest ancestor [StatefulWidget] widget
    /// that is an instance of the given type `T`.
    ///
    /// This should not be used from build methods, because the build context will
    /// not be rebuilt if the value that would be returned by this method changes.
    /// In general, [dependOnInheritedWidgetOfExactType] is more appropriate for such
    /// cases. This method is useful for changing the state of an ancestor widget in
    /// a one-off manner, for example, to cause an ancestor scrolling list to
    /// scroll this build context's widget into view, or to move the focus in
    /// response to user interaction.
    ///
    /// In general, though, consider using a callback that triggers a stateful
    /// change in the ancestor rather than using the imperative style implied by
    /// this method. This will usually lead to more maintainable and reusable code
    /// since it decouples widgets from each other.
    ///
    /// Calling this method is relatively expensive (O(N) in the depth of the
    /// tree). Only call this method if the distance from this widget to the
    /// desired ancestor is known to be small and bounded.
    ///
    /// This method should not be called from [State.deactivate] or [State.dispose]
    /// because the widget tree is no longer stable at that time. To refer to
    /// an ancestor from one of those methods, save a reference to the ancestor
    /// by calling [findAncestorStateOfType] in [State.didChangeDependencies].
    // func findAncestorStateOfType<T: StateProtocol>(_ type: T.Type) -> T?

    /// Returns the [State] object of the furthest ancestor [StatefulWidget] widget
    /// that is an instance of the given type `T`.
    ///
    /// Functions the same way as [findAncestorStateOfType] but keeps visiting subsequent
    /// ancestors until there are none of the type instance of `T` remaining.
    /// Then returns the last one found.
    ///
    /// This operation is O(N) as well though N is the entire widget tree rather than
    /// a subtree.
    // func findRootAncestorStateOfType<T: StateProtocol>(_ type: T.Type) -> T?

    /// Returns the [RenderObject] object of the nearest ancestor [RenderObjectWidget] widget
    /// that is an instance of the given type `T`.
    ///
    /// This should not be used from build methods, because the build context will
    /// not be rebuilt if the value that would be returned by this method changes.
    /// In general, [dependOnInheritedWidgetOfExactType] is more appropriate for such
    /// cases. This method is useful only in esoteric cases where a widget needs
    /// to cause an ancestor to change its layout or paint behavior. For example,
    /// it is used by [Material] so that [InkWell] widgets can trigger the ink
    /// splash on the [Material]'s actual render object.
    ///
    /// Calling this method is relatively expensive (O(N) in the depth of the
    /// tree). Only call this method if the distance from this widget to the
    /// desired ancestor is known to be small and bounded.
    ///
    /// This method should not be called from [State.deactivate] or [State.dispose]
    /// because the widget tree is no longer stable at that time. To refer to
    /// an ancestor from one of those methods, save a reference to the ancestor
    /// by calling [findAncestorRenderObjectOfType] in [State.didChangeDependencies].
    // func findAncestorRenderObjectOfType<T: RenderObject>(_ type: T.Type) -> T?

    /// Walks the ancestor chain, starting with the parent of this build context's
    /// widget, invoking the argument for each ancestor.
    ///
    /// The callback is given a reference to the ancestor widget's corresponding
    /// [Element] object. The walk stops when it reaches the root widget or when
    /// the callback returns false. The callback must not return null.
    ///
    /// This is useful for inspecting the widget tree.
    ///
    /// Calling this method is relatively expensive (O(N) in the depth of the tree).
    ///
    /// This method should not be called from [State.deactivate] or [State.dispose]
    /// because the element tree is no longer stable at that time. To refer to
    /// an ancestor from one of those methods, save a reference to the ancestor
    /// by calling [visitAncestorElements] in [State.didChangeDependencies].
    func visitAncestorElements(_ visitor: (Element) -> Bool)

    /// Walks the children of this widget.
    ///
    /// {@template flutter.widgets.BuildContext.visitChildElements}
    /// This is useful for applying changes to children after they are built
    /// without waiting for the next frame, especially if the children are known,
    /// and especially if there is exactly one child (as is always the case for
    /// [StatefulWidget]s or [StatelessWidget]s).
    ///
    /// Calling this method is very cheap for build contexts that correspond to
    /// [StatefulWidget]s or [StatelessWidget]s (O(1), since there's only one
    /// child).
    ///
    /// Calling this method is potentially expensive for build contexts that
    /// correspond to [RenderObjectWidget]s (O(N) in the number of children).
    ///
    /// Calling this method recursively is extremely expensive (O(N) in the number
    /// of descendants), and should be avoided if possible. Generally it is
    /// significantly cheaper to use an [InheritedWidget] and have the descendants
    /// pull data down, than it is to use [visitChildElements] recursively to push
    /// data down to them.
    /// {@endtemplate}
    func visitChildElements(_ visitor: (Element) -> Void)

    /// Start bubbling this notification at the given build context.
    ///
    /// The notification will be delivered to any [NotificationListener] widgets
    /// with the appropriate type parameters that are ancestors of the given
    /// [BuildContext].
    // func dispatchNotification(_ notification: Notification)

    /// Returns a description of the [Element] associated with the current build context.
    ///
    /// The `name` is typically something like "The element being rebuilt was".
    ///
    /// See also:
    ///
    ///  * [Element.describeElements], which can be used to describe a list of elements.
    //   DiagnosticsNode describeElement(String name, {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty});

    /// Returns a description of the [Widget] associated with the current build context.
    ///
    /// The `name` is typically something like "The widget being rebuilt was".
    //   DiagnosticsNode describeWidget(String name, {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty});

    /// Adds a description of a specific type of widget missing from the current
    /// build context's ancestry tree.
    ///
    /// You can find an example of using this method in [debugCheckHasMaterial].
    //   List<DiagnosticsNode> describeMissingAncestor({ required Type expectedAncestorType });

    /// Adds a description of the ownership chain from a specific [Element]
    /// to the error report.
    ///
    /// The ownership chain is useful for debugging the source of an element.
    //   DiagnosticsNode describeOwnershipChain(String name);
}

extension BuildContext {
    /// A shortcut for calling [dependOnInheritedWidgetOfExactType] with no
    /// aspect.
    public func dependOnInheritedWidgetOfExactType<T: InheritedWidget>(_ type: T.Type) -> T? {
        return dependOnInheritedWidgetOfExactType(type, aspect: nil)
    }

    /// Obtains the nearest [InheritedWidget] ancestor and establishes a dependency on it.
    ///
    /// This method is a shorthand for calling `dependOnInheritedElement(_:aspect:)` with a `nil` aspect.
    public func dependOnInheritedElement(_ ancestor: InheritedElement) -> any InheritedWidget {
        return dependOnInheritedElement(ancestor, aspect: nil)
    }
}

/// A widget that does not require mutable state.
///
/// A stateless widget is a widget that describes part of the user interface by
/// building a constellation of other widgets that describe the user interface
/// more concretely. The building process continues recursively until the
/// description of the user interface is fully concrete (e.g., consists
/// entirely of [RenderObjectWidget]s, which describe concrete [RenderObject]s).
public protocol StatelessWidget: Widget {
    /// Describes the part of the user interface represented by this widget.
    ///
    /// The framework calls this method when this widget is inserted into the tree
    /// in a given [BuildContext] and when the dependencies of this widget change
    /// (e.g., an [InheritedWidget] referenced by this widget changes). This
    /// method can potentially be called in every frame and should not have any side
    /// effects beyond building a widget.
    ///
    /// The framework replaces the subtree below this widget with the widget
    /// returned by this method, either by updating the existing subtree or by
    /// removing the subtree and inflating a new subtree, depending on whether the
    /// widget returned by this method can update the root of the existing
    /// subtree, as determined by calling [Widget.canUpdate].
    func build(context: BuildContext) -> Widget
}

extension StatelessWidget {
    /// Creates a [StatelessElement] to manage this widget's location in the tree.
    ///
    /// It is uncommon for subclasses to override this method.
    public func createElement() -> Element {
        StatelessElement(self)
    }
}

/// A widget that has mutable state.
///
/// State is information that (1) can be read synchronously when the widget is
/// built and (2) might change during the lifetime of the widget. It is the
/// responsibility of the widget implementer to ensure that the [State] is
/// promptly notified when such state changes, using [State.setState].
///
/// A stateful widget is a widget that describes part of the user interface by
/// building a constellation of other widgets that describe the user interface
/// more concretely. The building process continues recursively until the
/// description of the user interface is fully concrete (e.g., consists
/// entirely of [RenderObjectWidget]s, which describe concrete [RenderObject]s).
///
/// Stateful widgets are useful when the part of the user interface you are
/// describing can change dynamically, e.g. due to having an internal
/// clock-driven state, or depending on some system state. For compositions that
/// depend only on the configuration information in the object itself and the
/// [BuildContext] in which the widget is inflated, consider using
/// [StatelessWidget].
public protocol StatefulWidget: Widget {
    associatedtype StateType: State<Self>

    /// Creates the mutable state for this widget at a given location in the tree.
    ///
    /// Subclasses should override this method to return a newly created
    /// instance of their associated [State] subclass:
    ///
    /// ```swift
    /// override func createState() -> StateType
    /// ```
    ///
    /// The framework can call this method multiple times over the lifetime of
    /// a [StatefulWidget]. For example, if the widget is inserted into the tree
    /// in multiple locations, the framework will create a separate [State] object
    /// for each location. Similarly, if the widget is removed from the tree and
    /// later inserted into the tree again, the framework will call [createState]
    /// again to create a fresh [State] object, simplifying the lifecycle of
    /// [State] objects.
    func createState() -> StateType
}

extension StatefulWidget {
    /// Creates a [StatefulElement] to manage this widget's location in the tree.
    ///
    /// It is uncommon for subclasses to override this method.
    public func createElement() -> Element {
        StatefulElement<Self>(self)
    }
}

public protocol StateProtocol {
    associatedtype WidgetType: StatefulWidget

    var context: BuildContext { get }
}

open class State<WidgetType: StatefulWidget>: StateProtocol {
    required public init() {}

    /// The current configuration.
    ///
    /// A [State] object's configuration is the corresponding [StatefulWidget]
    /// instance. This property is initialized by the framework before calling
    /// [initState]. If the parent updates this location in the tree to a new
    /// widget with the same [runtimeType] and [Widget.key] as the current
    /// configuration, the framework will update this property to refer to the new
    /// widget and then call [didUpdateWidget], passing the old configuration as
    /// an argument.
    public fileprivate(set) var widget: WidgetType!

    /// The location in the tree where this widget builds.
    ///
    /// The framework associates [State] objects with a [BuildContext] after
    /// creating them with [StatefulWidget.createState] and before calling
    /// [initState]. The association is permanent: the [State] object will never
    /// change its [BuildContext]. However, the [BuildContext] itself can be moved
    /// around the tree.
    ///
    /// After calling [dispose], the framework severs the [State] object's
    /// connection with the [BuildContext].
    public var context: BuildContext {
        assert(
            element != nil,
            "This widget has been unmounted, so the State no longer has a context (and should be considered defunct). \n"
                + "Consider canceling any active work during \"dispose\" or using the \"mounted\" getter to determine if the State is still active."
        )
        return element!
    }
    fileprivate weak var element: Element?

    /// Whether this [State] object is currently in a tree.
    ///
    /// After creating a [State] object and before calling [initState], the
    /// framework "mounts" the [State] object by associating it with a
    /// [BuildContext]. The [State] object remains mounted until the framework
    /// calls [dispose], after which time the framework will never ask the [State]
    /// object to [build] again.
    ///
    /// It is an error to call [setState] unless [mounted] is true.
    var mounted: Bool { element != nil }

    /// Notify the framework that the internal state of this object has changed.
    ///
    /// Whenever you change the internal state of a [State] object, make the
    /// change in a function that you pass to [setState]:
    ///
    /// ```swift
    /// setState { _myState = newValue }
    /// ```
    ///
    /// The provided callback is immediately called synchronously. It must not
    /// return a future (the callback cannot be `async`), since then it would be
    /// unclear when the state was actually being set.
    public func setState(_ fn: () -> Void) {
        assert(
            debugLifecycleState != .defunct,
            "setState() called after dispose(): \(self)"
        )
        assert(
            (debugLifecycleState != .created) || mounted,
            "setState() called in constructor: \(self)"
        )
        fn()
        element!.markNeedsBuild()
    }

    /// Describes the part of the user interface represented by this widget.
    ///
    /// The framework calls this method in a number of different situations. For
    /// example:
    ///
    ///  * After calling [initState].
    ///  * After calling [didUpdateWidget].
    ///  * After receiving a call to [setState].
    ///  * After a dependency of this [State] object changes (e.g., an
    ///    [InheritedWidget] referenced by the previous [build] changes).
    ///  * After calling [deactivate] and then reinserting the [State] object into
    ///    the tree at another location.
    ///
    /// This method can potentially be called in every frame and should not have
    /// any side effects beyond building a widget.
    ///
    /// The framework replaces the subtree below this widget with the widget
    /// returned by this method, either by updating the existing subtree or by
    /// removing the subtree and inflating a new subtree, depending on whether the
    /// widget returned by this method can update the root of the existing
    /// subtree, as determined by calling [Widget.canUpdate].
    open func build(context: BuildContext) -> Widget {
        fatalError("Subclasses must override build")
    }

    // MARK: - Lifecycle

    private var mixins = [StateMixin]()

    public func registerMixin(_ mixin: StateMixin) {
        mixins.append(mixin)
    }

    /// Called when this object is inserted into the tree.
    ///
    /// The framework will call this method exactly once for each [State] object
    /// it creates.
    ///
    /// Override this method to perform initialization that depends on the
    /// location at which this object was inserted into the tree (i.e., [context])
    /// or on the widget used to configure this object (i.e., [widget]).
    open func initState() {
        assert(debugLifecycleState == StateLifecycle.created)
        for mixin in mixins {
            mixin.initState()
        }
    }

    /// Called whenever the widget configuration changes.
    ///
    /// If the parent widget rebuilds and requests that this location in the tree
    /// update to display a new widget with the same [runtimeType] and
    /// [Widget.key], the framework will update the [widget] property of this
    /// [State] object to refer to the new widget and then call this method
    /// with the previous widget as an argument.
    ///
    /// Override this method to respond when the [widget] changes (e.g., to start
    /// implicit animations).
    ///
    /// The framework always calls [build] after calling [didUpdateWidget], which
    /// means any calls to [setState] in [didUpdateWidget] are redundant.
    open func didUpdateWidget(_ oldWidget: WidgetType) {
        for mixin in mixins {
            mixin.didUpdateWidget(oldWidget)
        }
    }

    /// Called when a dependency of this [State] object changes.
    ///
    /// For example, if the previous call to [build] referenced an
    /// [InheritedWidget] that later changed, the framework would call this
    /// method to notify this object about the change.
    ///
    /// This method is also called immediately after [initState]. It is safe to
    /// call [BuildContext.dependOnInheritedWidgetOfExactType] from this method.
    ///
    /// Subclasses rarely override this method because the framework always
    /// calls [build] after a dependency changes. Some subclasses do override
    /// this method because they need to do some expensive work (e.g., network
    /// fetches) when their dependencies change, and that work would be too
    /// expensive to do for every build.
    open func didChangeDependencies() {
        for mixin in mixins {
            mixin.didChangeDependencies()
        }
    }

    /// Called when this object is removed from the tree.
    ///
    /// The framework calls this method whenever it removes this [State] object
    /// from the tree. In some cases, the framework will reinsert the [State]
    /// object into another part of the tree (e.g., if the subtree containing this
    /// [State] object is grafted from one location in the tree to another due to
    /// the use of a [GlobalKey]). If that happens, the framework will call
    /// [activate] to give the [State] object a chance to reacquire any resources
    /// that it released in [deactivate]. It will then also call [build] to give
    /// the [State] object a chance to adapt to its new location in the tree. If
    /// the framework does reinsert this subtree, it will do so before the end of
    /// the animation frame in which the subtree was removed from the tree. For
    /// this reason, [State] objects can defer releasing most resources until the
    /// framework calls their [dispose] method.
    ///
    /// Subclasses should override this method to clean up any links between
    /// this object and other elements in the tree (e.g. if you have provided an
    /// ancestor with a pointer to a descendant's [RenderObject]).
    ///
    /// Implementations of this method should end with a call to the inherited
    /// method, as in `super.deactivate()`.
    open func deactivate() {
        for mixin in mixins {
            mixin.deactivate()
        }
    }

    /// Called when this object is reinserted into the tree after having been
    /// removed via [deactivate].
    ///
    /// In most cases, after a [State] object has been deactivated, it is _not_
    /// reinserted into the tree, and its [dispose] method will be called to
    /// signal that it is ready to be garbage collected.
    ///
    /// In some cases, however, after a [State] object has been deactivated, the
    /// framework will reinsert it into another part of the tree (e.g., if the
    /// subtree containing this [State] object is grafted from one location in
    /// the tree to another due to the use of a [GlobalKey]). If that happens,
    /// the framework will call [activate] to give the [State] object a chance to
    /// reacquire any resources that it released in [deactivate]. It will then
    /// also call [build] to give the object a chance to adapt to its new
    /// location in the tree. If the framework does reinsert this subtree, it
    /// will do so before the end of the animation frame in which the subtree was
    /// removed from the tree. For this reason, [State] objects can defer
    /// releasing most resources until the framework calls their [dispose] method.
    ///
    /// The framework does not call this method the first time a [State] object
    /// is inserted into the tree. Instead, the framework calls [initState] in
    /// that situation.
    ///
    /// Implementations of this method should start with a call to the inherited
    /// method, as in `super.activate()`.
    open func activate() {
        for mixin in mixins {
            mixin.activate()
        }
    }

    /// Called when this object is removed from the tree permanently.
    ///
    /// The framework calls this method when this [State] object will never
    /// build again. After the framework calls [dispose], the [State] object is
    /// considered unmounted and the [mounted] property is false. It is an error
    /// to call [setState] at this point. This stage of the lifecycle is terminal:
    /// there is no way to remount a [State] object that has been disposed.
    ///
    /// Subclasses should override this method to release any resources retained
    /// by this object (e.g., stop any active animations).
    ///
    /// Implementations of this method should end with a call to the inherited
    /// method, as in `super.dispose()`.
    open func dispose() {
        assert(debugLifecycleState == .ready)
        assert {
            debugLifecycleState = StateLifecycle.defunct
            return true
        }
        for mixin in mixins {
            mixin.dispose()
        }
    }

    // MARK: - Debugging

    /// The current stage in the lifecycle for this state object.
    ///
    /// This field is used by the framework when asserts are enabled to verify
    /// that [State] objects move through their lifecycle in an orderly fashion.
    fileprivate var debugLifecycleState = StateLifecycle.created
}

/// A mixin can listen to the lifecycle of a [State] object to provide
/// additional functionality.
public protocol StateMixin {
    init()

    /// Lifecycle method called when the [State] object is created.
    func initState()

    /// Lifecycle method called when configuration of the widget changes.
    func didUpdateWidget(_ oldWidget: Widget)

    /// Lifecycle method called when the [State] object's dependencies change.
    func didChangeDependencies()

    /// Lifecycle method called when the [State] object is removed from the
    /// tree.
    func deactivate()

    /// Lifecycle method called when the [State] object is reinserted into the
    /// tree.
    func activate()

    /// Lifecycle method called when the [State] object is permanently removed
    /// from the tree.
    func dispose()
}

/// Tracks the lifecycle of [State] objects when asserts are enabled.
private enum StateLifecycle {
    /// The [State] object has been created. [State.initState] is called at this
    /// time.
    case created

    /// The [State.initState] method has been called but the [State] object is
    /// not yet ready to build. [State.didChangeDependencies] is called at this time.
    case initialized

    /// The [State] object is ready to build and [State.dispose] has not yet been
    /// called.
    case ready

    /// The [State.dispose] method has been called and the [State] object is
    /// no longer able to build.
    case defunct
}

/// A widget that has a child widget provided to it, instead of building a new
/// widget.
///
/// Useful as a base class for other widgets, such as [InheritedWidget] and
/// [ParentDataWidget].
public protocol ProxyWidget: Widget {
    /// The widget below this widget in the tree.
    ///
    /// This widget can only have one child. To lay out multiple children, let
    /// this widget's child be a widget such as [Row], [Column], or [Stack],
    /// which have a `children` property, and then provide the children to that
    /// widget.
    var child: Widget { get }
}

/// Base class for widgets that hook [ParentData] information to children of
/// [RenderObjectWidget]s.
///
/// This can be used to provide per-child configuration for
/// [RenderObjectWidget]s with more than one child. For example, [Stack] uses
/// the [Positioned] parent data widget to position each child.
///
/// A [ParentDataWidget] is specific to a particular kind of [ParentData]. That
/// class is `T`, the [ParentData] type argument.
public protocol ParentDataWidget: ProxyWidget {
    // associatedtype ParentDataType: ParentData
    // associatedtype RenderObjectType: RenderObject

    /// Write the data from this widget into the given render object's parent data.
    ///
    /// The framework calls this function whenever it detects that the
    /// [RenderObject] associated with the [child] has outdated
    /// [RenderObject.parentData]. For example, if the render object was recently
    /// inserted into the render tree, the render object's parent data might not
    /// match the data in this widget.
    ///
    /// Subclasses are expected to override this function to copy data from their
    /// fields into the [RenderObject.parentData] field of the given render
    /// object. The render object's parent is guaranteed to have been created by a
    /// widget of type `T`, which usually means that this function can assume that
    /// the render object's parent data object inherits from a particular class.
    ///
    /// If this function modifies data that can change the parent's layout or
    /// painting, this function is responsible for calling
    /// [RenderObject.markNeedsLayout] or [RenderObject.markNeedsPaint] on the
    /// parent, as appropriate.
    func applyParentData(_ renderObject: RenderObject)
}

extension ParentDataWidget {
    public func createElement() -> Element {
        ParentDataElement(self)
    }
}

/// Base class for widgets that efficiently propagate information down the tree.
///
/// To obtain the nearest instance of a particular type of inherited widget from
/// a build context, use [BuildContext.dependOnInheritedWidgetOfExactType].
///
/// Inherited widgets, when referenced in this way, will cause the consumer to
/// rebuild when the inherited widget itself changes state.
public protocol InheritedWidget: ProxyWidget {
    /// Whether the framework should notify widgets that inherit from this widget.
    ///
    /// When this widget is rebuilt, sometimes we need to rebuild the widgets that
    /// inherit from this widget but sometimes we do not. For example, if the data
    /// held by this widget is the same as the data held by `oldWidget`, then we
    /// do not need to rebuild the widgets that inherited the data held by
    /// `oldWidget`.
    ///
    /// The framework distinguishes these cases by calling this function with the
    /// widget that previously occupied this location in the tree as an argument.
    /// The given widget is guaranteed to have the same [runtimeType] as this
    /// object.
    func updateShouldNotify(_ oldWidget: Self) -> Bool
}

extension InheritedWidget {
    public func createElement() -> Element {
        InheritedElement(self)
    }

    /// The widget from the closest instance of this class that encloses the
    /// given context, or null if none is found.
    public static func maybeOf(_ context: BuildContext) -> Self? {
        context.dependOnInheritedWidgetOfExactType(Self.self)
    }
}

public protocol RenderObjectWidget: Widget {
    associatedtype RenderObjectType: RenderObject

    /// Creates an instance of the [RenderObject] class that this
    /// [RenderObjectWidget] represents, using the configuration described by this
    /// [RenderObjectWidget].
    func createRenderObject(context: BuildContext) -> RenderObjectType

    /// Copies the configuration described by this [RenderObjectWidget] to the
    /// given [RenderObject], which will be of the same type as returned by this
    /// object's [createRenderObject].
    func updateRenderObject(context: BuildContext, renderObject: RenderObjectType)

    /// A render object previously associated with this widget has been removed
    /// from the tree. The given [RenderObject] will be of the same type as
    /// returned by this object's [createRenderObject].
    func didUnmountRenderObject(renderObject: RenderObjectType)
}

extension RenderObjectWidget {
    public func updateRenderObject(context: BuildContext, renderObject: RenderObjectType) {
        // no-op by default
    }

    public func didUnmountRenderObject(renderObject: RenderObjectType) {
        // no-op by default
    }
}

/// A superclass for [RenderObjectWidget]s that configure [RenderObject] subclasses
/// that have no children.
///
/// Subclasses must implement [createRenderObject] and [updateRenderObject].
public protocol LeafRenderObjectWidget: RenderObjectWidget {}

extension LeafRenderObjectWidget {
    public func createElement() -> Element {
        LeafRenderObjectElement(self)
    }

    public func debugDescribeChildren() -> [DiagnosticableTree] {
        return []
    }
}

/// A superclass for [RenderObjectWidget]s that configure [RenderObject] subclasses
/// that have a single child slot.
///
/// The render object assigned to this widget should make use of
/// [RenderObjectWithChildMixin] to implement a single-child model. The mixin
/// exposes a [RenderObjectWithChildMixin.child] property that allows retrieving
/// the render object belonging to the [child] widget.
///
/// Subclasses must implement [createRenderObject] and [updateRenderObject].
public protocol SingleChildRenderObjectWidget: RenderObjectWidget {
    /// The widget below this widget in the tree.
    var child: Widget? { get }
}

extension SingleChildRenderObjectWidget {
    public func createElement() -> Element {
        SingleChildRenderObjectElement(self)
    }
}

/// A superclass for [RenderObjectWidget]s that configure [RenderObject] subclasses
/// that have a single list of children. (This superclass only provides the
/// storage for that child list, it doesn't actually provide the updating
/// logic.)
///
/// Subclasses must use a [RenderObject] that mixes in
/// [ContainerRenderObjectMixin], which provides the necessary functionality to
/// visit the children of the container render object (the render object
/// belonging to the [children] widgets). Typically, subclasses will use a
/// [RenderBox] that mixes in both [ContainerRenderObjectMixin] and
/// [RenderBoxContainerDefaultsMixin].
///
/// Subclasses must implement [createRenderObject] and [updateRenderObject].
public protocol MultiChildRenderObjectWidget: RenderObjectWidget {
    /// The widgets below this widget in the tree.
    ///
    /// If this list is going to be mutated, it is usually wise to put a [Key] on
    /// each of the child widgets, so that the framework can match old
    /// configurations to new configurations and maintain the underlying render
    /// objects.
    ///
    /// Also, a [Widget] in Flutter is immutable, so directly modifying the
    /// [children] such as `someMultiChildRenderObjectWidget.children.add(...)` or
    /// as the example code below will result in incorrect behaviors. Whenever the
    /// children list is modified, a new list object should be provided.
    var children: [Widget] { get }
}

extension MultiChildRenderObjectWidget {
    public func createElement() -> Element {
        MultiChildRenderObjectElement(self)
    }
}

/// Manager class for the widgets framework.
///
/// This class tracks which widgets need rebuilding, and handles other tasks
/// that apply to widget trees as a whole, such as managing the inactive element
/// list for the tree and triggering the "reassemble" command when necessary
/// during hot reload when debugging.
///
/// The main build owner is typically owned by the [WidgetsBinding], and is
/// driven from the operating system along with the rest of the
/// build/layout/paint pipeline.
///
/// Additional build owners can be built to manage off-screen widget trees.
///
/// To assign a build owner to a tree, use the [RootElementMixin.assignOwner]
/// method on the root element of the widget tree.
public class BuildOwner {
    /// Called on each build pass when the first buildable element is marked
    /// dirty.
    let onBuildScheduled: VoidCallback?

    init(onBuildScheduled: VoidCallback? = nil) {
        self.onBuildScheduled = onBuildScheduled
        focusManager.registerGlobalHandlers()
    }

    private var dirtyElements = [Element]()
    private var scheduledFlushDirtyElements = false

    /// Whether [_dirtyElements] need to be sorted again as a result of more
    /// elements becoming dirty during the build.
    ///
    /// This is necessary to preserve the sort order defined by [Element._sort].
    ///
    /// This field is set to null when [buildScope] is not actively rebuilding
    /// the widget tree.
    private var dirtyElementsNeedsResorting: Bool?

    /// Whether [buildScope] is actively rebuilding the widget tree.
    ///
    /// [scheduleBuildFor] should only be called when this value is true.
    private var debugIsInBuildScope: Bool { dirtyElementsNeedsResorting != nil }

    /// The object in charge of the focus tree.
    ///
    /// Rarely used directly. Instead, consider using [FocusScope.of] to obtain
    /// the [FocusScopeNode] for a given [BuildContext].
    ///
    /// See [FocusManager] for more details.
    ///
    /// This field will default to a [FocusManager] that has registered its
    /// global input handlers via [FocusManager.registerGlobalHandlers]. Callers
    /// wishing to avoid registering those handlers (and modifying the
    /// associated static state) can explicitly pass a focus manager to the
    /// [BuildOwner.new] constructor.
    public let focusManager = FocusManager()

    /// Whether this widget tree is in the build phase.
    ///
    /// Only valid when asserts are enabled.
    public private(set) var debugBuilding: Bool = false

    /// Adds an element to the dirty elements list so that it will be rebuilt
    /// when [WidgetsBinding.drawFrame] calls [buildScope].
    func scheduleBuildFor(_ element: Element) {
        assert(element.owner === self)
        assert(element.dirty)
        if element.inDirtyList {
            dirtyElementsNeedsResorting = true
        }
        if !scheduledFlushDirtyElements, let onBuildScheduled {
            scheduledFlushDirtyElements = true
            onBuildScheduled()
        }
        dirtyElements.append(element)
        element.inDirtyList = true
    }

    /// Establishes a scope for updating the widget tree, and calls the given
    /// `callback`, if any. Then, builds all the elements that were marked as
    /// dirty using [scheduleBuildFor], in depth order.
    ///
    /// This mechanism prevents build methods from transitively requiring other
    /// build methods to run, potentially causing infinite loops.
    func buildScope(_ context: Element, _ callback: VoidCallback? = nil) {
        if callback == nil && dirtyElements.isEmpty {
            return
        }
        assert(debugStateLockLevel >= 0)
        assert(!debugBuilding)
        assert {
            debugStateLockLevel += 1
            debugBuilding = true
            return true
        }

        scheduledFlushDirtyElements = true
        if callback != nil {
            assert(debugStateLocked)
            dirtyElementsNeedsResorting = false
            callback!()
        }

        dirtyElements.sort(by: Element.sort)
        dirtyElementsNeedsResorting = false

        var dirtyCount = dirtyElements.count
        var index = 0
        while index < dirtyCount {
            let element = dirtyElements[index]
            element.rebuild()

            index += 1
            if dirtyCount < dirtyElements.count || dirtyElementsNeedsResorting! {
                dirtyElements.sort(by: Element.sort)
                dirtyElementsNeedsResorting = false
                dirtyCount = dirtyElements.count
                while index > 0 && dirtyElements[index - 1].dirty {
                    index -= 1
                }
            }
        }

        for element in dirtyElements {
            element.inDirtyList = false
        }
        dirtyElements.removeAll()
        dirtyElementsNeedsResorting = false
        scheduledFlushDirtyElements = false

        assert(debugBuilding)
        assert {
            debugStateLockLevel -= 1
            debugBuilding = false
            return true
        }
        assert(debugStateLockLevel >= 0)
    }

    fileprivate var inactiveElements = InactiveElements()

    /// Complete the element build pass by unmounting any elements that are no
    /// longer active.
    ///
    /// This is called by [WidgetsBinding.drawFrame].
    func finalizeTree() {
        lockState {
            inactiveElements.unmountAll()  // this unregisters the GlobalKeys
        }
    }

    // MARK: - Global Key

    /// Keeps track of elements that have been given global keys.
    public private(set) var globalKeyRegistry = [AnyHashable: Element]()

    /// The number of [GlobalKey] instances that are currently associated with
    /// [Element]s that have been built by this build owner.
    public var globalKeyCount: Int { globalKeyRegistry.count }

    fileprivate func registerGlobalKey(key: GlobalKey, element: Element) {
        assert(globalKeyRegistry[key] == nil)
        globalKeyRegistry[key] = element
    }

    fileprivate func unregisterGlobalKey(key: GlobalKey, element: Element) {
        assert(globalKeyRegistry[key] === element)
        globalKeyRegistry.removeValue(forKey: key)
    }

    // MARK: - Lock State

    private var debugStateLockLevel = 0
    var debugStateLocked: Bool { debugStateLockLevel > 0 }

    /// Establishes a scope in which calls to [State.setState] are forbidden, and
    /// calls the given `callback`.
    ///
    /// This mechanism is used to ensure that, for instance, [State.dispose] does
    /// not call [State.setState].
    func lockState(_ callback: VoidCallback) {
        assert(debugStateLockLevel >= 0)
        assert {
            debugStateLockLevel += 1
            return true
        }
        callback()
        assert {
            debugStateLockLevel -= 1
            return true
        }
        assert(debugStateLockLevel >= 0)

    }
}

/// Set-like collection of [Element]s with additional logic to handle the
/// element lifecycle.
private struct InactiveElements {
    private var locked = false
    private var elements = Set<Element>()

    private func unmount(_ element: Element) {
        assert(element.lifecycleState == .inactive)
        element.visitChildren { child in
            assert(child.parent === element)
            unmount(child)
        }
        element.unmount()
        assert(element.lifecycleState == .defunct)
    }

    fileprivate mutating func unmountAll() {
        locked = true
        let elements = self.elements.sorted(by: Element.sort)
        self.elements.removeAll()
        for element in elements.reversed() {
            unmount(element)
        }
        assert(self.elements.isEmpty)
        locked = false
    }

    private func deactivateRecursively(_ element: Element) {
        assert(element.lifecycleState == .active)
        element.deactivate()
        assert(element.lifecycleState == .inactive)
        element.visitChildren(deactivateRecursively)
        assert {
            element.debugDeactivated()
            return true
        }
    }

    mutating func add(_ element: Element) {
        assert(!locked)
        assert(!elements.contains(element))
        assert(element.parent == nil)
        if element.lifecycleState == .active {
            deactivateRecursively(element)
        }
        elements.insert(element)
    }

    mutating func remove(_ element: Element) {
        assert(!locked)
        assert(elements.contains(element))
        assert(element.parent == nil)
        elements.remove(element)
        assert(element.lifecycleState != ElementLifecycle.active)
    }
}

enum ElementLifecycle {
    case initial
    case active
    case inactive
    case defunct
}

/// Signature for the callback to [BuildContext.visitChildElements].
///
/// The argument is the child being visited.
///
/// It is safe to call `element.visitChildElements` reentrantly within
/// this callback.
public typealias ElementVisitor = (Element) -> Void

/// An instantiation of a [Widget] at a particular location in the tree.
///
/// Widgets describe how to configure a subtree but the same widget can be used
/// to configure multiple subtrees simultaneously because widgets are immutable.
/// An [Element] represents the use of a widget to configure a specific location
/// in the tree. Over time, the widget associated with a given element can
/// change, for example, if the parent widget rebuilds and creates a new widget
/// for this location.
public class Element: BuildContext, HashableObject, DiagnosticableTree {
    init(_ widget: Widget) {
        self.widget = widget
    }

    // This is used to verify that Element objects move through life in an
    // orderly fashion.
    var lifecycleState: ElementLifecycle = .initial

    /// The render object at (or below) this location in the tree.
    ///
    /// If this object is a [RenderObjectElement], the render object is the one at
    /// this location in the tree. Otherwise, this getter will walk down the tree
    /// until it finds a [RenderObjectElement].
    ///
    /// Some locations in the tree are not backed by a render object. In those
    /// cases, this getter returns null. This can happen, if the element is
    /// located outside of a [View] since only the element subtree rooted in a
    /// view has a render tree associated with it.
    public var renderObject: RenderObject? {
        var current: Element? = self
        while current !== nil {
            if current?.lifecycleState == .defunct {
                break
            } else if let current = current as? RenderObjectElement {
                return current._renderObject
            } else {
                current = current!.renderObjectAttachingChild
            }
        }
        return nil
    }

    public func findRenderObject() -> RenderObject? {
        assert(lifecycleState == .active, "Cannot get renderObject of inactive element.")
        return renderObject
    }

    public var size: Size? {
        assert {
            if lifecycleState != .active {
                // TODO(jacobr): is this a good separation into contract and violation?
                // I have added a line of white space.
                assertionFailure("Cannot get size of inactive element.")
            }
            if owner!.debugBuilding {
                assertionFailure("Cannot get size during build.")
            }
            return true
        }

        let renderObject = findRenderObject()
        assert {
            if renderObject == nil {
                assertionFailure("Cannot get size without a render object.")
            }
            // if renderObject is RenderSliver {
            //     assertionFailure("Cannot get size from a RenderSliver.")
            // }
            if !(renderObject is RenderBox) {
                assertionFailure("Cannot get size from a render object that is not a RenderBox.")
            }
            let box = renderObject as! RenderBox
            if !box.hasSize {
                assertionFailure(
                    "Cannot get size from a render object that has not been through layout."
                )
            }
            if box.needsLayout {
                assertionFailure(
                    "Cannot get size from a render object that has been marked dirty for layout."
                )
            }
            return true
        }

        if let renderObject = renderObject as? RenderBox {
            return renderObject.size
        }
        return nil
    }

    public func visitAncestorElements(_ visitor: (Element) -> Bool) {
        assert(debugCheckStateIsActiveForAncestorLookup())
        var ancestor: Element? = parent
        while let current = ancestor, visitor(current) {
            ancestor = current.parent
        }
    }

    /// Wrapper around [visitChildren] for [BuildContext].
    public func visitChildElements(_ visitor: ElementVisitor) {
        assert {
            if owner == nil || !owner!.debugStateLocked {
                return true
            }
            preconditionFailure(
                """
                visitChildElements() called during build.
                The BuildContext.visitChildElements() method can't be called during
                build because the child list is still being updated at that point,
                so the children might not be constructed yet, or might be old children
                that are going to be replaced.
                """
            )
        }
        visitChildren(visitor)
    }

    func debugCheckStateIsActiveForAncestorLookup() -> Bool {
        assert {
            if lifecycleState != ElementLifecycle.active {
                assertionFailure(
                    """
                    Looking up a deactivated widget's ancestor is unsafe.
                    At this point the state of the widget's element tree is no longer stable.
                    To safely refer to a widget's ancestor in its dispose() method, save a reference to the ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's didChangeDependencies() method.
                    """
                )
            }
            return true
        }
        return true
    }

    /// Returns the child of this [Element] that will insert a [RenderObject] into
    /// an ancestor of this Element to construct the render tree.
    ///
    /// Returns null if this Element doesn't have any children who need to attach
    /// a [RenderObject] to an ancestor of this [Element]. A [RenderObjectElement]
    /// will therefore return null because its children insert their
    /// [RenderObject]s into the [RenderObjectElement] itself and not into an
    /// ancestor of the [RenderObjectElement].
    ///
    /// Furthermore, this may return null for [Element]s that hoist their own
    /// independent render tree and do not extend the ancestor render tree.
    internal var renderObjectAttachingChild: Element? {
        var next: Element?
        visitChildren { child in
            assert(next == nil)  // This verifies that there's only one child.
            next = child
        }
        return next
    }

    // MARK: - Node

    /// An integer that is guaranteed to be greater than the parent's, if any.
    /// The element at the root of the tree must have a depth greater than 0.
    public private(set) var depth: Int = 0

    /// Return true if a should be sorted before b.
    static fileprivate func sort(_ a: Element, _ b: Element) -> Bool {
        let diff = a.depth - b.depth
        // If depths are not equal, return the difference.
        if diff != 0 {
            return diff < 0
        }
        // If the `dirty` values are not equal, sort with non-dirty elements being
        // less than dirty elements.
        let bDirty = b.dirty
        if a.dirty != bDirty {
            return bDirty ? true : false
        }
        // Otherwise, `depth`s and `dirty`s are equal.
        return true
    }

    /// The object that manages the lifecycle of this element.
    public fileprivate(set) var owner: BuildOwner?

    public private(set) weak var parent: Element?

    /// Information set by parent to define where this child fits in its parent's
    /// child list.
    ///
    /// A child widget's slot is determined when the parent's [updateChild] method
    /// is called to inflate the child widget. See [RenderObjectElement] for more
    /// details on slots.
    public fileprivate(set) var slot: Slot?

    /// Add this element to the tree in the given slot of the given parent.
    ///
    /// The framework calls this function when a newly created element is added to
    /// the tree for the first time. Use this method to initialize state that
    /// depends on having a parent. State that is independent of the parent can
    /// more easily be initialized in the constructor.
    ///
    /// This method transitions the element from the "initial" lifecycle state to
    /// the "active" lifecycle state.
    open func mount(_ parent: Element?, slot: Slot? = nil) {
        assert(lifecycleState == .initial)
        assert(self.parent == nil)
        assert(parent == nil || parent!.lifecycleState == .active)
        assert(self.slot == nil)

        self.parent = parent
        self.slot = slot
        lifecycleState = .active
        depth = parent != nil ? parent!.depth + 1 : 0
        if let parent {
            // Only assign ownership if the parent is non-null. If parent is null
            // (the root node), the owner should have already been assigned.
            // See RootRenderObjectElement.assignOwner().
            owner = parent.owner
        }
        assert(owner != nil)

        if let key = widget.key as? GlobalKey {
            owner!.registerGlobalKey(key: key, element: self)
        }
        updateInheritance()
        // attachNotificationTree()
    }

    /// Transition from the "inactive" to the "defunct" lifecycle state.
    ///
    /// Called when the framework determines that an inactive element will never
    /// be reactivated. At the end of each animation frame, the framework calls
    /// [unmount] on any remaining inactive elements, preventing inactive
    /// elements from remaining inactive for longer than a single animation
    /// frame.
    ///
    /// After this function is called, the element will not be incorporated into
    /// the tree again.
    ///
    /// Any resources this element holds should be released at this point. For
    /// example, [RenderObjectElement.unmount] calls [RenderObject.dispose] and
    /// nulls out its reference to the render object.
    ///
    /// See the lifecycle documentation for [Element] for additional
    /// information.
    ///
    /// Implementations of this method should end with a call to the inherited
    /// method, as in `super.unmount()`.
    open func unmount() {
        assert(lifecycleState == .inactive)
        assert(widget !== nil)
        assert(owner !== nil)

        // Use the private property to avoid a CastError during hot reload.
        if let key = widget.key as? GlobalKey {
            owner!.unregisterGlobalKey(key: key, element: self)
        }

        // Release resources to reduce the severity of memory leaks caused by
        // defunct, but accidentally retained Elements.
        widget = nil
        dependencies = nil
        lifecycleState = .defunct
    }

    /// Transition from the "inactive" to the "active" lifecycle state.
    ///
    /// The framework calls this method when a previously deactivated element has
    /// been reincorporated into the tree. The framework does not call this method
    /// the first time an element becomes active (i.e., from the "initial"
    /// lifecycle state). Instead, the framework calls [mount] in that situation.
    ///
    /// See the lifecycle documentation for [Element] for additional information.
    ///
    /// Implementations of this method should start with a call to the inherited
    /// method, as in `super.activate()`.
    open func activate() {
        assert(lifecycleState == .inactive)
        assert(owner !== nil)
        let hadDependencies =
            dependencies != nil && !dependencies!.isEmpty || hadUnsatisfiedDependencies
        lifecycleState = .active
        // We unregistered our dependencies in deactivate, but never cleared the list.
        // Since we're going to be reused, let's clear our list now.
        dependencies?.removeAll()
        hadUnsatisfiedDependencies = false
        updateInheritance()
        if dirty {
            owner!.scheduleBuildFor(self)
        }
        if hadDependencies {
            didChangeDependencies()
        }
    }

    /// Transition from the "active" to the "inactive" lifecycle state.
    ///
    /// The framework calls this method when a previously active element is
    /// moved to the list of inactive elements. While in the inactive state, the
    /// element will not appear on screen. The element can remain in the
    /// inactive state only until the end of the current animation frame. At the
    /// end of the animation frame, if the element has not be reactivated, the
    /// framework will unmount the element.
    ///
    /// This is (indirectly) called by [deactivateChild].
    ///
    /// See the lifecycle documentation for [Element] for additional
    /// information.
    ///
    /// Implementations of this method should end with a call to the inherited
    /// method, as in `super.deactivate()`.
    open func deactivate() {
        assert(lifecycleState == .active)
        assert(widget != nil)
        if let dependencies, dependencies.isNotEmpty {
            for dependency in dependencies {
                dependency.removeDependent(self)
            }
            // For expediency, we don't actually clear the list here, even
            // though it's no longer representative of what we are registered
            // with. If we never get re-used, it doesn't matter. If we do, then
            // we'll clear the list in activate(). The benefit of this is that
            // it allows Element's activate() implementation to decide whether
            // to rebuild based on whether we had dependencies here.
        }
        inheritedElements = nil
        lifecycleState = ElementLifecycle.inactive
    }

    /// Called, in debug mode, after children have been deactivated (see [deactivate]).
    ///
    /// This method is not called in release builds.
    open func debugDeactivated() {
        assert(lifecycleState == .inactive)
    }

    /// Calls the argument for each child. Must be overridden by subclasses that
    /// support having children.
    ///
    /// There is no guaranteed order in which the children will be visited,
    /// though it should be consistent over time.
    ///
    /// Calling this during build is dangerous: the child list might still be
    /// being updated at that point, so the children might not be constructed
    /// yet, or might be old children that are going to be replaced. This method
    /// should only be called if it is provable that the children are available.
    open func visitChildren(_ visitor: (Element) -> Void) {
        assertionFailure("Subclasses of Element must implement visitChildren().")
    }

    private func activateWithParent(_ parent: Element, newSlot: Slot?) {
        assert(lifecycleState == .inactive)
        self.parent = parent
        updateDepth(parent.depth)
        Self.activateRecursively(self)
        attachRenderObject(newSlot)
        assert(lifecycleState == .active)
    }

    private static func activateRecursively(_ element: Element) {
        assert(element.lifecycleState == .inactive)
        element.activate()
        assert(element.lifecycleState == .active)
        element.visitChildren(activateRecursively)
    }

    /// Recursively updates the depth of this element and its descendants.
    private func updateDepth(_ parentDepth: Int) {
        let expectedDepth = parentDepth + 1
        if depth < expectedDepth {
            depth = expectedDepth
            visitChildren { child in
                child.updateDepth(expectedDepth)
            }
        }
    }

    /// Move the given element to the list of inactive elements and detach its
    /// render object from the render tree.
    ///
    /// This method stops the given element from being a child of this element by
    /// detaching its render object from the render tree and moving the element to
    /// the list of inactive elements.
    ///
    /// This method (indirectly) calls [deactivate] on the child.
    ///
    /// The caller is responsible for removing the child from its child model.
    /// Typically [deactivateChild] is called by the element itself while it is
    /// updating its child model; however, during [GlobalKey] reparenting, the new
    /// parent proactively calls the old parent's [deactivateChild], first using
    /// [forgetChild] to cause the old parent to update its child model.
    func deactivateChild(_ child: Element) {
        assert(child.parent === self)
        child.parent = nil
        child.detachRenderObject()
        owner!.inactiveElements.add(child)
    }

    /// Remove the given child from the element's child list, in preparation for
    /// the child being reused elsewhere in the element tree.
    ///
    /// This updates the child model such that, e.g., [visitChildren] does not
    /// walk that child anymore.
    ///
    /// The element will still have a valid parent when this is called, and the
    /// child's [Element.slot] value will be valid in the context of that
    /// parent. After this is called, [deactivateChild] is called to sever the
    /// link to this object.
    ///
    /// The [update] is responsible for updating or creating the new child that
    /// will replace this [child].
    open func forgetChild(_ child: Element) {
        // This method is called on the old parent when the given child (with a
        // global key) is given a new parent. We cannot remove the global key
        // reservation directly in this method because the forgotten child is not
        // removed from the tree until this Element is updated in [update]. If
        // [update] is never called, the forgotten child still represents a global
        // key duplication that we need to catch.
        // assert {
        //   if (child.widget.key is GlobalKey) {
        //     _debugForgottenChildrenWithGlobalKey?.add(child);
        //   }
        //   return true;
        // }
    }

    /// Add [renderObject] to the render tree at the location specified by `newSlot`.
    ///
    /// The default implementation of this function calls
    /// [attachRenderObject] recursively on each child. The
    /// [RenderObjectElement.attachRenderObject] override does the actual work of
    /// adding [renderObject] to the render tree.
    ///
    /// The `newSlot` argument specifies the new value for this element's [slot].
    open func attachRenderObject(_ newSlot: Slot?) {
        assert(slot == nil)
        visitChildren { child in
            child.attachRenderObject(newSlot)
        }
        slot = newSlot
    }

    /// Remove [renderObject] from the render tree.
    ///
    /// The default implementation of this function calls
    /// [detachRenderObject] recursively on each child. The
    /// [RenderObjectElement.detachRenderObject] override does the actual work of
    /// removing [renderObject] from the render tree.
    ///
    /// This is called by [deactivateChild].
    open func detachRenderObject() {
        visitChildren { child in
            child.detachRenderObject()
        }
        slot = nil
    }

    // MARK: - Widget

    /// The configuration for this element.
    public private(set) var widget: Widget!

    public var mounted: Bool { widget != nil }

    /// Cause the widget to update itself. In debug builds, also verify various
    /// invariants.
    ///
    /// Called by the [BuildOwner] when [BuildOwner.scheduleBuildFor] has been
    /// called to mark this element dirty, by [mount] when the element is first
    /// built, and by [update] when the widget has changed.
    ///
    /// The method will only rebuild if [dirty] is true. To rebuild regardless
    /// of the [dirty] flag, set `force` to true. Forcing a rebuild is convenient
    /// from [update], during which [dirty] is false.
    public final func rebuild(force: Bool = false) {
        assert(lifecycleState != .initial)
        if lifecycleState != .active || (!dirty && !force) {
            return
        }
        assert(lifecycleState == .active)
        performRebuild()
    }

    /// Cause the widget to update itself.
    ///
    /// Called by [rebuild] after the appropriate checks have been made.
    ///
    /// The base implementation only clears the [dirty] flag.
    open func performRebuild() {
        dirty = false
    }

    /// Change the widget used to configure this element.
    ///
    /// The framework calls this function when the parent wishes to use a
    /// different widget to configure this element. The new widget is guaranteed
    /// to have the same [runtimeType] as the old widget.
    ///
    /// This function is called only during the "active" lifecycle state.
    open func update(_ newWidget: Widget) {
        assert(lifecycleState == .active)
        assert(newWidget !== widget)
        assert(widget.canUpdate(newWidget))
        // assert {
        //     _debugForgottenChildrenWithGlobalKey?.forEach(_debugRemoveGlobalKeyReservation)
        //     _debugForgottenChildrenWithGlobalKey?.clear()
        //     return true
        // }
        widget = newWidget
    }

    /// Update the given child with the given new configuration.
    ///
    /// This method is the core of the widgets system. It is called each time we
    /// are to add, update, or remove a child based on an updated configuration.
    public func updateChild(_ child: Element?, _ newWidget: Widget?, _ newSlot: Slot? = nil)
        -> Element?
    {
        guard let newWidget = newWidget else {
            if let child {
                deactivateChild(child)
            }
            return nil
        }

        let newChild: Element

        if let child {
            if child.widget === newWidget {
                if !slotEqual(child.slot, newSlot) {
                    updateSlotForChild(child, newSlot!)
                }
                newChild = child
            } else if child.widget.canUpdate(newWidget) {
                if !slotEqual(child.slot, newSlot) {
                    updateSlotForChild(child, newSlot!)
                }
                child.update(newWidget)
                newChild = child
            } else {
                deactivateChild(child)
                newChild = inflateWidget(newWidget, newSlot)
            }
        } else {
            newChild = inflateWidget(newWidget, newSlot)
        }

        return newChild
    }

    /// Updates the children of this element to use new widgets.
    ///
    /// Attempts to update the given old children list using the given new
    /// widgets, removing obsolete elements and introducing new ones as necessary,
    /// and then returns the new child list.
    ///
    /// During this function the `oldChildren` list must not be modified. If the
    /// caller wishes to remove elements from `oldChildren` reentrantly while
    /// this function is on the stack, the caller can supply a `forgottenChildren`
    /// argument, which can be modified while this function is on the stack.
    /// Whenever this function reads from `oldChildren`, this function first
    /// checks whether the child is in `forgottenChildren`. If it is, the function
    /// acts as if the child was not in `oldChildren`.
    ///
    /// This function is a convenience wrapper around [updateChild], which updates
    /// each individual child. If `slots` is non-null, the value for the `newSlot`
    /// argument of [updateChild] is retrieved from that list using the index that
    /// the currently processed `child` corresponds to in the `newWidgets` list
    /// (`newWidgets` and `slots` must have the same length). If `slots` is null,
    /// an [IndexedSlot<Element>] is used as the value for the `newSlot` argument.
    /// In that case, [IndexedSlot.index] is set to the index that the currently
    /// processed `child` corresponds to in the `newWidgets` list and
    /// [IndexedSlot.value] is set to the [Element] of the previous widget in that
    /// list (or null if it is the first child).
    ///
    /// When the [slot] value of an [Element] changes, its
    /// associated [renderObject] needs to move to a new position in the child
    /// list of its parents. If that [RenderObject] organizes its children in a
    /// linked list (as is done by the [ContainerRenderObjectMixin]) this can
    /// be implemented by re-inserting the child [RenderObject] into the
    /// list after the [RenderObject] associated with the [Element] provided as
    /// [IndexedSlot.value] in the [slot] object.
    ///
    /// Using the previous sibling as a [slot] is not enough, though, because
    /// child [RenderObject]s are only moved around when the [slot] of their
    /// associated [RenderObjectElement]s is updated. When the order of child
    /// [Element]s is changed, some elements in the list may move to a new index
    /// but still have the same previous sibling. For example, when
    /// `[e1, e2, e3, e4]` is changed to `[e1, e3, e4, e2]` the element e4
    /// continues to have e3 as a previous sibling even though its index in the list
    /// has changed and its [RenderObject] needs to move to come before e2's
    /// [RenderObject]. In order to trigger this move, a new [slot] value needs to
    /// be assigned to its [Element] whenever its index in its
    /// parent's child list changes. Using an [IndexedSlot<Element>] achieves
    /// exactly that and also ensures that the underlying parent [RenderObject]
    /// knows where a child needs to move to in a linked list by providing its new
    /// previous sibling.
    func updateChildren(
        _ oldChildren: [Element],
        _ newWidgets: [Widget],
        forgottenChildren: Box<Set<Element>>? = nil,
        slots: [Slot?]? = nil
    )
        -> [Element]
    {
        assert(slots == nil || newWidgets.count == slots!.count)

        func replaceWithNullIfForgotten(_ child: Element) -> Element? {
            if let forgottenChildren = forgottenChildren {
                return forgottenChildren.value.contains(child) ? nil : child
            } else {
                return child
            }
        }

        func slotFor(_ newChildIndex: Int, _ previousChild: Element?) -> Slot? {
            if let slots = slots {
                return slots[newChildIndex]
            } else {
                return IndexedSlot(value: previousChild, index: newChildIndex)
            }
        }

        // This attempts to diff the new child list (newWidgets) with
        // the old child list (oldChildren), and produce a new list of elements to
        // be the new list of child elements of this element. The called of this
        // method is expected to update this render object accordingly.

        // The cases it tries to optimize for are:
        //  - the old list is empty
        //  - the lists are identical
        //  - there is an insertion or removal of one or more widgets in
        //    only one place in the list
        // If a widget with a key is in both lists, it will be synced.
        // Widgets without keys might be synced but there is no guarantee.

        // The general approach is to sync the entire new list backwards, as follows:
        // 1. Walk the lists from the top, syncing nodes, until you no longer have
        //    matching nodes.
        // 2. Walk the lists from the bottom, without syncing nodes, until you no
        //    longer have matching nodes. We'll sync these nodes at the end. We
        //    don't sync them now because we want to sync all the nodes in order
        //    from beginning to end.
        // At this point we narrowed the old and new lists to the point
        // where the nodes no longer match.
        // 3. Walk the narrowed part of the old list to get the list of
        //    keys and sync null with non-keyed items.
        // 4. Walk the narrowed part of the new list forwards:
        //     * Sync non-keyed items with null
        //     * Sync keyed items with the source if it exists, else with null.
        // 5. Walk the bottom of the list again, syncing the nodes.
        // 6. Sync null with any items in the list of keys that are still
        //    mounted.

        var newChildrenTop = 0
        var oldChildrenTop = 0
        var newChildrenBottom = newWidgets.count - 1
        var oldChildrenBottom = oldChildren.count - 1

        var newChildren = [Element](repeating: NullElement.shared, count: newWidgets.count)

        var previousChild: Element?

        // Update the top of the list.
        while oldChildrenTop <= oldChildrenBottom && newChildrenTop <= newChildrenBottom {
            let oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenTop])
            let newWidget = newWidgets[newChildrenTop]
            assert(oldChild == nil || oldChild!.lifecycleState == .active)
            if oldChild == nil || !oldChild!.widget.canUpdate(newWidget) {
                break
            }
            let newChild = updateChild(oldChild, newWidget, slotFor(newChildrenTop, previousChild))!
            assert(newChild.lifecycleState == .active)
            newChildren[newChildrenTop] = newChild
            previousChild = newChild
            newChildrenTop += 1
            oldChildrenTop += 1
        }

        // Scan the bottom of the list.
        while oldChildrenTop <= oldChildrenBottom && newChildrenTop <= newChildrenBottom {
            let oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenBottom])
            let newWidget = newWidgets[newChildrenBottom]
            assert(oldChild == nil || oldChild!.lifecycleState == .active)
            if oldChild == nil || !oldChild!.widget.canUpdate(newWidget) {
                break
            }
            oldChildrenBottom -= 1
            newChildrenBottom -= 1
        }

        // Scan the old children in the middle of the list.
        let haveOldChildren = oldChildrenTop <= oldChildrenBottom
        var oldKeyedChildren: [AnyKey: Element]?
        if haveOldChildren {
            oldKeyedChildren = [:]
            while oldChildrenTop <= oldChildrenBottom {
                let oldChild = replaceWithNullIfForgotten(oldChildren[oldChildrenTop])
                assert(oldChild == nil || oldChild!.lifecycleState == .active)
                if let oldChild = oldChild {
                    if oldChild.widget.key != nil {
                        oldKeyedChildren![AnyKey(oldChild.widget.key!)] = oldChild
                    } else {
                        deactivateChild(oldChild)
                    }
                }
                oldChildrenTop += 1
            }
        }

        // Update the middle of the list.
        while newChildrenTop <= newChildrenBottom {
            var oldChild: Element?
            let newWidget = newWidgets[newChildrenTop]
            assert(oldChild == nil || oldChild!.lifecycleState == .active)
            if haveOldChildren {
                if let key = newWidget.key {
                    oldChild = oldKeyedChildren![AnyKey(key)]
                    if oldChild != nil {
                        if oldChild!.widget.canUpdate(newWidget) {
                            // we found a match!
                            // remove it from oldKeyedChildren so we don't unsync it later
                            oldKeyedChildren!.removeValue(forKey: AnyKey(key))
                        } else {
                            // Not a match, let's pretend we didn't see it for now.
                            oldChild = nil
                        }
                    }
                }
            }
            assert(oldChild == nil || oldChild!.widget.canUpdate(newWidget))
            let newChild = updateChild(oldChild, newWidget, slotFor(newChildrenTop, previousChild))!
            assert(newChild.lifecycleState == .active)
            assert(oldChild === newChild || oldChild == nil || oldChild!.lifecycleState != .active)
            newChildren[newChildrenTop] = newChild
            previousChild = newChild
            newChildrenTop += 1
        }

        // We've scanned the whole list.
        assert(oldChildrenTop == oldChildrenBottom + 1)
        assert(newChildrenTop == newChildrenBottom + 1)
        assert(newWidgets.count - newChildrenTop == oldChildren.count - oldChildrenTop)
        newChildrenBottom = newWidgets.count - 1
        oldChildrenBottom = oldChildren.count - 1

        // Update the bottom of the list.
        while (oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom) {
            let oldChild = oldChildren[oldChildrenTop]
            assert(replaceWithNullIfForgotten(oldChild) != nil)
            assert(oldChild.lifecycleState == .active)
            let newWidget = newWidgets[newChildrenTop]
            assert(oldChild.widget.canUpdate(newWidget))
            let newChild = updateChild(oldChild, newWidget, slotFor(newChildrenTop, previousChild))!
            assert(newChild.lifecycleState == .active)
            assert(oldChild === newChild || oldChild.lifecycleState != .active)
            newChildren[newChildrenTop] = newChild
            previousChild = newChild
            newChildrenTop += 1
            oldChildrenTop += 1
        }

        // Clean up any of the remaining middle nodes from the old list.
        if let oldKeyedChildren, !oldKeyedChildren.isEmpty {
            for oldChild in oldKeyedChildren.values {
                if forgottenChildren == nil || !forgottenChildren!.value.contains(oldChild) {
                    deactivateChild(oldChild)
                }
            }
        }

        assert(newChildren.allSatisfy({ $0 !== NullElement.shared }))
        return newChildren
    }

    /// Change the slot that the given child occupies in its parent.
    ///
    /// Called by [MultiChildRenderObjectElement], and other [RenderObjectElement]
    /// subclasses that have multiple children, when child moves from one position
    /// to another in this element's child list.
    func updateSlotForChild(_ child: Element, _ newSlot: Slot) {
        // TODO: multi-child
    }

    /// Create an element for the given widget and add it as a child of this
    /// element in the given slot.
    ///
    /// This method is typically called by [updateChild] but can be called
    /// directly by subclasses that need finer-grained control over creating
    /// elements.
    public func inflateWidget(_ newWidget: Widget, _ newSlot: Slot?) -> Element {
        if let key = newWidget.key as? GlobalKey {
            if let newChild = retakeInactiveElement(key: key, newWidget: newWidget) {
                newChild.activateWithParent(self, newSlot: newSlot)
                let updatedChild = updateChild(newChild, newWidget, newSlot)
                return updatedChild!
            }
        }
        let newChild = newWidget.createElement()
        newChild.mount(self, slot: newSlot)
        return newChild
    }

    private func retakeInactiveElement(key: GlobalKey, newWidget: Widget) -> Element? {
        // The "inactivity" of the element being retaken here may be forward-looking: if
        // we are taking an element with a GlobalKey from an element that currently has
        // it as a child, then we know that element will soon no longer have that
        // element as a child. The only way that assumption could be false is if the
        // global key is being duplicated, and we'll try to track that using the
        // _debugTrackElementThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans call below.
        guard let element = key.currentElement else {
            return nil
        }

        if !element.widget.canUpdate(newWidget) {
            return nil
        }

        if let parent = element.parent {
            assert(
                parent !== self,
                "A GlobalKey was used multiple times inside one widget's child list."
            )
            parent.forgetChild(element)
            parent.deactivateChild(element)
        }
        assert(element.parent == nil)
        owner!.inactiveElements.remove(element)
        return element
    }

    // MARK: - Dirty

    /// Returns true if the element has been marked as needing rebuilding.
    public private(set) var dirty: Bool = true

    // Whether this is in owner._dirtyElements. This is used to know whether we
    // should be adding the element back into the list when it's reactivated.
    fileprivate var inDirtyList = false

    final func markNeedsBuild() {
        assert(lifecycleState != .defunct)
        if lifecycleState != .active {
            return
        }
        assert(owner != nil)
        assert(lifecycleState == .active)
        assert {
            if owner!.debugBuilding {
                assert(owner!.debugStateLocked)
            }
            return true
        }

        if dirty {
            return
        }
        dirty = true
        owner!.scheduleBuildFor(self)
    }

    // MARK: - Inheritance

    /// Updates the InheritedWidget lookup table. InheritedElement overrides
    /// this to add itself to the table.
    fileprivate func updateInheritance() {
        assert(lifecycleState == .active)
        inheritedElements = parent?.inheritedElements
    }

    /// The InheritedWidget lookup table that contains all InheritedWidgets that
    /// are visible at this location in the tree.
    fileprivate var inheritedElements: [HashableType: InheritedElement]?

    /// A Set that keeps track of InheritedWidgets that this widget depends on.
    fileprivate var dependencies: Set<InheritedElement>?

    /// Whether a previous call to dependOnInheritedWidgetOfExactType failed to
    /// find a widget. When this is true, we unconditionally call
    /// didChangeDependencies in case the widget becomes activated later.
    private var hadUnsatisfiedDependencies = false

    /// Called when a dependency of this element changes.
    ///
    /// The [dependOnInheritedWidgetOfExactType] registers this element as
    /// depending on inherited information of the given type. When the
    /// information of that type changes at this location in the tree (e.g.,
    /// because the [InheritedElement] updated to a new [InheritedWidget] and
    /// [InheritedWidget.updateShouldNotify] returned true), the framework calls
    /// this function to notify this element of the change.
    open func didChangeDependencies() {
        assert(lifecycleState == .active)
        markNeedsBuild()
    }

    public func dependOnInheritedElement(_ ancestor: InheritedElement, aspect: Any? = nil)
        -> any InheritedWidget
    {
        dependencies = dependencies ?? Set<InheritedElement>()
        dependencies!.insert(ancestor)
        ancestor.updateDependencies(self, aspect: aspect)
        return ancestor.widget as! any InheritedWidget
    }

    public func dependOnInheritedWidgetOfExactType<T: InheritedWidget>(
        _ type: T.Type,
        aspect: AnyObject? = nil
    )
        -> T?
    {
        assert(lifecycleState == .active)
        let ancestor = inheritedElements?[HashableType(T.self)]
        if let ancestor {
            return dependOnInheritedElement(ancestor, aspect: aspect) as? T
        }
        hadUnsatisfiedDependencies = true
        return nil
    }

    public func getElementForInheritedWidgetOfExactType(_ type: AnyObject.Type) -> InheritedElement?
    {
        assert(lifecycleState == .active)
        return inheritedElements?[HashableType(type)]
    }

    public func getInheritedWidgetOfExactType<T: InheritedWidget>(_ type: T.Type) -> T? {
        if let widget = getElementForInheritedWidgetOfExactType(type)?.widget {
            return widget as! T?
        }
        return nil
    }

    public func toStringShort() -> String {
        if let widget {
            let type = objectRuntimeType(widget)
            if let key = widget.key {
                return "\(type)-(\(key))"
            } else {
                return type
            }
        } else {
            return "\(describeIdentity(self))(DEFUNCT)"
        }
    }

    public func debugDescribeChildren() -> [DiagnosticableTree] {
        var children: [DiagnosticableTree] = []
        visitChildren { child in
            children.append(child)
        }
        return children
    }
}

/// Signature for a function that creates a widget for a given index, e.g., in a
/// list.
///
/// Used by [ListView.builder] and other APIs that use lazily-generated widgets.
///
/// See also:
///
///  * [WidgetBuilder], which is similar but only takes a [BuildContext].
///  * [TransitionBuilder], which is similar but also takes a child.
///  * [NullableIndexedWidgetBuilder], which is similar but may return null.
public typealias IndexedWidgetBuilder = (BuildContext, Int) -> Widget

/// Signature for a function that creates a widget for a given index, e.g., in a
/// list, but may return null.
///
/// Used by [SliverChildBuilderDelegate.builder] and other APIs that
/// use lazily-generated widgets where the child count is not known
/// ahead of time.
///
/// Unlike most builders, this callback can return null, indicating the index
/// is out of range. Whether and when this is valid depends on the semantics
/// of the builder. For example, [SliverChildBuilderDelegate.builder] returns
/// null when the index is out of range, where the range is defined by the
/// [SliverChildBuilderDelegate.childCount]; so in that case the `index`
/// parameter's value may determine whether returning null is valid or not.
///
/// See also:
///
///  * [WidgetBuilder], which is similar but only takes a [BuildContext].
///  * [TransitionBuilder], which is similar but also takes a child.
///  * [IndexedWidgetBuilder], which is similar but not nullable.
public typealias NullableIndexedWidgetBuilder = (BuildContext, Int) -> Widget?

/// A builder that builds a widget given a child.
///
/// The child should typically be part of the returned widget tree.
///
/// Used by [AnimatedBuilder.builder], [ListenableBuilder.builder],
/// [WidgetsApp.builder], and [MaterialApp.builder].
///
/// See also:
///
/// * [WidgetBuilder], which is similar but only takes a [BuildContext].
/// * [IndexedWidgetBuilder], which is similar but also takes an index.
/// * [ValueWidgetBuilder], which is similar but takes a value and a child.
public typealias TransitionBuilder = (BuildContext, Widget?) -> Widget

/// An [Element] that composes other [Element]s.
///
/// Rather than creating a [RenderObject] directly, a [ComponentElement] creates
/// [RenderObject]s indirectly by creating other [Element]s.
///
/// Contrast with [RenderObjectElement].
public class ComponentElement: Element {
    override init(_ widget: Widget) {
        super.init(widget)
    }

    private var child: Element?

    override var renderObjectAttachingChild: Element? {
        return child
    }

    override public func mount(_ parent: Element?, slot: Slot? = nil) {
        super.mount(parent, slot: slot)
        assert(child == nil)
        assert(lifecycleState == .active)
        firstBuild()
        assert(child != nil)
    }

    override public func visitChildren(_ visitor: (Element) -> Void) {
        if child != nil {
            visitor(child!)
        }
    }

    override public func forgetChild(_ child: Element) {
        assert(child == self.child)
        self.child = nil
        super.forgetChild(child)
    }

    /// StatefulElement overrides this to also call state.didChangeDependencies.
    internal func firstBuild() {
        // This eventually calls performRebuild.
        rebuild()
    }

    public private(set) var debugDoingBuild: Bool = false

    /// Calls the [StatelessWidget.build] method of the [StatelessWidget] object
    /// (for stateless widgets) or the [State.build] method of the [State] object
    /// (for stateful widgets) and then updates the widget tree.
    ///
    /// Called automatically during [mount] to generate the first build, and by
    /// [rebuild] when the element needs updating.
    public override func performRebuild() {
        assert {
            debugDoingBuild = true
            return true
        }
        let built =
            if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) {
                withObservationTracking {
                    build()
                } onChange: {
                    backend.runOnMainThread {
                        if self.mounted {
                            self.markNeedsBuild()
                        }
                    }
                }
            } else {
                build()
            }
        assert {
            debugDoingBuild = false
            return true
        }

        // We delay marking the element as clean until after calling build() so
        // that attempts to markNeedsBuild() during build() will be ignored.
        super.performRebuild()

        child = updateChild(child, built, slot)
    }

    open func build() -> Widget {
        fatalError("Subclasses must override build")
    }
}

/// An [Element] that uses a [StatelessWidget] as its configuration.
class StatelessElement: ComponentElement {
    override init(_ widget: Widget) {
        assert(widget is StatelessWidget)
        super.init(widget)
    }

    override func update(_ newWidget: Widget) {
        super.update(newWidget)
        assert(widget === newWidget)
        rebuild(force: true)
    }

    override func build() -> Widget {
        return (widget as! StatelessWidget).build(context: self)
    }
}

/// An [Element] that uses a [StatefulWidget] as its configuration.
class StatefulElement<T: StatefulWidget>: ComponentElement {
    init(_ widget: T) {
        super.init(widget)
        state = widget.createState()
        assert(state.element == nil)
        state.element = self
        assert(state.widget == nil)
        state.widget = widget
    }

    /// The [State] instance associated with this location in the tree.
    ///
    /// There is a one-to-one relationship between [State] objects and the
    /// [StatefulElement] objects that hold them. The [State] objects are created
    /// by [StatefulElement] in [mount].
    var state: State<T>!

    override func build() -> Widget {
        state.build(context: self)
    }

    override func firstBuild() {
        assert {
            state.debugLifecycleState = .created
            return true
        }
        state.initState()
        assert {
            state.debugLifecycleState = .initialized
            return true
        }
        state.didChangeDependencies()
        assert {
            state.debugLifecycleState = .ready
            return true
        }
        super.firstBuild()
    }

    override func performRebuild() {
        if _didChangeDependencies {
            state.didChangeDependencies()
            _didChangeDependencies = false
        }
        super.performRebuild()
    }

    override func update(_ newWidget: Widget) {
        super.update(newWidget)
        assert(widget === newWidget)
        let oldWidget = state.widget!
        state.widget = (newWidget as! T)
        state.didUpdateWidget(oldWidget)
        rebuild(force: true)
    }

    //   @override
    //   void activate() {
    //     super.activate();
    //     state.activate();
    //     // Since the State could have observed the deactivate() and thus disposed of
    //     // resources allocated in the build method, we have to rebuild the widget
    //     // so that its State can reallocate its resources.
    //     assert(_lifecycleState == _ElementLifecycle.active); // otherwise markNeedsBuild is a no-op
    //     markNeedsBuild();
    //   }

    //   @override
    //   void deactivate() {
    //     state.deactivate();
    //     super.deactivate();
    //   }

    override func unmount() {
        super.unmount()
        state.dispose()
        assert(state.debugLifecycleState == .defunct)
        state.element = nil
        // Release resources to reduce the severity of memory leaks caused by
        // defunct, but accidentally retained Elements.
        state = nil
    }

    /// This controls whether we should call [State.didChangeDependencies] from
    /// the start of [build], to avoid calls when the [State] will not get built.
    /// This can happen when the widget has dropped out of the tree, but depends
    /// on an [InheritedWidget] that is still in the tree.
    ///
    /// It is set initially to false, since [_firstBuild] makes the initial call
    /// on the [state]. When it is true, [build] will call
    /// `state.didChangeDependencies` and then sets it to false. Subsequent calls
    /// to [didChangeDependencies] set it to true.
    private var _didChangeDependencies = false

    override func didChangeDependencies() {
        super.didChangeDependencies()
        _didChangeDependencies = true
    }
}

/// An [Element] that uses a [ProxyWidget] as its configuration.
public class ProxyElement: ComponentElement {
    override init(_ widget: Widget) {
        assert(widget is ProxyWidget)
        super.init(widget)
    }

    override public func build() -> Widget {
        return (widget as! ProxyWidget).child
    }

    override public func update(_ newWidget: Widget) {
        let oldWidget = widget as! ProxyWidget
        assert(widget !== newWidget)
        super.update(newWidget)
        assert(widget === newWidget)
        updated(oldWidget)
        rebuild(force: true)
    }

    /// Called during build when the [widget] has changed.
    ///
    /// By default, calls [notifyClients]. Subclasses may override this method to
    /// avoid calling [notifyClients] unnecessarily (e.g. if the old and new
    /// widgets are equivalent).
    public func updated(_ oldWidget: ProxyWidget) {
        notifyClients(oldWidget)
    }

    /// Notify other objects that the widget associated with this element has
    /// changed.
    ///
    /// Called during ``update`` (via ``updated``) after changing the widget
    /// associated with this element but before rebuilding this element.
    open func notifyClients(_ oldWidget: ProxyWidget) {}
}

/// An [Element] that uses a [ParentDataWidget] as its configuration.
public class ParentDataElement: ProxyElement {
    private func applyParentData(_ widget: any ParentDataWidget) {
        // print(type(of: widget).RenderObjectType.self)
        func applyParentDataToChild(_ child: Element) {
            if let child = child as? RenderObjectElement {
                child.updateParentData(widget)
            } else {
                child.visitChildren(applyParentDataToChild)
            }
        }
        visitChildren(applyParentDataToChild)
    }

    /// Calls [ParentDataWidget.applyParentData] on the given widget, passing it
    /// the [RenderObject] whose parent data this element is ultimately
    /// responsible for.
    ///
    /// This allows a render object's [RenderObject.parentData] to be modified
    /// without triggering a build. This is generally ill-advised, but makes sense
    /// in situations such as the following:
    ///
    ///  * Build and layout are currently under way, but the [ParentData] in question
    ///    does not affect layout, and the value to be applied could not be
    ///    determined before build and layout (e.g. it depends on the layout of a
    ///    descendant).
    ///
    ///  * Paint is currently under way, but the [ParentData] in question does not
    ///    affect layout or paint, and the value to be applied could not be
    ///    determined before paint (e.g. it depends on the compositing phase).
    ///
    /// In either case, the next build is expected to cause this element to be
    /// configured with the given new widget (or a widget with equivalent data).
    ///
    /// Only [ParentDataWidget]s that return true for
    /// [ParentDataWidget.debugCanApplyOutOfTurn] can be applied this way.
    ///
    /// The new widget must have the same child as the current widget.
    ///
    /// An example of when this is used is the [AutomaticKeepAlive] widget. If it
    /// receives a notification during the build of one of its descendants saying
    /// that its child must be kept alive, it will apply a [KeepAlive] widget out
    /// of turn. This is safe, because by definition the child is already alive,
    /// and therefore this will not change the behavior of the parent this frame.
    /// It is more efficient than requesting an additional frame just for the
    /// purpose of updating the [KeepAlive] widget.
    func applyWidgetOutOfTurn(_ newWidget: any ParentDataWidget) {
        // assert(newWidget.debugCanApplyOutOfTurn())
        assert(newWidget.child === (widget as! any ParentDataWidget).child)
        applyParentData(newWidget)
    }

    override public func notifyClients(_ oldWidget: ProxyWidget) {
        let widget = widget as! any ParentDataWidget
        applyParentData(widget)
    }
}

public class InheritedElement: ProxyElement {
    private var dependents: [Element: Any?] = [:]

    override func updateInheritance() {
        assert(lifecycleState == .active)
        let incomingWidgets = parent?.inheritedElements ?? [:]
        inheritedElements = incomingWidgets
        inheritedElements![HashableType(type(of: widget))] = self
    }

    //   @override
    //   void debugDeactivated() {
    //     assert(() {
    //       assert(_dependents.isEmpty);
    //       return true;
    //     }());
    //     super.debugDeactivated();
    //   }

    /// Returns the dependencies value recorded for [dependent]
    /// with [setDependencies].
    ///
    /// Each dependent element is mapped to a single object value
    /// which represents how the element depends on this
    /// [InheritedElement]. This value is null by default and by default
    /// dependent elements are rebuilt unconditionally.
    ///
    /// Subclasses can manage these values with [updateDependencies]
    /// so that they can selectively rebuild dependents in
    /// [notifyDependent].
    ///
    /// This method is typically only called in overrides of [updateDependencies].
    ///
    /// See also:
    ///
    ///  * [updateDependencies], which is called each time a dependency is
    ///    created with [dependOnInheritedWidgetOfExactType].
    ///  * [setDependencies], which sets dependencies value for a dependent
    ///    element.
    ///  * [notifyDependent], which can be overridden to use a dependent's
    ///    dependencies value to decide if the dependent needs to be rebuilt.
    ///  * [InheritedModel], which is an example of a class that uses this method
    ///    to manage dependency values.
    public func getDependencies(_ dependent: Element) -> Any? {
        dependents[dependent] ?? nil
    }

    /// Sets the value returned by [getDependencies] value for [dependent].
    ///
    /// Each dependent element is mapped to a single object value
    /// which represents how the element depends on this
    /// [InheritedElement]. The [updateDependencies] method sets this value to
    /// null by default so that dependent elements are rebuilt unconditionally.
    ///
    /// Subclasses can manage these values with [updateDependencies]
    /// so that they can selectively rebuild dependents in [notifyDependent].
    ///
    /// This method is typically only called in overrides of [updateDependencies].
    ///
    /// See also:
    ///
    ///  * [updateDependencies], which is called each time a dependency is
    ///    created with [dependOnInheritedWidgetOfExactType].
    ///  * [getDependencies], which returns the current value for a dependent
    ///    element.
    ///  * [notifyDependent], which can be overridden to use a dependent's
    ///    [getDependencies] value to decide if the dependent needs to be rebuilt.
    ///  * [InheritedModel], which is an example of a class that uses this method
    ///    to manage dependency values.
    public func setDependencies(_ dependent: Element, _ value: Any?) {
        dependents[dependent] = value
    }

    /// Called by [dependOnInheritedWidgetOfExactType] when a new [dependent] is added.
    ///
    /// Each dependent element can be mapped to a single object value with
    /// [setDependencies]. This method can lookup the existing dependencies with
    /// [getDependencies].
    ///
    /// By default this method sets the inherited dependencies for [dependent]
    /// to null. This only serves to record an unconditional dependency on
    /// [dependent].
    ///
    /// Subclasses can manage their own dependencies values so that they
    /// can selectively rebuild dependents in [notifyDependent].
    ///
    /// See also:
    ///
    ///  * [getDependencies], which returns the current value for a dependent
    ///    element.
    ///  * [setDependencies], which sets the value for a dependent element.
    ///  * [notifyDependent], which can be overridden to use a dependent's
    ///    dependencies value to decide if the dependent needs to be rebuilt.
    ///  * [InheritedModel], which is an example of a class that uses this method
    ///    to manage dependency values.
    public func updateDependencies(_ dependent: Element, aspect: Any?) {
        setDependencies(dependent, nil)
    }

    /// Called by [notifyClients] for each dependent.
    ///
    /// Calls `dependent.didChangeDependencies()` by default.
    ///
    /// Subclasses can override this method to selectively call
    /// [didChangeDependencies] based on the value of [getDependencies].
    ///
    /// See also:
    ///
    ///  * [updateDependencies], which is called each time a dependency is
    ///    created with [dependOnInheritedWidgetOfExactType].
    ///  * [getDependencies], which returns the current value for a dependent
    ///    element.
    ///  * [setDependencies], which sets the value for a dependent element.
    ///  * [InheritedModel], which is an example of a class that uses this method
    ///    to manage dependency values.
    public func notifyDependent(_ oldWidget: ProxyWidget, _ dependent: Element) {
        dependent.didChangeDependencies()
    }

    /// Called by [Element.deactivate] to remove the provided `dependent` [Element] from this [InheritedElement].
    ///
    /// After the dependent is removed, [Element.didChangeDependencies] will no
    /// longer be called on it when this [InheritedElement] notifies its dependents.
    ///
    /// Subclasses can override this method to release any resources retained for
    /// a given [dependent].
    public func removeDependent(_ dependent: Element) {
        dependents.removeValue(forKey: dependent)
    }

    /// Calls [Element.didChangeDependencies] of all dependent elements, if
    /// [InheritedWidget.updateShouldNotify] returns true.
    ///
    /// Called by [update], immediately prior to [build].
    ///
    /// Calls [notifyClients] to actually trigger the notifications.
    public override func updated(_ oldWidget: ProxyWidget) {
        let oldWidget = oldWidget as! any InheritedWidget
        if updateShouldNotify(oldWidget) {
            super.updated(oldWidget)
        }
    }

    private func updateShouldNotify<T: InheritedWidget>(_ oldWidget: T) -> Bool {
        (widget as! T).updateShouldNotify(oldWidget)
    }

    /// Notifies all dependent elements that this inherited widget has changed, by
    /// calling [Element.didChangeDependencies].
    ///
    /// This method must only be called during the build phase. Usually this
    /// method is called automatically when an inherited widget is rebuilt, e.g.
    /// as a result of calling [State.setState] above the inherited widget.
    ///
    /// See also:
    ///
    ///  * [InheritedNotifier], a subclass of [InheritedWidget] that also calls
    ///    this method when its [Listenable] sends a notification.
    public override func notifyClients(_ oldWidget: ProxyWidget) {
        for (dependent, _) in dependents {
            // check that it really is our descendant
            assert {
                var ancestor: Element? = dependent.parent
                while ancestor !== self && ancestor != nil {
                    ancestor = ancestor!.parent
                }
                return ancestor === self
            }
            // check that it really depends on us
            assert(dependent.dependencies!.contains(self))
            notifyDependent(oldWidget, dependent)
        }
    }
}

public class RenderObjectElement: Element {
    /// The underlying [RenderObject] for this element.
    ///
    /// nil if the element is unmounted.
    fileprivate var _renderObject: RenderObject?

    public override var renderObject: RenderObject! {
        return _renderObject
    }

    override var renderObjectAttachingChild: Element? {
        return nil
    }

    public override func mount(_ parent: Element?, slot: Slot? = nil) {
        super.mount(parent, slot: slot)
        _renderObject = (widget as! any RenderObjectWidget).createRenderObject(context: self)
        attachRenderObject(slot)
        super.performRebuild()
    }

    public override func update(_ newWidget: Widget) {
        super.update(newWidget)
        assert(widget === newWidget)
        _performRebuild()  // calls widget.updateRenderObject()
    }

    public override func performRebuild() {
        _performRebuild()  // calls widget.updateRenderObject()
    }

    private func _performRebuild() {
        let renderObjectWidget = widget as! any RenderObjectWidget
        _updateRenderObject(widget: renderObjectWidget)
        super.performRebuild()
    }

    private func _updateRenderObject<T: RenderObjectWidget>(widget: T) {
        widget.updateRenderObject(context: self, renderObject: _renderObject as! T.RenderObjectType)
    }

    private weak var ancestorRenderObjectElement: RenderObjectElement?

    private func findAncestorRenderObjectElement() -> RenderObjectElement? {
        var ancestor: Element? = parent
        while ancestor != nil && !(ancestor is RenderObjectElement) {
            ancestor = ancestor!.parent
        }
        return ancestor as? RenderObjectElement
    }

    private func findAncestorParentDataElements() -> [ParentDataElement] {
        var ancestor: Element? = parent
        var result = [ParentDataElement]()
        // var debugAncestorTypes = [Any.Type]()
        // var debugParentDataTypes = [Any.Type]()
        // var debugAncestorCulprits = [Any.Type]()

        // More than one ParentDataWidget can contribute ParentData, but there are
        // some constraints.
        // 1. ParentData can only be written by unique ParentDataWidget types.
        //    For example, two KeepAlive ParentDataWidgets trying to write to the
        //    same child is not allowed.
        // 2. Each contributing ParentDataWidget must contribute to a unique
        //    ParentData type, less ParentData be overwritten.
        //    For example, there cannot be two ParentDataWidgets that both write
        //    ParentData of type KeepAliveParentDataMixin, if the first check was
        //    subverted by a subclassing of the KeepAlive ParentDataWidget.
        // 3. The ParentData itself must be compatible with all ParentDataWidgets
        //    writing to it.
        //    For example, TwoDimensionalViewportParentData uses the
        //    KeepAliveParentDataMixin, so it could be compatible with both
        //    KeepAlive, and another ParentDataWidget with ParentData type
        //    TwoDimensionalViewportParentData or a subclass thereof.
        // The first and second cases are verified here. The third is verified in
        // debugIsValidRenderObject.
        while ancestor != nil && !(ancestor is RenderObjectElement) {
            if let ancestor = ancestor as? ParentDataElement {
                // assert {
                //     if !debugAncestorTypes.insert(ancestor.runtimeType).inserted
                //         || !debugParentDataTypes.insert(ancestor.debugParentDataType).inserted
                //     {
                //         debugAncestorCulprits.append(ancestor.runtimeType)
                //     }
                //     return true
                // }
                result.append(ancestor)
            }
            ancestor = ancestor!.parent
        }
        // assert {
        //     if result.isEmpty || ancestor == nil {
        //         return true
        //     }
        //     // Validate points 1 and 2 from above.
        //     _debugCheckCompetingAncestors(
        //         result,
        //         debugAncestorTypes,
        //         debugParentDataTypes,
        //         debugAncestorCulprits
        //     )
        //     return true
        // }
        return result
    }

    public override func attachRenderObject(_ newSlot: Slot?) {
        slot = newSlot
        ancestorRenderObjectElement = findAncestorRenderObjectElement()
        ancestorRenderObjectElement?.insertRenderObjectChild(_renderObject!, slot: newSlot)
        for parentDataElement in findAncestorParentDataElements() {
            let parentDataWidget = parentDataElement.widget as! any ParentDataWidget
            updateParentData(parentDataWidget)
        }
    }

    public override func detachRenderObject() {
        if let ancestorRenderObjectElement {
            ancestorRenderObjectElement.removeRenderObjectChild(_renderObject!, slot: slot)
            self.ancestorRenderObjectElement = nil
        }
        slot = nil
    }

    func insertRenderObjectChild(_ child: RenderObject, slot: Slot?) {
        assertionFailure("\(Self.self) does not support addChild.")
    }

    func moveRenderObjectChild(_ child: RenderObject, oldSlot: Slot?, newSlot: Slot?) {
        assertionFailure("\(Self.self) does not support moveChild.")
    }

    func removeRenderObjectChild(_ child: RenderObject, slot: Slot?) {
        assertionFailure("\(Self.self) does not support removeChild.")
    }

    public override func unmount() {
        assert(
            !renderObject.debugDisposed,
            "A RenderObject was disposed prior to its owning element being unmounted: "
                + "\(String(describing: renderObject))"
        )
        let oldWidget = widget as! any RenderObjectWidget
        super.unmount()
        assert(
            !renderObject.attached,
            "A RenderObject was still attached when attempting to unmount its "
                + "RenderObjectElement: \(String(describing: renderObject))"
        )
        _didUnmountRenderObject(widget: oldWidget)
        _renderObject!.dispose()
        _renderObject = nil
    }

    private func _didUnmountRenderObject<T: RenderObjectWidget>(widget: T) {
        widget.didUnmountRenderObject(renderObject: _renderObject as! T.RenderObjectType)
    }

    fileprivate func updateParentData(_ parentDataWidget: any ParentDataWidget) {
        parentDataWidget.applyParentData(renderObject)
    }
}

public class LeafRenderObjectElement: RenderObjectElement {
    public override func visitChildren(_ visitor: (Element) -> Void) {
        // Leaf render objects have no children.
    }
}

public class SingleChildRenderObjectElement: RenderObjectElement {
    private var child: Element?

    public override func visitChildren(_ visitor: (Element) -> Void) {
        if let child {
            visitor(child)
        }
    }

    public override func forgetChild(_ child: Element) {
        self.child = nil
        super.forgetChild(child)
    }

    public override func mount(_ parent: Element?, slot: Slot? = nil) {
        super.mount(parent, slot: slot)
        assert(child == nil)
        child = updateChild(child, (widget as! any SingleChildRenderObjectWidget).child, nil)
    }

    public override func update(_ newWidget: Widget) {
        super.update(newWidget)
        assert(widget === newWidget)
        child = updateChild(child, (widget as! any SingleChildRenderObjectWidget).child, nil)
    }

    override func insertRenderObjectChild(_ child: RenderObject, slot: Slot?) {
        // let renderObject = renderObject as! RenderObjectWithSingleChild
        let renderObject = renderObject as! any RenderObjectWithSingleChild
        assert(slot == nil)
        renderObject.setChild(child: child)
        assert(renderObject === self.renderObject)
    }

    override func moveRenderObjectChild(_ child: RenderObject, oldSlot: Slot?, newSlot: Slot?) {
        assertionFailure("\(Self.self) does not support moveChild.")
    }

    override func removeRenderObjectChild(_ child: RenderObject, slot: Slot?) {
        let renderObject = renderObject as! any RenderObjectWithSingleChild
        assert(slot == nil)
        // assert(renderObject.child === child)
        renderObject.setChild(child: nil)
        assert(renderObject === self.renderObject)
    }
}

public class MultiChildRenderObjectElement: RenderObjectElement {

    /// The current list of children of this element.
    ///
    /// This list is filtered to hide elements that have been forgotten (using
    /// [forgetChild]).
    var children: [Element] {
        _children.filter({ !forgottenChildren.value.contains($0) })
    }

    private var _children = [Element]()
    // We keep a set of forgotten children to avoid O(n^2) work walking _children
    // repeatedly to remove children.
    private var forgottenChildren = Box(Set<Element>())

    override func insertRenderObjectChild(_ child: RenderObject, slot: Slot?) {
        let renderObject = _renderObject as! any RenderObjectWithChildren
        let slot = slot as! IndexedSlot
        renderObject.insert(child, after: slot.value?.renderObject)
    }

    override func moveRenderObjectChild(_ child: RenderObject, oldSlot: Slot?, newSlot: Slot?) {
        let renderObject = _renderObject as! any RenderObjectWithChildren
        let slot = slot as! IndexedSlot
        renderObject.move(child, after: slot.value?.renderObject)
    }

    override func removeRenderObjectChild(_ child: RenderObject, slot: Slot?) {
        let renderObject = _renderObject as! any RenderObjectWithChildren
        renderObject.remove(child)
    }

    public override func visitChildren(_ visitor: (Element) -> Void) {
        for child in _children {
            if !forgottenChildren.value.contains(child) {
                visitor(child)
            }
        }
    }

    public override func forgetChild(_ child: Element) {
        assert(child.parent === self)
        assert(_children.contains(child))
        assert(!forgottenChildren.value.contains(child))
        forgottenChildren.value.insert(child)
        super.forgetChild(child)
    }

    public override func inflateWidget(_ newWidget: Widget, _ newSlot: Slot?) -> Element {
        let newChild = super.inflateWidget(newWidget, newSlot)
        assert(
            newChild.renderObject != nil,
            "The children of `MultiChildRenderObjectElement` must each has an associated render object."
        )
        return newChild
    }

    public override func mount(_ parent: Element?, slot: Slot? = nil) {
        super.mount(parent, slot: slot)
        let multiChildRenderObjectWidget = widget as! any MultiChildRenderObjectWidget
        var children = [Element]()
        var previousChild: Element?
        for i in 0..<multiChildRenderObjectWidget.children.count {
            let newChild = inflateWidget(
                multiChildRenderObjectWidget.children[i],
                IndexedSlot(value: previousChild, index: i)
            )
            children.append(newChild)
            previousChild = newChild
        }
        _children = children
    }

    public override func update(_ newWidget: Widget) {
        super.update(newWidget)
        let multiChildRenderObjectWidget = widget as! any MultiChildRenderObjectWidget
        assert(widget === newWidget)
        // assert(!debugChildrenHaveDuplicateKeys(widget, multiChildRenderObjectWidget.children));
        _children = updateChildren(
            _children,
            multiChildRenderObjectWidget.children,
            forgottenChildren: forgottenChildren
        )
        forgottenChildren.value.removeAll()
    }
}

public protocol Slot {
    func isEqualTo(_ other: Slot) -> Bool
}

internal func slotEqual(_ a: Slot?, _ b: Slot?) -> Bool {
    if let a = a, let b = b {
        return a.isEqualTo(b)
    } else {
        return a == nil && b == nil
    }
}

extension Int: Slot {
    public func isEqualTo(_ other: Slot) -> Bool {
        guard let other = other as? Int else {
            return false
        }
        return other == self
    }
}

/// A slot that only equals itself.
public class UniqueSlot: Slot {
    public func isEqualTo(_ other: Slot) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return other === self
    }
}

/// A value for [Element.slot] used for children of
/// [MultiChildRenderObjectElement]s.
///
/// A slot for a [MultiChildRenderObjectElement] consists of an [index]
/// identifying where the child occupying this slot is located in the
/// [MultiChildRenderObjectElement]'s child list and an arbitrary [value] that
/// can further define where the child occupying this slot fits in its
/// parent's child list.
///
/// See also:
///
///  * [RenderObjectElement.updateChildren], which discusses why this class is
///    used as slot values for the children of a [MultiChildRenderObjectElement].
public struct IndexedSlot: Slot, Equatable {
    /// Information to define where the child occupying this slot fits in its
    /// parent's child list.
    let value: Element?

    /// The index of this slot in the parent's child list.
    let index: Int

    public func isEqualTo(_ other: Slot) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return other == self
    }
}

/// Mixin for the element at the root of the tree.
///
/// Only root elements may have their owner set explicitly. All other
/// elements inherit their owner from their parent.
public protocol RootElementMixin: Element {
}

extension RootElementMixin {
    public func assignOwner(_ owner: BuildOwner) {
        self.owner = owner
    }
}

private class NullElement: Element {
    static let shared = NullElement(
        NullWidget()
    )
}

private class NullWidget: Widget {
    func createElement() -> Element {
        assertionFailure("NullWidget should never be instantiated.")
        fatalError()
    }
}
