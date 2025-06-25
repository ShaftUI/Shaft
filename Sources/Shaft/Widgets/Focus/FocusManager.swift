// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An enum that describes how to handle a key event handled by a
/// [FocusOnKeyCallback] or [FocusOnKeyEventCallback].
public enum KeyEventResult {
    /// The key event has been handled, and the event should not be propagated
    /// to other key event handlers.

    case handled
    /// The key event has not been handled, and the event should continue to be
    /// propagated to other key event handlers, even non-Flutter ones.
    case ignored

    /// The key event has not been handled, but the key event should not be
    /// propagated to other key event handlers.
    ///
    /// It will be returned to the platform embedding to be propagated to text
    /// fields and non-Flutter key event handlers on the platform.
    case skipRemainingHandlers
}

public class FocusNode: ChangeNotifier, HashableObject {
    public init(
        skipTraversal: Bool = false,
        canRequestFocus: Bool = true,
        descendantsAreFocusable: Bool = true,
        descendantsAreTraversable: Bool = true,
        debugLabel: String? = nil
    ) {
        self._skipTraversal = skipTraversal
        self._canRequestFocus = canRequestFocus
        self.descendantsAreFocusable = descendantsAreFocusable
        self.descendantsAreTraversable = descendantsAreTraversable
        self.debugLabel = debugLabel
    }

    /// If true, tells the focus traversal policy to skip over this node for
    /// purposes of the traversal algorithm.
    ///
    /// This may be used to place nodes in the focus tree that may be focused,
    /// but not traversed, allowing them to receive key events as part of the
    /// focus chain, but not be traversed to via focus traversal.
    ///
    /// This is different from [canRequestFocus] because it only implies that
    /// the node can't be reached via traversal, not that it can't be focused.
    /// It may still be focused explicitly.
    public var skipTraversal: Bool {
        get {
            if _skipTraversal {
                return true
            }
            for ancestor in ancestors {
                if !ancestor.descendantsAreTraversable {
                    return true
                }
            }
            return false
        }
        set {
            if newValue != _skipTraversal {
                _skipTraversal = newValue
                manager?.markPropertiesChanged(self)
            }
        }
    }
    private var _skipTraversal: Bool

    /// If true, this focus node may request the primary focus.
    ///
    /// Defaults to true. Set to false if you want this node to do nothing when
    /// [requestFocus] is called on it.
    ///
    /// If set to false on a [FocusScopeNode], will cause all of the children of
    /// the scope node to not be focusable.
    ///
    /// If set to false on a [FocusNode], it will not affect the focusability of
    /// children of the node.
    ///
    /// The [hasFocus] member can still return true if this node is the ancestor
    /// of a node with primary focus.
    ///
    /// This is different than [skipTraversal] because [skipTraversal] still
    /// allows the node to be focused, just not traversed to via the
    /// [FocusTraversalPolicy].
    ///
    /// Setting [canRequestFocus] to false implies that the node will also be
    /// skipped for traversal purposes.
    ///
    /// See also:
    ///
    ///  * [FocusTraversalGroup], a widget used to group together and configure
    ///    the focus traversal policy for a widget subtree.
    ///  * [FocusTraversalPolicy], a class that can be extended to describe a
    ///    traversal policy.
    public var canRequestFocus: Bool {
        get {
            if !_canRequestFocus {
                return false
            }
            if let scope = enclosingScope, !scope.canRequestFocus {
                return false
            }
            for ancestor in ancestors {
                if !ancestor.descendantsAreFocusable {
                    return false
                }
            }
            return true
        }
        set {
            if newValue != _canRequestFocus {
                // Have to set this first before unfocusing, since it checks this to cull
                // unfocusable, previously-focused children.
                _canRequestFocus = newValue
                if hasFocus && !newValue {
                    unfocus(disposition: .previouslyFocusedChild)
                }
                manager?.markPropertiesChanged(self)
            }
        }
    }
    private var _canRequestFocus: Bool

    /// If false, will disable focus for all of this node's descendants.
    ///
    /// Defaults to true. Does not affect focusability of this node: for that,
    /// use [canRequestFocus].
    ///
    /// If any descendants are focused when this is set to false, they will be
    /// unfocused. When [descendantsAreFocusable] is set to true again, they
    /// will not be refocused, although they will be able to accept focus again.
    ///
    /// Does not affect the value of [canRequestFocus] on the descendants.
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
    /// * [Focus], a widget that exposes this setting as a parameter.
    /// * [FocusTraversalGroup], a widget used to group together and configure
    ///   the focus traversal policy for a widget subtree that also has a
    ///   `descendantsAreFocusable` parameter that prevents its children from
    ///   being focused.
    public var descendantsAreFocusable: Bool {
        didSet {
            if oldValue != descendantsAreFocusable {
                if !descendantsAreFocusable && hasFocus {
                    unfocus(disposition: .previouslyFocusedChild)
                }
                manager?.markPropertiesChanged(self)
            }
        }
    }

    /// If false, tells the focus traversal policy to skip over for all of this
    /// node's descendants for purposes of the traversal algorithm.
    ///
    /// Defaults to true. Does not affect the focus traversal of this node: for
    /// that, use [skipTraversal].
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
    /// * [ExcludeFocus], a widget that conditionally excludes focus for a
    ///   subtree.
    /// * [FocusTraversalGroup], a widget used to group together and configure
    ///   the focus traversal policy for a widget subtree that also has an
    ///   `descendantsAreFocusable` parameter that prevents its children from
    ///   being focused.
    public var descendantsAreTraversable: Bool {
        didSet {
            if oldValue != descendantsAreTraversable {
                manager?.markPropertiesChanged(self)
            }
        }
    }

    /// The context that was supplied to [attach].
    ///
    /// This is typically the context for the widget that is being focused, as
    /// it is used to determine the bounds of the widget.
    public private(set) var context: BuildContext?

    /// Called if this focus node receives a key event while focused (i.e. when
    /// [hasFocus] returns true).
    public var onKeyEvent: FocusOnKeyEventCallback?

    //   var _hasKeyboardToken = false;

    fileprivate var attachment: FocusAttachment?

    /// Whether this node has input focus.
    ///
    /// A [FocusNode] has focus when it is an ancestor of a node that returns true
    /// from [hasPrimaryFocus], or it has the primary focus itself.
    ///
    /// The [hasFocus] accessor is different from [hasPrimaryFocus] in that
    /// [hasFocus] is true if the node is anywhere in the focus chain, but for
    /// [hasPrimaryFocus] the node must to be at the end of the chain to return
    /// true.
    ///
    /// A node that returns true for [hasFocus] will receive key events if none of
    /// its focused descendants returned true from their [onKey] handler.
    ///
    /// This object is a [ChangeNotifier], and notifies its [Listenable] listeners
    /// (registered via [addListener]) whenever this value changes.
    ///
    /// See also:
    ///
    ///  * [Focus.isAt], which is a static method that will return the focus
    ///    state of the nearest ancestor [Focus] widget's focus node.
    public var hasFocus: Bool {
        return hasPrimaryFocus
            || (manager?.primaryFocus?.ancestors.contains(object: self) ?? false)
    }

    /// Returns true if this node currently has the application-wide input focus.
    ///
    /// A [FocusNode] has the primary focus when the node is focused in its
    /// nearest ancestor [FocusScopeNode] and [hasFocus] is true for all its
    /// ancestor nodes, but none of its descendants.
    ///
    /// This is different from [hasFocus] in that [hasFocus] is true if the node
    /// is anywhere in the focus chain, but here the node has to be at the end of
    /// the chain to return true.
    ///
    /// A node that returns true for [hasPrimaryFocus] will be the first node to
    /// receive key events through its [onKey] handler.
    ///
    /// This object notifies its listeners whenever this value changes.
    public var hasPrimaryFocus: Bool {
        return manager?.primaryFocus === self
    }

    /// Returns the parent node for this object.
    ///
    /// All nodes except for the root [FocusScopeNode] ([FocusManager.rootScope])
    /// will be given a parent when they are added to the focus tree, which is
    /// done using [FocusAttachment.reparent].
    public private(set) var parent: FocusNode?

    /// An iterator over the children of this node.
    public private(set) var children: [FocusNode] = []

    /// An iterator over the children that are allowed to be traversed by the
    /// [FocusTraversalPolicy].
    ///
    /// Returns the list of focusable, traversable children of this node,
    /// regardless of those settings on this focus node. Will return an empty
    /// iterable if [descendantsAreFocusable] is false.
    ///
    /// See also
    ///
    ///  * [traversalDescendants], which traverses all of the node's
    ///    descendants, not just the immediate children.
    public var traversalChildren: any Sequence<FocusNode> {
        if descendantsAreFocusable {
            return []
        }
        return children.lazy.filter { !$0.skipTraversal && $0.canRequestFocus }
    }

    /// A debug label that is used for diagnostic output.
    public var debugLabel: String?

    /// An [Iterable] over the ancestors of this node.
    ///
    /// Iterates the ancestors of this node starting at the parent and iterating
    /// over successively more remote ancestors of this node, ending at the root
    /// [FocusScopeNode] ([FocusManager.rootScope]).
    public var ancestors: [FocusNode] {
        if _ancestors == nil {
            var result: [FocusNode] = []
            var parent = parent
            while parent != nil {
                result.append(parent!)
                parent = parent?.parent
            }
            _ancestors = result
        }
        return _ancestors!
    }
    private var _ancestors: [FocusNode]?

    /// An [Sequence] over the hierarchy of children below this one, in
    /// depth-first order.
    public var descendants: [FocusNode] {
        if _descendants == nil {
            var result: [FocusNode] = []
            for child in children {
                result.append(contentsOf: child.descendants)
                result.append(child)
            }
            _descendants = result
        }
        return _descendants!
    }
    private var _descendants: [FocusNode]?

    /// Returns all descendants which do not have the [skipTraversal] and do have
    /// the [canRequestFocus] flag set.
    public var traversalDescendants: any Sequence<FocusNode> {
        if !descendantsAreFocusable {
            return []
        }
        return descendants.lazy.filter { !$0.skipTraversal && $0.canRequestFocus }
    }

    /// Returns the nearest enclosing scope node above this node, or nil if the
    /// node has not yet be added to the focus tree.
    ///
    /// If this node is itself a scope, this will only return ancestors of this
    /// scope.
    ///
    /// Use [nearestScope] to start at this node instead of above it.
    public var enclosingScope: FocusScopeNode? {
        for node in ancestors {
            if let scope = node as? FocusScopeNode {
                return scope
            }
        }
        return nil
    }

    /// Returns the nearest enclosing scope node above this node, including this
    /// node, if it's a scope.
    ///
    /// Returns null if no scope is found.
    ///
    /// Use [enclosingScope] to look for scopes above this node.
    public var nearestScope: FocusScopeNode? {
        return enclosingScope
    }

    /// Called by the _host_ [StatefulWidget] to attach a [FocusNode] to the
    /// widget tree.
    ///
    /// In order to attach a [FocusNode] to the widget tree, call [attach],
    /// typically from the [StatefulWidget]'s [State.initState] method.
    ///
    /// If the focus node in the host widget is swapped out, the new node will
    /// need to be attached. [FocusAttachment.detach] should be called on the old
    /// node, and then [attach] called on the new node. This typically happens in
    /// the [State.didUpdateWidget] method.
    ///
    /// To receive key events that focuses on this node, pass a listener to
    /// `onKeyEvent`.
    public func attach(
        _ context: BuildContext? = nil,
        onKeyEvent: FocusOnKeyEventCallback? = nil
    ) -> FocusAttachment {
        self.context = context
        self.onKeyEvent = onKeyEvent ?? self.onKeyEvent
        attachment = FocusAttachment(self)
        return attachment!
    }

    public override func dispose() {
        // Detaching will also unfocus and clean up the manager's data
        // structures.
        attachment?.detach()
        super.dispose()
    }

    /// Requests the primary focus for this node, or for a supplied [node],
    /// which will also give focus to its [ancestors].
    ///
    /// If called without a node, request focus for this node. If the node
    /// hasn't been added to the focus tree yet, then defer the focus request
    /// until it is, allowing newly created widgets to request focus as soon as
    /// they are added.
    ///
    /// If the given [node] is not yet a part of the focus tree, then this
    /// method will add the [node] as a child of this node before requesting
    /// focus.
    ///
    /// If the given [node] is a [FocusScopeNode] and that focus scope node has
    /// a non-null [FocusScopeNode.focusedChild], then request the focus for the
    /// focused child. This process is recursive and continues until it
    /// encounters either a focus scope node with a null focused child or an
    /// ordinary (non-scope) [FocusNode] is found.
    ///
    /// The node is notified that it has received the primary focus in a
    /// microtask, so notification may lag the request by up to one frame.
    public final func requestFocus(_ node: FocusNode? = nil) {
        if let node = node {
            if node.parent == nil {
                reparent(node)
            }
            assert(
                node.ancestors.contains(object: self),
                "Focus was requested for a node that is not a descendant of the scope from which it was requested."
            )
            node.doRequestFocus(findFirstFocus: true)
            return
        }
        doRequestFocus(findFirstFocus: true)
    }

    // If set to true, the node will request focus on this node the next time
    // this node is reparented in the focus tree.
    //
    // Once requestFocus has been called at the next reparenting, this value
    // will be reset to false.
    //
    // This will only force a call to requestFocus for the node once the next time
    // the node is reparented. After that, _requestFocusWhenReparented would need
    // to be set to true again to have it be focused again on the next
    // reparenting.
    //
    // This is used when requestFocus is called and there is no parent yet.
    private var requestFocusWhenReparented = false

    private var hasKeyboardToken = false

    /// Removes the keyboard token from this focus node if it has one.
    ///
    /// This mechanism helps distinguish between an input control gaining focus by
    /// default and gaining focus as a result of an explicit user action.
    ///
    /// When a focus node requests the focus (either via
    /// [FocusScopeNode.requestFocus] or [FocusScopeNode.autofocus]), the focus
    /// node receives a keyboard token if it does not already have one. Later,
    /// when the focus node becomes focused, the widget that manages the
    /// [TextInputConnection] should show the keyboard (i.e. call
    /// [TextInputConnection.show]) only if it successfully consumes the keyboard
    /// token from the focus node.
    ///
    /// Returns true if this method successfully consumes the keyboard token.
    public func consumeKeyboardToken() -> Bool {
        if !hasKeyboardToken {
            return false
        }
        hasKeyboardToken = false
        return true
    }

    // This is overridden in FocusScopeNode.
    fileprivate func doRequestFocus(findFirstFocus: Bool) {
        if !canRequestFocus {
            return
        }
        // If the node isn't part of the tree, then we just defer the focus request
        // until the next time it is reparented, so that it's possible to focus
        // newly added widgets.
        if parent == nil {
            requestFocusWhenReparented = true
            return
        }
        setAsFocusedChildForScope()
        if hasPrimaryFocus
            && (manager!.markedForFocus == nil || manager!.markedForFocus == self)
        {
            return
        }
        hasKeyboardToken = true
        markNextFocus()
    }

    /// Marks the node as being the next to be focused, meaning that it will
    /// become the primary focus and notify listeners of a focus change the next
    /// time focus is resolved by the manager. If something else calls
    /// _markNextFocus before then, then that node will become the next focus
    /// instead of the previous one.
    fileprivate func markNextFocus() {
        if manager != nil {
            // If we have a manager, then let it handle the focus change.
            manager!.markNextFocus(self)
            return
        }
        // If we don't have a manager, then change the focus locally.
        setAsFocusedChildForScope()
        notify()
    }

    /// Removes the given FocusNode and its children as a child of this node.
    fileprivate func removeChild(_ node: FocusNode, removeScopeFocus: Bool = true) {
        assert(children.contains(node), "Tried to remove a node that wasn't a child.")
        assert(node.parent == self)
        assert(node.manager === manager)

        if removeScopeFocus {
            if let nodeScope = node.enclosingScope {
                nodeScope.focusedChildren.remove(object: node)
                for descendant in node.descendants {
                    if descendant.enclosingScope == nodeScope {
                        nodeScope.focusedChildren.remove(object: descendant)
                    }
                }
            }
        }

        node.parent = nil
        children.remove(object: node)
        for ancestor in ancestors {
            ancestor._descendants = nil
        }
        _descendants = nil
        assert(manager == nil || !manager!.rootScope.descendants.contains(node))
    }

    /// The manager that this node is currently attached to. Nil if this node is
    /// not yet attached to the focus tree.
    fileprivate var manager: FocusManager?

    private func updateManager(_ manager: FocusManager?) {
        self.manager = manager
        for descendant in descendants {
            descendant.manager = manager
            descendant._ancestors = nil
        }
    }

    fileprivate func notify() {
        if parent == nil {
            // no longer part of the tree, so don't notify.
            return
        }
        if hasPrimaryFocus {
            setAsFocusedChildForScope()
        }
        notifyListeners()
    }

    /// Removes the focus on this node by moving the primary focus to another
    /// node.
    ///
    /// This method removes focus from a node that has the primary focus,
    /// cancels any outstanding requests to focus it, while setting the primary
    /// focus to another node according to the `disposition`.
    ///
    /// It is safe to call regardless of whether this node has ever requested
    /// focus or not. If this node doesn't have focus or primary focus, nothing
    /// happens.
    ///
    /// The `disposition` argument determines which node will receive primary
    /// focus after this one loses it.
    ///
    /// If `disposition` is set to [UnfocusDisposition.scope] (the default),
    /// then the previously focused node history of the enclosing scope will be
    /// cleared, and the primary focus will be moved to the nearest enclosing
    /// scope ancestor that is enabled for focus, ignoring the
    /// [FocusScopeNode.focusedChild] for that scope.
    ///
    /// If `disposition` is set to [UnfocusDisposition.previouslyFocusedChild],
    /// then this node will be removed from the previously focused list in the
    /// [enclosingScope], and the focus will be moved to the previously focused
    /// node of the [enclosingScope], which (if it is a scope itself), will find
    /// its focused child, etc., until a leaf focus node is found. If there is
    /// no previously focused child, then the scope itself will receive focus,
    /// as if [UnfocusDisposition.scope] were specified.
    ///
    /// If you want this node to lose focus and the focus to move to the next or
    /// previous node in the enclosing [FocusTraversalGroup], call [nextFocus]
    /// or [previousFocus] instead of calling [unfocus].
    ///
    /// {@tool dartpad} This example shows the difference between the different
    /// [UnfocusDisposition] values for [unfocus].
    ///
    /// Try setting focus on the four text fields by selecting them, and then
    /// select "UNFOCUS" to see what happens when the current
    /// [FocusManager.primaryFocus] is unfocused.
    ///
    /// Try pressing the TAB key after unfocusing to see what the next widget
    /// chosen is.
    public func unfocus(disposition: UnfocusDisposition = .scope) {
        if !hasFocus {
            if manager == nil || manager!.markedForFocus != self {
                return
            }
        }
        guard var scope = enclosingScope else {
            // If the scope is null, then this is either the root node, or a
            // node that is not yet in the tree, neither of which do anything
            // when unfocused.
            return
        }
        switch disposition {
        case .scope:
            // If it can't request focus, then don't modify its focused children.
            if scope.canRequestFocus {
                // Clearing the focused children here prevents re-focusing the node
                // that we just unfocused if we immediately hit "next" after
                // unfocusing, and also prevents choosing to refocus the next-to-last
                // focused child if unfocus is called more than once.
                scope.focusedChildren.removeAll()
            }
            while !scope.canRequestFocus {
                scope = scope.enclosingScope ?? manager!.rootScope
            }
            scope.doRequestFocus(findFirstFocus: false)
        case .previouslyFocusedChild:
            // Select the most recent focused child from the nearest focusable
            // scope and focus that. If there isn't one, focus the scope itself.
            if scope.canRequestFocus {
                scope.focusedChildren.remove(object: self)
            }
            while !scope.canRequestFocus {
                scope.enclosingScope?.focusedChildren.remove(object: scope)
                scope = scope.enclosingScope ?? manager!.rootScope
            }
            scope.doRequestFocus(findFirstFocus: true)
        }
    }

    /// Used by FocusAttachment.reparent to perform the actual parenting
    /// operation.
    fileprivate func reparent(_ child: FocusNode) {
        assert(child != self, "Tried to make a child into a parent of itself.")
        if child.parent === self {
            assert(
                children.contains(object: child),
                "Found a node that says it's a child, but doesn't appear in the child list."
            )
            // The child is already a child of this parent.
            return
        }
        assert(
            manager == nil || child != manager!.rootScope,
            "Reparenting the root node isn't allowed."
        )
        assert(
            !ancestors.contains(child),
            "The supplied child is already an ancestor of this node. Loops are not allowed."
        )
        let oldScope = child.enclosingScope
        let hadFocus = child.hasFocus
        child.parent?.removeChild(child, removeScopeFocus: oldScope != nearestScope)
        children.append(child)
        child.parent = self
        child._ancestors = nil
        child.updateManager(manager)
        for ancestor in child.ancestors {
            ancestor._descendants = nil
        }
        if hadFocus {
            // Update the focus chain for the current focus without changing it.
            manager?.primaryFocus?.setAsFocusedChildForScope()
        }
        if oldScope != nil && child.context != nil && child.enclosingScope != oldScope {
            FocusTraversalGroup.maybeOf(child.context!)?.changedScope(
                node: child,
                oldScope: oldScope
            )
        }
        if child.requestFocusWhenReparented {
            child.doRequestFocus(findFirstFocus: true)
            child.requestFocusWhenReparented = false
        }
    }

    /// Sets this node as the [FocusScopeNode.focusedChild] of the enclosing
    /// scope.
    ///
    /// Sets this node as the focused child for the enclosing scope, and that
    /// scope as the focused child for the scope above it, etc., until it
    /// reaches the root node. It doesn't change the primary focus, it just
    /// changes what node would be focused if the enclosing scope receives
    /// focus, and keeps track of previously focused children in that scope, so
    /// that if the focused child in that scope is removed, the previous focus
    /// returns.
    fileprivate func setAsFocusedChildForScope() {
        var scopeFocus = self
        for ancestor in ancestors.compactMap({ $0 as? FocusScopeNode }) {
            assert(
                scopeFocus !== ancestor,
                "Somehow made a loop by setting focusedChild to its scope."
            )
            // Remove it anywhere in the focused child history.
            ancestor.focusedChildren.removeAll { $0 === scopeFocus }
            // Add it to the end of the list, which is also the top of the queue: The
            // end of the list represents the currently focused child.
            ancestor.focusedChildren.append(scopeFocus)
            scopeFocus = ancestor
        }
    }
}

/// Describe what should happen after [FocusNode.unfocus] is called.
///
/// See also:
///
///  * [FocusNode.unfocus], which takes this as its `disposition` parameter.
public enum UnfocusDisposition {
    /// Focus the nearest focusable enclosing scope of this node, but do not
    /// descend to locate the leaf [FocusScopeNode.focusedChild] the way
    /// [previouslyFocusedChild] does.
    ///
    /// Focusing the scope in this way clears the [FocusScopeNode.focusedChild]
    /// history for the enclosing scope when it receives focus. Because of this,
    /// calling a traversal method like [FocusNode.nextFocus] after unfocusing
    /// will cause the [FocusTraversalPolicy] to pick the node it thinks should be
    /// first in the scope.
    ///
    /// This is the default disposition for [FocusNode.unfocus].
    case scope

    /// Focus the previously focused child of the nearest focusable enclosing
    /// scope of this node.
    ///
    /// If there is no previously focused child, then this is equivalent to using
    /// the [scope] disposition.
    ///
    /// Unfocusing with this disposition will cause [FocusNode.unfocus] to walk up
    /// the tree to the nearest focusable enclosing scope, then start to walk down
    /// the tree, looking for a focused child at its
    /// [FocusScopeNode.focusedChild].
    ///
    /// If the [FocusScopeNode.focusedChild] is a scope, then look for its
    /// [FocusScopeNode.focusedChild], and so on, finding the leaf
    /// [FocusScopeNode.focusedChild] that is not a scope, or, failing that, a
    /// leaf scope that has no focused child.
    case previouslyFocusedChild
}

/// An attachment point for a [FocusNode].
///
/// Using a [FocusAttachment] is rarely needed, unless building something akin
/// to the [Focus] or [FocusScope] widgets from scratch.
///
/// Once created, a [FocusNode] must be attached to the widget tree by its
/// _host_ [StatefulWidget] via a [FocusAttachment] object. [FocusAttachment]s
/// are owned by the [StatefulWidget] that hosts a [FocusNode] or
/// [FocusScopeNode]. There can be multiple [FocusAttachment]s for each
/// [FocusNode], but the node will only ever be attached to one of them at a
/// time.
///
/// This attachment is created by calling [FocusNode.attach], usually from the
/// host widget's [State.initState] method. If the widget is updated to have a
/// different focus node, then the new node needs to be attached in
/// [State.didUpdateWidget], after calling [detach] on the previous
/// [FocusAttachment]. Once detached, the attachment is defunct and will no
/// longer make changes to the [FocusNode] through [reparent].
///
/// Without these attachment points, it would be possible for a focus node to
/// simultaneously be attached to more than one part of the widget tree during
/// the build stage.
public class FocusAttachment {
    fileprivate init(_ node: FocusNode) {
        self.node = node
    }

    // The focus node that this attachment manages an attachment for. The node
    // may not yet have a parent, or may have been detached from this
    // attachment, so don't count on this node being in a usable state.
    private weak var node: FocusNode?

    /// Returns true if the associated node is attached to this attachment.
    ///
    /// It is possible to be attached to the widget tree, but not be placed in
    /// the focus tree (i.e. to not have a parent yet in the focus tree).
    public var isAttached: Bool {
        return node?.attachment === self
    }

    /// Detaches the [FocusNode] this attachment point is associated with from
    /// the focus tree, and disconnects it from this attachment point.
    ///
    /// Calling [FocusNode.dispose] will also automatically detach the node.
    public func detach() {
        guard let node else {
            return
        }
        if isAttached {
            if node.hasPrimaryFocus
                || (node.manager != nil && node.manager!.markedForFocus == node)
            {
                node.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild)
            }
            // This node is no longer in the tree, so shouldn't send notifications anymore.
            node.manager?.markDetached(node)
            node.parent?.removeChild(node)
            node.attachment = nil
            assert(!node.hasPrimaryFocus)
            assert(node.manager?.markedForFocus != node)
        }
        assert(!isAttached)
    }

    /// Ensures that the [FocusNode] attached at this attachment point has the
    /// proper parent node, changing it if necessary.
    ///
    /// If given, ensures that the given [parent] node is the parent of the node
    /// that is attached at this attachment point, changing it if necessary.
    /// However, it is usually not necessary to supply an explicit parent, since
    /// [reparent] will use [Focus.of] to determine the correct parent node for
    /// the context given in [FocusNode.attach].
    ///
    /// If [isAttached] is false, then calling this method does nothing.
    ///
    /// Should be called whenever the associated widget is rebuilt in order to
    /// maintain the focus hierarchy.
    ///
    /// A [StatefulWidget] that hosts a [FocusNode] should call this method on the
    /// node it hosts during its [State.build] or [State.didChangeDependencies]
    /// methods in case the widget is moved from one location in the tree to
    /// another location that has a different [FocusScope] or context.
    ///
    /// The optional [parent] argument must be supplied when not using [Focus] and
    /// [FocusScope] widgets to build the focus tree, or if there is a need to
    /// supply the parent explicitly (which are both uncommon).
    public func reparent(parent: FocusNode? = nil) {
        guard let node else {
            return
        }
        var parent = parent
        if isAttached {
            assert(node.context != nil)
            parent = parent ?? Focus.maybeOf(node.context!, scopeOk: true)
            parent = parent ?? node.context!.owner!.focusManager.rootScope
            parent!.reparent(node)
        }
    }
}

public class FocusScopeNode: FocusNode {
    public override var nearestScope: FocusScopeNode? {
        return self
    }

    /// Returns the child of this node that should receive focus if this scope
    /// node receives focus.
    ///
    /// If [hasFocus] is true, then this points to the child of this node that is
    /// currently focused.
    ///
    /// Returns null if there is no currently focused child.
    public var focusedChild: FocusNode? {
        assert(
            focusedChildren.isEmpty || focusedChildren.last?.enclosingScope === self,
            "Focused child does not have the same idea of its enclosing scope as the scope does."
        )
        return focusedChildren.last
    }

    // A stack of the children that have been set as the focusedChild, most
    // recent last (which is the top of the stack).
    fileprivate var focusedChildren: [FocusNode] = []

    /// An iterator over the children that are allowed to be traversed by the
    /// [FocusTraversalPolicy].
    ///
    /// Will return an empty iterable if this scope node is not focusable, or if
    /// [descendantsAreFocusable] is false.
    ///
    /// See also:
    ///
    ///  * [traversalDescendants], which traverses all of the node's
    ///    descendants, not just the immediate children.
    public override var traversalChildren: any Sequence<FocusNode> {
        if !canRequestFocus {
            return []
        }
        return super.traversalChildren
    }

    /// Returns all descendants which do not have the [skipTraversal] and do
    /// have the [canRequestFocus] flag set.
    ///
    /// Will return an empty iterable if this scope node is not focusable, or if
    /// [descendantsAreFocusable] is false.
    public override var traversalDescendants: any Sequence<FocusNode> {
        if !canRequestFocus {
            return []
        }
        return super.traversalDescendants
    }

    /// If this scope lacks a focus, request that the given node become the focus.
    ///
    /// If the given node is not yet part of the focus tree, then add it as a
    /// child of this node.
    ///
    /// Useful for widgets that wish to grab the focus if no other widget already
    /// has the focus.
    ///
    /// The node is notified that it has received the primary focus in a
    /// microtask, so notification may lag the request by up to one frame.
    public func autofocus(_ node: FocusNode) {
        // Attach the node to the tree first, so in _applyFocusChange if the node
        // is detached we don't add it back to the tree.
        if node.parent == nil {
            reparent(node)
        }

        assert(manager != nil)
        manager?.pendingAutofocuses.append(Autofocus(scope: self, autofocusNode: node))
        manager?.markNeedsUpdate()
    }

    fileprivate override func doRequestFocus(findFirstFocus: Bool) {
        // It is possible that a previously focused child is no longer focusable.
        while self.focusedChild != nil && !self.focusedChild!.canRequestFocus {
            focusedChildren.removeLast()
        }

        // final FocusNode? focusedChild = self.focusedChild;
        // // If findFirstFocus is false, then the request is to make this scope the
        // // focus instead of looking for the ultimate first focus for this scope and
        // // its descendants.
        if !findFirstFocus || focusedChild == nil {
            if canRequestFocus {
                setAsFocusedChildForScope()
                markNextFocus()
            }
            return
        }

        focusedChild!.doRequestFocus(findFirstFocus: true)
    }
}

/// Manages the focus tree.
///
/// The focus tree is a separate, sparser, tree from the widget tree that
/// maintains the hierarchical relationship between focusable widgets in the
/// widget tree.
///
/// The focus manager is responsible for tracking which [FocusNode] has the
/// primary input focus (the [primaryFocus]), holding the [FocusScopeNode] that
/// is the root of the focus tree (the [rootScope]), and what the current
/// [highlightMode] is. It also distributes [KeyEvent]s to the nodes in the
/// focus tree.
///
/// The singleton [FocusManager] instance is held by the [WidgetsBinding] as
/// [WidgetsBinding.focusManager], and can be conveniently accessed using the
/// [FocusManager.instance] static accessor.
///
/// To find the [FocusNode] for a given [BuildContext], use [Focus.of]. To find
/// the [FocusScopeNode] for a given [BuildContext], use [FocusScope.of].
///
/// If you would like notification whenever the [primaryFocus] changes, register
/// a listener with [addListener]. When you no longer want to receive these
/// events, as when your object is about to be disposed, you must unregister
/// with [removeListener] to avoid memory leaks. Removing listeners is typically
/// done in [State.dispose] on stateful widgets.
///
/// The [highlightMode] describes how focus highlights should be displayed on
/// components in the UI. The [highlightMode] changes are notified separately
/// via [addHighlightModeListener] and removed with
/// [removeHighlightModeListener]. The highlight mode changes when the user
/// switches from a mouse to a touch interface, or vice versa.
///
/// The widgets that are used to manage focus in the widget tree are:
///
///  * [Focus], a widget that manages a [FocusNode] in the focus tree so that
///    the focus tree reflects changes in the widget hierarchy.
///  * [FocusScope], a widget that manages a [FocusScopeNode] in the focus tree,
///    creating a new scope for restricting focus to a set of focus nodes.
///  * [FocusTraversalGroup], a widget that groups together nodes that should be
///    traversed using an order described by a given [FocusTraversalPolicy].
///
/// See also:
///
///  * [FocusNode], which is a node in the focus tree that can receive focus.
///  * [FocusScopeNode], which is a node in the focus tree used to collect
///    subtrees into groups and restrict focus to them.
///  * The [primaryFocus] global accessor, for convenient access from anywhere
///    to the current focus manager state.
public class FocusManager: ChangeNotifier {
    public override init() {
        super.init()
        rootScope.manager = self
    }

    /// Provides convenient access to the current [FocusManager] singleton from
    /// the [WidgetsBinding] instance.
    //   static FocusManager get instance => WidgetsBinding.instance.focusManager;
    public static var shared: FocusManager {
        WidgetsBinding.shared.buildOwner.focusManager
    }

    /// The instance of KeyEventDispatcher that is used to send key events to the
    /// focused nodes of the focus tree managed by this focus manager.
    public private(set) lazy var dispatcher = KeyEventDispatcher(self)

    /// Registers global input event handlers that are needed to manage focus.
    public func registerGlobalHandlers() {
        HardwareKeyboard.shared.addHandler(self.dispatcher)
    }

    /// The root [FocusScopeNode] in the focus tree.
    ///
    /// This field is rarely used directly. To find the nearest [FocusScopeNode]
    /// for a given [FocusNode], call [FocusNode.nearestScope].
    //   final FocusScopeNode rootScope = FocusScopeNode(debugLabel: 'Root Focus Scope');
    public let rootScope = FocusScopeNode(debugLabel: "Root Focus Scope")

    /// The node that currently has the primary focus.
    public private(set) var primaryFocus: FocusNode?

    // The set of nodes that need to notify their listeners of changes at the
    // next update.
    private var dirtyNodes: Set<FocusNode> = []

    // The node that has requested to have the primary focus, but hasn't been
    // given it yet.
    fileprivate var markedForFocus: FocusNode?

    fileprivate func markDetached(_ node: FocusNode) {
        // The node has been removed from the tree, so it no longer needs to be
        // notified of changes.
        if primaryFocus == node {
            primaryFocus = nil
        }
        dirtyNodes.remove(node)
    }

    fileprivate func markPropertiesChanged(_ node: FocusNode) {
        markNeedsUpdate()
        dirtyNodes.insert(node)
    }

    /// Set ``node`` as the node that should receive the primary focus the next
    /// time the focus is resolved, and schedule a focus update.
    fileprivate func markNextFocus(_ node: FocusNode) {
        if primaryFocus == node {
            // The caller asked for the current focus to be the next focus, so
            // just pretend that didn't happen.
            markedForFocus = nil
        } else {
            markedForFocus = node
            markNeedsUpdate()
        }
    }

    // True indicates that there is an update pending.
    private var haveScheduledUpdate = false

    // Request that an update be scheduled, optionally requesting focus for the
    // given newFocus node.
    fileprivate func markNeedsUpdate() {
        if haveScheduledUpdate {
            return
        }
        haveScheduledUpdate = true
        backend.postTask(applyFocusChangesIfNeeded)
    }

    /// The list of autofocus requests made since the last
    /// ``applyFocusChangesIfNeeded`` call.
    fileprivate var pendingAutofocuses = [Autofocus]()

    /// Applies any pending focus changes and notifies listeners that the focus
    /// has changed.
    ///
    /// Must not be called during the build phase. This method is meant to be
    /// called in a post-frame callback or microtask when the pending focus
    /// changes need to be resolved before something else occurs.
    ///
    /// It can't be called during the build phase because not all listeners are
    /// safe to be called with an update during a build.
    ///
    /// Typically, this is called automatically by the [FocusManager], but
    /// sometimes it is necessary to ensure that no focus changes are pending
    /// before executing an action. For example, the [MenuAnchor] class uses
    /// this to make sure that the previous focus has been restored before
    /// executing a menu callback when a menu item is selected.
    ///
    /// It is safe to call this if no focus changes are pending.
    private func applyFocusChangesIfNeeded() {
        assert(
            SchedulerBinding.shared.schedulerPhase != .persistentCallbacks,
            "applyFocusChangesIfNeeded() should not be called during the build phase."
        )

        haveScheduledUpdate = false
        let previousFocus = primaryFocus

        for autofocus in pendingAutofocuses {
            autofocus.applyIfValid(self)
        }
        pendingAutofocuses.removeAll()

        // If we don't have any current focus, and nobody has asked to focus
        // yet, then revert to the root scope.
        if primaryFocus == nil && markedForFocus == nil {
            markedForFocus = rootScope
        }

        // A node has requested to be the next focus, and isn't already the primary
        // focus.
        if markedForFocus != nil && markedForFocus != primaryFocus {
            let previousPath = Set(previousFocus?.ancestors ?? [])
            let nextPath = Set(markedForFocus!.ancestors)
            // Notify nodes that are newly focused.
            dirtyNodes.formUnion(nextPath.subtracting(previousPath))
            // Notify nodes that are no longer focused
            dirtyNodes.formUnion(previousPath.subtracting(nextPath))

            primaryFocus = markedForFocus
            markedForFocus = nil
        }
        assert(markedForFocus == nil)

        if previousFocus != primaryFocus {
            if previousFocus != nil {
                dirtyNodes.insert(previousFocus!)
            }
            if primaryFocus != nil {
                dirtyNodes.insert(primaryFocus!)
            }
        }

        for node in dirtyNodes {
            node.notify()
        }
        dirtyNodes.removeAll()

        if previousFocus != primaryFocus {
            notifyListeners()
        }
    }
}

/// Represents a pending autofocus request.
private struct Autofocus {
    /// The scope that the autofocus should be applied to.
    let scope: FocusScopeNode

    /// The node that want to be focused.
    let autofocusNode: FocusNode

    // Applies the autofocus request, if the node is still attached to the
    // original scope and the scope has no focused child.
    //
    // The widget tree is responsible for calling reparent/detach on attached
    // nodes to keep their parent/manager information up-to-date, so here we can
    // safely check if the scope/node involved in each autofocus request is
    // still attached, and discard the ones which are no longer attached to the
    // original manager.
    func applyIfValid(_ manager: FocusManager) {
        let shouldApply =
            (scope.parent != nil || scope == manager.rootScope)
            && scope.manager === manager
            && scope.focusedChild == nil
            && autofocusNode.ancestors.contains(scope)
        if shouldApply {
            autofocusNode.doRequestFocus(findFirstFocus: true)
        }
    }
}

public class KeyEventDispatcher: HardwareKeyboard.Handler {
    public init(_ manager: FocusManager) {
        self.manager = manager
    }

    public private(set) weak var manager: FocusManager?

    /// Dispatches the given key event to the focus chain for the given manager
    /// in order. Returns true if the event was handled by any node.
    public func handleKeyEvent(_ event: KeyEvent) -> Bool {
        guard let manager, let primaryFocus = manager.primaryFocus else {
            return false
        }

        var handled = false

        for node in [primaryFocus] + primaryFocus.ancestors {
            let result = node.onKeyEvent?(node, event)
            switch result {
            case .handled:
                handled = true
                break
            case .skipRemainingHandlers:
                handled = false
                break
            case .ignored, nil:
                continue
            }
        }

        return handled
    }

    public func addEarlyKeyEventHandler(_ handler: KeyEventCallback) {
        // earlyKeyHandlers.append(handler)
        assertionFailure()
    }

    public func removeEarlyKeyEventHandler(_ handler: KeyEventCallback) {
        // earlyKeyHandlers.remove(handler)
        assertionFailure()
    }

    public func addLateKeyEventHandler(_ handler: KeyEventCallback) {
        // lateKeyHandlers.append(handler)
        assertionFailure()
    }

    public func removeLateKeyEventHandler(_ handler: KeyEventCallback) {
        // lateKeyHandlers.remove(handler)
        assertionFailure()
    }
}

/// Provides convenient access to the current [FocusManager.primaryFocus] from
/// the [WidgetsBinding] instance.
public var primaryFocus: FocusNode? {
    FocusManager.shared.primaryFocus
}
