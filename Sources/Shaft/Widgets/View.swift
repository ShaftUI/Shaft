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
    public init(view: NativeView, renderOwner: RenderOwner? = nil, child: Widget) {
        self.view = view
        self.renderOwner = renderOwner
        self.child = child
    }

    public let view: NativeView

    let renderOwner: RenderOwner?

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
                    renderOwner: widget.renderOwner,
                ) { context, renderOwner in
                    RenderOwnerScope(renderOwner: renderOwner) {
                        self.widget.child
                    }
                }
            }
        }
    }
}

class RawView: RenderObjectWidget {
    typealias ContentBuilder = (BuildContext, RenderOwner) -> Widget

    internal init(
        view: NativeView,
        renderOwner: RenderOwner?,
        @WidgetBuilder builder: @escaping ContentBuilder
    ) {
        self.view = view
        self.renderOwner = renderOwner
        self.builder = builder
    }

    let view: NativeView

    let renderOwner: RenderOwner?

    let builder: ContentBuilder

    func createRenderObject(context: BuildContext) -> RenderView {
        RenderView(nativeView: view)
    }

    func createElement() -> Element {
        RawViewElement(self)
    }
}

class RawViewElement: RenderObjectElement {
    private let internalRenderOwner = RenderOwner(
        onNeedVisualUpdate: SchedulerBinding.shared.ensureVisualUpdate
    )
    private var effectiveRenderOwner: RenderOwner {
        (widget as! RawView).renderOwner ?? internalRenderOwner
    }

    override func mount(_ parent: Element?, slot: Slot? = nil) {
        super.mount(parent, slot: slot)
        effectiveRenderOwner.rootNode = renderObject
        attachView()
        updateChild()
        (renderObject as! RenderView).prepareInitialFrame()
        // if _effectivePipelineOwner.semanticsOwner != null {
        //     renderObject.scheduleInitialSemantics()
        // }
    }

    override func activate() {
        super.activate()
        assert(effectiveRenderOwner.rootNode == nil)
        effectiveRenderOwner.rootNode = renderObject
        attachView()
    }

    override func deactivate() {
        super.deactivate()
        detachView()
        effectiveRenderOwner.rootNode = nil
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

    // Is nil if view is currently not attached.
    private var parentRenderOwner: RenderOwner?

    // A view is the root of its own render tree and does not need to attach to
    // a parent render object.
    override func attachRenderObject(_ newSlot: (any Slot)?) {}

    // A view is the root of its own render tree and does not need to detach
    // from a parent render object.
    override func detachRenderObject() {}

    private func attachView() {
        RendererBinding.shared.addRenderView(renderObject as! RenderView)
        if let parent = RenderOwnerScope.maybeOf(self) {
            parent.renderOwner.adoptChild(effectiveRenderOwner)
            parentRenderOwner = parent.renderOwner
        }
    }

    private func detachView() {
        if let parentRenderOwner {
            RendererBinding.shared.removeRenderView(renderObject as! RenderView)
            parentRenderOwner.dropChild(effectiveRenderOwner)
            self.parentRenderOwner = nil
        }
    }

    override func didChangeDependencies() {
        super.didChangeDependencies()
        let newParentRenderOwner = RenderOwnerScope.maybeOf(self)?.renderOwner
        if let newParentRenderOwner, newParentRenderOwner !== parentRenderOwner {
            detachView()
            attachView()
        }
    }

    private var child: Element?

    private func updateChild() {
        child = updateChild(child, (widget as! RawView).builder(self, effectiveRenderOwner), nil)
    }

    override func insertRenderObjectChild(_ child: RenderObject, slot: Slot?) {
        let renderObject = (renderObject as! RenderView)
        renderObject.child = (child as! RenderBox)
    }

    override func moveRenderObjectChild(
        _ child: RenderObject,
        oldSlot: (any Slot)?,
        newSlot: (any Slot)?
    ) {
        assertionFailure()
    }

    override func removeRenderObjectChild(_ child: RenderObject, slot: (any Slot)?) {
        assert(slot == nil)
        assert((renderObject as! RenderView).child === child)
        (renderObject as! RenderView).child = nil
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

/// A scope that provides the [RenderOwner] to its descendants.
internal class RenderOwnerScope: InheritedWidget {
    internal init(
        renderOwner: RenderOwner,
        @WidgetBuilder child: () -> Widget
    ) {
        self.renderOwner = renderOwner
        self.child = child()
    }

    let renderOwner: RenderOwner

    let child: Widget

    func updateShouldNotify(_ oldWidget: RenderOwnerScope) -> Bool {
        renderOwner !== oldWidget.renderOwner
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

/// A widget that creates and manages a sub-window (a separate native view).
///
/// `SubWindow` creates a new native view using the backend and renders its child
/// widget into that view. This allows for creating separate windows or views that
/// can be positioned independently of the main application window.
///
/// The widget provides callbacks for when the window is created and destroyed,
/// allowing the parent to perform additional setup or cleanup as needed.
///
/// Example usage:
/// ```swift
/// SubWindow(
///     onWindowCreated: { view in
///         // Configure the new window
///         view.title = "Sub Window"
///     },
///     onWindowDestroyed: { view in
///         // Cleanup when window is closed
///         print("Window closed")
///     }
/// ) {
///     // Child widget to render in the sub-window
///     Text("Hello from sub-window!")
/// }
/// ```
public final class SubWindow: StatefulWidget {
    public typealias OnCreateWindow = () -> NativeView?
    public typealias OnWindowCreated = (NativeView) -> Void
    public typealias OnWindowDestroyed = (NativeView) -> Void

    public init(
        onCreateWindow: OnCreateWindow? = nil,
        onWindowCreated: OnWindowCreated? = nil,
        onWindowDestroyed: OnWindowDestroyed? = nil,
        @WidgetBuilder child: () -> Widget
    ) {
        self.onCreateWindow = onCreateWindow
        self.onWindowCreated = onWindowCreated
        self.onWindowDestroyed = onWindowDestroyed
        self.child = child()
    }

    /// Optional callback for custom window creation.
    ///
    /// When provided, this callback will be used to create the native view
    /// instead of using the default `backend.createView()` method. This allows
    /// for custom window creation logic, such as wrapping existing native views
    /// or applying specific creation parameters.
    ///
    /// If this callback returns `nil`, the window creation will fail and the
    /// sub-window will not be displayed.
    public let onCreateWindow: OnCreateWindow?

    /// Callback invoked when the native view is successfully created.
    ///
    /// This callback provides access to the newly created `NativeView` instance,
    /// allowing for additional configuration such as setting the window title,
    /// size, or other platform-specific properties.
    public let onWindowCreated: OnWindowCreated?

    /// Callback invoked when the native view is about to be destroyed.
    ///
    /// This callback is called before the view is actually destroyed, providing
    /// an opportunity to perform cleanup operations or save state before the
    /// window is closed.
    public let onWindowDestroyed: OnWindowDestroyed?

    /// The child widget to render within the sub-window.
    ///
    /// This widget will be rendered as the root content of the newly created
    /// native view, forming the visual hierarchy for the sub-window.
    public let child: Widget

    public func createState() -> some State<SubWindow> {
        SubWindowState()
    }
}

private class SubWindowState: State<SubWindow> {
    var window: NativeView?

    override func initState() {
        super.initState()
        window = widget.onCreateWindow?() ?? backend.createView()
        if let window, let onWindowCreated = widget.onWindowCreated {
            onWindowCreated(window)
        }
    }

    override func dispose() {
        if let window, let onWindowDestroyed = widget.onWindowDestroyed {
            backend.destroyView(window)
            onWindowDestroyed(window)
        }
        super.dispose()
    }

    override func build(context: any BuildContext) -> any Widget {
        if let window {
            BoxToViewAdapter {
                View(view: window, child: widget.child)
            }
        } else {
            SizedBox()
        }
    }
}

/// A widget that adapts a box-based widget hierarchy to be rendered within a
/// view.
///
/// `BoxToViewAdapter` serves as a bridge between the box layout system and the
/// view rendering system. It takes a child widget that uses box constraints and
/// adapts it to be rendered within a view context, typically used when
/// embedding widgets into native views or sub-windows.
public class BoxToViewAdapter: SingleChildRenderObjectWidget {
    public init(
        @WidgetBuilder child: () -> Widget
    ) {
        self.child = child()
    }

    public let child: Widget?

    public func createRenderObject(context: BuildContext) -> some RenderObject {
        RenderBoxToViewAdapter()
    }
}

/// The render object for `BoxToViewAdapter` that handles the layout adaptation.
class RenderBoxToViewAdapter: RenderBox, RenderObjectWithSingleChild {
    public var childMixin = RenderSingleChildMixin<RenderView>()

    func visitChildren(visitor: (RenderView) -> Void) {
        if let child {
            visitor(child)
        }
    }

    override func performLayout() {
        size = boxConstraint.smallest
    }

    func attachChild(_ owner: RenderOwner) {}

    func detachChild() {}
}
