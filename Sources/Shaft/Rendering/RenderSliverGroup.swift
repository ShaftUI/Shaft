import SwiftMath

/// A sliver that places multiple sliver children in a linear array along the cross
/// axis.
///
/// Since the extent of the viewport in the cross axis direction is finite,
/// this extent will be divided up and allocated to the children slivers.
///
/// The algorithm for dividing up the cross axis extent is as follows.
/// Every widget has a [SliverPhysicalParentData.crossAxisFlex] value associated with them.
/// First, lay out all of the slivers with flex of 0 or null, in which case the slivers themselves will
/// figure out how much cross axis extent to take up. For example, [SliverConstrainedCrossAxis]
/// is an example of a widget which sets its own flex to 0. Then [RenderSliverCrossAxisGroup] will
/// divide up the remaining space to all the remaining children proportionally
/// to each child's flex factor. By default, children of [SliverCrossAxisGroup]
/// are setup to have a flex factor of 1, but a different flex factor can be
/// specified via the [SliverCrossAxisExpanded] widgets.
// class RenderSliverCrossAxisGroup extends RenderSliver with ContainerRenderObjectMixin<RenderSliver, SliverPhysicalContainerParentData> {
public class RenderSliverCrossAxisGroup: RenderSliver, RenderObjectWithChildren {
    public typealias ChildType = RenderSliver
    public typealias ParentDataType = SliverPhysicalContainerParentData
    public var childMixin = RenderContainerMixin<RenderSliver>()

    public override func setupParentData(_ child: RenderObject) {
        if !(child.parentData is SliverPhysicalContainerParentData) {
            child.parentData = SliverPhysicalContainerParentData()
            (child.parentData as! SliverPhysicalParentData).crossAxisFlex = 1
        }
    }

    public override func childMainAxisPosition(_ child: RenderObject) -> Float {
        return 0.0
    }

    public override func childCrossAxisPosition(_ child: RenderObject) -> Float {
        let paintOffset = (child.parentData as! SliverPhysicalParentData).paintOffset
        switch sliverConstraints.axis {
        case .vertical:
            return paintOffset.dx
        case .horizontal:
            return paintOffset.dy
        }
    }

    public override func performLayout() {
        let constraints = sliverConstraints

        // Iterate through each sliver.
        // Get the parent's dimensions.
        let crossAxisExtent = constraints.crossAxisExtent
        assert(crossAxisExtent.isFinite)

        // First, layout each child with flex == 0 or null.
        var totalFlex = 0
        var remainingExtent = crossAxisExtent
        var child = firstChild
        while child != nil {
            let childParentData = child!.parentData as! SliverPhysicalParentData
            let flex = childParentData.crossAxisFlex ?? 0
            if flex == 0 {
                // If flex is 0 or null, then the child sliver must provide their own crossAxisExtent.
                assert(_assertOutOfExtent(remainingExtent))
                child!.layout(
                    constraints.copyWith(crossAxisExtent: remainingExtent),
                    parentUsesSize: true
                )
                let childCrossAxisExtent = child!.geometry!.crossAxisExtent
                assert(childCrossAxisExtent != nil)
                remainingExtent = max(0.0, remainingExtent - childCrossAxisExtent!)
            } else {
                totalFlex += flex
            }
            child = childAfter(child!)
        }
        let extentPerFlexValue = remainingExtent / Float(totalFlex)

        child = firstChild

        // At this point, all slivers with constrained cross axis should already be laid out.
        // Layout the rest and keep track of the child geometry with greatest scrollExtent.
        geometry = SliverGeometry.zero
        while child != nil {
            let childParentData = child!.parentData as! SliverPhysicalParentData
            let flex = childParentData.crossAxisFlex ?? 0
            var childExtent: Float
            if flex != 0 {
                childExtent = extentPerFlexValue * Float(flex)
                assert(_assertOutOfExtent(childExtent))
                child!.layout(
                    constraints.copyWith(
                        crossAxisExtent: extentPerFlexValue * Float(flex)
                    ),
                    parentUsesSize: true
                )
            } else {
                childExtent = child!.geometry!.crossAxisExtent!
            }
            let childLayoutGeometry = child!.geometry!
            if geometry!.scrollExtent < childLayoutGeometry.scrollExtent {
                geometry = childLayoutGeometry
            }
            child = childAfter(child!)
        }

        // Go back and correct any slivers using a negative paint offset if it tries
        // to paint outside the bounds of the sliver group.
        child = firstChild
        var offset: Float = 0.0
        while child != nil {
            let childParentData = child!.parentData as! SliverPhysicalParentData
            let childLayoutGeometry = child!.geometry!
            let remainingExtent = geometry!.scrollExtent - constraints.scrollOffset
            let paintCorrection =
                childLayoutGeometry.paintExtent > remainingExtent
                ? childLayoutGeometry.paintExtent - remainingExtent
                : 0.0
            let childExtent =
                child!.geometry!.crossAxisExtent ?? extentPerFlexValue
                * Float(childParentData.crossAxisFlex ?? 0)
            // Set child parent data.
            childParentData.paintOffset =
                switch constraints.axis {
                case .vertical:
                    Offset(offset, -paintCorrection)
                case .horizontal:
                    Offset(-paintCorrection, offset)
                }
            offset += childExtent
            child = childAfter(child!)
        }
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        var child = firstChild

        while child != nil {
            if child!.geometry!.visible {
                let childParentData = child!.parentData as! SliverPhysicalParentData
                context.paintChild(child!, offset: offset + childParentData.paintOffset)
            }
            child = childAfter(child!)
        }
    }

    public override func applyPaintTransform(
        _ child: RenderObject,
        transform: inout Matrix4x4f
    ) {
        let childParentData = child.parentData as! SliverPhysicalParentData
        childParentData.applyPaintTransform(&transform)
    }

    public override func hitTestChildren(
        _ result: SliverHitTestResult,
        mainAxisPosition: Float,
        crossAxisPosition: Float
    ) -> Bool {
        var child = lastChild
        while child != nil {
            let isHit = result.addWithAxisOffset(
                paintOffset: nil,
                mainAxisOffset: childMainAxisPosition(child!),
                crossAxisOffset: childCrossAxisPosition(child!),
                mainAxisPosition: mainAxisPosition,
                crossAxisPosition: crossAxisPosition,
                hitTest: child!.hitTest
            )
            if isHit {
                return true
            }
            child = childBefore(child!)
        }
        return false
    }
}

private func _assertOutOfExtent(_ extent: Float) -> Bool {
    if extent <= 0.0 {
        preconditionFailure(
            """
            SliverCrossAxisGroup ran out of extent before child could be laid out.
              
            SliverCrossAxisGroup lays out any slivers with a constrained cross \
            axis before laying out those which expand. In this case, cross axis \
            extent was used up before the next sliver could be laid out.
              
            Make sure that the total amount of extent allocated by constrained \
            child slivers does not exceed the cross axis extent that is available \
            for the SliverCrossAxisGroup.
            """
        )
    }
    return true
}

/// A sliver that places multiple sliver children in a linear array along the
/// main axis.
///
/// The layout algorithm lays out slivers one by one. If the sliver is at the top
/// of the viewport or above the top, then we pass in a nonzero [SliverConstraints.scrollOffset]
/// to inform the sliver at what point along the main axis we should start layout.
/// For the slivers that come after it, we compute the amount of space taken up so
/// far to be used as the [SliverPhysicalParentData.paintOffset] and the
/// [SliverConstraints.remainingPaintExtent] to be passed in as a constraint.
///
/// Finally, this sliver will also ensure that all child slivers are painted within
/// the total scroll extent of the group by adjusting the child's
/// [SliverPhysicalParentData.paintOffset] as necessary. This can happen for
/// slivers such as [SliverPersistentHeader] which, when pinned, positions itself
/// at the top of the [Viewport] regardless of the scroll offset.
public class RenderSliverMainAxisGroup: RenderSliver, RenderObjectWithChildren {
    public typealias ChildType = RenderSliver
    public typealias ParentDataType = SliverPhysicalContainerParentData
    public var childMixin = RenderContainerMixin<RenderSliver>()

    public override func setupParentData(_ child: RenderObject) {
        if !(child.parentData is SliverPhysicalContainerParentData) {
            child.parentData = SliverPhysicalContainerParentData()
        }
    }

    public override func childScrollOffset(_ child: RenderObject) -> Float? {
        assert(child.parent === self)
        let growthDirection = sliverConstraints.growthDirection
        switch growthDirection {
        case .forward:
            var childScrollOffset: Float = 0.0
            var current = childBefore(child as! RenderSliver)
            while current != nil {
                childScrollOffset += current!.geometry!.scrollExtent
                current = childBefore(current!)
            }
            return childScrollOffset
        case .reverse:
            var childScrollOffset: Float = 0.0
            var current = childAfter(child as! RenderSliver)
            while current != nil {
                childScrollOffset -= current!.geometry!.scrollExtent
                current = childAfter(current!)
            }
            return childScrollOffset
        }
    }

    public override func childMainAxisPosition(_ child: RenderObject) -> Float {
        let paintOffset = (child.parentData as! SliverPhysicalParentData).paintOffset
        switch sliverConstraints.axis {
        case .horizontal:
            return paintOffset.dx
        case .vertical:
            return paintOffset.dy
        }
    }

    public override func childCrossAxisPosition(_ child: RenderObject) -> Float {
        return 0.0
    }

    public override func performLayout() {
        let constraints = sliverConstraints

        var offset: Float = 0
        var maxPaintExtent: Float = 0

        var child = firstChild

        while child != nil {
            let beforeOffsetPaintExtent = calculatePaintOffset(
                constraints,
                from: 0.0,
                to: offset
            )
            child!.layout(
                constraints.copyWith(
                    scrollOffset: max(0.0, constraints.scrollOffset - offset),
                    precedingScrollExtent: offset + constraints.precedingScrollExtent,
                    overlap: max(0.0, constraints.overlap - beforeOffsetPaintExtent),
                    remainingPaintExtent: constraints.remainingPaintExtent
                        - beforeOffsetPaintExtent,
                    remainingCacheExtent: constraints.remainingCacheExtent
                        - calculateCacheOffset(constraints, from: 0.0, to: offset),
                    cacheOrigin: min(0.0, constraints.cacheOrigin + offset)
                ),
                parentUsesSize: true
            )
            let childLayoutGeometry = child!.geometry!
            let childParentData = child!.parentData as! SliverPhysicalParentData
            childParentData.paintOffset =
                switch constraints.axis {
                case .vertical: Offset(0.0, beforeOffsetPaintExtent)
                case .horizontal: Offset(beforeOffsetPaintExtent, 0.0)
                }
            offset += childLayoutGeometry.scrollExtent
            maxPaintExtent += child!.geometry!.maxPaintExtent
            child = childAfter(child!)
            assert {
                if child != nil && maxPaintExtent.isInfinite {
                    preconditionFailure(
                        "Unreachable sliver found, you may have a sliver following "
                            + "a sliver with an infinite extent. "
                    )
                }
                return true
            }
        }

        let totalScrollExtent = offset
        offset = 0.0
        child = firstChild
        // Second pass to correct out of bound paintOffsets.
        while child != nil {
            let beforeOffsetPaintExtent = calculatePaintOffset(
                constraints,
                from: 0.0,
                to: offset
            )
            let childLayoutGeometry = child!.geometry!
            let childParentData = child!.parentData as! SliverPhysicalParentData
            let remainingExtent = totalScrollExtent - constraints.scrollOffset
            if childLayoutGeometry.paintExtent > remainingExtent {
                let paintCorrection = childLayoutGeometry.paintExtent - remainingExtent
                childParentData.paintOffset =
                    switch constraints.axis {
                    case .vertical:
                        Offset(0.0, beforeOffsetPaintExtent - paintCorrection)
                    case .horizontal:
                        Offset(beforeOffsetPaintExtent - paintCorrection, 0.0)
                    }
            }
            offset += child!.geometry!.scrollExtent
            child = childAfter(child!)
        }

        let paintExtent = calculatePaintOffset(
            constraints,
            from: min(constraints.scrollOffset, 0),
            to: totalScrollExtent
        )
        let cacheExtent = calculateCacheOffset(
            constraints,
            from: min(constraints.scrollOffset, 0),
            to: totalScrollExtent
        )
        geometry = SliverGeometry(
            scrollExtent: totalScrollExtent,
            paintExtent: paintExtent,
            maxPaintExtent: maxPaintExtent,
            hasVisualOverflow: totalScrollExtent > constraints.remainingPaintExtent
                || constraints.scrollOffset > 0.0,
            cacheExtent: cacheExtent
        )
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        let constraints = sliverConstraints

        if firstChild == nil {
            return
        }
        // offset is to the top-left corner, regardless of our axis direction.
        // originOffset gives us the delta from the real origin to the origin in the axis direction.
        let mainAxisUnit: Offset
        let crossAxisUnit: Offset
        let originOffset: Offset
        let addExtent: Bool
        switch applyGrowthDirectionToAxisDirection(
            constraints.axisDirection,
            constraints.growthDirection
        ) {
        case .up:
            mainAxisUnit = Offset(0.0, -1.0)
            crossAxisUnit = Offset(1.0, 0.0)
            originOffset = offset + Offset(0.0, geometry!.paintExtent)
            addExtent = true
        case .right:
            mainAxisUnit = Offset(1.0, 0.0)
            crossAxisUnit = Offset(0.0, 1.0)
            originOffset = offset
            addExtent = false
        case .down:
            mainAxisUnit = Offset(0.0, 1.0)
            crossAxisUnit = Offset(1.0, 0.0)
            originOffset = offset
            addExtent = false
        case .left:
            mainAxisUnit = Offset(-1.0, 0.0)
            crossAxisUnit = Offset(0.0, 1.0)
            originOffset = offset + Offset(geometry!.paintExtent, 0.0)
            addExtent = true
        }

        var child = lastChild
        while child != nil {
            let mainAxisDelta = childMainAxisPosition(child!)
            let crossAxisDelta = childCrossAxisPosition(child!)
            var childOffset = Offset(
                originOffset.dx + mainAxisUnit.dx * mainAxisDelta + crossAxisUnit.dx
                    * crossAxisDelta,
                originOffset.dy + mainAxisUnit.dy * mainAxisDelta + crossAxisUnit.dy
                    * crossAxisDelta
            )
            if addExtent {
                childOffset = childOffset + mainAxisUnit * child!.geometry!.paintExtent
            }

            if child!.geometry!.visible {
                context.paintChild(child!, offset: childOffset)
            }
            child = childBefore(child!)
        }
    }

    public override func applyPaintTransform(_ child: RenderObject, transform: inout Matrix4x4f) {
        let childParentData = child.parentData as! SliverPhysicalParentData
        childParentData.applyPaintTransform(&transform)
    }

    public override func hitTestChildren(
        _ result: SliverHitTestResult,
        mainAxisPosition: Float,
        crossAxisPosition: Float
    ) -> Bool {
        var child = firstChild
        while child != nil {
            let isHit = result.addWithAxisOffset(
                paintOffset: nil,
                mainAxisOffset: childMainAxisPosition(child!),
                crossAxisOffset: childCrossAxisPosition(child!),
                mainAxisPosition: mainAxisPosition,
                crossAxisPosition: crossAxisPosition,
                hitTest: child!.hitTest
            )
            if isHit {
                return true
            }
            child = childAfter(child!)
        }
        return false
    }

    // public override func visitChildrenForSemantics(_ visitor: RenderObjectVisitor) {
    //     var child = firstChild
    //     while child != nil {
    //         if child!.geometry!.visible {
    //             visitor(child!)
    //         }
    //         child = childAfter(child!)
    //     }
    // }
}
