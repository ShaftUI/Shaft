// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// Base class for data associated with a [RenderObject] by its parent.
///
/// Some render objects wish to store data on their children, such as the
/// children's input parameters to the parent's layout algorithm or the
/// children's position relative to other children.
public class ParentData {

}

/// An abstract set of layout constraints.
///
/// Concrete layout models (such as box) will create concrete subclasses to
/// communicate layout constraints between parents and children.
public protocol Constraints {
    var isTight: Bool { get }

    func isEqualTo(_ other: Constraints) -> Bool
}

extension Constraints where Self: Equatable {
    public func isEqualTo(other: Constraints) -> Bool {
        if let other = other as? Self {
            return self == other
        }
        return false
    }
}

public class PaintingContext: ClipContext {
    private let containerLayer: ContainerLayer

    let estimatedBounds: Rect

    init(_ containerLayer: ContainerLayer, _ estimatedBounds: Rect) {
        self.containerLayer = containerLayer
        self.estimatedBounds = estimatedBounds
    }

    /// Repaint the given render object.
    ///
    /// The render object must be attached to a [PipelineOwner], must have a
    /// composited layer, and must be in need of painting. The render object's
    /// layer, if any, is re-used, along with any layers in the subtree that don't
    /// need to be repainted.
    static func repaintCompositedChild(_ child: RenderObject) {
        assert(child.isRepaintBoundary)
        var childLayer = child.layer as! OffsetLayer?
        if childLayer == nil {
            childLayer = child.updateCompositedLayer(oldLayer: nil)
            child.layer = childLayer
        } else {
            childLayer!.removeAllChildren()
            let updatedLayer = child.updateCompositedLayer(oldLayer: childLayer)
            assert(updatedLayer === childLayer)
        }
        child.needsCompositingBitsUpdate = false

        let childContext = PaintingContext(childLayer!, child.paintBounds)
        child.paintWithContext(childContext, Offset.zero)

        assert(childLayer === child.layer)
        childContext.stopRecordingIfNeeded()
    }

    /// Update the composited layer of [child] without repainting its children.
    ///
    /// The render object must be attached to a [PipelineOwner], must have a
    /// composited layer, and must be in need of a composited layer update but
    /// not in need of painting. The render object's layer is re-used, and none
    /// of its children are repaint or their layers updated.
    static func updateLayerProperties(_ child: RenderObject) {
        assert(child.isRepaintBoundary && child.wasRepaintBoundary)
        assert(!child.needsPaint)
        assert(child.layer != nil)

        let childLayer = child.layer as! OffsetLayer
        let updatedLayer = child.updateCompositedLayer(oldLayer: childLayer)
        assert(updatedLayer === childLayer)

        child.needsCompositedLayerUpdate = false
    }

    // MARK: - Recording

    private var recordingCanvas: RecordingCanvas?
    private var currentLayer: PictureLayer?

    public var canvas: Canvas {
        if recordingCanvas == nil {
            startRecording()
        }
        return recordingCanvas!
    }

    private var isRecording: Bool { recordingCanvas != nil }

    private func startRecording() {
        assert(!isRecording)
        currentLayer = PictureLayer(canvasBounds: estimatedBounds)
        recordingCanvas = RecordingCanvas()
        containerLayer.append(currentLayer!)
    }

    /// Stop recording to a canvas if recording has started.
    private func stopRecordingIfNeeded() {
        if !isRecording {
            return
        }
        currentLayer!.picture = recordingCanvas!.build()
        currentLayer = nil
        recordingCanvas = nil
    }

    /// Adds a layer to the recording requiring that the recording is already
    /// stopped.
    ///
    /// Do not call this function directly: call [addLayer] or [pushLayer]
    /// instead. This function is called internally when all layers not
    /// generated from the [canvas] are added.
    ///
    /// Subclasses that need to customize how layers are added should override
    /// this method.
    internal func appendLayer(_ layer: Layer) {
        assert(!isRecording)
        containerLayer.append(layer)
    }

    /// Appends the given layer to the recording, and calls the `painter` callback
    /// with that layer, providing the `childPaintBounds` as the estimated paint
    /// bounds of the child. The `childPaintBounds` can be used for debugging but
    /// have no effect on painting.
    ///
    /// The given layer must be an unattached orphan. (Providing a newly created
    /// object, rather than reusing an existing layer, satisfies that
    /// requirement.)
    ///
    /// {@template flutter.rendering.PaintingContext.pushLayer.offset}
    /// The `offset` is the offset to pass to the `painter`. In particular, it is
    /// not an offset applied to the layer itself. Layers conceptually by default
    /// have no position or size, though they can transform their contents. For
    /// example, an [OffsetLayer] applies an offset to its children.
    /// {@endtemplate}
    ///
    /// If the `childPaintBounds` are not specified then the current layer's paint
    /// bounds are used. This is appropriate if the child layer does not apply any
    /// transformation or clipping to its contents. The `childPaintBounds`, if
    /// specified, must be in the coordinate system of the new layer (i.e. as seen
    /// by its children after it applies whatever transform to its contents), and
    /// should not go outside the current layer's paint bounds.
    ///
    /// See also:
    ///
    ///  * [addLayer], for pushing a layer without painting further contents
    ///    within it.
    public func pushLayer(
        _ childLayer: ContainerLayer,
        _ painter: (PaintingContext, Offset) -> Void,
        _ offset: Offset,
        childPaintBounds: Rect? = nil
    ) {
        // If a layer is being reused, it may already contain children. We remove
        // them so that `painter` can add children that are relevant for this frame.
        if childLayer.hasChildren {
            childLayer.removeAllChildren()
        }
        stopRecordingIfNeeded()
        appendLayer(childLayer)
        let childContext = PaintingContext(childLayer, childPaintBounds ?? estimatedBounds)

        painter(childContext, offset)
        childContext.stopRecordingIfNeeded()
    }

    // MARK: - Painting

    public func paintChild(_ child: RenderObject, offset: Offset = Offset.zero) {
        if child.isRepaintBoundary {
            stopRecordingIfNeeded()
            compositeChild(child, offset: offset)
        }
        // If a render object was a repaint boundary but no longer is one, this
        // is where the layer is unreferenced
        else if child.wasRepaintBoundary {
            child.layer = nil
            child.paintWithContext(self, offset)
        } else {
            child.paintWithContext(self, offset)
        }
    }

    private func compositeChild(_ child: RenderObject, offset: Offset) {
        assert(!isRecording)
        assert(child.isRepaintBoundary)
        assert(recordingCanvas === nil || recordingCanvas!.getSaveCount() == 1)

        // Create a layer for our child, and paint the child into it.
        if child.needsPaint || !child.wasRepaintBoundary {
            Self.repaintCompositedChild(child)
        } else {
            if child.needsCompositedLayerUpdate {
                Self.updateLayerProperties(child)
            }
            // assert(() {
            //     // register the call for RepaintBoundary metrics
            //     child.debugRegisterRepaintBoundaryPaint();
            //     child._layerHandle.layer!.debugCreator = child.debugCreator ?? child;
            //     return true;
            // }());
        }
        assert(child.layer is OffsetLayer)
        let childOffsetLayer = child.layer! as! OffsetLayer
        childOffsetLayer.offset = offset
        appendLayer(childOffsetLayer)
    }

    /// Clip further painting using a rectangle.
    ///
    /// The `needsCompositing` argument specifies whether the child needs
    /// compositing. Typically this matches the value of
    /// [RenderObject.needsCompositing] for the caller. If false, this method
    /// returns null, indicating that a layer is no longer necessary. If a
    /// render object calling this method stores the `oldLayer` in its
    /// [RenderObject.layer] field, it should set that field to null.
    ///
    /// When `needsCompositing` is false, this method will use a more efficient
    /// way to apply the layer effect than actually creating a layer.
    /// {@endtemplate}
    ///
    /// {@template flutter.rendering.PaintingContext.pushClipRect.offset} The
    /// `offset` argument is the offset from the origin of the canvas'
    /// coordinate system to the origin of the caller's coordinate system.
    /// {@endtemplate}
    ///
    /// The `clipRect` is the rectangle (in the caller's coordinate system) to
    /// use to clip the painting done by [painter]. It should not include the
    /// `offset`.
    ///
    /// The `painter` callback will be called while the `clipRect` is applied.
    /// It is called synchronously during the call to [pushClipRect].
    ///
    /// The `clipBehavior` argument controls how the rectangle is clipped.
    ///
    /// {@template flutter.rendering.PaintingContext.pushClipRect.oldLayer} For
    /// the `oldLayer` argument, specify the layer created in the previous
    /// frame. This gives the engine more information for performance
    /// optimizations. Typically this is the value of [RenderObject.layer] that
    /// a render object creates once, then reuses for all subsequent frames
    /// until a layer is no longer needed (e.g. the render object no longer
    /// needs compositing) or until the render object changes the type of the
    /// layer (e.g. from opacity layer to a clip rect layer).
    public func pushClipRect(
        needsCompositing: Bool,
        offset: Offset,
        clipRect: Rect,
        clipBehavior: Clip = .hardEdge,
        painter: (PaintingContext, Offset) -> Void,
        oldLayer: ClipRectLayer? = nil
    ) -> ClipRectLayer? {
        if clipBehavior == .none {
            painter(self, offset)
            return nil
        }
        let offsetClipRect = clipRect.shift(offset)
        if needsCompositing {
            let layer = oldLayer ?? ClipRectLayer()
            layer.clipRect = offsetClipRect
            layer.clipBehavior = clipBehavior
            pushLayer(layer, painter, offset, childPaintBounds: offsetClipRect)
            return layer
        } else {
            clipRectAndPaint(
                offsetClipRect,
                clipBehavior,
                offsetClipRect,
                { painter(self, offset) }
            )
            return nil
        }
    }

    /// Transform further painting using a matrix.
    ///
    /// The `offset` argument is the offset to pass to `painter` and the offset to
    /// the origin used by `transform`.
    ///
    /// The `transform` argument is the [Matrix4] with which to transform the
    /// coordinate system while calling `painter`. It should not include `offset`.
    /// It is applied effectively after applying `offset`.
    ///
    /// The `painter` callback will be called while the `transform` is applied. It
    /// is called synchronously during the call to [pushTransform].
    public func pushTransform(
        needsCompositing: Bool,
        offset: Offset,
        transform: Matrix4x4f,
        painter: (PaintingContext, Offset) -> Void,
        oldLayer: TransformLayer? = nil
    ) -> TransformLayer? {

        var effectiveTransform =
            Matrix4x4f.translate(tx: offset.dx, ty: offset.dy, tz: 0.0) * transform
        effectiveTransform.translate(-offset.dx, -offset.dy, 0.0)

        if needsCompositing {
            let layer = oldLayer ?? TransformLayer()
            layer.transform = effectiveTransform

            pushLayer(
                layer,
                painter,
                offset,
                childPaintBounds: MatrixUtils.inverseTransformRect(
                    effectiveTransform,
                    estimatedBounds
                )
            )
            return layer
        } else {
            canvas.save()
            canvas.transform(effectiveTransform)
            painter(self, offset)
            canvas.restore()
            return nil
        }
    }
}

/// The pipeline owner manages the rendering pipeline.
///
/// The pipeline owner provides an interface for driving the rendering pipeline
/// and stores the state about which render objects have requested to be visited
/// in each stage of the pipeline. To flush the pipeline, call the following
/// functions in order:
public class RenderOwner {
    private let onNeedVisualUpdate: () -> Void

    init(onNeedVisualUpdate: @escaping () -> Void) {
        self.onNeedVisualUpdate = onNeedVisualUpdate
    }

    public var rootNode: RenderObject? {
        willSet {
            rootNode?.detach()
        }
        didSet {
            rootNode?.attach(self)
        }
    }

    internal func requestVisualUpdate() {
        onNeedVisualUpdate()
    }

    // MARK: - Layout

    internal var nodesNeedingLayout: [RenderObject] = []

    /// Whether the current [flushLayout] call should pause to incorporate the
    /// [RenderObject]s in `_nodesNeedingLayout` into the current dirty list,
    /// before continuing to process dirty relayout boundaries.
    private var shouldMergeDirtyNodes = false

    public func flushLayout() {
        while nodesNeedingLayout.isNotEmpty {
            var dirtyNodes = nodesNeedingLayout
            nodesNeedingLayout.removeAll()
            dirtyNodes.sort(by: { $0.depth < $1.depth })
            for i in 0..<dirtyNodes.count {
                if shouldMergeDirtyNodes {
                    shouldMergeDirtyNodes = false
                    if nodesNeedingLayout.isNotEmpty {
                        nodesNeedingLayout.append(contentsOf: dirtyNodes[i...])
                        break
                    }
                }

                let node = dirtyNodes[i]
                if node.needsLayout && node.owner === self {
                    node.layoutWithoutResize()
                }
                // No need to merge dirty nodes generated from processing the last
                // relayout boundary back.
                shouldMergeDirtyNodes = false
            }
        }

        // for (final PipelineOwner child in _children) {
        //     child.flushLayout();
        // }
    }

    // MARK: - Compositing Bits

    internal var nodesNeedingCompositingBitsUpdate: [RenderObject] = []

    /// Updates the [RenderObject.needsCompositing] bits.
    ///
    /// Called as part of the rendering pipeline after [flushLayout] and before
    /// [flushPaint].
    func flushCompositingBits() {
        nodesNeedingCompositingBitsUpdate.sort(by: { $0.depth < $1.depth })
        for node in nodesNeedingCompositingBitsUpdate {
            if node.needsCompositingBitsUpdate && node.owner === self {
                node.updateCompositingBits()
            }
        }
        nodesNeedingCompositingBitsUpdate.removeAll()
        // for (final PipelineOwner child in _children) {
        //     child.flushCompositingBits();
        // }
    }

    // MARK: - Painting

    internal var nodesNeedingPaint: [RenderObject] = []

    public func flushPaint() {
        var dirtyNodes = nodesNeedingPaint
        defer { nodesNeedingPaint.removeAll() }

        dirtyNodes.sort(by: { $0.depth < $1.depth })
        for node in dirtyNodes {
            if (node.needsPaint || node.needsCompositedLayerUpdate) && node.owner === self {
                if node.layer != nil {
                    if node.needsPaint {
                        PaintingContext.repaintCompositedChild(node)
                    } else {
                        PaintingContext.updateLayerProperties(node)
                    }
                } else {
                    // node._skippedPaintingOnLayer();
                }
            }

        }

        // for (final PipelineOwner child in _children) {
        //     child.flushPaint();
        // }
    }

}

open class RenderObject: HitTestTarget, DiagnosticableTree {

    // MARK: - Tree Node Basics

    /// The owner for this node (null if unattached).
    ///
    /// The entire subtree that this node belongs to will have the same owner.
    public private(set) var owner: RenderOwner?

    /// Whether this node is in a tree whose root is attached to something.
    ///
    /// This becomes true during the call to [attach].
    ///
    /// This becomes false during the call to [detach].
    public var attached: Bool { owner != nil }

    /// Data for use by the parent render object.
    public var parentData: ParentData?

    /// Override to setup parent data correctly for your children.
    ///
    /// You can call this function to set up the parent data for child before the
    /// child is added to the parent's child list.
    open func setupParentData(_ child: RenderObject) {
        if child.parentData == nil {
            child.parentData = ParentData()
        }
    }

    /// Mark this node as attached to the given owner.
    ///
    /// Typically called only from the [parent]'s [attach] method, and by the
    /// [owner] to mark the root of a tree as attached.
    open func attach(_ owner: RenderOwner) {
        assert(self.owner == nil)
        self.owner = owner

        // If the node was dirtied in some way while unattached, make sure to add
        // it to the appropriate dirty list now that an owner is available
        if needsLayout && relayoutBoundary != nil {
            // Don't enter this block if we've never laid out at all;
            // scheduleInitialLayout() will handle it
            needsLayout = false
            markNeedsLayout()
        }

        if needsPaint && layer != nil {
            // Don't enter this block if we've never painted at all;
            // scheduleInitialP aint() will handle it
            needsPaint = false
            markNeedsPaint()
        }

        (self as? any RenderObjectWithChild)?.attachChild(owner)
    }

    /// Mark this node as detached.
    ///
    /// Typically called only from the [parent]'s [detach], and by the [owner]
    /// to mark the root of a tree as detached.
    open func detach() {
        assert(owner !== nil)
        owner = nil
        assert(parent == nil || attached == parent!.attached)
        (self as? any RenderObjectWithChild)?.detachChild()
    }

    package var debugDisposed = false

    /// Release any resources held by this render object.
    ///
    /// The object that creates a RenderObject is in charge of disposing it.
    /// If this render object has created any children directly, it must dispose
    /// of those children in this method as well. It must not dispose of any
    /// children that were created by some other object, such as
    /// a [RenderObjectElement]. Those children will be disposed when that
    /// element unmounts, which may be delayed if the element is moved to another
    /// part of the tree.
    ///
    /// Implementations of this method must end with a call to the inherited
    /// method, as in `super.dispose()`.
    ///
    /// The object is no longer usable after calling dispose.
    open func dispose() {
        assert(!debugDisposed)
        layer = nil
        assert {
            debugDisposed = true
            return true
        }
    }

    /// The parent of this node in the render tree.
    public private(set) weak var parent: RenderObject?

    /// Called by subclasses when they decide a render object is a child.
    ///
    /// Only for use by subclasses when changing their child lists. Calling this
    /// in other cases will lead to an inconsistent tree and probably cause crashes.
    func adoptChild(child: RenderObject) {
        assert(child.parent == nil)
        child.parent = self
        setupParentData(child)
        markNeedsLayout()
        markNeedsCompositingBitsUpdate()
        child.parent = self
        if let owner {
            child.attach(owner)
        }
        redepthChild(child)
    }

    /// Called by subclasses when they decide a render object is no longer a child.
    ///
    /// Only for use by subclasses when changing their child lists. Calling this
    /// in other cases will lead to an inconsistent tree and probably cause crashes.
    func dropChild(child: RenderObject) {
        assert(child.parent === self)
        assert(child.attached == attached)
        child.cleanRelayoutBoundary()
        child.parentData = nil
        child.parent = nil
        if attached {
            child.detach()
        }
        markNeedsLayout()
        markNeedsCompositingBitsUpdate()

    }

    /// The depth of this node in the tree.
    ///
    /// The depth of nodes in a tree monotonically increases as you traverse down
    /// the tree.
    private(set) var depth: Int = 0

    /// Adjust the [depth] of the given [child] to be greater than this node's own
    /// [depth].
    ///
    /// Only call this method from overrides of [redepthChildren].
    func redepthChild(_ child: RenderObject) {
        assert(child.owner === owner)
        if child.depth <= depth {
            child.depth = depth + 1
            (child as? any RenderObjectWithChild)?.redepthChildren()
        }
    }

    // MARK: - Layout

    open var sizedByParent: Bool { false }

    public private(set) var needsLayout = true

    private var _constraints: (any Constraints)?

    public var constraints: any Constraints { _constraints! }

    internal weak var relayoutBoundary: RenderObject?

    public func markNeedsLayout() {
        if needsLayout {
            return
        }

        if relayoutBoundary == nil {
            markParentNeedsLayout()
            return
        }

        if relayoutBoundary !== self {
            markParentNeedsLayout()

        } else {
            needsLayout = true
            if let owner {
                owner.nodesNeedingLayout.append(self)
                owner.requestVisualUpdate()
            }
        }
    }

    public func markParentNeedsLayout() {
        needsLayout = true
        if let parent {
            parent.markNeedsLayout()
        }
    }

    private func cleanRelayoutBoundary() {
        if relayoutBoundary !== self {
            relayoutBoundary = nil
            (self as? any RenderObjectWithChild)?.visitChildren { child in
                child.cleanRelayoutBoundary()
            }
        }
    }

    private func propagateLayoutConstraints() {
        if relayoutBoundary === self {
            return
        }
        let parentRelayoutBoundary = parent!.relayoutBoundary
        if relayoutBoundary !== parentRelayoutBoundary {
            relayoutBoundary = parentRelayoutBoundary
            (self as? any RenderObjectWithChild)?.visitChildren { child in
                child.propagateLayoutConstraints()
            }
        }
    }

    public func layout(_ constraints: any Constraints, parentUsesSize: Bool = false) {
        let isRepaintBoundary =
            !parentUsesSize || sizedByParent || constraints.isTight || parent == nil
        let relayoutBoundary = isRepaintBoundary ? self : parent!.relayoutBoundary

        if !needsLayout && constraints.isEqualTo(self.constraints) {
            if self.relayoutBoundary !== relayoutBoundary {
                self.relayoutBoundary = relayoutBoundary
                (self as? any RenderObjectWithChild)?.visitChildren { child in
                    child.propagateLayoutConstraints()
                }
            }
        }

        _constraints = constraints
        if relayoutBoundary != nil && self.relayoutBoundary !== relayoutBoundary {
            // The local relayout boundary has changed, must notify children in case
            // they also need updating. Otherwise, they will be confused about what
            // their actual relayout boundary is later.
            (self as? any RenderObjectWithChild)?.visitChildren { child in
                child.cleanRelayoutBoundary()
            }
        }
        self.relayoutBoundary = relayoutBoundary

        if sizedByParent {
            performResize()
        }

        performLayout()
        needsLayout = false
        markNeedsPaint()
    }

    /// Updates the render objects size using only the constraints.
    ///
    /// Do not call this function directly: call [layout] instead. This function
    /// is called by [layout] when there is actually work to be done by this
    /// render object during layout. The layout constraints provided by your
    /// parent are available via the [constraints] getter.
    open func performResize() {}

    /// Do the work of computing the layout for this render object.
    ///
    /// Do not call this function directly: call [layout] instead. This function
    /// is called by [layout] when there is actually work to be done by this
    /// render object during layout. The layout constraints provided by your
    /// parent are available via the [constraints] getter.
    open func performLayout() {}

    fileprivate func layoutWithoutResize() {
        performLayout()
        needsLayout = false
        markNeedsPaint()
    }

    // MARK: - Painting

    /// Whether this render object repaints separately from its parent.
    ///
    /// Override this in subclasses to indicate that instances of your class ought
    /// to repaint independently. For example, render objects that repaint
    /// frequently might want to repaint themselves without requiring their parent
    /// to repaint.
    ///
    /// If this getter returns true, the [paintBounds] are applied to this object
    /// and all descendants. The framework invokes [RenderObject.updateCompositedLayer]
    /// to create an [OffsetLayer] and assigns it to the [layer] field.
    /// Render objects that declare themselves as repaint boundaries must not replace
    /// the layer created by the framework.
    ///
    /// If the value of this getter changes, [markNeedsCompositingBitsUpdate] must
    /// be called.
    open var isRepaintBoundary: Bool { false }

    /// An estimate of the bounds within which this render object will paint.
    /// Useful for debugging flags such as [debugPaintLayerBordersEnabled].
    ///
    /// These are also the bounds used by [showOnScreen] to make a [RenderObject]
    /// visible on screen.
    open var paintBounds: Rect { Rect.zero }

    /// Whether this render object was a repaint boundary the last time it was
    /// painted.
    lazy fileprivate var wasRepaintBoundary = isRepaintBoundary

    private(set) var needsPaint = true

    /// Mark this render object as having changed its visual appearance.
    ///
    /// Rather than eagerly updating this render object's display list
    /// in response to writes, we instead mark the render object as needing to
    /// paint, which schedules a visual update. As part of the visual update, the
    /// rendering pipeline will give this render object an opportunity to update
    /// its display list.
    public func markNeedsPaint() {
        if needsPaint {
            return
        }
        needsPaint = true

        if isRepaintBoundary && wasRepaintBoundary {
            if let owner {
                owner.nodesNeedingPaint.append(self)
                owner.requestVisualUpdate()
            }
        } else if let parent = parent {
            parent.markNeedsPaint()
        } else {
            // If we are the root of the render tree and not a repaint boundary
            // then we have to paint ourselves, since nobody else can paint us.
            // We don't add ourselves to _nodesNeedingPaint in this case,
            // because the root is always told to paint regardless.
            //
            // Trees rooted at a RenderView do not go through this
            // code path because RenderViews are repaint boundaries.
            if let owner {
                owner.requestVisualUpdate()
            }
        }

    }

    fileprivate func paintWithContext(_ context: PaintingContext, _ offset: Offset) {
        // If we still need layout, then that means that we were skipped in the
        // layout phase and therefore don't need painting.
        if needsLayout {
            return
        }

        needsPaint = false
        needsCompositedLayerUpdate = false
        wasRepaintBoundary = isRepaintBoundary
        paint(context: context, offset: offset)
    }

    /// Paint this render object into the given context at the given offset.
    ///
    /// Subclasses should override this method to provide a visual appearance
    /// for themselves. The render object's local coordinate system is
    /// axis-aligned with the coordinate system of the context's canvas and the
    /// render object's local origin (i.e, x=0 and y=0) is placed at the given
    /// offset in the context's canvas.
    ///
    /// Do not call this function directly. If you wish to paint yourself, call
    /// [markNeedsPaint] instead to schedule a call to this function. If you wish
    /// to paint one of your children, call [PaintingContext.paintChild] on the
    /// given `context`.
    ///
    /// When painting one of your children (via a paint child function on the
    /// given context), the current canvas held by the context might change
    /// because draw operations before and after painting children might need to
    /// be recorded on separate compositing layers.
    open func paint(context: PaintingContext, offset: Offset) {}

    /// Applies the transform that would be applied when painting the given child
    /// to the given matrix.
    ///
    /// Used by coordinate conversion functions to translate coordinates local to
    /// one render object into coordinates local to another render object.
    ///
    /// Some RenderObjects will provide a zeroed out matrix in this method,
    /// indicating that the child should not paint anything or respond to hit
    /// tests currently. A parent may supply a non-zero matrix even though it
    /// does not paint its child currently, for example if the parent is a
    /// [RenderOffstage] with `offstage` set to true. In both of these cases,
    /// the parent must return `false` from [paintsChild].
    open func applyPaintTransform(_ child: RenderObject, transform: inout Matrix4x4f) {
        assert(child.parent === self)
    }

    // MARK: - Compositing Bits

    fileprivate var needsCompositingBitsUpdate = false

    /// Mark the compositing state for this render object as dirty.
    ///
    /// This is called to indicate that the value for [needsCompositing] needs to
    /// be recomputed during the next [PipelineOwner.flushCompositingBits] engine
    /// phase.
    func markNeedsCompositingBitsUpdate() {
        if needsCompositingBitsUpdate {
            return
        }
        needsCompositingBitsUpdate = true

        if let parent {
            if parent.needsCompositingBitsUpdate {
                return
            }

            if (!wasRepaintBoundary || !isRepaintBoundary) && !parent.isRepaintBoundary {
                parent.markNeedsCompositingBitsUpdate()
                return
            }
        }

        if let owner {
            owner.nodesNeedingCompositingBitsUpdate.append(self)
        }
    }

    fileprivate func updateCompositingBits() {
        if !needsCompositingBitsUpdate {
            return
        }
        let oldNeedsCompositing = needsCompositing
        needsCompositing = false

        (self as? any RenderObjectWithChild)?.visitChildren { child in
            child.updateCompositingBits()
            if child.needsCompositing {
                needsCompositing = true
            }
        }

        if isRepaintBoundary || alwaysNeedsCompositing {
            needsCompositing = true
        }

        // If a node was previously a repaint boundary, but no longer is one, then
        // regardless of its compositing state we need to find a new parent to
        // paint from. To do this, we mark it clean again so that the traversal
        // in markNeedsPaint is not short-circuited. It is removed from _nodesNeedingPaint
        // so that we do not attempt to paint from it after locating a parent.
        if !isRepaintBoundary && wasRepaintBoundary {
            needsPaint = false
            needsCompositedLayerUpdate = false
            owner?.nodesNeedingPaint.remove(object: self)
            markNeedsPaint()
        } else if oldNeedsCompositing != needsCompositing {
            needsCompositingBitsUpdate = false
            markNeedsPaint()
        } else {
            needsCompositingBitsUpdate = false
        }
    }

    // MARK: - Composited Layer

    var layer: Layer?

    /// Whether this render object always needs compositing.
    ///
    /// Override this in subclasses to indicate that your paint function always
    /// creates at least one composited layer. For example, videos should return
    /// true if they use hardware decoders.
    ///
    /// You must call `markNeedsCompositingBitsUpdate` if the value of this getter
    /// changes. (This is implied when `adoptChild` or `dropChild` are called.)
    open var alwaysNeedsCompositing: Bool { false }

    public private(set) lazy var needsCompositing = isRepaintBoundary || alwaysNeedsCompositing

    public fileprivate(set) var needsCompositedLayerUpdate = false

    /// Mark this render object as having changed a property on its composited
    /// layer.
    ///
    /// Render objects that have a composited layer have [isRepaintBoundary] equal
    /// to true may update the properties of that composited layer without repainting
    /// their children. If this render object is a repaint boundary but does
    /// not yet have a composited layer created for it, this method will instead
    /// mark the nearest repaint boundary parent as needing to be painted.
    ///
    /// If this method is called on a render object that is not a repaint boundary
    /// or is a repaint boundary but hasn't been composited yet, it is equivalent
    /// to calling [markNeedsPaint].
    public func markNeedsCompositedLayerUpdate() {
        if needsCompositedLayerUpdate || needsPaint {
            return
        }
        needsCompositedLayerUpdate = true
        // If this was not previously a repaint boundary it will not have
        // a layer we can paint from.
        if isRepaintBoundary && wasRepaintBoundary {
            owner?.nodesNeedingPaint.append(self)
            owner?.requestVisualUpdate()
        } else {
            markNeedsPaint()
        }
    }

    /// Update the composited layer owned by this render object.
    ///
    /// This method is called by the framework when [isRepaintBoundary] is true.
    ///
    /// If [oldLayer] is `null`, this method must return a new [OffsetLayer]
    /// (or subtype thereof). If [oldLayer] is not `null`, then this method must
    /// reuse the layer instance that is provided - it is an error to create a new
    /// layer in this instance. The layer will be disposed by the framework when
    /// either the render object is disposed or if it is no longer a repaint
    /// boundary.
    open func updateCompositedLayer(oldLayer: OffsetLayer?) -> OffsetLayer {
        return oldLayer ?? OffsetLayer()
    }

    // MARK: - Events

    /// Override this method to handle pointer events that hit this render object.
    public func handleEvent(_ event: PointerEvent, entry: HitTestEntry) {}

    public func debugDescribeChildren() -> [DiagnosticableTree] {
        if let selfWithChild = self as? any RenderObjectWithChild {
            var children: [DiagnosticableTree] = []
            selfWithChild.visitChildren { children.append($0) }
            return children
        }
        return []
    }

    public func toStringShort() -> String {
        return describeIdentity(self)
    }
}

public protocol RenderObjectWithChild<ChildType>: RenderObject {
    associatedtype ChildType: RenderObject

    func visitChildren(visitor: (ChildType) -> Void)

    func redepthChildren()

    func attachChild(_ owner: RenderOwner)

    func detachChild()
}

extension RenderObjectWithChild {
    public func redepthChildren() {
        visitChildren { redepthChild($0) }
    }

    public func attachChild(_ owner: RenderOwner) {
        visitChildren { $0.attach(owner) }
    }

    public func detachChild() {
        visitChildren { $0.detach() }
    }
}

// MARK: - Single Child

/// Opaque storage for a [RenderObject] that uses a [RenderObjectWithSingleChild]
public struct RenderSingleChildMixin<T: RenderObject> {
    fileprivate var child: T?
}

/// Generic mixin for render objects with one child.
///
/// Provides a child model for a render object subclass that has a unique child,
/// which is accessible via the [child] getter.
public protocol RenderObjectWithSingleChild: RenderObjectWithChild {
    /// Storage required to store children.
    var childMixin: RenderSingleChildMixin<ChildType> { get set }
}

extension RenderObjectWithSingleChild {
    public var child: ChildType? {
        get { childMixin.child }
        set {
            if let child { dropChild(child: child) }
            childMixin.child = newValue
            if let child { adoptChild(child: child) }
        }
    }

    public func setChild(child: RenderObject?) {
        if let child {
            self.child = (child as! ChildType)
        } else {
            self.child = nil
        }
    }

    public func visitChildren(visitor: (ChildType) -> Void) {
        if let child = child {
            visitor(child)
        }
    }

}

// MARK: - Multi Child

/// Parent data to support a doubly-linked list of children.
///
/// The children can be traversed using [nextSibling] or [previousSibling],
/// which can be called on the parent data of the render objects
/// obtained via [ContainerRenderObjectMixin.firstChild] or
/// [ContainerRenderObjectMixin.lastChild].
public protocol ContainerParentData<ChildType>: ParentData {
    associatedtype ChildType: RenderObject

    /// The previous sibling in the parent's child list.
    var nextSibling: ChildType? { get set }

    /// The next sibling in the parent's child list.
    var previousSibling: ChildType? { get set }
}

/// Opaque storage for a [RenderObject] that uses a [RenderObjectWithSingleChild]
public struct RenderContainerMixin<T: RenderObject> {
    fileprivate var firstChild: T?
    fileprivate var lastChild: T?
    fileprivate var childCount: Int = 0
}

/// Generic mixin for render objects with a list of children.
///
/// Provides a child model for a render object subclass that has a doubly-linked
/// list of children.
public protocol RenderObjectWithChildren: RenderObjectWithChild {
    associatedtype ParentDataType: ContainerParentData<ChildType>

    /// Storage required to store children.
    var childMixin: RenderContainerMixin<ChildType> { get set }
}

extension RenderObjectWithChildren {
    /// The number of children.
    public var childCount: Int { childMixin.childCount }

    private func debugUltimatePreviousSiblingOf(_ child: ChildType) -> ChildType {
        var child = child
        var childParentData = child.parentData! as! ParentDataType
        while childParentData.previousSibling !== nil {
            assert(childParentData.previousSibling !== child)
            child = childParentData.previousSibling!
            childParentData = child.parentData! as! ParentDataType
        }
        return child
    }

    private func debugUltimateNextSiblingOf(_ child: ChildType) -> ChildType {
        var child = child
        var childParentData = child.parentData! as! ParentDataType
        while childParentData.nextSibling != nil {
            assert(childParentData.nextSibling !== child)
            child = childParentData.nextSibling!
            childParentData = child.parentData! as! ParentDataType
        }
        return child
    }

    private func insertIntoChildList(_ child: ChildType, after: ChildType?) {
        let childParentData = child.parentData as! ParentDataType
        assert(childParentData.nextSibling == nil)
        assert(childParentData.previousSibling == nil)
        childMixin.childCount += 1
        assert(childCount > 0)

        if let after {
            assert(childMixin.firstChild != nil)
            assert(childMixin.lastChild != nil)
            assert(debugUltimatePreviousSiblingOf(after) === childMixin.firstChild)
            assert(debugUltimateNextSiblingOf(after) === childMixin.lastChild)
            let afterParentData = after.parentData as! ParentDataType
            if afterParentData.nextSibling == nil {
                assert(after === childMixin.lastChild)
                childParentData.previousSibling = after
                afterParentData.nextSibling = child
                childMixin.lastChild = child
            } else {
                // insert in the middle; we'll end up with three or more children
                // set up links from child to siblings
                childParentData.nextSibling = afterParentData.nextSibling
                childParentData.previousSibling = after
                // set up links from siblings to child
                let childPreviousSiblingParentData =
                    childParentData.previousSibling!.parentData as! ParentDataType
                let childNextSiblingParentData =
                    childParentData.nextSibling!.parentData as! ParentDataType
                childPreviousSiblingParentData.nextSibling = child
                childNextSiblingParentData.previousSibling = child
                assert(afterParentData.nextSibling === child)
            }
        } else {
            childParentData.nextSibling = childMixin.firstChild
            if let firstChild = childMixin.firstChild {
                let firstChildParentData = firstChild.parentData as! ParentDataType
                firstChildParentData.previousSibling = child
            }
            childMixin.firstChild = child
            childMixin.lastChild = childMixin.lastChild ?? child
        }
    }

    /// Insert child into this render object's child list after the given child.
    ///
    /// If `after` is null, then this inserts the child at the start of the list,
    /// and the child becomes the new [firstChild].
    public func insert(_ child: RenderObject, after: RenderObject? = nil) {
        let child = child as! ChildType
        let after = after as! ChildType?
        assert(child !== self, "A RenderObject cannot be inserted into itself.")
        assert(
            after !== self,
            "A RenderObject cannot simultaneously be both the parent and the sibling of another RenderObject."
        )
        assert(child !== after, "A RenderObject cannot be inserted after itself.")
        assert(child !== childMixin.firstChild)
        assert(child !== childMixin.lastChild)

        adoptChild(child: child)
        insertIntoChildList(child, after: after)
    }

    /// Append child to the end of this render object's child list.
    public func add(_ child: RenderObject) {
        let child = child as! ChildType
        insert(child, after: childMixin.lastChild)
    }

    /// Add all the children to the end of this render object's child list.
    public func addAll(_ children: [RenderObject]) {
        for child in children {
            add(child)
        }
    }

    private func removeFromChildList(_ child: ChildType) {
        let childParentData = child.parentData as! ParentDataType
        assert(debugUltimatePreviousSiblingOf(child) === childMixin.firstChild)
        assert(debugUltimateNextSiblingOf(child) === childMixin.lastChild)
        assert(childCount > 0)

        if childParentData.previousSibling == nil {
            assert(childMixin.firstChild === child)
            childMixin.firstChild = childParentData.nextSibling
        } else {
            let childPreviousSiblingParentData =
                childParentData.previousSibling!.parentData as! ParentDataType
            childPreviousSiblingParentData.nextSibling = childParentData.nextSibling
        }

        if childParentData.nextSibling == nil {
            assert(childMixin.lastChild === child)
            childMixin.lastChild = childParentData.previousSibling
        } else {
            let childNextSiblingParentData =
                childParentData.nextSibling!.parentData as! ParentDataType
            childNextSiblingParentData.previousSibling = childParentData.previousSibling
        }

        childParentData.previousSibling = nil
        childParentData.nextSibling = nil
        childMixin.childCount -= 1
    }

    /// Remove this child from the child list.
    ///
    /// Requires the child to be present in the child list.
    func remove(_ child: RenderObject) {
        let child = child as! ChildType
        removeFromChildList(child)
        dropChild(child: child)
    }

    /// Remove all their children from this render object's child list.
    ///
    /// More efficient than removing them individually.
    func removeAll() {
        var child: ChildType? = childMixin.firstChild
        while child != nil {
            let childParentData = child!.parentData as! ParentDataType
            let next = childParentData.nextSibling
            childParentData.previousSibling = nil
            childParentData.nextSibling = nil
            dropChild(child: child!)
            child = next
        }
        childMixin.firstChild = nil
        childMixin.lastChild = nil
        childMixin.childCount = 0
    }

    /// Move the given `child` in the child list to be after another child.
    ///
    /// More efficient than removing and re-adding the child. Requires the child
    /// to already be in the child list at some position. Pass null for `after` to
    /// move the child to the start of the child list.
    func move(_ child: RenderObject, after: RenderObject? = nil) {
        let child = child as! ChildType
        let after = after as! ChildType?
        assert(child !== self)
        assert(after !== self)
        assert(child !== after)
        assert(child.parent === self)
        let childParentData = child.parentData! as! ParentDataType
        if childParentData.previousSibling === after {
            return
        }
        removeFromChildList(child)
        insertIntoChildList(child, after: after)
        markNeedsLayout()
    }

    public func visitChildren(visitor: (ChildType) -> Void) {
        var next: ChildType? = childMixin.firstChild
        while let child = next {
            visitor(child)
            let childParentData = child.parentData as! ParentDataType
            next = childParentData.nextSibling
        }
    }
}

extension RenderObjectWithChildren where ParentDataType: ContainerBoxParentData<ChildType> {
    //       void defaultPaint(PaintingContext context, Offset offset) {
    //     ChildType? child = firstChild;
    //     while (child != null) {
    //       final ParentDataType childParentData = child.parentData! as ParentDataType;
    //       context.paintChild(child, childParentData.offset + offset);
    //       child = childParentData.nextSibling;
    //     }
    //   }
    func defaultPaint(context: PaintingContext, offset: Offset) {
        visitChildren { child in
            let childParentData = child.parentData as! ParentDataType
            context.paintChild(child, offset: childParentData.offset + offset)
        }
    }

    /// Performs a hit test on each child by walking the child list backwards.
    ///
    /// Stops walking once after the first child reports that it contains the
    /// given point. Returns whether any children contain the given point.
    ///
    /// See also:
    ///
    ///  * [defaultPaint], which paints the children appropriate for this
    ///    hit-testing strategy.
    func defaultHitTestChildren(_ result: BoxHitTestResult, position: Offset) -> Bool {
        var child: ChildType? = childMixin.lastChild
        while child != nil {
            // The x, y parameters have the top left of the node's box as the origin.
            let childParentData = child!.parentData! as! ParentDataType
            let isHit = result.addWithPaintOffset(
                offset: childParentData.offset,
                position: position,
                hitTest: { result, transformed in
                    assert(transformed == position - childParentData.offset)
                    return child!.hitTest(result, position: transformed)
                }
            )
            if isHit {
                return true
            }
            child = childParentData.previousSibling
        }
        return false
    }
}
