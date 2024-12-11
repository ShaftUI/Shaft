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

}
