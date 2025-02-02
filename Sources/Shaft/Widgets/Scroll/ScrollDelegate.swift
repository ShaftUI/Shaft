/// A callback which produces a semantic index given a widget and the local index.
///
/// Return a null value to prevent a widget from receiving an index.
///
/// A semantic index is used to tag child semantic nodes for accessibility
/// announcements in scroll view.
///
/// See also:
///
///  * [CustomScrollView], for an explanation of scroll semantics.
///  * [SliverChildBuilderDelegate], for an explanation of how this is used to
///    generate indexes.
public typealias SemanticIndexCallback = (_ widget: Widget, _ localIndex: Int) -> Int?

public func _kDefaultSemanticIndexCallback(_ widget: Widget, _ localIndex: Int) -> Int? {
    return localIndex
}

/// A delegate that supplies children for slivers.
///
/// Many slivers lazily construct their box children to avoid creating more
/// children than are visible through the [Viewport]. Rather than receiving
/// their children as an explicit [List], they receive their children using a
/// [SliverChildDelegate].
///
/// It's uncommon to subclass [SliverChildDelegate]. Instead, consider using one
/// of the existing subclasses that provide adaptors to builder callbacks or
/// explicit child lists.
///
/// {@template flutter.widgets.SliverChildDelegate.lifecycle}
/// ## Child elements' lifecycle
///
/// ### Creation
///
/// While laying out the list, visible children's elements, states and render
/// objects will be created lazily based on existing widgets (such as in the
/// case of [SliverChildListDelegate]) or lazily provided ones (such as in the
/// case of [SliverChildBuilderDelegate]).
///
/// ### Destruction
///
/// When a child is scrolled out of view, the associated element subtree, states
/// and render objects are destroyed. A new child at the same position in the
/// sliver will be lazily recreated along with new elements, states and render
/// objects when it is scrolled back.
///
/// ### Destruction mitigation
///
/// In order to preserve state as child elements are scrolled in and out of
/// view, the following options are possible:
///
///  * Moving the ownership of non-trivial UI-state-driving business logic
///    out of the sliver child subtree. For instance, if a list contains posts
///    with their number of upvotes coming from a cached network response, store
///    the list of posts and upvote number in a data model outside the list. Let
///    the sliver child UI subtree be easily recreate-able from the
///    source-of-truth model object. Use [StatefulWidget]s in the child widget
///    subtree to store instantaneous UI state only.
///
///  * Letting [KeepAlive] be the root widget of the sliver child widget subtree
///    that needs to be preserved. The [KeepAlive] widget marks the child
///    subtree's top render object child for keepalive. When the associated top
///    render object is scrolled out of view, the sliver keeps the child's
///    render object (and by extension, its associated elements and states) in a
///    cache list instead of destroying them. When scrolled back into view, the
///    render object is repainted as-is (if it wasn't marked dirty in the
///    interim).
///
///    This only works if the [SliverChildDelegate] subclasses don't wrap the
///    child widget subtree with other widgets such as [AutomaticKeepAlive] and
///    [RepaintBoundary] via `addAutomaticKeepAlives` and
///    `addRepaintBoundaries`.
///
///  * Using [AutomaticKeepAlive] widgets (inserted by default in
///    [SliverChildListDelegate] or [SliverChildListDelegate]).
///    [AutomaticKeepAlive] allows descendant widgets to control whether the
///    subtree is actually kept alive or not. This behavior is in contrast with
///    [KeepAlive], which will unconditionally keep the subtree alive.
///
///    As an example, the [EditableText] widget signals its sliver child element
///    subtree to stay alive while its text field has input focus. If it doesn't
///    have focus and no other descendants signaled for keepalive via a
///    [KeepAliveNotification], the sliver child element subtree will be
///    destroyed when scrolled away.
///
///    [AutomaticKeepAlive] descendants typically signal it to be kept alive by
///    using the [AutomaticKeepAliveClientMixin], then implementing the
///    [AutomaticKeepAliveClientMixin.wantKeepAlive] getter and calling
///    [AutomaticKeepAliveClientMixin.updateKeepAlive].
///
/// ## Using more than one delegate in a [Viewport]
///
/// If multiple delegates are used in a single scroll view, the first child of
/// each delegate will always be laid out, even if it extends beyond the
/// currently viewable area. This is because at least one child is required in
/// order to [estimateMaxScrollOffset] for the whole scroll view, as it uses the
/// currently built children to estimate the remaining children's extent.
/// {@endtemplate}
///
/// See also:
///
///  * [SliverChildBuilderDelegate], which is a delegate that uses a builder
///    callback to construct the children.
///  * [SliverChildListDelegate], which is a delegate that has an explicit list
///    of children.
public protocol SliverChildDelegate: AnyObject {
    /// Returns the child with the given index.
    ///
    /// Should return null if asked to build a widget with a greater
    /// index than exists. If this returns null, [estimatedChildCount]
    /// must subsequently return a precise non-null value (which is then
    /// used to implement [RenderSliverBoxChildManager.childCount]).
    ///
    /// Subclasses typically override this function and wrap their children in
    /// [AutomaticKeepAlive], [IndexedSemantics], and [RepaintBoundary] widgets.
    ///
    /// The values returned by this method are cached. To indicate that the
    /// widgets have changed, a new delegate must be provided, and the new
    /// delegate's [shouldRebuild] method must return true.
    func build(_ context: BuildContext, index: Int) -> Widget?

    /// Returns an estimate of the number of children this delegate will build.
    ///
    /// Used to estimate the maximum scroll offset if [estimateMaxScrollOffset]
    /// returns null.
    ///
    /// Return null if there are an unbounded number of children or if it would
    /// be too difficult to estimate the number of children.
    ///
    /// This must return a precise number once [build] has returned null, as it
    /// used to implement [RenderSliverBoxChildManager.childCount].
    var estimatedChildCount: Int? { get }

    /// Returns an estimate of the max scroll extent for all the children.
    ///
    /// Subclasses should override this function if they have additional
    /// information about their max scroll extent.
    ///
    /// The default implementation returns null, which causes the caller to
    /// extrapolate the max scroll offset from the given parameters.
    func estimateMaxScrollOffset(
        firstIndex: Int,
        lastIndex: Int,
        leadingScrollOffset: Float,
        trailingScrollOffset: Float
    ) -> Float?

    /// Called at the end of layout to indicate that layout is now complete.
    ///
    /// The `firstIndex` argument is the index of the first child that was
    /// included in the current layout. The `lastIndex` argument is the index of
    /// the last child that was included in the current layout.
    ///
    /// Useful for subclasses that which to track which children are included in
    /// the underlying render tree.
    func didFinishLayout(firstIndex: Int, lastIndex: Int)

    /// Called whenever a new instance of the child delegate class is
    /// provided to the sliver.
    ///
    /// If the new instance represents different information than the old
    /// instance, then the method should return true, otherwise it should return
    /// false.
    ///
    /// If the method returns false, then the [build] call might be optimized
    /// away.
    func shouldRebuild(oldDelegate: SliverChildDelegate) -> Bool

    /// Find index of child element with associated key.
    ///
    /// This will be called during `performRebuild` in [SliverMultiBoxAdaptorElement]
    /// to check if a child has moved to a different position. It should return the
    /// index of the child element with associated key, null if not found.
    ///
    /// If not provided, a child widget may not map to its existing [RenderObject]
    /// when the order of children returned from the children builder changes.
    /// This may result in state-loss.
    func findIndexByKey(_ key: any Key) -> Int?
}

/// Default implementation for [SliverChildDelegate] methods.
extension SliverChildDelegate {
    /// Default implementation of [estimatedChildCount].
    public var estimatedChildCount: Int? {
        return nil
    }

    /// Default implementation of [estimateMaxScrollOffset].
    public func estimateMaxScrollOffset(
        firstIndex: Int,
        lastIndex: Int,
        leadingScrollOffset: Float,
        trailingScrollOffset: Float
    ) -> Float? {
        return nil
    }

    /// Default implementation of [didFinishLayout].
    public func didFinishLayout(firstIndex: Int, lastIndex: Int) {}

    /// Default implementation of [shouldRebuild].
    public func shouldRebuild(_ oldDelegate: SliverChildDelegate) -> Bool {
        return true
    }

    /// Default implementation of [findIndexByKey].
    public func findIndexByKey(_ key: any Key) -> Int? {
        return nil
    }
}

private class _SaltedValueKey: Key, HashableObject {
    init(_ value: any Key) {
        self.value = value
    }

    public let value: any Key

    func isEqualTo(_ other: (any Key)?) -> Bool {
        if let other = other as? _SaltedValueKey {
            return value.isEqualTo(other.value)
        }
        return false
    }
}

/// Called to find the new index of a child based on its `key` in case of
/// reordering.
///
/// If the child with the `key` is no longer present, null is returned.
///
/// Used by [SliverChildBuilderDelegate.findChildIndexCallback].
public typealias ChildIndexGetter = (_ key: any Key) -> Int?

/// A delegate that supplies children for slivers using a builder callback.
///
/// Many slivers lazily construct their box children to avoid creating more
/// children than are visible through the [Viewport]. This delegate provides
/// children using a [NullableIndexedWidgetBuilder] callback, so that the children do
/// not even have to be built until they are displayed.
///
/// The widgets returned from the builder callback are automatically wrapped in
/// [AutomaticKeepAlive] widgets if [addAutomaticKeepAlives] is true (the
/// default) and in [RepaintBoundary] widgets if [addRepaintBoundaries] is true
/// (also the default).
///
/// ## Accessibility
///
/// The [CustomScrollView] requires that its semantic children are annotated
/// using [IndexedSemantics]. This is done by default in the delegate with
/// the `addSemanticIndexes` parameter set to true.
///
/// If multiple delegates are used in a single scroll view, then the indexes
/// will not be correct by default. The `semanticIndexOffset` can be used to
/// offset the semantic indexes of each delegate so that the indexes are
/// monotonically increasing. For example, if a scroll view contains two
/// delegates where the first has 10 children contributing semantics, then the
/// second delegate should offset its children by 10.
///
/// {@tool snippet}
///
/// This sample code shows how to use `semanticIndexOffset` to handle multiple
/// delegates in a single scroll view.
///
/// ```dart
/// CustomScrollView(
///   semanticChildCount: 4,
///   slivers: <Widget>[
///     SliverGrid(
///       gridDelegate: _gridDelegate,
///       delegate: SliverChildBuilderDelegate(
///         (BuildContext context, int index) {
///            return const Text('...');
///          },
///          childCount: 2,
///        ),
///      ),
///     SliverGrid(
///       gridDelegate: _gridDelegate,
///       delegate: SliverChildBuilderDelegate(
///         (BuildContext context, int index) {
///            return const Text('...');
///          },
///          childCount: 2,
///          semanticIndexOffset: 2,
///        ),
///      ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// In certain cases, only a subset of child widgets should be annotated
/// with a semantic index. For example, in [ListView.separated()] the
/// separators do not have an index associated with them. This is done by
/// providing a `semanticIndexCallback` which returns null for separators
/// indexes and rounds the non-separator indexes down by half.
///
/// {@tool snippet}
///
/// This sample code shows how to use `semanticIndexCallback` to handle
/// annotating a subset of child nodes with a semantic index. There is
/// a [Spacer] widget at odd indexes which should not have a semantic
/// index.
///
/// ```dart
/// CustomScrollView(
///   semanticChildCount: 5,
///   slivers: <Widget>[
///     SliverGrid(
///       gridDelegate: _gridDelegate,
///       delegate: SliverChildBuilderDelegate(
///         (BuildContext context, int index) {
///            if (index.isEven) {
///              return const Text('...');
///            }
///            return const Spacer();
///          },
///          semanticIndexCallback: (Widget widget, int localIndex) {
///            if (localIndex.isEven) {
///              return localIndex ~/ 2;
///            }
///            return null;
///          },
///          childCount: 10,
///        ),
///      ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SliverChildListDelegate], which is a delegate that has an explicit list
///    of children.
///  * [IndexedSemantics], for an example of manually annotating child nodes
///    with semantic indexes.
public class SliverChildBuilderDelegate: SliverChildDelegate {
    /// Creates a delegate that supplies children for slivers using the given
    /// builder callback.
    ///
    /// The [builder], [addAutomaticKeepAlives], [addRepaintBoundaries],
    /// [addSemanticIndexes], and [semanticIndexCallback] arguments must not be
    /// null.
    ///
    /// If the order in which [builder] returns children ever changes, consider
    /// providing a [findChildIndexCallback]. This allows the delegate to find the
    /// new index for a child that was previously located at a different index to
    /// attach the existing state to the [Widget] at its new location.
    public init(
        _ builder: @escaping NullableIndexedWidgetBuilder,
        findChildIndexCallback: ChildIndexGetter? = nil,
        childCount: Int? = nil,
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true,
        semanticIndexCallback: @escaping SemanticIndexCallback = _kDefaultSemanticIndexCallback,
        semanticIndexOffset: Int = 0
    ) {
        self.builder = builder
        self.findChildIndexCallback = findChildIndexCallback
        self.childCount = childCount
        self.addAutomaticKeepAlives = addAutomaticKeepAlives
        self.addRepaintBoundaries = addRepaintBoundaries
        self.addSemanticIndexes = addSemanticIndexes
        self.semanticIndexCallback = semanticIndexCallback
        self.semanticIndexOffset = semanticIndexOffset
    }

    /// Called to build children for the sliver.
    ///
    /// Will be called only for indices greater than or equal to zero and less
    /// than [childCount] (if [childCount] is non-null).
    ///
    /// Should return null if asked to build a widget with a greater index than
    /// exists.
    ///
    /// May result in an infinite loop or run out of memory if [childCount] is null
    /// and the [builder] always provides a zero-size widget (such as `Container()`
    /// or `SizedBox.shrink()`). If possible, provide children with non-zero size,
    /// return null from [builder], or set a [childCount].
    ///
    /// The delegate wraps the children returned by this builder in
    /// [RepaintBoundary] widgets.
    public let builder: NullableIndexedWidgetBuilder

    /// The total number of children this delegate can provide.
    ///
    /// If null, the number of children is determined by the least index for which
    /// [builder] returns null.
    ///
    /// May result in an infinite loop or run out of memory if [childCount] is null
    /// and the [builder] always provides a zero-size widget (such as `Container()`
    /// or `SizedBox.shrink()`). If possible, provide children with non-zero size,
    /// return null from [builder], or set a [childCount].
    public let childCount: Int?

    /// {@template flutter.widgets.SliverChildBuilderDelegate.addAutomaticKeepAlives}
    /// Whether to wrap each child in an [AutomaticKeepAlive].
    ///
    /// Typically, lazily laid out children are wrapped in [AutomaticKeepAlive]
    /// widgets so that the children can use [KeepAliveNotification]s to preserve
    /// their state when they would otherwise be garbage collected off-screen.
    ///
    /// This feature (and [addRepaintBoundaries]) must be disabled if the children
    /// are going to manually maintain their [KeepAlive] state. It may also be
    /// more efficient to disable this feature if it is known ahead of time that
    /// none of the children will ever try to keep themselves alive.
    ///
    /// Defaults to true.
    /// {@endtemplate}
    public let addAutomaticKeepAlives: Bool

    /// {@template flutter.widgets.SliverChildBuilderDelegate.addRepaintBoundaries}
    /// Whether to wrap each child in a [RepaintBoundary].
    ///
    /// Typically, children in a scrolling container are wrapped in repaint
    /// boundaries so that they do not need to be repainted as the list scrolls.
    /// If the children are easy to repaint (e.g., solid color blocks or a short
    /// snippet of text), it might be more efficient to not add a repaint boundary
    /// and instead always repaint the children during scrolling.
    ///
    /// Defaults to true.
    /// {@endtemplate}
    public let addRepaintBoundaries: Bool

    /// {@template flutter.widgets.SliverChildBuilderDelegate.addSemanticIndexes}
    /// Whether to wrap each child in an [IndexedSemantics].
    ///
    /// Typically, children in a scrolling container must be annotated with a
    /// semantic index in order to generate the correct accessibility
    /// announcements. This should only be set to false if the indexes have
    /// already been provided by an [IndexedSemantics] widget.
    ///
    /// Defaults to true.
    ///
    /// See also:
    ///
    ///  * [IndexedSemantics], for an explanation of how to manually
    ///    provide semantic indexes.
    /// {@endtemplate}
    public let addSemanticIndexes: Bool

    /// {@template flutter.widgets.SliverChildBuilderDelegate.semanticIndexOffset}
    /// An initial offset to add to the semantic indexes generated by this widget.
    ///
    /// Defaults to zero.
    /// {@endtemplate}
    public let semanticIndexOffset: Int

    /// {@template flutter.widgets.SliverChildBuilderDelegate.semanticIndexCallback}
    /// A [SemanticIndexCallback] which is used when [addSemanticIndexes] is true.
    ///
    /// Defaults to providing an index for each widget.
    /// {@endtemplate}
    public let semanticIndexCallback: SemanticIndexCallback

    /// Called to find the new index of a child based on its key in case of reordering.
    ///
    /// If not provided, a child widget may not map to its existing [RenderObject]
    /// when the order of children returned from the children builder changes.
    /// This may result in state-loss.
    ///
    /// This callback should take an input [Key], and it should return the
    /// index of the child element with that associated key, or null if not found.
    public let findChildIndexCallback: ChildIndexGetter?

    public func findIndexByKey(_ key: any Key) -> Int? {
        if findChildIndexCallback == nil {
            return nil
        }
        let childKey: any Key
        if let saltedValueKey = key as? _SaltedValueKey {
            childKey = saltedValueKey.value
        } else {
            childKey = key
        }
        return findChildIndexCallback?(childKey)
    }

    public func build(_ context: BuildContext, index: Int) -> Widget? {
        if index < 0 || (childCount != nil && index >= childCount!) {
            return nil
        }
        let child = builder(context, index)
        guard let child else {
            return nil
        }
        let key: (any Key)? = child.key != nil ? _SaltedValueKey(child.key!) : nil
        // if addRepaintBoundaries {
        //     child = RepaintBoundary(child: child)
        // }
        // if addSemanticIndexes {
        //     let semanticIndex = semanticIndexCallback(child!, index)
        //     if let semanticIndex = semanticIndex {
        //         child = IndexedSemantics(index: semanticIndex + semanticIndexOffset, child: child!)
        //     }
        // }
        // if addAutomaticKeepAlives {
        //     child = AutomaticKeepAlive(child: _SelectionKeepAlive(child: child!))
        // }
        return KeyedSubtree(key: key) { child }
    }

    public var estimatedChildCount: Int? {
        return childCount
    }

    public func shouldRebuild(oldDelegate: SliverChildDelegate) -> Bool {
        return true
    }
}

/// A delegate that supplies children for slivers using an explicit list.
///
/// Many slivers lazily construct their box children to avoid creating more
/// children than are visible through the [Viewport]. This delegate provides
/// children using an explicit list, which is convenient but reduces the benefit
/// of building children lazily.
///
/// In general building all the widgets in advance is not efficient. It is
/// better to create a delegate that builds them on demand using
/// [SliverChildBuilderDelegate] or by subclassing [SliverChildDelegate]
/// directly.
///
/// This class is provided for the cases where either the list of children is
/// known well in advance (ideally the children are themselves compile-time
/// constants, for example), and therefore will not be built each time the
/// delegate itself is created, or the list is small, such that it's likely
/// always visible (and thus there is nothing to be gained by building it on
/// demand). For example, the body of a dialog box might fit both of these
/// conditions.
///
/// The widgets in the given [children] list are automatically wrapped in
/// [AutomaticKeepAlive] widgets if [addAutomaticKeepAlives] is true (the
/// default) and in [RepaintBoundary] widgets if [addRepaintBoundaries] is true
/// (also the default).
///
/// ## Accessibility
///
/// The [CustomScrollView] requires that its semantic children are annotated
/// using [IndexedSemantics]. This is done by default in the delegate with
/// the `addSemanticIndexes` parameter set to true.
///
/// If multiple delegates are used in a single scroll view, then the indexes
/// will not be correct by default. The `semanticIndexOffset` can be used to
/// offset the semantic indexes of each delegate so that the indexes are
/// monotonically increasing. For example, if a scroll view contains two
/// delegates where the first has 10 children contributing semantics, then the
/// second delegate should offset its children by 10.
///
/// In certain cases, only a subset of child widgets should be annotated
/// with a semantic index. For example, in [ListView.separated()] the
/// separators do not have an index associated with them. This is done by
/// providing a `semanticIndexCallback` which returns null for separators
/// indexes and rounds the non-separator indexes down by half.
///
/// See [SliverChildBuilderDelegate] for sample code using
/// `semanticIndexOffset` and `semanticIndexCallback`.
///
/// See also:
///
///  * [SliverChildBuilderDelegate], which is a delegate that uses a builder
///    callback to construct the children.
public class SliverChildListDelegate: SliverChildDelegate {
    /// Creates a delegate that supplies children for slivers using the given
    /// list.
    ///
    /// The [children], [addAutomaticKeepAlives], [addRepaintBoundaries],
    /// [addSemanticIndexes], and [semanticIndexCallback] arguments must not be
    /// null.
    ///
    /// If the order of children never changes, consider using the constant
    /// [SliverChildListDelegate.fixed] constructor.
    public init(
        _ children: [Widget],
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true,
        semanticIndexCallback: @escaping SemanticIndexCallback = _kDefaultSemanticIndexCallback,
        semanticIndexOffset: Int = 0
    ) {
        self.children = children
        self.addAutomaticKeepAlives = addAutomaticKeepAlives
        self.addRepaintBoundaries = addRepaintBoundaries
        self.addSemanticIndexes = addSemanticIndexes
        self.semanticIndexCallback = semanticIndexCallback
        self.semanticIndexOffset = semanticIndexOffset
        self._keyToIndex = [nil: 0]
    }

    /// Creates a constant version of the delegate that supplies children for
    /// slivers using the given list.
    ///
    /// If the order of the children will change, consider using the regular
    /// [SliverChildListDelegate] constructor.
    ///
    /// The [children], [addAutomaticKeepAlives], [addRepaintBoundaries],
    /// [addSemanticIndexes], and [semanticIndexCallback] arguments must not be
    /// null.
    public init(
        fixed children: [Widget],
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true,
        semanticIndexCallback: @escaping SemanticIndexCallback = _kDefaultSemanticIndexCallback,
        semanticIndexOffset: Int = 0
    ) {
        self.children = children
        self.addAutomaticKeepAlives = addAutomaticKeepAlives
        self.addRepaintBoundaries = addRepaintBoundaries
        self.addSemanticIndexes = addSemanticIndexes
        self.semanticIndexCallback = semanticIndexCallback
        self.semanticIndexOffset = semanticIndexOffset
        self._keyToIndex = nil
    }

    /// {@macro flutter.widgets.SliverChildBuilderDelegate.addAutomaticKeepAlives}
    public let addAutomaticKeepAlives: Bool

    /// {@macro flutter.widgets.SliverChildBuilderDelegate.addRepaintBoundaries}
    public let addRepaintBoundaries: Bool

    /// {@macro flutter.widgets.SliverChildBuilderDelegate.addSemanticIndexes}
    public let addSemanticIndexes: Bool

    /// {@macro flutter.widgets.SliverChildBuilderDelegate.semanticIndexOffset}
    public let semanticIndexOffset: Int

    /// {@macro flutter.widgets.SliverChildBuilderDelegate.semanticIndexCallback}
    public let semanticIndexCallback: SemanticIndexCallback

    /// The widgets to display.
    ///
    /// If this list is going to be mutated, it is usually wise to put a [Key] on
    /// each of the child widgets, so that the framework can match old
    /// configurations to new configurations and maintain the underlying render
    /// objects.
    ///
    /// Also, a [Widget] in Flutter is immutable, so directly modifying the
    /// [children] such as `someWidget.children.add(...)` or
    /// passing a reference of the original list value to the [children] parameter
    /// will result in incorrect behaviors. Whenever the
    /// children list is modified, a new list object must be provided.
    ///
    /// The following code corrects the problem mentioned above.
    ///
    /// ```swift
    /// class SomeWidgetState extends State<SomeWidget> {
    ///   final List<Widget> _children = <Widget>[];
    ///
    ///   void someHandler() {
    ///     setState(() {
    ///       // The key here allows Flutter to reuse the underlying render
    ///       // objects even if the children list is recreated.
    ///       _children.add(ChildWidget(key: UniqueKey()));
    ///     });
    ///   }
    ///
    ///   @override
    ///   Widget build(BuildContext context) {
    ///     // Always create a new list of children as a Widget is immutable.
    ///     return PageView(children: List<Widget>.of(_children));
    ///   }
    /// }
    /// ```
    public let children: [Widget]

    // A map to cache key to index lookup for children.
    //
    // _keyToIndex[null] is used as current index during the lazy loading process
    // in [_findChildIndex]. _keyToIndex should never be used for looking up null key.
    private var _keyToIndex: [AnyKey?: Int]?

    private var _isConstantInstance: Bool { _keyToIndex == nil }

    private func _findChildIndex(_ key: any Key) -> Int? {
        if _isConstantInstance {
            return nil
        }
        // Lazily fill the [_keyToIndex].
        if !_keyToIndex!.keys.contains(AnyKey(key)) {
            var index = _keyToIndex![nil]!
            while index < children.count {
                let child = children[index]
                if let childKey = child.key {
                    _keyToIndex![AnyKey(childKey)] = index
                }
                if child.key?.isEqualTo(key) == true {
                    // Record current index for next function call.
                    _keyToIndex![nil] = index + 1
                    return index
                }
                index += 1
            }
            _keyToIndex![nil] = index
        } else {
            return _keyToIndex![AnyKey(key)]
        }
        return nil
    }

    public func findIndexByKey(_ key: any Key) -> Int? {
        let childKey: any Key
        if let saltedValueKey = key as? _SaltedValueKey {
            childKey = saltedValueKey.value
        } else {
            childKey = key
        }
        return _findChildIndex(childKey)
    }

    public func build(_ context: BuildContext, index: Int) -> Widget? {
        if index < 0 || index >= children.count {
            return nil
        }
        let child = children[index]
        let key: (any Key)? = child.key != nil ? _SaltedValueKey(child.key!) : nil
        // if addRepaintBoundaries {
        //     child = RepaintBoundary { child }
        // }
        // if addSemanticIndexes {
        //     if let semanticIndex = semanticIndexCallback(child, index) {
        //         child = IndexedSemantics(index: semanticIndex + semanticIndexOffset) { child }
        //     }
        // }
        // if addAutomaticKeepAlives {
        //     child = AutomaticKeepAlive { _SelectionKeepAlive { child } }
        // }

        return KeyedSubtree(key: key) { child }
    }

    public var estimatedChildCount: Int? {
        return children.count
    }

    public func shouldRebuild(oldDelegate: any SliverChildDelegate) -> Bool {
        let oldDelegate = oldDelegate as! SliverChildListDelegate
        return !objectsEqual(children, oldDelegate.children)
    }
}
