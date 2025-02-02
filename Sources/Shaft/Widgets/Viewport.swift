/// A widget through which a portion of larger content can be viewed, typically
/// in combination with a [Scrollable].
///
/// [Viewport] is the visual workhorse of the scrolling machinery. It displays a
/// subset of its children according to its own dimensions and the given
/// [offset]. As the offset varies, different children are visible through
/// the viewport.
///
/// [Viewport] hosts a bidirectional list of slivers, anchored on a [center]
/// sliver, which is placed at the zero scroll offset. The center widget is
/// displayed in the viewport according to the [anchor] property.
///
/// Slivers that are earlier in the child list than [center] are displayed in
/// reverse order in the reverse [axisDirection] starting from the [center]. For
/// example, if the [axisDirection] is [AxisDirection.down], the first sliver
/// before [center] is placed above the [center]. The slivers that are later in
/// the child list than [center] are placed in order in the [axisDirection]. For
/// example, in the preceding scenario, the first sliver after [center] is
/// placed below the [center].
///
/// [Viewport] cannot contain box children directly. Instead, use a
/// [SliverList], [SliverFixedExtentList], [SliverGrid], or a
/// [SliverToBoxAdapter], for example.
///
/// See also:
///
///  * [ListView], [PageView], [GridView], and [CustomScrollView], which combine
///    [Scrollable] and [Viewport] into widgets that are easier to use.
///  * [SliverToBoxAdapter], which allows a box widget to be placed inside a
///    sliver context (the opposite of this widget).
///  * [ShrinkWrappingViewport], a variant of [Viewport] that shrink-wraps its
///    contents along the main axis.
///  * [ViewportElementMixin], which should be mixed in to the [Element] type used
///    by viewport-like widgets to correctly handle scroll notifications.
public final class Viewport: MultiChildRenderObjectWidget {
    /// Creates a widget that is bigger on the inside.
    ///
    /// The viewport listens to the [offset], which means you do not need to
    /// rebuild this widget when the [offset] changes.
    ///
    /// The [cacheExtent] must be specified if the [cacheExtentStyle] is
    /// not [CacheExtentStyle.pixel].
    public init(
        key: (any Key)? = nil,
        axisDirection: AxisDirection = .down,
        crossAxisDirection: AxisDirection? = nil,
        anchor: Float = 0.0,
        offset: ViewportOffset,
        center: (any Key)? = nil,
        cacheExtent: Float? = nil,
        cacheExtentStyle: CacheExtentStyle = .pixel,
        clipBehavior: Clip = .hardEdge,
        slivers: [Widget] = []
    ) {
        precondition(
            center == nil || slivers.filter { $0.key?.isEqualTo(center) == true }.count == 1
        )
        precondition(cacheExtentStyle != .viewport || cacheExtent != nil)
        self.axisDirection = axisDirection
        self.crossAxisDirection = crossAxisDirection
        self.anchor = anchor
        self.offset = offset
        self.center = center
        self.cacheExtent = cacheExtent
        self.cacheExtentStyle = cacheExtentStyle
        self.clipBehavior = clipBehavior
        self.children = slivers
    }

    public let children: [Widget]

    /// The direction in which the [offset]'s [ViewportOffset.pixels] increases.
    ///
    /// For example, if the [axisDirection] is [AxisDirection.down], a scroll
    /// offset of zero is at the top of the viewport and increases towards the
    /// bottom of the viewport.
    public let axisDirection: AxisDirection

    /// The direction in which child should be laid out in the cross axis.
    ///
    /// If the [axisDirection] is [AxisDirection.down] or [AxisDirection.up], this
    /// property defaults to [AxisDirection.left] if the ambient [Directionality]
    /// is [TextDirection.rtl] and [AxisDirection.right] if the ambient
    /// [Directionality] is [TextDirection.ltr].
    ///
    /// If the [axisDirection] is [AxisDirection.left] or [AxisDirection.right],
    /// this property defaults to [AxisDirection.down].
    public let crossAxisDirection: AxisDirection?

    /// The relative position of the zero scroll offset.
    ///
    /// For example, if [anchor] is 0.5 and the [axisDirection] is
    /// [AxisDirection.down] or [AxisDirection.up], then the zero scroll offset is
    /// vertically centered within the viewport. If the [anchor] is 1.0, and the
    /// [axisDirection] is [AxisDirection.right], then the zero scroll offset is
    /// on the left edge of the viewport.
    ///
    public let anchor: Float

    /// Which part of the content inside the viewport should be visible.
    ///
    /// The [ViewportOffset.pixels] value determines the scroll offset that the
    /// viewport uses to select which part of its content to display. As the user
    /// scrolls the viewport, this value changes, which changes the content that
    /// is displayed.
    ///
    /// Typically a [ScrollPosition].
    public let offset: ViewportOffset

    /// The first child in the [GrowthDirection.forward] growth direction.
    ///
    /// Children after [center] will be placed in the [axisDirection] relative to
    /// the [center]. Children before [center] will be placed in the opposite of
    /// the [axisDirection] relative to the [center].
    ///
    /// The [center] must be the key of a child of the viewport.
    ///
    public let center: (any Key)?

    ///
    /// See also:
    ///
    ///  * [cacheExtentStyle], which controls the units of the [cacheExtent].
    public let cacheExtent: Float?

    public let cacheExtentStyle: CacheExtentStyle

    /// Defaults to [Clip.hardEdge].
    public let clipBehavior: Clip

    /// Given a [BuildContext] and an [AxisDirection], determine the correct cross
    /// axis direction.
    ///
    /// This depends on the [Directionality] if the `axisDirection` is vertical;
    /// otherwise, the default cross axis direction is downwards.
    static func getDefaultCrossAxisDirection(
        _ context: BuildContext,
        _ axisDirection: AxisDirection
    ) -> AxisDirection {
        switch axisDirection {
        case .up:
            // assert(
            //     debugCheckHasDirectionality(
            //         context,
            //         why:
            //             "to determine the cross-axis direction when the viewport has an 'up' axisDirection",
            //         alternative:
            //             "Alternatively, consider specifying the 'crossAxisDirection' argument on the Viewport."
            //     )
            // )
            // return textDirectionToAxisDirection(Directionality.of(context))
            return .right
        case .right:
            return .down
        case .down:
            // assert(
            //     debugCheckHasDirectionality(
            //         context,
            //         why:
            //             "to determine the cross-axis direction when the viewport has a 'down' axisDirection",
            //         alternative:
            //             "Alternatively, consider specifying the 'crossAxisDirection' argument on the Viewport."
            //     )
            // )
            // return textDirectionToAxisDirection(Directionality.of(context))
            return .right
        case .left:
            return .down
        }
    }

    public func createRenderObject(context: BuildContext) -> RenderViewport {
        return RenderViewport(
            axisDirection: axisDirection,
            crossAxisDirection: crossAxisDirection
                ?? Viewport.getDefaultCrossAxisDirection(context, axisDirection),
            offset: offset,
            anchor: anchor,
            cacheExtent: cacheExtent,
            cacheExtentStyle: cacheExtentStyle,
            clipBehavior: clipBehavior
        )
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderViewport) {
        renderObject.axisDirection = axisDirection
        renderObject.crossAxisDirection =
            crossAxisDirection ?? Viewport.getDefaultCrossAxisDirection(context, axisDirection)
        renderObject.anchor = anchor
        renderObject.offset = offset
        renderObject.cacheExtent = cacheExtent
        renderObject.cacheExtentStyle = cacheExtentStyle
        renderObject.clipBehavior = clipBehavior
    }

    public func createElement() -> Element {
        return _ViewportElement(self)
    }
}

private class _ViewportElement: MultiChildRenderObjectElement  // , NotifiableElementMixin, ViewportElementMixin
{
    /// Creates an element that uses the given widget as its configuration.
    init(_ widget: Viewport) {
        super.init(widget)
    }

    private var _doingMountOrUpdate = false
    private var _centerSlotIndex: Int?

    override var renderObject: RenderViewport {
        return super.renderObject as! RenderViewport
    }

    override func mount(_ parent: Element?, slot newSlot: (any Slot)? = nil) {
        assert(!_doingMountOrUpdate)
        _doingMountOrUpdate = true
        super.mount(parent, slot: newSlot)
        _updateCenter()
        assert(_doingMountOrUpdate)
        _doingMountOrUpdate = false
    }

    override func update(_ newWidget: Widget) {
        assert(!_doingMountOrUpdate)
        _doingMountOrUpdate = true
        super.update(newWidget)
        _updateCenter()
        assert(_doingMountOrUpdate)
        _doingMountOrUpdate = false
    }

    private func _updateCenter() {
        // TODO(ianh): cache the keys to make this faster
        let viewport = widget as! Viewport
        if viewport.center != nil {
            var elementIndex = 0
            for e in children {
                if e.widget.key?.isEqualTo(viewport.center) != false {
                    renderObject.center = e.renderObject as? RenderSliver
                    break
                }
                elementIndex += 1
            }
            assert(elementIndex < children.count)
            _centerSlotIndex = elementIndex
        } else if !children.isEmpty {
            renderObject.center = children.first?.renderObject as? RenderSliver
            _centerSlotIndex = 0
        } else {
            renderObject.center = nil
            _centerSlotIndex = nil
        }
    }

    override func insertRenderObjectChild(_ child: RenderObject, slot: (any Slot)?) {
        super.insertRenderObjectChild(child, slot: slot)
        let slot = slot as! IndexedSlot
        // Once [mount]/[update] are done, the `renderObject.center` will be updated
        // in [_updateCenter].
        if !_doingMountOrUpdate && slot.index == _centerSlotIndex {
            renderObject.center = child as? RenderSliver
        }
    }

    override func moveRenderObjectChild(_ child: RenderObject, oldSlot: Slot?, newSlot: Slot?) {
        super.moveRenderObjectChild(child, oldSlot: oldSlot, newSlot: newSlot)
        assert(_doingMountOrUpdate)
    }

    override func removeRenderObjectChild(_ child: RenderObject, slot: Slot?) {
        super.removeRenderObjectChild(child, slot: slot)
        if !_doingMountOrUpdate && renderObject.center === child {
            renderObject.center = nil
        }
    }

    func debugVisitOnstageChildren(_ visitor: ElementVisitor) {
        children.filter { e in
            let renderSliver = e.renderObject as! RenderSliver
            return renderSliver.geometry!.visible
        }.forEach(visitor)
    }
}

/// A widget that is bigger on the inside and shrink wraps its children in the
/// main axis.
///
/// [ShrinkWrappingViewport] displays a subset of its children according to its
/// own dimensions and the given [offset]. As the offset varies, different
/// children are visible through the viewport.
///
/// [ShrinkWrappingViewport] differs from [Viewport] in that [Viewport] expands
/// to fill the main axis whereas [ShrinkWrappingViewport] sizes itself to match
/// its children in the main axis. This shrink wrapping behavior is expensive
/// because the children, and hence the viewport, could potentially change size
/// whenever the [offset] changes (e.g., because of a collapsing header).
///
/// [ShrinkWrappingViewport] cannot contain box children directly. Instead, use
/// a [SliverList], [SliverFixedExtentList], [SliverGrid], or a
/// [SliverToBoxAdapter], for example.
///
/// See also:
///
///  * [ListView], [PageView], [GridView], and [CustomScrollView], which combine
///    [Scrollable] and [ShrinkWrappingViewport] into widgets that are easier to
///    use.
///  * [SliverToBoxAdapter], which allows a box widget to be placed inside a
///    sliver context (the opposite of this widget).
///  * [Viewport], a viewport that does not shrink-wrap its contents.
public final class ShrinkWrappingViewport: MultiChildRenderObjectWidget {
    /// Creates a widget that is bigger on the inside and shrink wraps its
    /// children in the main axis.
    ///
    /// The viewport listens to the [offset], which means you do not need to
    /// rebuild this widget when the [offset] changes.
    public init(
        key: (any Key)? = nil,
        axisDirection: AxisDirection = .down,
        crossAxisDirection: AxisDirection? = nil,
        offset: ViewportOffset,
        clipBehavior: Clip = .hardEdge,
        slivers: [Widget] = []
    ) {
        self.axisDirection = axisDirection
        self.crossAxisDirection = crossAxisDirection
        self.offset = offset
        self.clipBehavior = clipBehavior
        self.children = slivers
    }

    public let children: [Widget]

    /// The direction in which the [offset]'s [ViewportOffset.pixels] increases.
    ///
    /// For example, if the [axisDirection] is [AxisDirection.down], a scroll
    /// offset of zero is at the top of the viewport and increases towards the
    /// bottom of the viewport.
    public let axisDirection: AxisDirection

    /// The direction in which child should be laid out in the cross axis.
    ///
    /// If the [axisDirection] is [AxisDirection.down] or [AxisDirection.up], this
    /// property defaults to [AxisDirection.left] if the ambient [Directionality]
    /// is [TextDirection.rtl] and [AxisDirection.right] if the ambient
    /// [Directionality] is [TextDirection.ltr].
    ///
    /// If the [axisDirection] is [AxisDirection.left] or [AxisDirection.right],
    /// this property defaults to [AxisDirection.down].
    public let crossAxisDirection: AxisDirection?

    /// Which part of the content inside the viewport should be visible.
    ///
    /// The [ViewportOffset.pixels] value determines the scroll offset that the
    /// viewport uses to select which part of its content to display. As the user
    /// scrolls the viewport, this value changes, which changes the content that
    /// is displayed.
    ///
    /// Typically a [ScrollPosition].
    public let offset: ViewportOffset

    ///
    /// Defaults to [Clip.hardEdge].
    public let clipBehavior: Clip

    public func createRenderObject(context: BuildContext) -> RenderShrinkWrappingViewport {
        return RenderShrinkWrappingViewport(
            axisDirection: axisDirection,
            crossAxisDirection: crossAxisDirection
                ?? Viewport.getDefaultCrossAxisDirection(context, axisDirection),
            offset: offset,
            clipBehavior: clipBehavior
        )
    }

    public func updateRenderObject(
        context: BuildContext,
        renderObject: RenderShrinkWrappingViewport
    ) {
        renderObject.axisDirection = axisDirection
        renderObject.crossAxisDirection =
            crossAxisDirection ?? Viewport.getDefaultCrossAxisDirection(context, axisDirection)
        renderObject.offset = offset
        renderObject.clipBehavior = clipBehavior
    }
}
