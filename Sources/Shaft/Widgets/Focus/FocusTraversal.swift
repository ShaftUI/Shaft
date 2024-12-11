// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

public class FocusTraversalPolicy {
    /// This is called whenever the given [node] is re-parented into a new
    /// scope, so that the policy has a chance to update or invalidate any
    /// cached data that it maintains per scope about the node.
    ///
    /// The [oldScope] is the previous scope that this node belonged to, if any.
    ///
    /// The default implementation does nothing.
    public func changedScope(node: FocusNode?, oldScope: FocusScopeNode?) {}
}

/// A widget that describes the inherited focus policy for focus traversal for
/// its descendants, grouping them into a separate traversal group.
///
/// A traversal group is treated as one entity when sorted by the traversal
/// algorithm, so it can be used to segregate different parts of the widget tree
/// that need to be sorted using different algorithms and/or sort orders when
/// using an [OrderedTraversalPolicy].
///
/// Within the group, it will use the given [policy] to order the elements. The
/// group itself will be ordered using the parent group's policy.
///
/// By default, traverses in reading order using [ReadingOrderTraversalPolicy].
///
/// To prevent the members of the group from being focused, set the
/// [descendantsAreFocusable] attribute to false.
///
/// See also:
///
///  * [FocusNode], for a description of the focus system.
///  * [WidgetOrderTraversalPolicy], a policy that relies on the widget creation
///    order to describe the order of traversal.
///  * [ReadingOrderTraversalPolicy], a policy that describes the order as the
///    natural "reading order" for the current [Directionality].
///  * [DirectionalFocusTraversalPolicyMixin] a mixin class that implements
///    focus traversal in a direction.
public final class FocusTraversalGroup: StatefulWidget {
    internal init(
        policy: FocusTraversalPolicy,
        descendantsAreFocusable: Bool,
        descendantsAreTraversable: Bool,
        child: Widget
    ) {
        self.policy = policy
        self.descendantsAreFocusable = descendantsAreFocusable
        self.descendantsAreTraversable = descendantsAreTraversable
        self.child = child
    }

    /// The policy used to move the focus from one focus node to another when
    /// traversing them using a keyboard.
    ///
    /// If not specified, traverses in reading order using
    /// [ReadingOrderTraversalPolicy].
    ///
    /// See also:
    ///
    ///  * [FocusTraversalPolicy] for the API used to impose traversal order
    ///    policy.
    ///  * [WidgetOrderTraversalPolicy] for a traversal policy that traverses
    ///    nodes in the order they are added to the widget tree.
    ///  * [ReadingOrderTraversalPolicy] for a traversal policy that traverses
    ///    nodes in the reading order defined in the widget tree, and then top
    ///    to bottom.
    public let policy: FocusTraversalPolicy

    public let descendantsAreFocusable: Bool

    public let descendantsAreTraversable: Bool

    /// The child widget of this [FocusTraversalGroup].
    public let child: Widget

    /// Returns the [FocusTraversalPolicy] that applies to the nearest ancestor
    /// of the given [FocusNode].
    ///
    /// Will return null if no [FocusTraversalPolicy] ancestor applies to the
    /// given [FocusNode].
    ///
    /// The [FocusTraversalPolicy] is set by introducing a [FocusTraversalGroup]
    /// into the widget tree, which will associate a policy with the focus tree
    /// under the nearest ancestor [Focus] widget.
    ///
    /// This function differs from [maybeOf] in that it takes a [FocusNode] and
    /// only traverses the focus tree to determine the policy in effect. Unlike
    /// this function, the [maybeOf] function takes a [BuildContext] and first
    /// walks up the widget tree to find the nearest ancestor [Focus] or
    /// [FocusScope] widget, and then calls this function with the focus node
    /// associated with that widget to determine the policy in effect.
    public static func maybeOfNode(_ node: FocusNode) -> FocusTraversalPolicy? {
        return getGroupNode(node)?.policy
    }

    /// Finds the nearest ancestor [FocusTraversalGroup] of the given
    /// [FocusNode]. Returns null if no such ancestor exists.
    private static func getGroupNode(_ node: FocusNode) -> FocusTraversalGroupNode? {
        var node = node
        while node.parent != nil {
            if node.context == nil {
                return nil
            }
            if let node = node as? FocusTraversalGroupNode {
                return node
            }
            node = node.parent!
        }
        return nil
    }

    /// Returns the [FocusTraversalPolicy] that applies to the [FocusNode] of the
    /// nearest ancestor [Focus] widget, or null, given a [BuildContext].
    ///
    /// Will return null if it doesn't find an ancestor [Focus] or [FocusScope]
    /// widget, or doesn't find a [FocusTraversalPolicy] that applies to the node.
    ///
    /// {@macro flutter.widgets.focus_traversal.FocusTraversalGroup.of}
    ///
    /// See also:
    ///
    /// * [maybeOfNode] for a similar function that will look for a policy using a
    ///   given [FocusNode].
    /// * [of] for a similar function that will throw if no [FocusTraversalPolicy]
    ///   applies.
    public static func maybeOf(_ context: BuildContext) -> FocusTraversalPolicy? {
        let node = Focus.maybeOf(context, scopeOk: true, createDependency: false)
        guard let node else {
            return nil
        }
        return Self.maybeOfNode(node)
    }

    public func createState() -> some State<FocusTraversalGroup> {
        FocusTraversalGroupState()
    }
}

/// A special focus node subclass that only FocusTraversalGroup uses so that it
/// can be used to cache the policy in the focus tree, and so that the traversal
/// code can find groups in the focus tree.
private class FocusTraversalGroupNode: FocusNode {
    init(policy: FocusTraversalPolicy, debugLabel: String? = nil) {
        self.policy = policy
        super.init(debugLabel: debugLabel)
    }

    var policy: FocusTraversalPolicy
}

private class FocusTraversalGroupState: State<FocusTraversalGroup> {
    // The internal focus node used to collect the children of this node into a
    // group, and to provide a context for the traversal algorithm to sort the
    // group with. It's a special subclass of FocusNode just so that it can be
    // identified when walking the focus tree during traversal, and hold the
    // current policy.
    //   late final _FocusTraversalGroupNode focusNode = _FocusTraversalGroupNode(
    private lazy var focusNode = FocusTraversalGroupNode(policy: widget.policy)

    override func didUpdateWidget(_ oldWidget: FocusTraversalGroup) {
        super.didUpdateWidget(oldWidget)
        if widget.policy !== oldWidget.policy {
            focusNode.policy = widget.policy
        }
    }

    override func dispose() {
        focusNode.dispose()
        super.dispose()
    }

    override func build(context: BuildContext) -> Widget {
        Focus(
            focusNode: focusNode,
            canRequestFocus: false,
            skipTraversal: true,
            descendantsAreFocusable: widget.descendantsAreFocusable,
            descendantsAreTraversable: widget.descendantsAreTraversable,
            includeSemantics: false
        ) {
            widget.child
        }
    }
}
