import Foundation
import Shaft
import ShaftSetup
import SwiftMath

struct ElementSequence: Sequence {
    init(_ root: Element) {
        self.root = root
    }

    let root: Element

    struct Iterator: IteratorProtocol {
        init(_ root: Element) {
            self.root = root
            self.stack = [root]
        }

        let root: Element

        var stack: [Element]

        mutating func next() -> Element? {
            guard let current = stack.popLast() else {
                return nil
            }

            current.visitChildren {
                stack.append($0)
            }

            return current
        }
    }

    func makeIterator() -> Self.Iterator {
        Iterator(root)
    }
}

class WidgetTester {
    /// A convenience method for accessing the `TestBackend` instance
    var backend: TestBackend {
        return Shaft.backend as! TestBackend
    }

    /// A lazily-initialized `NativeView` that is used as the implicit view for
    /// the `WidgetTester`.
    lazy var implicitView: NativeView = {
        guard let view = backend.createView() else {
            fatalError("Failed to create view")
        }
        return view
    }()

    /// Attaches the provided `Widget` to the root of the widget tree, and
    /// schedules a frame to be rendered.
    public func pumpWidget(_ widget: Widget) {
        WidgetsBinding.shared.attachRootWidget(
            View(
                view: implicitView,
                renderOwner: RendererBinding.shared.rootRenderOwner,
                child: widget
            )
        )

        SchedulerBinding.shared.scheduleFrame()

        forceFrame()
    }

    /// Forces the rendering of a frame.
    public func forceFrame() {
        backend.onBeginFrame?(.zero)
        backend.onDrawFrame?()
    }

    // public func pumpAndSettle() {
    //     forceFrame()
    //     while backend.activeTimers.count > 0 {
    //         backend.elapse(.zero)
    //     }
    // }

    // MARK:- FINDERS

    /// Returns a sequence of all the elements in the widget tree.
    ///
    /// This property provides a way to iterate over all the elements in the
    /// widget tree, which can be useful for testing and debugging purposes. The
    /// sequence is generated from the root element of the widget tree.
    public var allElements: ElementSequence {
        ElementSequence(WidgetsBinding.shared.rootElement!)
    }

    /// Finds the first widget of the given type in the widget tree.
    ///
    /// This method iterates through all the elements in the widget tree and
    /// returns the first widget that is an instance of the specified type `T`.
    public func findWidget<T: Widget>(_ type: T.Type) -> T? {
        for element in allElements {
            if let widget = element.widget as? T {
                return widget
            }
        }
        return nil
    }

    /// Finds the first State object of the given type in the widget tree.
    ///
    /// This method iterates through all the elements in the widget tree and
    /// returns the first State object associated with a StatefulWidget that is
    /// an instance of the specified type `T`.
    public func findState<T: StatefulWidget>(_ type: T.Type) -> T.StateType? {
        for element in allElements {
            if let statefulElement = element as? StatefulElement<T> {
                return statefulElement.state as? T.StateType
            }
        }
        return nil
    }

    /// Finds all widgets of the given type in the widget tree.
    ///
    /// This method iterates through all the elements in the widget tree and
    /// returns an array of all widgets that are instances of the specified type
    /// `T`.
    public func findWidgets<T: Widget>(_ type: T.Type) -> [T] {
        var result: [T] = []
        for element in allElements {
            if let widget = element.widget as? T {
                result.append(widget)
            }
        }
        return result
    }

    /// Returns the first element that matches the given finder. If no matching
    /// element is found, this method will throw an error.
    public func match(_ finder: Finder) -> Element {
        for element in allElements {
            if finder.matches(candidate: element) {
                return element
            }
        }
        fatalError("The finder \"\(finder)\" could not find any matching widgets.")
    }

    /// Returns all elements that match the given finder.
    public func matchAll(_ finder: Finder) -> [Element] {
        var result: [Element] = []
        for element in allElements {
            if finder.matches(candidate: element) {
                result.append(element)
            }
        }
        return result
    }

    // MARK:- GEOMETRY

    private func getElementPoint(
        finder: Finder,
        sizeToPoint: (Shaft.Size) -> Offset
    ) -> Offset {
        let element = match(finder)
        let renderObject = element.renderObject
        if renderObject == nil {
            fatalError(
                "The finder \"\(finder)\" found an element, but it does not have a corresponding render object. Maybe the element has not yet been rendered?"
            )
        }
        if !(renderObject is RenderBox) {
            fatalError(
                "The finder \"\(finder)\" found an element whose corresponding render object is not a RenderBox (it is a \(type(of: renderObject))"
            )
        }
        let box = element.renderObject as! RenderBox
        let location = box.localToGlobal(sizeToPoint(box.size))
        return location
    }

    /// Returns the point at the center of the given widget.
    ///
    /// {@template flutter.flutter_test.WidgetController.getCenter.warnIfMissed}
    /// If `warnIfMissed` is true (the default is false), then the returned
    /// coordinate is checked to see if a hit test at the returned location would
    /// actually include the specified element in the [HitTestResult], and if not,
    /// a warning is printed to the console.
    ///
    /// The `callee` argument is used to identify the method that should be
    /// referenced in messages regarding `warnIfMissed`. It can be ignored unless
    /// this method is being called from another that is forwarding its own
    /// `warnIfMissed` parameter (see e.g. the implementation of [tap]).
    /// {@endtemplate}
    public func getCenter(_ finder: Finder) -> Offset {
        return getElementPoint(finder: finder) { size in
            size.center(origin: Offset.zero)
        }
    }

    /// Returns the point at the top left of the given widget.
    public func getTopLeft(_ finder: Finder) -> Offset {
        return getElementPoint(finder: finder) { _ in
            Offset.zero
        }
    }

    /// Returns the point at the top right of the given widget. This
    /// point is not inside the object's hit test area.
    public func getTopRight(_ finder: Finder) -> Offset {
        return getElementPoint(finder: finder) { size in
            size.topRight(origin: Offset.zero)
        }
    }

    /// Returns the point at the bottom left of the given widget. This
    /// point is not inside the object's hit test area.
    public func getBottomLeft(_ finder: Finder) -> Offset {
        return getElementPoint(finder: finder) { size in
            size.bottomLeft(origin: Offset.zero)
        }
    }

    /// Returns the point at the bottom right of the given widget. This
    /// point is not inside the object's hit test area.
    public func getBottomRight(_ finder: Finder) -> Offset {
        return getElementPoint(finder: finder) { size in
            size.bottomRight(origin: Offset.zero)
        }
    }

    /// Returns the rect of the given widget. This is only valid once
    /// the widget's render object has been laid out at least once.
    public func getRect(_ finder: Finder) -> Shaft.Rect {
        let topLeft = getTopLeft(finder)
        let bottomRight = getBottomRight(finder)
        return .fromPoints(topLeft, bottomRight)
    }

    /// Returns the size of the given widget. This is only valid once
    /// the widget's render object has been laid out at least once.
    public func getSize(_ finder: Finder) -> Shaft.Size {
        let element = match(finder)
        let box = element.renderObject as! RenderBox
        return box.size
    }
}

public protocol Finder {
    func matches(candidate: Element) -> Bool
}

public class _MatchTextFinder: Finder {
    public init(findRichText: Bool = false) {
        self.findRichText = findRichText
    }

    /// Whether standalone [RichText] widgets should be found or not.
    ///
    /// Defaults to `false`.
    ///
    /// If disabled, only [Text] widgets will be matched. [RichText] widgets
    /// *without* a [Text] ancestor will be ignored.
    /// If enabled, only [RichText] widgets will be matched. This *implicitly*
    /// matches [Text] widgets as well since they always insert a [RichText]
    /// child.
    ///
    /// In either case, [EditableText] widgets will also be matched.
    let findRichText: Bool

    func matchesText(_ textToMatch: String) -> Bool {
        fatalError("Must be implemented by subclass")
    }

    public func matches(candidate: Element) -> Bool {
        let widget = candidate.widget!
        if widget is EditableText {
            return _matchesEditableText(widget as! EditableText)
        }

        if !findRichText {
            return _matchesNonRichText(widget)
        }
        // It would be sufficient to always use _matchesRichText if we wanted to
        // match both standalone RichText widgets as well as Text widgets. However,
        // the find.text() finder used to always ignore standalone RichText widgets,
        // which is why we need the _matchesNonRichText method in order to not be
        // backwards-compatible and not break existing tests.
        return _matchesRichText(widget)
    }

    func _matchesRichText(_ widget: Widget) -> Bool {
        if let richText = widget as? RichText {
            return matchesText(richText.text.toPlainText())
        }
        return false
    }

    func _matchesNonRichText(_ widget: Widget) -> Bool {
        if let text = widget as? Text {
            if let data = text.data {
                return matchesText(data)
            }
            assert(text.textSpan != nil)
            return matchesText(text.textSpan!.toPlainText())
        }
        return false
    }

    func _matchesEditableText(_ widget: EditableText) -> Bool {
        return matchesText(widget.controller.text)
    }
}

public class _TextWidgetFinder: _MatchTextFinder {
    init(text: String, findRichText: Bool = false) {
        self.text = text
        super.init(findRichText: findRichText)
    }

    let text: String

    var description: String {
        return "text \"\(text)\""
    }

    override func matchesText(_ textToMatch: String) -> Bool {
        return textToMatch == text
    }
}

extension Finder where Self == _TextWidgetFinder {
    static func text(_ text: String, findRichText: Bool = false) -> _TextWidgetFinder {
        return _TextWidgetFinder(text: text, findRichText: findRichText)
    }
}

/// A timer implementation that is used in the `TestBackend` class.
///
/// This timer is used to simulate the passage of time in a test environment.
/// It keeps track of when the timer should fire and provides a way to cancel
/// the timer. When the timer fires, it calls the provided callback function.
class TestTimer: Shaft.Timer {
    init(
        backend: TestBackend,
        fireTime: Duration,
        shouldRepeat: Bool,
        delay: Duration,
        callback: @escaping () -> Void
    ) {
        self.backend = backend
        self.fireTime = fireTime
        self.shouldRepeat = shouldRepeat
        self.delay = delay
        self.callback = callback
    }

    weak var backend: TestBackend?

    var fireTime: Duration
    let shouldRepeat: Bool
    let delay: Duration

    let callback: () -> Void

    var isActive: Bool {
        return backend?.activeTimers.contains { $0 === self } ?? false
    }

    func cancel() {
        backend?.activeTimers.removeAll { $0 === self }
    }

    func fire() {
        callback()
        if shouldRepeat {
            // Reschedule the timer for the next interval
            fireTime = (backend?.elapsed ?? .zero) + delay
        } else {
            cancel()
        }
    }
}

class TestBackend: Backend {
    func destroyView(_ view: any Shaft.NativeView) {

    }

    var lifecycleState: AppLifecycleState { .resumed }

    var onAppLifecycleStateChanged: AppLifecycleStateCallback?

    func createCursor(_ cursor: Shaft.SystemMouseCursor) -> (any Shaft.NativeMouseCursor)? {
        return nil
    }

    internal init(
        wrap inner: Backend
    ) {
        self.inner = inner
    }

    /// The amount of fake time that's elapsed since this backend was created.
    fileprivate var elapsed = Duration.zero

    /// This list keeps track of all the timers that have been created and are
    /// currently active. When the `elapse` function is called, it iterates
    /// through this list to find and fire any timers that have reached their
    /// scheduled fire time.
    var activeTimers: [TestTimer] = []

    /// The fake time at which the current call to [elapse] will finish running.
    ///
    /// This is `null` if there's no current call to [elapse].
    var elapsingTo: Duration?

    /// Simulates the asynchronous passage of time.
    func elapse(_ duration: Duration) {
        if duration < .zero {
            assertionFailure("duration must be positive")
        } else if elapsingTo != nil {
            assertionFailure("Cannot elapse until previous elapse is complete.")
        }

        elapsingTo = elapsed + duration
        fireTimersWhile { next in next.fireTime <= elapsingTo! }
        elapseTo(elapsingTo!)
        elapsingTo = nil
    }

    /// Advances the elapsed time to the specified duration.
    private func elapseTo(_ to: Duration) {
        assert(elapsed <= to)
        elapsed = to
    }

    /// Invoke the callback for each timer until [predicate] returns `false` for
    /// the next timer that would be fired.
    ///
    /// Microtasks are flushed before and after each timer is fired. Before each
    /// timer fires, [_elapsed] is updated to the appropriate duration.
    func fireTimersWhile(predicate: (TestTimer) -> Bool) {
        flushMicrotasks()
        while true {
            if activeTimers.isEmpty { break }

            let nextTimer = activeTimers.min { $0.fireTime < $1.fireTime }!
            if !predicate(nextTimer) { break }

            elapseTo(nextTimer.fireTime)
            nextTimer.fire()
            flushMicrotasks()
        }
    }

    func createTimer(_ delay: Duration, repeat: Bool, callback: @escaping () -> Void) -> any Shaft
        .Timer
    {
        let timer = TestTimer(
            backend: self,
            fireTime: elapsed + delay,
            shouldRepeat: `repeat`,
            delay: delay,
            callback: callback
        )
        activeTimers.append(timer)
        return timer
    }

    func startTextInput() {
    }

    func stopTextInput() {
    }

    func getKeyboardState() -> [Shaft.PhysicalKeyboardKey: Shaft.LogicalKeyboardKey]? {
        return [:]
    }

    func setComposingRect(_ rect: Shaft.Rect) {
    }

    func setEditableSizeAndTransform(_ size: Shaft.Size, _ transform: SwiftMath.Matrix4x4f) {
    }

    var textInputActive: Bool { false }

    var onTextEditing: TextEditingCallback?

    var onTextComposed: TextComposedCallback?

    var onKeyEvent: KeyEventCallback?

    var targetPlatform: TargetPlatform? {
        .macOS
    }

    fileprivate let inner: Backend

    func createView() -> NativeView? {
        inner.createView()
    }

    func view(_ viewId: Int) -> NativeView? {
        inner.view(viewId)
    }

    var onPointerData: PointerDataCallback?

    var onMetricsChanged: MetricsChangedCallback?

    var onBeginFrame: FrameCallback?

    var onDrawFrame: VoidCallback?

    func scheduleFrame() {
        inner.scheduleFrame()
    }

    func run() {
        inner.run()
    }

    func stop() {
        inner.stop()
    }

    var isMainThread: Bool {
        inner.isMainThread
    }

    private var pendingTasks: [() -> Void] = []

    func postTask(_ f: @escaping () -> Void) {
        pendingTasks.append(f)
    }

    func flushMicrotasks() {
        for task in pendingTasks {
            task()
        }
        pendingTasks.removeAll()
    }

    var renderer: Renderer {
        inner.renderer
    }

    var locales: [Shaft.Locale] = []

    func launchUrl(_ url: String) -> Bool {
        return false
    }
}

func testWidgets(_ callback: @escaping (WidgetTester) -> Void) {
    if !backendInitialized {
        backend = TestBackend(wrap: ShaftSetup.createDefaultBackend())
    }

    let testBackend = backend as! TestBackend

    testBackend.inner.postTask {
        callback(WidgetTester())
        testBackend.onBeginFrame?(.zero)
        testBackend.onDrawFrame?()
        testBackend.stop()
    }
    testBackend.run()
}
