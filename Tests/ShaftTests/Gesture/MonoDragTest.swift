import Shaft
import XCTest

class MonoDragTest: XCTestCase {
    func test_acceptGesture_tolerates_a_null_lastPendingEventTimestamp() {
        testGesture { tester in
            // Regression test for https://github.com/flutter/flutter/issues/112403
            // and b/249091367
            let recognizer: DragGestureRecognizer = VerticalDragGestureRecognizer()
            let event = PointerDownEvent(timeStamp: .seconds(100000))

            XCTAssertNil(recognizer.debugLastPendingEventTimestamp)

            recognizer.addAllowedPointer(event: event)
            XCTAssertEqual(recognizer.debugLastPendingEventTimestamp, event.timeStamp)

            // Normal case: acceptGesture called and we have a last timestamp set.
            recognizer.acceptGesture(pointer: event.pointer)
            XCTAssertNil(recognizer.debugLastPendingEventTimestamp)

            // Reject the gesture to reset state and allow accepting it again.
            recognizer.rejectGesture(pointer: event.pointer)
            XCTAssertNil(recognizer.debugLastPendingEventTimestamp)

            // Not entirely clear how this can happen, but the bugs mentioned above show
            // we can end up in this state empirically.
            recognizer.acceptGesture(pointer: event.pointer)
            XCTAssertNil(recognizer.debugLastPendingEventTimestamp)
        }
    }
}

class DragGestureRecognizerTest: XCTestCase {
    func test_Should_recognize_pan() {
        testGesture { tester in
            let pan = PanGestureRecognizer()
            let tap = TapGestureRecognizer()
            tap.onTap = {}
            defer { pan.dispose() }
            defer { tap.dispose() }

            var didStartPan = false
            pan.onStart = { _ in
                didStartPan = true
            }

            var updatedScrollDelta: Offset?
            pan.onUpdate = { details in
                updatedScrollDelta = details.delta
            }

            var didEndPan = false
            pan.onEnd = { details in
                didEndPan = true
            }

            var didTap = false
            tap.onTap = {
                didTap = true
            }

            let pointer = TestPointer(pointer: 5)
            let down = pointer.down(Offset(10.0, 10.0))
            pan.addPointer(event: down)
            tap.addPointer(event: down)
            tester.closeArena(5)
            XCTAssertFalse(didStartPan)
            XCTAssertNil(updatedScrollDelta)
            XCTAssertFalse(didEndPan)
            XCTAssertFalse(didTap)

            tester.route(down)
            XCTAssertFalse(didStartPan)
            XCTAssertNil(updatedScrollDelta)
            XCTAssertFalse(didEndPan)
            XCTAssertFalse(didTap)

            // touch should give up when it hits kTouchSlop, which was 18.0 when this test was last updated.

            tester.route(pointer.move(Offset(20.0, 20.0)))  // moved 10 horizontally and 10 vertically which is 14 total
            XCTAssertFalse(didStartPan)  // 14 < 18
            tester.route(pointer.move(Offset(20.0, 30.0)))  // moved 10 horizontally and 20 vertically which is 22 total
            XCTAssertTrue(didStartPan)  // 22 > 18
            didStartPan = false
            XCTAssertFalse(didEndPan)
            XCTAssertFalse(didTap)

            tester.route(pointer.move(Offset(20.0, 25.0)))
            XCTAssertFalse(didStartPan)
            XCTAssertEqual(updatedScrollDelta, Offset(0.0, -5.0))
            updatedScrollDelta = nil
            XCTAssertFalse(didEndPan)
            XCTAssertFalse(didTap)

            tester.route(pointer.up())
            XCTAssertFalse(didStartPan)
            XCTAssertNil(updatedScrollDelta)
            XCTAssertTrue(didEndPan)
            didEndPan = false
            XCTAssertFalse(didTap)
        }
    }

    func test_Should_report_most_recent_point_to_onStart_by_default() {
        testGesture { tester in
            let drag = HorizontalDragGestureRecognizer()
            let competingDrag = VerticalDragGestureRecognizer()
            competingDrag.onStart = { _ in }
            defer { drag.dispose() }
            defer { competingDrag.dispose() }

            var positionAtOnStart: Offset!
            drag.onStart = { details in
                positionAtOnStart = details.globalPosition
            }

            let pointer = TestPointer(pointer: 5)
            let down = pointer.down(Offset(10.0, 10.0))
            drag.addPointer(event: down)
            competingDrag.addPointer(event: down)
            tester.closeArena(5)
            tester.route(down)

            tester.route(pointer.move(Offset(30.0, 0.0)))
            XCTAssertEqual(positionAtOnStart, Offset(30.0, 0.0))
        }
    }

    func test_Should_report_most_recent_point_to_onStart_with_a_start_configuration() {
        testGesture { tester in
            let drag = HorizontalDragGestureRecognizer()
            let competingDrag = VerticalDragGestureRecognizer()
            competingDrag.onStart = { _ in }
            defer { drag.dispose() }
            defer { competingDrag.dispose() }

            var positionAtOnStart: Offset!
            drag.onStart = { details in
                positionAtOnStart = details.globalPosition
            }
            var updateOffset: Offset?
            drag.onUpdate = { details in
                updateOffset = details.globalPosition
            }

            let pointer = TestPointer(pointer: 5)
            let down = pointer.down(Offset(10.0, 10.0))
            drag.addPointer(event: down)
            competingDrag.addPointer(event: down)
            tester.closeArena(5)
            tester.route(down)

            tester.route(pointer.move(Offset(30.0, 0.0)))

            XCTAssertEqual(positionAtOnStart, Offset(30.0, 0.0))
            XCTAssertNil(updateOffset)
        }
    }

    func test_Should_recognize_drag() {
        testGesture { tester in
            let drag = HorizontalDragGestureRecognizer()
            drag.dragStartBehavior = .down
            defer { drag.dispose() }

            var didStartDrag = false
            drag.onStart = { _ in
                didStartDrag = true
            }

            var updatedDelta: Float?
            drag.onUpdate = { details in
                updatedDelta = details.primaryDelta
            }

            var didEndDrag = false
            drag.onEnd = { details in
                didEndDrag = true
            }

            let pointer = TestPointer(pointer: 5)
            let down = pointer.down(Offset(10.0, 10.0))
            drag.addPointer(event: down)
            tester.closeArena(5)
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)

            tester.route(down)
            XCTAssertTrue(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)

            tester.route(pointer.move(Offset(20.0, 25.0)))
            XCTAssertTrue(didStartDrag)
            didStartDrag = false
            XCTAssertEqual(updatedDelta, 10.0)
            updatedDelta = nil
            XCTAssertFalse(didEndDrag)

            tester.route(pointer.move(Offset(20.0, 25.0)))
            XCTAssertFalse(didStartDrag)
            XCTAssertEqual(updatedDelta, 0.0)
            updatedDelta = nil
            XCTAssertFalse(didEndDrag)

            tester.route(pointer.up())
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertTrue(didEndDrag)
            didEndDrag = false
        }
    }

    func test_Should_reject_mouse_drag_when_configured_to_ignore_mouse_pointers_Horizontal() {
        testGesture { tester in
            let drag = HorizontalDragGestureRecognizer(supportedDevices: [.touch])
            drag.dragStartBehavior = .down
            defer { drag.dispose() }

            var didStartDrag = false
            drag.onStart = { _ in
                didStartDrag = true
            }

            var updatedDelta: Float?
            drag.onUpdate = { details in
                updatedDelta = details.primaryDelta
            }

            var didEndDrag = false
            drag.onEnd = { details in
                didEndDrag = true
            }

            let pointer = TestPointer(pointer: 5, kind: .mouse)
            let down = pointer.down(Offset(10.0, 10.0))
            drag.addPointer(event: down)
            tester.closeArena(5)
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)

            tester.route(down)
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)

            tester.route(pointer.move(Offset(20.0, 25.0)))
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)

            tester.route(pointer.move(Offset(20.0, 25.0)))
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)

            tester.route(pointer.up())
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)
        }
    }

    func test_Should_reject_mouse_drag_when_configured_to_ignore_mouse_pointers_Vertical() {
        testGesture { tester in
            let drag = VerticalDragGestureRecognizer(supportedDevices: [.touch])
            drag.dragStartBehavior = .down
            defer { drag.dispose() }

            var didStartDrag = false
            drag.onStart = { _ in
                didStartDrag = true
            }

            var updatedDelta: Float?
            drag.onUpdate = { details in
                updatedDelta = details.primaryDelta
            }

            var didEndDrag = false
            drag.onEnd = { details in
                didEndDrag = true
            }

            let pointer = TestPointer(pointer: 5, kind: .mouse)
            let down = pointer.down(Offset(10.0, 10.0))
            drag.addPointer(event: down)
            tester.closeArena(5)
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)

            tester.route(down)
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)

            tester.route(pointer.move(Offset(25.0, 20.0)))
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)

            tester.route(pointer.move(Offset(25.0, 20.0)))
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)

            tester.route(pointer.up())
            XCTAssertFalse(didStartDrag)
            XCTAssertNil(updatedDelta)
            XCTAssertFalse(didEndDrag)
        }
    }

    func test_DragGestureRecognizer_onStart_behavior() {
        testGesture { tester in
            let drag = HorizontalDragGestureRecognizer()
            drag.dragStartBehavior = .down
            defer { drag.dispose() }

            var startTimestamp: Duration?
            var positionAtOnStart: Offset?
            drag.onStart = { details in
                startTimestamp = details.sourceTimeStamp
                positionAtOnStart = details.globalPosition
            }

            var updatedTimestamp: Duration?
            var updateDelta: Offset?
            drag.onUpdate = { details in
                updatedTimestamp = details.sourceTimeStamp
                updateDelta = details.delta
            }

            // No competing, dragStartBehavior == DragStartBehavior.down
            let pointer = TestPointer(pointer: 5)
            var down = pointer.down(Offset(10.0, 10.0), timeStamp: Duration.milliseconds(100))
            drag.addPointer(event: down)
            tester.closeArena(5)
            XCTAssertNil(startTimestamp)
            XCTAssertNil(positionAtOnStart)
            XCTAssertNil(updatedTimestamp)

            tester.route(down)
            // The only horizontal drag gesture win the arena when the pointer down.
            XCTAssertEqual(startTimestamp, Duration.milliseconds(100))
            XCTAssertEqual(positionAtOnStart, Offset(10.0, 10.0))
            XCTAssertNil(updatedTimestamp)

            tester.route(pointer.move(Offset(20.0, 25.0), timeStamp: Duration.milliseconds(200)))
            XCTAssertEqual(updatedTimestamp, Duration.milliseconds(200))
            XCTAssertEqual(updateDelta, Offset(10.0, 0.0))

            tester.route(pointer.move(Offset(20.0, 25.0), timeStamp: Duration.milliseconds(300)))
            XCTAssertEqual(updatedTimestamp, Duration.milliseconds(300))
            XCTAssertEqual(updateDelta, Offset.zero)
            tester.route(pointer.up())

            // No competing, dragStartBehavior == DragStartBehavior.start
            // When there are no other gestures competing with this gesture in the arena,
            // there's no difference in behavior between the two settings.
            drag.dragStartBehavior = .start
            startTimestamp = nil
            positionAtOnStart = nil
            updatedTimestamp = nil
            updateDelta = nil

            down = pointer.down(Offset(10.0, 10.0), timeStamp: Duration.milliseconds(400))
            drag.addPointer(event: down)
            tester.closeArena(5)
            tester.route(down)

            XCTAssertEqual(startTimestamp, Duration.milliseconds(400))
            XCTAssertEqual(positionAtOnStart, Offset(10.0, 10.0))
            XCTAssertNil(updatedTimestamp)

            tester.route(pointer.move(Offset(20.0, 25.0), timeStamp: Duration.milliseconds(500)))
            XCTAssertEqual(updatedTimestamp, Duration.milliseconds(500))
            tester.route(pointer.up())

            // With competing, dragStartBehavior == DragStartBehavior.start
            startTimestamp = nil
            positionAtOnStart = nil
            updatedTimestamp = nil
            updateDelta = nil

            let competingDrag = VerticalDragGestureRecognizer()
            competingDrag.onStart = { _ in }
            defer { competingDrag.dispose() }

            down = pointer.down(Offset(10.0, 10.0), timeStamp: Duration.milliseconds(600))
            drag.addPointer(event: down)
            competingDrag.addPointer(event: down)
            tester.closeArena(5)
            tester.route(down)

            // The pointer down event do not trigger anything.
            XCTAssertNil(startTimestamp)
            XCTAssertNil(positionAtOnStart)
            XCTAssertNil(updatedTimestamp)

            tester.route(pointer.move(Offset(30.0, 10.0), timeStamp: Duration.milliseconds(700)))
            XCTAssertEqual(startTimestamp, Duration.milliseconds(700))
            // Using the position of the pointer at the time this gesture recognizer won the arena.
            XCTAssertEqual(positionAtOnStart, Offset(30.0, 10.0))
            XCTAssertNil(updatedTimestamp)  // Do not trigger an update event.
            tester.route(pointer.up())

            // With competing, dragStartBehavior == DragStartBehavior.down
            drag.dragStartBehavior = .down
            startTimestamp = nil
            positionAtOnStart = nil
            updatedTimestamp = nil
            updateDelta = nil

            down = pointer.down(Offset(10.0, 10.0), timeStamp: Duration.milliseconds(800))
            drag.addPointer(event: down)
            competingDrag.addPointer(event: down)
            tester.closeArena(5)
            tester.route(down)

            XCTAssertNil(startTimestamp)
            XCTAssertNil(positionAtOnStart)
            XCTAssertNil(updatedTimestamp)

            tester.route(pointer.move(Offset(30.0, 10.0), timeStamp: Duration.milliseconds(900)))
            XCTAssertEqual(startTimestamp, Duration.milliseconds(900))
            // Using the position of the first detected down event for the pointer.
            XCTAssertEqual(positionAtOnStart, Offset(10.0, 10.0))
            XCTAssertEqual(updatedTimestamp, Duration.milliseconds(900))  // Also, trigger an update event.
            XCTAssertEqual(updateDelta, Offset(20.0, 0.0))
            tester.route(pointer.up())
        }
    }
}
