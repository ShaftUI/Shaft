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
        backend.onReassemble = reassemble
        backend.onAppLifecycleStateChanged = handleAppLifecycleStateChanged
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

    private func reassemble() {
        if let rootElement {
            buildOwner.reassemble(rootElement)
        }
        RendererBinding.shared.reassemble()
    }

    private var observers: [WidgetsBindingObserver] = []

    /// The observer that is currently handling an active predictive back gesture.
    private var backGestureObserver: WidgetsBindingObserver?

    /// Registers the given object as a binding observer. Binding
    /// observers are notified when various application events occur,
    /// for example when the system locale changes. Generally, one
    /// widget in the widget tree registers itself as a binding
    /// observer, and converts the system state into inherited widgets.
    ///
    /// For example, the [WidgetsApp] widget registers as a binding
    /// observer and passes the screen size to a [MediaQuery] widget
    /// each time it is built, which enables other widgets to use the
    /// [MediaQuery.sizeOf] static method and (implicitly) the
    /// [InheritedWidget] mechanism to be notified whenever the screen
    /// size changes (e.g. whenever the screen rotates).
    ///
    /// See also:
    ///
    ///  * [removeObserver], to release the resources reserved by this method.
    ///  * [WidgetsBindingObserver], which has an example of using this method.
    public func addObserver(_ observer: WidgetsBindingObserver) {
        observers.append(observer)
    }

    /// Unregisters the given observer. This should be used sparingly as it is
    /// relatively expensive (O(N) in the number of registered observers).
    ///
    /// See also:
    ///
    ///  * [addObserver], for the method that adds observers in the first place.
    ///  * [WidgetsBindingObserver], which has an example of using this method.
    @discardableResult
    public func removeObserver(_ observer: WidgetsBindingObserver) -> Bool {
        if observer === backGestureObserver {
            backGestureObserver = nil
        }

        if let index = observers.firstIndex(where: { $0 === observer }) {
            observers.remove(at: index)
            return true
        }
        return false
    }

    private func handleAppLifecycleStateChanged(state: AppLifecycleState) {
        for observer in observers {
            observer.didChangeAppLifecycleState(state: state)
        }
    }
}

/// Interface for classes that register with the Widgets layer binding.
///
/// This can be used by any class, not just widgets. It provides an interface
/// which is used by [WidgetsBinding.addObserver] and
/// [WidgetsBinding.removeObserver] to notify objects of changes in the
/// environment, such as changes to the device metrics or accessibility
/// settings. It is used to implement features such as [MediaQuery].
///
/// This protocol can be adopted directly to get default behaviors
/// for all of the handlers.
///
/// To start receiving notifications, call `WidgetsBinding.shared.addObserver`
/// with a reference to the object implementing the [WidgetsBindingObserver]
/// protocol. To avoid memory leaks, call
/// `WidgetsBinding.shared.removeObserver` to unregister the object when it
/// reaches the end of its lifecycle.
///
/// {@tool dartpad}
/// This sample shows how to implement parts of the [State] and
/// [WidgetsBindingObserver] protocols necessary to react to application
/// lifecycle messages. See [didChangeAppLifecycleState].
///
/// To respond to other notifications, replace the [didChangeAppLifecycleState]
/// method in this example with other methods from this class.
///
/// ** See code in examples/api/lib/widgets/binding/widget_binding_observer.0.dart **
/// {@end-tool}
public protocol WidgetsBindingObserver: AnyObject {
    /// Called when the system tells the app to pop the current route, such as
    /// after a system back button press or back gesture.
    ///
    /// Observers are notified in registration order until one returns
    /// true. If none return true, the application quits.
    ///
    /// Observers are expected to return true if they were able to
    /// handle the notification, for example by closing an active dialog
    /// box, and false otherwise. The [WidgetsApp] widget uses this
    /// mechanism to notify the [Navigator] widget that it should pop
    /// its current route if possible.
    ///
    /// This method exposes the `popRoute` notification from
    /// [SystemChannels.navigation].
    ///
    /// {@macro flutter.widgets.AndroidPredictiveBack}
    func didPopRoute() async -> Bool

    /// Called at the start of a predictive back gesture.
    ///
    /// Observers are notified in registration order until one returns true or all
    /// observers have been notified. If an observer returns true then that
    /// observer, and only that observer, will be notified of subsequent events in
    /// this same gesture (for example [handleUpdateBackGestureProgress], etc.).
    ///
    /// Observers are expected to return true if they were able to handle the
    /// notification, for example by starting a predictive back animation, and
    /// false otherwise. [PredictiveBackPageTransitionsBuilder] uses this
    /// mechanism to listen for predictive back gestures.
    ///
    /// If all observers indicate they are not handling this back gesture by
    /// returning false, then a navigation pop will result when
    /// [handleCommitBackGesture] is called, as in a non-predictive system back
    /// gesture.
    ///
    /// Currently, this is only used on Android devices that support the
    /// predictive back feature.
    // func handleStartBackGesture(backEvent: PredictiveBackEvent) -> Bool

    /// Called when a predictive back gesture moves.
    ///
    /// The observer which was notified of this gesture's [handleStartBackGesture]
    /// is the same observer notified for this.
    ///
    /// Currently, this is only used on Android devices that support the
    /// predictive back feature.
    // func handleUpdateBackGestureProgress(backEvent: PredictiveBackEvent)

    /// Called when a predictive back gesture is finished successfully, indicating
    /// that the current route should be popped.
    ///
    /// The observer which was notified of this gesture's [handleStartBackGesture]
    /// is the same observer notified for this. If there is none, then a
    /// navigation pop will result, as in a non-predictive system back gesture.
    ///
    /// Currently, this is only used on Android devices that support the
    /// predictive back feature.
    func handleCommitBackGesture()

    /// Called when a predictive back gesture is canceled, indicating that no
    /// navigation should occur.
    ///
    /// The observer which was notified of this gesture's [handleStartBackGesture]
    /// is the same observer notified for this.
    ///
    /// Currently, this is only used on Android devices that support the
    /// predictive back feature.
    func handleCancelBackGesture()

    /// Called when the host tells the application to push a new
    /// [RouteInformation] and a restoration state onto the router.
    ///
    /// Observers are expected to return true if they were able to
    /// handle the notification. Observers are notified in registration
    /// order until one returns true.
    ///
    /// This method exposes the `pushRouteInformation` notification from
    /// [SystemChannels.navigation].
    ///
    /// The default implementation is to call the [didPushRoute] directly with the
    /// string constructed from [RouteInformation.uri]'s path and query parameters.
    // func didPushRouteInformation(routeInformation: RouteInformation) async -> Bool

    /// Called when the application's dimensions change. For example,
    /// when a phone is rotated.
    ///
    /// This method exposes notifications from
    /// [dart:ui.PlatformDispatcher.onMetricsChanged].
    ///
    /// {@tool snippet}
    ///
    /// This [StatefulWidget] implements the parts of the [State] and
    /// [WidgetsBindingObserver] protocols necessary to react when the device is
    /// rotated (or otherwise changes dimensions).
    ///
    /// ```dart
    /// class MetricsReactor extends StatefulWidget {
    ///   const MetricsReactor({ super.key });
    ///
    ///   @override
    ///   State<MetricsReactor> createState() => _MetricsReactorState();
    /// }
    ///
    /// class _MetricsReactorState extends State<MetricsReactor> with WidgetsBindingObserver {
    ///   late Size _lastSize;
    ///
    ///   @override
    ///   void initState() {
    ///     super.initState();
    ///     WidgetsBinding.instance.addObserver(this);
    ///   }
    ///
    ///   @override
    ///   void didChangeDependencies() {
    ///     super.didChangeDependencies();
    ///     // [View.of] exposes the view from `WidgetsBinding.instance.platformDispatcher.views`
    ///     // into which this widget is drawn.
    ///     _lastSize = View.of(context).physicalSize;
    ///   }
    ///
    ///   @override
    ///   void dispose() {
    ///     WidgetsBinding.instance.removeObserver(this);
    ///     super.dispose();
    ///   }
    ///
    ///   @override
    ///   void didChangeMetrics() {
    ///     setState(() { _lastSize = View.of(context).physicalSize; });
    ///   }
    ///
    ///   @override
    ///   Widget build(BuildContext context) {
    ///     return Text('Current size: $_lastSize');
    ///   }
    /// }
    /// ```
    /// {@end-tool}
    ///
    /// In general, this is unnecessary as the layout system takes care of
    /// automatically recomputing the application geometry when the application
    /// size changes.
    ///
    /// See also:
    ///
    ///  * [MediaQuery.sizeOf], which provides a similar service with less
    ///    boilerplate.
    func didChangeMetrics()

    /// Called when the platform's text scale factor changes.
    ///
    /// This typically happens as the result of the user changing system
    /// preferences, and it should affect all of the text sizes in the
    /// application.
    ///
    /// This method exposes notifications from
    /// [dart:ui.PlatformDispatcher.onTextScaleFactorChanged].
    ///
    /// {@tool snippet}
    ///
    /// ```dart
    /// class TextScaleFactorReactor extends StatefulWidget {
    ///   const TextScaleFactorReactor({ super.key });
    ///
    ///   @override
    ///   State<TextScaleFactorReactor> createState() => _TextScaleFactorReactorState();
    /// }
    ///
    /// class _TextScaleFactorReactorState extends State<TextScaleFactorReactor> with WidgetsBindingObserver {
    ///   @override
    ///   void initState() {
    ///     super.initState();
    ///     WidgetsBinding.instance.addObserver(this);
    ///   }
    ///
    ///   @override
    ///   void dispose() {
    ///     WidgetsBinding.instance.removeObserver(this);
    ///     super.dispose();
    ///   }
    ///
    ///   late double _lastTextScaleFactor;
    ///
    ///   @override
    ///   void didChangeTextScaleFactor() {
    ///     setState(() { _lastTextScaleFactor = WidgetsBinding.instance.platformDispatcher.textScaleFactor; });
    ///   }
    ///
    ///   @override
    ///   Widget build(BuildContext context) {
    ///     return Text('Current scale factor: $_lastTextScaleFactor');
    ///   }
    /// }
    /// ```
    /// {@end-tool}
    ///
    /// See also:
    ///
    ///  * [MediaQuery.textScaleFactorOf], which provides a similar service with less
    ///    boilerplate.
    func didChangeTextScaleFactor()

    /// Called when the platform brightness changes.
    ///
    /// This method exposes notifications from
    /// [dart:ui.PlatformDispatcher.onPlatformBrightnessChanged].
    ///
    /// See also:
    ///
    /// * [MediaQuery.platformBrightnessOf], which provides a similar service with
    ///   less boilerplate.
    func didChangePlatformBrightness()

    /// Called when the system tells the app that the user's locale has
    /// changed. For example, if the user changes the system language
    /// settings.
    ///
    /// This method exposes notifications from
    /// [dart:ui.PlatformDispatcher.onLocaleChanged].
    // func didChangeLocales(locales: [Locale]?)

    /// Called when the system puts the app in the background or returns
    /// the app to the foreground.
    ///
    /// An example of implementing this method is provided in the class-level
    /// documentation for the [WidgetsBindingObserver] class.
    ///
    /// This method exposes notifications from [SystemChannels.lifecycle].
    ///
    /// See also:
    ///
    ///  * [AppLifecycleListener], an alternative API for responding to
    ///    application lifecycle changes.
    func didChangeAppLifecycleState(state: AppLifecycleState)

    /// Called whenever the [PlatformDispatcher] receives a notification that the
    /// focus state on a view has changed.
    ///
    /// The [event] contains the view ID for the view that changed its focus
    /// state.
    ///
    /// The view ID of the [FlutterView] in which a particular [BuildContext]
    /// resides can be retrieved with `View.of(context).viewId`, so that it may be
    /// compared with the view ID in the `event` to see if the event pertains to
    /// the given context.
    // func didChangeViewFocus(event: ViewFocusEvent)

    /// Called when a request is received from the system to exit the application.
    ///
    /// If any observer responds with [AppExitResponse.cancel], it will cancel the
    /// exit. All observers will be asked before exiting.
    ///
    /// {@macro flutter.services.binding.ServicesBinding.requestAppExit}
    ///
    /// See also:
    ///
    /// * [ServicesBinding.exitApplication] for a function to call that will request
    ///   that the application exits.
    // func didRequestAppExit() async -> AppExitResponse

    /// Called when the system is running low on memory.
    ///
    /// This method exposes the `memoryPressure` notification from
    /// [SystemChannels.system].
    func didHaveMemoryPressure()

    /// Called when the system changes the set of currently active accessibility
    /// features.
    ///
    /// This method exposes notifications from
    /// [dart:ui.PlatformDispatcher.onAccessibilityFeaturesChanged].
    func didChangeAccessibilityFeatures()
}

// Default implementations
extension WidgetsBindingObserver {
    public func didPopRoute() async -> Bool {
        return false
    }

    // public func handleStartBackGesture(backEvent: PredictiveBackEvent) -> Bool {
    //     return false
    // }

    // public func handleUpdateBackGestureProgress(backEvent: PredictiveBackEvent) {}

    public func handleCommitBackGesture() {}

    public func handleCancelBackGesture() {}

    // public func didPushRouteInformation(routeInformation: RouteInformation) -> Future<Bool> {
    //     let uri = routeInformation.uri
    //     return didPushRoute(
    //         route: Uri.decodeComponent(
    //             Uri(
    //                 path: uri.path.isEmpty ? "/" : uri.path,
    //                 queryParameters: uri.queryParametersAll.isEmpty ? nil : uri.queryParametersAll,
    //                 fragment: uri.fragment.isEmpty ? nil : uri.fragment
    //             ).toString()
    //         )
    //     )
    // }

    // public func didPushRoute(route: String) async -> Bool {
    //     return false
    // }

    public func didChangeMetrics() {}

    public func didChangeTextScaleFactor() {}

    public func didChangePlatformBrightness() {}

    // public func didChangeLocales(locales: [Locale]?) {}

    public func didChangeAppLifecycleState(state: AppLifecycleState) {}

    // public func didChangeViewFocus(event: ViewFocusEvent) {}

    // public func didRequestAppExit() async -> AppExitResponse {
    //     return .exit
    // }

    public func didHaveMemoryPressure() {}

    public func didChangeAccessibilityFeatures() {}
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
///
/// An additional optional parameter `view` can be passed to specify the
/// `NativeView` to use for rendering the app. If not provided, a new
/// `NativeView` will be created.
public func runApp(_ app: Widget, view: NativeView? = nil) {
    runPlainApp(
        DefaultApp { app }
    )
}

public func runPlainApp(_ app: Widget, view: NativeView? = nil) {
    guard let view = view ?? backend.createView() else {
        fatalError("Failed to create view")
    }

    WidgetsBinding.shared.attachRootWidget(
        View(
            view: view,
            renderOwner: RendererBinding.shared.rootRenderOwner,
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
