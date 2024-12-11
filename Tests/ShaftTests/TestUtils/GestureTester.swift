import Shaft

// class GestureTester {
//   GestureTester._(this.async);

//   final FakeAsync async;

//   void closeArena(int pointer) {
//     GestureBinding.instance.gestureArena.close(pointer);
//   }

//   void route(PointerEvent event) {
//     GestureBinding.instance.pointerRouter.route(event);
//     async.flushMicrotasks();
//   }
// }

final class GestureTester {
    /// A convenience method for accessing the `TestBackend` instance
    var backend: TestBackend {
        return Shaft.backend as! TestBackend
    }

    func closeArena(_ pointer: Int) {
        GestureBinding.shared.gestureArena.close(pointer)
    }

    func sweepArena(_ pointer: Int) {
        GestureBinding.shared.gestureArena.sweep(pointer)
    }

    func route(_ event: PointerEvent) {
        GestureBinding.shared.pointerRouter.route(event)
        backend.flushMicrotasks()
    }
}

typealias GestureTest = (GestureTester) -> Void

func testGesture(_ callback: @escaping GestureTest) {
    testWidgets { WidgetTester in
        callback(GestureTester())
    }
}
