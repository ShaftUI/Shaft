/// Describes the placement of a child in a [RenderSliverGrid].
///
/// This class is similar to [Rect], in that it gives a two-dimensional position
/// and a two-dimensional dimension, but is direction-agnostic.
///
/// {@tool dartpad}
/// This example shows how a custom [SliverGridLayout] uses [SliverGridGeometry]
/// to lay out the children.
///
/// ** See code in examples/api/lib/widgets/scroll_view/grid_view.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SliverGridLayout], which represents the geometry of all the tiles in a
///    grid.
///  * [SliverGridLayout.getGeometryForChildIndex], which returns this object
///    to describe the child's placement.
///  * [RenderSliverGrid], which uses this class during its
///    [RenderSliverGrid.performLayout] method.
public struct SliverGridGeometry {
    /// Creates an object that describes the placement of a child in a [RenderSliverGrid].
    public init(
        scrollOffset: Float,
        crossAxisOffset: Float,
        mainAxisExtent: Float,
        crossAxisExtent: Float
    ) {
        self.scrollOffset = scrollOffset
        self.crossAxisOffset = crossAxisOffset
        self.mainAxisExtent = mainAxisExtent
        self.crossAxisExtent = crossAxisExtent
    }

    /// The scroll offset of the leading edge of the child relative to the leading
    /// edge of the parent.
    public let scrollOffset: Float

    /// The offset of the child in the non-scrolling axis.
    ///
    /// If the scroll axis is vertical, this offset is from the left-most edge of
    /// the parent to the left-most edge of the child. If the scroll axis is
    /// horizontal, this offset is from the top-most edge of the parent to the
    /// top-most edge of the child.
    public let crossAxisOffset: Float

    /// The extent of the child in the scrolling axis.
    ///
    /// If the scroll axis is vertical, this extent is the child's height. If the
    /// scroll axis is horizontal, this extent is the child's width.
    public let mainAxisExtent: Float

    /// The extent of the child in the non-scrolling axis.
    ///
    /// If the scroll axis is vertical, this extent is the child's width. If the
    /// scroll axis is horizontal, this extent is the child's height.
    public let crossAxisExtent: Float

    /// The scroll offset of the trailing edge of the child relative to the
    /// leading edge of the parent.
    public var trailingScrollOffset: Float {
        return scrollOffset + mainAxisExtent
    }

    /// Returns a tight [BoxConstraints] that forces the child to have the
    /// required size, given a [SliverConstraints].
    public func getBoxConstraints(_ constraints: SliverConstraints) -> BoxConstraints {
        return constraints.asBoxConstraints(
            minExtent: mainAxisExtent,
            maxExtent: mainAxisExtent,
            crossAxisExtent: crossAxisExtent
        )
    }
}

/// The size and position of all the tiles in a [RenderSliverGrid].
///
/// Rather that providing a grid with a [SliverGridLayout] directly, the grid is
/// provided a [SliverGridDelegate], which computes a [SliverGridLayout] given a
/// set of [SliverConstraints]. This allows the algorithm to dynamically respond
/// to changes in the environment (e.g. the user rotating the device).
///
/// The tiles can be placed arbitrarily, but it is more efficient to place tiles
/// roughly in order by scroll offset because grids reify a contiguous sequence
/// of children.
///
/// {@tool dartpad}
/// This example shows how to construct a custom [SliverGridLayout] to lay tiles
/// in a grid form with some cells stretched to fit the entire width of the
/// grid (sometimes called "hero tiles").
///
/// ** See code in examples/api/lib/widgets/scroll_view/grid_view.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SliverGridRegularTileLayout], which represents a layout that uses
///    equally sized and spaced tiles.
///  * [SliverGridGeometry], which represents the size and position of a single
///    tile in a grid.
///  * [SliverGridDelegate.getLayout], which returns this object to describe the
///    delegate's layout.
///  * [RenderSliverGrid], which uses this class during its
///    [RenderSliverGrid.performLayout] method.
public protocol SliverGridLayout {
    /// The minimum child index that intersects with (or is after) this scroll offset.
    func getMinChildIndexForScrollOffset(_ scrollOffset: Float) -> Int

    /// The maximum child index that intersects with (or is before) this scroll offset.
    func getMaxChildIndexForScrollOffset(_ scrollOffset: Float) -> Int

    /// The size and position of the child with the given index.
    func getGeometryForChildIndex(_ index: Int) -> SliverGridGeometry

    /// The scroll extent needed to fully display all the tiles if there are
    /// `childCount` children in total.
    ///
    /// The child count will never be null.
    func computeMaxScrollOffset(_ childCount: Int) -> Float
}

/// A [SliverGridLayout] that uses equally sized and spaced tiles.
///
/// Rather that providing a grid with a [SliverGridLayout] directly, you instead
/// provide the grid a [SliverGridDelegate], which can compute a
/// [SliverGridLayout] given the current [SliverConstraints].
///
/// This layout is used by [SliverGridDelegateWithFixedCrossAxisCount] and
/// [SliverGridDelegateWithMaxCrossAxisExtent].
///
/// See also:
///
///  * [SliverGridDelegateWithFixedCrossAxisCount], which uses this layout.
///  * [SliverGridDelegateWithMaxCrossAxisExtent], which uses this layout.
///  * [SliverGridLayout], which represents an arbitrary tile layout.
///  * [SliverGridGeometry], which represents the size and position of a single
///    tile in a grid.
///  * [SliverGridDelegate.getLayout], which returns this object to describe the
///    delegate's layout.
///  * [RenderSliverGrid], which uses this class during its
///    [RenderSliverGrid.performLayout] method.
public struct SliverGridRegularTileLayout: SliverGridLayout {
    /// Creates a layout that uses equally sized and spaced tiles.
    ///
    /// All of the arguments must not be negative. The `crossAxisCount` argument
    /// must be greater than zero.
    public init(
        crossAxisCount: Int,
        mainAxisStride: Float,
        crossAxisStride: Float,
        childMainAxisExtent: Float,
        childCrossAxisExtent: Float,
        reverseCrossAxis: Bool
    ) {
        assert(crossAxisCount > 0)
        assert(mainAxisStride >= 0)
        assert(crossAxisStride >= 0)
        assert(childMainAxisExtent >= 0)
        assert(childCrossAxisExtent >= 0)

        self.crossAxisCount = crossAxisCount
        self.mainAxisStride = mainAxisStride
        self.crossAxisStride = crossAxisStride
        self.childMainAxisExtent = childMainAxisExtent
        self.childCrossAxisExtent = childCrossAxisExtent
        self.reverseCrossAxis = reverseCrossAxis
    }

    /// The number of children in the cross axis.
    public let crossAxisCount: Int

    /// The number of pixels from the leading edge of one tile to the leading edge
    /// of the next tile in the main axis.
    public let mainAxisStride: Float

    /// The number of pixels from the leading edge of one tile to the leading edge
    /// of the next tile in the cross axis.
    public let crossAxisStride: Float

    /// The number of pixels from the leading edge of one tile to the trailing
    /// edge of the same tile in the main axis.
    public let childMainAxisExtent: Float

    /// The number of pixels from the leading edge of one tile to the trailing
    /// edge of the same tile in the cross axis.
    public let childCrossAxisExtent: Float

    /// Whether the children should be placed in the opposite order of increasing
    /// coordinates in the cross axis.
    ///
    /// For example, if the cross axis is horizontal, the children are placed from
    /// left to right when [reverseCrossAxis] is false and from right to left when
    /// [reverseCrossAxis] is true.
    ///
    /// Typically set to the return value of [axisDirectionIsReversed] applied to
    /// the [SliverConstraints.crossAxisDirection].
    public let reverseCrossAxis: Bool

    public func getMinChildIndexForScrollOffset(_ scrollOffset: Float) -> Int {
        return mainAxisStride > precisionErrorTolerance
            ? crossAxisCount * Int(scrollOffset / mainAxisStride) : 0
    }

    public func getMaxChildIndexForScrollOffset(_ scrollOffset: Float) -> Int {
        if mainAxisStride > 0.0 {
            let mainAxisCount = ceilToInt(scrollOffset / mainAxisStride)
            return max(0, crossAxisCount * mainAxisCount - 1)
        }
        return 0
    }

    private func getOffsetFromStartInCrossAxis(_ crossAxisStart: Float) -> Float {
        if reverseCrossAxis {
            return Float(crossAxisCount) * crossAxisStride - crossAxisStart - childCrossAxisExtent
                - (crossAxisStride - childCrossAxisExtent)
        }
        return crossAxisStart
    }

    public func getGeometryForChildIndex(_ index: Int) -> SliverGridGeometry {
        let crossAxisStart = Float(index % crossAxisCount) * crossAxisStride
        return SliverGridGeometry(
            scrollOffset: Float(index / crossAxisCount) * mainAxisStride,
            crossAxisOffset: getOffsetFromStartInCrossAxis(crossAxisStart),
            mainAxisExtent: childMainAxisExtent,
            crossAxisExtent: childCrossAxisExtent
        )
    }

    public func computeMaxScrollOffset(_ childCount: Int) -> Float {
        if childCount == 0 {
            // There are no children in the grid. The max scroll offset should be
            // zero.
            return 0.0
        }
        let mainAxisCount = ((childCount - 1) / crossAxisCount) + 1
        let mainAxisSpacing = mainAxisStride - childMainAxisExtent
        return mainAxisStride * Float(mainAxisCount) - mainAxisSpacing
    }
}

/// Controls the layout of tiles in a grid.
///
/// Given the current constraints on the grid, a [SliverGridDelegate] computes
/// the layout for the tiles in the grid. The tiles can be placed arbitrarily,
/// but it is more efficient to place tiles roughly in order by scroll offset
/// because grids reify a contiguous sequence of children.
///
/// {@tool dartpad}
/// This example shows how a [SliverGridDelegate] returns a [SliverGridLayout]
/// configured based on the provided [SliverConstraints] in [getLayout].
///
/// ** See code in examples/api/lib/widgets/scroll_view/grid_view.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SliverGridDelegateWithFixedCrossAxisCount], which creates a layout with
///    a fixed number of tiles in the cross axis.
///  * [SliverGridDelegateWithMaxCrossAxisExtent], which creates a layout with
///    tiles that have a maximum cross-axis extent.
///  * [GridView], which uses this delegate to control the layout of its tiles.
///  * [SliverGrid], which uses this delegate to control the layout of its
///    tiles.
///  * [RenderSliverGrid], which uses this delegate to control the layout of its
///    tiles.
public protocol SliverGridDelegate: Equatable {
    /// Returns information about the size and position of the tiles in the grid.
    func getLayout(_ constraints: SliverConstraints) -> SliverGridLayout

    /// Override this method to return true when the children need to be
    /// laid out.
    ///
    /// This should compare the fields of the current delegate and the given
    /// `oldDelegate` and return true if the fields are such that the layout would
    /// be different.
    func shouldRelayout(_ oldDelegate: Self) -> Bool
}

/// Creates grid layouts with a fixed number of tiles in the cross axis.
///
/// For example, if the grid is vertical, this delegate will create a layout
/// with a fixed number of columns. If the grid is horizontal, this delegate
/// will create a layout with a fixed number of rows.
///
/// This delegate creates grids with equally sized and spaced tiles.
///
/// {@tool dartpad}
/// Here is an example using the [childAspectRatio] property. On a device with a
/// screen width of 800.0, it creates a GridView with each tile with a width of
/// 200.0 and a height of 100.0.
///
/// ** See code in examples/api/lib/rendering/sliver_grid/sliver_grid_delegate_with_fixed_cross_axis_count.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// Here is an example using the [mainAxisExtent] property. On a device with a
/// screen width of 800.0, it creates a GridView with each tile with a width of
/// 200.0 and a height of 150.0.
///
/// ** See code in examples/api/lib/rendering/sliver_grid/sliver_grid_delegate_with_fixed_cross_axis_count.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SliverGridDelegateWithMaxCrossAxisExtent], which creates a layout with
///    tiles that have a maximum cross-axis extent.
///  * [SliverGridDelegate], which creates arbitrary layouts.
///  * [GridView], which can use this delegate to control the layout of its
///    tiles.
///  * [SliverGrid], which can use this delegate to control the layout of its
///    tiles.
///  * [RenderSliverGrid], which can use this delegate to control the layout of
///    its tiles.
public struct SliverGridDelegateWithFixedCrossAxisCount: SliverGridDelegate {
    /// Creates a delegate that makes grid layouts with a fixed number of tiles in
    /// the cross axis.
    ///
    /// The `mainAxisSpacing`, `mainAxisExtent` and `crossAxisSpacing` arguments
    /// must not be negative. The `crossAxisCount` and `childAspectRatio`
    /// arguments must be greater than zero.
    public init(
        crossAxisCount: Int,
        mainAxisSpacing: Float = 0.0,
        crossAxisSpacing: Float = 0.0,
        childAspectRatio: Float = 1.0,
        mainAxisExtent: Float? = nil
    ) {
        assert(crossAxisCount > 0)
        assert(mainAxisSpacing >= 0)
        assert(crossAxisSpacing >= 0)
        assert(childAspectRatio > 0)
        assert(mainAxisExtent == nil || mainAxisExtent! >= 0)

        self.crossAxisCount = crossAxisCount
        self.mainAxisSpacing = mainAxisSpacing
        self.crossAxisSpacing = crossAxisSpacing
        self.childAspectRatio = childAspectRatio
        self.mainAxisExtent = mainAxisExtent
    }

    /// The number of children in the cross axis.
    public let crossAxisCount: Int

    /// The number of logical pixels between each child along the main axis.
    public let mainAxisSpacing: Float

    /// The number of logical pixels between each child along the cross axis.
    public let crossAxisSpacing: Float

    /// The ratio of the cross-axis to the main-axis extent of each child.
    public let childAspectRatio: Float

    /// The extent of each tile in the main axis. If provided it would define the
    /// logical pixels taken by each tile in the main-axis.
    ///
    /// If null, [childAspectRatio] is used instead.
    public let mainAxisExtent: Float?

    private func debugAssertIsValid() -> Bool {
        assert(crossAxisCount > 0)
        assert(mainAxisSpacing >= 0.0)
        assert(crossAxisSpacing >= 0.0)
        assert(childAspectRatio > 0.0)
        return true
    }

    public func getLayout(_ constraints: SliverConstraints) -> SliverGridLayout {
        assert(debugAssertIsValid())
        let usableCrossAxisExtent = max(
            0.0,
            constraints.crossAxisExtent - crossAxisSpacing * Float(crossAxisCount - 1)
        )
        let childCrossAxisExtent = usableCrossAxisExtent / Float(crossAxisCount)
        let childMainAxisExtent = mainAxisExtent ?? childCrossAxisExtent / childAspectRatio
        return SliverGridRegularTileLayout(
            crossAxisCount: crossAxisCount,
            mainAxisStride: childMainAxisExtent + mainAxisSpacing,
            crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
            childMainAxisExtent: childMainAxisExtent,
            childCrossAxisExtent: childCrossAxisExtent,
            reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection)
        )
    }

    public func shouldRelayout(_ oldDelegate: Self) -> Bool {
        return oldDelegate != self
    }
}

/// Creates grid layouts with tiles that each have a maximum cross-axis extent.
///
/// This delegate will select a cross-axis extent for the tiles that is as
/// large as possible subject to the following conditions:
///
///  - The extent evenly divides the cross-axis extent of the grid.
///  - The extent is at most [maxCrossAxisExtent].
///
/// For example, if the grid is vertical, the grid is 500.0 pixels wide, and
/// [maxCrossAxisExtent] is 150.0, this delegate will create a grid with 4
/// columns that are 125.0 pixels wide.
///
/// This delegate creates grids with equally sized and spaced tiles.
///
/// See also:
///
///  * [SliverGridDelegateWithFixedCrossAxisCount], which creates a layout with
///    a fixed number of tiles in the cross axis.
///  * [SliverGridDelegate], which creates arbitrary layouts.
///  * [GridView], which can use this delegate to control the layout of its
///    tiles.
///  * [SliverGrid], which can use this delegate to control the layout of its
///    tiles.
///  * [RenderSliverGrid], which can use this delegate to control the layout of
///    its tiles.
public struct SliverGridDelegateWithMaxCrossAxisExtent: SliverGridDelegate {
    /// Creates a delegate that makes grid layouts with tiles that have a maximum
    /// cross-axis extent.
    ///
    /// The [maxCrossAxisExtent], [mainAxisExtent], [mainAxisSpacing],
    /// and [crossAxisSpacing] arguments must not be negative.
    /// The [childAspectRatio] argument must be greater than zero.
    public init(
        maxCrossAxisExtent: Float,
        mainAxisSpacing: Float = 0.0,
        crossAxisSpacing: Float = 0.0,
        childAspectRatio: Float = 1.0,
        mainAxisExtent: Float? = nil
    ) {
        assert(maxCrossAxisExtent > 0)
        assert(mainAxisSpacing >= 0)
        assert(crossAxisSpacing >= 0)
        assert(childAspectRatio > 0)
        assert(mainAxisExtent == nil || mainAxisExtent! >= 0)

        self.maxCrossAxisExtent = maxCrossAxisExtent
        self.mainAxisSpacing = mainAxisSpacing
        self.crossAxisSpacing = crossAxisSpacing
        self.childAspectRatio = childAspectRatio
        self.mainAxisExtent = mainAxisExtent
    }

    /// The maximum extent of tiles in the cross axis.
    ///
    /// This delegate will select a cross-axis extent for the tiles that is as
    /// large as possible subject to the following conditions:
    ///
    ///  - The extent evenly divides the cross-axis extent of the grid.
    ///  - The extent is at most [maxCrossAxisExtent].
    ///
    /// For example, if the grid is vertical, the grid is 500.0 pixels wide, and
    /// [maxCrossAxisExtent] is 150.0, this delegate will create a grid with 4
    /// columns that are 125.0 pixels wide.
    public let maxCrossAxisExtent: Float

    /// The number of logical pixels between each child along the main axis.
    public let mainAxisSpacing: Float

    /// The number of logical pixels between each child along the cross axis.
    public let crossAxisSpacing: Float

    /// The ratio of the cross-axis to the main-axis extent of each child.
    public let childAspectRatio: Float

    /// The extent of each tile in the main axis. If provided it would define the
    /// logical pixels taken by each tile in the main-axis.
    ///
    /// If null, [childAspectRatio] is used instead.
    public let mainAxisExtent: Float?

    private func debugAssertIsValid(_ crossAxisExtent: Float) -> Bool {
        assert(crossAxisExtent > 0.0)
        assert(maxCrossAxisExtent > 0.0)
        assert(mainAxisSpacing >= 0.0)
        assert(crossAxisSpacing >= 0.0)
        assert(childAspectRatio > 0.0)
        return true
    }

    public func getLayout(_ constraints: SliverConstraints) -> SliverGridLayout {
        assert(debugAssertIsValid(constraints.crossAxisExtent))
        var crossAxisCount = ceilToInt(
            constraints.crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing)
        )

        // Ensure a minimum count of 1, can be zero and result in an infinite extent
        // below when the window size is 0.
        crossAxisCount = max(1, crossAxisCount)
        let usableCrossAxisExtent = max(
            0.0,
            constraints.crossAxisExtent - crossAxisSpacing * Float(crossAxisCount - 1)
        )
        let childCrossAxisExtent = usableCrossAxisExtent / Float(crossAxisCount)
        let childMainAxisExtent = mainAxisExtent ?? childCrossAxisExtent / childAspectRatio
        return SliverGridRegularTileLayout(
            crossAxisCount: Int(crossAxisCount),
            mainAxisStride: childMainAxisExtent + mainAxisSpacing,
            crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
            childMainAxisExtent: childMainAxisExtent,
            childCrossAxisExtent: childCrossAxisExtent,
            reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection)
        )
    }

    public func shouldRelayout(_ oldDelegate: Self) -> Bool {
        return oldDelegate != self
    }
}

/// Parent data structure used by [RenderSliverGrid].
public class SliverGridParentData: SliverMultiBoxAdaptorParentData {
    /// The offset of the child in the non-scrolling axis.
    ///
    /// If the scroll axis is vertical, this offset is from the left-most edge of
    /// the parent to the left-most edge of the child. If the scroll axis is
    /// horizontal, this offset is from the top-most edge of the parent to the
    /// top-most edge of the child.
    public var crossAxisOffset: Float?
}

/// A sliver that places multiple box children in a two dimensional arrangement.
///
/// [RenderSliverGrid] places its children in arbitrary positions determined by
/// [gridDelegate]. Each child is forced to have the size specified by the
/// [gridDelegate].
///
/// See also:
///
///  * [RenderSliverList], which places its children in a linear
///    array.
///  * [RenderSliverFixedExtentList], which places its children in a linear
///    array with a fixed extent in the main axis.
public class RenderSliverGrid: RenderSliverMultiBoxAdaptor {

    /// Creates a sliver that contains multiple box children that whose size and
    /// position are determined by a delegate.
    public init(
        childManager: RenderSliverBoxChildManager,
        gridDelegate: any SliverGridDelegate
    ) {
        self.gridDelegate = gridDelegate
        super.init(childManager: childManager)
    }

    public override func setupParentData(_ child: RenderObject) {
        if !(child.parentData is SliverGridParentData) {
            child.parentData = SliverGridParentData()
        }
    }

    /// The delegate that controls the size and position of the children.
    public var gridDelegate: any SliverGridDelegate {
        didSet {
            if isEqual(gridDelegate, oldValue) {
                return
            }
            if delegateShouldRelayout(oldValue, gridDelegate) {
                markNeedsLayout()
            }
        }

    }

    private func delegateShouldRelayout<D1: SliverGridDelegate, D2: SliverGridDelegate>(
        _ oldDelegate: D1,
        _ newDelegate: D2
    ) -> Bool {
        if let oldDelegate = oldDelegate as? D2 {
            return newDelegate.shouldRelayout(oldDelegate)
        }
        return true
    }

    public override func childCrossAxisPosition(_ child: RenderObject) -> Float {
        let childParentData = child.parentData as! SliverGridParentData
        return childParentData.crossAxisOffset!
    }

    public override func performLayout() {
        let constraints = self.sliverConstraints
        childManager.didStartLayout()
        childManager.setDidUnderflow(false)

        let scrollOffset = constraints.scrollOffset + constraints.cacheOrigin
        assert(scrollOffset >= 0.0)
        let remainingExtent = constraints.remainingCacheExtent
        assert(remainingExtent >= 0.0)
        let targetEndScrollOffset = scrollOffset + remainingExtent

        let layout = gridDelegate.getLayout(constraints)

        let firstIndex = layout.getMinChildIndexForScrollOffset(scrollOffset)
        let targetLastIndex =
            targetEndScrollOffset.isFinite
            ? layout.getMaxChildIndexForScrollOffset(targetEndScrollOffset) : nil
        if firstChild != nil {
            let leadingGarbage = calculateLeadingGarbage(firstIndex: firstIndex)
            let trailingGarbage =
                targetLastIndex != nil ? calculateTrailingGarbage(lastIndex: targetLastIndex!) : 0
            collectGarbage(leadingGarbage, trailingGarbage)
        } else {
            collectGarbage(0, 0)
        }

        let firstChildGridGeometry = layout.getGeometryForChildIndex(firstIndex)

        if firstChild == nil {
            if !addInitialChild(
                index: firstIndex,
                layoutOffset: firstChildGridGeometry.scrollOffset
            ) {
                // There are either no children, or we are past the end of all our children.
                let max = layout.computeMaxScrollOffset(childManager.childCount)
                geometry = SliverGeometry(
                    scrollExtent: max,
                    maxPaintExtent: max
                )
                childManager.didFinishLayout()
                return
            }
        }

        let leadingScrollOffset = firstChildGridGeometry.scrollOffset
        var trailingScrollOffset = firstChildGridGeometry.trailingScrollOffset
        var trailingChildWithLayout: RenderBox?
        var reachedEnd = false

        for index in stride(from: indexOf(firstChild!) - 1, through: firstIndex, by: -1) {
            let gridGeometry = layout.getGeometryForChildIndex(index)
            let child = insertAndLayoutLeadingChild(
                gridGeometry.getBoxConstraints(constraints)
            )!
            let childParentData = child.parentData as! SliverGridParentData
            childParentData.layoutOffset = gridGeometry.scrollOffset
            childParentData.crossAxisOffset = gridGeometry.crossAxisOffset
            assert(childParentData.index == index)
            trailingChildWithLayout = trailingChildWithLayout ?? child
            trailingScrollOffset = max(trailingScrollOffset, gridGeometry.trailingScrollOffset)
        }

        if trailingChildWithLayout == nil {
            firstChild!.layout(firstChildGridGeometry.getBoxConstraints(constraints))
            let childParentData = firstChild!.parentData as! SliverGridParentData
            childParentData.layoutOffset = firstChildGridGeometry.scrollOffset
            childParentData.crossAxisOffset = firstChildGridGeometry.crossAxisOffset
            trailingChildWithLayout = firstChild
        }

        var index = indexOf(trailingChildWithLayout!) + 1
        while targetLastIndex == nil || index <= targetLastIndex! {
            let gridGeometry = layout.getGeometryForChildIndex(index)
            let childConstraints = gridGeometry.getBoxConstraints(constraints)
            var child = childAfter(trailingChildWithLayout!)
            if child == nil || indexOf(child!) != index {
                child = insertAndLayoutChild(childConstraints, after: trailingChildWithLayout)
                if child == nil {
                    reachedEnd = true
                    // We have run out of children.
                    break
                }
            } else {
                child!.layout(childConstraints)
            }
            trailingChildWithLayout = child
            let childParentData = child!.parentData as! SliverGridParentData
            childParentData.layoutOffset = gridGeometry.scrollOffset
            childParentData.crossAxisOffset = gridGeometry.crossAxisOffset
            assert(childParentData.index == index)
            trailingScrollOffset = max(trailingScrollOffset, gridGeometry.trailingScrollOffset)
            index += 1
        }

        let lastIndex = indexOf(lastChild!)

        assert(debugAssertChildListIsNonEmptyAndContiguous())
        assert(indexOf(firstChild!) == firstIndex)
        assert(targetLastIndex == nil || lastIndex <= targetLastIndex!)

        let estimatedTotalExtent =
            reachedEnd
            ? trailingScrollOffset
            : childManager.estimateMaxScrollOffset(
                constraints,
                firstIndex: firstIndex,
                lastIndex: lastIndex,
                leadingScrollOffset: leadingScrollOffset,
                trailingScrollOffset: trailingScrollOffset
            )
        let paintExtent = calculatePaintOffset(
            constraints,
            from: min(constraints.scrollOffset, leadingScrollOffset),
            to: trailingScrollOffset
        )
        let cacheExtent = calculateCacheOffset(
            constraints,
            from: leadingScrollOffset,
            to: trailingScrollOffset
        )

        geometry = SliverGeometry(
            scrollExtent: estimatedTotalExtent,
            paintExtent: paintExtent,
            maxPaintExtent: estimatedTotalExtent,
            hasVisualOverflow: estimatedTotalExtent > paintExtent || constraints.scrollOffset > 0.0
                || constraints.overlap != 0.0,
            cacheExtent: cacheExtent
        )

        // We may have started the layout while scrolled to the end, which
        // would not expose a new child.
        if estimatedTotalExtent == trailingScrollOffset {
            childManager.setDidUnderflow(true)
        }
        childManager.didFinishLayout()
    }
}
