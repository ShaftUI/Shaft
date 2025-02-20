// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

public class RendererBinding {
    public static let shared = RendererBinding()

    private init() {
        SchedulerBinding.shared.addPersistentFrameCallback(handlePersistentFrameCallback)
        GestureBinding.shared.onHitTest = hitTestInView
        GestureBinding.shared.beforeDispatchEventCallbacks.add(beforeDispatchEvent)
        backend.onMetricsChanged = handleMetricsChanged
        initMouseTracker()
    }

    public final lazy var rootRenderOwner = RenderOwner(
        onNeedVisualUpdate: SchedulerBinding.shared.ensureVisualUpdate
    )

    private func handlePersistentFrameCallback(timeStamp: Duration) {
        drawFrame()
        _scheduleMouseTrackerUpdate()
    }

    /// The object that manages state about currently connected mice, for hover
    /// notification.
    //   MouseTracker get mouseTracker => _mouseTracker!;
    public private(set) var mouseTracker: MouseTracker?

    /// Creates a MouseTracker which manages state about currently connected
    /// mice, for hover notification.
    ///
    /// Used by testing framework to reinitialize the mouse tracker between tests.
    package func initMouseTracker(_ tracker: MouseTracker? = nil) {
        mouseTracker =
            tracker
            ?? MouseTracker { [self] position, viewId in
                let result = HitTestResult()
                hitTestInView(result, position: position, viewId: viewId)
                return result
            }
    }

    private var _debugMouseTrackerUpdateScheduled = false

    private func _scheduleMouseTrackerUpdate() {
        assert(!_debugMouseTrackerUpdateScheduled)
        assert {
            _debugMouseTrackerUpdateScheduled = true
            return true
        }
        SchedulerBinding.shared.addPostFrameCallback { _ in
            assert(self._debugMouseTrackerUpdateScheduled)
            assert {
                self._debugMouseTrackerUpdateScheduled = false
                return true
            }
            self.mouseTracker?.updateAllDevices()
        }
    }

    private func beforeDispatchEvent(_ event: PointerEvent, hitTestResult: HitTestResult?) {
        mouseTracker!.updateWithEvent(
            event,
            // When the button is pressed, normal hit test uses a cached
            // result, but MouseTracker requires that the hit test is re-executed to
            // update the hovering events.
            hitTestResult: event is PointerMoveEvent ? nil : hitTestResult
        )
    }

    private var renderViewById: [Int: RenderView] = [:]

    public var renderViews: some Collection<RenderView> { renderViewById.values }

    public func addRenderView(_ view: RenderView) {
        renderViewById[view.nativeView.viewID] = view
    }

    var sendFramesToEngine: Bool { true }

    var beforeFrameCallbacks = CallbackList()
    var afterFrameCallbacks = CallbackList()

    func drawFrame() {
        beforeFrameCallbacks.call()
        defer { afterFrameCallbacks.call() }

        rootRenderOwner.flushLayout()
        rootRenderOwner.flushCompositingBits()
        rootRenderOwner.flushPaint()
        if sendFramesToEngine {
            for view in renderViews {
                view.compositeFrame()
            }
        }
    }

    func hitTestInView(_ result: HitTestResult, position: Offset, viewId: Int) {
        guard let view = renderViewById[viewId] else {
            return
        }
        view.hitTest(result, position: position)
    }

    func handleMetricsChanged(_ viewId: Int) {
        guard let renderView = renderViewById[viewId] else {
            return
        }
        renderView.handleMetricsChanged()
        if renderView.child != nil {
            // SchedulerBinding.shared.scheduleFrame()
            drawFrame()
        }
    }

    public func reassemble() {
        for view in renderViews {
            view.reassemble()
        }
        // scheduleWarmUpFrame()
        // await endOfFrame
    }
}
