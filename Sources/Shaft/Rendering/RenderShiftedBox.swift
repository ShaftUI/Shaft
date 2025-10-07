// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Signature for a function that transforms a ``BoxConstraints`` to another
/// ``BoxConstraints``.
///
/// Used by ``RenderConstraintsTransformBox`` and ``ConstraintsTransformBox``.
/// Typically the caller requires the returned ``BoxConstraints`` to be
/// ``BoxConstraints/isNormalized``.
public class RenderShiftedBox: RenderBox, RenderObjectWithSingleChild {
    public typealias ChildType = RenderBox
    public var childMixin = RenderSingleChildMixin<RenderBox>()

    internal init(_ child: RenderBox?) {
        super.init()
        self.child = child
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        if let child {
            let childParentData = child.parentData as! BoxParentData
            context.paintChild(child, offset: childParentData.offset + offset)
        }
    }

    public override func hitTestChildren(_ result: HitTestResult, position: Offset) -> Bool {
        guard let child else {
            return false
        }
        let childParentData = child.parentData as! BoxParentData
        return (result as! BoxHitTestResult).addWithPaintOffset(
            offset: childParentData.offset,
            position: position,
            hitTest: { result, transformed in
                assert(transformed == position - childParentData.offset)
                return child.hitTest(result, position: transformed)
            }
        )
    }
}

/// Insets its child by the given padding.
///
/// When passing layout constraints to its child, padding shrinks the
/// constraints by the given padding, causing the child to layout at a smaller
/// size. Padding then sizes itself to its child's size, inflated by the
/// padding, effectively creating empty space around the child.
public class RenderPadding: RenderShiftedBox {
    public init(
        padding: EdgeInsetsGeometry,
        textDirection: TextDirection? = nil,
        child: RenderBox? = nil
    ) {
        self.padding = padding
        self.textDirection = textDirection
        super.init(child)
    }

    /// The amount to pad the child in each dimension.
    ///
    /// If this is set to an [EdgeInsetsDirectional] object, then ``textDirection``
    /// must not be null.

    public var padding: EdgeInsetsGeometry {
        didSet {
            if !padding.isEqualTo(oldValue) {
                markNeedResolution()
            }
        }
    }

    /// The text direction with which to resolve ``padding``.
    ///
    /// This may be changed to null, but only after the ``padding`` has been changed
    /// to a value that does not depend on the direction.
    public var textDirection: TextDirection? {
        didSet {
            if textDirection != oldValue {
                markNeedResolution()
            }
        }
    }

    private var resolvedPadding: EdgeInsets? = nil

    private func markNeedResolution() {
        resolvedPadding = nil
        markNeedsLayout()
    }

    private func resolve() {
        if resolvedPadding != nil {
            return
        }
        resolvedPadding = padding.resolve(.ltr)
        // assert(resolvedPadding!.isNonNegative)
    }

    public override func performLayout() {
        resolve()

        guard let child else {
            size = boxConstraint.constrain(
                Size(
                    resolvedPadding!.left + resolvedPadding!.right,
                    resolvedPadding!.top + resolvedPadding!.bottom
                )
            )
            return
        }

        let innerConstraints = boxConstraint.deflate(resolvedPadding!)
        child.layout(innerConstraints, parentUsesSize: true)
        let childParentData = child.parentData as! BoxParentData
        childParentData.offset = Offset(resolvedPadding!.left, resolvedPadding!.top)
        size = boxConstraint.constrain(
            Size(
                resolvedPadding!.left + child.size.width + resolvedPadding!.right,
                resolvedPadding!.top + child.size.height + resolvedPadding!.bottom
            )
        )
    }
}

/// Abstract class for one-child-layout render boxes that use a
/// ``AlignmentGeometry`` to align their children.
public class RenderAligningShiftedBox: RenderShiftedBox {
    /// Initializes member variables for subclasses.
    ///
    /// The ``textDirection`` must be non-null if the ``alignment`` is
    /// direction-sensitive.
    public init(
        alignment: any AlignmentGeometry = .center,
        textDirection: TextDirection = .ltr,
        child: RenderBox? = nil
    ) {
        self.alignment = alignment
        self.textDirection = textDirection
        super.init(child)
    }

    /// The [Alignment] to use for aligning the child.
    ///
    /// This is the ``alignment`` resolved against ``textDirection``. Subclasses should
    /// use [resolvedAlignment] instead of ``alignment`` directly, for computing the
    /// child's offset.
    ///
    /// The [performLayout] method will be called when the value changes.
    public var resolvedAlignment: Alignment {
        return _resolvedAlignment ?? alignment.resolve(textDirection)
    }
    private var _resolvedAlignment: Alignment?

    private func _markNeedResolution() {
        _resolvedAlignment = nil
        markNeedsLayout()
    }

    /// How to align the child.
    ///
    /// The x and y values of the alignment control the horizontal and vertical
    /// alignment, respectively. An x value of -1.0 means that the left edge of
    /// the child is aligned with the left edge of the parent whereas an x value
    /// of 1.0 means that the right edge of the child is aligned with the right
    /// edge of the parent. Other values interpolate (and extrapolate) linearly.
    /// For example, a value of 0.0 means that the center of the child is aligned
    /// with the center of the parent.
    ///
    /// If this is set to an [AlignmentDirectional] object, then
    /// ``textDirection`` must not be null.
    public var alignment: any AlignmentGeometry {
        didSet {
            if alignment.isEqualTo(oldValue) {
                return
            }
            _markNeedResolution()
        }
    }

    /// The text direction with which to resolve ``alignment``.
    ///
    /// This may be changed to null, but only after ``alignment`` has been changed
    /// to a value that does not depend on the direction.
    public var textDirection: TextDirection = .ltr {
        didSet {
            if textDirection == oldValue {
                return
            }
            _markNeedResolution()
        }
    }

    /// Apply the current ``alignment`` to the [child].
    ///
    /// Subclasses should call this method if they have a child, to have
    /// this class perform the actual alignment. If there is no child,
    /// do not call this method.
    ///
    /// This method must be called after the child has been laid out and
    /// this object's own size has been set.
    public func alignChild() {
        assert(child != nil)
        // assert(!child!.debugNeedsLayout)
        assert(child!.hasSize)
        assert(hasSize)
        let childParentData = child!.parentData as! BoxParentData
        childParentData.offset = resolvedAlignment.alongOffset(size - child!.size)
    }
}
/// Positions its child using an ``AlignmentGeometry``.
///
/// For example, to align a box at the bottom right, you would pass this box a
/// tight constraint that is bigger than the child's natural size,
/// with an alignment of [Alignment.bottomRight].
///
/// By default, sizes to be as big as possible in both axes. If either axis is
/// unconstrained, then in that direction it will be sized to fit the child's
/// dimensions. Using widthFactor and heightFactor you can force this latter
/// behavior in all cases.
public class RenderPositionedBox: RenderAligningShiftedBox {
    /// Creates a render object that positions its child.
    public init(
        child: RenderBox? = nil,
        widthFactor: Float? = nil,
        heightFactor: Float? = nil,
        alignment: any AlignmentGeometry,
        textDirection: TextDirection = .ltr
    ) {
        assert(widthFactor == nil || widthFactor! >= 0.0)
        assert(heightFactor == nil || heightFactor! >= 0.0)
        self.widthFactor = widthFactor
        self.heightFactor = heightFactor
        super.init(alignment: alignment, textDirection: textDirection, child: child)
    }

    /// If non-null, sets its width to the child's width multiplied by this factor.
    ///
    /// Can be both greater and less than 1.0 but must be positive.
    public var widthFactor: Float? {
        didSet {
            assert(widthFactor == nil || widthFactor! >= 0.0)
            if widthFactor == oldValue {
                return
            }
            markNeedsLayout()
        }
    }

    /// If non-null, sets its height to the child's height multiplied by this factor.
    ///
    /// Can be both greater and less than 1.0 but must be positive.
    public var heightFactor: Float? {
        didSet {
            assert(heightFactor == nil || heightFactor! >= 0.0)
            if heightFactor == oldValue {
                return
            }
            markNeedsLayout()
        }
    }

    public override func computeMinIntrinsicWidth(_ height: Float) -> Float {
        return super.computeMinIntrinsicWidth(height) * (widthFactor ?? 1)
    }

    public override func computeMaxIntrinsicWidth(_ height: Float) -> Float {
        return super.computeMaxIntrinsicWidth(height) * (widthFactor ?? 1)
    }

    public override func computeMinIntrinsicHeight(_ width: Float) -> Float {
        return super.computeMinIntrinsicHeight(width) * (heightFactor ?? 1)
    }

    public override func computeMaxIntrinsicHeight(_ width: Float) -> Float {
        return super.computeMaxIntrinsicHeight(width) * (heightFactor ?? 1)
    }

    public override func computeDryLayout(_ constraints: BoxConstraints) -> Size {
        super.computeDryLayout(constraints)
    }

    // public override func computeDryLayout(_ constraints: BoxConstraints) -> Size {
    //     let shrinkWrapWidth = widthFactor != nil || constraints.maxWidth == .infinity
    //     let shrinkWrapHeight = heightFactor != nil || constraints.maxHeight == .infinity
    //     if let child = child {
    //         let childSize = child.getDryLayout(constraints.loosen())
    //         return constraints.constrain(
    //             Size(
    //                 width: shrinkWrapWidth ? childSize.width * (widthFactor ?? 1.0) : .infinity,
    //                 height: shrinkWrapHeight ? childSize.height * (heightFactor ?? 1.0) : .infinity
    //             )
    //         )
    //     }
    //     return constraints.constrain(
    //         Size(
    //             width: shrinkWrapWidth ? 0.0 : .infinity,
    //             height: shrinkWrapHeight ? 0.0 : .infinity
    //         )
    //     )
    // }

    public override func performLayout() {
        let constraints = boxConstraint
        let shrinkWrapWidth = widthFactor != nil || constraints.maxWidth == .infinity
        let shrinkWrapHeight = heightFactor != nil || constraints.maxHeight == .infinity

        if let child = child {
            child.layout(constraints.loosen(), parentUsesSize: true)
            size = constraints.constrain(
                Size(
                    shrinkWrapWidth ? child.size.width * (widthFactor ?? 1.0) : .infinity,
                    shrinkWrapHeight
                        ? child.size.height * (heightFactor ?? 1.0) : .infinity
                )
            )
            alignChild()
        } else {
            size = constraints.constrain(
                Size(
                    shrinkWrapWidth ? 0.0 : .infinity,
                    shrinkWrapHeight ? 0.0 : .infinity
                )
            )
        }
    }
}

/// Sizes its child to a fraction of the total available space.
///
/// For both its width and height, this render object imposes a tight constraint
/// on its child that is a multiple (typically less than 1.0) of the maximum
/// constraint it received from its parent on that axis. If the factor for a
/// given axis is nil, then the constraints from the parent are just passed
/// through instead.
///
/// It then tries to size itself to the size of its child. Where this is not
/// possible (e.g. if the constraints from the parent are themselves tight), the
/// child is aligned according to alignment.
public class RenderFractionallySizedOverflowBox: RenderAligningShiftedBox {
    /// Creates a render box that sizes its child to a fraction of the total
    /// available space.
    ///
    /// If non-nil, the widthFactor and heightFactor arguments must be
    /// non-negative.
    ///
    /// The textDirection must be non-nil if the alignment is
    /// direction-sensitive.
    public init(
        child: RenderBox? = nil,
        widthFactor: Float? = nil,
        heightFactor: Float? = nil,
        alignment: any AlignmentGeometry = Alignment.center,
        textDirection: TextDirection = .ltr
    ) {
        self.widthFactor = widthFactor
        self.heightFactor = heightFactor
        super.init(alignment: alignment, textDirection: textDirection, child: child)
        assert(widthFactor == nil || widthFactor! >= 0.0)
        assert(heightFactor == nil || heightFactor! >= 0.0)
    }

    /// If non-nil, the factor of the incoming width to use.
    ///
    /// If non-nil, the child is given a tight width constraint that is the max
    /// incoming width constraint multiplied by this factor. If nil, the child is
    /// given the incoming width constraints.
    public var widthFactor: Float? {
        didSet {
            assert(widthFactor == nil || widthFactor! >= 0.0)
            if widthFactor == oldValue {
                return
            }
            markNeedsLayout()
        }
    }

    /// If non-nil, the factor of the incoming height to use.
    ///
    /// If non-nil, the child is given a tight height constraint that is the max
    /// incoming width constraint multiplied by this factor. If nil, the child is
    /// given the incoming width constraints.
    public var heightFactor: Float? {
        didSet {
            assert(heightFactor == nil || heightFactor! >= 0.0)
            if heightFactor == oldValue {
                return
            }
            markNeedsLayout()
        }
    }

    private func getInnerConstraints(_ constraints: BoxConstraints) -> BoxConstraints {
        var minWidth = constraints.minWidth
        var maxWidth = constraints.maxWidth
        if let widthFactor = widthFactor {
            let width = maxWidth * widthFactor
            minWidth = width
            maxWidth = width
        }
        var minHeight = constraints.minHeight
        var maxHeight = constraints.maxHeight
        if let heightFactor = heightFactor {
            let height = maxHeight * heightFactor
            minHeight = height
            maxHeight = height
        }
        return BoxConstraints(
            minWidth: minWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            maxHeight: maxHeight
        )
    }

    public override func computeMinIntrinsicWidth(_ height: Float) -> Float {
        let result: Float
        if let child = child {
            result = child.getMinIntrinsicWidth(height * (heightFactor ?? 1.0))
        } else {
            result = super.computeMinIntrinsicWidth(height)
        }
        assert(result.isFinite)
        return result / (widthFactor ?? 1.0)
    }

    public override func computeMaxIntrinsicWidth(_ height: Float) -> Float {
        let result: Float
        if let child = child {
            result = child.getMaxIntrinsicWidth(height * (heightFactor ?? 1.0))
        } else {
            result = super.computeMaxIntrinsicWidth(height)
        }
        assert(result.isFinite)
        return result / (widthFactor ?? 1.0)
    }

    public override func computeMinIntrinsicHeight(_ width: Float) -> Float {
        let result: Float
        if let child = child {
            result = child.getMinIntrinsicHeight(width * (widthFactor ?? 1.0))
        } else {
            result = super.computeMinIntrinsicHeight(width)
        }
        assert(result.isFinite)
        return result / (heightFactor ?? 1.0)
    }

    public override func computeMaxIntrinsicHeight(_ width: Float) -> Float {
        let result: Float
        if let child = child {
            result = child.getMaxIntrinsicHeight(width * (widthFactor ?? 1.0))
        } else {
            result = super.computeMaxIntrinsicHeight(width)
        }
        assert(result.isFinite)
        return result / (heightFactor ?? 1.0)
    }

    // public override func computeDryLayout(_ constraints: BoxConstraints) -> Size {
    //     if let child = child {
    //         let childSize = child.getDryLayout(_getInnerConstraints(constraints))
    //         return constraints.constrain(childSize)
    //     }
    //     return constraints.constrain(_getInnerConstraints(constraints).constrain(Size.zero))
    // }

    // public override func computeDryBaseline(_ constraints: BoxConstraints, baseline: TextBaseline)
    //     -> Float?
    // {
    //     guard let child = child else {
    //         return nil
    //     }
    //     let childConstraints = _getInnerConstraints(constraints)
    //     guard let result = child.getDryBaseline(childConstraints, baseline: baseline) else {
    //         return nil
    //     }
    //     let childSize = child.getDryLayout(childConstraints)
    //     let size = getDryLayout(constraints)
    //     return result + resolvedAlignment.alongOffset(size - childSize as Offset).dy
    // }

    public override func performLayout() {
        if let child = child {
            child.layout(getInnerConstraints(boxConstraint), parentUsesSize: true)
            size = boxConstraint.constrain(child.size)
            alignChild()
        } else {
            size = boxConstraint.constrain(getInnerConstraints(boxConstraint).constrain(Size.zero))
        }
    }
}
