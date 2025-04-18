import Collections
import SortedCollections

/// A base class for slivers that have [KeepAlive] children.
///
/// See also:
///
/// * [KeepAlive], which marks whether its child widget should be kept alive.
/// * [SliverChildBuilderDelegate] and [SliverChildListDelegate], slivers
///    which make use of the keep alive functionality through the
///    `addAutomaticKeepAlives` property.
/// * [SliverGrid] and [SliverList], two sliver widgets that are commonly
///    wrapped with [KeepAlive] widgets to preserve their sliver child subtrees.
public protocol SliverWithKeepAliveWidget: RenderObjectWidget {}

/// A base class for slivers that have multiple box children.
///
/// Helps subclasses build their children lazily using a [SliverChildDelegate].
///
/// The widgets returned by the [delegate] are cached and the delegate is only
/// consulted again if it changes and the new delegate's
/// [SliverChildDelegate.shouldRebuild] method returns true.
public protocol SliverMultiBoxAdaptorWidget: SliverWithKeepAliveWidget {
    /// {@template flutter.widgets.SliverMultiBoxAdaptorWidget.delegate}
    /// The delegate that provides the children for this widget.
    ///
    /// The children are constructed lazily using this delegate to avoid creating
    /// more children than are visible through the [Viewport].
    ///
    /// ## Using more than one delegate in a [Viewport]
    ///
    /// If multiple delegates are used in a single scroll view, the first child of
    /// each delegate will always be laid out, even if it extends beyond the
    /// currently viewable area. This is because at least one child is required in
    /// order to estimate the max scroll offset for the whole scroll view, as it
    /// uses the currently built children to estimate the remaining children's
    /// extent.
    ///
    /// See also:
    ///
    ///  * [SliverChildBuilderDelegate] and [SliverChildListDelegate], which are
    ///    commonly used subclasses of [SliverChildDelegate] that use a builder
    ///    callback and an explicit child list, respectively.
    /// {@endtemplate}
    var delegate: SliverChildDelegate { get }

    /// Returns an estimate of the max scroll extent for all the children.
    ///
    /// Subclasses should override this function if they have additional
    /// information about their max scroll extent.
    ///
    /// This is used by [SliverMultiBoxAdaptorElement] to implement part of the
    /// [RenderSliverBoxChildManager] API.
    ///
    /// The default implementation defers to [delegate] via its
    /// [SliverChildDelegate.estimateMaxScrollOffset] method.
    func estimateMaxScrollOffset(
        constraints: SliverConstraints?,
        firstIndex: Int,
        lastIndex: Int,
        leadingScrollOffset: Float,
        trailingScrollOffset: Float
    ) -> Float?
}

extension SliverMultiBoxAdaptorWidget {
    public func createElement() -> Element {
        return SliverMultiBoxAdaptorElement(widget: self)
    }

    public func estimateMaxScrollOffset(
        constraints: SliverConstraints?,
        firstIndex: Int,
        lastIndex: Int,
        leadingScrollOffset: Float,
        trailingScrollOffset: Float
    ) -> Float? {
        return delegate.estimateMaxScrollOffset(
            firstIndex: firstIndex,
            lastIndex: lastIndex,
            leadingScrollOffset: leadingScrollOffset,
            trailingScrollOffset: trailingScrollOffset
        )
    }
}

/// A sliver that places multiple box children in a linear array along the main
/// axis.
///
/// _To learn more about slivers, see [CustomScrollView.slivers]._
///
/// Each child is forced to have the [SliverConstraints.crossAxisExtent] in the
/// cross axis but determines its own main axis extent.
///
/// [SliverList] determines its scroll offset by "dead reckoning" because
/// children outside the visible part of the sliver are not materialized, which
/// means [SliverList] cannot learn their main axis extent. Instead, newly
/// materialized children are placed adjacent to existing children.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ORiTTaVY6mM}
///
/// If the children have a fixed extent in the main axis, consider using
/// [SliverFixedExtentList] rather than [SliverList] because
/// [SliverFixedExtentList] does not need to perform layout on its children to
/// obtain their extent in the main axis and is therefore more efficient.
///
/// {@macro flutter.widgets.SliverChildDelegate.lifecycle}
///
/// See also:
///
///  * <https://docs.flutter.dev/ui/layout/scrolling/slivers>, a description
///    of what slivers are and how to use them.
///  * [SliverFixedExtentList], which is more efficient for children with
///    the same extent in the main axis.
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item instead of a pixel value to define
///    the main axis extent of each item.
///  * [SliverAnimatedList], which animates items added to or removed from a
///    list.
///  * [SliverGrid], which places multiple children in a two dimensional grid.
///  * [SliverAnimatedGrid], a sliver which animates items when they are
///    inserted into or removed from a grid.
public class SliverList: SliverMultiBoxAdaptorWidget {
    /// Creates a sliver that places box children in a linear array.
    public init(key: (any Key)? = nil, delegate: SliverChildDelegate) {
        self.key = key
        self.delegate = delegate
    }

    public let key: (any Key)?

    public let delegate: SliverChildDelegate

    /// A sliver that places multiple box children in a linear array along the main
    /// axis.
    ///
    /// This constructor is appropriate for sliver lists with a large (or
    /// infinite) number of children because the builder is called only for those
    /// children that are actually visible.
    ///
    /// Providing a non-null `itemCount` improves the ability of the [SliverList]
    /// to estimate the maximum scroll extent.
    ///
    /// `itemBuilder` will be called only with indices greater than or equal to
    /// zero and less than `itemCount`.
    ///
    /// {@macro flutter.widgets.ListView.builder.itemBuilder}
    ///
    /// {@macro flutter.widgets.PageView.findChildIndexCallback}
    ///
    /// The `addAutomaticKeepAlives` argument corresponds to the
    /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
    /// `addRepaintBoundaries` argument corresponds to the
    /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
    /// `addSemanticIndexes` argument corresponds to the
    /// [SliverChildBuilderDelegate.addSemanticIndexes] property.
    ///
    /// {@tool snippet}
    /// This example, which would be provided in [CustomScrollView.slivers],
    /// shows an infinite number of items in varying shades of blue:
    ///
    ///
    /// SliverList.builder(
    ///   itemBuilder: (BuildContext context, int index) {
    ///     return Container(
    ///       alignment: Alignment.center,
    ///       color: Colors.lightBlue[100 * (index % 9)],
    ///       child: Text('list item $index'),
    ///     );
    ///   },
    /// )
    ///
    /// {@end-tool}
    public static func builder(
        key: (any Key)? = nil,
        itemCount: Int? = nil,
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true,
        itemBuilder: @escaping NullableIndexedWidgetBuilder,
        findChildIndexCallback: ChildIndexGetter? = nil
    ) -> SliverList {
        .init(
            key: key,
            delegate: SliverChildBuilderDelegate(
                itemBuilder,
                findChildIndexCallback: findChildIndexCallback,
                childCount: itemCount,
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addRepaintBoundaries: addRepaintBoundaries,
                addSemanticIndexes: addSemanticIndexes
            )
        )
    }

    /// A sliver that places multiple box children, separated by box widgets, in a
    /// linear array along the main axis.
    ///
    /// This constructor is appropriate for sliver lists with a large (or
    /// infinite) number of children because the builder is called only for those
    /// children that are actually visible.
    ///
    /// Providing a non-null `itemCount` improves the ability of the [SliverList]
    /// to estimate the maximum scroll extent.
    ///
    /// `itemBuilder` will be called only with indices greater than or equal to
    /// zero and less than `itemCount`.
    ///
    /// {@macro flutter.widgets.ListView.builder.itemBuilder}
    ///
    /// {@macro flutter.widgets.PageView.findChildIndexCallback}
    ///
    ///
    /// The `separatorBuilder` is similar to `itemBuilder`, except it is the widget
    /// that gets placed between itemBuilder(context, index) and itemBuilder(context, index + 1).
    ///
    /// The `addAutomaticKeepAlives` argument corresponds to the
    /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
    /// `addRepaintBoundaries` argument corresponds to the
    /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
    /// `addSemanticIndexes` argument corresponds to the
    /// [SliverChildBuilderDelegate.addSemanticIndexes] property.
    ///
    /// {@tool snippet}
    /// This example shows how to create a [SliverList] whose [Container] items
    /// are separated by [Divider]s. The [SliverList] would be provided in
    /// [CustomScrollView.slivers].
    ///
    ///
    /// SliverList.separated(
    ///   itemBuilder: (BuildContext context, int index) {
    ///     return Container(
    ///       alignment: Alignment.center,
    ///       color: Colors.lightBlue[100 * (index % 9)],
    ///       child: Text('list item $index'),
    ///     );
    ///   },
    ///   separatorBuilder: (BuildContext context, int index) => const Divider(),
    /// )
    ///
    /// {@end-tool}
    public static func separated(
        key: (any Key)? = nil,
        itemBuilder: @escaping NullableIndexedWidgetBuilder,
        findChildIndexCallback: ChildIndexGetter? = nil,
        separatorBuilder: @escaping NullableIndexedWidgetBuilder,
        itemCount: Int? = nil,
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true
    ) -> SliverList {
        .init(
            key: key,
            delegate: SliverChildBuilderDelegate(
                { (context: BuildContext, index: Int) -> Widget? in
                    let itemIndex = index / 2
                    let widget: Widget?
                    if index.isMultiple(of: 2) {
                        widget = itemBuilder(context, itemIndex)
                    } else {
                        widget = separatorBuilder(context, itemIndex)
                        assert(widget != nil, "separatorBuilder cannot return nil.")
                    }
                    return widget
                },
                findChildIndexCallback: findChildIndexCallback,
                childCount: itemCount == nil ? nil : max(0, itemCount! * 2 - 1),
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addRepaintBoundaries: addRepaintBoundaries,
                addSemanticIndexes: addSemanticIndexes,
                semanticIndexCallback: { (_, index: Int) -> Int? in
                    return index.isMultiple(of: 2) ? index / 2 : nil
                }
            )
        )
    }

    /// A sliver that places multiple box children in a linear array along the main
    /// axis.
    ///
    /// This constructor uses a list of [Widget]s to build the sliver.
    ///
    /// The `addAutomaticKeepAlives` argument corresponds to the
    /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
    /// `addRepaintBoundaries` argument corresponds to the
    /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
    /// `addSemanticIndexes` argument corresponds to the
    /// [SliverChildBuilderDelegate.addSemanticIndexes] property.
    ///
    /// {@tool snippet}
    /// This example, which would be provided in [CustomScrollView.slivers],
    /// shows a list containing two [Text] widgets:
    ///
    /// ```
    /// SliverList.list(
    ///   children: const <Widget>[
    ///     Text('Hello'),
    ///     Text('World!'),
    ///   ],
    /// );
    /// ```
    /// {@end-tool}
    public static func list(
        key: (any Key)? = nil,
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true,
        @WidgetListBuilder children: () -> [Widget]
    ) -> SliverList {
        .init(
            key: key,
            delegate: SliverChildListDelegate(
                children(),
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addRepaintBoundaries: addRepaintBoundaries,
                addSemanticIndexes: addSemanticIndexes
            )
        )
    }

    public func createElement() -> Element {
        return SliverMultiBoxAdaptorElement(widget: self, replaceMovedChildren: true)
    }

    public func createRenderObject(context: BuildContext) -> RenderSliverList {
        let element = context as! SliverMultiBoxAdaptorElement
        return RenderSliverList(childManager: element)
    }
}

/// A sliver that places multiple box children with the same main axis extent in
/// a linear array.
///
/// _To learn more about slivers, see [CustomScrollView.slivers]._
///
/// [SliverFixedExtentList] places its children in a linear array along the main
/// axis starting at offset zero and without gaps. Each child is forced to have
/// the [itemExtent] in the main axis and the
/// [SliverConstraints.crossAxisExtent] in the cross axis.
///
/// [SliverFixedExtentList] is more efficient than [SliverList] because
/// [SliverFixedExtentList] does not need to perform layout on its children to
/// obtain their extent in the main axis.
///
/// {@tool snippet}
///
/// This example, which would be inserted into a [CustomScrollView.slivers]
/// list, shows an infinite number of items in varying shades of blue:
///
/// ```dart
/// SliverFixedExtentList(
///   itemExtent: 50.0,
///   delegate: SliverChildBuilderDelegate(
///     (BuildContext context, int index) {
///       return Container(
///         alignment: Alignment.center,
///         color: Colors.lightBlue[100 * (index % 9)],
///         child: Text('list item $index'),
///       );
///     },
///   ),
/// )
/// ```
/// {@end-tool}
///
/// {@macro flutter.widgets.SliverChildDelegate.lifecycle}
///
/// See also:
///
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item instead of a pixel value to define
///    the main axis extent of each item.
///  * [SliverVariedExtentList], which supports children with varying (but known
///    upfront) extents.
///  * [SliverFillViewport], which determines the [itemExtent] based on
///    [SliverConstraints.viewportMainAxisExtent].
///  * [SliverList], which does not require its children to have the same
///    extent in the main axis.
public class SliverFixedExtentList: SliverMultiBoxAdaptorWidget {
    /// Creates a sliver that places box children with the same main axis extent
    /// in a linear array.
    public init(key: (any Key)? = nil, delegate: SliverChildDelegate, itemExtent: Float) {
        self.key = key
        self.delegate = delegate
        self.itemExtent = itemExtent
    }

    /// A sliver that places multiple box children in a linear array along the main
    /// axis.
    ///
    /// [SliverFixedExtentList] places its children in a linear array along the main
    /// axis starting at offset zero and without gaps. Each child is forced to have
    /// the [itemExtent] in the main axis and the
    /// [SliverConstraints.crossAxisExtent] in the cross axis.
    ///
    /// This constructor is appropriate for sliver lists with a large (or
    /// infinite) number of children whose extent is already determined.
    ///
    /// Providing a non-null `itemCount` improves the ability of the [SliverFixedExtentList]
    /// to estimate the maximum scroll extent.
    ///
    /// `itemBuilder` will be called only with indices greater than or equal to
    /// zero and less than `itemCount`.
    ///
    /// {@macro flutter.widgets.ListView.builder.itemBuilder}
    ///
    /// The `itemExtent` argument is the extent of each item.
    ///
    /// {@macro flutter.widgets.PageView.findChildIndexCallback}
    ///
    /// The `addAutomaticKeepAlives` argument corresponds to the
    /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
    /// `addRepaintBoundaries` argument corresponds to the
    /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
    /// `addSemanticIndexes` argument corresponds to the
    /// [SliverChildBuilderDelegate.addSemanticIndexes] property.
    /// {@tool snippet}
    ///
    /// This example, which would be inserted into a [CustomScrollView.slivers]
    /// list, shows an infinite number of items in varying shades of blue:
    ///
    ///
    /// SliverFixedExtentList.builder(
    ///   itemExtent: 50.0,
    ///   itemBuilder: (BuildContext context, int index) {
    ///     return Container(
    ///       alignment: Alignment.center,
    ///       color: Colors.lightBlue[100 * (index % 9)],
    ///       child: Text('list item $index'),
    ///     );
    ///   },
    /// )
    ///
    /// {@end-tool}
    public static func builder(
        key: (any Key)? = nil,
        itemBuilder: @escaping NullableIndexedWidgetBuilder,
        itemExtent: Float,
        findChildIndexCallback: ChildIndexGetter? = nil,
        itemCount: Int? = nil,
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true
    ) -> SliverFixedExtentList {
        .init(
            key: key,
            delegate: SliverChildBuilderDelegate(
                itemBuilder,
                findChildIndexCallback: findChildIndexCallback,
                childCount: itemCount,
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addRepaintBoundaries: addRepaintBoundaries,
                addSemanticIndexes: addSemanticIndexes
            ),
            itemExtent: itemExtent
        )
    }

    /// A sliver that places multiple box children in a linear array along the main
    /// axis.
    ///
    /// [SliverFixedExtentList] places its children in a linear array along the main
    /// axis starting at offset zero and without gaps. Each child is forced to have
    /// the [itemExtent] in the main axis and the
    /// [SliverConstraints.crossAxisExtent] in the cross axis.
    ///
    /// This constructor uses a list of [Widget]s to build the sliver.
    ///
    /// The `addAutomaticKeepAlives` argument corresponds to the
    /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
    /// `addRepaintBoundaries` argument corresponds to the
    /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
    /// `addSemanticIndexes` argument corresponds to the
    /// [SliverChildBuilderDelegate.addSemanticIndexes] property.
    ///
    /// {@tool snippet}
    /// This example, which would be inserted into a [CustomScrollView.slivers]
    /// list, shows an infinite number of items in varying shades of blue:
    ///
    ///
    /// SliverFixedExtentList.list(
    ///   itemExtent: 50.0,
    ///   children: const <Widget>[
    ///     Text('Hello'),
    ///     Text('World!'),
    ///   ],
    /// );
    ///
    /// {@end-tool}
    public static func list(
        key: (any Key)? = nil,
        children: [Widget],
        itemExtent: Float,
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true
    ) -> SliverFixedExtentList {
        return SliverFixedExtentList(
            key: key,
            delegate: SliverChildListDelegate(
                children,
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addRepaintBoundaries: addRepaintBoundaries,
                addSemanticIndexes: addSemanticIndexes
            ),
            itemExtent: itemExtent
        )
    }

    public let key: (any Key)?
    public let delegate: SliverChildDelegate
    /// The extent the children are forced to have in the main axis.
    public let itemExtent: Float

    public func createRenderObject(context: BuildContext) -> RenderSliverFixedExtentList {
        let element = context as! SliverMultiBoxAdaptorElement
        return RenderSliverFixedExtentList(childManager: element, itemExtent: itemExtent)
    }

    public func updateRenderObject(
        context: BuildContext,
        renderObject: RenderSliverFixedExtentList
    ) {
        renderObject._itemExtent = itemExtent
    }
}

/// A sliver that places its box children in a linear array and constrains them
/// to have the corresponding extent returned by [itemExtentBuilder].
///
/// _To learn more about slivers, see [CustomScrollView.slivers]._
///
/// [SliverVariedExtentList] arranges its children in a line along
/// the main axis starting at offset zero and without gaps. Each child is
/// constrained to the corresponding extent along the main axis
/// and the [SliverConstraints.crossAxisExtent] along the cross axis.
///
/// [SliverVariedExtentList] is more efficient than [SliverList] because
/// [SliverVariedExtentList] does not need to lay out its children to obtain
/// their extent along the main axis. It's a little more flexible than
/// [SliverFixedExtentList] because this allow the children to have different extents.
///
/// See also:
///
///  * [SliverFixedExtentList], whose children are forced to a given pixel
///    extent.
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item instead of a pixel value to define
///    the main axis extent of each item.
///  * [SliverList], which does not require its children to have the same
///    extent in the main axis.
///  * [SliverFillViewport], which sizes its children based on the
///    size of the viewport, regardless of what else is in the scroll view.
public class SliverVariedExtentList: SliverMultiBoxAdaptorWidget {
    /// Creates a sliver that places box children with the same main axis extent
    /// in a linear array.
    public init(
        key: (any Key)? = nil,
        delegate: SliverChildDelegate,
        itemExtentBuilder: @escaping ItemExtentBuilder
    ) {
        self.key = key
        self.delegate = delegate
        self.itemExtentBuilder = itemExtentBuilder
    }

    /// A sliver that places multiple box children in a linear array along the main
    /// axis.
    ///
    /// [SliverVariedExtentList] places its children in a linear array along the main
    /// axis starting at offset zero and without gaps. Each child is forced to have
    /// the returned extent of [itemExtentBuilder] in the main axis and the
    /// [SliverConstraints.crossAxisExtent] in the cross axis.
    ///
    /// This constructor is appropriate for sliver lists with a large (or
    /// infinite) number of children whose extent is already determined.
    ///
    /// Providing a non-null `itemCount` improves the ability of the [SliverVariedExtentList]
    /// to estimate the maximum scroll extent.
    public static func builder(
        key: (any Key)? = nil,
        itemBuilder: @escaping NullableIndexedWidgetBuilder,
        itemExtentBuilder: @escaping ItemExtentBuilder,
        findChildIndexCallback: ChildIndexGetter? = nil,
        itemCount: Int? = nil,
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true
    ) -> SliverVariedExtentList {
        .init(
            key: key,
            delegate: SliverChildBuilderDelegate(
                itemBuilder,
                findChildIndexCallback: findChildIndexCallback,
                childCount: itemCount,
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addRepaintBoundaries: addRepaintBoundaries,
                addSemanticIndexes: addSemanticIndexes
            ),
            itemExtentBuilder: itemExtentBuilder
        )
    }

    /// A sliver that places multiple box children in a linear array along the main
    /// axis.
    ///
    /// [SliverVariedExtentList] places its children in a linear array along the main
    /// axis starting at offset zero and without gaps. Each child is forced to have
    /// the returned extent of [itemExtentBuilder] in the main axis and the
    /// [SliverConstraints.crossAxisExtent] in the cross axis.
    ///
    /// This constructor uses a list of [Widget]s to build the sliver.
    public static func list(
        key: (any Key)? = nil,
        children: [Widget],
        itemExtentBuilder: @escaping ItemExtentBuilder,
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true
    ) -> SliverVariedExtentList {
        .init(
            key: key,
            delegate: SliverChildListDelegate(
                children,
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addRepaintBoundaries: addRepaintBoundaries,
                addSemanticIndexes: addSemanticIndexes
            ),
            itemExtentBuilder: itemExtentBuilder
        )
    }

    public let key: (any Key)?
    public let delegate: SliverChildDelegate
    /// The children extent builder.
    ///
    /// Should return null if asked to build an item extent with a greater index than
    /// exists.
    public let itemExtentBuilder: ItemExtentBuilder

    public func createRenderObject(context: BuildContext) -> RenderSliverVariedExtentList {
        let element = context as! SliverMultiBoxAdaptorElement
        return RenderSliverVariedExtentList(
            childManager: element,
            itemExtentBuilder: itemExtentBuilder
        )
    }

    public func updateRenderObject(
        context: BuildContext,
        renderObject: RenderSliverVariedExtentList
    ) {
        renderObject._itemExtentBuilder = itemExtentBuilder
    }
}

/// A sliver that places multiple box children in a two dimensional arrangement.
///
/// _To learn more about slivers, see [CustomScrollView.slivers]._
///
/// [SliverGrid] places its children in arbitrary positions determined by
/// [gridDelegate]. Each child is forced to have the size specified by the
/// [gridDelegate].
///
/// The main axis direction of a grid is the direction in which it scrolls; the
/// cross axis direction is the orthogonal direction.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ORiTTaVY6mM}
///
/// {@tool snippet}
///
/// This example, which would be inserted into a [CustomScrollView.slivers]
/// list, shows twenty boxes in a pretty teal grid:
///
/// ```dart
/// SliverGrid(
///   gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
///     maxCrossAxisExtent: 200.0,
///     mainAxisSpacing: 10.0,
///     crossAxisSpacing: 10.0,
///     childAspectRatio: 4.0,
///   ),
///   delegate: SliverChildBuilderDelegate(
///     (BuildContext context, int index) {
///       return Container(
///         alignment: Alignment.center,
///         color: Colors.teal[100 * (index % 9)],
///         child: Text('grid item $index'),
///       );
///     },
///     childCount: 20,
///   ),
/// )
/// ```
/// {@end-tool}
///
/// {@macro flutter.widgets.SliverChildDelegate.lifecycle}
///
/// See also:
///
///  * [SliverList], which places its children in a linear array.
///  * [SliverFixedExtentList], which places its children in a linear
///    array with a fixed extent in the main axis.
///  * [SliverPrototypeExtentList], which is similar to [SliverFixedExtentList]
///    except that it uses a prototype list item instead of a pixel value to define
///    the main axis extent of each item.
public class SliverGrid: SliverMultiBoxAdaptorWidget {
    /// Creates a sliver that places multiple box children in a two dimensional
    /// arrangement.
    public init(
        key: (any Key)? = nil,
        delegate: SliverChildDelegate,
        gridDelegate: any SliverGridDelegate
    ) {
        self.key = key
        self.delegate = delegate
        self.gridDelegate = gridDelegate
    }

    /// A sliver that creates a 2D array of widgets that are created on demand.
    ///
    /// This constructor is appropriate for sliver grids with a large (or
    /// infinite) number of children because the builder is called only for those
    /// children that are actually visible.
    ///
    /// Providing a non-null `itemCount` improves the ability of the [SliverGrid]
    /// to estimate the maximum scroll extent.
    ///
    /// `itemBuilder` will be called only with indices greater than or equal to
    /// zero and less than `itemCount`.
    ///
    /// {@macro flutter.widgets.ListView.builder.itemBuilder}
    ///
    /// {@macro flutter.widgets.PageView.findChildIndexCallback}
    ///
    /// The [gridDelegate] argument is required.
    ///
    /// The `addAutomaticKeepAlives` argument corresponds to the
    /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
    /// `addRepaintBoundaries` argument corresponds to the
    /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
    /// `addSemanticIndexes` argument corresponds to the
    /// [SliverChildBuilderDelegate.addSemanticIndexes] property.
    public static func builder(
        key: (any Key)? = nil,
        gridDelegate: any SliverGridDelegate,
        itemBuilder: @escaping NullableIndexedWidgetBuilder,
        findChildIndexCallback: ChildIndexGetter? = nil,
        itemCount: Int? = nil,
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true
    ) -> SliverGrid {
        return SliverGrid(
            key: key,
            delegate: SliverChildBuilderDelegate(
                itemBuilder,
                findChildIndexCallback: findChildIndexCallback,
                childCount: itemCount,
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addRepaintBoundaries: addRepaintBoundaries,
                addSemanticIndexes: addSemanticIndexes
            ),
            gridDelegate: gridDelegate
        )
    }

    /// Creates a sliver that places multiple box children in a two dimensional
    /// arrangement with a fixed number of tiles in the cross axis.
    ///
    /// Uses a [SliverGridDelegateWithFixedCrossAxisCount] as the [gridDelegate],
    /// and a [SliverChildListDelegate] as the [delegate].
    ///
    /// See also:
    ///
    ///  * [GridView.count], the equivalent constructor for [GridView] widgets.
    public static func count(
        key: (any Key)? = nil,
        crossAxisCount: Int,
        mainAxisSpacing: Float = 0.0,
        crossAxisSpacing: Float = 0.0,
        childAspectRatio: Float = 1.0,
        @WidgetListBuilder children: () -> [Widget]
    ) -> SliverGrid {
        return SliverGrid(
            key: key,
            delegate: SliverChildListDelegate(children()),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
                childAspectRatio: childAspectRatio
            )
        )
    }

    /// Creates a sliver that places multiple box children in a two dimensional
    /// arrangement with tiles that each have a maximum cross-axis extent.
    ///
    /// Uses a [SliverGridDelegateWithMaxCrossAxisExtent] as the [gridDelegate],
    /// and a [SliverChildListDelegate] as the [delegate].
    ///
    /// See also:
    ///
    ///  * [GridView.extent], the equivalent constructor for [GridView] widgets.
    public static func extent(
        key: (any Key)? = nil,
        maxCrossAxisExtent: Float,
        mainAxisSpacing: Float = 0.0,
        crossAxisSpacing: Float = 0.0,
        childAspectRatio: Float = 1.0,
        @WidgetListBuilder children: () -> [Widget]
    ) -> SliverGrid {
        return SliverGrid(
            key: key,
            delegate: SliverChildListDelegate(children()),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxCrossAxisExtent,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
                childAspectRatio: childAspectRatio
            )
        )
    }

    public let key: (any Key)?
    public let delegate: SliverChildDelegate
    /// The delegate that controls the size and position of the children.
    public let gridDelegate: any SliverGridDelegate

    public func createRenderObject(context: BuildContext) -> RenderSliverGrid {
        let element = context as! SliverMultiBoxAdaptorElement
        return RenderSliverGrid(childManager: element, gridDelegate: gridDelegate)
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderSliverGrid) {
        renderObject.gridDelegate = gridDelegate
    }

    public func estimateMaxScrollOffset(
        constraints: SliverConstraints?,
        firstIndex: Int,
        lastIndex: Int,
        leadingScrollOffset: Float,
        trailingScrollOffset: Float
    ) -> Float? {
        return delegate.estimateMaxScrollOffset(
            firstIndex: firstIndex,
            lastIndex: lastIndex,
            leadingScrollOffset: leadingScrollOffset,
            trailingScrollOffset: trailingScrollOffset
        )
            ?? gridDelegate.getLayout(constraints!).computeMaxScrollOffset(
                delegate.estimatedChildCount!
            )
    }
}

/// An element that lazily builds children for a [SliverMultiBoxAdaptorWidget].
///
/// Implements [RenderSliverBoxChildManager], which lets this element manage
/// the children of subclasses of [RenderSliverMultiBoxAdaptor].
public class SliverMultiBoxAdaptorElement: RenderObjectElement, RenderSliverBoxChildManager {
    /// Creates an element that lazily builds children for the given widget.
    ///
    /// If `replaceMovedChildren` is set to true, a new child is proactively
    /// inflate for the index that was previously occupied by a child that moved
    /// to a new index. The layout offset of the moved child is copied over to the
    /// new child. RenderObjects, that depend on the layout offset of existing
    /// children during [RenderObject.performLayout] should set this to true
    /// (example: [RenderSliverList]). For RenderObjects that figure out the
    /// layout offset of their children without looking at the layout offset of
    /// existing children this should be set to false (example:
    /// [RenderSliverFixedExtentList]) to avoid inflating unnecessary children.
    public init(widget: any SliverMultiBoxAdaptorWidget, replaceMovedChildren: Bool = false) {
        self._replaceMovedChildren = replaceMovedChildren
        super.init(widget)
    }

    private let _replaceMovedChildren: Bool

    private var _renderObject: RenderSliverMultiBoxAdaptor {
        return super.renderObject as! RenderSliverMultiBoxAdaptor
    }

    public override func update(_ newWidget: any Widget) {
        let newWidget = newWidget as! any SliverMultiBoxAdaptorWidget
        let oldWidget = widget as! any SliverMultiBoxAdaptorWidget
        super.update(newWidget)
        let newDelegate = newWidget.delegate
        let oldDelegate = oldWidget.delegate
        if newDelegate !== oldDelegate
            && (type(of: newDelegate) != type(of: oldDelegate)
                || newDelegate.shouldRebuild(oldDelegate))
        {
            performRebuild()
        }
    }

    private var _childElements = SortedDictionary<Int, Element?>()
    private var _currentBeforeChild: RenderBox?

    public override func performRebuild() {
        super.performRebuild()
        _currentBeforeChild = nil
        var childrenUpdated = false
        assert(_currentlyUpdatingChildIndex == nil)

        var newChildren = SortedDictionary<Int, Element?>()
        var indexToLayoutOffset = [Int: Float]()
        let adaptorWidget = widget as! any SliverMultiBoxAdaptorWidget

        func processElement(_ index: Int) {
            _currentlyUpdatingChildIndex = index
            if _childElements[index] != nil && _childElements[index] != newChildren[index] {
                // This index has an old child that isn't used anywhere and should be deactivated.
                _childElements[index] = updateChild(_childElements[index] ?? nil, nil, index)
                childrenUpdated = true
            }
            let newChild = updateChild(
                newChildren[index] ?? nil,
                _build(index: index, widget: adaptorWidget),
                index
            )
            if let newChild {
                childrenUpdated = childrenUpdated || _childElements[index] != newChild
                _childElements[index] = newChild
                let parentData =
                    newChild.renderObject!.parentData! as! SliverMultiBoxAdaptorParentData
                if index == 0 {
                    parentData.layoutOffset = 0.0
                } else if indexToLayoutOffset[index] != nil {
                    parentData.layoutOffset = indexToLayoutOffset[index]
                }
                if !parentData.keptAlive {
                    _currentBeforeChild = newChild.renderObject as? RenderBox
                }
            } else {
                childrenUpdated = true
                _ = _childElements.removeValue(forKey: index)
            }
        }

        for index in _childElements.keys {
            let key = _childElements[index]!!.widget.key
            let newIndex = key == nil ? nil : adaptorWidget.delegate.findIndexByKey(key!)
            let childParentData =
                _childElements[index]!!.renderObject?.parentData as? SliverMultiBoxAdaptorParentData

            if let childParentData = childParentData, childParentData.layoutOffset != nil {
                indexToLayoutOffset[index] = childParentData.layoutOffset!
            }

            if let newIndex = newIndex, newIndex != index {
                // The layout offset of the child being moved is no longer accurate.
                if let childParentData = childParentData {
                    childParentData.layoutOffset = nil
                }

                newChildren[newIndex] = _childElements[index]
                if _replaceMovedChildren {
                    // We need to make sure the original index gets processed.
                    newChildren[index] = newChildren[index] ?? nil
                }
                // We do not want the remapped child to get deactivated during processElement.
                _ = _childElements.removeValue(forKey: index)
            } else {
                newChildren[index] = newChildren[index] ?? _childElements[index]
            }
        }

        // renderObject.debugChildIntegrityEnabled = false  // Moving children will temporary violate the integrity.
        newChildren.keys.forEach(processElement)
        // An element rebuild only updates existing children. The underflow check
        // is here to make sure we look ahead one more child if we were at the end
        // of the child list before the update. By doing so, we can update the max
        // scroll offset during the layout phase. Otherwise, the layout phase may
        // be skipped, and the scroll view may be stuck at the previous max
        // scroll offset.
        //
        // This logic is not needed if any existing children has been updated,
        // because we will not skip the layout phase if that happens.
        if !childrenUpdated && _didUnderflow {
            let lastKey = _childElements.keys.max() ?? -1
            let rightBoundary = lastKey + 1
            newChildren[rightBoundary] = _childElements[rightBoundary]
            processElement(rightBoundary)
        }

        _currentlyUpdatingChildIndex = nil
        // renderObject.debugChildIntegrityEnabled = true
    }

    private func _build(index: Int, widget: any SliverMultiBoxAdaptorWidget) -> Widget? {
        return widget.delegate.build(self, index: index)
    }

    public func createChild(_ index: Int, after: RenderBox?) {
        assert(_currentlyUpdatingChildIndex == nil)
        owner!.buildScope(self) { [self] in
            let insertFirst = after == nil
            assert(insertFirst || _childElements[index - 1] != nil)
            _currentBeforeChild =
                insertFirst ? nil : (_childElements[index - 1]!!.renderObject as? RenderBox)
            var newChild: Element?
            let adaptorWidget = widget as! (any SliverMultiBoxAdaptorWidget)
            _currentlyUpdatingChildIndex = index
            newChild = updateChild(
                _childElements[index] ?? nil,
                _build(index: index, widget: adaptorWidget),
                index
            )
            _currentlyUpdatingChildIndex = nil
            if let newChild = newChild {
                _childElements[index] = newChild
            } else {
                _ = _childElements.removeValue(forKey: index)
            }
        }
    }

    public override func updateChild(_ child: Element?, _ newWidget: Widget?, _ newSlot: Slot?)
        -> Element?
    {
        let oldParentData = child?.renderObject?.parentData as? SliverMultiBoxAdaptorParentData
        let newChild = super.updateChild(child, newWidget, newSlot)
        let newParentData = newChild?.renderObject?.parentData as? SliverMultiBoxAdaptorParentData

        // Preserve the old layoutOffset if the renderObject was swapped out.
        if oldParentData !== newParentData && oldParentData != nil && newParentData != nil {
            newParentData!.layoutOffset = oldParentData!.layoutOffset
        }
        return newChild
    }

    public override func forgetChild(_ child: Element) {
        assert(child.slot != nil)
        assert(_childElements.keys.contains(child.slot as! Int))
        _ = _childElements.removeValue(forKey: child.slot as! Int)
        super.forgetChild(child)
    }

    public func removeChild(_ child: RenderBox) {
        let index = _renderObject.indexOf(child)
        assert(_currentlyUpdatingChildIndex == nil)
        assert(index >= 0)
        owner!.buildScope(self) { [self] in
            assert(_childElements.keys.contains(index))
            _currentlyUpdatingChildIndex = index
            let result = updateChild(_childElements[index] ?? nil, nil, index)
            assert(result == nil)
            _currentlyUpdatingChildIndex = nil
            _ = _childElements.removeValue(forKey: index)
            assert(!_childElements.keys.contains(index))
        }
    }

    private static func _extrapolateMaxScrollOffset(
        firstIndex: Int,
        lastIndex: Int,
        leadingScrollOffset: Float,
        trailingScrollOffset: Float,
        childCount: Int
    ) -> Float {
        if lastIndex == childCount - 1 {
            return trailingScrollOffset
        }
        let reifiedCount = lastIndex - firstIndex + 1
        let averageExtent = (trailingScrollOffset - leadingScrollOffset) / Float(reifiedCount)
        let remainingCount = childCount - lastIndex - 1
        return trailingScrollOffset + averageExtent * Float(remainingCount)
    }

    public func estimateMaxScrollOffset(
        _ constraints: SliverConstraints,
        firstIndex: Int?,
        lastIndex: Int?,
        leadingScrollOffset: Float?,
        trailingScrollOffset: Float?
    ) -> Float {
        let childCount = estimatedChildCount
        if childCount == nil {
            return .infinity
        }
        return (widget as! any SliverMultiBoxAdaptorWidget).estimateMaxScrollOffset(
            constraints: constraints,
            firstIndex: firstIndex!,
            lastIndex: lastIndex!,
            leadingScrollOffset: leadingScrollOffset!,
            trailingScrollOffset: trailingScrollOffset!
        )
            ?? Self._extrapolateMaxScrollOffset(
                firstIndex: firstIndex!,
                lastIndex: lastIndex!,
                leadingScrollOffset: leadingScrollOffset!,
                trailingScrollOffset: trailingScrollOffset!,
                childCount: childCount!
            )
    }

    public var estimatedChildCount: Int? {
        return (widget as! any SliverMultiBoxAdaptorWidget).delegate.estimatedChildCount
    }

    public var childCount: Int {
        var result = estimatedChildCount
        if result == nil {
            // Since childCount was called, we know that we reached the end of
            // the list (as in, _build return null once), so we know that the
            // list is finite.
            // Let's do an open-ended binary search to find the end of the list
            // manually.
            var lo = 0
            var hi = 1
            let adaptorWidget = widget as! any SliverMultiBoxAdaptorWidget
            let max = Int.max
            while _build(index: hi - 1, widget: adaptorWidget) != nil {
                lo = hi - 1
                if hi < max / 2 {
                    hi *= 2
                } else if hi < max {
                    hi = max
                } else {
                    preconditionFailure(
                        """
                        Could not find the number of children in \(adaptorWidget.delegate).
                        The childCount getter was called (implying that the delegate's builder returned nil
                        for a positive index), but even building the child with index \(hi) (the maximum
                        possible integer) did not return nil. Consider implementing childCount to avoid
                        the cost of searching for the final child.
                        """
                    )
                }
            }
            while hi - lo > 1 {
                let mid = (hi - lo) / 2 + lo
                if _build(index: mid - 1, widget: adaptorWidget) == nil {
                    hi = mid
                } else {
                    lo = mid
                }
            }
            result = lo
        }
        return result!
    }

    public func didStartLayout() {
        assert(debugAssertChildListLocked())
    }

    public func didFinishLayout() {
        assert(debugAssertChildListLocked())
        let firstIndex = _childElements.keys.min() ?? 0
        let lastIndex = _childElements.keys.max() ?? 0
        (widget as! any SliverMultiBoxAdaptorWidget).delegate.didFinishLayout(
            firstIndex: firstIndex,
            lastIndex: lastIndex
        )
    }

    private var _currentlyUpdatingChildIndex: Int?

    public func debugAssertChildListLocked() -> Bool {
        assert(_currentlyUpdatingChildIndex == nil)
        return true
    }
    public func didAdoptChild(_ child: RenderBox) {
        assert(_currentlyUpdatingChildIndex != nil)
        let childParentData = child.parentData as! SliverMultiBoxAdaptorParentData
        childParentData.index = _currentlyUpdatingChildIndex
    }

    private var _didUnderflow = false

    public func setDidUnderflow(_ value: Bool) {
        _didUnderflow = value
    }

    public override func insertRenderObjectChild(_ child: RenderObject, slot: (any Slot)?) {
        let slot = slot as! Int
        assert(_currentlyUpdatingChildIndex == slot)
        // assert(renderObject.debugValidateChild(child))
        _renderObject.insert(child as! RenderBox, after: _currentBeforeChild)
        assert {
            let childParentData = child.parentData as! SliverMultiBoxAdaptorParentData
            assert(slot == childParentData.index)
            return true
        }
    }

    public override func moveRenderObjectChild(
        _ child: RenderObject,
        oldSlot: (any Slot)?,
        newSlot: (any Slot)?
    ) {
        let newSlot = newSlot as! Int
        assert(oldSlot is Int)
        assert(_currentlyUpdatingChildIndex == newSlot)
        _renderObject.move(child as! RenderBox, after: _currentBeforeChild)
    }

    public override func removeRenderObjectChild(_ child: RenderObject, slot: (any Slot)?) {
        assert(_currentlyUpdatingChildIndex != nil)
        _renderObject.remove(child as! RenderBox)
    }

    public override func visitChildren(_ visitor: ElementVisitor) {
        // The toList() is to make a copy so that the underlying list can be modified by
        // the visitor:
        assert(!_childElements.values.contains(where: { $0 == nil }))
        _childElements.values.compactMap({ $0 }).forEach(visitor)
    }

    // public override func debugVisitOnstageChildren(_ visitor: ElementVisitor) {
    //     _childElements.values.compactMap({ $0 }).filter { child in
    //         let parentData = child.renderObject!.parentData as! SliverMultiBoxAdaptorParentData
    //         let itemExtent: Float =
    //             switch renderObject.constraints.axis {
    //             case .horizontal:
    //                 child.renderObject!.paintBounds.width
    //             case .vertical:
    //                 child.renderObject!.paintBounds.height
    //             }

    //         return parentData.layoutOffset != nil
    //             && parentData.layoutOffset! < renderObject.constraints.scrollOffset
    //                 + renderObject.constraints.remainingPaintExtent
    //             && parentData.layoutOffset! + itemExtent > renderObject.constraints.scrollOffset
    //     }.forEach(visitor)
    // }
}

/// A sliver that places multiple sliver children in a linear array along
/// the cross axis.
///
/// ## Layout algorithm
///
/// _This section describes how the framework causes [RenderSliverCrossAxisGroup]
/// to position its children._
///
/// Layout for a [RenderSliverCrossAxisGroup] has four steps:
///
/// 1. Layout each child with a null or zero flex factor with cross axis constraint
///    being whatever cross axis space is remaining after laying out any previous
///    sliver. Slivers with null or zero flex factor should determine their own
///    [SliverGeometry.crossAxisExtent]. For example, the [SliverConstrainedCrossAxis]
///    widget uses either [SliverConstrainedCrossAxis.maxExtent] or
///    [SliverConstraints.crossAxisExtent], deciding between whichever is smaller.
/// 2. Divide up the remaining cross axis space among the children with non-zero flex
///    factors according to their flex factor. For example, a child with a flex
///    factor of 2.0 will receive twice the amount of cross axis space as a child
///    with a flex factor 1.0.
/// 3. Layout each of the remaining children with the cross axis constraint
///    allocated in the previous step.
/// 4. Set the geometry to that of whichever child has the longest
///    [SliverGeometry.scrollExtent] with the [SliverGeometry.crossAxisExtent] adjusted
///    to [SliverConstraints.crossAxisExtent].
///
/// {@tool dartpad}
/// In this sample the [SliverCrossAxisGroup] sizes its three [children] so that
/// the first normal [SliverList] has a flex factor of 1, the second [SliverConstrainedCrossAxis]
/// has a flex factor of 0 and a maximum cross axis extent of 200.0, and the third
/// [SliverCrossAxisExpanded] has a flex factor of 2.
///
/// ** See code in examples/api/lib/widgets/sliver/sliver_cross_axis_group.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SliverCrossAxisExpanded], which is the [ParentDataWidget] for setting a flex
///    value to a widget.
///  * [SliverConstrainedCrossAxis], which is a [RenderObjectWidget] for setting
///    an extent to constrain the widget to.
///  * [SliverMainAxisGroup], which is the [RenderObjectWidget] for laying out
///    multiple slivers along the main axis.
/// A sliver that places multiple sliver children in a linear array along
/// the cross axis.
public class SliverCrossAxisGroup: MultiChildRenderObjectWidget {
    /// Creates a sliver that places sliver children in a linear array along
    /// the cross axis.
    public init(
        key: (any Key)? = nil,
        slivers: [Widget]
    ) {
        self.key = key
        self.children = slivers
    }

    public let key: (any Key)?
    public var children: [any Widget]

    public func createRenderObject(context: BuildContext) -> RenderSliverCrossAxisGroup {
        return RenderSliverCrossAxisGroup()
    }
}

/// A sliver that places multiple sliver children in a linear array along
/// the main axis, one after another.
///
/// ## Layout algorithm
///
/// _This section describes how the framework causes [RenderSliverMainAxisGroup]
/// to position its children._
///
/// Layout for a [RenderSliverMainAxisGroup] has four steps:
///
/// 1. Keep track of an offset variable which is the total [SliverGeometry.scrollExtent]
///    of the slivers laid out so far.
/// 2. To determine the constraints for the next sliver child to layout, calculate the
///    amount of paint extent occupied from 0.0 to the offset variable and subtract this from
///    [SliverConstraints.remainingPaintExtent] minus to use as the child's
///    [SliverConstraints.remainingPaintExtent]. For the [SliverConstraints.scrollOffset],
///    take the provided constraint's value and subtract out the offset variable, using
///    0.0 if negative.
/// 3. Once we finish laying out all the slivers, this offset variable represents
///    the total [SliverGeometry.scrollExtent] of the sliver group. Since it is possible
///    for specialized slivers to try to paint itself outside of the bounds of the
///    sliver group's scroll extent (see [SliverPersistentHeader]), we must do a
///    second pass to set a [SliverPhysicalParentData.paintOffset] to make sure it
///    is within the bounds of the sliver group.
/// 4. Finally, set the [RenderSliverMainAxisGroup.geometry] with the total
///    [SliverGeometry.scrollExtent], [SliverGeometry.paintExtent] calculated from
///    the constraints and [SliverGeometry.scrollExtent], and [SliverGeometry.maxPaintExtent].
///
/// {@tool dartpad}
/// In this sample the [CustomScrollView] renders a [SliverMainAxisGroup] and a
/// [SliverToBoxAdapter] with some content. The [SliverMainAxisGroup] renders a
/// [SliverAppBar], [SliverList], and [SliverToBoxAdapter]. Notice that when the
/// [SliverMainAxisGroup] goes out of view, so does the pinned [SliverAppBar].
///
/// ** See code in examples/api/lib/widgets/sliver/sliver_main_axis_group.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SliverPersistentHeader], which is a [RenderObjectWidget] which may require
///    adjustment to its [SliverPhysicalParentData.paintOffset] to make it fit
///    within the computed [SliverGeometry.scrollExtent] of the [SliverMainAxisGroup].
///  * [SliverCrossAxisGroup], which is the [RenderObjectWidget] for laying out
///    multiple slivers along the cross axis.
public class SliverMainAxisGroup: MultiChildRenderObjectWidget {
    public init(
        key: (any Key)? = nil,
        @WidgetListBuilder children: () -> [Widget]
    ) {
        self.key = key
        self.children = children()
    }

    public var key: (any Key)?

    public var children: [any Widget]

    public func createRenderObject(context: any BuildContext) -> some RenderObject {
        return RenderSliverMainAxisGroup()
    }
}
