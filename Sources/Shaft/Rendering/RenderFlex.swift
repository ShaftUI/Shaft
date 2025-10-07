// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// How the child is inscribed into the available space.
///
/// See also:
///
///  * ``RenderFlex``, the flex render object.
///  * ``Column``, ``Row``, and ``Flex``, the flex widgets.
///  * ``Expanded``, the widget equivalent of [tight].
///  * ``Flexible``, the widget equivalent of [loose].
public enum FlexFit {
    /// The child is forced to fill the available space.
    ///
    /// The ``Expanded`` widget assigns this kind of [FlexFit] to its child.
    case tight

    /// The child can be at most as large as the available space (but is
    /// allowed to be smaller).
    ///
    /// The ``Flexible`` widget assigns this kind of [FlexFit] to its child.
    case loose
}

/// How much space should be occupied in the main axis.
///
/// During a flex layout, available space along the main axis is allocated to
/// children. After allocating space, there might be some remaining free space.
/// This value controls whether to maximize or minimize the amount of free
/// space, subject to the incoming layout constraints.
///
/// See also:
///
///  * ``Column``, ``Row``, and ``Flex``, the flex widgets.
///  * ``Expanded`` and ``Flexible``, the widgets that controls a flex widgets'
///    children's flex.
///  * ``RenderFlex``, the flex render object.
///  * [MainAxisAlignment], which controls how the free space is distributed.
public enum MainAxisSize {
    /// Minimize the amount of free space along the main axis, subject to the
    /// incoming layout constraints.
    ///
    /// If the incoming layout constraints have a large enough
    /// ``BoxConstraints/minWidth`` or ``BoxConstraints/minHeight``, there might still
    /// be a non-zero amount of free space.
    ///
    /// If the incoming layout constraints are unbounded, and any children have a
    /// non-zero [FlexParentData.flex] and a [FlexFit.tight] fit (as applied by
    /// ``Expanded``), the ``RenderFlex`` will assert, because there would be infinite
    /// remaining free space and boxes cannot be given infinite size.
    case min

    /// Maximize the amount of free space along the main axis, subject to the
    /// incoming layout constraints.
    ///
    /// If the incoming layout constraints have a small enough
    /// [BoxConstraints.maxWidth] or [BoxConstraints.maxHeight], there might still
    /// be no free space.
    ///
    /// If the incoming layout constraints are unbounded, the ``RenderFlex`` will
    /// assert, because there would be infinite remaining free space and boxes
    /// cannot be given infinite size.
    case max
}

/// How the children should be placed along the main axis in a flex layout.
///
/// See also:
///
///  * ``Column``, ``Row``, and ``Flex``, the flex widgets.
///  * ``RenderFlex``, the flex render object.
public enum MainAxisAlignment {
    /// Place the children as close to the start of the main axis as possible.
    ///
    /// If this value is used in a horizontal direction, a [TextDirection] must be
    /// available to determine if the start is the left or the right.
    ///
    /// If this value is used in a vertical direction, a [VerticalDirection] must be
    /// available to determine if the start is the top or the bottom.
    case start

    /// Place the children as close to the end of the main axis as possible.
    ///
    /// If this value is used in a horizontal direction, a [TextDirection] must be
    /// available to determine if the end is the left or the right.
    ///
    /// If this value is used in a vertical direction, a [VerticalDirection] must be
    /// available to determine if the end is the top or the bottom.
    case end

    /// Place the children as close to the middle of the main axis as possible.
    case center

    /// Place the free space evenly between the children.
    case spaceBetween

    /// Place the free space evenly between the children as well as half of that
    /// space before and after the first and last child.
    case spaceAround

    /// Place the free space evenly between the children as well as before and
    /// after the first and last child.
    case spaceEvenly
}

/// How the children should be placed along the cross axis in a flex layout.
///
/// See also:
///
///  * ``Column``, ``Row``, and ``Flex``, the flex widgets.
///  * ``RenderFlex``, the flex render object.
public enum CrossAxisAlignment {
    /// Place the children with their start edge aligned with the start side of
    /// the cross axis.
    ///
    /// For example, in a column (a flex with a vertical axis) whose
    /// [TextDirection] is [TextDirection.ltr], this aligns the left edge of the
    /// children along the left edge of the column.
    ///
    /// If this value is used in a horizontal direction, a [TextDirection] must be
    /// available to determine if the start is the left or the right.
    ///
    /// If this value is used in a vertical direction, a [VerticalDirection] must be
    /// available to determine if the start is the top or the bottom.
    case start

    /// Place the children as close to the end of the cross axis as possible.
    ///
    /// For example, in a column (a flex with a vertical axis) whose
    /// [TextDirection] is [TextDirection.ltr], this aligns the right edge of the
    /// children along the right edge of the column.
    ///
    /// If this value is used in a horizontal direction, a [TextDirection] must be
    /// available to determine if the end is the left or the right.
    ///
    /// If this value is used in a vertical direction, a [VerticalDirection] must be
    /// available to determine if the end is the top or the bottom.
    case end

    /// Place the children so that their centers align with the middle of the
    /// cross axis.
    ///
    /// This is the default cross-axis alignment.
    case center

    /// Require the children to fill the cross axis.
    ///
    /// This causes the constraints passed to the children to be tight in the
    /// cross axis.
    case stretch

    /// Place the children along the cross axis such that their baselines match.
    ///
    /// Because baselines are always horizontal, this alignment is intended for
    /// horizontal main axes. If the main axis is vertical, then this value is
    /// treated like [start].
    ///
    /// For horizontal main axes, if the minimum height constraint passed to the
    /// flex layout exceeds the intrinsic height of the cross axis, children will
    /// be aligned as close to the top as they can be while honoring the baseline
    /// alignment. In other words, the extra space will be below all the children.
    ///
    /// Children who report no baseline will be top-aligned.
    case baseline
}

public class FlexParentData: ContainerBoxParentData<RenderBox> {
    /// The flex factor to use for this child.
    ///
    /// If null or zero, the child is inflexible and determines its own size. If
    /// non-zero, the amount of space the child's can occupy in the main axis is
    /// determined by dividing the free space (after placing the inflexible
    /// children) according to the flex factors of the flexible children.
    public var flex: Float?

    /// How a flexible child is inscribed into the available space.
    ///
    /// If [flex] is non-zero, the [fit] determines whether the child fills the
    /// space the parent makes available during layout. If the fit is
    /// [FlexFit.tight], the child is required to fill the available space. If the
    /// fit is [FlexFit.loose], the child can be at most as large as the available
    /// space (but is allowed to be smaller).
    public var fit: FlexFit?
}

public class RenderFlex: RenderBox, RenderObjectWithChildren {
    public init(
        direction: Axis,
        mainAxisAlignment: MainAxisAlignment,
        mainAxisSize: MainAxisSize,
        crossAxisAlignment: CrossAxisAlignment,
        textDirection: TextDirection? = nil,
        verticalDirection: VerticalDirection? = nil,
        textBaseline: TextBaseline? = nil,
        clipBehavior: Clip,
        children: [RenderBox]? = nil
    ) {
        self.direction = direction
        self.mainAxisAlignment = mainAxisAlignment
        self.mainAxisSize = mainAxisSize
        self.crossAxisAlignment = crossAxisAlignment
        self.textDirection = textDirection
        self.verticalDirection = verticalDirection
        self.textBaseline = textBaseline
        self.clipBehavior = clipBehavior
        super.init()
        if let children {
            addAll(children)
        }
    }

    public typealias ChildType = RenderBox
    public typealias ParentDataType = FlexParentData
    public var childMixin = RenderContainerMixin<RenderBox>()

    /// The direction to use as the main axis.
    public var direction: Axis {
        didSet {
            if direction != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// How the children should be placed along the main axis.
    ///
    /// If the [direction] is [Axis.horizontal], and the [mainAxisAlignment] is
    /// either [MainAxisAlignment.start] or [MainAxisAlignment.end], then the
    /// [textDirection] must not be null.
    ///
    /// If the [direction] is [Axis.vertical], and the [mainAxisAlignment] is
    /// either [MainAxisAlignment.start] or [MainAxisAlignment.end], then the
    /// [verticalDirection] must not be null.
    public var mainAxisAlignment: MainAxisAlignment {
        didSet {
            if mainAxisAlignment != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// How much space should be occupied in the main axis.
    ///
    /// After allocating space to children, there might be some remaining free
    /// space. This value controls whether to maximize or minimize the amount of
    /// free space, subject to the incoming layout constraints.
    ///
    /// If some children have a non-zero flex factors (and none have a fit of
    /// [FlexFit.loose]), they will expand to consume all the available space and
    /// there will be no remaining free space to maximize or minimize, making this
    /// value irrelevant to the final layout.
    public var mainAxisSize: MainAxisSize {
        didSet {
            if mainAxisSize != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// How the children should be placed along the cross axis.
    ///
    /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
    /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
    /// [verticalDirection] must not be null.
    ///
    /// If the [direction] is [Axis.vertical], and the [crossAxisAlignment] is
    /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
    /// [textDirection] must not be null.
    public var crossAxisAlignment: CrossAxisAlignment {
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
    /// of the [mainAxisAlignment] property's [MainAxisAlignment.start] and
    /// [MainAxisAlignment.end] values.
    ///
    /// If the [direction] is [Axis.horizontal], and either the
    /// [mainAxisAlignment] is either [MainAxisAlignment.start] or
    /// [MainAxisAlignment.end], or there's more than one child, then the
    /// [textDirection] must not be null.
    ///
    /// If the [direction] is [Axis.vertical], this controls the meaning of the
    /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
    /// [CrossAxisAlignment.end] values.
    ///
    /// If the [direction] is [Axis.vertical], and the [crossAxisAlignment] is
    /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
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
    /// are painted in (down or up), the meaning of the [mainAxisAlignment]
    /// property's [MainAxisAlignment.start] and [MainAxisAlignment.end] values.
    ///
    /// If the [direction] is [Axis.vertical], and either the [mainAxisAlignment]
    /// is either [MainAxisAlignment.start] or [MainAxisAlignment.end], or there's
    /// more than one child, then the [verticalDirection] must not be null.
    ///
    /// If the [direction] is [Axis.horizontal], this controls the meaning of the
    /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
    /// [CrossAxisAlignment.end] values.
    ///
    /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
    /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
    /// [verticalDirection] must not be null.
    public var verticalDirection: VerticalDirection? {
        didSet {
            if verticalDirection != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// If aligning items according to their baseline, which baseline to use.
    ///
    /// Must not be null if [crossAxisAlignment] is [CrossAxisAlignment.baseline].
    public var textBaseline: TextBaseline? {
        didSet {
            if textBaseline != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// Defaults to [Clip.none].
    public var clipBehavior: Clip {
        didSet {
            if clipBehavior != oldValue {
                markNeedsPaint()
                // markNeedsSemanticsUpdate()
            }
        }
    }

    // Set during layout if overflow occurred on the main axis.
    private var overflow: Float = 0

    // Check whether any meaningful overflow is present. Values below an epsilon
    // are treated as not overflowing.
    public var hasOverflow: Bool { overflow > precisionErrorTolerance }

    public override func setupParentData(_ child: RenderObject) {
        if !(child.parentData is FlexParentData) {
            child.parentData = FlexParentData()
        }
    }

    private func getFlex(_ child: ChildType) -> Float {
        let childParentData = child.parentData as! FlexParentData
        return childParentData.flex ?? 0.0
    }

    private func getFit(_ child: ChildType) -> FlexFit {
        let childParentData = child.parentData as! FlexParentData
        return childParentData.fit ?? FlexFit.tight
    }

    private func getMainSize(_ size: Size) -> Float {
        switch direction {
        case Axis.horizontal:
            return size.width
        case Axis.vertical:
            return size.height
        }
    }

    private func getCrossSize(_ size: Size) -> Float {
        switch direction {
        case Axis.horizontal:
            return size.height
        case Axis.vertical:
            return size.width
        }
    }

    /// Calls `layoutChild` for each child and determines the appropriate size
    /// for self.
    private func computeSizes(constraints: BoxConstraints, layoutChild: ChildLayouter)
        -> LayoutSizes
    {
        // assert(_debugHasNecessaryDirections);
        var totalFlex: Float = 0
        let maxMainSize =
            direction == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight
        let canFlex = maxMainSize < Float.infinity

        var crossSize: Float = 0.0
        var allocatedSize: Float = 0.0  // Sum of the sizes of the non-flexible children.
        var lastFlexChild: RenderBox?

        // Layout non-flexible children and accumulate their sizes.
        visitChildren { child in
            let childParentData = child.parentData as! FlexParentData
            let flex = getFlex(child)
            if flex > 0 {
                totalFlex += flex
                lastFlexChild = child
            } else {
                let innerConstraints =
                    if self.crossAxisAlignment == .stretch {
                        switch direction {
                        case .horizontal:
                            BoxConstraints.tightFor(height: constraints.maxHeight)
                        case .vertical:
                            BoxConstraints.tightFor(width: constraints.maxWidth)
                        }
                    } else {
                        switch direction {
                        case .horizontal:
                            BoxConstraints(maxHeight: constraints.maxHeight)
                        case .vertical:
                            BoxConstraints(maxWidth: constraints.maxWidth)
                        }
                    }

                let childSize = layoutChild(child, innerConstraints)
                allocatedSize += getMainSize(childSize)
                crossSize = max(crossSize, getCrossSize(childSize))
            }
            assert(child.parentData === childParentData)
        }

        // Distribute free space to flexible children.
        let freeSpace = max(0.0, (canFlex ? maxMainSize : 0.0) - allocatedSize)
        var allocatedFlexSpace: Float = 0.0
        if totalFlex > 0 {
            let spacePerFlex = canFlex ? (freeSpace / Float(totalFlex)) : Float.nan
            visitChildren { child in
                let flex = getFlex(child)
                if flex > 0 {
                    let maxChildExtent =
                        if canFlex {
                            if child === lastFlexChild {
                                freeSpace - allocatedFlexSpace
                            } else {
                                spacePerFlex * Float(flex)
                            }
                        } else {
                            Float.infinity
                        }

                    let minChildExtent =
                        switch getFit(child) {
                        case .loose: Float(0.0)
                        case .tight: maxChildExtent
                        }

                    let innerConstraints =
                        if crossAxisAlignment == .stretch {
                            switch direction {
                            case .horizontal:
                                BoxConstraints(
                                    minWidth: minChildExtent,
                                    maxWidth: maxChildExtent,
                                    minHeight: constraints.maxHeight,
                                    maxHeight: constraints.maxHeight
                                )
                            case .vertical:
                                BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                    maxWidth: constraints.maxWidth,
                                    minHeight: minChildExtent,
                                    maxHeight: maxChildExtent
                                )
                            }
                        } else {
                            switch direction {
                            case .horizontal:
                                BoxConstraints(
                                    minWidth: minChildExtent,
                                    maxWidth: maxChildExtent,
                                    maxHeight: constraints.maxHeight
                                )
                            case .vertical:
                                BoxConstraints(
                                    maxWidth: constraints.maxWidth,
                                    minHeight: minChildExtent,
                                    maxHeight: maxChildExtent
                                )
                            }
                        }
                    let childSize = layoutChild(child, innerConstraints)
                    let childMainSize = getMainSize(childSize)
                    allocatedSize += childMainSize
                    allocatedFlexSpace += maxChildExtent
                    crossSize = max(crossSize, getCrossSize(childSize))
                }
            }
        }

        let idealSize = canFlex && mainAxisSize == MainAxisSize.max ? maxMainSize : allocatedSize
        return LayoutSizes(
            mainSize: idealSize,
            crossSize: crossSize,
            allocatedSize: allocatedSize
        )
    }

    public override func performLayout() {
        let sizes = computeSizes(
            constraints: boxConstraint,
            layoutChild: ChildLayoutHelper.layoutChild
        )

        let allocatedSize = sizes.allocatedSize
        var actualSize = sizes.mainSize
        var crossSize = sizes.crossSize
        // var maxBaselineDistance = 0.0
        // if crossAxisAlignment == CrossAxisAlignment.baseline {
        //     ...
        // }

        // Align items along the main axis.
        switch direction {
        case Axis.horizontal:
            size = boxConstraint.constrain(Size(actualSize, crossSize))
            actualSize = size.width
            crossSize = size.height
        case Axis.vertical:
            size = boxConstraint.constrain(Size(crossSize, actualSize))
            actualSize = size.height
            crossSize = size.width
        }
        let actualSizeDelta = actualSize - allocatedSize
        overflow = max(0.0, -actualSizeDelta)
        let remainingSpace = max(0.0, actualSizeDelta)
        let leadingSpace: Float
        let betweenSpace: Float
        // flipMainAxis is used to decide whether to lay out
        // left-to-right/top-to-bottom (false), or right-to-left/bottom-to-top
        // (true). The _startIsTopLeft will return null if there's only one child
        // and the relevant direction is null, in which case we arbitrarily decide
        // to flip, but that doesn't have any detectable effect.
        let flipMainAxis = !(startIsTopLeft(direction, textDirection, verticalDirection) ?? true)
        switch mainAxisAlignment {
        case MainAxisAlignment.start:
            leadingSpace = 0.0
            betweenSpace = 0.0
        case MainAxisAlignment.end:
            leadingSpace = remainingSpace
            betweenSpace = 0.0
        case MainAxisAlignment.center:
            leadingSpace = remainingSpace / 2.0
            betweenSpace = 0.0
        case MainAxisAlignment.spaceBetween:
            leadingSpace = 0.0
            betweenSpace = childCount > 1 ? remainingSpace / Float(childCount - 1) : 0.0
        case MainAxisAlignment.spaceAround:
            betweenSpace = childCount > 0 ? remainingSpace / Float(childCount) : 0.0
            leadingSpace = betweenSpace / 2.0
        case MainAxisAlignment.spaceEvenly:
            betweenSpace = childCount > 0 ? remainingSpace / Float(childCount + 1) : 0.0
            leadingSpace = betweenSpace
        }

        var childMainPosition = flipMainAxis ? actualSize - leadingSpace : leadingSpace
        visitChildren { child in
            let childParentData = child.parentData as! FlexParentData
            let childCrossPosition =
                switch crossAxisAlignment {
                case .start, .end:
                    startIsTopLeft(direction.flip(), textDirection, verticalDirection)
                        == (crossAxisAlignment == .start)
                        ? Float(0.0)
                        : crossSize - getCrossSize(child.size)
                case .center:
                    crossSize / Float(2.0) - getCrossSize(child.size) / Float(2.0)
                case .stretch:
                    Float(0.0)
                case .baseline:
                    if direction == .horizontal {
                        // assert(textBaseline != nil)
                        // let distance = child.getDistanceToBaseline(textBaseline!, onlyReal: true)
                        // if let distance {
                        //     maxBaselineDistance - distance
                        // } else {
                        //     0.0
                        // }
                        fatalError()
                    } else {
                        Float(0.0)
                    }
                }
            if flipMainAxis {
                childMainPosition -= getMainSize(child.size)
            }
            switch direction {
            case Axis.horizontal:
                childParentData.offset = Offset(childMainPosition, childCrossPosition)
            case Axis.vertical:
                childParentData.offset = Offset(childCrossPosition, childMainPosition)
            }
            if flipMainAxis {
                childMainPosition -= betweenSpace
            } else {
                childMainPosition += getMainSize(child.size) + betweenSpace
            }
        }
    }

    public override func hitTestChildren(_ result: HitTestResult, position: Offset) -> Bool {
        defaultHitTestChildren(result as! BoxHitTestResult, position: position)
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        defaultPaint(context: context, offset: offset)
    }
}

private struct LayoutSizes {
    var mainSize: Float
    var crossSize: Float
    var allocatedSize: Float
}

private func startIsTopLeft(
    _ direction: Axis,
    _ textDirection: TextDirection?,
    _ verticalDirection: VerticalDirection?
) -> Bool? {
    // If the relevant value of textDirection or verticalDirection is null, this returns null too.
    switch direction {
    case Axis.horizontal:
        if let textDirection {
            switch textDirection {
            case TextDirection.ltr: true
            case TextDirection.rtl: false
            }
        } else {
            nil
        }
    case Axis.vertical:
        if let verticalDirection {
            switch verticalDirection {
            case VerticalDirection.down: true
            case VerticalDirection.up: false
            }
        } else {
            nil
        }
    }
}
