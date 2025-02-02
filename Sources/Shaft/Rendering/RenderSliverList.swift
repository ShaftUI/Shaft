/// A sliver that places multiple box children in a linear array along the main
/// axis.
///
/// Each child is forced to have the [SliverConstraints.crossAxisExtent] in the
/// cross axis but determines its own main axis extent.
///
/// [RenderSliverList] determines its scroll offset by "dead reckoning" because
/// children outside the visible part of the sliver are not materialized, which
/// means [RenderSliverList] cannot learn their main axis extent. Instead, newly
/// materialized children are placed adjacent to existing children. If this dead
/// reckoning results in a logical inconsistency (e.g., attempting to place the
/// zeroth child at a scroll offset other than zero), the [RenderSliverList]
/// generates a [SliverGeometry.scrollOffsetCorrection] to restore consistency.
///
/// If the children have a fixed extent in the main axis, consider using
/// [RenderSliverFixedExtentList] rather than [RenderSliverList] because
/// [RenderSliverFixedExtentList] does not need to perform layout on its
/// children to obtain their extent in the main axis and is therefore more
/// efficient.
///
/// See also:
///
///  * [RenderSliverFixedExtentList], which is more efficient for children with
///    the same extent in the main axis.
///  * [RenderSliverGrid], which places its children in arbitrary positions.
public class RenderSliverList: RenderSliverMultiBoxAdaptor {
    public override func performLayout() {
        let constraints = self.sliverConstraints
        childManager.didStartLayout()
        childManager.setDidUnderflow(false)

        let scrollOffset = constraints.scrollOffset + constraints.cacheOrigin
        assert(scrollOffset >= 0.0)
        let remainingExtent = constraints.remainingCacheExtent
        assert(remainingExtent >= 0.0)
        let targetEndScrollOffset = scrollOffset + remainingExtent
        let childConstraints = constraints.asBoxConstraints()
        var leadingGarbage = 0
        var trailingGarbage = 0
        var reachedEnd = false

        // This algorithm in principle is straight-forward: find the first child
        // that overlaps the given scrollOffset, creating more children at the top
        // of the list if necessary, then walk down the list updating and laying out
        // each child and adding more at the end if necessary until we have enough
        // children to cover the entire viewport.
        //
        // It is complicated by one minor issue, which is that any time you update
        // or create a child, it's possible that the some of the children that
        // haven't yet been laid out will be removed, leaving the list in an
        // inconsistent state, and requiring that missing nodes be recreated.
        //
        // To keep this mess tractable, this algorithm starts from what is currently
        // the first child, if any, and then walks up and/or down from there, so
        // that the nodes that might get removed are always at the edges of what has
        // already been laid out.

        // Make sure we have at least one child to start from.
        if firstChild == nil {
            if !addInitialChild() {
                // There are no children.
                geometry = SliverGeometry.zero
                childManager.didFinishLayout()
                return
            }
        }

        // We have at least one child.

        // These variables track the range of children that we have laid out. Within
        // this range, the children have consecutive indices. Outside this range,
        // it's possible for a child to get removed without notice.
        var leadingChildWithLayout: RenderBox?
        var trailingChildWithLayout: RenderBox?

        var earliestUsefulChild = firstChild

        // A firstChild with null layout offset is likely a result of children
        // reordering.
        //
        // We rely on firstChild to have accurate layout offset. In the case of null
        // layout offset, we have to find the first child that has valid layout
        // offset.
        if childScrollOffset(firstChild!) == nil {
            var leadingChildrenWithoutLayoutOffset = 0
            while earliestUsefulChild != nil && childScrollOffset(earliestUsefulChild!) == nil {
                earliestUsefulChild = childAfter(earliestUsefulChild!)
                leadingChildrenWithoutLayoutOffset += 1
            }
            // We should be able to destroy children with null layout offset safely,
            // because they are likely outside of viewport
            collectGarbage(leadingChildrenWithoutLayoutOffset, 0)
            // If can not find a valid layout offset, start from the initial child.
            if firstChild == nil {
                if !addInitialChild() {
                    // There are no children.
                    geometry = SliverGeometry.zero
                    childManager.didFinishLayout()
                    return
                }
            }
        }

        // Find the last child that is at or before the scrollOffset.
        earliestUsefulChild = firstChild
        var earliestScrollOffset = childScrollOffset(earliestUsefulChild!)!
        while earliestScrollOffset > scrollOffset {
            // We have to add children before the earliestUsefulChild.
            earliestUsefulChild = insertAndLayoutLeadingChild(
                childConstraints,
                parentUsesSize: true
            )
            if earliestUsefulChild == nil {
                let childParentData = firstChild!.parentData as! SliverMultiBoxAdaptorParentData
                childParentData.layoutOffset = 0.0

                if scrollOffset == 0.0 {
                    // insertAndLayoutLeadingChild only lays out the children before
                    // firstChild. In this case, nothing has been laid out. We have
                    // to lay out firstChild manually.
                    firstChild!.layout(childConstraints, parentUsesSize: true)
                    earliestUsefulChild = firstChild
                    leadingChildWithLayout = earliestUsefulChild
                    trailingChildWithLayout = trailingChildWithLayout ?? earliestUsefulChild
                    break
                } else {
                    // We ran out of children before reaching the scroll offset.
                    // We must inform our parent that this sliver cannot fulfill
                    // its contract and that we need a scroll offset correction.
                    geometry = SliverGeometry(scrollOffsetCorrection: -scrollOffset)
                    return
                }
            }

            let firstChildScrollOffset = earliestScrollOffset - paintExtentOf(firstChild!)
            // firstChildScrollOffset may contain double precision error
            if firstChildScrollOffset < -precisionErrorTolerance {
                // Let's assume there is no child before the first child. We will
                // correct it on the next layout if it is not.
                geometry = SliverGeometry(scrollOffsetCorrection: -firstChildScrollOffset)
                let childParentData = firstChild!.parentData as! SliverMultiBoxAdaptorParentData
                childParentData.layoutOffset = 0.0
                return
            }

            let childParentData =
                earliestUsefulChild!.parentData as! SliverMultiBoxAdaptorParentData
            childParentData.layoutOffset = firstChildScrollOffset
            assert(earliestUsefulChild === firstChild)
            leadingChildWithLayout = earliestUsefulChild
            trailingChildWithLayout = trailingChildWithLayout ?? earliestUsefulChild
            earliestScrollOffset = childScrollOffset(earliestUsefulChild!)!
        }

        assert(childScrollOffset(firstChild!)! > -precisionErrorTolerance)

        // If the scroll offset is at zero, we should make sure we are
        // actually at the beginning of the list.
        if scrollOffset < precisionErrorTolerance {
            // We iterate from the firstChild in case the leading child has a 0 paint
            // extent.
            while indexOf(firstChild!) > 0 {
                let earliestScrollOffset = childScrollOffset(firstChild!)!
                // We correct one child at a time. If there are more children before
                // the earliestUsefulChild, we will correct it once the scroll offset
                // reaches zero again.
                earliestUsefulChild = insertAndLayoutLeadingChild(
                    childConstraints,
                    parentUsesSize: true
                )
                assert(earliestUsefulChild != nil)
                let firstChildScrollOffset = earliestScrollOffset - paintExtentOf(firstChild!)
                let childParentData = firstChild!.parentData as! SliverMultiBoxAdaptorParentData
                childParentData.layoutOffset = 0.0
                // We only need to correct if the leading child actually has a
                // paint extent.
                if firstChildScrollOffset < -precisionErrorTolerance {
                    geometry = SliverGeometry(scrollOffsetCorrection: -firstChildScrollOffset)
                    return
                }
            }
        }

        // At this point, earliestUsefulChild is the first child, and is a child
        // whose scrollOffset is at or before the scrollOffset, and
        // leadingChildWithLayout and trailingChildWithLayout are either null or
        // cover a range of render boxes that we have laid out with the first being
        // the same as earliestUsefulChild and the last being either at or after the
        // scroll offset.

        assert(earliestUsefulChild === firstChild)
        assert(childScrollOffset(earliestUsefulChild!)! <= scrollOffset)

        // Make sure we've laid out at least one child.
        if leadingChildWithLayout == nil {
            earliestUsefulChild!.layout(childConstraints, parentUsesSize: true)
            leadingChildWithLayout = earliestUsefulChild
            trailingChildWithLayout = earliestUsefulChild
        }

        // Here, earliestUsefulChild is still the first child, it's got a
        // scrollOffset that is at or before our actual scrollOffset, and it has
        // been laid out, and is in fact our leadingChildWithLayout. It's possible
        // that some children beyond that one have also been laid out.

        var inLayoutRange = true
        var child = earliestUsefulChild
        var index = indexOf(child!)
        var endScrollOffset = childScrollOffset(child!)! + paintExtentOf(child!)

        func advance() -> Bool {  // returns true if we advanced, false if we have no more children
            // This function is used in two different places below, to avoid code duplication.
            assert(child != nil)
            if child === trailingChildWithLayout {
                inLayoutRange = false
            }
            child = childAfter(child!)
            if child == nil {
                inLayoutRange = false
            }
            index += 1
            if !inLayoutRange {
                if child == nil || indexOf(child!) != index {
                    // We are missing a child. Insert it (and lay it out) if possible.
                    child = insertAndLayoutChild(
                        childConstraints,
                        after: trailingChildWithLayout,
                        parentUsesSize: true
                    )
                    if child == nil {
                        // We have run out of children.
                        return false
                    }
                } else {
                    // Lay out the child.
                    child!.layout(childConstraints, parentUsesSize: true)
                }
                trailingChildWithLayout = child
            }
            assert(child != nil)
            let childParentData = child!.parentData as! SliverMultiBoxAdaptorParentData
            childParentData.layoutOffset = endScrollOffset
            assert(childParentData.index == index)
            endScrollOffset = childScrollOffset(child!)! + paintExtentOf(child!)
            return true
        }

        // Find the first child that ends after the scroll offset.
        while endScrollOffset < scrollOffset {
            leadingGarbage += 1
            if !advance() {
                assert(leadingGarbage == childCount)
                assert(child == nil)
                // we want to make sure we keep the last child around so we know the end scroll offset
                collectGarbage(leadingGarbage - 1, 0)
                assert(firstChild === lastChild)
                let extent = childScrollOffset(lastChild!)! + paintExtentOf(lastChild!)
                geometry = SliverGeometry(
                    scrollExtent: extent,
                    maxPaintExtent: extent
                )
                return
            }
        }

        // Now find the first child that ends after our end.
        while endScrollOffset < targetEndScrollOffset {
            if !advance() {
                reachedEnd = true
                break
            }
        }

        // Finally count up all the remaining children and label them as garbage.
        if child != nil {
            child = childAfter(child!)
            while child != nil {
                trailingGarbage += 1
                child = childAfter(child!)
            }
        }

        // At this point everything should be good to go, we just have to clean up
        // the garbage and report the geometry.

        collectGarbage(leadingGarbage, trailingGarbage)

        assert(debugAssertChildListIsNonEmptyAndContiguous())
        let estimatedMaxScrollOffset: Float
        if reachedEnd {
            estimatedMaxScrollOffset = endScrollOffset
        } else {
            estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
                constraints,
                firstIndex: indexOf(firstChild!),
                lastIndex: indexOf(lastChild!),
                leadingScrollOffset: childScrollOffset(firstChild!),
                trailingScrollOffset: endScrollOffset
            )
            assert(estimatedMaxScrollOffset >= endScrollOffset - childScrollOffset(firstChild!)!)
        }
        let paintExtent = calculatePaintOffset(
            constraints,
            from: childScrollOffset(firstChild!)!,
            to: endScrollOffset
        )
        let cacheExtent = calculateCacheOffset(
            constraints,
            from: childScrollOffset(firstChild!)!,
            to: endScrollOffset
        )
        let targetEndScrollOffsetForPaint =
            constraints.scrollOffset + constraints.remainingPaintExtent
        geometry = SliverGeometry(
            scrollExtent: estimatedMaxScrollOffset,
            paintExtent: paintExtent,
            maxPaintExtent: estimatedMaxScrollOffset,
            // Conservative to avoid flickering away the clip during scroll.
            hasVisualOverflow: endScrollOffset > targetEndScrollOffsetForPaint
                || constraints.scrollOffset > 0.0,
            cacheExtent: cacheExtent
        )

        // We may have started the layout while scrolled to the end, which would not
        // expose a new child.
        if estimatedMaxScrollOffset == endScrollOffset {
            childManager.setDidUnderflow(true)
        }
        childManager.didFinishLayout()
    }
}

/// A sliver that contains multiple box children that have the explicit extent in
/// the main axis.
///
/// [RenderSliverFixedExtentBoxAdaptor] places its children in a linear array
/// along the main axis. Each child is forced to have the returned value of [itemExtentBuilder]
/// when the [itemExtentBuilder] is non-null or the [itemExtent] when [itemExtentBuilder]
/// is null in the main axis and the [SliverConstraints.crossAxisExtent] in the cross axis.
///
/// Subclasses should override [itemExtent] or [itemExtentBuilder] to control
/// the size of the children in the main axis. For a concrete subclass with a
/// configurable [itemExtent], see [RenderSliverFixedExtentList] or [RenderSliverVariedExtentList].
///
/// [RenderSliverFixedExtentBoxAdaptor] is more efficient than
/// [RenderSliverList] because [RenderSliverFixedExtentBoxAdaptor] does not need
/// to perform layout on its children to obtain their extent in the main axis.
///
/// See also:
///
///  * [RenderSliverFixedExtentList], which has a configurable [itemExtent].
///  * [RenderSliverFillViewport], which determines the [itemExtent] based on
///    [SliverConstraints.viewportMainAxisExtent].
///  * [RenderSliverFillRemaining], which determines the [itemExtent] based on
///    [SliverConstraints.remainingPaintExtent].
///  * [RenderSliverList], which does not require its children to have the same
///    extent in the main axis.
public class RenderSliverFixedExtentBoxAdaptor: RenderSliverMultiBoxAdaptor {
    /// The main-axis extent of each item.
    ///
    /// If this is non-null, the [itemExtentBuilder] must be null.
    /// If this is null, the [itemExtentBuilder] must be non-null.
    public var itemExtent: Float? {
        shouldImplement()
    }

    /// The main-axis extent builder of each item.
    ///
    /// If this is non-null, the [itemExtent] must be null.
    /// If this is null, the [itemExtent] must be non-null.
    public var itemExtentBuilder: ItemExtentBuilder? {
        return nil
    }

    /// The layout offset for the child with the given index.
    ///
    /// This function uses the returned value of [itemExtentBuilder] or the
    /// [itemExtent] to avoid recomputing item size repeatedly during layout.
    ///
    /// By default, places the children in order, without gaps, starting from
    /// layout offset zero.
    public func indexToLayoutOffset(_ itemExtent: Float, _ index: Int) -> Float {
        if itemExtentBuilder == nil {
            let extent = self.itemExtent!
            return extent * Float(index)
        } else {
            var offset: Float = 0.0
            var extent: Float?
            for i in 0..<index {
                let childCount = childManager.estimatedChildCount
                if let count = childCount, i > count - 1 {
                    break
                }
                extent = itemExtentBuilder!(i, _currentLayoutDimensions)
                if extent == nil {
                    break
                }
                offset += extent!
            }
            return offset
        }
    }

    /// The minimum child index that is visible at the given scroll offset.
    ///
    /// This function uses the returned value of [itemExtentBuilder] or the
    /// [itemExtent] to avoid recomputing item size repeatedly during layout.
    ///
    /// By default, returns a value consistent with the children being placed in
    /// order, without gaps, starting from layout offset zero.
    public func getMinChildIndexForScrollOffset(_ scrollOffset: Float, _ itemExtent: Float) -> Int {
        if itemExtentBuilder == nil {
            let extent = self.itemExtent!
            if extent > 0.0 {
                let actual = scrollOffset / extent
                let round = actual.rounded()
                if abs(actual * extent - round * extent) < precisionErrorTolerance {
                    return Int(round)
                }
                return Int(actual.rounded(.down))
            }
            return 0
        } else {
            return _getChildIndexForScrollOffset(scrollOffset, itemExtentBuilder!)
        }
    }

    /// The maximum child index that is visible at the given scroll offset.
    ///
    /// This function uses the returned value of [itemExtentBuilder] or the
    /// [itemExtent] to avoid recomputing item size repeatedly during layout.
    ///
    /// By default, returns a value consistent with the children being placed in
    /// order, without gaps, starting from layout offset zero.
    public func getMaxChildIndexForScrollOffset(_ scrollOffset: Float, _ itemExtent: Float) -> Int {
        if itemExtentBuilder == nil {
            let extent = self.itemExtent!
            if extent > 0.0 {
                let actual = scrollOffset / extent - 1
                let round = actual.rounded()
                if abs(actual * extent - round * extent) < precisionErrorTolerance {
                    return max(0, Int(round))
                }
                return max(0, Int(actual.rounded(.up)))
            }
            return 0
        } else {
            return _getChildIndexForScrollOffset(scrollOffset, itemExtentBuilder!)
        }
    }

    /// Called to estimate the total scrollable extents of this object.
    ///
    /// Must return the total distance from the start of the child with the
    /// earliest possible index to the end of the child with the last possible
    /// index.
    ///
    /// By default, defers to [RenderSliverBoxChildManager.estimateMaxScrollOffset].
    ///
    /// See also:
    ///
    ///  * [computeMaxScrollOffset], which is similar but must provide a precise
    ///    value.
    public func estimateMaxScrollOffset(
        _ constraints: SliverConstraints,
        firstIndex: Int? = nil,
        lastIndex: Int? = nil,
        leadingScrollOffset: Float? = nil,
        trailingScrollOffset: Float? = nil
    ) -> Float {
        return childManager.estimateMaxScrollOffset(
            constraints,
            firstIndex: firstIndex,
            lastIndex: lastIndex,
            leadingScrollOffset: leadingScrollOffset,
            trailingScrollOffset: trailingScrollOffset
        )
    }

    /// Called to obtain a precise measure of the total scrollable extents of this
    /// object.
    ///
    /// Must return the precise total distance from the start of the child with
    /// the earliest possible index to the end of the child with the last possible
    /// index.
    ///
    /// This is used when no child is available for the index corresponding to the
    /// current scroll offset, to determine the precise dimensions of the sliver.
    /// It must return a precise value. It will not be called if the
    /// [childManager] returns an infinite number of children for positive
    /// indices.
    ///
    /// If [itemExtentBuilder] is null, multiplies the [itemExtent] by the number
    /// of children reported by [RenderSliverBoxChildManager.childCount].
    /// If [itemExtentBuilder] is non-null, sum the extents of the first
    /// [RenderSliverBoxChildManager.childCount] children.
    ///
    /// See also:
    ///
    ///  * [estimateMaxScrollOffset], which is similar but may provide inaccurate
    ///    values.
    public func computeMaxScrollOffset(
        _ constraints: SliverConstraints,
        itemExtent: Float  // Deprecated: The itemExtent is already available within the scope of this function
    ) -> Float {
        if itemExtentBuilder == nil {
            let extent = self.itemExtent!
            return Float(childManager.childCount) * extent
        } else {
            var offset: Float = 0.0
            var extent: Float?
            for i in 0..<childManager.childCount {
                extent = itemExtentBuilder!(i, _currentLayoutDimensions)
                if extent == nil {
                    break
                }
                offset += extent!
            }
            return offset
        }
    }

    func _getChildIndexForScrollOffset(_ scrollOffset: Float, _ callback: ItemExtentBuilder) -> Int
    {
        if scrollOffset == 0.0 {
            return 0
        }
        var position: Float = 0.0
        var index = 0
        var itemExtent: Float?
        while position < scrollOffset {
            let childCount = childManager.estimatedChildCount
            if let count = childCount, index > count - 1 {
                break
            }
            itemExtent = callback(index, _currentLayoutDimensions)
            if itemExtent == nil {
                break
            }
            position += itemExtent!
            index += 1
        }
        return index - 1
    }

    func _getChildConstraints(_ index: Int) -> BoxConstraints {
        let extent: Float
        if itemExtentBuilder == nil {
            extent = itemExtent!
        } else {
            extent = itemExtentBuilder!(index, _currentLayoutDimensions)!
        }
        return sliverConstraints.asBoxConstraints(
            minExtent: extent,
            maxExtent: extent
        )
    }

    private var _currentLayoutDimensions: SliverLayoutDimensions!

    public override func performLayout() {
        assert(
            (itemExtent != nil && itemExtentBuilder == nil)
                || (itemExtent == nil && itemExtentBuilder != nil)
        )
        assert(itemExtentBuilder != nil || (itemExtent!.isFinite && itemExtent! >= 0))

        let constraints = self.sliverConstraints
        childManager.didStartLayout()
        childManager.setDidUnderflow(false)

        let scrollOffset = constraints.scrollOffset + constraints.cacheOrigin
        assert(scrollOffset >= 0.0)
        let remainingExtent = constraints.remainingCacheExtent
        assert(remainingExtent >= 0.0)
        let targetEndScrollOffset = scrollOffset + remainingExtent

        _currentLayoutDimensions = SliverLayoutDimensions(
            scrollOffset: constraints.scrollOffset,
            precedingScrollExtent: constraints.precedingScrollExtent,
            viewportMainAxisExtent: constraints.viewportMainAxisExtent,
            crossAxisExtent: constraints.crossAxisExtent
        )
        // TODO(Piinks): Clean up when deprecation expires.
        let deprecatedExtraItemExtent: Float = -1

        let firstIndex = getMinChildIndexForScrollOffset(scrollOffset, deprecatedExtraItemExtent)
        let targetLastIndex =
            targetEndScrollOffset.isFinite
            ? getMaxChildIndexForScrollOffset(targetEndScrollOffset, deprecatedExtraItemExtent)
            : nil

        if firstChild != nil {
            let leadingGarbage = calculateLeadingGarbage(firstIndex: firstIndex)
            let trailingGarbage =
                targetLastIndex != nil ? calculateTrailingGarbage(lastIndex: targetLastIndex!) : 0
            collectGarbage(leadingGarbage, trailingGarbage)
        } else {
            collectGarbage(0, 0)
        }

        if firstChild == nil {
            let layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex)
            if !addInitialChild(index: firstIndex, layoutOffset: layoutOffset) {
                // There are either no children, or we are past the end of all our children.
                let max: Float
                if firstIndex <= 0 {
                    max = 0.0
                } else {
                    max = computeMaxScrollOffset(constraints, itemExtent: deprecatedExtraItemExtent)
                }
                geometry = SliverGeometry(
                    scrollExtent: max,
                    maxPaintExtent: max
                )
                childManager.didFinishLayout()
                return
            }
        }

        var trailingChildWithLayout: RenderBox?

        for index in stride(from: indexOf(firstChild!) - 1, through: firstIndex, by: -1) {
            let child = insertAndLayoutLeadingChild(_getChildConstraints(index))
            if child == nil {
                // Items before the previously first child are no longer present.
                // Reset the scroll offset to offset all items prior and up to the
                // missing item. Let parent re-layout everything.
                geometry = SliverGeometry(
                    scrollOffsetCorrection: indexToLayoutOffset(deprecatedExtraItemExtent, index)
                )
                return
            }
            let childParentData = child!.parentData as! SliverMultiBoxAdaptorParentData
            childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index)
            assert(childParentData.index == index)
            trailingChildWithLayout = trailingChildWithLayout ?? child
        }

        if trailingChildWithLayout == nil {
            firstChild!.layout(_getChildConstraints(indexOf(firstChild!)))
            let childParentData = firstChild!.parentData as! SliverMultiBoxAdaptorParentData
            childParentData.layoutOffset = indexToLayoutOffset(
                deprecatedExtraItemExtent,
                firstIndex
            )
            trailingChildWithLayout = firstChild
        }

        var estimatedMaxScrollOffset: Float = .infinity
        var index = indexOf(trailingChildWithLayout!) + 1
        while targetLastIndex == nil || index <= targetLastIndex! {
            var child = childAfter(trailingChildWithLayout!)
            if child == nil || indexOf(child!) != index {
                child = insertAndLayoutChild(
                    _getChildConstraints(index),
                    after: trailingChildWithLayout
                )
                if child == nil {
                    // We have run out of children.
                    estimatedMaxScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index)
                    break
                }
            } else {
                child!.layout(_getChildConstraints(index))
            }
            trailingChildWithLayout = child
            let childParentData = child!.parentData as! SliverMultiBoxAdaptorParentData
            assert(childParentData.index == index)
            childParentData.layoutOffset = indexToLayoutOffset(
                deprecatedExtraItemExtent,
                childParentData.index!
            )
            index += 1
        }

        let lastIndex = indexOf(lastChild!)
        let leadingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex)
        let trailingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, lastIndex + 1)

        assert(
            firstIndex == 0
                || childScrollOffset(firstChild!)! - scrollOffset <= precisionErrorTolerance
        )
        assert(debugAssertChildListIsNonEmptyAndContiguous())
        assert(indexOf(firstChild!) == firstIndex)
        assert(targetLastIndex == nil || lastIndex <= targetLastIndex!)

        estimatedMaxScrollOffset = min(
            estimatedMaxScrollOffset,
            estimateMaxScrollOffset(
                constraints,
                firstIndex: firstIndex,
                lastIndex: lastIndex,
                leadingScrollOffset: leadingScrollOffset,
                trailingScrollOffset: trailingScrollOffset
            )
        )

        let paintExtent = calculatePaintOffset(
            constraints,
            from: leadingScrollOffset,
            to: trailingScrollOffset
        )

        let cacheExtent = calculateCacheOffset(
            constraints,
            from: leadingScrollOffset,
            to: trailingScrollOffset
        )

        let targetEndScrollOffsetForPaint =
            constraints.scrollOffset + constraints.remainingPaintExtent
        let targetLastIndexForPaint =
            targetEndScrollOffsetForPaint.isFinite
            ? getMaxChildIndexForScrollOffset(
                targetEndScrollOffsetForPaint,
                deprecatedExtraItemExtent
            ) : nil

        geometry = SliverGeometry(
            scrollExtent: estimatedMaxScrollOffset,
            paintExtent: paintExtent,
            maxPaintExtent: estimatedMaxScrollOffset,
            // Conservative to avoid flickering away the clip during scroll.
            hasVisualOverflow: (targetLastIndexForPaint != nil
                && lastIndex >= targetLastIndexForPaint!)
                || constraints.scrollOffset > 0.0,
            cacheExtent: cacheExtent
        )

        // We may have started the layout while scrolled to the end, which would not
        // expose a new child.
        if estimatedMaxScrollOffset == trailingScrollOffset {
            childManager.setDidUnderflow(true)
        }
        childManager.didFinishLayout()
    }
}

/// A sliver that places multiple box children with the same main axis extent in
/// a linear array.
///
/// [RenderSliverFixedExtentList] places its children in a linear array along
/// the main axis starting at offset zero and without gaps. Each child is forced
/// to have the [itemExtent] in the main axis and the
/// [SliverConstraints.crossAxisExtent] in the cross axis.
///
/// [RenderSliverFixedExtentList] is more efficient than [RenderSliverList]
/// because [RenderSliverFixedExtentList] does not need to perform layout on its
/// children to obtain their extent in the main axis.
///
/// See also:
///
///  * [RenderSliverList], which does not require its children to have the same
///    extent in the main axis.
///  * [RenderSliverFillViewport], which determines the [itemExtent] based on
///    [SliverConstraints.viewportMainAxisExtent].
///  * [RenderSliverFillRemaining], which determines the [itemExtent] based on
///    [SliverConstraints.remainingPaintExtent].
public class RenderSliverFixedExtentList: RenderSliverFixedExtentBoxAdaptor {
    /// Creates a sliver that contains multiple box children that have a given
    /// extent in the main axis.
    public init(childManager: RenderSliverBoxChildManager, itemExtent: Float) {
        self._itemExtent = itemExtent
        super.init(childManager: childManager)
    }

    public override var itemExtent: Float? {
        return _itemExtent
    }
    public var _itemExtent: Float? {
        didSet {
            if _itemExtent != oldValue {
                markNeedsLayout()
            }
        }
    }
}

/// A sliver that places multiple box children with the corresponding main axis extent in
/// a linear array.
public class RenderSliverVariedExtentList: RenderSliverFixedExtentBoxAdaptor {
    /// Creates a sliver that contains multiple box children that have a explicit
    /// extent in the main axis.
    public init(
        childManager: RenderSliverBoxChildManager,
        itemExtentBuilder: @escaping ItemExtentBuilder
    ) {
        self._itemExtentBuilder = itemExtentBuilder
        super.init(childManager: childManager)
    }

    public override var itemExtentBuilder: ItemExtentBuilder? {
        return _itemExtentBuilder
    }
    public var _itemExtentBuilder: ItemExtentBuilder {
        didSet {
            // if _itemExtentBuilder != oldValue {
            markNeedsLayout()
            // }
        }
    }

    public override var itemExtent: Float? {
        return nil
    }
}
