// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An abstract class representing a particular configuration of an `Action`.
///
/// This class is what the `Shortcuts.shortcuts` map has as values, and is used
/// by an `ActionDispatcher` to look up an action and invoke it, giving it this
/// object to extract configuration information from.
///
/// See also:
///
///  * `Shortcuts`, a widget used to bind key combinations to `Intent`s.
///  * `Actions`, a widget used to map `Intent`s to `Action`s.
///  * `Actions.invoke`, which invokes the action associated with a specified
///    `Intent` using the `Actions` widget that most tightly encloses the given
///    `BuildContext`.
public protocol Intent {}

/// The kind of callback that an ``Action`` uses to notify of changes to the
/// action's state.
///
/// To register an action listener, call ``Action/addActionListener``.
public typealias ActionListenerCallback = (any ActionProtocol) -> Void

/// Protocol that all ``Action`` instances implement.
public protocol ActionProtocol: AnyObject, HashableObject {
    associatedtype IntentType: Intent

    /// Returns true if the action is enabled and is ready to be invoked.
    ///
    /// This will be called by the ``ActionDispatcher`` before attempting to invoke
    /// the action.
    ///
    /// If the action's enable state depends on a ``BuildContext``, subclass
    /// ``ContextAction`` instead of ``Action``.
    func isEnabled(_ intent: IntentType, context: BuildContext?) -> Bool

    /// Called when the action is to be performed.
    ///
    /// This is called by the ``ActionDispatcher`` when an action is invoked via
    /// ``Actions/invoke``, or when an action is invoked using
    /// ``ActionDispatcher/invokeAction`` directly.
    ///
    /// This method is only meant to be invoked by an ``ActionDispatcher``, or by
    /// its subclasses, and only when [isEnabled] is true.
    ///
    /// When overriding this method, the returned value can be any [Object], but
    /// changing the return type of the override to match the type of the returned
    /// value provides more type safety.
    ///
    /// For instance, if an override of [invoke] returned an `int`, then it might
    /// be defined like so:
    ///
    /// ```swift
    /// class IncrementIntent extends Intent {
    ///   const IncrementIntent({required this.index});
    ///
    ///   final int index;
    /// }
    ///
    /// class MyIncrementAction extends Action<IncrementIntent> {
    ///   @override
    ///   int invoke(IncrementIntent intent) {
    ///     return intent.index + 1;
    ///   }
    /// }
    /// ```
    ///
    /// To receive the result of invoking an action, it must be invoked using
    /// ``Actions/invoke``, or by invoking it using an ``ActionDispatcher``. An action
    /// invoked via a [Shortcuts] widget will have its return value ignored.
    ///
    /// If the action's behavior depends on a ``BuildContext``, subclass
    /// ``ContextAction`` instead of ``Action``.
    func invoke(_ intent: IntentType, context: BuildContext?) -> Any?

    /// Converts the result of [invoke] of this action to a [KeyEventResult].
    ///
    /// This is typically used when the action is invoked in response to a
    /// keyboard shortcut.
    ///
    /// The [invokeResult] argument is the value returned by the [invoke]
    /// method.
    ///
    /// By default, calls [consumesKey] and converts the returned boolean to
    /// [KeyEventResult.handled] if it's true, and
    /// [KeyEventResult.skipRemainingHandlers] if it's false.
    ///
    /// Concrete implementations may refine the type of [invokeResult], since
    /// they know the type returned by [invoke].
    func toKeyEventResult(_ intent: IntentType, invokeResult: Any?) -> KeyEventResult

    /// Register a callback to listen for changes to the state of this action.
    ///
    /// If you call this, you must call [removeActionListener] a matching number
    /// of times, or memory leaks will occur. To help manage this and avoid memory
    /// leaks, use of the [ActionListener] widget to register and unregister your
    /// listener appropriately is highly recommended.
    ///
    /// If a listener had been added twice, and is removed once during an
    /// iteration (i.e. in response to a notification), it will still be called
    /// again. If, on the other hand, it is removed as many times as it was
    /// registered, then it will no longer be called. This odd behavior is the
    /// result of the ``Action`` not being able to determine which listener
    /// is being removed, since they are identical, and therefore conservatively
    /// still calling all the listeners when it knows that any are still
    /// registered.
    ///
    /// This surprising behavior can be unexpectedly observed when registering a
    /// listener on two separate objects which are both forwarding all
    /// registrations to a common upstream object.
    func addActionListener(_ listener: AnyObject, callback: @escaping ActionListenerCallback)

    /// Remove a previously registered closure from the list of closures that are
    /// notified when the object changes.
    ///
    /// If the given listener is not registered, the call is ignored.
    ///
    /// If you call [addActionListener], you must call this method a matching
    /// number of times, or memory leaks will occur. To help manage this and avoid
    /// memory leaks, use of the [ActionListener] widget to register and
    /// unregister your listener appropriately is highly recommended.
    func removeActionListener(_ listener: AnyObject)
}

/// A type-erased ``Action`` that wraps another ``Action``.
public struct AnyAction: Hashable {
    public init(_ action: any ActionProtocol) {
        self.inner = action
    }

    public let inner: any ActionProtocol

    public func hash(into hasher: inout Hasher) {
        hasher.combine(inner)
    }

    public static func == (lhs: AnyAction, rhs: AnyAction) -> Bool {
        return lhs.inner === rhs.inner
    }
}

/// Base class for an action or command to be performed.
///
/// ``Action``s are typically invoked as a result of a user action. For example,
/// the [Shortcuts] widget will map a keyboard shortcut into an [Intent], which
/// is given to an ``ActionDispatcher`` to map the [Intent] to an ``Action`` and
/// invoke it.
///
/// The ``ActionDispatcher`` can invoke an ``Action`` on the primary focus, or
/// without regard for focus.
///
/// ### Action Overriding
///
/// When using a leaf widget to build a more specialized widget, it's sometimes
/// desirable to change the default handling of an [Intent] defined in the leaf
/// widget. For instance, [TextField]'s [SelectAllTextIntent] by default selects
/// the text it currently contains, but in a US phone number widget that
/// consists of 3 different [TextField]s (area code, prefix and line number),
/// [SelectAllTextIntent] should instead select the text within all 3
/// [TextField]s.
///
/// An overridable ``Action`` is a special kind of ``Action`` created using the
/// [Action.overridable] constructor. It has access to a default ``Action``, and a
/// nullable override ``Action``. It has the same behavior as its override if that
/// exists, and mirrors the behavior of its `defaultAction` otherwise.
///
/// The [Action.overridable] constructor creates overridable ``Action``s that use
/// a ``BuildContext`` to find a suitable override in its ancestor [Actions]
/// widget. This can be used to provide a default implementation when creating a
/// general purpose leaf widget, and later override it when building a more
/// specialized widget using that leaf widget. Using the [TextField] example
/// above, the [TextField] widget uses an overridable ``Action`` to provide a
/// sensible default for [SelectAllTextIntent], while still allowing app
/// developers to change that if they add an ancestor [Actions] widget that maps
/// [SelectAllTextIntent] to a different ``Action``.
///
/// See also:
///
///  * [Shortcuts], which is a widget that contains a key map, in which it looks
///    up key combinations in order to invoke actions.
///  * [Actions], which is a widget that defines a map of [Intent] to ``Action``
///    and allows redefining of actions for its descendants.
///  * ``ActionDispatcher``, a class that takes an ``Action`` and invokes it, passing
///    a given [Intent].
///  * [Action.overridable] for an example on how to make an ``Action``
///    overridable.
public class Action<IntentType: Intent>: ActionProtocol {
    /// Creates an ``Action``.
    public init() {}

    // /// Creates an ``Action`` that allows itself to be overridden by the closest
    // /// ancestor ``Action`` in the given [context] that handles the same [Intent],
    // /// if one exists.
    // ///
    // /// When invoked, the resulting ``Action`` tries to find the closest ``Action`` in
    // /// the given `context` that handles the same type of [Intent] as the
    // /// `defaultAction`, then calls its [Action.invoke] method. When no override
    // /// ``Action``s can be found, it invokes the `defaultAction`.
    // ///
    // /// An overridable action delegates everything to its override if one exists,
    // /// and has the same behavior as its `defaultAction` otherwise. For this
    // /// reason, the override has full control over whether and how an [Intent]
    // /// should be handled, or a key event should be consumed. An override
    // /// ``Action``'s [callingAction] property will be set to the ``Action`` it
    // /// currently overrides, giving it access to the default behavior. See the
    // /// [callingAction] property for an example.
    // ///
    // /// The `context` argument is the ``BuildContext`` to find the override with. It
    // /// is typically a ``BuildContext`` above the [Actions] widget that contains
    // /// this overridable ``Action``.
    // ///
    // /// The `defaultAction` argument is the ``Action`` to be invoked where there's
    // /// no ancestor ``Action``s can't be found in `context` that handle the same
    // /// type of [Intent].
    // ///
    // /// This is useful for providing a set of default ``Action``s in a leaf widget
    // /// to allow further overriding, or to allow the [Intent] to propagate to
    // /// parent widgets that also support this [Intent].
    // ///
    // /// {@tool dartpad}
    // /// This sample shows how to implement a rudimentary `CopyableText` widget
    // /// that responds to Ctrl-C by copying its own content to the clipboard.
    // ///
    // /// if `CopyableText` is to be provided in a package, developers using the
    // /// widget may want to change how copying is handled. As the author of the
    // /// package, you can enable that by making the corresponding ``Action``
    // /// overridable. In the second part of the code sample, three `CopyableText`
    // /// widgets are used to build a verification code widget which overrides the
    // /// "copy" action by copying the combined numbers from all three `CopyableText`
    // /// widgets.
    // ///
    // /// ** See code in examples/api/lib/widgets/actions/action.action_overridable.0.dart **
    // /// {@end-tool}
    // factory Action.overridable({
    //   required Action<T> defaultAction,
    //   required BuildContext context,
    // }) {
    //   return defaultAction._makeOverridableAction(context);
    // }

    var _listeners = [ObjectIdentifier: ActionListenerCallback]()

    // Action<T>? _currentCallingAction;
    // // ignore: use_setters_to_change_properties, (code predates enabling of this lint)
    // void _updateCallingAction(Action<T>? value) {
    //   _currentCallingAction = value;
    // }

    // /// The ``Action`` overridden by this ``Action``.
    // ///
    // /// The [Action.overridable] constructor creates an overridable ``Action`` that
    // /// allows itself to be overridden by the closest ancestor ``Action``, and falls
    // /// back to its own `defaultAction` when no overrides can be found. When an
    // /// override is present, an overridable ``Action`` forwards all incoming
    // /// method calls to the override, and allows the override to access the
    // /// `defaultAction` via its [callingAction] property.
    // ///
    // /// Before forwarding the call to the override, the overridable ``Action`` is
    // /// responsible for setting [callingAction] to its `defaultAction`, which is
    // /// already taken care of by the overridable ``Action`` created using
    // /// [Action.overridable].
    // ///
    // /// This property is only non-null when this ``Action`` is an override of the
    // /// [callingAction], and is currently being invoked from [callingAction].
    // ///
    // /// Invoking [callingAction]'s methods, or accessing its properties, is
    // /// allowed and does not introduce infinite loops or infinite recursions.
    // ///
    // /// {@tool snippet}
    // /// An example `Action` that handles [PasteTextIntent] but has mostly the same
    // /// behavior as the overridable action. It's OK to call
    // /// `callingAction?.isActionEnabled` in the implementation of this `Action`.
    // ///
    // /// ```swift
    // /// class MyPasteAction: Action<PasteTextIntent> {
    // ///   override func invoke(intent: PasteTextIntent) -> Any? {
    // ///     print(intent)
    // ///     return callingAction?.invoke(intent)
    // ///   }
    // ///
    // ///   override var isActionEnabled: Bool {
    // ///     callingAction?.isActionEnabled ?? false
    // ///   }
    // ///
    // ///   override func consumesKey(intent: PasteTextIntent) -> Bool {
    // ///     callingAction?.consumesKey(intent) ?? false
    // ///   }
    // /// }
    // /// ```
    // /// {@end-tool}
    // @protected
    // Action<T>? get callingAction => _currentCallingAction;

    /// Gets the type of intent this action responds to.
    var intentType: Intent.Type { IntentType.self }

    /// Whether this ``Action`` is inherently enabled.
    ///
    /// If [isActionEnabled] is false, then this ``Action`` is disabled for any
    /// given [Intent].
    //
    /// If the enabled state changes, overriding subclasses must call
    /// [notifyActionListeners] to notify any listeners of the change.
    ///
    /// In the case of an overridable `Action`, accessing this property creates
    /// an dependency on the overridable `Action`s `lookupContext`.
    var isActionEnabled: Bool { true }

    public func isEnabled(_ intent: IntentType, context: BuildContext?) -> Bool {
        return isActionEnabled
    }

    /// Indicates whether this action should treat key events mapped to this
    /// action as being "handled" when it is invoked via the key event.
    ///
    /// If the key is handled, then no other key event handlers in the focus chain
    /// will receive the event.
    ///
    /// If the key event is not handled, it will be passed back to the engine, and
    /// continue to be processed there, allowing text fields and non-Flutter
    /// widgets to receive the key event.
    ///
    /// The default implementation returns true.
    func consumesKey(_ intent: IntentType) -> Bool { true }

    public func toKeyEventResult(_ intent: IntentType, invokeResult: Any?) -> KeyEventResult {
        return consumesKey(intent)
            ? .handled
            : .skipRemainingHandlers
    }

    public func invoke(_ intent: IntentType, context: BuildContext?) -> Any? {
        assertionFailure("invoke() must be overridden")
    }

    public func addActionListener(_ listener: AnyObject, callback: @escaping ActionListenerCallback)
    {
        assert(_listeners[ObjectIdentifier(listener)] == nil)
        _listeners[ObjectIdentifier(listener)] = callback
    }

    public func removeActionListener(_ listener: AnyObject) {
        _listeners.removeValue(forKey: ObjectIdentifier(listener))
    }

    /// Call all the registered listeners.
    ///
    /// Subclasses should call this method whenever the object changes, to
    /// notify any clients the object may have changed. Listeners that are added
    /// during this iteration will not be visited. Listeners that are removed
    /// during this iteration will not be visited after they are removed.
    ///
    /// Surprising behavior can result when reentrantly removing a listener
    /// (i.e. in response to a notification) that has been registered multiple
    /// times. See the discussion at [removeActionListener].
    public func notifyActionListeners() {
        if _listeners.isEmpty {
            return
        }

        // Make a local copy so that a listener can unregister while the list is
        // being iterated over.
        let localListeners = _listeners
        for (key, value) in localListeners {
            if _listeners.keys.contains(key) {
                value(self)
            }
        }
    }

    // Action<T> _makeOverridableAction(BuildContext context) {
    //   return _OverridableAction<T>(defaultAction: this, lookupContext: context);
    // }
}

/// The signature of a callback accepted by [CallbackAction.onInvoke].
///
/// Such callbacks are implementations of [Action.invoke]. The returned value
/// is the return value of [Action.invoke], the argument is the intent passed
/// to [Action.invoke], and so forth.
public typealias OnInvokeCallback<T: Intent> = (T) -> Any?

/// An ``Action`` that takes a callback in order to configure it without having to
/// create an explicit ``Action`` subclass just to call a callback.
///
/// See also:
///
///  * [Shortcuts], which is a widget that contains a key map, in which it looks
///    up key combinations in order to invoke actions.
///  * [Actions], which is a widget that defines a map of [Intent] to ``Action``
///    and allows redefining of actions for its descendants.
///  * ``ActionDispatcher``, a class that takes an ``Action`` and invokes it using a
///    [FocusNode] for context.
public class CallbackAction<T: Intent>: Action<T> {
    /// A constructor for a [CallbackAction].
    ///
    /// The given callback is used as the implementation of [invoke].
    public init(onInvoke: @escaping OnInvokeCallback<T>) {
        self.onInvoke = onInvoke
        super.init()
    }

    /// The callback to be called when invoked.
    ///
    /// This is effectively the implementation of [invoke].
    private let onInvoke: OnInvokeCallback<T>

    public override func invoke(_ intent: T, context: BuildContext?) -> Any? {
        return onInvoke(intent)
    }
}
/// An action dispatcher that invokes the actions given to it.
///
/// The [invokeAction] method on this class directly calls the [Action.invoke]
/// method on the ``Action`` object.
///
/// For ``ContextAction`` actions, if no `context` is provided, the
/// ``BuildContext`` of the [primaryFocus] is used instead.
///
/// See also:
///
///  - [ShortcutManager], that uses this class to invoke actions.
///  - [Shortcuts] widget, which defines key mappings to [Intent]s.
///  - [Actions] widget, which defines a mapping between a in [Intent] type and
///    an ``Action``.
public class ActionDispatcher: Diagnosticable {
    /// Creates an action dispatcher that invokes actions directly.
    public init() {}

    /// Invokes the given `action`, passing it the given `intent`.
    ///
    /// The action will be invoked with the given `context`, if given, but only if
    /// the action is a ``ContextAction`` subclass. If no `context` is given, and
    /// the action is a ``ContextAction``, then the context from the [primaryFocus]
    /// is used.
    ///
    /// Returns the object returned from [Action.invoke].
    ///
    /// The caller must receive a `true` result from [Action.isEnabled] before
    /// calling this function (or [ContextAction.isEnabled] with the same
    /// `context`, if the `action` is a ``ContextAction``). This function will
    /// assert if the action is not enabled when called.
    ///
    /// Consider using [invokeActionIfEnabled] to invoke the action conditionally
    /// based on whether it is enabled or not, without having to check first.
    public func invokeAction<T: Intent>(
        _ action: Action<T>,
        _ intent: T,
        _ context: BuildContext? = nil
    ) -> Any? {
        let target = context ?? primaryFocus?.context
        assert(
            action.isEnabled(intent, context: target),
            "Action must be enabled when calling invokeAction"
        )
        return action.invoke(intent, context: target)
    }

    /// Invokes the given `action`, passing it the given `intent`, but only if the
    /// action is enabled.
    ///
    /// The action will be invoked with the given `context`, if given, but only if
    /// the action is a ``ContextAction`` subclass. If no `context` is given, and
    /// the action is a ``ContextAction``, then the context from the [primaryFocus]
    /// is used.
    ///
    /// The return value has two components. The first is a boolean indicating if
    /// the action was enabled (as per [Action.isEnabled]). If this is false, the
    /// second return value is null. Otherwise, the second return value is the
    /// object returned from [Action.invoke].
    ///
    /// Consider using [invokeAction] if the enabled state of the action is not in
    /// question; this avoids calling [Action.isEnabled] redundantly.
    public func invokeActionIfEnabled<T: Intent>(
        _ action: Action<T>,
        _ intent: T,
        _ context: BuildContext? = nil
    ) -> (Bool, Any?) {
        let target = context ?? primaryFocus?.context
        if action.isEnabled(intent, context: target) {
            return (true, action.invoke(intent, context: target))
        }
        return (false, nil)
    }
}

/// A widget that maps [Intent]s to ``Action``s to be used by its descendants
/// when invoking an ``Action``.
///
/// Actions are typically invoked using [Shortcuts]. They can also be invoked
/// using ``Actions/invoke`` on a context containing an ambient [Actions] widget.
///
/// See also:
///
///  * [Shortcuts], a widget used to bind key combinations to [Intent]s.
///  * [Intent], a class that contains configuration information for running an
///    ``Action``.
///  * ``Action``, a class for containing and defining an invocation of a user
///    action.
///  * ``ActionDispatcher``, the object that this widget uses to manage actions.
public final class Actions: StatefulWidget {
    /// Creates an Actions widget.
    public init(
        dispatcher: ActionDispatcher? = nil,
        actions: [any ActionProtocol],
        @WidgetBuilder child: () -> Widget
    ) {
        self.dispatcher = dispatcher
        self.actions = actions
        self.child = child()
    }

    /// The ActionDispatcher object that invokes actions.
    ///
    /// This is what is returned from Actions.of, and used by Actions.invoke.
    ///
    /// If this dispatcher is null, then Actions.of and Actions.invoke will
    /// look up the tree until they find an Actions widget that has a dispatcher
    /// set. If no such widget is found, then they will return/use a
    /// default-constructed ActionDispatcher.
    public let dispatcher: ActionDispatcher?

    /// A map of Intent keys to ActionProtocol objects that defines which
    /// actions this widget knows about.
    ///
    /// For performance reasons, it is recommended that a pre-built map is
    /// passed in here (e.g. a final variable from your widget class) instead of
    /// defining it inline in the build function.
    public let actions: [any ActionProtocol]

    /// The child widget
    public let child: Widget

    // Visits the Actions widget ancestors of the given element using
    // getElementForInheritedWidgetOfExactType. Returns true if the visitor found
    // what it was looking for.
    static func visitActionsAncestors(
        _ context: BuildContext,
        _ visitor: (InheritedElement) -> Bool
    ) -> Bool {
        if !context.mounted {
            return false
        }
        var actionsElement = context.getElementForInheritedWidgetOfExactType(ActionsScope.self)
        while actionsElement != nil {
            if visitor(actionsElement!) {
                break
            }
            // _getParent is needed here because
            // context.getElementForInheritedWidgetOfExactType will return itself if it
            // happens to be of the correct type.
            let parent = actionsElement!.parent!
            actionsElement = parent.getElementForInheritedWidgetOfExactType(ActionsScope.self)
        }
        return actionsElement != nil
    }

    // Finds the nearest valid ActionDispatcher, or creates a new one if it
    // doesn't find one.
    static func findDispatcher(_ context: BuildContext) -> ActionDispatcher {
        var dispatcher: ActionDispatcher?
        _ = visitActionsAncestors(context) { element in
            let found = (element.widget as! ActionsScope).dispatcher
            if let found {
                dispatcher = found
                return true
            }
            return false
        }
        return dispatcher ?? ActionDispatcher()
    }

    /// Returns a [VoidCallback] handler that invokes the bound action for the
    /// given `intent` if the action is enabled, and returns null if the action is
    /// not enabled, or no matching action is found.
    ///
    /// This is intended to be used in widgets which have something similar to an
    /// `onTap` handler, which takes a `VoidCallback`, and can be set to the
    /// result of calling this function.
    ///
    /// Creates a dependency on the [Actions] widget that maps the bound action so
    /// that if the actions change, the context will be rebuilt and find the
    /// updated action.
    ///
    /// The value returned from the [Action.invoke] method is discarded when the
    /// returned callback is called. If the return value is needed, consider using
    /// ``Actions/invoke`` instead.
    static func handler<T: Intent>(_ context: BuildContext, _ intent: T) -> VoidCallback? {
        let action = Actions.maybeFind(context) as Action<T>?
        if let action, action.isEnabled(intent, context: context) {
            return {
                // Could be that the action was enabled when the closure was created,
                // but is now no longer enabled, so check again.
                if action.isEnabled(intent, context: context) {
                    _ = Actions.of(context).invokeAction(action, intent, context)
                }
            }
        }
        return nil
    }

    /// Finds the ``Action`` bound to the given intent type `T` in the given `context`.
    ///
    /// Creates a dependency on the [Actions] widget that maps the bound action so
    /// that if the actions change, the context will be rebuilt and find the
    /// updated action.
    ///
    /// The optional `intent` argument supplies the type of the intent to look for
    /// if the concrete type of the intent sought isn't available. If not
    /// supplied, then `T` is used.
    ///
    /// If no [Actions] widget surrounds the given context, this function will
    /// assert in debug mode, and throw an exception in release mode.
    ///
    /// See also:
    ///
    ///  * [maybeFind], which is similar to this function, but will return null if
    ///    no [Actions] ancestor is found.
    static func find<T: Intent>(_ context: BuildContext) -> Action<T> {
        let action = maybeFind(context) as Action<T>?

        assert(
            action != nil,
            "Unable to find an action for a \(T.self) in an Actions widget "
                + "in the given context.\n"
                + "Actions.find() was called on a context that doesn't contain an "
                + "Actions widget with a mapping for the given intent type.\n"
                + "The context used was:\n" + "  \(context)\n"
                + "The intent type requested was:\n" + "  \(T.self)"
        )

        return action!
    }

    /// Finds the ``Action`` bound to the given intent type `T` in the given `context`.
    ///
    /// Creates a dependency on the [Actions] widget that maps the bound action so
    /// that if the actions change, the context will be rebuilt and find the
    /// updated action.
    ///
    /// The optional `intent` argument supplies the type of the intent to look for
    /// if the concrete type of the intent sought isn't available. If not
    /// supplied, then `T` is used.
    ///
    /// If no [Actions] widget surrounds the given context, this function will
    /// return null.
    ///
    /// See also:
    ///
    ///  * [find], which is similar to this function, but will throw if
    ///    no [Actions] ancestor is found.
    static func maybeFind<T: Intent>(_ context: BuildContext) -> Action<T>? {
        var action: Action<T>?

        _ = visitActionsAncestors(context) { element in
            let actionScope = element.widget as! ActionsScope
            if let result: Action<T> = findAction(actionScope.actions) {
                _ = context.dependOnInheritedElement(element)
                action = result
                return true
            }
            return false
        }

        return action
    }

    static func _maybeFindWithoutDependingOn<T: Intent>(
        _ context: BuildContext,
        intentType: Intent.Type
    )
        -> Action<T>?
    {
        var action: Action<T>?

        _ = visitActionsAncestors(context) { element in
            let actionScope = element.widget as! ActionsScope
            if let result = findAction(actionScope.actions) as? Action<T> {
                action = result
                return true
            }
            return false
        }

        return action
    }

    // Find the ``Action`` that handles the given `intent` in the given
    // `ActionsScope`, and verify it has the right type parameter.
    private static func findAction<T: Intent>(_ actions: [any ActionProtocol])
        -> Action<T>?
    {
        for action in actions {
            if let action = action as? Action<T> {
                return action
            }
        }
        return nil
    }

    /// Returns the ``ActionDispatcher`` associated with the [Actions] widget that
    /// most tightly encloses the given ``BuildContext``.
    ///
    /// Will return a newly created ``ActionDispatcher`` if no ambient [Actions]
    /// widget is found.
    public static func of(_ context: BuildContext) -> ActionDispatcher {
        let marker = context.dependOnInheritedWidgetOfExactType(ActionsScope.self)
        return marker?.dispatcher ?? findDispatcher(context)
    }

    /// Invokes the action associated with the given [Intent] using the
    /// [Actions] widget that most tightly encloses the given ``BuildContext``.
    ///
    /// This method returns the result of invoking the action's [Action.invoke]
    /// method.
    ///
    /// If the given `intent` doesn't map to an action, then it will look to the
    /// next ancestor [Actions] widget in the hierarchy until it reaches the root.
    ///
    /// This method will throw an exception if no ambient [Actions] widget is
    /// found, or when a suitable ``Action`` is found but it returns false for
    /// [Action.isEnabled].
    public static func invoke<T: Intent>(
        _ context: BuildContext,
        _ intent: T
    ) -> Any? {
        var returnValue: Any?

        let actionFound = visitActionsAncestors(context) { element in
            let actions = element.widget as! ActionsScope
            let result: Action<T>? = findAction(actions.actions)
            if let result, result.isEnabled(intent, context: context) {
                // Invoke the action we found using the relevant dispatcher from the Actions
                // Element we found.
                returnValue = findDispatcher(element).invokeAction(result, intent, context)
            }
            return result != nil
        }

        assert(
            {
                if !actionFound {
                    assertionFailure(
                        """
                        Unable to find an action for an Intent with type \
                        \(String(describing: T.self)) in an Actions widget in the given context.
                        Actions.invoke() was unable to find an Actions widget that \
                        contained a mapping for the given intent, or the intent type isn't the \
                        same as the type argument to invoke (which is \(T.self) - try supplying a \
                        type argument to invoke if one was not given)
                        The context used was:
                          \(context)
                        The intent type requested was:
                          \(String(describing: T.self))
                        """
                    )
                }
                return true
            }()
        )
        return returnValue
    }

    /// Invokes the action associated with the given [Intent] using the
    /// [Actions] widget that most tightly encloses the given ``BuildContext``.
    ///
    /// This method returns the result of invoking the action's [Action.invoke]
    /// method. If no action mapping was found for the specified intent, or if the
    /// first action found was disabled, or the action itself returns null
    /// from [Action.invoke], then this method returns null.
    ///
    /// If the given `intent` doesn't map to an action, then it will look to the
    /// next ancestor [Actions] widget in the hierarchy until it reaches the root.
    /// If a suitable ``Action`` is found but its [Action.isEnabled] returns false,
    /// the search will stop and this method will return null.
    public static func maybeInvoke<T: Intent>(
        _ context: BuildContext,
        _ intent: T
    ) -> Any? {
        var returnValue: Any?
        _ = visitActionsAncestors(context) { element in
            let actions = element.widget as! ActionsScope
            let result: Action<T>? = findAction(actions.actions)
            if let result, result.isEnabled(intent, context: context) {
                // Invoke the action we found using the relevant dispatcher from the Actions
                // element we found.
                returnValue = findDispatcher(element).invokeAction(result, intent, context)
            }
            return result != nil
        }
        return returnValue
    }

    public func createState() -> some State<Actions> {
        ActionState()
    }
}

private class ActionState: State<Actions> {
    // The set of actions that this Actions widget is current listening to.
    var listenedActions: Set<AnyAction>? = Set<AnyAction>()
    // Used to tell the marker to rebuild its dependencies when the state of an
    // action in the map changes.
    fileprivate var rebuildKey = _RebuildKey()

    override func initState() {
        super.initState()
        _updateActionListeners()
    }

    func _handleActionChanged(_ action: any ActionProtocol) {
        // Generate a new key so that the marker notifies dependents.
        setState { rebuildKey = _RebuildKey() }
    }

    func _updateActionListeners() {
        let widgetActions = Set(widget.actions.map { AnyAction($0) })
        let removedActions = listenedActions?.subtracting(widgetActions) ?? Set()
        let addedActions = widgetActions.subtracting(listenedActions ?? Set())

        for action in removedActions {
            action.inner.removeActionListener(self)
        }
        for action in addedActions {
            action.inner.addActionListener(self, callback: _handleActionChanged)
        }
        listenedActions = widgetActions
    }

    override func didUpdateWidget(_ oldWidget: Actions) {
        super.didUpdateWidget(oldWidget)
        _updateActionListeners()
    }

    override func dispose() {
        super.dispose()
        for action in listenedActions! {
            action.inner.removeActionListener(self)
        }
        listenedActions = nil
    }

    override func build(context: BuildContext) -> Widget {
        return ActionsScope(
            dispatcher: widget.dispatcher,
            actions: widget.actions,
            rebuildKey: rebuildKey,
            child: widget.child
        )
    }
}

// An inherited widget used by Actions widget for fast lookup of the Actions
// widget information.
private final class ActionsScope: InheritedWidget {
    init(
        dispatcher: ActionDispatcher?,
        actions: [any ActionProtocol],
        rebuildKey: _RebuildKey,
        child: Widget
    ) {
        self.dispatcher = dispatcher
        self.actions = actions
        self.rebuildKey = rebuildKey
        self.child = child
    }

    let dispatcher: ActionDispatcher?
    let actions: [any ActionProtocol]
    let rebuildKey: _RebuildKey
    let child: Widget

    func updateShouldNotify(_ oldWidget: ActionsScope) -> Bool {
        return rebuildKey !== oldWidget.rebuildKey
            || oldWidget.dispatcher !== dispatcher
            || !objectsEqual(actions, oldWidget.actions)
    }

}

private class _RebuildKey {}
