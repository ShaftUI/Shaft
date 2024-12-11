// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A widget for the root of the widget tree.
///
/// Exposes an [attach] method to attach the widget tree to a [BuildOwner]. That
/// method also bootstraps the element tree.
///
/// Used by [WidgetsBinding.attachRootWidget] (which is indirectly called by
/// [runApp]) to bootstrap applications.
class RootWidget: Widget {
    internal init(child: Widget? = nil) {
        self.child = child
    }

    /// The widget below this widget in the tree.
    let child: Widget?

    func createElement() -> Element { RootElement(self) }

    /// Inflate this widget and attaches it to the provided [BuildOwner].
    ///
    /// If `element` is null, this function will create a new element.
    /// Otherwise, the given element will have an update scheduled to switch to
    /// this widget.
    ///
    /// Used by [WidgetsBinding.attachToBuildOwner] (which is indirectly called
    /// by [runApp]) to bootstrap applications.
    func attach(_ owner: BuildOwner, element: RootElement? = nil) -> Element {
        var element = element
        if element == nil {
            owner.lockState {
                element = createElement() as? RootElement
                assert(element != nil)
                element!.assignOwner(owner)
            }
            owner.buildScope(element!) {
                element!.mount(nil, slot: nil)
            }
        } else {
            element!.newWidget = self
            element!.markNeedsBuild()
        }
        return element!
    }
}

/// The root of the element tree.
///
/// This element class is the instantiation of a [RootWidget]. It can be used
/// only as the root of an [Element] tree (it cannot be mounted into another
/// [Element]; its parent must be null).
///
/// In typical usage, it will be instantiated for a [RootWidget] by calling
/// [RootWidget.attach]. In this usage, it is normally instantiated by the
/// bootstrapping logic in the [WidgetsFlutterBinding] singleton created by
/// [runApp].
class RootElement: Element, RootElementMixin {
    init(_ widget: RootWidget) {
        super.init(widget)
    }

    private var child: Element?

    override func mount(_ parent: Element?, slot: Slot?) {
        assert(parent == nil)
        super.mount(parent, slot: slot)
        rebuild()
        assert(child != nil)
        super.performRebuild()  // clears the "dirty" flag
    }

    override func update(_ newWidget: Widget) {
        super.update(newWidget)
        // assert(newWidget == newWidget)
        rebuild()
    }

    // When we are assigned a new widget, we store it here
    // until we are ready to update to it.
    fileprivate var newWidget: RootWidget?

    override func performRebuild() {
        if newWidget != nil {
            let newWidget = self.newWidget!
            self.newWidget = nil
            update(newWidget)
        }
        super.performRebuild()
        assert(newWidget == nil)
    }

    private func rebuild() {
        child = updateChild(child, (widget as! RootWidget).child)
    }

    override func visitChildren(_ visitor: (Element) -> Void) {
        if let child = child {
            visitor(child)
        }
    }
}

public class WidgetsBinding {
    public static let shared = WidgetsBinding()

    private init() {
        RendererBinding.shared.beforeFrameCallbacks.add(beforeDrawFrame)
        RendererBinding.shared.afterFrameCallbacks.add(afterDrawFrame)
    }

    /// The [BuildOwner] in charge of executing the build pipeline for the
    /// widget tree rooted at this binding.
    public lazy var buildOwner = BuildOwner(onBuildScheduled: handleBuildScheduled)

    private func handleBuildScheduled() {
        SchedulerBinding.shared.ensureVisualUpdate()
    }

    /// The [Element] that is at the root of the element tree hierarchy.
    ///
    /// This is initialized the first time [runApp] is called.
    public private(set) var rootElement: Element?

    private var readyToProduceFrames = false

    public func attachRootWidget(_ rootWidget: Widget) {
        attachToBuildOwner(
            RootWidget(child: rootWidget)
        )
    }

    private func attachToBuildOwner(_ widget: RootWidget) {
        let isBootstrapFrame = rootElement == nil
        readyToProduceFrames = true
        rootElement = widget.attach(buildOwner, element: rootElement as! RootElement?)
        if isBootstrapFrame {
            SchedulerBinding.shared.ensureVisualUpdate()
        }
    }

    private func beforeDrawFrame() {
        if let rootElement {
            buildOwner.buildScope(rootElement)
        }
    }

    private func afterDrawFrame() {
        buildOwner.finalizeTree()
    }
}

/// Inflate the given widget and attach it to the screen.
///
/// The widget is given constraints during layout that force it to fill the
/// entire screen. If you wish to align your widget to one side of the screen
/// (e.g., the top), consider using the [Align] widget. If you wish to center
/// your widget, you can also use the [Center] widget.
///
/// Calling [runApp] again will detach the previous root widget from the screen
/// and attach the given widget in its place. The new widget tree is compared
/// against the previous widget tree and any differences are applied to the
/// underlying render tree, similar to what happens when a [StatefulWidget]
/// rebuilds after calling [State.setState].
public func runApp(_ app: Widget) {
    runPlainApp(
        DefaultApp { app }
    )
}

public func runPlainApp(_ app: Widget) {
    guard let view = backend.createView() else {
        fatalError("Failed to create view")
    }

    WidgetsBinding.shared.attachRootWidget(
        View(
            view: view,
            renderingOwner: RendererBinding.shared.rootRenderOwner,
            child: app
        )
    )
    // SchedulerBinding.shared.addPostFrameCallback {
    //     mark("post frame")
    // }
    SchedulerBinding.shared.scheduleFrame()

    backend.run()
}

// public func runApp(@WidgetBuilder _ builder: () -> [View]) {
//     runApp(ViewCollection(children: builder()))
// }

private class DefaultApp: StatelessWidget {
    init(@WidgetBuilder child: () -> Widget) {
        self.child = child()
    }

    let child: Widget

    func build(context: any BuildContext) -> any Widget {
        DefaultTextEditingShortcuts {
            child
        }
        .buttonStyle(.default)
        .background(.init(0xFFFF_FFFF))
        .textStyle(.init(color: .init(0xFF_000000), fontSize: 16))
    }
}
