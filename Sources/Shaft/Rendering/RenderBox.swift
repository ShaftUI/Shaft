// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// Parent data used by [RenderBox] and its subclasses.
public class BoxParentData: ParentData {
    var offset = Offset.zero
}

/// Abstract [ParentData] subclass for [RenderBox] subclasses that want the
/// [ContainerRenderObjectMixin].
///
/// This is a convenience class that mixes in the relevant classes with
/// the relevant type arguments.
public class ContainerBoxParentData<ChildType: RenderBox>: BoxParentData, ContainerParentData {
    public var nextSibling: ChildType?
    public var previousSibling: ChildType?
}

/// Immutable layout constraints for [RenderBox] layout.
///
/// A [Size] respects a [BoxConstraints] if, and only if, all of the following
/// relations hold:
///
/// * [minWidth] <= [Size.width] <= [maxWidth]
/// * [minHeight] <= [Size.height] <= [maxHeight]
public struct BoxConstraints: Constraints, Equatable {
    /// Creates box constraints with the given constraints.
    init(
        minWidth: Float = 0.0,
        maxWidth: Float = Float.infinity,
        minHeight: Float = 0.0,
        maxHeight: Float = Float.infinity
    ) {
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }

    /// Creates box constraints that is respected only by the given size.
    static func tight(_ size: Size) -> BoxConstraints {
        BoxConstraints(
            minWidth: Float(size.width),
            maxWidth: Float(size.width),
            minHeight: Float(size.height),
            maxHeight: Float(size.height)
        )
    }

    /// Creates box constraints that require the given width or height.
    static func tightFor(width: Float? = nil, height: Float? = nil) -> BoxConstraints {
        BoxConstraints(
            minWidth: width ?? 0.0,
            maxWidth: width ?? Float.infinity,
            minHeight: height ?? 0.0,
            maxHeight: height ?? Float.infinity
        )
    }

    let minWidth: Float
    let maxWidth: Float
    let minHeight: Float
    let maxHeight: Float

    public var isTight: Bool {
        minWidth == maxWidth && minHeight == maxHeight
    }

    public func isEqualTo(_ other: Constraints) -> Bool {
        guard let other = other as? BoxConstraints else {
            return false
        }
        return minWidth == other.minWidth
            && maxWidth == other.maxWidth
            && minHeight == other.minHeight
            && maxHeight == other.maxHeight
    }

    /// Returns box constraints with the same width constraints but with
    /// unconstrained height.
    public func widthConstraints() -> BoxConstraints {
        BoxConstraints(minWidth: minWidth, maxWidth: maxWidth)
    }

    /// Returns box constraints with the same height constraints but with
    /// unconstrained width.
    public func heightConstraints() -> BoxConstraints {
        BoxConstraints(minHeight: minHeight, maxHeight: maxHeight)
    }

    /// Returns the width that both satisfies the constraints and is as close as
    /// possible to the given width.
    public func constrainWidth(_ width: Float = Float.infinity) -> Float {
        // assert(debugAssertIsValid())
        return width.clamped(to: minWidth...maxWidth)
    }

    /// Returns the height that both satisfies the constraints and is as close as
    /// possible to the given height.
    public func constrainHeight(_ height: Float = Float.infinity) -> Float {
        // assert(debugAssertIsValid())
        return height.clamped(to: minHeight...maxHeight)
    }

    /// Returns the size that both satisfies the constraints and is as close as
    /// possible to the given size.
    public func constrain(_ size: Size) -> Size {
        return Size(
            constrainWidth(size.width),
            constrainHeight(size.height)
        )
    }

    /// Returns new box constraints that are smaller by the given edge dimensions.
    public func deflate(_ edges: EdgeInsets) -> BoxConstraints {
        // assert(debugAssertIsValid())
        let horizontal = edges.horizontal
        let vertical = edges.vertical
        let deflatedMinWidth = max(0.0, minWidth - horizontal)
        let deflatedMinHeight = max(0.0, minHeight - vertical)
        return BoxConstraints(
            minWidth: deflatedMinWidth,
            maxWidth: max(deflatedMinWidth, maxWidth - horizontal),
            minHeight: deflatedMinHeight,
            maxHeight: max(deflatedMinHeight, maxHeight - vertical)
        )
    }

    /// Returns new box constraints that remove the minimum width and height requirements.
    public func loosen() -> BoxConstraints {
        // assert(debugAssertIsValid())
        return BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )
    }

    /// Returns new box constraints that respect the given constraints while being
    /// as close as possible to the original constraints.
    public func enforce(_ constraints: BoxConstraints) -> BoxConstraints {
        return BoxConstraints(
            minWidth: minWidth.clamped(to: constraints.minWidth...constraints.maxWidth),
            maxWidth: maxWidth.clamped(to: constraints.minWidth...constraints.maxWidth),
            minHeight: minHeight.clamped(to: constraints.minHeight...constraints.maxHeight),
            maxHeight: maxHeight.clamped(to: constraints.minHeight...constraints.maxHeight)
        )
    }

    /// Returns new box constraints with a tight width and/or height as close to
    /// the given width and height as possible while still respecting the original
    /// box constraints.
    public func tighten(width: Float? = nil, height: Float? = nil) -> BoxConstraints {
        return BoxConstraints(
            minWidth: width == nil ? minWidth : width!.clamped(to: minWidth...maxWidth),
            maxWidth: width == nil ? maxWidth : width!.clamped(to: minWidth...maxWidth),
            minHeight: height == nil ? minHeight : height!.clamped(to: minHeight...maxHeight),
            maxHeight: height == nil ? maxHeight : height!.clamped(to: minHeight...maxHeight)
        )
    }

    /// Returns a size that attempts to meet the following conditions, in order:
    ///
    ///  * The size must satisfy these constraints.
    ///  * The aspect ratio of the returned size matches the aspect ratio of the
    ///    given size.
    ///  * The returned size is as big as possible while still being equal to or
    ///    smaller than the given size.
    public func constrainSizeAndAttemptToPreserveAspectRatio(_ size: Size) -> Size {
        if isTight {
            return smallest
        }

        var width = size.width
        var height = size.height
        assert(width > 0.0)
        assert(height > 0.0)
        let aspectRatio = width / height

        if width > maxWidth {
            width = maxWidth
            height = width / aspectRatio
        }

        if height > maxHeight {
            height = maxHeight
            width = height * aspectRatio
        }

        if width < minWidth {
            width = minWidth
            height = width / aspectRatio
        }

        if height < minHeight {
            height = minHeight
            width = height * aspectRatio
        }

        return Size(constrainWidth(width), constrainHeight(height))
    }

}

extension BoxConstraints {
    public var biggest: Size {
        Size(maxWidth, maxHeight)
    }

    public var smallest: Size {
        Size(minWidth, minHeight)
    }
}

/// Method signature for hit testing a [RenderBox].
///
/// Used by [BoxHitTestResult.addWithPaintTransform] to hit test children
/// of a [RenderBox].
///
/// See also:
///
///  * [RenderBox.hitTest], which documents more details around hit testing
///    [RenderBox]es.
public typealias BoxHitTest = (BoxHitTestResult, Offset) -> Bool

/// The result of performing a hit test on [RenderBox]es.
///
/// An instance of this class is provided to [RenderBox.hitTest] to record the
/// result of the hit test.
public class BoxHitTestResult: HitTestResult {
    public override init() {
        super.init()
    }

    /// Wraps `result` to create a [HitTestResult] that implements the
    /// [BoxHitTestResult] protocol for hit testing on [RenderBox]es.
    ///
    /// This method is used by [RenderObject]s that adapt between the
    /// [RenderBox]-world and the non-[RenderBox]-world to convert a (subtype of)
    /// [HitTestResult] to a [BoxHitTestResult] for hit testing on [RenderBox]es.
    ///
    /// The [HitTestEntry] instances added to the returned [BoxHitTestResult] are
    /// also added to the wrapped `result` (both share the same underlying data
    /// structure to store [HitTestEntry] instances).
    public override init(wrap: HitTestResult) {
        super.init(wrap: wrap)
    }

    /// Convenience method for hit testing children, that are translated by
    /// an [Offset].
    ///
    /// The actual hit testing of the child needs to be implemented in the
    /// provided `hitTest` callback, which is invoked with the transformed
    /// `position` as argument.
    ///
    /// This method can be used as a convenience over [addWithPaintTransform] if
    /// a parent paints a child at an `offset`.
    ///
    /// A null value for `offset` is treated as if [Offset.zero] was provided.
    ///
    /// The function returns the return value of the `hitTest` callback.
    ///
    /// See also:
    ///
    ///  * [addWithPaintTransform], which takes a generic paint transform matrix and
    ///    documents the intended usage of this API in more detail.
    public func addWithPaintOffset(
        offset: Offset? = nil,
        position: Offset,
        hitTest: BoxHitTest
    ) -> Bool {
        let transformedPosition = offset == nil ? position : position - offset!
        if let offset {
            pushOffset(-offset)
        }
        let isHit = hitTest(self, transformedPosition)
        if offset != nil {
            popTransform()
        }
        return isHit
    }
}

private enum IntrinsicDimension {
    case minWidth
    case maxWidth
    case minHeight
    case maxHeight
}

private struct IntrinsicDimensionsCacheEntry: Hashable {
    let dimension: IntrinsicDimension
    let argument: Float
}

/// A render object in a 2D Cartesian coordinate system.
///
/// The [size] of each box is expressed as a width and a height. Each box has
/// its own coordinate system in which its upper left corner is placed at (0,
/// 0). The lower right corner of the box is therefore at (width, height). The
/// box contains all the points including the upper left corner and extending
/// to, but not including, the lower right corner.
open class RenderBox: RenderObject {
    public override init() {
    }

    public override func setupParentData(_ child: RenderObject) {
        if !(child.parentData is BoxParentData) {
            child.parentData = BoxParentData()
        }
    }

    public var size: Size!

    /// Whether this render object has undergone layout and has a [size].
    var hasSize: Bool { size != nil }

    private var cachedBaselines: [TextBaseline: Double]?
    private var cachedIntrinsicDimensions: [IntrinsicDimensionsCacheEntry: Float]?
    private var cachedDryLayoutSizes: [Int]?

    private final func computeIntrinsicDimension(
        _ dimension: IntrinsicDimension,
        _ argument: Float,
        _ compute: (Float) -> Float
    ) -> Float {
        cachedIntrinsicDimensions = cachedIntrinsicDimensions ?? [:]
        let entry = IntrinsicDimensionsCacheEntry(dimension: dimension, argument: argument)
        let result = cachedIntrinsicDimensions!.putIfAbsent(entry) {
            compute(argument)
        }
        return result
    }

    /// Returns the minimum width that this box could be without failing to
    /// correctly paint its contents within itself, without clipping.
    public final func getMinIntrinsicWidth(_ height: Float) -> Float {
        assert(height >= 0.0, "The height argument to getMinIntrinsicWidth() must be positive.")
        return computeIntrinsicDimension(
            IntrinsicDimension.minWidth,
            height,
            computeMinIntrinsicWidth
        )
    }

    /// Computes the value returned by [getMinIntrinsicWidth]. Do not call this
    /// function directly, instead, call [getMinIntrinsicWidth].
    open func computeMinIntrinsicWidth(_ height: Float) -> Float {
        return 0.0
    }

    /// Returns the smallest width beyond which increasing the width never
    /// decreases the preferred height. The preferred height is the value that
    /// would be returned by [getMinIntrinsicHeight] for that width.
    public final func getMaxIntrinsicWidth(_ height: Float) -> Float {
        assert(height >= 0.0, "The height argument to getMaxIntrinsicWidth() must be positive.")
        return computeIntrinsicDimension(
            IntrinsicDimension.maxWidth,
            height,
            computeMaxIntrinsicWidth
        )
    }

    /// Computes the value returned by [getMaxIntrinsicWidth]. Do not call this
    /// function directly, instead, call [getMaxIntrinsicWidth].
    open func computeMaxIntrinsicWidth(_ height: Float) -> Float {
        return 0.0
    }

    /// Returns the minimum height that this box could be without failing to
    /// correctly paint its contents within itself, without clipping.
    public final func getMinIntrinsicHeight(_ width: Float) -> Float {
        assert(width >= 0.0, "The width argument to getMinIntrinsicHeight() must be positive.")
        return computeIntrinsicDimension(
            IntrinsicDimension.minHeight,
            width,
            computeMinIntrinsicHeight
        )
    }

    /// Computes the value returned by [getMinIntrinsicHeight]. Do not call this
    /// function directly, instead, call [getMinIntrinsicHeight].
    open func computeMinIntrinsicHeight(_ width: Float) -> Float {
        return 0.0
    }

    /// Returns the smallest height beyond which increasing the height never
    /// decreases the preferred width. The preferred width is the value that
    /// would be returned by [getMinIntrinsicWidth] for that height.
    public final func getMaxIntrinsicHeight(_ width: Float) -> Float {
        assert(width >= 0.0, "The width argument to getMaxIntrinsicHeight() must be positive.")
        return computeIntrinsicDimension(
            IntrinsicDimension.maxHeight,
            width,
            computeMaxIntrinsicHeight
        )
    }

    /// Computes the value returned by [getMaxIntrinsicHeight]. Do not call this
    /// function directly, instead, call [getMaxIntrinsicHeight].
    open func computeMaxIntrinsicHeight(_ width: Float) -> Float {
        return 0.0
    }

    /// Computes the value returned by [getDryLayout]. Do not call this
    /// function directly, instead, call [getDryLayout].
    open func computeDryLayout(_ constraints: BoxConstraints) -> Size {
        return Size.zero
    }

    /// Clears any cached layout information for this render object. Returns
    /// true any data was cleared, otherwise returns false.
    private func clearCachedData() -> Bool {
        if (cachedBaselines != nil && cachedBaselines!.isNotEmpty)
            || (cachedIntrinsicDimensions != nil && cachedIntrinsicDimensions!.isNotEmpty)
            || (cachedDryLayoutSizes != nil && cachedDryLayoutSizes!.isNotEmpty)
        {
            // If we have cached data, then someone must have used our data.
            // Since the parent will shortly be marked dirty, we can forget that they
            // used the baseline and/or intrinsic dimensions. If they use them again,
            // then we'll fill the cache again, and if we get dirty again, we'll
            // notify them again.
            cachedBaselines?.removeAll()
            cachedIntrinsicDimensions?.removeAll()
            cachedDryLayoutSizes?.removeAll()
            return true
        }
        return false
    }

    public override func markNeedsLayout() {
        if clearCachedData() && parent != nil {
            markParentNeedsLayout()
            return
        }
        super.markNeedsLayout()
    }

    public var boxConstraint: BoxConstraints { constraints as! BoxConstraints }

    public override func layout(_ constraints: any Constraints, parentUsesSize: Bool = false) {
        if hasSize
            && !constraints.isEqualTo(self.constraints)
            && cachedBaselines != nil
            && cachedBaselines!.isNotEmpty
        {
            // The cached baselines data may need update if the constraints change.
            cachedBaselines?.removeAll()
        }
        super.layout(constraints, parentUsesSize: parentUsesSize)
    }

    /// By default this method sets [size] to the result of [computeDryLayout]
    /// called with the current [constraints]. Instead of overriding this method,
    /// consider overriding [computeDryLayout].
    open override func performResize() {
        // default behavior for subclasses that have sizedByParent = true
        size = computeDryLayout(boxConstraint)
        assert(size.isFinite)
    }


    open override func performLayout() {
        assert(sizedByParent, "\(self) did not implement performLayout()")
    }

    public override var paintBounds: Rect {
        Offset.zero & (size ?? Size.zero)
    }

    // MARK: - HitTest

    /// Determines the set of render objects located at the given position.
    ///
    /// Returns true, and adds any render objects that contain the point to the
    /// given hit test result, if this render object or one of its descendants
    /// absorbs the hit (preventing objects below this one from being hit).
    /// Returns false if the hit can continue to other objects below this one.
    ///
    /// The caller is responsible for transforming [position] from global
    /// coordinates to its location relative to the origin of this [RenderBox].
    /// This [RenderBox] is responsible for checking whether the given position is
    /// within its bounds.
    open func hitTest(_ result: HitTestResult, position: Offset) -> Bool {
        assert(hasSize, "Cannot hit test a render box with no size.")

        if size.contains(position) {
            if hitTestChildren(result, position: position) || hitTestSelf(position) {
                result.add(BoxHitTestEntry(self, position))
                return true
            }
        }

        return false
    }

    /// Override this method if this render object can be hit even if its
    /// children were not hit.
    ///
    /// Returns true if the specified `position` should be considered a hit
    /// on this render object.
    ///
    /// The caller is responsible for transforming [position] from global
    /// coordinates to its location relative to the origin of this [RenderBox].
    /// This [RenderBox] is responsible for checking whether the given position is
    /// within its bounds.
    ///
    /// Used by [hitTest]. If you override [hitTest] and do not call this
    /// function, then you don't need to implement this function.
    open func hitTestSelf(_ position: Offset) -> Bool {
        return false
    }

    /// Override this method to check whether any children are located at the
    /// given position.
    ///
    /// Subclasses should return true if at least one child reported a hit at the
    /// specified position.
    ///
    /// Typically children should be hit-tested in reverse paint order so that
    /// hit tests at locations where children overlap hit the child that is
    /// visually "on top" (i.e., paints later).
    ///
    /// The caller is responsible for transforming [position] from global
    /// coordinates to its location relative to the origin of this [RenderBox].
    /// Likewise, this [RenderBox] is responsible for transforming the position
    /// that it passes to its children when it calls [hitTest] on each child.
    open func hitTestChildren(_ result: HitTestResult, position: Offset) -> Bool {
        return false
    }

    /// Multiply the transform from the parent's coordinate system to this box's
    /// coordinate system into the given transform.
    ///
    /// This function is used to convert coordinate systems between boxes.
    /// Subclasses that apply transforms during painting should override this
    /// function to factor those transforms into the calculation.
    ///
    /// The [RenderBox] implementation takes care of adjusting the matrix for the
    /// position of the given child as determined during layout and stored on the
    /// child's [parentData] in the [BoxParentData.offset] field.
    open override func applyPaintTransform(_ child: RenderObject, transform: inout Matrix4x4f) {
        assert(child.parent === self)
        let childParentData = child.parentData as! BoxParentData
        let offset = childParentData.offset
        transform = transform.translated(by: Vector3f(offset.dx, offset.dy, 0))
    }

    public override func toStringShort() -> String {
        if let size {
            return "\(describeIdentity(self)): \(size)"
        } else {
            return describeIdentity(self)
        }
    }
}

extension RenderBox {
    /// {@template flutter.rendering.RenderObject.getTransformTo}
    /// Applies the paint transform up the tree to `ancestor`.
    ///
    /// Returns a matrix that maps the local paint coordinate system to the
    /// coordinate system of `ancestor`.
    ///
    /// If `ancestor` is null, this method returns a matrix that maps from the
    /// local paint coordinate system to the coordinate system of the
    /// [PipelineOwner.rootNode].
    /// {@endtemplate}
    ///
    /// For the render tree owned by the [RendererBinding] (i.e. for the main
    /// render tree displayed on the device) this means that this method maps to
    /// the global coordinate system in logical pixels. To get physical pixels,
    /// use [applyPaintTransform] from the [RenderView] to further transform the
    /// coordinate.
    public func getTransformTo(_ ancestor: RenderObject? = nil) -> Matrix4x4f {
        var ancestor = ancestor
        let ancestorSpecified = ancestor != nil
        assert(attached)
        if ancestor == nil {
            let rootNode = owner?.rootNode
            if let rootNode {
                ancestor = rootNode
            }
        }
        var renderers: [RenderObject] = []
        var renderer: RenderObject = self
        while renderer !== ancestor {
            renderers.append(renderer)
            assert(renderer.parent != nil)  // Failed to find ancestor in parent chain.
            renderer = renderer.parent!
        }
        if ancestorSpecified {
            renderers.append(ancestor!)
        }
        var transform = Matrix4x4f.identity
        for index in stride(from: renderers.count - 1, to: 0, by: -1) {
            renderers[index].applyPaintTransform(renderers[index - 1], transform: &transform)
        }
        return transform
    }

    /// Convert the given point from the global coordinate system in logical
    /// pixels to the local coordinate system for this box.
    ///
    /// This method will un-project the point from the screen onto the widget,
    /// which makes it different from [MatrixUtils.transformPoint].
    ///
    /// If the transform from global coordinates to local coordinates is
    /// degenerate, this function returns [Offset.zero].
    ///
    /// If `ancestor` is non-null, this function converts the given point from
    /// the coordinate system of `ancestor` (which must be an ancestor of this
    /// render object) instead of from the global coordinate system.
    ///
    /// This method is implemented in terms of [getTransformTo].
    public func globalToLocal(_ point: Offset, ancestor: RenderObject? = nil) -> Offset {
        var transform = getTransformTo(ancestor)
        if transform.determinant == 0.0 {
            return Offset.zero
        }
        transform = transform.inversed

        // We want to find point (p) that corresponds to a given point on the
        // screen (s), but that also physically resides on the local render
        // plane, so that it is useful for visually accurate gesture processing
        // in the local space. For that, we can't simply transform 2D screen
        // point to the 3D local space since the screen space lacks the depth
        // component |z|, and so there are many 3D points that correspond to the
        // screen point. We must first unproject the screen point onto the
        // render plane to find the true 3D point that corresponds to the screen
        // point. We do orthogonal unprojection after undoing perspective, in
        // local space. The render plane is specified by renderBox offset (o)
        // and Z axis (n). Unprojection is done by finding the intersection of
        // the view vector (d) with the local X-Y plane: (o-s).dot(n) ==
        // (p-s).dot(n), (p-s) == |z|*d.
        let n = Vector3f(0.0, 0.0, 1.0)
        let i = transform.multiplyAndProject(v: Vector3f(0.0, 0.0, 0.0))
        let d = transform.multiplyAndProject(v: Vector3f(0.0, 0.0, 1.0)) - i
        let s = transform.multiplyAndProject(v: Vector3f(point.dx, point.dy, 0.0))
        let p = s - d * (n.dot(s) / n.dot(d))
        return Offset(p.x, p.y)
    }

    /// Convert the given point from the local coordinate system for this box to
    /// the global coordinate system in logical pixels.
    ///
    /// If `ancestor` is non-null, this function converts the given point to the
    /// coordinate system of `ancestor` (which must be an ancestor of this render
    /// object) instead of to the global coordinate system.
    ///
    /// This method is implemented in terms of [getTransformTo]. If the transform
    /// matrix puts the given `point` on the line at infinity (for instance, when
    /// the transform matrix is the zero matrix), this method returns (NaN, NaN).
    public func localToGlobal(_ point: Offset, ancestor: RenderObject? = nil) -> Offset {
        return MatrixUtils.transformPoint(getTransformTo(ancestor), point)
    }
}

/// A hit test entry used by [RenderBox].
public final class BoxHitTestEntry: HitTestEntry {
    public init(_ target: HitTestTarget, _ localPosition: Offset) {
        self.localPosition = localPosition
        super.init(target)
    }

    /// The position of the hit test in the local coordinates of [target].
    let localPosition: Offset
}
