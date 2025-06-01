// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// A base class for render boxes that resemble their children.
///
/// A proxy box has a single child and mimics all the properties of that
/// child by calling through to the child for each function in the render box
/// protocol. For example, a proxy box determines its size by asking its child
/// to layout with the same constraints and then matching the size.
///
/// A proxy box isn't useful on its own because you might as well just replace
/// the proxy box with its child. However, RenderProxyBox is a useful base class
/// for render objects that wish to mimic most, but not all, of the properties
/// of their child.
///
/// See also:
///
///  * [RenderProxySliver], a base class for render slivers that resemble their
///    children.
public class RenderProxyBox: RenderBox, RenderObjectWithSingleChild {
    public init(child: RenderBox? = nil) {
        super.init()
        self.child = child
    }

    public typealias ChildType = RenderBox

    public var childMixin = RenderSingleChildMixin<RenderBox>()

    public override func setupParentData(_ child: RenderObject) {
        // We don't actually use the offset argument in BoxParentData, so let's
        // avoid allocating it at all.
        if child.parentData == nil {
            child.parentData = ParentData()
        }
    }

    public override func computeMinIntrinsicWidth(_ height: Float) -> Float {
        return child?.getMinIntrinsicWidth(height) ?? 0.0
    }

    public override func computeMaxIntrinsicWidth(_ height: Float) -> Float {
        return child?.getMaxIntrinsicWidth(height) ?? 0.0
    }

    public override func computeMinIntrinsicHeight(_ width: Float) -> Float {
        return child?.getMinIntrinsicHeight(width) ?? 0.0
    }

    public override func computeMaxIntrinsicHeight(_ width: Float) -> Float {
        return child?.getMaxIntrinsicHeight(width) ?? 0.0
    }

    // func computeDistanceToActualBaseline(TextBaseline baseline) {
    //     return child?.getDistanceToActualBaseline(baseline)
    //         ?? super.computeDistanceToActualBaseline(baseline);
    //   }

    // public  override func computeDryLayout(constraints: ): BoxConstraints -> Size{
    //   return child?.getDryLayout(constraints) ?? computeSizeForNoChild(constraints);
    // }

    public override func performLayout() {
        if let child {
            child.layout(constraints, parentUsesSize: true)
            size = child.size
        } else {
            size = computeSizeForNoChild(boxConstraint)
        }
    }

    /// Calculate the size the [RenderProxyBox] would have under the given
    /// [BoxConstraints] for the case where it does not have a child.
    open func computeSizeForNoChild(_ constraints: BoxConstraints) -> Size {
        return constraints.smallest
    }

    public override func hitTestChildren(_ result: HitTestResult, position: Offset) -> Bool {
        return child?.hitTest(result, position: position) ?? false
    }

    public override func applyPaintTransform(_ child: RenderObject, transform: inout Matrix4x4f) {}

    public override func paint(context: PaintingContext, offset: Offset) {
        if let child {
            context.paintChild(child, offset: offset)
        }
    }

}

/// How to behave during hit tests.
public enum HitTestBehavior {
    /// Targets that defer to their children receive events within their bounds
    /// only if one of their children is hit by the hit test.
    case deferToChild

    /// Opaque targets can be hit by hit tests, causing them to both receive
    /// events within their bounds and prevent targets visually behind them from
    /// also receiving events.
    case opaque

    /// Translucent targets both receive events within their bounds and permit
    /// targets visually behind them to also receive events.
    case translucent
}

/// A RenderProxyBox subclass that allows you to customize the
/// hit-testing behavior.
public class RenderProxyBoxWithHitTestBehavior: RenderProxyBox {
    public init(behavior: HitTestBehavior, child: RenderBox? = nil) {
        self.behavior = behavior
        super.init(child: child)
    }

    /// How to behave during hit testing when deciding how the hit test propagates
    /// to children and whether to consider targets behind this one.
    ///
    /// Defaults to [HitTestBehavior.deferToChild].
    ///
    /// See [HitTestBehavior] for the allowed values and their meanings.
    public var behavior: HitTestBehavior

    public override func hitTest(_ result: HitTestResult, position: Offset) -> Bool {
        var hitTarget = false
        if size.contains(position) {
            hitTarget = hitTestChildren(result, position: position) || hitTestSelf(position)
            if hitTarget || behavior == .translucent {
                result.add(HitTestEntry(self))
            }
        }
        return hitTarget
    }

    public override func hitTestSelf(_ position: Offset) -> Bool {
        return behavior == .opaque
    }
}

/// Imposes additional constraints on its child.
///
/// A render constrained box proxies most functions in the render box protocol
/// to its child, except that when laying out its child, it tightens the
/// constraints provided by its parent by enforcing the [additionalConstraints]
/// as well.
///
/// For example, if you wanted [child] to have a minimum height of 50.0 logical
/// pixels, you could use `const BoxConstraints(minHeight: 50.0)` as the
/// [additionalConstraints].
public class RenderConstrainedBox: RenderProxyBox {
    /// Creates a render box that constrains its child.
    ///
    /// The [additionalConstraints] argument must be valid.
    public init(additionalConstraints: BoxConstraints, child: RenderBox? = nil) {
        self.additionalConstraints = additionalConstraints
        super.init(child: child)
    }

    /// Additional constraints to apply to [child] during layout.
    public var additionalConstraints: BoxConstraints {
        didSet {
            // assert(additionalConstraints.isValid)
            if additionalConstraints != oldValue {
                markNeedsLayout()
            }
        }
    }

    public override func performLayout() {
        if let child {
            child.layout(additionalConstraints.enforce(boxConstraint), parentUsesSize: true)
            size = child.size
        } else {
            size = additionalConstraints.enforce(boxConstraint).constrain(Size.zero)
        }
    }
}

/// Where to paint a box decoration.
public enum DecorationPosition {
    /// Paint the box decoration behind the children.
    case background

    /// Paint the box decoration in front of the children.
    case foreground
}

/// Paints a [Decoration] either before or after its child paints.
public class RenderDecoratedBox: RenderProxyBox {
    public init(
        decoration: Decoration,
        position: DecorationPosition,
        configuration: ImageConfiguration,
        child: RenderBox? = nil
    ) {
        self.decoration = decoration
        self.position = position
        self.configuration = configuration
        super.init(child: child)
    }

    private var painter: BoxPainter? = nil

    /// What decoration to paint.
    ///
    /// Commonly a [BoxDecoration].
    var decoration: Decoration {
        didSet {
            if decoration !== oldValue {
                painter = nil
                markNeedsPaint()
            }
        }
    }

    /// Whether to paint the box decoration behind or in front of the child.
    var position: DecorationPosition {
        didSet {
            if position != oldValue {
                markNeedsPaint()
            }
        }
    }

    /// The settings to pass to the decoration when painting, so that it can
    /// resolve images appropriately. See [ImageProvider.resolve] and
    /// [BoxPainter.paint].
    ///
    /// The [ImageConfiguration.textDirection] field is also used by
    /// direction-sensitive [Decoration]s for painting and hit-testing.
    var configuration: ImageConfiguration {
        didSet {
            if configuration != oldValue {
                markNeedsPaint()
            }
        }
    }

    public override func hitTestSelf(_ position: Offset) -> Bool {
        decoration.hitTest(size, position, textDirection: configuration.textDirection)
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        painter = painter ?? decoration.createBoxPainter(onChanged: markNeedsPaint)
        let filledConfiguration = configuration.copyWith(size: size)

        if position == .background {
            painter!.paint(context.canvas, offset, configuration: filledConfiguration)
            // if decoration.isComplex {
            //     context.setIsComplexHint()
            // }
        }
        super.paint(context: context, offset: offset)
        if position == .foreground {
            painter!.paint(context.canvas, offset, configuration: filledConfiguration)
            // if decoration.isComplex {
            //     context.setIsComplexHint()
            // }
        }
    }

    public override func dispose() {
        painter = nil
        super.dispose()
    }
}

/// Lays the child out as if it was in the tree, but without painting anything,
/// without making the child available for hit testing, and without taking any
/// room in the parent.
public class RenderOffstage: RenderProxyBox {
    /// Creates an offstage render object.
    public init(
        offstage: Bool = true,
        child: RenderBox? = nil
    ) {
        self.offstage = offstage
        super.init(child: child)
    }

    /// Whether the child is hidden from the rest of the tree.
    ///
    /// If true, the child is laid out as if it was in the tree, but without
    /// painting anything, without making the child available for hit testing, and
    /// without taking any room in the parent.
    ///
    /// If false, the child is included in the tree as normal.
    public var offstage: Bool {
        didSet {
            if offstage == oldValue {
                return
            }
            markNeedsLayout()
        }
    }

    public override func computeMinIntrinsicWidth(_ height: Float) -> Float {
        if offstage {
            return 0.0
        }
        return super.computeMinIntrinsicWidth(height)
    }

    public override func computeMaxIntrinsicWidth(_ height: Float) -> Float {
        if offstage {
            return 0.0
        }
        return super.computeMaxIntrinsicWidth(height)
    }

    public override func computeMinIntrinsicHeight(_ width: Float) -> Float {
        if offstage {
            return 0.0
        }
        return super.computeMinIntrinsicHeight(width)
    }

    public override func computeMaxIntrinsicHeight(_ width: Float) -> Float {
        if offstage {
            return 0.0
        }
        return super.computeMaxIntrinsicHeight(width)
    }

    public override var sizedByParent: Bool {
        return offstage
    }

    public override func computeDryLayout(_ constraints: BoxConstraints) -> Size {
        if offstage {
            return constraints.smallest
        }
        return super.computeDryLayout(constraints)
    }

    public override func performLayout() {
        if offstage {
            child?.layout(constraints)
        } else {
            super.performLayout()
        }
    }

    public override func hitTest(_ result: HitTestResult, position: Offset) -> Bool {
        return !offstage && super.hitTest(result, position: position)
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        if offstage {
            return
        }
        super.paint(context: context, offset: offset)
    }
}

/// Applies a transformation before painting its child.
public class RenderTransform: RenderProxyBox {
    /// Creates a render object that transforms its child.
    public init(
        transform: Matrix4x4f,
        origin: Offset? = nil,
        alignment: (any AlignmentGeometry)? = nil,
        textDirection: TextDirection? = nil,
        transformHitTests: Bool = true,
        filterQuality: FilterQuality? = nil,
        child: RenderBox? = nil
    ) {
        self.transform = transform
        self.origin = origin
        self.alignment = alignment
        self.textDirection = textDirection ?? .ltr
        self.transformHitTests = transformHitTests
        self.filterQuality = filterQuality
        super.init(child: child)
    }

    /// The origin of the coordinate system (relative to the upper left corner of
    /// this render object) in which to apply the matrix.
    ///
    /// Setting an origin is equivalent to conjugating the transform matrix by a
    /// translation. This property is provided just for convenience.
    public var origin: Offset? {
        didSet {
            if origin == oldValue {
                return
            }
            markNeedsPaint()
            // markNeedsSemanticsUpdate()
        }
    }

    /// The alignment of the origin, relative to the size of the box.
    ///
    /// This is equivalent to setting an origin based on the size of the box.
    /// If it is specified at the same time as an offset, both are applied.
    ///
    /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
    /// whose [Alignment.x] value is `-1.0` if [textDirection] is
    /// [TextDirection.ltr], and `1.0` if [textDirection] is [TextDirection.rtl].
    /// Similarly [AlignmentDirectional.centerEnd] is the same as an [Alignment]
    /// whose [Alignment.x] value is `1.0` if [textDirection] is
    /// [TextDirection.ltr], and `-1.0` if [textDirection] is [TextDirection.rtl].
    public var alignment: (any AlignmentGeometry)? {
        didSet {
            if alignment == nil && oldValue == nil {
                return
            }
            if let alignment, let oldValue {
                if alignment.isEqualTo(oldValue) {
                    return
                }
            }
            markNeedsPaint()
            // markNeedsSemanticsUpdate()
        }
    }

    /// The text direction with which to resolve [alignment].
    ///
    /// This may be changed to null, but only after [alignment] has been changed
    /// to a value that does not depend on the direction.
    public var textDirection: TextDirection = .ltr {
        didSet {
            if textDirection == oldValue {
                return
            }
            markNeedsPaint()
            // markNeedsSemanticsUpdate()
        }
    }

    public override var alwaysNeedsCompositing: Bool {
        return child != nil && filterQuality != nil
    }

    /// When set to true, hit tests are performed based on the position of the
    /// child as it is painted. When set to false, hit tests are performed
    /// ignoring the transformation.
    ///
    /// [applyPaintTransform], and therefore [localToGlobal] and [globalToLocal],
    /// always honor the transformation, regardless of the value of this property.
    public var transformHitTests: Bool

    /// The matrix to transform the child by during painting. The provided value
    /// is copied on assignment.
    public var transform: Matrix4x4f {
        didSet {
            if transform == oldValue {
                return
            }
            markNeedsPaint()
            // markNeedsSemanticsUpdate()
        }
    }

    /// The filter quality with which to apply the transform as a bitmap operation.
    public var filterQuality: FilterQuality? {
        didSet {
            if filterQuality == oldValue {
                return
            }
            let didNeedCompositing = child != nil && oldValue != nil
            if didNeedCompositing != alwaysNeedsCompositing {
                markNeedsCompositingBitsUpdate()
            }
            markNeedsPaint()
        }
    }
    /// Sets the transform to the identity matrix.
    public func setIdentity() {
        transform = Matrix4x4f.identity
    }

    /// Concatenates a rotation about the x axis into the transform.
    public func rotateX(_ angle: Angle) {
        transform.rotateX(angle)
    }

    /// Concatenates a rotation about the y axis into the transform.
    public func rotateY(_ angle: Angle) {
        transform.rotateY(angle)
    }

    /// Concatenates a rotation about the z axis into the transform.
    public func rotateZ(_ angle: Angle) {
        transform.rotateZ(angle)
    }

    /// Concatenates a translation by (x, y, z) into the transform.
    public func translate(x: Float, y: Float = 0.0, z: Float = 0.0) {
        transform.translate(x, y, z)
    }

    /// Concatenates a scale into the transform.
    public func scale(x: Float, y: Float? = nil, z: Float? = nil) {
        transform.scale(x, y, z)
    }

    private var _effectiveTransform: Matrix4x4f? {
        let resolvedAlignment = alignment?.resolve(textDirection)
        if origin == nil && resolvedAlignment == nil {
            return transform
        }
        var result = Matrix4x4f.identity
        if let origin {
            result.translate(origin.dx, origin.dy)
        }
        var translation: Offset?
        if let resolvedAlignment {
            translation = resolvedAlignment.alongSize(size)
            result.translate(translation!.dx, translation!.dy)
        }
        result = result * transform
        if let translation {
            result.translate(-translation.dx, -translation.dy)
        }
        if let origin {
            result.translate(-origin.dx, -origin.dy)
        }
        return result
    }

    public override func hitTest(_ result: HitTestResult, position: Offset) -> Bool {
        // RenderTransform objects don't check if they are
        // themselves hit, because it's confusing to think about
        // how the untransformed size and the child's transformed
        // position interact.
        return hitTestChildren(result, position: position)
    }

    public override func hitTestChildren(_ result: HitTestResult, position: Offset) -> Bool {
        assert(!transformHitTests || _effectiveTransform != nil)
        return (result as! BoxHitTestResult).addWithPaintTransform(
            transform: transformHitTests ? _effectiveTransform : nil,
            position: position,
            hitTest: { result, position in
                return super.hitTestChildren(result, position: position)
            }
        )
    }
    public override func paint(context: PaintingContext, offset: Offset) {
        if child != nil {
            let transform = _effectiveTransform!
            // if filterQuality == nil {
            if true {
                let childOffset = MatrixUtils.getAsTranslation(transform)
                if childOffset == nil {
                    // if the matrix is singular the children would be compressed to a line or
                    // single point, instead short-circuit and paint nothing.
                    let det = transform.determinant
                    if det == 0 || !det.isFinite {
                        layer = nil
                        return
                    }
                    layer = context.pushTransform(
                        needsCompositing: needsCompositing,
                        offset: offset,
                        transform: transform,
                        painter: super.paint,
                        oldLayer: layer as? TransformLayer
                    )
                } else {
                    super.paint(context: context, offset: offset + childOffset!)
                    layer = nil
                }
            } else {
                // var effectiveTransform =
                //     Matrix4x4f.translate(tx: offset.dx, ty: offset.dy, tz: 0.0)
                //     * transform
                // effectiveTransform.translate(-offset.dx, -offset.dy)

                // let filter = ImageFilter.matrix(
                //     effectiveTransform.storage,
                //     filterQuality: filterQuality!
                // )
                // if layer is ImageFilterLayer {
                //     let filterLayer = layer! as! ImageFilterLayer
                //     filterLayer.imageFilter = filter
                // } else {
                //     layer = ImageFilterLayer(imageFilter: filter)
                // }
                // context.pushLayer(layer!, super.paint, offset)
            }
        }
    }

    public override func applyPaintTransform(_ child: RenderObject, transform: inout Matrix4x4f) {
        transform = transform * _effectiveTransform!
    }
}

public class _RenderCustomClip<T>: RenderProxyBox {
    public init(
        child: RenderBox? = nil,
        clipper: (any CustomClipper<T>)? = nil,
        clipBehavior: Clip = .antiAlias
    ) {
        self.clipper = clipper
        self.clipBehavior = clipBehavior
        super.init(child: child)
    }

    /// If non-null, determines which clip to use on the child.
    public var clipper: (any CustomClipper<T>)? {
        didSet {
            if clipper === oldValue {
                return
            }
            assert(clipper != nil || oldValue != nil)
            if clipper == nil || oldValue == nil || shouldClip(clipper!, oldValue!) {
                _markNeedsClip()
            }
            if attached {
                oldValue?.removeListener(self)
                clipper?.addListener(self, callback: _markNeedsClip)
            }
        }
    }

    private func shouldClip<T1: CustomClipper, T2: CustomClipper>(
        _ newClipper: T1,
        _ oldClipper: T2
    )
        -> Bool
    {
        guard let oldClipper = oldClipper as? T1 else {
            return true
        }
        if newClipper.shouldReclip(oldClipper: oldClipper) {
            return true
        }
        return false
    }

    public override func attach(_ owner: RenderOwner) {
        super.attach(owner)
        clipper?.addListener(self, callback: _markNeedsClip)
    }

    public override func detach() {
        clipper?.removeListener(self)
        super.detach()
    }

    fileprivate func _markNeedsClip() {
        _clip = nil
        markNeedsPaint()
        // markNeedsSemanticsUpdate()
    }

    public var _defaultClip: T { fatalError("Must be implemented by subclass") }
    fileprivate var _clip: T?

    public var clipBehavior: Clip {
        didSet {
            if clipBehavior != oldValue {
                markNeedsPaint()
            }
        }
    }

    public override func performLayout() {
        let oldSize = hasSize ? size : nil
        super.performLayout()
        if oldSize != size {
            _clip = nil
        }
    }

    public func _updateClip() {
        _clip = clipper?.getClip(size: size) ?? _defaultClip
    }

    // public override func describeApproximatePaintClip(_ child: RenderObject) -> Rect? {
    //     switch clipBehavior {
    //     case .none:
    //         return nil
    //     case .hardEdge, .antiAlias, .antiAliasWithSaveLayer:
    //         return clipper?.getApproximateClipRect(size) ?? (Offset.zero & size)
    //     }
    // }
}

/// Clips its child using a rectangle.
///
/// By default, [RenderClipRect] prevents its child from painting outside its
/// bounds, but the size and location of the clip rect can be customized using a
/// custom [clipper].
public class RenderClipRect: _RenderCustomClip<Rect> {
    /// Creates a rectangular clip.
    ///
    /// If [clipper] is null, the clip will match the layout size and position of
    /// the child.
    ///
    /// If [clipBehavior] is [Clip.none], no clipping will be applied.
    public override init(
        child: RenderBox? = nil,
        clipper: (any CustomClipper<Rect>)? = nil,
        clipBehavior: Clip = .hardEdge
    ) {
        super.init(child: child, clipper: clipper, clipBehavior: clipBehavior)
    }

    public override var _defaultClip: Rect {
        return Offset.zero & size
    }

    public override func hitTest(_ result: HitTestResult, position: Offset) -> Bool {
        if clipper != nil {
            _updateClip()
            assert(_clip != nil)
            if !_clip!.contains(position) {
                return false
            }
        }

        return super.hitTest(result, position: position)
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        if let child {
            if clipBehavior != .none {
                _updateClip()
                layer = context.pushClipRect(
                    needsCompositing: needsCompositing,
                    offset: offset,
                    clipRect: _clip!,
                    clipBehavior: clipBehavior,
                    painter: super.paint,
                    oldLayer: layer as? ClipRectLayer
                )
            } else {
                context.paintChild(child, offset: offset)
                layer = nil
            }
        } else {
            layer = nil
        }
    }
}

/// Clips its child using a rounded rectangle.
///
/// By default, [RenderClipRRect] uses its own bounds as the base rectangle for
/// the clip, but the size and location of the clip can be customized using a
/// custom [clipper].
public class RenderClipRRect: _RenderCustomClip<RRect> {
    /// Creates a rounded-rectangular clip.
    ///
    /// The [borderRadius] defaults to [BorderRadius.zero], i.e. a rectangle with
    /// right-angled corners.
    ///
    /// If [clipper] is non-null, then [borderRadius] is ignored.
    ///
    /// If [clipBehavior] is [Clip.none], no clipping will be applied.

    public init(
        child: RenderBox? = nil,
        borderRadius: any BorderRadiusGeometry = .zero,
        clipper: (any CustomClipper<RRect>)? = nil,
        clipBehavior: Clip = .hardEdge,
        textDirection: TextDirection? = nil
    ) {
        self.borderRadius = borderRadius
        self.textDirection = textDirection
        super.init(child: child, clipper: clipper, clipBehavior: clipBehavior)
    }

    /// The border radius of the rounded corners.
    ///
    /// Values are clamped so that horizontal and vertical radii sums do not
    /// exceed width/height.
    ///
    /// This value is ignored if [clipper] is non-null.

    public var borderRadius: any BorderRadiusGeometry {
        didSet {
            if isEqual(borderRadius, oldValue) {
                return
            }
            _markNeedsClip()
        }
    }

    /// The text direction with which to resolve [borderRadius].

    public var textDirection: TextDirection? {
        didSet {
            if textDirection == oldValue {
                return
            }
            _markNeedsClip()
        }
    }

    public override var _defaultClip: RRect {
        return borderRadius.resolve(textDirection).toRRect(Offset.zero & size)
    }

    public override func hitTest(_ result: HitTestResult, position: Offset) -> Bool {
        if clipper != nil {
            _updateClip()
            assert(_clip != nil)
            if !_clip!.contains(position) {
                return false
            }
        }

        return super.hitTest(result, position: position)
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        if let child {
            if clipBehavior != .none {
                _updateClip()
                layer = context.pushClipRRect(
                    needsCompositing: needsCompositing,
                    offset: offset,
                    bounds: _clip!.outerRect,
                    clipRRect: _clip!,
                    painter: super.paint,
                    clipBehavior: clipBehavior,
                    oldLayer: layer as? ClipRRectLayer
                )
            } else {
                context.paintChild(child, offset: offset)
                layer = nil
            }
        } else {
            layer = nil
        }
    }
}
