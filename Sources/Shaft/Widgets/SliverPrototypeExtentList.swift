/// A sliver that places its box children in a linear array and constrains them
/// to have the same extent as a prototype item along the main axis.
///
/// _To learn more about slivers, see [CustomScrollView.slivers]._
///
/// [SliverPrototypeExtentList] arranges its children in a line along
/// the main axis starting at offset zero and without gaps. Each child is
/// constrained to the same extent as the [prototypeItem] along the main axis
/// and the [SliverConstraints.crossAxisExtent] along the cross axis.
///
/// [SliverPrototypeExtentList] is more efficient than [SliverList] because
/// [SliverPrototypeExtentList] does not need to lay out its children to obtain
/// their extent along the main axis. It's a little more flexible than
/// [SliverFixedExtentList] because there's no need to determine the appropriate
/// item extent in pixels.
///
/// See also:
///
///  * [SliverFixedExtentList], whose children are forced to a given pixel
///    extent.
///  * [SliverVariedExtentList], which supports children with varying (but known
///    upfront) extents.
///  * [SliverList], which does not require its children to have the same
///    extent in the main axis.
///  * [SliverFillViewport], which sizes its children based on the
///    size of the viewport, regardless of what else is in the scroll view.
public class SliverPrototypeExtentList: SliverMultiBoxAdaptorWidget {
    /// Creates a sliver that places its box children in a linear array and
    /// constrains them to have the same extent as a prototype item along
    /// the main axis.
    public init(
        key: (any Key)? = nil,
        delegate: SliverChildDelegate,
        prototypeItem: Widget
    ) {
        self.key = key
        self.delegate = delegate
        self.prototypeItem = prototypeItem
    }

    /// A sliver that places its box children in a linear array and constrains them
    /// to have the same extent as a prototype item along the main axis.
    ///
    /// This constructor is appropriate for sliver lists with a large (or
    /// infinite) number of children whose extent is already determined.
    ///
    /// Providing a non-null `itemCount` improves the ability of the [SliverGrid]
    /// to estimate the maximum scroll extent.
    ///
    /// `itemBuilder` will be called only with indices greater than or equal to
    /// zero and less than `itemCount`.
    ///
    /// {@macro flutter.widgets.ListView.builder.itemBuilder}
    ///
    /// The `prototypeItem` argument is used to determine the extent of each item.
    ///
    /// {@macro flutter.widgets.PageView.findChildIndexCallback}
    ///
    /// The `addAutomaticKeepAlives` argument corresponds to the
    /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
    /// `addRepaintBoundaries` argument corresponds to the
    /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
    /// `addSemanticIndexes` argument corresponds to the
    /// [SliverChildBuilderDelegate.addSemanticIndexes] property.
    public convenience init(
        key: (any Key)? = nil,
        itemBuilder: @escaping NullableIndexedWidgetBuilder,
        prototypeItem: Widget,
        findChildIndexCallback: ChildIndexGetter? = nil,
        itemCount: Int? = nil,
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true
    ) {
        let delegate = SliverChildBuilderDelegate(
            itemBuilder,
            findChildIndexCallback: findChildIndexCallback,
            childCount: itemCount,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes
        )
        self.init(key: key, delegate: delegate, prototypeItem: prototypeItem)
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
    public convenience init(
        key: (any Key)? = nil,
        children: [Widget],
        prototypeItem: Widget,
        addAutomaticKeepAlives: Bool = true,
        addRepaintBoundaries: Bool = true,
        addSemanticIndexes: Bool = true
    ) {
        let delegate = SliverChildListDelegate(
            children,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes
        )
        self.init(key: key, delegate: delegate, prototypeItem: prototypeItem)
    }

    public let key: (any Key)?

    public let delegate: SliverChildDelegate

    /// Defines the main axis extent of all of this sliver's children.
    ///
    /// The [prototypeItem] is laid out before the rest of the sliver's children
    /// and its size along the main axis fixes the size of each child. The
    /// [prototypeItem] is essentially [Offstage]: it is not painted and it
    /// cannot respond to input.
    public let prototypeItem: Widget

    public func createRenderObject(context: BuildContext) -> RenderSliverMultiBoxAdaptor {
        let element = context as! _SliverPrototypeExtentListElement
        return _RenderSliverPrototypeExtentList(childManager: element)
    }

    public func createElement() -> SliverMultiBoxAdaptorElement {
        return _SliverPrototypeExtentListElement(self)
    }
}

private class _SliverPrototypeExtentListElement: SliverMultiBoxAdaptorElement {
    public init(_ widget: SliverPrototypeExtentList) {
        super.init(widget: widget)
    }

    private var _renderObject: _RenderSliverPrototypeExtentList {
        return super.renderObject as! _RenderSliverPrototypeExtentList
    }

    var _prototype: Element?
    static let _prototypeSlot = UniqueSlot()

    override func insertRenderObjectChild(_ child: RenderObject, slot: (any Slot)?) {
        if slotEqual(slot, Self._prototypeSlot) {
            assert(child is RenderBox)
            _renderObject.child = child as? RenderBox
        } else {
            super.insertRenderObjectChild(child, slot: slot as! Int)
        }
    }

    override func didAdoptChild(_ child: RenderBox) {
        if child !== _renderObject.child {
            super.didAdoptChild(child)
        }
    }

    override func moveRenderObjectChild(
        _ child: RenderObject,
        oldSlot: (any Slot)?,
        newSlot: (any Slot)?
    ) {
        if slotEqual(newSlot, Self._prototypeSlot) {
            // There's only one prototype child so it cannot be moved.
            assert(false)
        } else {
            super.moveRenderObjectChild(child, oldSlot: oldSlot as! Int, newSlot: newSlot as! Int)
        }
    }

    override func removeRenderObjectChild(_ child: RenderObject, slot: (any Slot)?) {
        if _renderObject.child === child {
            _renderObject.child = nil
        } else {
            super.removeRenderObjectChild(child, slot: slot as! Int)
        }
    }

    override func visitChildren(_ visitor: ElementVisitor) {
        if let _prototype {
            visitor(_prototype)
        }
        super.visitChildren(visitor)
    }

    override func mount(_ parent: Element?, slot newSlot: (any Slot)? = nil) {
        super.mount(parent, slot: newSlot)
        _prototype = updateChild(
            _prototype,
            (widget as! SliverPrototypeExtentList).prototypeItem,
            Self._prototypeSlot
        )
    }

    override func update(_ newWidget: any Widget) {
        super.update(newWidget)
        assert(widget === newWidget)
        _prototype = updateChild(
            _prototype,
            (widget as! SliverPrototypeExtentList).prototypeItem,
            Self._prototypeSlot
        )
    }
}

private class _RenderSliverPrototypeExtentList: RenderSliverFixedExtentBoxAdaptor {
    init(childManager: _SliverPrototypeExtentListElement) {
        super.init(childManager: childManager)
    }

    private var _child: RenderBox?
    var child: RenderBox? {
        get { _child }
        set {
            if let _child {
                dropChild(child: _child)
            }
            _child = newValue
            if let _child {
                adoptChild(child: _child)
            }
            markNeedsLayout()
        }
    }

    override func performLayout() {
        child!.layout(sliverConstraints.asBoxConstraints(), parentUsesSize: true)
        super.performLayout()
    }

    override func attach(_ owner: RenderOwner) {
        super.attach(owner)
        _child?.attach(owner)
    }

    override func detach() {
        super.detach()
        _child?.detach()
    }

    override func redepthChildren() {
        if let _child {
            redepthChild(_child)
        }
        super.redepthChildren()
    }

    override func visitChildren(_ visitor: (RenderBox) -> Void) {
        if let _child {
            visitor(_child)
        }
        super.visitChildren(visitor)
    }

    override var itemExtent: Float {
        assert(child != nil && child!.hasSize)
        return sliverConstraints.axis == .vertical ? child!.size.height : child!.size.width
    }
}
