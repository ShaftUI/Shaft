// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

// MARK: - Helper Types

/// A 2D vector that uses a [RenderWrap]'s main axis and cross axis as its first and second coordinate axes.
/// It represents the same vector as (Float mainAxisExtent, Float crossAxisExtent).
///
/// Note: Dart's `extension type const` is not directly translatable to Swift.
/// This is implemented as a struct wrapper around Size.
struct _AxisSize {
    private let _size: Size

    init(mainAxisExtent: Float, crossAxisExtent: Float) {
        self._size = Size(mainAxisExtent, crossAxisExtent)
    }

    init(fromSize size: Size, direction: Axis) {
        self._size = Self._convert(size, direction: direction)
    }

    static let empty = _AxisSize(mainAxisExtent: 0.0, crossAxisExtent: 0.0)

    private static func _convert(_ size: Size, direction: Axis) -> Size {
        switch direction {
        case .horizontal:
            return size
        case .vertical:
            return Size(size.height, size.width)  // Flip width and height
        }
    }

    var mainAxisExtent: Float { _size.width }
    var crossAxisExtent: Float { _size.height }

    func toSize(direction: Axis) -> Size {
        Self._convert(_size, direction: direction)
    }

    func applyConstraints(_ constraints: BoxConstraints, direction: Axis) -> _AxisSize {
        let effectiveConstraints: BoxConstraints =
            switch direction {
            case .horizontal:
                constraints
            case .vertical:
                // Flip constraints (swap width/height constraints)
                BoxConstraints(
                    minWidth: constraints.minHeight,
                    maxWidth: constraints.maxHeight,
                    minHeight: constraints.minWidth,
                    maxHeight: constraints.maxWidth
                )
            }
        return _AxisSize(
            mainAxisExtent: effectiveConstraints.constrainWidth(_size.width),
            crossAxisExtent: effectiveConstraints.constrainHeight(_size.height)
        )
    }

    var flipped: _AxisSize {
        _AxisSize(mainAxisExtent: _size.height, crossAxisExtent: _size.width)
    }

    static func + (lhs: _AxisSize, rhs: _AxisSize) -> _AxisSize {
        _AxisSize(
            mainAxisExtent: lhs._size.width + rhs._size.width,
            crossAxisExtent: max(lhs._size.height, rhs._size.height)
        )
    }

    static func - (lhs: _AxisSize, rhs: _AxisSize) -> _AxisSize {
        _AxisSize(
            mainAxisExtent: lhs._size.width - rhs._size.width,
            crossAxisExtent: lhs._size.height - rhs._size.height
        )
    }
}

/// How [Wrap] should align objects.
///
/// Used both to align children within a run in the main axis as well as to
/// align the runs themselves in the cross axis.
public enum WrapAlignment {
    /// Place the objects as close to the start of the axis as possible.
    ///
    /// If this value is used in a horizontal direction, a [TextDirection] must be
    /// available to determine if the start is the left or the right.
    ///
    /// If this value is used in a vertical direction, a [VerticalDirection] must be
    /// available to determine if the start is the top or the bottom.
    case start

    /// Place the objects as close to the end of the axis as possible.
    ///
    /// If this value is used in a horizontal direction, a [TextDirection] must be
    /// available to determine if the end is the left or the right.
    ///
    /// If this value is used in a vertical direction, a [VerticalDirection] must be
    /// available to determine if the end is the top or the bottom.
    case end

    /// Place the objects as close to the middle of the axis as possible.
    case center

    /// Place the free space evenly between the objects.
    case spaceBetween

    /// Place the free space evenly between the objects as well as half of that
    /// space before and after the first and last objects.
    case spaceAround

    /// Place the free space evenly between the objects as well as before and
    /// after the first and last objects.
    case spaceEvenly

    func _distributeSpace(
        freeSpace: Float,
        itemSpacing: Float,
        itemCount: Int,
        flipped: Bool
    ) -> (leadingSpace: Float, betweenSpace: Float) {
        assert(itemCount > 0)
        switch self {
        case .start:
            return (flipped ? freeSpace : 0.0, itemSpacing)

        case .end:
            return WrapAlignment.start._distributeSpace(
                freeSpace: freeSpace,
                itemSpacing: itemSpacing,
                itemCount: itemCount,
                flipped: !flipped
            )

        case .spaceBetween where itemCount < 2:
            return WrapAlignment.start._distributeSpace(
                freeSpace: freeSpace,
                itemSpacing: itemSpacing,
                itemCount: itemCount,
                flipped: flipped
            )

        case .center:
            return (freeSpace / 2.0, itemSpacing)

        case .spaceBetween:
            return (0, freeSpace / Float(itemCount - 1) + itemSpacing)

        case .spaceAround:
            return (freeSpace / Float(itemCount) / 2, freeSpace / Float(itemCount) + itemSpacing)

        case .spaceEvenly:
            return (
                freeSpace / Float(itemCount + 1),
                freeSpace / Float(itemCount + 1) + itemSpacing
            )

        default:
            fatalError("Unhandled WrapAlignment case")
        }
    }
}

/// How [Wrap] should align children within a run in the cross axis.
public enum WrapCrossAlignment {
    /// Place the children as close to the start of the run in the cross axis as
    /// possible.
    ///
    /// If this value is used in a horizontal direction, a [TextDirection] must be
    /// available to determine if the start is the left or the right.
    ///
    /// If this value is used in a vertical direction, a [VerticalDirection] must be
    /// available to determine if the start is the top or the bottom.
    case start

    /// Place the children as close to the end of the run in the cross axis as
    /// possible.
    ///
    /// If this value is used in a horizontal direction, a [TextDirection] must be
    /// available to determine if the end is the left or the right.
    ///
    /// If this value is used in a vertical direction, a [VerticalDirection] must be
    /// available to determine if the end is the top or the bottom.
    case end

    /// Place the children as close to the middle of the run in the cross axis as
    /// possible.
    case center

    // TODO(ianh): baseline.

    var _flipped: WrapCrossAlignment {
        switch self {
        case .start:
            return .end
        case .end:
            return .start
        case .center:
            return .center
        }
    }

    var _alignment: Float {
        switch self {
        case .start:
            return 0
        case .end:
            return 1
        case .center:
            return 0.5
        }
    }
}

class _RunMetrics {
    var axisSize: _AxisSize
    var childCount: Int = 1
    var leadingChild: RenderBox

    init(_ leadingChild: RenderBox, _ axisSize: _AxisSize) {
        self.leadingChild = leadingChild
        self.axisSize = axisSize
    }

    // Look ahead, creates a new run if incorporating the child would exceed the allowed line width.
    func tryAddingNewChild(
        _ child: RenderBox,
        _ childSize: _AxisSize,
        _ flipMainAxis: Bool,
        _ spacing: Float,
        _ maxMainExtent: Float
    ) -> _RunMetrics? {
        let needsNewRun =
            axisSize.mainAxisExtent + childSize.mainAxisExtent + spacing - maxMainExtent
            > precisionErrorTolerance
        if needsNewRun {
            return _RunMetrics(child, childSize)
        } else {
            axisSize =
                axisSize + childSize + _AxisSize(mainAxisExtent: spacing, crossAxisExtent: 0.0)
            childCount += 1
            if flipMainAxis {
                leadingChild = child
            }
            return nil
        }
    }
}

/// Parent data for use with [RenderWrap].
public class WrapParentData: ContainerBoxParentData<RenderBox> {}

// MARK: - RenderWrap

/// Displays its children in multiple horizontal or vertical runs.
///
/// A [RenderWrap] lays out each child and attempts to place the child adjacent
/// to the previous child in the main axis, given by [direction], leaving
/// [spacing] space in between. If there is not enough space to fit the child,
/// [RenderWrap] creates a new _run_ adjacent to the existing children in the
/// cross axis.
///
/// After all the children have been allocated to runs, the children within the
/// runs are positioned according to the [alignment] in the main axis and
/// according to the [crossAxisAlignment] in the cross axis.
///
/// The runs themselves are then positioned in the cross axis according to the
/// [runSpacing] and [runAlignment].
public class RenderWrap: RenderBox, RenderObjectWithChildren {
    /// Creates a wrap render object.
    ///
    /// By default, the wrap layout is horizontal and both the children and the
    /// runs are aligned to the start.
    public init(
        children: [RenderBox]? = nil,
        direction: Axis = .horizontal,
        alignment: WrapAlignment = .start,
        spacing: Float = 0.0,
        runAlignment: WrapAlignment = .start,
        runSpacing: Float = 0.0,
        crossAxisAlignment: WrapCrossAlignment = .start,
        textDirection: TextDirection? = nil,
        verticalDirection: VerticalDirection = .down,
        clipBehavior: Clip = .none
    ) {
        self.direction = direction
        self.alignment = alignment
        self.spacing = spacing
        self.runAlignment = runAlignment
        self.runSpacing = runSpacing
        self.crossAxisAlignment = crossAxisAlignment
        self.textDirection = textDirection
        self.verticalDirection = verticalDirection
        self.clipBehavior = clipBehavior
        super.init()
        if let children {
            addAll(children)
        }
    }

    public typealias ChildType = RenderBox
    public typealias ParentDataType = WrapParentData
    public var childMixin = RenderContainerMixin<RenderBox>()

    /// The direction to use as the main axis.
    ///
    /// For example, if [direction] is [Axis.horizontal], the default, the
    /// children are placed adjacent to one another in a horizontal run until the
    /// available horizontal space is consumed, at which point a subsequent
    /// children are placed in a new run vertically adjacent to the previous run.
    public var direction: Axis {
        didSet {
            if direction != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// How the children within a run should be placed in the main axis.
    ///
    /// For example, if [alignment] is [WrapAlignment.center], the children in
    /// each run are grouped together in the center of their run in the main axis.
    ///
    /// Defaults to [WrapAlignment.start].
    ///
    /// See also:
    ///
    ///  * [runAlignment], which controls how the runs are placed relative to each
    ///    other in the cross axis.
    ///  * [crossAxisAlignment], which controls how the children within each run
    ///    are placed relative to each other in the cross axis.
    public var alignment: WrapAlignment {
        didSet {
            if alignment != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// How much space to place between children in a run in the main axis.
    ///
    /// For example, if [spacing] is 10.0, the children will be spaced at least
    /// 10.0 logical pixels apart in the main axis.
    ///
    /// If there is additional free space in a run (e.g., because the wrap has a
    /// minimum size that is not filled or because some runs are longer than
    /// others), the additional free space will be allocated according to the
    /// [alignment].
    ///
    /// Defaults to 0.0.
    public var spacing: Float = 0.0 {
        didSet {
            if spacing != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// How the runs themselves should be placed in the cross axis.
    ///
    /// For example, if [runAlignment] is [WrapAlignment.center], the runs are
    /// grouped together in the center of the overall [RenderWrap] in the cross
    /// axis.
    ///
    /// Defaults to [WrapAlignment.start].
    ///
    /// See also:
    ///
    ///  * [alignment], which controls how the children within each run are placed
    ///    relative to each other in the main axis.
    ///  * [crossAxisAlignment], which controls how the children within each run
    ///    are placed relative to each other in the cross axis.
    public var runAlignment: WrapAlignment {
        didSet {
            if runAlignment != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// How much space to place between the runs themselves in the cross axis.
    ///
    /// For example, if [runSpacing] is 10.0, the runs will be spaced at least
    /// 10.0 logical pixels apart in the cross axis.
    ///
    /// If there is additional free space in the overall [RenderWrap] (e.g.,
    /// because the wrap has a minimum size that is not filled), the additional
    /// free space will be allocated according to the [runAlignment].
    ///
    /// Defaults to 0.0.
    public var runSpacing: Float = 0.0 {
        didSet {
            if runSpacing != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// How the children within a run should be aligned relative to each other in
    /// the cross axis.
    ///
    /// For example, if this is set to [WrapCrossAlignment.end], and the
    /// [direction] is [Axis.horizontal], then the children within each
    /// run will have their bottom edges aligned to the bottom edge of the run.
    ///
    /// Defaults to [WrapCrossAlignment.start].
    ///
    /// See also:
    ///
    ///  * [alignment], which controls how the children within each run are placed
    ///    relative to each other in the main axis.
    ///  * [runAlignment], which controls how the runs are placed relative to each
    ///    other in the cross axis.
    public var crossAxisAlignment: WrapCrossAlignment {
        didSet {
            if crossAxisAlignment != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// Determines the order to lay children out horizontally and how to interpret
    /// `start` and `end` in the horizontal direction.
    ///
    /// If the [direction] is [Axis.horizontal], this controls the order in which
    /// children are positioned (left-to-right or right-to-left), and the meaning
    /// of the [alignment] property's [WrapAlignment.start] and
    /// [WrapAlignment.end] values.
    ///
    /// If the [direction] is [Axis.horizontal], and either the
    /// [alignment] is either [WrapAlignment.start] or [WrapAlignment.end], or
    /// there's more than one child, then the [textDirection] must not be null.
    ///
    /// If the [direction] is [Axis.vertical], this controls the order in
    /// which runs are positioned, the meaning of the [runAlignment] property's
    /// [WrapAlignment.start] and [WrapAlignment.end] values, as well as the
    /// [crossAxisAlignment] property's [WrapCrossAlignment.start] and
    /// [WrapCrossAlignment.end] values.
    ///
    /// If the [direction] is [Axis.vertical], and either the
    /// [runAlignment] is either [WrapAlignment.start] or [WrapAlignment.end], the
    /// [crossAxisAlignment] is either [WrapCrossAlignment.start] or
    /// [WrapCrossAlignment.end], or there's more than one child, then the
    /// [textDirection] must not be null.
    public var textDirection: TextDirection? {
        didSet {
            if textDirection != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// Determines the order to lay children out vertically and how to interpret
    /// `start` and `end` in the vertical direction.
    ///
    /// If the [direction] is [Axis.vertical], this controls which order children
    /// are painted in (down or up), the meaning of the [alignment] property's
    /// [WrapAlignment.start] and [WrapAlignment.end] values.
    ///
    /// If the [direction] is [Axis.vertical], and either the [alignment]
    /// is either [WrapAlignment.start] or [WrapAlignment.end], or there's
    /// more than one child, then the [verticalDirection] must not be null.
    ///
    /// If the [direction] is [Axis.horizontal], this controls the order in which
    /// runs are positioned, the meaning of the [runAlignment] property's
    /// [WrapAlignment.start] and [WrapAlignment.end] values, as well as the
    /// [crossAxisAlignment] property's [WrapCrossAlignment.start] and
    /// [WrapCrossAlignment.end] values.
    ///
    /// If the [direction] is [Axis.horizontal], and either the
    /// [runAlignment] is either [WrapAlignment.start] or [WrapAlignment.end], the
    /// [crossAxisAlignment] is either [WrapCrossAlignment.start] or
    /// [WrapCrossAlignment.end], or there's more than one child, then the
    /// [verticalDirection] must not be null.
    public var verticalDirection: VerticalDirection {
        didSet {
            if verticalDirection != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// {@macro flutter.material.Material.clipBehavior}
    ///
    /// Defaults to [Clip.none].
    public var clipBehavior: Clip = .none {
        didSet {
            if clipBehavior != oldValue {
                markNeedsPaint()
                // markNeedsSemanticsUpdate()
            }
        }
    }

    // MARK: - Debug Helpers

    private var _debugHasNecessaryDirections: Bool {
        if firstChild != nil && lastChild !== firstChild {
            // i.e. there's more than one child
            switch direction {
            case .horizontal:
                assert(
                    textDirection != nil,
                    "Horizontal \(type(of: self)) with multiple children has a null textDirection, so the layout order is undefined."
                )
            case .vertical:
                break
            }
        }
        if alignment == .start || alignment == .end {
            switch direction {
            case .horizontal:
                assert(
                    textDirection != nil,
                    "Horizontal \(type(of: self)) with alignment \(alignment) has a null textDirection, so the alignment cannot be resolved."
                )
            case .vertical:
                break
            }
        }
        if runAlignment == .start || runAlignment == .end {
            switch direction {
            case .horizontal:
                break
            case .vertical:
                assert(
                    textDirection != nil,
                    "Vertical \(type(of: self)) with runAlignment \(runAlignment) has a null textDirection, so the alignment cannot be resolved."
                )
            }
        }
        if crossAxisAlignment == .start || crossAxisAlignment == .end {
            switch direction {
            case .horizontal:
                break
            case .vertical:
                assert(
                    textDirection != nil,
                    "Vertical \(type(of: self)) with crossAxisAlignment \(crossAxisAlignment) has a null textDirection, so the alignment cannot be resolved."
                )
            }
        }
        return true
    }

    // MARK: - Parent Data Setup

    public override func setupParentData(_ child: RenderObject) {
        if !(child.parentData is WrapParentData) {
            child.parentData = WrapParentData()
        }
    }

    // // MARK: - Intrinsic Dimensions

    // public override func computeMinIntrinsicWidth(_ height: Float) -> Float {
    //     switch direction {
    //     case .horizontal:
    //         var width: Float = 0.0
    //         var child = firstChild
    //         while let currentChild = child {
    //             width = max(width, currentChild.getMinIntrinsicWidth(Float.infinity))
    //             child = childAfter(currentChild)
    //         }
    //         return width
    //     case .vertical:
    //         return getDryLayout(BoxConstraints(maxHeight: height)).width
    //     }
    // }

    // public override func computeMaxIntrinsicWidth(_ height: Float) -> Float {
    //     switch direction {
    //     case .horizontal:
    //         var width: Float = 0.0
    //         var child = firstChild
    //         while let currentChild = child {
    //             width += currentChild.getMaxIntrinsicWidth(Float.infinity)
    //             child = childAfter(currentChild)
    //         }
    //         return width
    //     case .vertical:
    //         return getDryLayout(BoxConstraints(maxHeight: height)).width
    //     }
    // }

    // public override func computeMinIntrinsicHeight(_ width: Float) -> Float {
    //     switch direction {
    //     case .horizontal:
    //         return getDryLayout(BoxConstraints(maxWidth: width)).height
    //     case .vertical:
    //         var height: Float = 0.0
    //         var child = firstChild
    //         while let currentChild = child {
    //             height = max(height, currentChild.getMinIntrinsicHeight(Float.infinity))
    //             child = childAfter(currentChild)
    //         }
    //         return height
    //     }
    // }

    // public override func computeMaxIntrinsicHeight(_ width: Float) -> Float {
    //     switch direction {
    //     case .horizontal:
    //         return getDryLayout(BoxConstraints(maxWidth: width)).height
    //     case .vertical:
    //         var height: Float = 0.0
    //         var child = firstChild
    //         while let currentChild = child {
    //             height += currentChild.getMaxIntrinsicHeight(Float.infinity)
    //             child = childAfter(currentChild)
    //         }
    //         return height
    //     }
    // }

    // // MARK: - Baseline Computation

    // // TODO: Translate computeDistanceToActualBaseline - requires BaselineOffset type
    // // The Dart code uses defaultComputeDistanceToHighestActualBaseline which may not exist in Swift
    // public override func computeDistanceToActualBaseline(_ baseline: TextBaseline) -> Float? {
    //     // FIXME: Implement baseline computation
    //     // return defaultComputeDistanceToHighestActualBaseline(baseline)
    //     return nil
    // }

    // MARK: - Helper Methods

    private func _getMainAxisExtent(_ childSize: Size) -> Float {
        switch direction {
        case .horizontal:
            return childSize.width
        case .vertical:
            return childSize.height
        }
    }

    private func _getCrossAxisExtent(_ childSize: Size) -> Float {
        switch direction {
        case .horizontal:
            return childSize.height
        case .vertical:
            return childSize.width
        }
    }

    private func _getOffset(mainAxisOffset: Float, crossAxisOffset: Float) -> Offset {
        switch direction {
        case .horizontal:
            return Offset(mainAxisOffset, crossAxisOffset)
        case .vertical:
            return Offset(crossAxisOffset, mainAxisOffset)
        }
    }

    private var _areAxesFlipped: (flipHorizontal: Bool, flipVertical: Bool) {
        let flipHorizontal =
            switch textDirection ?? .ltr {
            case .ltr:
                false
            case .rtl:
                true
            }
        let flipVertical =
            switch verticalDirection {
            case .down:
                false
            case .up:
                true
            }
        return switch direction {
        case .horizontal:
            (flipHorizontal, flipVertical)
        case .vertical:
            (flipVertical, flipHorizontal)
        }
    }

    // MARK: - Dry Layout

    // // TODO: Translate computeDryBaseline - requires BaselineOffset type
    // // The Dart code uses BaselineOffset which may not exist in Swift
    // public override func computeDryBaseline(_ constraints: BoxConstraints, baseline: TextBaseline) -> Float? {
    //     if firstChild == nil {
    //         return nil
    //     }
    //     let childConstraints: BoxConstraints = switch direction {
    //     case .horizontal:
    //         BoxConstraints(maxWidth: constraints.maxWidth)
    //     case .vertical:
    //         BoxConstraints(maxHeight: constraints.maxHeight)
    //     }

    //     let (childrenAxisSize, runMetrics) = _computeRuns(
    //         constraints,
    //         layoutChild: ChildLayoutHelper.dryLayoutChild
    //     )
    //     let containerAxisSize = childrenAxisSize.applyConstraints(constraints, direction: direction)

    //     // FIXME: BaselineOffset type not found - marking as TODO
    //     // BaselineOffset baselineOffset = BaselineOffset.noBaseline;
    //     // void findHighestBaseline(Offset offset, RenderBox child) {
    //     //     baselineOffset = baselineOffset.minOf(
    //     //         BaselineOffset(child.getDryBaseline(childConstraints, baseline)) + offset.dy,
    //     //     );
    //     // }

    //     // let getChildSize: (RenderBox) -> Size = { child in
    //     //     child.getDryLayout(childConstraints)
    //     // }
    //     // _positionChildren(
    //     //     runMetrics,
    //     //     childrenAxisSize,
    //     //     containerAxisSize,
    //     //     findHighestBaseline,
    //     //     getChildSize,
    //     // )
    //     // return baselineOffset.offset

    //     return nil
    // }

    // public override func getDryLayout(_ constraints: BoxConstraints) -> Size {
    //     return _computeDryLayout(constraints)
    // }

    // private func _computeDryLayout(
    //     _ constraints: BoxConstraints,
    //     layoutChild: ChildLayouter = ChildLayoutHelper.dryLayoutChild
    // ) -> Size {
    //     let (childConstraints, mainAxisLimit): (BoxConstraints, Float) = switch direction {
    //     case .horizontal:
    //         (BoxConstraints(maxWidth: constraints.maxWidth), constraints.maxWidth)
    //     case .vertical:
    //         (BoxConstraints(maxHeight: constraints.maxHeight), constraints.maxHeight)
    //     }

    //     var mainAxisExtent: Float = 0.0
    //     var crossAxisExtent: Float = 0.0
    //     var runMainAxisExtent: Float = 0.0
    //     var runCrossAxisExtent: Float = 0.0
    //     var childCount = 0
    //     var child = firstChild
    //     while let currentChild = child {
    //         let childSize = layoutChild(currentChild, childConstraints)
    //         let childMainAxisExtent = _getMainAxisExtent(childSize)
    //         let childCrossAxisExtent = _getCrossAxisExtent(childSize)
    //         // There must be at least one child before we move on to the next run.
    //         if childCount > 0 && runMainAxisExtent + childMainAxisExtent + spacing > mainAxisLimit {
    //             mainAxisExtent = max(mainAxisExtent, runMainAxisExtent)
    //             crossAxisExtent += runCrossAxisExtent + runSpacing
    //             runMainAxisExtent = 0.0
    //             runCrossAxisExtent = 0.0
    //             childCount = 0
    //         }
    //         runMainAxisExtent += childMainAxisExtent
    //         runCrossAxisExtent = max(runCrossAxisExtent, childCrossAxisExtent)
    //         if childCount > 0 {
    //             runMainAxisExtent += spacing
    //         }
    //         childCount += 1
    //         child = childAfter(currentChild)
    //     }
    //     crossAxisExtent += runCrossAxisExtent
    //     mainAxisExtent = max(mainAxisExtent, runMainAxisExtent)

    //     return constraints.constrain(switch direction {
    //     case .horizontal:
    //         Size(mainAxisExtent, crossAxisExtent)
    //     case .vertical:
    //         Size(crossAxisExtent, mainAxisExtent)
    //     })
    // }

    // MARK: - Layout

    private static func _getChildSize(_ child: RenderBox) -> Size {
        child.size
    }

    private static func _setChildPosition(_ offset: Offset, _ child: RenderBox) {
        (child.parentData! as! WrapParentData).offset = offset
    }

    private var _hasVisualOverflow = false

    public override func performLayout() {
        let constraints = self.boxConstraint
        assert(_debugHasNecessaryDirections)
        if firstChild == nil {
            size = constraints.smallest
            _hasVisualOverflow = false
            return
        }

        let (childrenAxisSize, runMetrics) = _computeRuns(
            constraints,
            layoutChild: ChildLayoutHelper.layoutChild
        )
        let containerAxisSize = childrenAxisSize.applyConstraints(
            constraints,
            direction: direction
        )
        size = containerAxisSize.toSize(direction: direction)
        let freeAxisSize = containerAxisSize - childrenAxisSize
        _hasVisualOverflow = freeAxisSize.mainAxisExtent < 0.0 || freeAxisSize.crossAxisExtent < 0.0
        _positionChildren(
            runMetrics,
            freeAxisSize,
            containerAxisSize,
            Self._setChildPosition,
            Self._getChildSize
        )
    }

    private func _computeRuns(
        _ constraints: BoxConstraints,
        layoutChild: ChildLayouter
    ) -> (childrenSize: _AxisSize, runMetrics: [_RunMetrics]) {
        assert(firstChild != nil)
        let (childConstraints, mainAxisLimit): (BoxConstraints, Float) =
            switch direction {
            case .horizontal:
                (BoxConstraints(maxWidth: constraints.maxWidth), constraints.maxWidth)
            case .vertical:
                (BoxConstraints(maxHeight: constraints.maxHeight), constraints.maxHeight)
            }

        let (flipMainAxis, _) = _areAxesFlipped
        let spacing = self.spacing
        var runMetrics: [_RunMetrics] = []

        var currentRun: _RunMetrics?
        var childrenAxisSize = _AxisSize.empty
        var child = firstChild
        while let currentChild = child {
            let childSize = _AxisSize(
                fromSize: layoutChild(currentChild, childConstraints),
                direction: direction
            )
            let newRun: _RunMetrics? =
                currentRun == nil
                ? _RunMetrics(currentChild, childSize)
                : currentRun!.tryAddingNewChild(
                    currentChild,
                    childSize,
                    flipMainAxis,
                    spacing,
                    mainAxisLimit
                )
            if let newRun {
                runMetrics.append(newRun)
                childrenAxisSize =
                    childrenAxisSize + (currentRun?.axisSize.flipped ?? _AxisSize.empty)
                currentRun = newRun
            }
            child = childAfter(currentChild)
        }
        assert(!runMetrics.isEmpty)
        let totalRunSpacing = runSpacing * Float(runMetrics.count - 1)
        childrenAxisSize =
            childrenAxisSize + _AxisSize(mainAxisExtent: totalRunSpacing, crossAxisExtent: 0.0)
            + currentRun!.axisSize.flipped
        return (childrenAxisSize.flipped, runMetrics)
    }

    private func _positionChildren(
        _ runMetrics: [_RunMetrics],
        _ freeAxisSize: _AxisSize,
        _ containerAxisSize: _AxisSize,
        _ positionChild: (Offset, RenderBox) -> Void,
        _ getChildSize: (RenderBox) -> Size
    ) {
        assert(!runMetrics.isEmpty)

        let spacing = self.spacing

        let crossAxisFreeSpace = max(0.0, freeAxisSize.crossAxisExtent)

        let (flipMainAxis, flipCrossAxis) = _areAxesFlipped
        let effectiveCrossAlignment =
            flipCrossAxis
            ? crossAxisAlignment._flipped
            : crossAxisAlignment
        let (runLeadingSpace, runBetweenSpace) = runAlignment._distributeSpace(
            freeSpace: crossAxisFreeSpace,
            itemSpacing: runSpacing,
            itemCount: runMetrics.count,
            flipped: flipCrossAxis
        )
        let nextChild: (RenderBox) -> RenderBox? = flipMainAxis ? childBefore : childAfter

        var runCrossAxisOffset = runLeadingSpace
        let runs: [_RunMetrics] = flipCrossAxis ? runMetrics.reversed() : runMetrics
        for run in runs {
            let runCrossAxisExtent = run.axisSize.crossAxisExtent
            let childCount = run.childCount

            let mainAxisFreeSpace = max(
                0.0,
                containerAxisSize.mainAxisExtent - run.axisSize.mainAxisExtent
            )
            let (childLeadingSpace, childBetweenSpace) = alignment._distributeSpace(
                freeSpace: mainAxisFreeSpace,
                itemSpacing: spacing,
                itemCount: childCount,
                flipped: flipMainAxis
            )

            var childMainAxisOffset = childLeadingSpace

            var remainingChildCount = run.childCount
            var child: RenderBox? = run.leadingChild
            while let currentChild = child, remainingChildCount > 0 {
                let childSize = _AxisSize(
                    fromSize: getChildSize(currentChild),
                    direction: direction
                )
                let childMainAxisExtent = childSize.mainAxisExtent
                let childCrossAxisExtent = childSize.crossAxisExtent
                let childCrossAxisOffset =
                    effectiveCrossAlignment._alignment * (runCrossAxisExtent - childCrossAxisExtent)
                positionChild(
                    _getOffset(
                        mainAxisOffset: childMainAxisOffset,
                        crossAxisOffset: runCrossAxisOffset + childCrossAxisOffset
                    ),
                    currentChild
                )
                childMainAxisOffset += childMainAxisExtent + childBetweenSpace
                child = nextChild(currentChild)
                remainingChildCount -= 1
            }
            runCrossAxisOffset += runCrossAxisExtent + runBetweenSpace
        }
    }

    // MARK: - Hit Testing

    public override func hitTest(_ result: HitTestResult, position: Offset) -> Bool {
        defaultHitTestChildren(result as! BoxHitTestResult, position: position)
    }

    // MARK: - Painting

    // TODO: LayerHandle type may not exist - using optional ClipRectLayer instead
    private var _clipRectLayer: ClipRectLayer? = nil

    public override func paint(context: PaintingContext, offset: Offset) {
        // TODO(ianh): move the debug flex overflow paint logic somewhere common so
        // it can be reused here
        if _hasVisualOverflow && clipBehavior != .none {
            _clipRectLayer = context.pushClipRect(
                needsCompositing: needsCompositing,
                offset: offset,
                clipRect: Offset.zero & size,
                clipBehavior: clipBehavior,
                painter: { ctx, off in
                    defaultPaint(context: ctx, offset: off)
                },
                oldLayer: _clipRectLayer
            )
        } else {
            _clipRectLayer = nil
            defaultPaint(context: context, offset: offset)
        }
    }

    public override func dispose() {
        _clipRectLayer = nil
        super.dispose()
    }

    // MARK: - Debug

    // TODO: DiagnosticPropertiesBuilder may not exist - marking as TODO
    // public override func debugFillProperties(_ properties: DiagnosticPropertiesBuilder) {
    //     super.debugFillProperties(properties)
    //     properties.add(EnumProperty<Axis>('direction', direction))
    //     properties.add(EnumProperty<WrapAlignment>('alignment', alignment))
    //     properties.add(DoubleProperty('spacing', spacing))
    //     properties.add(EnumProperty<WrapAlignment>('runAlignment', runAlignment))
    //     properties.add(DoubleProperty('runSpacing', runSpacing))
    //     properties.add(DoubleProperty('crossAxisAlignment', runSpacing))
    //     properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null))
    //     properties.add(
    //       EnumProperty<VerticalDirection>(
    //         'verticalDirection',
    //         verticalDirection,
    //         defaultValue: VerticalDirection.down,
    //       ),
    //     )
    // }
}
