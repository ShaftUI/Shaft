// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Parent data for use with [RenderStack].
public class StackParentData: ContainerBoxParentData<RenderBox> {
    /// The distance by which the child's top edge is inset from the top of the stack.
    public var top: Float?

    /// The distance by which the child's right edge is inset from the right of the stack.
    public var right: Float?

    /// The distance by which the child's bottom edge is inset from the bottom of the stack.
    public var bottom: Float?

    /// The distance by which the child's left edge is inset from the left of the stack.
    public var left: Float?

    /// The child's width.
    ///
    /// Ignored if both left and right are non-null.
    public var width: Float?

    /// The child's height.
    ///
    /// Ignored if both top and bottom are non-null.
    public var height: Float?

    /// Whether this child is considered positioned.
    ///
    /// A child is positioned if any of the top, right, bottom, or left properties
    /// are non-null. Positioned children do not factor into determining the size
    /// of the stack but are instead placed relative to the non-positioned
    /// children in the stack.
    public var isPositioned: Bool {
        top != nil || right != nil || bottom != nil || left != nil || width != nil || height != nil
    }
}

extension StackParentData: CustomStringConvertible {
    public var description: String {
        "top: \(top ?? 0), right: \(right ?? 0), bottom: \(bottom ?? 0), left: \(left ?? 0), width: \(width ?? 0), height: \(height ?? 0)"
    }
}

/// How to size the non-positioned children of a [Stack].
///
/// This enum is used with [Stack.fit] and [RenderStack.fit] to control
/// how the [BoxConstraints] passed from the stack's parent to the stack's child
/// are adjusted.
///
/// See also:
///
///  * [Stack], the widget that uses this.
///  * [RenderStack], the render object that implements the stack algorithm.
public enum StackFit {
    /// The constraints passed to the stack from its parent are loosened.
    ///
    /// For example, if the stack has constraints that force it to 350x600, then
    /// this would allow the non-positioned children of the stack to have any
    /// width from zero to 350 and any height from zero to 600.
    ///
    /// See also:
    ///
    ///  * [Center], which loosens the constraints passed to its child and then
    ///    centers the child in itself.
    ///  * [BoxConstraints.loosen], which implements the loosening of box
    ///    constraints.
    case loose

    /// The constraints passed to the stack from its parent are tightened to the
    /// biggest size allowed.
    ///
    /// For example, if the stack has loose constraints with a width in the range
    /// 10 to 100 and a height in the range 0 to 600, then the non-positioned
    /// children of the stack would all be sized as 100 pixels wide and 600 high.
    case expand

    /// The constraints passed to the stack from its parent are passed unmodified
    /// to the non-positioned children.
    ///
    /// For example, if a [Stack] is an [Expanded] child of a [Row], the
    /// horizontal constraints will be tight and the vertical constraints will be
    /// loose.
    case passthrough
}

/// Implements the stack layout algorithm.
///
/// In a stack layout, the children are positioned on top of each other in the
/// order in which they appear in the child list. First, the non-positioned
/// children (those with null values for top, right, bottom, and left) are
/// laid out and initially placed in the upper-left corner of the stack. The
/// stack is then sized to enclose all of the non-positioned children. If there
/// are no non-positioned children, the stack becomes as large as possible.
///
/// The final location of non-positioned children is determined by the alignment
/// parameter. The left of each non-positioned child becomes the
/// difference between the child's width and the stack's width scaled by
/// alignment.x. The top of each non-positioned child is computed
/// similarly and scaled by alignment.y. So if the alignment x and y properties
/// are 0.0 (the default) then the non-positioned children remain in the
/// upper-left corner. If the alignment x and y properties are 0.5 then the
/// non-positioned children are centered within the stack.
///
/// Next, the positioned children are laid out. If a child has top and bottom
/// values that are both non-null, the child is given a fixed height determined
/// by subtracting the sum of the top and bottom values from the height of the stack.
/// Similarly, if the child has right and left values that are both non-null,
/// the child is given a fixed width derived from the stack's width.
/// Otherwise, the child is given unbounded constraints in the non-fixed dimensions.
///
/// Once the child is laid out, the stack positions the child
/// according to the top, right, bottom, and left properties of their
/// [StackParentData]. For example, if the bottom value is 10.0, the
/// bottom edge of the child will be inset 10.0 pixels from the bottom
/// edge of the stack. If the child extends beyond the bounds of the
/// stack, the stack will clip the child's painting to the bounds of
/// the stack.
public class RenderStack: RenderBox, RenderObjectWithChildren {
    internal init(
        alignment: any AlignmentGeometry = Alignment.topLeft,
        textDirection: TextDirection,
        fit: StackFit,
        clipBehavior: Clip,
        children: [RenderBox] = []
    ) {
        self.alignment = alignment
        self.textDirection = textDirection
        self.fit = fit
        self.clipBehavior = clipBehavior
        super.init()
        addAll(children)
    }

    public typealias ChildType = RenderBox
    public typealias ParentDataType = StackParentData
    public var childMixin = RenderContainerMixin<RenderBox>()

    /// How to align the non-positioned or partially-positioned children in the
    /// stack.
    ///
    /// The non-positioned children are placed relative to each other such that
    /// the points determined by [alignment] are co-located. For example, if the
    /// [alignment] is [Alignment.topLeft], then the top left corner of
    /// each non-positioned child will be located at the same global coordinate.
    ///
    /// Partially-positioned children, those that do not specify an alignment in a
    /// particular axis (e.g. that have neither `top` nor `bottom` set), use the
    /// alignment to determine how they should be positioned in that
    /// under-specified axis.
    ///
    /// If this is set to an [AlignmentDirectional] object, then [textDirection]
    /// must not be null.
    var alignment: any AlignmentGeometry {
        didSet {
            if alignment.isEqualTo(oldValue) {
                markNeedResolution()
            }
        }
    }

    /// The text direction with which to resolve [alignment].
    ///
    /// This may be changed to null, but only after the [alignment] has been changed
    /// to a value that does not depend on the direction.
    var textDirection: TextDirection {
        didSet {
            if textDirection != oldValue {
                markNeedResolution()
            }
        }
    }

    /// How to size the non-positioned children in the stack.
    ///
    /// The constraints passed into the [RenderStack] from its parent are either
    /// loosened ([StackFit.loose]) or tightened to their biggest size
    /// ([StackFit.expand]).
    var fit: StackFit {
        didSet {
            if fit != oldValue {
                markNeedsLayout()
            }
        }
    }

    /// Stacks only clip children whose geometry overflow the stack. A child that
    /// paints outside its bounds (e.g. a box with a shadow) will not be clipped,
    /// regardless of the value of this property. Similarly, a child that itself
    /// has a descendant that overflows the stack will not be clipped, as only the
    /// geometry of the stack's direct children are considered.
    ///
    /// To clip children whose geometry does not overflow the stack, consider
    /// using a [RenderClipRect] render object.
    ///
    /// Defaults to [Clip.hardEdge].
    var clipBehavior: Clip {
        didSet {
            if clipBehavior != oldValue {
                markNeedsPaint()
                // markNeedsSemanticsUpdate()
            }
        }
    }

    /// Whether any of the children of this render object paints outside the
    /// bounds of this object. Updated during layout based on the positions and
    /// sizes of the children.
    private var hasVisualOverflow = false

    private var resolvedAlignment: Alignment? = nil

    private func resolve() {
        if resolvedAlignment == nil {
            resolvedAlignment = alignment.resolve(textDirection)
        }
    }

    private func markNeedResolution() {
        resolvedAlignment = nil
        markNeedsLayout()
    }

    /// Lays out the positioned `child` according to `alignment` within a Stack of `size`.
    ///
    /// Returns true when the child has visual overflow.
    private func layoutPositionedChild(
        _ child: RenderBox,
        _ childParentData: StackParentData,
        _ size: Size,
        _ alignment: Alignment
    ) -> Bool {
        assert(childParentData.isPositioned)
        assert(child.parentData === childParentData)

        var hasVisualOverflow = false
        var childConstraints = BoxConstraints()

        if let left = childParentData.left, let right = childParentData.right {
            childConstraints = childConstraints.tighten(width: size.width - right - left)
        } else if let width = childParentData.width {
            childConstraints = childConstraints.tighten(width: width)
        }

        if let top = childParentData.top, let bottom = childParentData.bottom {
            childConstraints = childConstraints.tighten(height: size.height - bottom - top)
        } else if let height = childParentData.height {
            childConstraints = childConstraints.tighten(height: height)
        }

        child.layout(childConstraints, parentUsesSize: true)

        let x: Float
        if let left = childParentData.left {
            x = left
        } else if let right = childParentData.right {
            x = size.width - right - child.size.width
        } else {
            x = alignment.alongOffset(size - child.size).dx
        }

        if x < 0 || x + child.size.width > size.width {
            hasVisualOverflow = true
        }

        let y: Float
        if let top = childParentData.top {
            y = top
        } else if let bottom = childParentData.bottom {
            y = size.height - bottom - child.size.height
        } else {
            y = alignment.alongOffset(size - child.size).dy
        }

        if y < 0 || y + child.size.height > size.height {
            hasVisualOverflow = true
        }

        childParentData.offset = Offset(x, y)

        return hasVisualOverflow
    }

    private func computeSize(
        constraints: BoxConstraints,
        layoutChild: (RenderBox, BoxConstraints) -> Size
    ) -> Size {
        resolve()
        assert(resolvedAlignment != nil)

        var hasNonPositionedChildren = false
        if childCount == 0 {
            return constraints.biggest.isFinite ? constraints.biggest : constraints.smallest
        }

        var width = constraints.minWidth
        var height = constraints.minHeight

        let nonPositionedConstraints =
            switch fit {
            case .loose:
                constraints.loosen()
            case .expand:
                BoxConstraints.tight(constraints.biggest)
            case .passthrough:
                constraints
            }

        visitChildren { child in
            let childParentData = child.parentData as! StackParentData

            if !childParentData.isPositioned {
                hasNonPositionedChildren = true

                let childSize = layoutChild(child, nonPositionedConstraints)

                width = max(width, childSize.width)
                height = max(height, childSize.height)
            }
        }

        let size: Size
        if hasNonPositionedChildren {
            size = Size(width, height)
            assert(size.width == constraints.constrainWidth(width))
            assert(size.height == constraints.constrainHeight(height))
        } else {
            size = constraints.biggest
        }

        assert(size.isFinite)
        return size
    }

    public override func setupParentData(_ child: RenderObject) {
        if !(child.parentData is StackParentData) {
            child.parentData = StackParentData()
        }
    }

    public override func performLayout() {
        hasVisualOverflow = false

        size = computeSize(constraints: boxConstraint, layoutChild: ChildLayoutHelper.layoutChild)

        assert(resolvedAlignment != nil)
        visitChildren { child in
            let childParentData = child.parentData as! StackParentData

            if !childParentData.isPositioned {
                childParentData.offset = resolvedAlignment!.alongOffset(size - child.size)
            } else {
                hasVisualOverflow =
                    layoutPositionedChild(child, childParentData, size, resolvedAlignment!)
                    || hasVisualOverflow
            }

            assert(child.parentData === childParentData)
        }
    }

    public override func hitTest(_ result: HitTestResult, position: Offset) -> Bool {
        defaultHitTestChildren(result as! BoxHitTestResult, position: position)
    }

    /// Override in subclasses to customize how the stack paints.
    ///
    /// By default, the stack uses [defaultPaint]. This function is called by
    /// [paint] after potentially applying a clip to contain visual overflow.
    open func paintStack(context: PaintingContext, offset: Offset) {
        defaultPaint(context: context, offset: offset)
    }

    private var clipRectLayer: ClipRectLayer? = nil

    public override func paint(context: PaintingContext, offset: Offset) {
        if clipBehavior != .none && hasVisualOverflow {
            clipRectLayer = context.pushClipRect(
                needsCompositing: needsCompositing,
                offset: offset,
                clipRect: Offset.zero & size,
                clipBehavior: clipBehavior,
                painter: paintStack,
                oldLayer: clipRectLayer
            )
        } else {
            paintStack(context: context, offset: offset)
        }
    }
}
