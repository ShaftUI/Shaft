import Foundation
import Shaft
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
    func pumpWidget(_ widget: Widget) {
        WidgetsBinding.shared.attachRootWidget(
            View(
                view: implicitView,
                renderingOwner: RendererBinding.shared.rootRenderOwner,
                child: widget
            )
        )

        SchedulerBinding.shared.scheduleFrame()

        forceFrame()
    }

    /// Returns a sequence of all the elements in the widget tree.
    ///
    /// This property provides a way to iterate over all the elements in the
    /// widget tree, which can be useful for testing and debugging purposes. The
    /// sequence is generated from the root element of the widget tree.
    var allElements: ElementSequence {
        ElementSequence(WidgetsBinding.shared.rootElement!)
    }

    /// Finds the first widget of the given type in the widget tree.
    ///
    /// This method iterates through all the elements in the widget tree and
    /// returns the first widget that is an instance of the specified type `T`.
    func findWidget<T: Widget>(_ type: T.Type) -> T? {
        for element in allElements {
            if let widget = element.widget as? T {
                return widget
            }
        }
        return nil
    }

    /// Finds all widgets of the given type in the widget tree.
    ///
    /// This method iterates through all the elements in the widget tree and
    /// returns an array of all widgets that are instances of the specified type
    /// `T`.
    func findWidgets<T: Widget>(_ type: T.Type) -> [T] {
        var result: [T] = []
        for element in allElements {
            if let widget = element.widget as? T {
                result.append(widget)
            }
        }
        return result
    }

    /// Forces the rendering of a frame.
    func forceFrame() {
        backend.onBeginFrame?(.zero)
        backend.onDrawFrame?()
    }
}

/// A timer implementation that is used in the `TestBackend` class.
///
/// This timer is used to simulate the passage of time in a test environment.
/// It keeps track of when the timer should fire and provides a way to cancel
/// the timer. When the timer fires, it calls the provided callback function.
class TestTimer: Shaft.Timer {
    init(backend: TestBackend, fireTime: Duration, callback: @escaping () -> Void) {
        self.backend = backend
        self.fireTime = fireTime
        self.callback = callback
    }

    weak var backend: TestBackend?

    let fireTime: Duration

    let callback: () -> Void

    var isActive: Bool {
        return backend?.activeTimers.contains { $0 === self } ?? false
    }

    func cancel() {
        backend?.activeTimers.removeAll { $0 === self }
    }

    func fire() {
        callback()
        cancel()
    }
}

class TestBackend: Backend {

    func createCursor(_ cursor: Shaft.SystemMouseCursor) -> (any Shaft.NativeMouseCursor)? {
        return nil
    }

    internal init(
        wrap inner: Backend
    ) {
        self.inner = inner
    }

    /// The amount of fake time that's elapsed since this backend was created.
    private var elapsed = Duration.zero

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

    func createTimer(_ delay: Duration, _ f: @escaping () -> Void) -> any Shaft.Timer {
        let timer = TestTimer(backend: self, fireTime: elapsed + delay, callback: f)
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
}

func testWidgets(_ callback: @escaping (WidgetTester) -> Void) {
    let testBackend = TestBackend(wrap: SDLBackend.shared)
    backend = testBackend
    testBackend.inner.postTask {
        callback(WidgetTester())
        testBackend.onBeginFrame?(.zero)
        testBackend.onDrawFrame?()
        testBackend.stop()
    }
    testBackend.run()
}
