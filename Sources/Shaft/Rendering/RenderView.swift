// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import SwiftMath

/// The layout constraints for the root render object.
public struct ViewConfiguration: Equatable {
    /// The size of the output surface.
    var size: Size

    /// The pixel density of the output surface.
    var devicePixelRatio: Double

    public init(size: Size, devicePixelRatio: Double) {
        self.size = size
        self.devicePixelRatio = devicePixelRatio
    }

    /// Creates a transformation matrix that applies the [devicePixelRatio].
    func toMatrix() -> Matrix4x4f {
        Matrix4x4f.scale(sx: Float(devicePixelRatio), sy: Float(devicePixelRatio), sz: 1)
    }
}

/// The root of the render tree.
///
/// The view represents the total output surface of the render tree and handles
/// bootstrapping the rendering pipeline. The view has a unique child
/// ``RenderBox``, which is required to fill the entire output surface.
public class RenderView: RenderObject, RenderObjectWithSingleChild {
    public typealias ChildType = RenderBox

    public var childMixin = RenderSingleChildMixin<RenderBox>()

    public init(nativeView: NativeView) {
        self.configuration = Self.createViewConfigurationFor(nativeView)
        self.nativeView = nativeView
        super.init()
    }

    func handleMetricsChanged() {
        configuration = Self.createViewConfigurationFor(nativeView)
    }

    /// Returns a [ViewConfiguration] configured for the provided [RenderView]
    /// based on the current environment.
    private static func createViewConfigurationFor(_ view: NativeView) -> ViewConfiguration {
        return ViewConfiguration(
            size: view.physicalSize / Float(view.devicePixelRatio),
            devicePixelRatio: view.devicePixelRatio
        )
    }

    /// The constraints used for the root layout.
    ///
    /// Typically, this configuration is set by the [RendererBinding], when the
    /// [RenderView] is registered with it. It will also update the configuration
    /// if necessary. Therefore, if used in conjunction with the [RendererBinding]
    /// this property must not be set manually as the [RendererBinding] will just
    /// override it.
    public private(set) var configuration: ViewConfiguration {
        didSet {
            if configuration == oldValue {
                return
            }
            if rootTransform == nil {
                // [prepareInitialFrame] has not been called yet, nothing to do for now.
                return
            }
            if oldValue.toMatrix() != configuration.toMatrix() {
                replaceRootLayer(updateMatricesAndCreateNewRootLayer())
            }
            assert(rootTransform != nil)
            markNeedsLayout()
        }
    }

    /// The [nativeView] into which this [RenderView] will render into.
    var nativeView: NativeView

    private var rootTransform: Matrix4x4f?

    private func updateMatricesAndCreateNewRootLayer() -> TransformLayer {
        rootTransform = configuration.toMatrix()
        let rootLayer = TransformLayer(transform: rootTransform!)
        return rootLayer
    }

    /// Bootstrap the rendering pipeline by preparing the first frame.
    ///
    /// This should only be called once, and must be called before changing
    /// [configuration]. It is typically called immediately after calling the
    /// constructor.
    ///
    /// This does not actually schedule the first frame. Call
    /// [PipelineOwner.requestVisualUpdate] on [owner] to do that.
    public func prepareInitialFrame() {
        assert(owner != nil)
        assert(rootTransform == nil)
        scheduleInitialLayout()
        scheduleInitialPaint(updateMatricesAndCreateNewRootLayer())
        assert(rootTransform != nil)
    }

    /// Bootstrap the rendering pipeline by scheduling the very first layout.
    ///
    /// Requires this render object to be attached and that this render object
    /// is the root of the render tree.
    private func scheduleInitialLayout() {
        assert(attached)
        assert(parent == nil)
        assert(relayoutBoundary == nil)
        relayoutBoundary = self
        owner!.nodesNeedingLayout.append(self)
    }

    /// Bootstrap the rendering pipeline by scheduling the very first paint.
    ///
    /// Requires that this render object is attached, is the root of the render
    /// tree, and has a composited layer.
    private func scheduleInitialPaint(_ rootLayer: TransformLayer) {
        assert(attached)
        assert(parent == nil)
        assert(isRepaintBoundary)
        assert(layer == nil)
        layer = rootLayer
        assert(needsPaint)
        owner!.nodesNeedingPaint.append(self)
    }

    func replaceRootLayer(_ newLayer: OffsetLayer) {
        assert(layer != nil)
        assert(attached)
        assert(parent == nil)
        assert(isRepaintBoundary)
        layer = newLayer
        markNeedsPaint()
    }

    public private(set) var size = Size.zero

    public override func performLayout() {
        size = configuration.size
        child?.layout(BoxConstraints.tight(size))
    }

    /// Determines the set of render objects located at the given position.
    ///
    /// Returns true if the given point is contained in this render object or one
    /// of its descendants. Adds any render objects that contain the point to the
    /// given hit test result.
    ///
    /// The [position] argument is in the coordinate system of the render view,
    /// which is to say, in logical pixels. This is not necessarily the same
    /// coordinate system as that expected by the root [Layer], which will
    /// normally be in physical (device) pixels.
    public func hitTest(_ result: HitTestResult, position: Offset) {
        if let child {
            let _ = child.hitTest(BoxHitTestResult(wrap: result), position: position)
        }
        result.add(HitTestEntry(self))
    }

    public override var isRepaintBoundary: Bool { true }

    public override func paint(context: PaintingContext, offset: Offset) {
        context.paintChild(child!)
    }

    public override var paintBounds: Rect {
        Offset.zero & size
    }

    func compositeFrame() {
        nativeView.render(LayerTree(root: layer!))
    }
}
