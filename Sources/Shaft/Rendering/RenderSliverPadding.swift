import SwiftMath

/// Insets a [RenderSliver] by applying [resolvedPadding] on each side.
///
/// A [RenderSliverEdgeInsetsPadding] subclass wraps the [SliverGeometry.layoutExtent]
/// of its child. Any incoming [SliverConstraints.overlap] is ignored and not
/// passed on to the child.
///
/// Applying padding in the main extent of the viewport to slivers that have scroll effects is likely to have
/// undesired effects. For example, wrapping a [SliverPersistentHeader] with
/// `pinned:true` will cause only the appbar to stay pinned while the padding will scroll away.
public class RenderSliverEdgeInsetsPadding: RenderSliver, RenderObjectWithSingleChild {
    public typealias ChildType = RenderSliver
    public var childMixin = RenderSingleChildMixin<RenderSliver>()

    /// The amount to pad the child in each dimension.
    ///
    /// The offsets are specified in terms of visual edges, left, top, right, and
    /// bottom. These values are not affected by the [TextDirection].
    ///
    /// Must not be null or contain negative values when [performLayout] is called.
    public var resolvedPadding: EdgeInsets? {
        preconditionFailure("\(#function) not yet implemented")
    }

    /// The padding in the scroll direction on the side nearest the 0.0 scroll direction.
    ///
    /// Only valid after layout has started, since before layout the render object
    /// doesn't know what direction it will be laid out in.
    public var beforePadding: Float {
        assert(resolvedPadding != nil)
        return
            switch applyGrowthDirectionToAxisDirection(
                sliverConstraints.axisDirection,
                sliverConstraints.growthDirection
            )
        {
        case .up: resolvedPadding!.bottom
        case .right: resolvedPadding!.left
        case .down: resolvedPadding!.top
        case .left: resolvedPadding!.right
        }
    }

    /// The padding in the scroll direction on the side furthest from the 0.0 scroll offset.
    ///
    /// Only valid after layout has started, since before layout the render object
    /// doesn't know what direction it will be laid out in.
    public var afterPadding: Float {
        assert(resolvedPadding != nil)
        return
            switch applyGrowthDirectionToAxisDirection(
                sliverConstraints.axisDirection,
                sliverConstraints.growthDirection
            )
        {
        case .up: resolvedPadding!.top
        case .right: resolvedPadding!.right
        case .down: resolvedPadding!.bottom
        case .left: resolvedPadding!.left
        }
    }

    /// The total padding in the [SliverConstraints.axisDirection]. (In other
    /// words, for a vertical downwards-growing list, the sum of the padding on
    /// the top and bottom.)
    ///
    /// Only valid after layout has started, since before layout the render object
    /// doesn't know what direction it will be laid out in.
    public var mainAxisPadding: Float {
        assert(resolvedPadding != nil)
        return resolvedPadding!.along(sliverConstraints.axis)
    }

    /// The total padding in the cross-axis direction. (In other words, for a
    /// vertical downwards-growing list, the sum of the padding on the left and
    /// right.)
    ///
    /// Only valid after layout has started, since before layout the render object
    /// doesn't know what direction it will be laid out in.
    public var crossAxisPadding: Float {
        assert(resolvedPadding != nil)
        return switch sliverConstraints.axis {
        case .horizontal: resolvedPadding!.vertical
        case .vertical: resolvedPadding!.horizontal
        }
    }

    public override func setupParentData(_ child: RenderObject) {
        if !(child.parentData is SliverPhysicalParentData) {
            child.parentData = SliverPhysicalParentData()
        }
    }

    public override func performLayout() {
        let constraints = sliverConstraints
        func paintOffset(from: Float, to: Float) -> Float {
            calculatePaintOffset(constraints, from: from, to: to)
        }
        func cacheOffset(from: Float, to: Float) -> Float {
            calculateCacheOffset(constraints, from: from, to: to)
        }

        assert(resolvedPadding != nil)
        let resolvedPadding = self.resolvedPadding!
        let beforePadding = self.beforePadding
        let afterPadding = self.afterPadding
        let mainAxisPadding = self.mainAxisPadding
        let crossAxisPadding = self.crossAxisPadding
        if child == nil {
            let paintExtent = paintOffset(from: 0.0, to: mainAxisPadding)
            let cacheExtent = cacheOffset(from: 0.0, to: mainAxisPadding)
            geometry = SliverGeometry(
                scrollExtent: mainAxisPadding,
                paintExtent: min(paintExtent, constraints.remainingPaintExtent),
                maxPaintExtent: mainAxisPadding,
                cacheExtent: cacheExtent
            )
            return
        }
        let beforePaddingPaintExtent = paintOffset(from: 0.0, to: beforePadding)
        var overlap = constraints.overlap
        if overlap > 0 {
            overlap = max(0.0, constraints.overlap - beforePaddingPaintExtent)
        }
        child!.layout(
            constraints.copyWith(
                scrollOffset: max(0.0, constraints.scrollOffset - beforePadding),
                precedingScrollExtent: beforePadding + constraints.precedingScrollExtent,
                overlap: overlap,
                remainingPaintExtent: constraints.remainingPaintExtent
                    - paintOffset(from: 0.0, to: beforePadding),
                crossAxisExtent: max(0.0, constraints.crossAxisExtent - crossAxisPadding),
                remainingCacheExtent: constraints.remainingCacheExtent
                    - cacheOffset(from: 0.0, to: beforePadding),
                cacheOrigin: min(0.0, constraints.cacheOrigin + beforePadding)
            ),
            parentUsesSize: true
        )
        let childLayoutGeometry = child!.geometry!
        if childLayoutGeometry.scrollOffsetCorrection != nil {
            geometry = SliverGeometry(
                scrollOffsetCorrection: childLayoutGeometry.scrollOffsetCorrection
            )
            return
        }
        let scrollExtent = childLayoutGeometry.scrollExtent
        let beforePaddingCacheExtent = cacheOffset(from: 0.0, to: beforePadding)
        let afterPaddingCacheExtent = cacheOffset(
            from: beforePadding + scrollExtent,
            to: mainAxisPadding + scrollExtent
        )
        let afterPaddingPaintExtent = paintOffset(
            from: beforePadding + scrollExtent,
            to: mainAxisPadding + scrollExtent
        )
        let mainAxisPaddingCacheExtent = beforePaddingCacheExtent + afterPaddingCacheExtent
        let mainAxisPaddingPaintExtent = beforePaddingPaintExtent + afterPaddingPaintExtent
        let paintExtent = min(
            beforePaddingPaintExtent
                + max(
                    childLayoutGeometry.paintExtent,
                    childLayoutGeometry.layoutExtent + afterPaddingPaintExtent
                ),
            constraints.remainingPaintExtent
        )
        geometry = SliverGeometry(
            scrollExtent: mainAxisPadding + scrollExtent,
            paintExtent: paintExtent,
            paintOrigin: childLayoutGeometry.paintOrigin,
            layoutExtent: min(
                mainAxisPaddingPaintExtent + childLayoutGeometry.layoutExtent,
                paintExtent
            ),
            maxPaintExtent: mainAxisPadding + childLayoutGeometry.maxPaintExtent,
            hitTestExtent: max(
                mainAxisPaddingPaintExtent + childLayoutGeometry.paintExtent,
                beforePaddingPaintExtent + childLayoutGeometry.hitTestExtent
            ),
            hasVisualOverflow: childLayoutGeometry.hasVisualOverflow,
            cacheExtent: min(
                mainAxisPaddingCacheExtent + childLayoutGeometry.cacheExtent,
                constraints.remainingCacheExtent
            )
        )
        let calculatedOffset =
            switch applyGrowthDirectionToAxisDirection(
                constraints.axisDirection,
                constraints.growthDirection
            ) {
            case .up:
                paintOffset(
                    from: resolvedPadding.bottom + scrollExtent,
                    to: resolvedPadding.vertical + scrollExtent
                )
            case .left:
                paintOffset(
                    from: resolvedPadding.right + scrollExtent,
                    to: resolvedPadding.horizontal + scrollExtent
                )
            case .right: paintOffset(from: 0.0, to: resolvedPadding.left)
            case .down: paintOffset(from: 0.0, to: resolvedPadding.top)
            }
        let childParentData = child!.parentData! as! SliverPhysicalParentData
        childParentData.paintOffset =
            switch constraints.axis {
            case .horizontal: Offset(calculatedOffset, resolvedPadding.top)
            case .vertical: Offset(resolvedPadding.left, calculatedOffset)
            }
        assert(beforePadding == self.beforePadding)
        assert(afterPadding == self.afterPadding)
        assert(mainAxisPadding == self.mainAxisPadding)
        assert(crossAxisPadding == self.crossAxisPadding)
    }

    public override func hitTestChildren(
        _ result: SliverHitTestResult,
        mainAxisPosition: Float,
        crossAxisPosition: Float
    ) -> Bool {
        if let child = child, child.geometry!.hitTestExtent > 0.0 {
            let childParentData = child.parentData! as! SliverPhysicalParentData
            return result.addWithAxisOffset(
                paintOffset: childParentData.paintOffset,
                mainAxisOffset: childMainAxisPosition(child),
                crossAxisOffset: childCrossAxisPosition(child),
                mainAxisPosition: mainAxisPosition,
                crossAxisPosition: crossAxisPosition,
                hitTest: child.hitTest
            )
        }
        return false
    }

    public override func childMainAxisPosition(_ child: RenderObject) -> Float {
        assert(child === self.child)
        return calculatePaintOffset(sliverConstraints, from: 0.0, to: beforePadding)
    }

    public override func childCrossAxisPosition(_ child: RenderObject) -> Float {
        assert(child === self.child)
        assert(resolvedPadding != nil)
        return switch sliverConstraints.axis {
        case .horizontal: resolvedPadding!.top
        case .vertical: resolvedPadding!.left
        }
    }

    public override func childScrollOffset(_ child: RenderObject) -> Float? {
        assert(child.parent === self)
        return beforePadding
    }

    public override func applyPaintTransform(_ child: RenderObject, transform: inout Matrix4x4f) {
        assert(child === self.child)
        let childParentData = child.parentData! as! SliverPhysicalParentData
        childParentData.applyPaintTransform(&transform)
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        if let child, child.geometry!.visible {
            let childParentData = child.parentData! as! SliverPhysicalParentData
            context.paintChild(child, offset: offset + childParentData.paintOffset)
        }
    }
}

/// Insets a [RenderSliver], applying padding on each side.
///
/// A [RenderSliverPadding] object wraps the [SliverGeometry.layoutExtent] of
/// its child. Any incoming [SliverConstraints.overlap] is ignored and not
/// passed on to the child.
public class RenderSliverPadding: RenderSliverEdgeInsetsPadding {
    /// Creates a render object that insets its child in a viewport.
    ///
    /// The [padding] argument must have non-negative insets.
    public init(
        padding: EdgeInsetsGeometry,
        textDirection: TextDirection? = nil,
        child: RenderSliver? = nil
    ) {
        assert(padding.isNonNegative)
        self.padding = padding
        self.textDirection = textDirection
        super.init()
        self.child = child
    }

    public override var resolvedPadding: EdgeInsets? {
        return _resolvedPadding
    }
    private var _resolvedPadding: EdgeInsets?

    private func _resolve() {
        if resolvedPadding != nil {
            return
        }
        _resolvedPadding = padding.resolve(textDirection)
        assert(resolvedPadding!.isNonNegative)
    }

    private func _markNeedsResolution() {
        _resolvedPadding = nil
        markNeedsLayout()
    }

    /// The amount to pad the child in each dimension.
    ///
    /// If this is set to an [EdgeInsetsDirectional] object, then [textDirection]
    /// must not be null.
    public var padding: EdgeInsetsGeometry {
        didSet {
            assert(padding.isNonNegative)
            if padding.isEqualTo(oldValue) {
                return
            }
            _markNeedsResolution()
        }
    }

    /// The text direction with which to resolve [padding].
    ///
    /// This may be changed to null, but only after the [padding] has been changed
    /// to a value that does not depend on the direction.
    public var textDirection: TextDirection? {
        didSet {
            if textDirection == oldValue {
                return
            }
            _markNeedsResolution()
        }
    }

    public override func performLayout() {
        _resolve()
        super.performLayout()
    }
}
