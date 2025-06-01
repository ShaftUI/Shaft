// A widget that conditionally hides its child, but without the forced
// compositing of `Opacity`.
//
// A fully opaque `Opacity` widget is required to leave its opacity layer in the
// layer tree. This forces all parent render objects to also composite, which
// can break a simple scene into many different layers. This can be
// significantly more expensive, so the issue is avoided by a specialized render
// object that does not ever force compositing.
public class Visibility: SingleChildRenderObjectWidget {
    init(
        visible: Bool,
        maintainSemantics: Bool,
        @OptionalWidgetBuilder child: () -> Widget? = voidBuilder
    ) {
        self.visible = visible
        self.maintainSemantics = maintainSemantics
        self.child = child()
    }

    let visible: Bool
    let maintainSemantics: Bool
    public var child: Widget?

    public func createRenderObject(context: BuildContext) -> RenderVisibility {
        return RenderVisibility(visible, maintainSemantics)
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderVisibility) {
        renderObject.visible = visible
        renderObject.maintainSemantics = maintainSemantics
    }
}

public class RenderVisibility: RenderProxyBox {
    init(_ visible: Bool, _ maintainSemantics: Bool) {
        self.visible = visible
        self.maintainSemantics = maintainSemantics
        super.init()
    }

    var visible: Bool {
        didSet {
            if visible == oldValue {
                return
            }
            markNeedsPaint()
        }
    }

    var maintainSemantics: Bool {
        didSet {
            if maintainSemantics == oldValue {
                return
            }
            // markNeedsSemanticsUpdate()
        }
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        if !visible {
            return
        }
        super.paint(context: context, offset: offset)
    }
}

extension Widget {
    public func visibility(_ visible: Bool, maintainSemantics: Bool = false) -> Widget {
        return Visibility(visible: visible, maintainSemantics: maintainSemantics) { self }
    }
}
