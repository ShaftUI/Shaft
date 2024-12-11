// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Bootstraps a render tree that is rendered into the provided [FlutterView].
///
/// The content rendered into that view is determined by the provided [child].
/// Descendants within the same [LookupBoundary] can look up the view they are
/// rendered into via [View.of] and [View.maybeOf].
///
/// The provided [child] is wrapped in a [MediaQuery] constructed from the given
/// [view].
///
/// For most use cases, using [MediaQuery.of], or its associated "...Of" methods
/// are a more appropriate way of obtaining the information that a [FlutterView]
/// exposes. For example, using [MediaQuery.sizeOf] will expose the _logical_
/// device size ([MediaQueryData.size]) rather than the physical size
/// ([FlutterView.physicalSize]). Similarly, while [FlutterView.padding] conveys
/// the information from the operating system, the [MediaQueryData.padding]
/// attribute (obtained from [MediaQuery.paddingOf]) further adjusts this
/// information to be aware of the context of the widget; e.g. the [Scaffold]
/// widget adjusts the values for its various children.
///
/// Each [FlutterView] can be associated with at most one [View] widget in the
/// widget tree. Two or more [View] widgets configured with the same
/// [FlutterView] must never exist within the same widget tree at the same time.
/// This limitation is enforced by a [GlobalObjectKey] that derives its identity
/// from the [view] provided to this widget.
///
/// Since the [View] widget bootstraps its own independent render tree, neither
/// it nor any of its descendants will insert a [RenderObject] into an existing
/// render tree. Therefore, the [View] widget can only be used in those parts of
/// the widget tree where it is not required to participate in the construction
/// of the surrounding render tree. In other words, the widget may only be used
/// in a non-rendering zone of the widget tree (see [WidgetsBinding] for a
/// definition of rendering and non-rendering zones).
///
/// In practical terms, the widget is typically used at the root of the widget
/// tree outside of any other [View] widget, as a child of a [ViewCollection]
/// widget, or in the [ViewAnchor.view] slot of a [ViewAnchor] widget. It is not
/// required to be a direct child, though, since other non-[RenderObjectWidget]s
/// (e.g. [InheritedWidget]s, [Builder]s, or [StatefulWidget]s/[StatelessWidget]
/// that only produce non-[RenderObjectWidget]s) are allowed to be present
/// between those widgets and the [View] widget.
///
public final class View: StatefulWidget {
    public init(view: NativeView, renderingOwner: RenderOwner, child: Widget) {
        self.view = view
        self.renderingOwner = renderingOwner
        self.child = child
    }

    public let view: NativeView

    let renderingOwner: RenderOwner

    public let child: Widget

    public func createState() -> some State<View> {
        ViewState()
    }

    public static func maybeOf(_ context: BuildContext) -> NativeView? {
        context.dependOnInheritedWidgetOfExactType(ViewScope.self)?.view
    }
}

private class ViewState: State<View> {
    lazy var textInput = TextInput(widget.view)

    override func build(context: any BuildContext) -> any Widget {
        ViewScope(view: widget.view) {
            TextInputScope(textInput: textInput) {
                RawView(
                    view: widget.view,
                    renderingOwner: widget.renderingOwner,
                    child: widget.child
                )
            }
        }
    }
}

class RawView: RenderObjectWidget {
    internal init(
        view: NativeView,
        renderingOwner: RenderOwner,
        child: Widget
    ) {
        self.view = view
        self.renderingOwner = renderingOwner
        self.child = child
    }

    let view: NativeView

    let renderingOwner: RenderOwner

    let child: Widget

    func createRenderObject(context: BuildContext) -> RenderView {
        RenderView(nativeView: view)
    }

    func createElement() -> Element {
        RawViewElement(self)
    }
}

class RawViewElement: RenderObjectElement {
    override func mount(_ parent: Element?, slot: Slot? = nil) {
        super.mount(parent, slot: slot)
        (widget as! RawView).renderingOwner.rootNode = renderObject
        attachView()
        updateChild()
        (renderObject as! RenderView).prepareInitialFrame()
        // if _effectivePipelineOwner.semanticsOwner != null {
        //     renderObject.scheduleInitialSemantics()
        // }
    }

    override func performRebuild() {
        super.performRebuild()
        updateChild()
    }

    override func update(_ newWidget: any Widget) {
        super.update(newWidget)
        updateChild()
    }

    override func forgetChild(_ child: Element) {
        assert(child == self.child)
        self.child = nil
        super.forgetChild(child)
    }

    private func attachView() {
        RendererBinding.shared.addRenderView(renderObject as! RenderView)
    }

    private func detachView() {
        // (widget as! RawView).rendererBinding.removeRenderView(renderObject as! RenderView)
    }

    private var child: Element?

    private func updateChild() {
        child = updateChild(child, (widget as! RawView).child, nil)
    }

    override func insertRenderObjectChild(_ child: RenderObject, _ slot: Slot?) {
        let renderObject = (renderObject as! RenderView)
        renderObject.child = (child as! RenderBox)
        // renderObject.child
    }

    override func visitChildren(_ visitor: (Element) -> Void) {
        if let child = child {
            visitor(child)
        }
    }
}

internal class ViewScope: InheritedWidget {
    internal init(
        view: NativeView,
        @WidgetBuilder child: () -> Widget
    ) {
        self.view = view
        self.child = child()
    }

    let view: NativeView

    let child: Widget

    func updateShouldNotify(_ oldWidget: ViewScope) -> Bool {
        view !== oldWidget.view
    }
}

public class TextInputScope: InheritedWidget {
    public init(
        textInput: TextInput,
        @WidgetBuilder child: () -> Widget
    ) {
        self.textInput = textInput
        self.child = child()
    }

    public let textInput: TextInput

    public let child: Widget

    public func updateShouldNotify(_ oldWidget: TextInputScope) -> Bool {
        textInput !== oldWidget.textInput
    }
}
