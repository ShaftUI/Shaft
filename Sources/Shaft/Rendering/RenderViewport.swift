import SwiftMath

/// The unit of measurement for a [Viewport.cacheExtent].
public enum CacheExtentStyle {
    /// Treat the [Viewport.cacheExtent] as logical pixels.
    case pixel
    /// Treat the [Viewport.cacheExtent] as a multiplier of the main axis extent.
    case viewport
}

/// An interface for render objects that are bigger on the inside.
///
/// Some render objects, such as [RenderViewport], present a portion of their
/// content, which can be controlled by a [ViewportOffset]. This interface lets
/// the framework recognize such render objects and interact with them without
/// having specific knowledge of all the various types of viewports.
public protocol RenderAbstractViewport: RenderObject {
    /// Returns the offset that would be needed to reveal the `target`
    /// [RenderObject].
    ///
    /// This is used by [RenderViewportBase.showInViewport], which is
    /// itself used by [RenderObject.showOnScreen] for
    /// [RenderViewportBase], which is in turn used by the semantics
    /// system to implement scrolling for accessibility tools.
    ///
    /// The optional `rect` parameter describes which area of that `target` object
    /// should be revealed in the viewport. If `rect` is null, the entire
    /// `target` [RenderObject] (as defined by its [RenderObject.paintBounds])
    /// will be revealed. If `rect` is provided it has to be given in the
    /// coordinate system of the `target` object.
    ///
    /// The `alignment` argument describes where the target should be positioned
    /// after applying the returned offset. If `alignment` is 0.0, the child must
    /// be positioned as close to the leading edge of the viewport as possible. If
    /// `alignment` is 1.0, the child must be positioned as close to the trailing
    /// edge of the viewport as possible. If `alignment` is 0.5, the child must be
    /// positioned as close to the center of the viewport as possible.
    ///
    /// The `target` might not be a direct child of this viewport but it must be a
    /// descendant of the viewport. Other viewports in between this viewport and
    /// the `target` will not be adjusted.
    ///
    /// This method assumes that the content of the viewport moves linearly, i.e.
    /// when the offset of the viewport is changed by x then `target` also moves
    /// by x within the viewport.
    ///
    /// The optional [Axis] is used by
    /// [RenderTwoDimensionalViewport.getOffsetToReveal] to
    /// determine which of the two axes to compute an offset for. One dimensional
    /// subclasses like [RenderViewportBase] and [RenderListWheelViewport]
    /// will ignore the `axis` value if provided, since there is only one [Axis].
    ///
    /// If the `axis` is omitted when called on [RenderTwoDimensionalViewport],
    /// the [RenderTwoDimensionalViewport.mainAxis] is used. To reveal an object
    /// properly in both axes, this method should be called for each [Axis] as the
    /// returned [RevealedOffset.offset] only represents the offset of one of the
    /// the two [ScrollPosition]s.
    ///
    /// See also:
    ///
    ///  * [RevealedOffset], which describes the return value of this method.
    func getOffsetToReveal(
        target: RenderObject,
        alignment: Float,
        rect: Rect?,
        axis: Axis?
    ) -> RevealedOffset
}

/// Return value for [RenderAbstractViewport.getOffsetToReveal].
extension RenderAbstractViewport {
    /// Returns the [RenderAbstractViewport] that most tightly encloses the given
    /// render object.
    ///
    /// If the object does not have a [RenderAbstractViewport] as an ancestor,
    /// this function returns null.
    ///
    /// See also:
    ///
    /// * [RenderAbstractViewport.of], which is similar to this method, but
    ///   asserts if no [RenderAbstractViewport] ancestor is found.
    static func maybeOf(_ object: RenderObject?) -> RenderAbstractViewport? {
        var current = object
        while current != nil {
            if let viewport = current as? RenderAbstractViewport {
                return viewport
            }
            current = current?.parent
        }
        return nil
    }

    /// Returns the [RenderAbstractViewport] that most tightly encloses the given
    /// render object.
    ///
    /// If the object does not have a [RenderAbstractViewport] as an ancestor,
    /// this function will assert in debug mode, and throw an exception in release
    /// mode.
    ///
    /// See also:
    ///
    /// * [RenderAbstractViewport.maybeOf], which is similar to this method, but
    ///   returns null if no [RenderAbstractViewport] ancestor is found.
    static func of(_ object: RenderObject?) -> RenderAbstractViewport {
        let viewport = maybeOf(object)
        assert(
            {
                if viewport == nil {
                    preconditionFailure(
                        """
                        RenderAbstractViewport.of() was called with a render object that was
                        not a descendant of a RenderAbstractViewport.
                        No RenderAbstractViewport render object ancestor could be found starting
                        from the object that was passed to RenderAbstractViewport.of().
                        The render object where the viewport search started was:
                          \(String(describing: object))
                        """
                    )
                }
                return true
            }()
        )
        return viewport!
    }
}

/// The default value for the cache extent of the viewport.
///
/// This default assumes [CacheExtentStyle.pixel].
///
/// See also:
///
///  * [RenderViewportBase.cacheExtent] for a definition of the cache extent.
private let defaultCacheExtent: Float = 250.0

/// Return value for [RenderAbstractViewport.getOffsetToReveal].
///
/// It indicates the [offset] required to reveal an element in a viewport and
/// the [rect] position said element would have in the viewport at that
/// [offset].
public struct RevealedOffset {
    /// Instantiates a return value for [RenderAbstractViewport.getOffsetToReveal].
    public init(offset: Float, rect: Rect) {
        self.offset = offset
        self.rect = rect
    }

    /// Offset for the viewport to reveal a specific element in the viewport.
    ///
    /// See also:
    ///
    ///  * [RenderAbstractViewport.getOffsetToReveal], which calculates this
    ///    value for a specific element.
    public let offset: Float

    /// The [Rect] in the outer coordinate system of the viewport at which the
    /// to-be-revealed element would be located if the viewport's offset is set
    /// to [offset].
    ///
    /// A viewport usually has two coordinate systems and works as an adapter
    /// between the two:
    ///
    /// The inner coordinate system has its origin at the top left corner of the
    /// content that moves inside the viewport. The origin of this coordinate
    /// system usually moves around relative to the leading edge of the viewport
    /// when the viewport offset changes.
    ///
    /// The outer coordinate system has its origin at the top left corner of the
    /// visible part of the viewport. This origin stays at the same position
    /// regardless of the current viewport offset.
    ///
    /// In other words: [rect] describes where the revealed element would be
    /// located relative to the top left corner of the visible part of the
    /// viewport if the viewport's offset is set to [offset].
    ///
    /// See also:
    ///
    ///  * [RenderAbstractViewport.getOffsetToReveal], which calculates this
    ///    value for a specific element.
    public let rect: Rect

    /// Determines which provided leading or trailing edge of the viewport, as
    /// [RevealedOffset]s, will be used for [RenderViewportBase.showInViewport]
    /// accounting for the size and already visible portion of the [RenderObject]
    /// that is being revealed.
    ///
    /// Also used by [RenderTwoDimensionalViewport.showInViewport] for each
    /// horizontal and vertical [Axis].
    ///
    /// If the target [RenderObject] is already fully visible, this will return
    /// null.

    public static func clampOffset(
        leadingEdgeOffset: RevealedOffset,
        trailingEdgeOffset: RevealedOffset,
        currentOffset: Float
    ) -> RevealedOffset? {
        //           scrollOffset
        //                       0 +---------+
        //                         |         |
        //                       _ |         |
        //    viewport position |  |         |
        // with `descendant` at |  |         | _
        //        trailing edge |_ | xxxxxxx |  | viewport position
        //                         |         |  | with `descendant` at
        //                         |         | _| leading edge
        //                         |         |
        //                     800 +---------+
        //
        // `trailingEdgeOffset`: Distance from scrollOffset 0 to the start of the
        //                       viewport on the left in image above.
        // `leadingEdgeOffset`: Distance from scrollOffset 0 to the start of the
        //                      viewport on the right in image above.
        //
        // The viewport position on the left is achieved by setting `offset.pixels`
        // to `trailingEdgeOffset`, the one on the right by setting it to
        // `leadingEdgeOffset`.
        let inverted = leadingEdgeOffset.offset < trailingEdgeOffset.offset
        let (smaller, larger) =
            inverted
            ? (leadingEdgeOffset, trailingEdgeOffset)
            : (trailingEdgeOffset, leadingEdgeOffset)

        if currentOffset > larger.offset {
            return larger
        } else if currentOffset < smaller.offset {
            return smaller
        } else {
            return nil
        }
    }
}

/// A base class for render objects that are bigger on the inside.
///
/// This render object provides the shared code for render objects that host
/// [RenderSliver] render objects inside a [RenderBox]. The viewport establishes
/// an [axisDirection], which orients the sliver's coordinate system, which is
/// based on scroll offsets rather than Cartesian coordinates.
///
/// The viewport also listens to an [offset], which determines the
/// [SliverConstraints.scrollOffset] input to the sliver layout protocol.
///
/// Subclasses typically override [performLayout] and call
/// [layoutChildSequence], perhaps multiple times.
///
/// See also:
///
///  * [RenderSliver], which explains more about the Sliver protocol.
///  * [RenderBox], which explains more about the Box protocol.
///  * [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
///    placed inside a [RenderSliver] (the opposite of this class).
public class RenderViewportBase<ParentDataType: SliverContainerParentData>: RenderBox,
    RenderObjectWithChildren, RenderAbstractViewport
{

    /// Initializes fields for subclasses.
    ///
    /// The [cacheExtent], if null, defaults to [defaultCacheExtent].
    ///
    /// The [cacheExtent] must be specified if [cacheExtentStyle] is not [CacheExtentStyle.pixel].
    public init(
        axisDirection: AxisDirection = .down,
        crossAxisDirection: AxisDirection,
        offset: ViewportOffset,
        cacheExtent: Float? = nil,
        cacheExtentStyle: CacheExtentStyle = .pixel,
        clipBehavior: Clip = .hardEdge
    ) {
        precondition(axisDirection.axis != crossAxisDirection.axis)
        precondition(cacheExtent != nil || cacheExtentStyle == .pixel)

        self.axisDirection = axisDirection
        self.crossAxisDirection = crossAxisDirection
        self.offset = offset
        self.cacheExtent = cacheExtent ?? defaultCacheExtent
        self.cacheExtentStyle = cacheExtentStyle
        self.clipBehavior = clipBehavior

        super.init()
    }

    public typealias ChildType = RenderSliver
    public var childMixin = RenderContainerMixin<RenderSliver>()

    /// The direction in which the [SliverConstraints.scrollOffset] increases.
    ///
    /// For example, if the [axisDirection] is [AxisDirection.down], a scroll
    /// offset of zero is at the top of the viewport and increases towards the
    /// bottom of the viewport.
    public var axisDirection: AxisDirection {
        didSet {
            if axisDirection != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// The direction in which child should be laid out in the cross axis.
    ///
    /// For example, if the [axisDirection] is [AxisDirection.down], this property
    /// is typically [AxisDirection.left] if the ambient [TextDirection] is
    /// [TextDirection.rtl] and [AxisDirection.right] if the ambient
    /// [TextDirection] is [TextDirection.ltr].
    public var crossAxisDirection: AxisDirection {
        didSet {
            if crossAxisDirection != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// The axis along which the viewport scrolls.
    ///
    /// For example, if the [axisDirection] is [AxisDirection.down], then the
    /// [axis] is [Axis.vertical] and the viewport scrolls vertically.
    public var axis: Axis {
        axisDirection.axis
    }

    /// Which part of the content inside the viewport should be visible.
    ///
    /// The [ViewportOffset.pixels] value determines the scroll offset that the
    /// viewport uses to select which part of its content to display. As the user
    /// scrolls the viewport, this value changes, which changes the content that
    /// is displayed.
    public var offset: ViewportOffset {
        didSet {
            if offset === oldValue {
                return
            }
            if attached {
                oldValue.removeListener(self)
            }
            offset.addListener(self, callback: markNeedsLayout)
            // We need to go through layout even if the new offset has the same pixels
            // value as the old offset so that we will apply our viewport and content
            // dimensions.
            markNeedsLayout()
        }
    }

    // TODO(ianh): cacheExtent/cacheExtentStyle should be a single
    // object that specifies both the scalar value and the unit, not a
    // pair of independent setters. Changing that would allow a more
    // rational API and would let us make the getter non-nullable.

    /// The viewport has an area before and after the visible area to cache items
    /// that are about to become visible when the user scrolls.
    ///
    /// Items that fall in this cache area are laid out even though they are not
    /// (yet) visible on screen. The [cacheExtent] describes how many pixels
    /// the cache area extends before the leading edge and after the trailing edge
    /// of the viewport.
    ///
    /// The total extent, which the viewport will try to cover with children, is
    /// [cacheExtent] before the leading edge + extent of the main axis +
    /// [cacheExtent] after the trailing edge.
    ///
    /// The cache area is also used to implement implicit accessibility scrolling
    /// on iOS: When the accessibility focus moves from an item in the visible
    /// viewport to an invisible item in the cache area, the framework will bring
    /// that item into view with an (implicit) scroll action.
    ///
    /// The getter can never return null, but the field is nullable
    /// because the setter can be set to null to reset the value to
    /// [RenderAbstractViewport.defaultCacheExtent] (in which case
    /// [cacheExtentStyle] must be [CacheExtentStyle.pixel]).
    ///
    /// See also:
    ///
    ///  * [cacheExtentStyle], which controls the units of the [cacheExtent].
    public var cacheExtent: Float? {
        didSet {
            if cacheExtent != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// This value is set during layout based on the [CacheExtentStyle].
    ///
    /// When the style is [CacheExtentStyle.viewport], it is the main axis extent
    /// of the viewport multiplied by the requested cache extent, which is still
    /// expressed in pixels.
    internal var calculatedCacheExtent: Float?

    /// Controls how the [cacheExtent] is interpreted.
    ///
    /// If set to [CacheExtentStyle.pixel], the [cacheExtent] will be
    /// treated as a logical pixels, and the default [cacheExtent] is
    /// [RenderAbstractViewport.defaultCacheExtent].
    ///
    /// If set to [CacheExtentStyle.viewport], the [cacheExtent] will be
    /// treated as a multiplier for the main axis extent of the
    /// viewport. In this case there is no default [cacheExtent]; it
    /// must be explicitly specified.
    ///
    /// Changing the [cacheExtentStyle] without also changing the [cacheExtent]
    /// is rarely the correct choice.
    public var cacheExtentStyle: CacheExtentStyle {
        didSet {
            if cacheExtentStyle != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// Defaults to [Clip.hardEdge].
    public var clipBehavior: Clip {
        didSet {
            if clipBehavior != oldValue {
                markNeedsPaint()
                // markNeedsSemanticsUpdate()
            }
        }
    }

    public override func attach(_ owner: RenderOwner) {
        super.attach(owner)
        offset.addListener(self, callback: markNeedsLayout)
    }

    public override func detach() {
        offset.removeListener(self)
        super.detach()
    }

    //   /// Throws an exception saying that the object does not support returning
    //   /// intrinsic dimensions if, in debug mode, we are not in the
    //   /// [RenderObject.debugCheckingIntrinsics] mode.
    //   ///
    //   /// This is used by [computeMinIntrinsicWidth] et al because viewports do not
    //   /// generally support returning intrinsic dimensions. See the discussion at
    //   /// [computeMinIntrinsicWidth].
    //   @protected
    //   bool debugThrowIfNotCheckingIntrinsics() {
    //     assert(() {
    //       if (!RenderObject.debugCheckingIntrinsics) {
    //         assert(this is! RenderShrinkWrappingViewport); // it has its own message
    //         throw FlutterError.fromParts(<DiagnosticsNode>[
    //           ErrorSummary('$runtimeType does not support returning intrinsic dimensions.'),
    //           ErrorDescription(
    //             'Calculating the intrinsic dimensions would require instantiating every child of '
    //             'the viewport, which defeats the point of viewports being lazy.',
    //           ),
    //           ErrorHint(
    //             'If you are merely trying to shrink-wrap the viewport in the main axis direction, '
    //             'consider a RenderShrinkWrappingViewport render object (ShrinkWrappingViewport widget), '
    //             'which achieves that effect without implementing the intrinsic dimension API.',
    //           ),
    //         ]);
    //       }
    //       return true;
    //     }());
    //     return true;
    //   }

    public override func computeMinIntrinsicWidth(_ height: Float) -> Float {
        // assert(debugThrowIfNotCheckingIntrinsics());
        0.0
    }

    public override func computeMaxIntrinsicWidth(_ height: Float) -> Float {
        // assert(debugThrowIfNotCheckingIntrinsics());
        0.0
    }

    public override func computeMinIntrinsicHeight(_ width: Float) -> Float {
        // assert(debugThrowIfNotCheckingIntrinsics());
        0.0
    }

    public override func computeMaxIntrinsicHeight(_ width: Float) -> Float {
        // assert(debugThrowIfNotCheckingIntrinsics());
        0.0
    }

    public override var isRepaintBoundary: Bool {
        true
    }

    /// Determines the size and position of some of the children of the viewport.
    ///
    /// This function is the workhorse of `performLayout` implementations in
    /// subclasses.
    ///
    /// Layout starts with `child`, proceeds according to the `advance` callback,
    /// and stops once `advance` returns null.
    ///
    ///  * `scrollOffset` is the [SliverConstraints.scrollOffset] to pass the
    ///    first child. The scroll offset is adjusted by
    ///    [SliverGeometry.scrollExtent] for subsequent children.
    ///  * `overlap` is the [SliverConstraints.overlap] to pass the first child.
    ///    The overlay is adjusted by the [SliverGeometry.paintOrigin] and
    ///    [SliverGeometry.paintExtent] for subsequent children.
    ///  * `layoutOffset` is the layout offset at which to place the first child.
    ///    The layout offset is updated by the [SliverGeometry.layoutExtent] for
    ///    subsequent children.
    ///  * `remainingPaintExtent` is [SliverConstraints.remainingPaintExtent] to
    ///    pass the first child. The remaining paint extent is updated by the
    ///    [SliverGeometry.layoutExtent] for subsequent children.
    ///  * `mainAxisExtent` is the [SliverConstraints.viewportMainAxisExtent] to
    ///    pass to each child.
    ///  * `crossAxisExtent` is the [SliverConstraints.crossAxisExtent] to pass to
    ///    each child.
    ///  * `growthDirection` is the [SliverConstraints.growthDirection] to pass to
    ///    each child.
    ///
    /// Returns the first non-zero [SliverGeometry.scrollOffsetCorrection]
    /// encountered, if any. Otherwise returns 0.0. Typical callers will call this
    /// function repeatedly until it returns 0.0.
    internal func layoutChildSequence(
        child: RenderSliver?,
        scrollOffset: Float,
        overlap: Float,
        layoutOffset: Float,
        remainingPaintExtent: Float,
        mainAxisExtent: Float,
        crossAxisExtent: Float,
        growthDirection: GrowthDirection,
        advance: (RenderSliver) -> RenderSliver?,
        remainingCacheExtent: Float,
        cacheOrigin: Float
    ) -> Float {
        assert(scrollOffset.isFinite)
        assert(scrollOffset >= 0.0)
        let initialLayoutOffset = layoutOffset
        let adjustedUserScrollDirection =
            applyGrowthDirectionToScrollDirection(offset.userScrollDirection, growthDirection)
        var maxPaintOffset = layoutOffset + overlap
        var precedingScrollExtent: Float = 0.0
        var scrollOffset = scrollOffset
        var layoutOffset = layoutOffset
        var cacheOrigin = cacheOrigin
        var remainingCacheExtent = remainingCacheExtent

        var currentChild = child
        while currentChild != nil {
            let sliverScrollOffset = scrollOffset <= 0.0 ? 0.0 : scrollOffset
            // If the scrollOffset is too small we adjust the paddedOrigin because it
            // doesn't make sense to ask a sliver for content before its scroll
            // offset.
            let correctedCacheOrigin = max(cacheOrigin, -sliverScrollOffset)
            let cacheExtentCorrection = cacheOrigin - correctedCacheOrigin

            assert(sliverScrollOffset >= abs(correctedCacheOrigin))
            assert(correctedCacheOrigin <= 0.0)
            assert(sliverScrollOffset >= 0.0)
            assert(cacheExtentCorrection <= 0.0)

            currentChild!.layout(
                SliverConstraints(
                    axisDirection: axisDirection,
                    growthDirection: growthDirection,
                    userScrollDirection: adjustedUserScrollDirection,
                    scrollOffset: sliverScrollOffset,
                    precedingScrollExtent: precedingScrollExtent,
                    overlap: maxPaintOffset - layoutOffset,
                    remainingPaintExtent: max(
                        0.0,
                        remainingPaintExtent - layoutOffset + initialLayoutOffset
                    ),
                    crossAxisExtent: crossAxisExtent,
                    crossAxisDirection: crossAxisDirection,
                    viewportMainAxisExtent: mainAxisExtent,
                    remainingCacheExtent: max(0.0, remainingCacheExtent + cacheExtentCorrection),
                    cacheOrigin: correctedCacheOrigin
                ),
                parentUsesSize: true
            )

            let childLayoutGeometry = currentChild!.geometry!
            assert(childLayoutGeometry.debugAssertIsValid())

            // If there is a correction to apply, we'll have to start over.
            if let correction = childLayoutGeometry.scrollOffsetCorrection {
                return correction
            }

            // We use the child's paint origin in our coordinate system as the
            // layoutOffset we store in the child's parent data.
            let effectiveLayoutOffset = layoutOffset + childLayoutGeometry.paintOrigin

            // `effectiveLayoutOffset` becomes meaningless once we moved past the trailing edge
            // because `childLayoutGeometry.layoutExtent` is zero. Using the still increasing
            // 'scrollOffset` to roughly position these invisible slivers in the right order.
            if childLayoutGeometry.visible || scrollOffset > 0 {
                updateChildLayoutOffset(currentChild!, effectiveLayoutOffset, growthDirection)
            } else {
                updateChildLayoutOffset(
                    currentChild!,
                    -scrollOffset + initialLayoutOffset,
                    growthDirection
                )
            }

            maxPaintOffset = max(
                effectiveLayoutOffset + childLayoutGeometry.paintExtent,
                maxPaintOffset
            )
            scrollOffset -= childLayoutGeometry.scrollExtent
            precedingScrollExtent += childLayoutGeometry.scrollExtent
            layoutOffset += childLayoutGeometry.layoutExtent
            if childLayoutGeometry.cacheExtent != 0.0 {
                remainingCacheExtent -= childLayoutGeometry.cacheExtent - cacheExtentCorrection
                cacheOrigin = min(correctedCacheOrigin + childLayoutGeometry.cacheExtent, 0.0)
            }

            updateOutOfBandData(growthDirection, childLayoutGeometry)

            // move on to the next child
            currentChild = advance(currentChild!)
        }

        // we made it without a correction, whee!
        return 0.0
    }

    func describeApproximatePaintClip(_ child: RenderSliver) -> Rect? {
        switch clipBehavior {
        case .none:
            return nil
        case .hardEdge, .antiAlias, .antiAliasWithSaveLayer:
            break
        }

        let viewportClip = Offset.zero & size
        // The child's viewportMainAxisExtent can be infinite when a
        // RenderShrinkWrappingViewport is given infinite constraints, such as when
        // it is the child of a Row or Column (depending on orientation).
        //
        // For example, a shrink wrapping render sliver may have infinite
        // constraints along the viewport's main axis but may also have bouncing
        // scroll physics, which will allow for some scrolling effect to occur.
        // We should just use the viewportClip - the start of the overlap is at
        // double.infinity and so it is effectively meaningless.
        if child.sliverConstraints.overlap == 0
            || !child.sliverConstraints.viewportMainAxisExtent.isFinite
        {
            return viewportClip
        }

        // Adjust the clip rect for this sliver by the overlap from the previous sliver.
        var left = viewportClip.left
        var right = viewportClip.right
        var top = viewportClip.top
        var bottom = viewportClip.bottom
        let startOfOverlap =
            child.sliverConstraints.viewportMainAxisExtent
            - child.sliverConstraints.remainingPaintExtent
        let overlapCorrection = startOfOverlap + child.sliverConstraints.overlap
        switch applyGrowthDirectionToAxisDirection(
            axisDirection,
            child.sliverConstraints.growthDirection
        )
        {
        case .down:
            top += overlapCorrection
        case .up:
            bottom -= overlapCorrection
        case .right:
            left += overlapCorrection
        case .left:
            right -= overlapCorrection
        }

        return Rect(left: left, top: top, right: right, bottom: bottom)
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        if firstChild == nil {
            return
        }
        if hasVisualOverflow && clipBehavior != .none {
            clipRectLayer = context.pushClipRect(
                needsCompositing: needsCompositing,
                offset: offset,
                clipRect: Offset.zero & size,
                clipBehavior: clipBehavior,
                painter: paintContents,
                oldLayer: clipRectLayer
            )
        } else {
            clipRectLayer = nil
            paintContents(context, offset)
        }
    }
    private var clipRectLayer: ClipRectLayer?

    public override func dispose() {
        clipRectLayer = nil
        super.dispose()
    }

    private func paintContents(_ context: PaintingContext, _ offset: Offset) {
        for child in childrenInPaintOrder {
            if child.geometry!.visible {
                context.paintChild(child, offset: offset + paintOffsetOf(child))
            }
        }
    }

    //   @override
    //   void debugPaintSize(PaintingContext context, Offset offset) {
    //     assert(() {
    //       super.debugPaintSize(context, offset);
    //       final Paint paint = Paint()
    //         ..style = PaintingStyle.stroke
    //         ..strokeWidth = 1.0
    //         ..color = const Color(0xFF00FF00);
    //       final Canvas canvas = context.canvas;
    //       RenderSliver? child = firstChild;
    //       while (child != null) {
    //         final Size size = switch (axis) {
    //           Axis.vertical   => Size(child.constraints.crossAxisExtent, child.geometry!.layoutExtent),
    //           Axis.horizontal => Size(child.geometry!.layoutExtent, child.constraints.crossAxisExtent),
    //         };
    //         canvas.drawRect(((offset + paintOffsetOf(child)) & size).deflate(0.5), paint);
    //         child = childAfter(child);
    //       }
    //       return true;
    //     }());
    //   }

    public override func hitTestChildren(_ result: HitTestResult, position: Offset) -> Bool {
        let result = result as! BoxHitTestResult
        let (mainAxisPosition, crossAxisPosition): (Float, Float) =
            switch axis {
            case .vertical: (position.dy, position.dx)
            case .horizontal: (position.dx, position.dy)
            }
        let sliverResult = SliverHitTestResult(wrap: result)
        for child in childrenInHitTestOrder {
            if !child.geometry!.visible {
                continue
            }
            var transform = Matrix4x4f.identity
            applyPaintTransform(child, transform: &transform)  // must be invertible
            let isHit = result.addWithOutOfBandPosition(
                paintTransform: transform,
                hitTest: { result in
                    return child.hitTest(
                        sliverResult,
                        mainAxisPosition: computeChildMainAxisPosition(child, mainAxisPosition),
                        crossAxisPosition: crossAxisPosition
                    )
                }
            )
            if isHit {
                return true
            }
        }
        return false
    }

    public func getOffsetToReveal(
        target: RenderObject,
        alignment: Float,
        rect: Rect? = nil,
        axis: Axis? = nil
    ) -> RevealedOffset {
        // One dimensional viewport has only one axis, override if it was
        // provided/may be mismatched.
        let axis = self.axis

        // Steps to convert `rect` (from a RenderBox coordinate system) to its
        // scroll offset within this viewport (not in the exact order):
        //
        // 1. Pick the outermost RenderBox (between which, and the viewport, there
        // is nothing but RenderSlivers) as an intermediate reference frame
        // (the `pivot`), convert `rect` to that coordinate space.
        //
        // 2. Convert `rect` from the `pivot` coordinate space to its sliver
        // parent's sliver coordinate system (i.e., to a scroll offset), based on
        // the axis direction and growth direction of the parent.
        //
        // 3. Convert the scroll offset to its sliver parent's coordinate space
        // using `childScrollOffset`, until we reach the viewport.
        //
        // 4. Make the final conversion from the outmost sliver to the viewport
        // using `scrollOffsetOf`.

        var leadingScrollOffset: Float = 0.0
        // Starting at `target` and walking towards the root:
        //  - `child` will be the last object before we reach this viewport, and
        //  - `pivot` will be the last RenderBox before we reach this viewport.
        var child = target
        var pivot: RenderBox?
        var onlySlivers = target is RenderSliver  // ... between viewport and `target` (`target` included).
        while child.parent !== self {
            let parent = child.parent!
            if let boxChild = child as? RenderBox {
                pivot = boxChild
            }
            if let sliverParent = parent as? RenderSliver {
                leadingScrollOffset += sliverParent.childScrollOffset(child)!
            } else {
                onlySlivers = false
                leadingScrollOffset = 0.0
            }
            child = parent
        }

        // `rect` in the new intermediate coordinate system.
        let rectLocal: Rect
        // Our new reference frame render object's main axis extent.
        let pivotExtent: Float
        let growthDirection: GrowthDirection

        // `leadingScrollOffset` is currently the scrollOffset of our new reference
        // frame (`pivot` or `target`), within `child`.
        var rect = rect
        if let pivot = pivot {
            assert(pivot.parent != nil)
            assert(pivot.parent !== self)
            assert(pivot !== self)
            assert(pivot.parent is RenderSliver)  // TODO(abarth): Support other kinds of render objects besides slivers.
            let pivotParent = pivot.parent as! RenderSliver
            growthDirection = pivotParent.sliverConstraints.growthDirection
            pivotExtent =
                switch axis {
                case .horizontal: pivot.size.width
                case .vertical: pivot.size.height
                }
            rect = rect ?? target.paintBounds
            rectLocal = MatrixUtils.transformRect(target.getTransformTo(pivot), rect!)
        } else if onlySlivers {
            // `pivot` does not exist. We'll have to make up one from `target`, the
            // innermost sliver.
            let targetSliver = target as! RenderSliver
            growthDirection = targetSliver.sliverConstraints.growthDirection
            // TODO(LongCatIsLooong): make sure this works if `targetSliver` is a
            // persistent header, when #56413 relands.
            pivotExtent = targetSliver.geometry!.scrollExtent
            if rect == nil {
                switch axis {
                case .horizontal:
                    rect = Rect(
                        left: 0,
                        top: 0,
                        right: targetSliver.geometry!.scrollExtent,
                        bottom: targetSliver.sliverConstraints.crossAxisExtent
                    )
                case .vertical:
                    rect = Rect(
                        left: 0,
                        top: 0,
                        right: targetSliver.sliverConstraints.crossAxisExtent,
                        bottom: targetSliver.geometry!.scrollExtent
                    )
                }
            }
            rectLocal = rect!
        } else {
            assert(rect != nil)
            return RevealedOffset(offset: offset.pixels, rect: rect!)
        }

        assert(child.parent === self)
        assert(child is RenderSliver)
        let sliver = child as! RenderSliver

        // The scroll offset of `rect` within `child`.
        switch applyGrowthDirectionToAxisDirection(axisDirection, growthDirection) {
        case .up: leadingScrollOffset += (pivotExtent - rectLocal.bottom)
        case .left: leadingScrollOffset += (pivotExtent - rectLocal.right)
        case .right: leadingScrollOffset += rectLocal.left
        case .down: leadingScrollOffset += rectLocal.top
        }

        // So far leadingScrollOffset is the scroll offset of `rect` in the `child`
        // sliver's sliver coordinate system. The sign of this value indicates
        // whether the `rect` protrudes the leading edge of the `child` sliver. When
        // this value is non-negative and `child`'s `maxScrollObstructionExtent` is
        // greater than 0, we assume `rect` can't be obstructed by the leading edge
        // of the viewport (i.e. its pinned to the leading edge).
        let isPinned = sliver.geometry!.maxScrollObstructionExtent > 0 && leadingScrollOffset >= 0

        // The scroll offset in the viewport to `rect`.
        leadingScrollOffset = scrollOffsetOf(sliver, scrollOffsetWithinChild: leadingScrollOffset)

        // This step assumes the viewport's layout is up-to-date, i.e., if
        // offset.pixels is changed after the last performLayout, the new scroll
        // position will not be accounted for.
        let transform = target.getTransformTo(self)
        var targetRect = MatrixUtils.transformRect(transform, rect!)
        let extentOfPinnedSlivers = maxScrollObstructionExtentBefore(sliver)

        switch sliver.sliverConstraints.growthDirection {
        case .forward:
            if isPinned && alignment <= 0 {
                return RevealedOffset(offset: .infinity, rect: targetRect)
            }
            leadingScrollOffset -= extentOfPinnedSlivers
        case .reverse:
            if isPinned && alignment >= 1 {
                return RevealedOffset(offset: -.infinity, rect: targetRect)
            }
            // If child's growth direction is reverse, when viewport.offset is
            // `leadingScrollOffset`, it is positioned just outside of the leading
            // edge of the viewport.
            switch axis {
            case .vertical: leadingScrollOffset -= targetRect.height
            case .horizontal: leadingScrollOffset -= targetRect.width
            }
        }

        let mainAxisExtentDifference =
            switch axis {
            case .horizontal: size.width - extentOfPinnedSlivers - rectLocal.width
            case .vertical: size.height - extentOfPinnedSlivers - rectLocal.height
            }

        let targetOffset = leadingScrollOffset - mainAxisExtentDifference * alignment
        let offsetDifference = offset.pixels - targetOffset

        targetRect =
            switch axisDirection {
            case .up: targetRect.translate(0.0, -offsetDifference)
            case .down: targetRect.translate(0.0, offsetDifference)
            case .left: targetRect.translate(-offsetDifference, 0.0)
            case .right: targetRect.translate(offsetDifference, 0.0)
            }

        return RevealedOffset(offset: targetOffset, rect: targetRect)
    }

    /// The offset at which the given `child` should be painted.
    ///
    /// The returned offset is from the top left corner of the inside of the
    /// viewport to the top left corner of the paint coordinate system of the
    /// `child`.
    ///
    /// See also:
    ///
    ///  * [paintOffsetOf], which uses the layout offset and growth direction
    ///    computed for the child during layout.
    public func computeAbsolutePaintOffset(
        _ child: RenderSliver,
        layoutOffset: Float,
        growthDirection: GrowthDirection
    ) -> Offset {
        assert(hasSize)  // this is only usable once we have a size
        assert(child.geometry != nil)
        switch applyGrowthDirectionToAxisDirection(axisDirection, growthDirection) {
        case .up:
            return Offset(0.0, size.height - layoutOffset - child.geometry!.paintExtent)
        case .left:
            return Offset(size.width - layoutOffset - child.geometry!.paintExtent, 0.0)
        case .right:
            return Offset(layoutOffset, 0.0)
        case .down:
            return Offset(0.0, layoutOffset)
        }
    }

    // MARK:- API TO BE IMPLEMENTED BY SUBCLASSES

    // setupParentData

    // performLayout (and optionally sizedByParent and performResize)

    /// Whether the contents of this viewport would paint outside the bounds of
    /// the viewport if [paint] did not clip.
    ///
    /// This property enables an optimization whereby [paint] can skip apply a
    /// clip of the contents of the viewport are known to paint entirely within
    /// the bounds of the viewport.
    open var hasVisualOverflow: Bool {
        fatalError()
    }

    /// Called during [layoutChildSequence] for each child.
    ///
    /// Typically used by subclasses to update any out-of-band data, such as the
    /// max scroll extent, for each child.
    open func updateOutOfBandData(
        _ growthDirection: GrowthDirection,
        _ childLayoutGeometry: SliverGeometry
    ) {
        fatalError()
    }

    /// Called during [layoutChildSequence] to store the layout offset for the
    /// given child.
    ///
    /// Different subclasses using different representations for their children's
    /// layout offset (e.g., logical or physical coordinates). This function lets
    /// subclasses transform the child's layout offset before storing it in the
    /// child's parent data.
    open func updateChildLayoutOffset(
        _ child: RenderSliver,
        _ layoutOffset: Float,
        _ growthDirection: GrowthDirection
    ) {
        fatalError()
    }

    /// The offset at which the given `child` should be painted.
    ///
    /// The returned offset is from the top left corner of the inside of the
    /// viewport to the top left corner of the paint coordinate system of the
    /// `child`.
    ///
    /// See also:
    ///
    ///  * [computeAbsolutePaintOffset], which computes the paint offset from an
    ///    explicit layout offset and growth direction instead of using the values
    ///    computed for the child during layout.
    func paintOffsetOf(_ child: RenderSliver) -> Offset {
        fatalError()
    }

    /// Returns the scroll offset within the viewport for the given
    /// `scrollOffsetWithinChild` within the given `child`.
    ///
    /// The returned value is an estimate that assumes the slivers within the
    /// viewport do not change the layout extent in response to changes in their
    /// scroll offset.
    func scrollOffsetOf(_ child: RenderSliver, scrollOffsetWithinChild: Float) -> Float {
        fatalError()
    }

    /// Returns the total scroll obstruction extent of all slivers in the viewport
    /// before [child].
    ///
    /// This is the extent by which the actual area in which content can scroll
    /// is reduced. For example, an app bar that is pinned at the top will reduce
    /// the area in which content can actually scroll by the height of the app bar.
    func maxScrollObstructionExtentBefore(_ child: RenderSliver) -> Float {
        fatalError()
    }

    /// Converts the `parentMainAxisPosition` into the child's coordinate system.
    ///
    /// The `parentMainAxisPosition` is a distance from the top edge (for vertical
    /// viewports) or left edge (for horizontal viewports) of the viewport bounds.
    /// This describes a line, perpendicular to the viewport's main axis, heretofore
    /// known as the target line.
    ///
    /// The child's coordinate system's origin in the main axis is at the leading
    /// edge of the given child, as given by the child's
    /// [SliverConstraints.axisDirection] and [SliverConstraints.growthDirection].
    ///
    /// This method returns the distance from the leading edge of the given child to
    /// the target line described above.
    ///
    /// (The `parentMainAxisPosition` is not from the leading edge of the
    /// viewport, it's always the top or left edge.)
    open func computeChildMainAxisPosition(_ child: RenderSliver, _ parentMainAxisPosition: Float)
        -> Float
    {
        fatalError()
    }

    /// The index of the first child of the viewport relative to the center child.
    ///
    /// For example, the center child has index zero and the first child in the
    /// reverse growth direction has index -1.
    open var indexOfFirstChild: Int { fatalError() }

    /// A short string to identify the child with the given index.
    ///
    /// Used by [debugDescribeChildren] to label the children.
    open func labelForChild(_ index: Int) -> String {
        fatalError()
    }

    /// Provides an iterable that walks the children of the viewport, in the order
    /// that they should be painted.
    ///
    /// This should be the reverse order of [childrenInHitTestOrder].
    open var childrenInPaintOrder: [RenderSliver] { fatalError() }

    /// Provides an iterable that walks the children of the viewport, in the order
    /// that hit-testing should use.
    ///
    /// This should be the reverse order of [childrenInPaintOrder].
    open var childrenInHitTestOrder: [RenderSliver] { fatalError() }

    //   @override
    //   void showOnScreen({
    //     RenderObject? descendant,
    //     Rect? rect,
    //     Duration duration = Duration.zero,
    //     Curve curve = Curves.ease,
    //   }) {
    //     if (!offset.allowImplicitScrolling) {
    //       return super.showOnScreen(
    //         descendant: descendant,
    //         rect: rect,
    //         duration: duration,
    //         curve: curve,
    //       );
    //     }

    //     final Rect? newRect = RenderViewportBase.showInViewport(
    //       descendant: descendant,
    //       viewport: this,
    //       offset: offset,
    //       rect: rect,
    //       duration: duration,
    //       curve: curve,
    //     );
    //     super.showOnScreen(
    //       rect: newRect,
    //       duration: duration,
    //       curve: curve,
    //     );
    //   }

    //   /// Make (a portion of) the given `descendant` of the given `viewport` fully
    //   /// visible in the `viewport` by manipulating the provided [ViewportOffset]
    //   /// `offset`.
    //   ///
    //   /// The optional `rect` parameter describes which area of the `descendant`
    //   /// should be shown in the viewport. If `rect` is null, the entire
    //   /// `descendant` will be revealed. The `rect` parameter is interpreted
    //   /// relative to the coordinate system of `descendant`.
    //   ///
    //   /// The returned [Rect] describes the new location of `descendant` or `rect`
    //   /// in the viewport after it has been revealed. See [RevealedOffset.rect]
    //   /// for a full definition of this [Rect].
    //   ///
    //   /// If `descendant` is null, this is a no-op and `rect` is returned.
    //   ///
    //   /// If both `descendant` and `rect` are null, null is returned because there is
    //   /// nothing to be shown in the viewport.
    //   ///
    //   /// The `duration` parameter can be set to a non-zero value to animate the
    //   /// target object into the viewport with an animation defined by `curve`.
    //   ///
    //   /// See also:
    //   ///
    //   /// * [RenderObject.showOnScreen], overridden by [RenderViewportBase] and the
    //   ///   renderer for [SingleChildScrollView] to delegate to this method.
    //   static Rect? showInViewport({
    //     RenderObject? descendant,
    //     Rect? rect,
    //     required RenderAbstractViewport viewport,
    //     required ViewportOffset offset,
    //     Duration duration = Duration.zero,
    //     Curve curve = Curves.ease,
    //   }) {
    //     if (descendant == null) {
    //       return rect;
    //     }
    //     final RevealedOffset leadingEdgeOffset = viewport.getOffsetToReveal(descendant, 0.0, rect: rect);
    //     final RevealedOffset trailingEdgeOffset = viewport.getOffsetToReveal(descendant, 1.0, rect: rect);
    //     final double currentOffset = offset.pixels;
    //     final RevealedOffset? targetOffset = RevealedOffset.clampOffset(
    //       leadingEdgeOffset: leadingEdgeOffset,
    //       trailingEdgeOffset: trailingEdgeOffset,
    //       currentOffset: currentOffset,
    //     );
    //     if (targetOffset == null) {
    //       // `descendant` is between leading and trailing edge and hence already
    //       //  fully shown on screen. No action necessary.
    //       assert(viewport.parent != null);
    //       final Matrix4 transform = descendant.getTransformTo(viewport.parent);
    //       return MatrixUtils.transformRect(transform, rect ?? descendant.paintBounds);
    //     }

    //     offset.moveTo(targetOffset.offset, duration: duration, curve: curve);
    //     return targetOffset.rect;
    //   }
}

/// A render object that is bigger on the inside.
///
/// [RenderViewport] is the visual workhorse of the scrolling machinery. It
/// displays a subset of its children according to its own dimensions and the
/// given [offset]. As the offset varies, different children are visible through
/// the viewport.
///
/// [RenderViewport] hosts a bidirectional list of slivers in a single shared
/// [Axis], anchored on a [center] sliver, which is placed at the zero scroll
/// offset. The center widget is displayed in the viewport according to the
/// [anchor] property.
///
/// Slivers that are earlier in the child list than [center] are displayed in
/// reverse order in the reverse [axisDirection] starting from the [center]. For
/// example, if the [axisDirection] is [AxisDirection.down], the first sliver
/// before [center] is placed above the [center]. The slivers that are later in
/// the child list than [center] are placed in order in the [axisDirection]. For
/// example, in the preceding scenario, the first sliver after [center] is
/// placed below the [center].
///
/// [RenderViewport] cannot contain [RenderBox] children directly. Instead, use
/// a [RenderSliverList], [RenderSliverFixedExtentList], [RenderSliverGrid], or
/// a [RenderSliverToBoxAdapter], for example.
///
/// See also:
///
///  * [RenderSliver], which explains more about the Sliver protocol.
///  * [RenderBox], which explains more about the Box protocol.
///  * [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
///    placed inside a [RenderSliver] (the opposite of this class).
///  * [RenderShrinkWrappingViewport], a variant of [RenderViewport] that
///    shrink-wraps its contents along the main axis.
public class RenderViewport: RenderViewportBase<SliverPhysicalContainerParentData> {
    /// Creates a viewport for [RenderSliver] objects.
    ///
    /// If the [center] is not specified, then the first child in the `children`
    /// list, if any, is used.
    ///
    /// The [offset] must be specified. For testing purposes, consider passing a
    /// [ViewportOffset.zero] or [ViewportOffset.fixed].
    public init(
        axisDirection: AxisDirection = .down,
        crossAxisDirection: AxisDirection,
        offset: ViewportOffset,
        anchor: Float = 0.0,
        children: [RenderSliver]? = nil,
        center: RenderSliver? = nil,
        cacheExtent: Float? = nil,
        cacheExtentStyle: CacheExtentStyle = .pixel,
        clipBehavior: Clip = .hardEdge
    ) {
        precondition(anchor >= 0.0 && anchor <= 1.0)
        precondition(cacheExtentStyle != .viewport || cacheExtent != nil)

        self.anchor = anchor
        self.center = center

        super.init(
            axisDirection: axisDirection,
            crossAxisDirection: crossAxisDirection,
            offset: offset,
            cacheExtent: cacheExtent,
            cacheExtentStyle: cacheExtentStyle,
            clipBehavior: clipBehavior
        )

        if let children {
            addAll(children)
        }
        if center == nil && firstChild != nil {
            self.center = firstChild
        }
    }

    /// If a [RenderAbstractViewport] overrides
    /// [RenderObject.describeSemanticsConfiguration] to add the [SemanticsTag]
    /// [useTwoPaneSemantics] to its [SemanticsConfiguration], two semantics nodes
    /// will be used to represent the viewport with its associated scrolling
    /// actions in the semantics tree.
    ///
    /// Two semantics nodes (an inner and an outer node) are necessary to exclude
    /// certain child nodes (via the [excludeFromScrolling] tag) from the
    /// scrollable area for semantic purposes: The [SemanticsNode]s of children
    /// that should be excluded from scrolling will be attached to the outer node.
    /// The semantic scrolling actions and the [SemanticsNode]s of scrollable
    /// children will be attached to the inner node, which itself is a child of
    /// the outer node.
    ///
    /// See also:
    ///
    /// * [RenderViewportBase.describeSemanticsConfiguration], which adds this
    ///   tag to its [SemanticsConfiguration].
    //   static const SemanticsTag useTwoPaneSemantics = SemanticsTag('RenderViewport.twoPane');

    /// When a top-level [SemanticsNode] below a [RenderAbstractViewport] is
    /// tagged with [excludeFromScrolling] it will not be part of the scrolling
    /// area for semantic purposes.
    ///
    /// This behavior is only active if the [RenderAbstractViewport]
    /// tagged its [SemanticsConfiguration] with [useTwoPaneSemantics].
    /// Otherwise, the [excludeFromScrolling] tag is ignored.
    ///
    /// As an example, a [RenderSliver] that stays on the screen within a
    /// [Scrollable] even though the user has scrolled past it (e.g. a pinned app
    /// bar) can tag its [SemanticsNode] with [excludeFromScrolling] to indicate
    /// that it should no longer be considered for semantic actions related to
    /// scrolling.
    //   static const SemanticsTag excludeFromScrolling = SemanticsTag('RenderViewport.excludeFromScrolling');

    public override func setupParentData(_ child: RenderObject) {
        if !(child.parentData is SliverPhysicalContainerParentData) {
            child.parentData = SliverPhysicalContainerParentData()
        }
    }

    /// The relative position of the zero scroll offset.
    ///
    /// For example, if [anchor] is 0.5 and the [axisDirection] is
    /// [AxisDirection.down] or [AxisDirection.up], then the zero scroll offset is
    /// vertically centered within the viewport. If the [anchor] is 1.0, and the
    /// [axisDirection] is [AxisDirection.right], then the zero scroll offset is
    /// on the left edge of the viewport.
    public var anchor: Float {
        didSet {
            assert(anchor >= 0.0 && anchor <= 1.0)
            if anchor != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// The first child in the [GrowthDirection.forward] growth direction.
    ///
    /// This child that will be at the position defined by [anchor] when the
    /// [ViewportOffset.pixels] of [offset] is `0`.
    ///
    /// Children after [center] will be placed in the [axisDirection] relative to
    /// the [center].
    ///
    /// Children before [center] will be placed in the opposite of
    /// the [axisDirection] relative to the [center]. These children above
    /// [center] will have a growth direction of [GrowthDirection.reverse].
    ///
    /// The [center] must be a direct child of the viewport.
    public var center: RenderSliver? {
        didSet {
            if center !== oldValue {
                markNeedsLayout()
            }
        }
    }

    //   @override
    public override var sizedByParent: Bool { true }

    public override func computeDryLayout(_ constraints: BoxConstraints) -> Size {
        // assert(debugCheckHasBoundedAxis(axis, constraints))
        return constraints.biggest
    }

    static let maxLayoutCyclesPerChild = 10

    // Out-of-band data computed during layout.
    private var _minScrollExtent: Float = 0.0
    private var _maxScrollExtent: Float = 0.0
    private var _hasVisualOverflow: Bool = false

    public override func performLayout() {
        // Ignore the return value of applyViewportDimension because we are
        // doing a layout regardless.
        switch axis {
        case .vertical:
            _ = offset.applyViewportDimension(size.height)
        case .horizontal:
            _ = offset.applyViewportDimension(size.width)
        }

        if center == nil {
            assert(firstChild == nil)
            _minScrollExtent = 0.0
            _maxScrollExtent = 0.0
            _hasVisualOverflow = false
            _ = offset.applyContentDimensions(0.0, 0.0)
            return
        }
        assert(center!.parent === self)

        let (mainAxisExtent, crossAxisExtent): (Float, Float) =
            switch axis {
            case .vertical: (size.height, size.width)
            case .horizontal: (size.width, size.height)
            }

        let centerOffsetAdjustment = center!.centerOffsetAdjustment
        let maxLayoutCycles = Self.maxLayoutCyclesPerChild * childCount

        var correction: Float = 0.0
        var count = 0
        repeat {
            correction = _attemptLayout(
                mainAxisExtent: mainAxisExtent,
                crossAxisExtent: crossAxisExtent,
                correctedOffset: offset.pixels + centerOffsetAdjustment
            )
            if correction != 0.0 {
                offset.correctBy(correction)
            } else {
                if offset.applyContentDimensions(
                    min(0.0, _minScrollExtent + mainAxisExtent * anchor),
                    max(0.0, _maxScrollExtent - mainAxisExtent * (1.0 - anchor))
                ) {
                    break
                }
            }
            count += 1
        } while count < maxLayoutCycles

        assert {
            if count >= maxLayoutCycles {
                assert(count != 1)
                preconditionFailure(
                    """
                    A RenderViewport exceeded its maximum number of layout cycles.
                    RenderViewport render objects, during layout, can retry if either their
                    slivers or their ViewportOffset decide that the offset should be corrected
                    to take into account information collected during that layout.
                    In the case of this RenderViewport object, however, this happened \(count)
                    times and still there was no consensus on the scroll offset. This usually
                    indicates a bug. Specifically, it means that one of the following three
                    problems is being experienced by the RenderViewport object:
                    * One of the RenderSliver children or the ViewportOffset have a bug such
                    that they always think that they need to correct the offset regardless.
                    * Some combination of the RenderSliver children and the ViewportOffset
                    have a bad interaction such that one applies a correction then another
                    applies a reverse correction, leading to an infinite loop of corrections.
                    * There is a pathological case that would eventually resolve, but it is
                    so complicated that it cannot be resolved in any reasonable number of
                    layout passes.
                    """
                )
            }
            return true
        }
    }

    private func _attemptLayout(
        mainAxisExtent: Float,
        crossAxisExtent: Float,
        correctedOffset: Float
    ) -> Float {
        assert(!mainAxisExtent.isNaN)
        assert(mainAxisExtent >= 0.0)
        assert(crossAxisExtent.isFinite)
        assert(crossAxisExtent >= 0.0)
        assert(correctedOffset.isFinite)
        _minScrollExtent = 0.0
        _maxScrollExtent = 0.0
        _hasVisualOverflow = false

        // centerOffset is the offset from the leading edge of the RenderViewport
        // to the zero scroll offset (the line between the forward slivers and the
        // reverse slivers).
        let centerOffset = mainAxisExtent * anchor - correctedOffset
        let reverseDirectionRemainingPaintExtent = centerOffset.clamped(to: 0.0...mainAxisExtent)
        let forwardDirectionRemainingPaintExtent = (mainAxisExtent - centerOffset).clamped(
            to: 0.0...mainAxisExtent
        )

        calculatedCacheExtent =
            switch cacheExtentStyle {
            case .pixel: cacheExtent
            case .viewport: mainAxisExtent * cacheExtent!
            }

        let fullCacheExtent = mainAxisExtent + 2 * calculatedCacheExtent!
        let centerCacheOffset = centerOffset + calculatedCacheExtent!
        let reverseDirectionRemainingCacheExtent = centerCacheOffset.clamped(
            to: 0.0...fullCacheExtent
        )
        let forwardDirectionRemainingCacheExtent = (fullCacheExtent - centerCacheOffset).clamped(
            to: 0.0...fullCacheExtent
        )

        let leadingNegativeChild = childBefore(center!)

        if let leadingNegativeChild = leadingNegativeChild {
            // negative scroll offsets
            let result = layoutChildSequence(
                child: leadingNegativeChild,
                scrollOffset: max(mainAxisExtent, centerOffset) - mainAxisExtent,
                overlap: 0.0,
                layoutOffset: forwardDirectionRemainingPaintExtent,
                remainingPaintExtent: reverseDirectionRemainingPaintExtent,
                mainAxisExtent: mainAxisExtent,
                crossAxisExtent: crossAxisExtent,
                growthDirection: .reverse,
                advance: childBefore,
                remainingCacheExtent: reverseDirectionRemainingCacheExtent,
                cacheOrigin: (mainAxisExtent - centerOffset).clamped(
                    to: -calculatedCacheExtent!...0.0
                )
            )
            if result != 0.0 {
                return -result
            }
        }

        // positive scroll offsets
        return layoutChildSequence(
            child: center,
            scrollOffset: max(0.0, -centerOffset),
            overlap: leadingNegativeChild == nil ? min(0.0, -centerOffset) : 0.0,
            layoutOffset: centerOffset >= mainAxisExtent
                ? centerOffset : reverseDirectionRemainingPaintExtent,
            remainingPaintExtent: forwardDirectionRemainingPaintExtent,
            mainAxisExtent: mainAxisExtent,
            crossAxisExtent: crossAxisExtent,
            growthDirection: .forward,
            advance: childAfter,
            remainingCacheExtent: forwardDirectionRemainingCacheExtent,
            cacheOrigin: centerOffset.clamped(to: -calculatedCacheExtent!...0.0)
        )
    }

    public override var hasVisualOverflow: Bool { _hasVisualOverflow }

    public override func updateOutOfBandData(
        _ growthDirection: GrowthDirection,
        _ childLayoutGeometry: SliverGeometry
    ) {
        switch growthDirection {
        case .forward:
            _maxScrollExtent += childLayoutGeometry.scrollExtent
        case .reverse:
            _minScrollExtent -= childLayoutGeometry.scrollExtent
        }
        if childLayoutGeometry.hasVisualOverflow {
            _hasVisualOverflow = true
        }
    }

    public override func updateChildLayoutOffset(
        _ child: RenderSliver,
        _ layoutOffset: Float,
        _ growthDirection: GrowthDirection
    ) {
        let childParentData = child.parentData as! SliverPhysicalContainerParentData
        childParentData.paintOffset = computeAbsolutePaintOffset(
            child,
            layoutOffset: layoutOffset,
            growthDirection: growthDirection
        )
    }

    public override func paintOffsetOf(_ child: RenderSliver) -> Offset {
        let childParentData = child.parentData as! SliverPhysicalContainerParentData
        return childParentData.paintOffset
    }

    public override func scrollOffsetOf(_ child: RenderSliver, scrollOffsetWithinChild: Float)
        -> Float
    {
        assert(child.parent === self)
        let growthDirection = child.sliverConstraints.growthDirection
        switch growthDirection {
        case .forward:
            var scrollOffsetToChild: Float = 0.0
            var current = center
            while current !== child {
                scrollOffsetToChild += current!.geometry!.scrollExtent
                current = childAfter(current!)
            }
            return scrollOffsetToChild + scrollOffsetWithinChild
        case .reverse:
            var scrollOffsetToChild: Float = 0.0
            var current = childBefore(center!)
            while current !== child {
                scrollOffsetToChild -= current!.geometry!.scrollExtent
                current = childBefore(current!)
            }
            return scrollOffsetToChild - scrollOffsetWithinChild
        }
    }

    public override func maxScrollObstructionExtentBefore(_ child: RenderSliver) -> Float {
        assert(child.parent === self)
        let growthDirection = child.sliverConstraints.growthDirection
        switch growthDirection {
        case .forward:
            var pinnedExtent: Float = 0.0
            var current = center
            while current !== child {
                pinnedExtent += current!.geometry!.maxScrollObstructionExtent
                current = childAfter(current!)
            }
            return pinnedExtent
        case .reverse:
            var pinnedExtent: Float = 0.0
            var current = childBefore(center!)
            while current !== child {
                pinnedExtent += current!.geometry!.maxScrollObstructionExtent
                current = childBefore(current!)
            }
            return pinnedExtent
        }
    }

    public override func applyPaintTransform(_ child: RenderObject, transform: inout Matrix4x4f) {
        // Hit test logic relies on this always providing an invertible matrix.
        let childParentData = child.parentData as! SliverPhysicalParentData
        childParentData.applyPaintTransform(&transform)
    }

    public override func computeChildMainAxisPosition(
        _ child: RenderSliver,
        _ parentMainAxisPosition: Float
    ) -> Float {
        let paintOffset = (child.parentData as! SliverPhysicalParentData).paintOffset
        return
            switch applyGrowthDirectionToAxisDirection(
                child.sliverConstraints.axisDirection,
                child.sliverConstraints.growthDirection
            )
        {
        case .down: parentMainAxisPosition - paintOffset.dy
        case .right: parentMainAxisPosition - paintOffset.dx
        case .up: child.geometry!.paintExtent - (parentMainAxisPosition - paintOffset.dy)
        case .left: child.geometry!.paintExtent - (parentMainAxisPosition - paintOffset.dx)
        }
    }

    public override var indexOfFirstChild: Int {
        assert(center != nil)
        assert(center!.parent === self)
        assert(firstChild != nil)
        var count = 0
        var child = center
        while child !== firstChild {
            count -= 1
            child = childBefore(child!)
        }
        return count
    }

    public override func labelForChild(_ index: Int) -> String {
        if index == 0 {
            return "center child"
        }
        return "child \(index)"
    }

    public override var childrenInPaintOrder: [RenderSliver] {
        var children: [RenderSliver] = []
        if firstChild == nil {
            return children
        }
        var child = firstChild
        while child !== center {
            children.append(child!)
            child = childAfter(child!)
        }
        child = lastChild
        while true {
            children.append(child!)
            if child === center {
                return children
            }
            child = childBefore(child!)
        }
    }

    public override var childrenInHitTestOrder: [RenderSliver] {
        var children: [RenderSliver] = []
        if firstChild == nil {
            return children
        }
        var child = center
        while child != nil {
            children.append(child!)
            child = childAfter(child!)
        }
        child = childBefore(center!)
        while child != nil {
            children.append(child!)
            child = childBefore(child!)
        }
        return children
    }
}

/// A render object that is bigger on the inside and shrink wraps its children
/// in the main axis.
///
/// [RenderShrinkWrappingViewport] displays a subset of its children according
/// to its own dimensions and the given [offset]. As the offset varies, different
/// children are visible through the viewport.
///
/// [RenderShrinkWrappingViewport] differs from [RenderViewport] in that
/// [RenderViewport] expands to fill the main axis whereas
/// [RenderShrinkWrappingViewport] sizes itself to match its children in the
/// main axis. This shrink wrapping behavior is expensive because the children,
/// and hence the viewport, could potentially change size whenever the [offset]
/// changes (e.g., because of a collapsing header).
///
/// [RenderShrinkWrappingViewport] cannot contain [RenderBox] children directly.
/// Instead, use a [RenderSliverList], [RenderSliverFixedExtentList],
/// [RenderSliverGrid], or a [RenderSliverToBoxAdapter], for example.
///
/// See also:
///
///  * [RenderViewport], a viewport that does not shrink-wrap its contents.
///  * [RenderSliver], which explains more about the Sliver protocol.
///  * [RenderBox], which explains more about the Box protocol.
///  * [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
///    placed inside a [RenderSliver] (the opposite of this class).
public class RenderShrinkWrappingViewport: RenderViewportBase<SliverLogicalContainerParentData> {
    /// Creates a viewport (for [RenderSliver] objects) that shrink-wraps its
    /// contents.
    ///
    /// The [offset] must be specified. For testing purposes, consider passing a
    /// [ViewportOffset.zero] or [ViewportOffset.fixed].
    public init(
        axisDirection: AxisDirection = .down,
        crossAxisDirection: AxisDirection,
        offset: ViewportOffset,
        clipBehavior: Clip = .hardEdge,
        children: [RenderSliver]? = nil
    ) {
        super.init(
            axisDirection: axisDirection,
            crossAxisDirection: crossAxisDirection,
            offset: offset,
            clipBehavior: clipBehavior
        )
        if let children {
            addAll(children)
        }
    }

    public override func setupParentData(_ child: RenderObject) {
        if !(child.parentData is SliverLogicalContainerParentData) {
            child.parentData = SliverLogicalContainerParentData()
        }
    }

    //   @override
    //   bool debugThrowIfNotCheckingIntrinsics() {
    //     assert(() {
    //       if (!RenderObject.debugCheckingIntrinsics) {
    //         throw FlutterError.fromParts(<DiagnosticsNode>[
    //           ErrorSummary('$runtimeType does not support returning intrinsic dimensions.'),
    //           ErrorDescription(
    //            'Calculating the intrinsic dimensions would require instantiating every child of '
    //            'the viewport, which defeats the point of viewports being lazy.',
    //           ),
    //           ErrorHint(
    //             'If you are merely trying to shrink-wrap the viewport in the main axis direction, '
    //             'you should be able to achieve that effect by just giving the viewport loose '
    //             'constraints, without needing to measure its intrinsic dimensions.',
    //           ),
    //         ]);
    //       }
    //       return true;
    //     }());
    //     return true;
    //   }

    // Out-of-band data computed during layout.
    private var _maxScrollExtent: Float = 0.0
    private var _shrinkWrapExtent: Float = 0.0
    private var _hasVisualOverflow: Bool = false

    private func _debugCheckHasBoundedCrossAxis() -> Bool {
        assert {
            switch axis {
            case .vertical:
                if !boxConstraint.hasBoundedWidth {
                    preconditionFailure(
                        """
                        Vertical viewport was given unbounded width.
                        Viewports expand in the cross axis to fill their container and \
                        constrain their children to match their extent in the cross axis. \
                        In this case, a vertical shrinkwrapping viewport was given an \
                        unlimited amount of horizontal space in which to expand.
                        """
                    )
                }
            case .horizontal:
                if !boxConstraint.hasBoundedHeight {
                    preconditionFailure(
                        """
                        Horizontal viewport was given unbounded height.
                        Viewports expand in the cross axis to fill their container and \
                        constrain their children to match their extent in the cross axis. \
                        In this case, a horizontal shrinkwrapping viewport was given an \
                        unlimited amount of vertical space in which to expand.
                        """
                    )
                }
            }
            return true
        }
        return true
    }

    public override func performLayout() {
        let constraints = self.boxConstraint
        if firstChild == nil {
            // Shrinkwrapping viewport only requires the cross axis to be bounded.
            assert(_debugCheckHasBoundedCrossAxis())
            size =
                switch axis {
                case .vertical: Size(constraints.maxWidth, constraints.minHeight)
                case .horizontal: Size(constraints.minWidth, constraints.maxHeight)
                }
            _ = offset.applyViewportDimension(0.0)
            _maxScrollExtent = 0.0
            _shrinkWrapExtent = 0.0
            _hasVisualOverflow = false
            _ = offset.applyContentDimensions(0.0, 0.0)
            return
        }

        // Shrinkwrapping viewport only requires the cross axis to be bounded.
        assert(_debugCheckHasBoundedCrossAxis())
        let (mainAxisExtent, crossAxisExtent): (Float, Float) =
            switch axis {
            case .vertical: (constraints.maxHeight, constraints.maxWidth)
            case .horizontal: (constraints.maxWidth, constraints.maxHeight)
            }

        var correction: Float
        var effectiveExtent: Float
        while true {
            correction = _attemptLayout(
                mainAxisExtent: mainAxisExtent,
                crossAxisExtent: crossAxisExtent,
                correctedOffset: offset.pixels
            )
            if correction != 0.0 {
                offset.correctBy(correction)
            } else {
                effectiveExtent =
                    switch axis {
                    case .vertical: constraints.constrainHeight(_shrinkWrapExtent)
                    case .horizontal: constraints.constrainWidth(_shrinkWrapExtent)
                    }
                let didAcceptViewportDimension = offset.applyViewportDimension(effectiveExtent)
                let didAcceptContentDimension = offset.applyContentDimensions(
                    0.0,
                    max(0.0, _maxScrollExtent - effectiveExtent)
                )
                if didAcceptViewportDimension && didAcceptContentDimension {
                    break
                }
            }
        }
        size =
            switch axis {
            case .vertical:
                constraints.constrainDimensions(width: crossAxisExtent, height: effectiveExtent)
            case .horizontal:
                constraints.constrainDimensions(width: effectiveExtent, height: crossAxisExtent)
            }
    }

    private func _attemptLayout(
        mainAxisExtent: Float,
        crossAxisExtent: Float,
        correctedOffset: Float
    ) -> Float {
        // We can't assert mainAxisExtent is finite, because it could be infinite if
        // it is within a column or row for example. In such a case, there's not
        // even any scrolling to do, although some scroll physics (i.e.
        // BouncingScrollPhysics) could still temporarily scroll the content in a
        // simulation.
        assert(!mainAxisExtent.isNaN)
        assert(mainAxisExtent >= 0.0)
        assert(crossAxisExtent.isFinite)
        assert(crossAxisExtent >= 0.0)
        assert(correctedOffset.isFinite)
        _maxScrollExtent = 0.0
        _shrinkWrapExtent = 0.0
        // Since the viewport is shrinkwrapped, we know that any negative overscroll
        // into the potentially infinite mainAxisExtent will overflow the end of
        // the viewport.
        _hasVisualOverflow = correctedOffset < 0.0
        calculatedCacheExtent =
            switch cacheExtentStyle {
            case .pixel: cacheExtent
            case .viewport: mainAxisExtent * cacheExtent!
            }

        return layoutChildSequence(
            child: firstChild,
            scrollOffset: max(0.0, correctedOffset),
            overlap: min(0.0, correctedOffset),
            layoutOffset: max(0.0, -correctedOffset),
            remainingPaintExtent: mainAxisExtent + min(0.0, correctedOffset),
            mainAxisExtent: mainAxisExtent,
            crossAxisExtent: crossAxisExtent,
            growthDirection: .forward,
            advance: childAfter,
            remainingCacheExtent: mainAxisExtent + 2 * calculatedCacheExtent!,
            cacheOrigin: -calculatedCacheExtent!
        )
    }

    public override var hasVisualOverflow: Bool { _hasVisualOverflow }

    public override func updateOutOfBandData(
        _ growthDirection: GrowthDirection,
        _ childLayoutGeometry: SliverGeometry
    ) {
        assert(growthDirection == .forward)
        _maxScrollExtent += childLayoutGeometry.scrollExtent
        if childLayoutGeometry.hasVisualOverflow {
            _hasVisualOverflow = true
        }
        _shrinkWrapExtent += childLayoutGeometry.maxPaintExtent
    }

    public override func updateChildLayoutOffset(
        _ child: RenderSliver,
        _ layoutOffset: Float,
        _ growthDirection: GrowthDirection
    ) {
        assert(growthDirection == .forward)
        let childParentData = child.parentData as! SliverLogicalParentData
        childParentData.layoutOffset = layoutOffset
    }

    public override func paintOffsetOf(_ child: RenderSliver) -> Offset {
        let childParentData = child.parentData as! SliverLogicalParentData
        return computeAbsolutePaintOffset(
            child,
            layoutOffset: childParentData.layoutOffset!,
            growthDirection: .forward
        )
    }

    public override func scrollOffsetOf(_ child: RenderSliver, scrollOffsetWithinChild: Float)
        -> Float
    {
        assert(child.parent === self)
        assert(child.sliverConstraints.growthDirection == .forward)
        var scrollOffsetToChild: Float = 0.0
        var current = firstChild
        while current !== child {
            scrollOffsetToChild += current!.geometry!.scrollExtent
            current = childAfter(current!)
        }
        return scrollOffsetToChild + scrollOffsetWithinChild
    }

    public override func maxScrollObstructionExtentBefore(_ child: RenderSliver) -> Float {
        assert(child.parent === self)
        assert(child.sliverConstraints.growthDirection == .forward)
        var pinnedExtent: Float = 0.0
        var current = firstChild
        while current !== child {
            pinnedExtent += current!.geometry!.maxScrollObstructionExtent
            current = childAfter(current!)
        }
        return pinnedExtent
    }

    public override func applyPaintTransform(_ child: RenderObject, transform: inout Matrix4x4f) {
        // Hit test logic relies on this always providing an invertible matrix.
        let offset = paintOffsetOf(child as! RenderSliver)
        transform.translate(offset.dx, offset.dy)
    }

    public override func computeChildMainAxisPosition(
        _ child: RenderSliver,
        _ parentMainAxisPosition: Float
    ) -> Float {
        assert(hasSize)
        let layoutOffset = (child.parentData as! SliverLogicalParentData).layoutOffset!

        return
            switch applyGrowthDirectionToAxisDirection(
                child.sliverConstraints.axisDirection,
                child.sliverConstraints.growthDirection
            )
        {
        case .down, .right:
            parentMainAxisPosition - layoutOffset
        case .up:
            size.height - parentMainAxisPosition - layoutOffset
        case .left:
            size.width - parentMainAxisPosition - layoutOffset
        }
    }

    public override var indexOfFirstChild: Int { 0 }

    public override func labelForChild(_ index: Int) -> String { "child \(index)" }

    public override var childrenInPaintOrder: [RenderSliver] {
        var children: [RenderSliver] = []
        var child = lastChild
        while child != nil {
            children.append(child!)
            child = childBefore(child!)
        }
        return children
    }

    public override var childrenInHitTestOrder: [RenderSliver] {
        var children: [RenderSliver] = []
        var child = firstChild
        while child != nil {
            children.append(child!)
            child = childAfter(child!)
        }
        return children
    }
}
