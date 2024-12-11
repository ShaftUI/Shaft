// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Signature of a callback used by [Focus.onKeyEvent] and [FocusScope.onKeyEvent]
/// to receive key events.
///
/// The [node] is the node that received the event.
///
/// Returns a [KeyEventResult] that describes how, and whether, the key event
/// was handled.
public typealias FocusOnKeyEventCallback = (FocusNode, KeyEvent) -> KeyEventResult

/// A widget that manages a [FocusNode] to allow keyboard focus to be given to
/// this widget and its descendants.
///
/// When the focus is gained or lost, [onFocusChange] is called.
///
/// For keyboard events, [onKey] and [onKeyEvent] are called if
/// [FocusNode.hasFocus] is true for this widget's [focusNode], unless a focused
/// descendant's [onKey] or [onKeyEvent] callback returned
/// [KeyEventResult.handled] when called.
///
/// This widget does not provide any visual indication that the focus has
/// changed. Any desired visual changes should be made when [onFocusChange] is
/// called.
///
/// To access the [FocusNode] of the nearest ancestor [Focus] widget and
/// establish a relationship that will rebuild the widget when the focus
/// changes, use the [Focus.of] and [FocusScope.of] static methods.
///
/// To access the focused state of the nearest [Focus] widget, use
/// [FocusNode.hasFocus] from a build method, which also establishes a
/// relationship between the calling widget and the [Focus] widget that will
/// rebuild the calling widget when the focus changes.
///
/// Managing a [FocusNode] means managing its lifecycle, listening for changes
/// in focus, and re-parenting it when needed to keep the focus hierarchy in
/// sync with the widget hierarchy. This widget does all of those things for
/// you. See [FocusNode] for more information about the details of what node
/// management entails if you are not using a [Focus] widget and you need to do
/// it yourself.
///
/// If the [Focus] default constructor is used, then this widget will manage any
/// given [focusNode] by overwriting the appropriate values of the [focusNode]
/// with the values of [FocusNode.onKey], [FocusNode.onKeyEvent],
/// [FocusNode.skipTraversal], [FocusNode.canRequestFocus], and
/// [FocusNode.descendantsAreFocusable] whenever the [Focus] widget is updated.
///
/// If the [Focus.withExternalFocusNode] is used instead, then the values
/// returned by [onKey], [onKeyEvent], [skipTraversal], [canRequestFocus], and
/// [descendantsAreFocusable] will be the values in the external focus node, and
/// the external focus node's values will not be overwritten when the widget is
/// updated.
///
/// To collect a sub-tree of nodes into an exclusive group that restricts focus
/// traversal to the group, use a [FocusScope]. To collect a sub-tree of nodes
/// into a group that has a specific order to its traversal but allows the
/// traversal to escape the group, use a [FocusTraversalGroup].
///
/// To move the focus, use methods on [FocusNode] by getting the [FocusNode]
/// through the [of] method. For instance, to move the focus to the next node in
/// the focus traversal order, call `Focus.of(context).nextFocus()`. To unfocus
/// a widget, call `Focus.of(context).unfocus()`.
public class Focus: StatefulWidget {
    public init(
        key: (any Key)? = nil,
        parentNode: FocusNode? = nil,
        focusNode: FocusNode? = nil,
        autofocus: Bool = false,
        onFocusChange: ValueChanged<Bool>? = nil,
        onKeyEvent: FocusOnKeyEventCallback? = nil,
        canRequestFocus: Bool? = nil,
        skipTraversal: Bool? = nil,
        descendantsAreFocusable: Bool? = nil,
        descendantsAreTraversable: Bool? = nil,
        includeSemantics: Bool = true,
        debugLabel: String? = nil,
        @WidgetBuilder child: () -> Widget
    ) {
        self.key = key
        self.parentNode = parentNode
        self.focusNode = focusNode
        self.autofocus = autofocus
        self.onFocusChange = onFocusChange
        self._onKeyEvent = onKeyEvent
        self._canRequestFocus = canRequestFocus
        self._skipTraversal = skipTraversal
        self._descendantsAreFocusable = descendantsAreFocusable
        self._descendantsAreTraversable = descendantsAreTraversable
        self.includeSemantics = includeSemantics
        self.debugLabel = debugLabel
        self.child = child()
    }

    public let key: (any Key)?

    // Indicates whether the widget's focusNode attributes should have priority
    // when then widget is updated.
    fileprivate var usingExternalFocus: Bool {
        return false
    }

    /// The optional parent node to use when reparenting the [focusNode] for
    /// this [Focus] widget.
    ///
    /// If [parentNode] is null, then [Focus.maybeOf] is used to find the parent
    /// in the widget tree, which is typically what is desired, since it is
    /// easier to reason about the focus tree if it mirrors the shape of the
    /// widget tree.
    ///
    /// Set this property if the focus tree needs to have a different shape than
    /// the widget tree. This is typically in cases where a dialog is in an
    /// [Overlay] (or another part of the widget tree), and focus should behave
    /// as if the widgets in the overlay are descendants of the given
    /// [parentNode] for purposes of focus.
    ///
    /// Defaults to null.
    public let parentNode: FocusNode?

    /// An optional focus node to use as the focus node for this widget.
    ///
    /// If one is not supplied, then one will be automatically allocated, owned,
    /// and managed by this widget. The widget will be focusable even if a
    /// [focusNode] is not supplied. If supplied, the given [focusNode] will be
    /// _hosted_ by this widget, but not owned. See [FocusNode] for more
    /// information on what being hosted and/or owned implies.
    ///
    /// Supplying a focus node is sometimes useful if an ancestor to this widget
    /// wants to control when this widget has the focus. The owner will be
    /// responsible for calling [FocusNode.dispose] on the focus node when it is
    /// done with it, but this widget will attach/detach and reparent the node
    /// when needed.
    ///
    /// A non-null [focusNode] must be supplied if using the
    /// [Focus.withExternalFocusNode] constructor.
    public let focusNode: FocusNode?

    /// True if this widget will be selected as the initial focus when no other
    /// node in its scope is currently focused.
    ///
    /// Ideally, there is only one widget with autofocus set in each [FocusScope].
    /// If there is more than one widget with autofocus set, then the first one
    /// added to the tree will get focus.
    ///
    /// Defaults to false.
    public let autofocus: Bool

    /// Handler called when the focus changes.
    ///
    /// Called with true if this widget's node gains focus, and false if it loses
    /// focus.
    public let onFocusChange: ValueChanged<Bool>?

    /// A handler for keys that are pressed when this object or one of its
    /// children has focus.
    ///
    /// Key events are first given to the [FocusNode] that has primary focus, and
    /// if its [onKeyEvent] method returns [KeyEventResult.ignored], then they are
    /// given to each ancestor node up the focus hierarchy in turn. If an event
    /// reaches the root of the hierarchy, it is discarded.
    ///
    /// This is not the way to get text input in the manner of a text field: it
    /// leaves out support for input method editors, and doesn't support soft
    /// keyboards in general. For text input, consider [TextField],
    /// [EditableText], or [CupertinoTextField] instead, which do support these
    /// things.
    //   FocusOnKeyEventCallback? get onKeyEvent => _onKeyEvent ?? focusNode?.onKeyEvent;
    private let _onKeyEvent: FocusOnKeyEventCallback?
    public var onKeyEvent: FocusOnKeyEventCallback? {
        _onKeyEvent ?? focusNode?.onKeyEvent
    }

    /// If true, this widget may request the primary focus.
    ///
    /// Defaults to true. Set to false if you want the [FocusNode] this widget
    /// manages to do nothing when [FocusNode.requestFocus] is called on it. Does
    /// not affect the children of this node, and [FocusNode.hasFocus] can still
    /// return true if this node is the ancestor of the primary focus.
    ///
    /// This is different than [Focus.skipTraversal] because [Focus.skipTraversal]
    /// still allows the widget to be focused, just not traversed to.
    ///
    /// Setting [FocusNode.canRequestFocus] to false implies that the widget will
    /// also be skipped for traversal purposes.
    ///
    /// See also:
    ///
    /// * [FocusTraversalGroup], a widget that sets the traversal policy for its
    ///   descendants.
    /// * [FocusTraversalPolicy], a class that can be extended to describe a
    ///   traversal policy.
    public var canRequestFocus: Bool {
        _canRequestFocus ?? focusNode?.canRequestFocus ?? true
    }
    fileprivate let _canRequestFocus: Bool?

    /// Sets the [FocusNode.skipTraversal] flag on the focus node so that it won't
    /// be visited by the [FocusTraversalPolicy].
    ///
    /// This is sometimes useful if a [Focus] widget should receive key events as
    /// part of the focus chain, but shouldn't be accessible via focus traversal.
    ///
    /// This is different from [FocusNode.canRequestFocus] because it only implies
    /// that the widget can't be reached via traversal, not that it can't be
    /// focused. It may still be focused explicitly.
    public var skipTraversal: Bool {
        _skipTraversal ?? focusNode?.skipTraversal ?? false
    }
    private let _skipTraversal: Bool?

    /// If false, will make this widget's descendants unfocusable.
    ///
    /// Defaults to true. Does not affect focusability of this node (just its
    /// descendants): for that, use [FocusNode.canRequestFocus].
    ///
    /// If any descendants are focused when this is set to false, they will be
    /// unfocused. When [descendantsAreFocusable] is set to true again, they will
    /// not be refocused, although they will be able to accept focus again.
    ///
    /// Does not affect the value of [FocusNode.canRequestFocus] on the
    /// descendants.
    ///
    /// If a descendant node loses focus when this value is changed, the focus
    /// will move to the scope enclosing this node.
    ///
    /// See also:
    ///
    /// * [ExcludeFocus], a widget that uses this property to conditionally
    ///   exclude focus for a subtree.
    /// * [descendantsAreTraversable], which makes this widget's descendants
    ///   untraversable.
    /// * [ExcludeFocusTraversal], a widget that conditionally excludes focus
    ///   traversal for a subtree.
    /// * [FocusTraversalGroup], a widget used to group together and configure the
    ///   focus traversal policy for a widget subtree that has a
    ///   `descendantsAreFocusable` parameter to conditionally block focus for a
    ///   subtree.
    public var descendantsAreFocusable: Bool {
        _descendantsAreFocusable ?? focusNode?.descendantsAreFocusable ?? true
    }
    private let _descendantsAreFocusable: Bool?

    /// If false, will make this widget's descendants untraversable.
    ///
    /// Defaults to true. Does not affect traversability of this node (just its
    /// descendants): for that, use [FocusNode.skipTraversal].
    ///
    /// Does not affect the value of [FocusNode.skipTraversal] on the
    /// descendants. Does not affect focusability of the descendants.
    ///
    /// See also:
    ///
    /// * [ExcludeFocusTraversal], a widget that uses this property to
    ///   conditionally exclude focus traversal for a subtree.
    /// * [descendantsAreFocusable], which makes this widget's descendants
    ///   unfocusable.
    /// * [ExcludeFocus], a widget that conditionally excludes focus for a subtree.
    /// * [FocusTraversalGroup], a widget used to group together and configure the
    ///   focus traversal policy for a widget subtree that has a
    ///   `descendantsAreFocusable` parameter to conditionally block focus for a
    ///   subtree.
    public var descendantsAreTraversable: Bool {
        _descendantsAreTraversable ?? focusNode?.descendantsAreTraversable ?? true
    }
    private let _descendantsAreTraversable: Bool?

    /// Include semantics information in this widget.
    ///
    /// If true, this widget will include a [Semantics] node that indicates the
    /// [SemanticsProperties.focusable] and [SemanticsProperties.focused]
    /// properties.
    ///
    /// It is not typical to set this to false, as that can affect the semantics
    /// information available to accessibility systems.
    ///
    /// Defaults to true.
    public let includeSemantics: Bool

    /// A debug label for this widget.
    ///
    /// Not used for anything except to be printed in the diagnostic output from
    /// [toString] or [toStringDeep].
    ///
    /// To get a string with the entire tree, call [debugDescribeFocusTree]. To
    /// print it to the console call [debugDumpFocusTree].
    ///
    /// Defaults to null.
    //   String? get debugLabel => _debugLabel ?? focusNode?.debugLabel;
    public let debugLabel: String?

    /// The child widget of this [Focus].
    public let child: Widget

    /// Returns the [focusNode] of the [Focus] that most tightly encloses the
    /// given [BuildContext].
    ///
    /// If no [Focus] node is found before reaching the nearest [FocusScope]
    /// widget, or there is no [Focus] widget in scope, then this method will
    /// return null.
    ///
    /// If `createDependency` is true (which is the default), calling this
    /// function creates a dependency that will rebuild the given context when
    /// the focus node gains or loses focus.
    ///
    /// See also:
    ///
    /// * [of], which is similar to this function, but will throw an exception
    ///   if it doesn't find a [Focus] node, instead of returning null.
    public static func maybeOf(
        _ context: BuildContext,
        scopeOk: Bool = false,
        createDependency: Bool = true
    ) -> FocusNode? {
        let scope =
            if createDependency {
                context.dependOnInheritedWidgetOfExactType(FocusInheritedScope.self)
            } else {
                context.getInheritedWidgetOfExactType(FocusInheritedScope.self)
            }
        let node = scope?.notifier
        if node == nil {
            return nil
        }
        if !scopeOk && node is FocusScopeNode {
            return nil
        }
        return node
    }

    public func createState() -> FocusState {
        FocusState()
    }
}

/// The InheritedWidget for Focus and FocusScope.
private class FocusInheritedScope: InheritedNotifier<FocusNode> {}

public class FocusState: State<Focus> {
    private var internalNode: FocusNode?
    public var focusNode: FocusNode { internalNode ?? widget.focusNode! }

    private var hadPrimaryFocus: Bool = false
    private var couldRequestFocus: Bool = false
    private var descendantsWereFocusable: Bool = false
    private var descendantsWereTraversable: Bool = false
    fileprivate var focusAttachment: FocusAttachment?

    public override func initState() {
        super.initState()
        initNode()
    }

    private func initNode() {
        if widget.focusNode == nil {
            // Only create a new node if the widget doesn't have one.
            // This calls a function instead of just allocating in place because
            // _createNode is overridden in _FocusScopeState.
            internalNode = internalNode ?? createNode()
        }
        focusNode.descendantsAreFocusable = widget.descendantsAreFocusable
        focusNode.descendantsAreTraversable = widget.descendantsAreTraversable
        focusNode.skipTraversal = widget.skipTraversal
        if let canRequestFocus = widget._canRequestFocus {
            focusNode.canRequestFocus = canRequestFocus
        }
        couldRequestFocus = focusNode.canRequestFocus
        descendantsWereFocusable = focusNode.descendantsAreFocusable
        descendantsWereTraversable = focusNode.descendantsAreTraversable
        hadPrimaryFocus = focusNode.hasPrimaryFocus
        focusAttachment = focusNode.attach(
            context,
            onKeyEvent: widget.onKeyEvent
        )

        // Add listener even if the _internalNode existed before, since it should
        // not be listening now if we're re-using a previous one because it should
        // have already removed its listener.
        focusNode.addListener(self, callback: handleFocusChanged)
    }

    /// Overriden in FocusScopeState.
    fileprivate func createNode() -> FocusNode {
        return FocusNode(
            skipTraversal: widget.skipTraversal,
            canRequestFocus: widget.canRequestFocus,
            descendantsAreFocusable: widget.descendantsAreFocusable,
            descendantsAreTraversable: widget.descendantsAreTraversable,
            debugLabel: widget.debugLabel
        )
    }

    public override func dispose() {
        // Regardless of the node owner, we need to remove it from the tree and stop
        // listening to it.
        focusNode.removeListener(self)
        focusAttachment!.detach()

        // Don't manage the lifetime of external nodes given to the widget, just the
        // internal node.
        internalNode?.dispose()
        super.dispose()
    }

    public override func didChangeDependencies() {
        super.didChangeDependencies()
        focusAttachment?.reparent()
        handleAutofocus()
    }

    private var didAutofocus: Bool = false

    private func handleAutofocus() {
        if !didAutofocus && widget.autofocus {
            FocusScope.of(context).autofocus(focusNode)
            didAutofocus = true
        }
    }

    public override func deactivate() {
        super.deactivate()
        // The focus node's location in the tree is no longer valid here. But we
        // can't unfocus or remove the node from the tree because if the widget
        // is moved to a different part of the tree (via global key) it should
        // retain its focus state. That's why we temporarily park it on the root
        // focus node (via reparent) until it either gets moved to a different
        // part of the tree (via didChangeDependencies) or until it is disposed.
        focusAttachment?.reparent()
        didAutofocus = false
    }

    public override func didUpdateWidget(_ oldWidget: Focus) {
        super.didUpdateWidget(oldWidget)
        assert {
            // Only update the debug label in debug builds.
            if oldWidget.focusNode == widget.focusNode && !widget.usingExternalFocus
                && oldWidget.debugLabel != widget.debugLabel
            {
                focusNode.debugLabel = widget.debugLabel
            }
            return true
        }

        if oldWidget.focusNode == widget.focusNode {
            if !widget.usingExternalFocus {
                focusNode.onKeyEvent = widget.onKeyEvent
                focusNode.skipTraversal = widget.skipTraversal
                if widget._canRequestFocus != nil {
                    focusNode.canRequestFocus = widget._canRequestFocus!
                }
                focusNode.descendantsAreFocusable = widget.descendantsAreFocusable
                focusNode.descendantsAreTraversable = widget.descendantsAreTraversable
            }
        } else {
            focusAttachment!.detach()
            oldWidget.focusNode?.removeListener(self)
            initNode()
        }

        if oldWidget.autofocus != widget.autofocus {
            handleAutofocus()
        }
    }

    private func handleFocusChanged() {
        let hasPrimaryFocus = focusNode.hasPrimaryFocus
        let canRequestFocus = focusNode.canRequestFocus
        let descendantsAreFocusable = focusNode.descendantsAreFocusable
        let descendantsAreTraversable = focusNode.descendantsAreTraversable
        widget.onFocusChange?(focusNode.hasFocus)
        // Check the cached states that matter here, and call setState if they
        // have changed.
        if hadPrimaryFocus != hasPrimaryFocus {
            setState {
                hadPrimaryFocus = hasPrimaryFocus
            }
        }
        if couldRequestFocus != canRequestFocus {
            setState {
                couldRequestFocus = canRequestFocus
            }
        }
        if descendantsWereFocusable != descendantsAreFocusable {
            setState {
                descendantsWereFocusable = descendantsAreFocusable
            }
        }
        if descendantsWereTraversable != descendantsAreTraversable {
            setState {
                descendantsWereTraversable = descendantsAreTraversable
            }
        }
    }

    public override func build(context: BuildContext) -> Widget {
        focusAttachment!.reparent(parent: widget.parentNode)
        let child = widget.child
        // if (widget.includeSemantics) {
        //   child = Semantics(
        //     focusable: _couldRequestFocus,
        //     focused: _hadPrimaryFocus,
        //     child: widget.child,
        //   );
        // }
        return FocusInheritedScope(
            notifier: focusNode,
            child: child
        )
    }
}

/// A [FocusScope] is similar to a [Focus], but also serves as a scope for its
/// descendants, restricting focus traversal to the scoped controls.
///
/// For example a new [FocusScope] is created automatically when a route is
/// pushed, keeping the focus traversal from moving to a control in a previous
/// route.
///
/// If you just want to group widgets together in a group so that they are
/// traversed in a particular order, but the focus can still leave the group,
/// use a [FocusTraversalGroup].
///
/// Like [Focus], [FocusScope] provides an [onFocusChange] as a way to be
/// notified when the focus is given to or removed from this widget.
///
/// The [onKey] argument allows specification of a key event handler that is
/// invoked when this node or one of its children has focus. Keys are handed to
/// the primary focused widget first, and then they propagate through the
/// ancestors of that node, stopping if one of them returns
/// [KeyEventResult.handled] from [onKey], indicating that it has handled the
/// event.
///
/// Managing a [FocusScopeNode] means managing its lifecycle, listening for
/// changes in focus, and re-parenting it when needed to keep the focus
/// hierarchy in sync with the widget hierarchy. This widget does all of those
/// things for you. See [FocusScopeNode] for more information about the details
/// of what node management entails if you are not using a [FocusScope] widget
/// and you need to do it yourself.
///
/// [FocusScopeNode]s remember the last [FocusNode] that was focused within
/// their descendants, and can move that focus to the next/previous node, or a
/// node in a particular direction when the [FocusNode.nextFocus],
/// [FocusNode.previousFocus], or [FocusNode.focusInDirection] are called on a
/// [FocusNode] or [FocusScopeNode].
///
/// To move the focus, use methods on [FocusNode] by getting the [FocusNode]
/// through the [of] method. For instance, to move the focus to the next node in
/// the focus traversal order, call `Focus.of(context).nextFocus()`. To unfocus
/// a widget, call `Focus.of(context).unfocus()`.
public class FocusScope: Focus {
    public init(
        parentNode: FocusNode? = nil,
        focusNode: FocusScopeNode? = nil,
        autofocus: Bool = false,
        onFocusChange: ValueChanged<Bool>? = nil,
        onKeyEvent: FocusOnKeyEventCallback? = nil,
        canRequestFocus: Bool? = nil,
        skipTraversal: Bool? = nil,
        descendantsAreFocusable: Bool? = nil,
        descendantsAreTraversable: Bool? = nil,
        includeSemantics: Bool = true,
        debugLabel: String? = nil,
        @WidgetBuilder child: () -> Widget
    ) {
        super.init(
            parentNode: parentNode,
            focusNode: focusNode,
            autofocus: autofocus,
            onFocusChange: onFocusChange,
            onKeyEvent: onKeyEvent,
            canRequestFocus: canRequestFocus,
            skipTraversal: skipTraversal,
            descendantsAreFocusable: descendantsAreFocusable,
            descendantsAreTraversable: descendantsAreTraversable,
            includeSemantics: includeSemantics,
            debugLabel: debugLabel,
            child: child
        )
    }

    /// Returns the [FocusNode.nearestScope] of the [Focus] or [FocusScope] that
    /// most tightly encloses the given [context].
    ///
    /// If this node doesn't have a [Focus] or [FocusScope] widget ancestor, then
    /// the [FocusManager.rootScope] is returned.
    public static func of(
        _ context: BuildContext,
        createDependency: Bool = true
    ) -> FocusScopeNode {
        return Focus.maybeOf(context, scopeOk: true, createDependency: createDependency)?
            .nearestScope ?? context.owner!.focusManager.rootScope
    }

    public override func createState() -> FocusState {
        FocusScopeState()
    }
}

private class FocusScopeState: FocusState {
    override func createNode() -> FocusNode {
        return FocusScopeNode(
            skipTraversal: widget.skipTraversal,
            canRequestFocus: widget.canRequestFocus,
            debugLabel: widget.debugLabel
        )
    }

    override func build(context: BuildContext) -> Widget {
        focusAttachment!.reparent(parent: widget.parentNode)
        return FocusInheritedScope(
            notifier: focusNode,
            child: widget.child
        )
    }
}
