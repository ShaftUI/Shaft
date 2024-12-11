// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// A box in which a single widget can be scrolled.
///
/// This widget is useful when you have a single box that will normally be
/// entirely visible, for example a clock face in a time picker, but you need to
/// make sure it can be scrolled if the container gets too small in one axis
/// (the scroll direction).
///
/// It is also useful if you need to shrink-wrap in both axes (the main
/// scrolling direction as well as the cross axis), as one might see in a dialog
/// or pop-up menu. In that case, you might pair the [SingleChildScrollView]
/// with a [ListBody] child.
///
/// When you have a list of children and do not require cross-axis
/// shrink-wrapping behavior, for example a scrolling list that is always the
/// width of the screen, consider [ListView], which is vastly more efficient
/// than a [SingleChildScrollView] containing a [ListBody] or [Column] with many
/// children.
public final class SingleChildScrollView: StatelessWidget {
    public init(
        scrollDirection: Axis = .vertical,
        reverse: Bool = false,
        padding: EdgeInsetsGeometry? = nil,
        controller: ScrollController? = nil,
        primary: Bool? = nil,
        physics: ScrollPhysics? = nil,
        dragStartBehavior: DragStartBehavior = .start,
        clipBehavior: Clip = .hardEdge,
        restorationId: String? = nil,
        // keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior = .manual,
        @WidgetBuilder child: () -> Widget
    ) {
        assert(
            !(controller != nil && primary != nil),
            "Primary ScrollViews obtain their ScrollController via inheritance "
                + "from a PrimaryScrollController widget. You cannot both set primary to "
                + "true and pass an explicit controller."
        )
        self.scrollDirection = scrollDirection
        self.reverse = reverse
        self.padding = padding
        self.controller = controller
        self.primary = primary
        self.physics = physics
        self.dragStartBehavior = dragStartBehavior
        self.clipBehavior = clipBehavior
        self.restorationId = restorationId
        // self.keyboardDismissBehavior = keyboardDismissBehavior
        self.child = child()
    }

    let scrollDirection: Axis

    /// Whether the scroll view scrolls in the reading direction.
    ///
    /// For example, if the reading direction is left-to-right and
    /// [scrollDirection] is [Axis.horizontal], then the scroll view scrolls from
    /// left to right when [reverse] is false and from right to left when
    /// [reverse] is true.
    ///
    /// Similarly, if [scrollDirection] is [Axis.vertical], then the scroll view
    /// scrolls from top to bottom when [reverse] is false and from bottom to top
    /// when [reverse] is true.
    ///
    /// Defaults to false.
    let reverse: Bool

    /// The amount of space by which to inset the child.
    let padding: EdgeInsetsGeometry?

    /// An object that can be used to control the position to which this scroll
    /// view is scrolled.
    ///
    /// Must be null if [primary] is true.
    ///
    /// A [ScrollController] serves several purposes. It can be used to control
    /// the initial scroll position (see [ScrollController.initialScrollOffset]).
    /// It can be used to control whether the scroll view should automatically
    /// save and restore its scroll position in the [PageStorage] (see
    /// [ScrollController.keepScrollOffset]). It can be used to read the current
    /// scroll position (see [ScrollController.offset]), or change it (see
    /// [ScrollController.animateTo]).
    let controller: ScrollController?

    let primary: Bool?

    /// How the scroll view should respond to user input.
    ///
    /// For example, determines how the scroll view continues to animate after the
    /// user stops dragging the scroll view.
    ///
    /// Defaults to matching platform conventions.
    let physics: ScrollPhysics?

    let dragStartBehavior: DragStartBehavior

    /// Defaults to [Clip.hardEdge].
    let clipBehavior: Clip

    let restorationId: String?

    // let keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior

    /// The widget that scrolls.
    let child: Widget?

    private func getDirection(context: BuildContext) -> AxisDirection {
        getAxisDirectionFromAxisReverseAndDirectionality(
            context: context,
            axis: scrollDirection,
            reverse: reverse
        )
    }

    public func build(context: BuildContext) -> Widget {
        let axisDirection = getDirection(context: context)

        var contents = child
        if let padding {
            contents = Padding(padding) { contents }
        }

        //     final bool effectivePrimary = primary
        //     ?? controller == null && PrimaryScrollController.shouldInherit(context, scrollDirection);

        // final ScrollController? scrollController = effectivePrimary
        //     ? PrimaryScrollController.maybeOf(context)
        //     : controller;
        let scrollController = controller

        let scrollable = Scrollable(
            axisDirection: axisDirection,
            controller: scrollController,
            physics: physics,
            dragStartBehavior: dragStartBehavior,
            restorationId: restorationId,
            clipBehavior: clipBehavior
        ) { context, offset in
            SingleChildViewport(
                axisDirection: axisDirection,
                offset: offset,
                clipBehavior: self.clipBehavior,
                child: contents
            )
        }

        return scrollable
    }
}

private class SingleChildViewport: SingleChildRenderObjectWidget {
    public init(
        axisDirection: AxisDirection,
        offset: ViewportOffset,
        clipBehavior: Clip,
        child: Widget?
    ) {
        self.axisDirection = axisDirection
        self.offset = offset
        self.clipBehavior = clipBehavior
        self.child = child
    }

    let axisDirection: AxisDirection
    let offset: ViewportOffset
    let clipBehavior: Clip
    let child: Widget?

    func createRenderObject(context: BuildContext) -> RenderSingleChildViewport {
        RenderSingleChildViewport(
            axisDirection: axisDirection,
            offset: offset,
            clipBehavior: clipBehavior
        )
    }

    func updateRenderObject(context: BuildContext, renderObject: RenderSingleChildViewport) {
        renderObject.axisDirection = axisDirection
        renderObject.offset = offset
        renderObject.clipBehavior = clipBehavior
    }
}

private class RenderSingleChildViewport: RenderBox, RenderObjectWithSingleChild {
    internal init(
        axisDirection: AxisDirection,
        offset: ViewportOffset,
        clipBehavior: Clip
    ) {
        self.axisDirection = axisDirection
        self.offset = offset
        self.clipBehavior = clipBehavior
    }

    typealias ChildType = RenderBox
    var childMixin = RenderSingleChildMixin<RenderBox>()

    var axisDirection: AxisDirection {
        didSet {
            if axisDirection != oldValue {
                markNeedsLayout()
            }
        }
    }

    var offset: ViewportOffset {
        didSet {
            if offset !== oldValue {
                if attached {
                    oldValue.removeListener(self)
                }
                if attached {
                    offset.addListener(self, callback: hasScrolled)
                }
                markNeedsLayout()
            }
        }
    }

    /// Defaults to [Clip.none].
    var clipBehavior: Clip {
        didSet {
            if clipBehavior != oldValue {
                markNeedsPaint()
                // markNeedsSemanticsUpdate()
            }
        }
    }

    private func hasScrolled() {
        markNeedsPaint()
        // markNeedsSemanticsUpdate()
    }

    override func setupParentData(_ child: RenderObject) {
        // We don't actually use the offset argument in BoxParentData, so let's
        if child.parentData == nil {
            child.parentData = ParentData()
        }
    }

    override func attach(_ owner: RenderOwner) {
        super.attach(owner)
        offset.addListener(self, callback: hasScrolled)
    }

    override func detach() {
        offset.removeListener(self)
        super.detach()
    }

    private var viewportExtent: Float {
        assert(hasSize)
        return switch axisDirection.axis {
        case .horizontal: size.width
        case .vertical: size.height
        }

    }

    private var minScrollExtent: Float {
        assert(hasSize)
        return 0.0
    }

    private var maxScrollExtent: Float {
        assert(hasSize)
        guard let child else {
            return 0.0
        }

        return switch axisDirection.axis {
        case .horizontal: max(0.0, child.size.width - size.width)
        case .vertical: max(0.0, child.size.height - size.height)
        }
    }

    private func getInnerConstraints(constraints: BoxConstraints) -> BoxConstraints {
        switch axisDirection.axis {
        case .horizontal:
            return constraints.heightConstraints()
        case .vertical:
            return constraints.widthConstraints()
        }
    }

    override func performLayout() {
        guard let child else {
            size = boxConstraint.smallest
            return
        }

        child.layout(getInnerConstraints(constraints: boxConstraint), parentUsesSize: true)
        size = boxConstraint.constrain(child.size)

        if offset.hasPixels {
            if offset.pixels > maxScrollExtent {
                offset.correctBy(maxScrollExtent - offset.pixels)
            } else if offset.pixels < minScrollExtent {
                offset.correctBy(minScrollExtent - offset.pixels)
            }
        }

        let _ = offset.applyViewportDimension(viewportExtent)
        let _ = offset.applyContentDimensions(minScrollExtent, maxScrollExtent)
    }

    private var paintOffset: Offset {
        paintOffsetForPosition(position: offset.pixels)
    }

    private func paintOffsetForPosition(position: Float) -> Offset {
        switch axisDirection {
        case .up:
            Offset(0.0, position - child!.size.height + size.height)
        case .down:
            Offset(0.0, -position)
        case .left:
            Offset(position - child!.size.width + size.width, 0.0)
        case .right:
            Offset(-position, 0.0)
        }
    }

    private func shouldClipAtPaintOffset(paintOffset: Offset) -> Bool {
        assert(child != nil)
        switch clipBehavior {
        case .none:
            return false
        case .hardEdge, .antiAlias, .antiAliasWithSaveLayer:
            return paintOffset.dx < 0 || paintOffset.dy < 0
                || paintOffset.dx + child!.size.width > size.width
                || paintOffset.dy + child!.size.height > size.height
        }
    }

    private var clipRectLayer: ClipRectLayer? = nil

    override func paint(context: PaintingContext, offset: Offset) {
        guard let child else {
            return
        }

        let paintOffset = self.paintOffset

        func paintContents(context: PaintingContext, offset: Offset) {
            context.paintChild(child, offset: offset + paintOffset)
        }

        if shouldClipAtPaintOffset(paintOffset: paintOffset) {
            clipRectLayer = context.pushClipRect(
                needsCompositing: needsCompositing,
                offset: offset,
                clipRect: Offset.zero & size,
                clipBehavior: clipBehavior,
                painter: paintContents,
                oldLayer: clipRectLayer
            )
        } else {
            clipRectLayer = nil
            paintContents(context: context, offset: offset)
        }
    }

    override func applyPaintTransform(_ child: RenderObject, transform: inout Matrix4x4f) {
        transform = transform.translated(by: Vector3f(paintOffset.dx, paintOffset.dy, 0))
    }

    override func hitTestChildren(_ result: HitTestResult, position: Offset) -> Bool {
        guard let child else {
            return false
        }
        let result = result as! BoxHitTestResult
        return result.addWithPaintOffset(
            offset: paintOffset,
            position: position,
            hitTest: { result, transformed in
                assert(transformed == position + -paintOffset)
                return child.hitTest(result, position: transformed)
            }
        )
    }
}
