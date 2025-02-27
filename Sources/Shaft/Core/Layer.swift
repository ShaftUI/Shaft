// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// A place for layers to paint themselves.
public struct LayerPaintContext {
    var canvas: Canvas
}

public struct LayerTree {
    let root: Layer

    public init(root: Layer) {
        self.root = root
    }

    public func paint(context: LayerPaintContext) {
        root.paint(context: context)
    }
}

/// A composited layer.
public protocol Layer: AnyObject {
    func paint(context: LayerPaintContext)
}

/// A composited layer that has a list of children.
///
/// A [ContainerLayer] instance merely takes a list of children and inserts them
/// into the composited rendering in order. There are subclasses of
/// [ContainerLayer] which apply more elaborate effects in the process.
public class ContainerLayer: Layer {
    var children: [Layer] = []

    /// Returns whether this layer has at least one child layer.
    var hasChildren: Bool {
        return !children.isEmpty
    }

    public func removeAllChildren() {
        children.removeAll()
    }

    public func append(_ child: Layer) {
        children.append(child)
    }

    func paintChildren(context: LayerPaintContext) {
        for child in children {
            child.paint(context: context)
        }
    }

    public func paint(context: LayerPaintContext) {
        paintChildren(context: context)
    }
}

/// A layer that is displayed at an offset from its parent layer.
///
/// Offset layers are key to efficient repainting because they are created by
/// repaint boundaries in the [RenderObject] tree (see
/// [RenderObject.isRepaintBoundary]). When a render object that is a repaint
/// boundary is asked to paint at given offset in a [PaintingContext], the
/// render object first checks whether it needs to repaint itself. If not, it
/// reuses its existing [OffsetLayer] (and its entire subtree) by mutating its
/// [offset] property, cutting off the paint walk.
public class OffsetLayer: ContainerLayer {
    public init(offset: Offset = Offset.zero) {
        self.offset = offset
    }

    public var offset: Offset

    public override func paint(context: LayerPaintContext) {
        context.canvas.save()
        context.canvas.translate(offset.dx, offset.dy)
        super.paint(context: context)
        context.canvas.restore()
    }
}

/// A composited layer that applies a given transformation matrix to its
/// children.
///
/// This class inherits from [OffsetLayer] to make it one of the layers that
/// can be used at the root of a [RenderObject] hierarchy.
public class TransformLayer: OffsetLayer {
    public init(transform: Matrix4x4f = .identity) {
        self.transform = transform
    }

    public var transform: Matrix4x4f

    public override func paint(context: LayerPaintContext) {
        let effectiveTransform =
            offset == Offset.zero
            ? transform
            : Matrix4x4f.translate(tx: offset.dx, ty: offset.dy, tz: 0) * transform
        context.canvas.save()
        context.canvas.transform(effectiveTransform)
        super.paint(context: context)
        context.canvas.restore()
    }
}

/// A composited layer containing a [DisplayList].
///
/// Picture layers are always leaves in the layer tree.
public class PictureLayer: Layer {
    let canvasBounds: Rect

    var picture: DisplayList?

    public init(canvasBounds: Rect) {
        self.canvasBounds = canvasBounds
    }

    public func paint(context: LayerPaintContext) {
        if let picture {
            context.canvas.drawDisplayList(picture)
        }
    }
}

/// A composite layer that clips its children using a rectangle.
public class ClipRectLayer: ContainerLayer {
    public init(clipRect: Rect = .zero, clipBehavior: Clip = .hardEdge) {
        self.clipRect = clipRect
        self.clipBehavior = clipBehavior
    }

    /// The rectangle to clip in the parent's coordinate system.
    public var clipRect: Rect

    /// Controls how to clip.
    ///
    /// Must not be set to null or [Clip.none].
    public var clipBehavior: Clip = .hardEdge

    public override func paint(context: LayerPaintContext) {
        context.canvas.save()
        context.canvas.clipRect(clipRect, .intersect, clipBehavior != .hardEdge)
        if clipBehavior == .antiAliasWithSaveLayer {
            context.canvas.saveLayer(clipRect, paint: nil)
        }
        super.paint(context: context)
        if clipBehavior == .antiAliasWithSaveLayer {
            context.canvas.restore()
        }
        context.canvas.restore()
    }
}

/// A composite layer that clips its children using a rounded rectangle.
public class ClipRRectLayer: ContainerLayer {
    public init(clipRRect: RRect = .zero, clipBehavior: Clip = .hardEdge) {
        self.clipRRect = clipRRect
        self.clipBehavior = clipBehavior
    }

    /// The rounded rectangle to clip in the parent's coordinate system.
    public var clipRRect: RRect

    /// Controls how to clip.
    ///
    /// Must not be set to null or [Clip.none].
    public var clipBehavior: Clip = .hardEdge

    public override func paint(context: LayerPaintContext) {
        context.canvas.save()
        context.canvas.clipRRect(clipRRect, clipBehavior != .hardEdge)
        if clipBehavior == .antiAliasWithSaveLayer {
            context.canvas.saveLayer(clipRRect.outerRect, paint: nil)
        }
        super.paint(context: context)
        if clipBehavior == .antiAliasWithSaveLayer {
            context.canvas.restore()
        }
        context.canvas.restore()
    }
}
