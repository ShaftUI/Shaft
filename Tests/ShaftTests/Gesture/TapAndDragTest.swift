import Shaft
import XCTest

// Anything longer than [kDoubleTapTimeout] will reset the consecutive tap count.
let kConsecutiveTapDelay = kDoubleTapTimeout / 2

class TapAndDragTest: XCTestCase {
    var events: [String]!
    var tapAndDrag: BaseTapAndDragGestureRecognizer!

    func setUpTapAndPanGestureRecognizer(eagerVictoryOnDrag: Bool = true) {
        tapAndDrag = TapAndPanGestureRecognizer()
        tapAndDrag.dragStartBehavior = .down
        tapAndDrag.eagerVictoryOnDrag = eagerVictoryOnDrag
        tapAndDrag.maxConsecutiveTap = 3
        tapAndDrag.onTapDown = { (details: TapDragDownDetails) in
            self.events.append("down#\(details.consecutiveTapCount)")
        }
        tapAndDrag.onTapUp = { [self] (details: TapDragUpDetails) in
            events.append("up#\(details.consecutiveTapCount)")
        }
        tapAndDrag.onDragStart = { (details: TapDragStartDetails) in
            self.events.append("panstart#\(details.consecutiveTapCount)")
        }
        tapAndDrag.onDragUpdate = { [self] (details: TapDragUpdateDetails) in
            events.append("panupdate#\(details.consecutiveTapCount)")
        }
        tapAndDrag.onDragEnd = { [self] (details: TapDragEndDetails) in
            events.append("panend#\(details.consecutiveTapCount)")
        }
        tapAndDrag.onCancel = { [self] in
            events.append("cancel")
        }
        addTeardownBlock(tapAndDrag.dispose)
    }

    // Down/up pair 1: normal tap sequence
    let down1 = PointerDownEvent(
        pointer: 1,
        position: Offset(10.0, 10.0)
    )

    let up1 = PointerUpEvent(
        pointer: 1,
        position: Offset(11.0, 9.0)
    )

    let cancel1 = PointerCancelEvent(
        pointer: 1
    )

    // Down/up pair 2: normal tap sequence close to pair 1
    let down2 = PointerDownEvent(
        pointer: 2,
        position: Offset(12.0, 12.0)
    )

    let up2 = PointerUpEvent(
        pointer: 2,
        position: Offset(13.0, 11.0)
    )

    // Down/up pair 3: normal tap sequence close to pair 1
    let down3 = PointerDownEvent(
        pointer: 3,
        position: Offset(12.0, 12.0)
    )

    let up3 = PointerUpEvent(
        pointer: 3,
        position: Offset(13.0, 11.0)
    )

    // Down/up pair 4: normal tap sequence far away from pair 1
    let down4 = PointerDownEvent(
        pointer: 4,
        position: Offset(130.0, 130.0)
    )

    let up4 = PointerUpEvent(
        pointer: 4,
        position: Offset(131.0, 129.0)
    )

    // Down/move/up sequence 5: intervening motion
    let down5 = PointerDownEvent(
        pointer: 5,
        position: Offset(10.0, 10.0)
    )

    let move5 = PointerMoveEvent(
        pointer: 5,
        position: Offset(25.0, 25.0)
    )

    let up5 = PointerUpEvent(
        pointer: 5,
        position: Offset(25.0, 25.0)
    )

    // Mouse Down/move/up sequence 6: intervening motion - kPrecisePointerPanSlop
    let down6 = PointerDownEvent(
        pointer: 6,
        kind: .mouse,
        position: Offset(10.0, 10.0)
    )

    let move6 = PointerMoveEvent(
        pointer: 6,
        kind: .mouse,
        position: Offset(15.0, 15.0),
        delta: Offset(5.0, 5.0)
    )

    let up6 = PointerUpEvent(
        pointer: 6,
        kind: .mouse,
        position: Offset(15.0, 15.0)
    )

    override func setUp() {
        events = []
    }

    func test_Recognizes_consecutive_taps() {
        testGesture { [self] tester in
            setUpTapAndPanGestureRecognizer()

            tapAndDrag.addPointer(event: down1)
            tester.closeArena(1)
            tester.route(down1)
            tester.route(up1)
            GestureBinding.shared.gestureArena.sweep(1)
            XCTAssertEqual(events, ["down#1", "up#1"])

            events.removeAll()
            tester.backend.elapse(kConsecutiveTapDelay)
            tapAndDrag.addPointer(event: down2)
            tester.closeArena(2)
            tester.route(down2)
            tester.route(up2)
            GestureBinding.shared.gestureArena.sweep(2)
            XCTAssertEqual(events, ["down#2", "up#2"])

            events.removeAll()
            tester.backend.elapse(kConsecutiveTapDelay)
            tapAndDrag.addPointer(event: down3)
            tester.closeArena(3)
            tester.route(down3)
            tester.route(up3)
            GestureBinding.shared.gestureArena.sweep(3)
            XCTAssertEqual(events, ["down#3", "up#3"])
        }
    }

    func test_Resets_if_times_out_in_between_taps() {
        testGesture { [self] tester in
            setUpTapAndPanGestureRecognizer()

            tapAndDrag.addPointer(event: down1)
            tester.closeArena(1)
            tester.route(down1)
            tester.route(up1)
            GestureBinding.shared.gestureArena.sweep(1)
            XCTAssertEqual(events, ["down#1", "up#1"])

            events.removeAll()
            tester.backend.elapse(.milliseconds(1000))
            tapAndDrag.addPointer(event: down2)
            tester.closeArena(2)
            tester.route(down2)
            tester.route(up2)
            GestureBinding.shared.gestureArena.sweep(2)
            XCTAssertEqual(events, ["down#1", "up#1"])
        }
    }

    func test_Resets_if_taps_are_far_apart() {
        testGesture { [self] tester in
            setUpTapAndPanGestureRecognizer()

            tapAndDrag.addPointer(event: down1)
            tester.closeArena(1)
            tester.route(down1)
            tester.route(up1)
            GestureBinding.shared.gestureArena.sweep(1)
            XCTAssertEqual(events, ["down#1", "up#1"])

            events.removeAll()
            tester.backend.elapse(Duration.milliseconds(100))
            tapAndDrag.addPointer(event: down4)
            tester.closeArena(4)
            tester.route(down4)
            tester.route(up4)
            GestureBinding.shared.gestureArena.sweep(4)
            XCTAssertEqual(events, ["down#1", "up#1"])
        }
    }

    func test_Resets_if_consecutiveTapCount_reaches_maxConsecutiveTap() {
        testGesture { [self] tester in
            setUpTapAndPanGestureRecognizer()

            // First tap
            tapAndDrag.addPointer(event: down1)
            tester.closeArena(1)
            tester.route(down1)
            tester.route(up1)
            GestureBinding.shared.gestureArena.sweep(1)
            XCTAssertEqual(events, ["down#1", "up#1"])

            // Second tap
            events.removeAll()
            tapAndDrag.addPointer(event: down2)
            tester.closeArena(2)
            tester.route(down2)
            tester.route(up2)
            GestureBinding.shared.gestureArena.sweep(2)
            XCTAssertEqual(events, ["down#2", "up#2"])

            // Third tap
            events.removeAll()
            tapAndDrag.addPointer(event: down3)
            tester.closeArena(3)
            tester.route(down3)
            tester.route(up3)
            GestureBinding.shared.gestureArena.sweep(3)
            XCTAssertEqual(events, ["down#3", "up#3"])

            // Fourth tap. Here we arrived at the `maxConsecutiveTap` for `consecutiveTapCount`
            // so our count should reset and our new count should be `1`.
            events.removeAll()
            tapAndDrag.addPointer(event: down3)
            tester.closeArena(3)
            tester.route(down3)
            tester.route(up3)
            GestureBinding.shared.gestureArena.sweep(3)
            XCTAssertEqual(events, ["down#1", "up#1"])
        }
    }

    func test_Should_recognize_drag() {
        testGesture { [self] tester in
            setUpTapAndPanGestureRecognizer()

            let pointer = TestPointer(pointer: 5)
            let down = pointer.down(Offset(10.0, 10.0))
            tapAndDrag.addPointer(event: down)
            tester.closeArena(5)
            tester.route(down)
            tester.route(pointer.move(Offset(40.0, 45.0)))
            tester.route(pointer.up())
            GestureBinding.shared.gestureArena.sweep(5)
            XCTAssertEqual(events, ["down#1", "panstart#1", "panupdate#1", "panend#1"])
        }
    }

    func test_Recognizes_consecutive_taps_and_drag() {
        testGesture { [self] tester in
            setUpTapAndPanGestureRecognizer()

            let pointer = TestPointer(pointer: 5)
            let downA = pointer.down(Offset(10.0, 10.0))
            tapAndDrag.addPointer(event: downA)
            tester.closeArena(5)
            tester.route(downA)
            tester.route(pointer.up())
            GestureBinding.shared.gestureArena.sweep(5)

            tester.backend.elapse(kConsecutiveTapDelay)

            let downB = pointer.down(Offset(10.0, 10.0))
            tapAndDrag.addPointer(event: downB)
            tester.closeArena(5)
            tester.route(downB)
            tester.route(pointer.up())
            GestureBinding.shared.gestureArena.sweep(5)

            tester.backend.elapse(kConsecutiveTapDelay)

            let downC = pointer.down(Offset(10.0, 10.0))
            tapAndDrag.addPointer(event: downC)
            tester.closeArena(5)
            tester.route(downC)
            tester.route(pointer.move(Offset(40.0, 45.0)))
            tester.route(pointer.up())
            XCTAssertEqual(
                events,
                [
                    "down#1",
                    "up#1",
                    "down#2",
                    "up#2",
                    "down#3",
                    "panstart#3",
                    "panupdate#3",
                    "panend#3",
                ]
            )
        }
    }

    func test_Recognizer_rejects_pointer_that_is_not_the_primary_one_before_acceptance() {
        testGesture { [self] tester in
            setUpTapAndPanGestureRecognizer()

            tapAndDrag.addPointer(event: down1)
            tapAndDrag.addPointer(event: down2)
            tester.closeArena(1)
            tester.route(down1)

            tester.closeArena(2)
            tester.route(down2)

            tester.route(up1)
            GestureBinding.shared.gestureArena.sweep(1)

            tester.route(up2)
            GestureBinding.shared.gestureArena.sweep(2)
            XCTAssertEqual(events, ["down#1", "up#1"])
        }
    }

    func test_Calls_tap_up_when_the_recognizer_accepts_before_handleEvent_is_called() {
        testGesture { [self] tester in
            setUpTapAndPanGestureRecognizer()

            tapAndDrag.addPointer(event: down1)
            tester.closeArena(1)
            GestureBinding.shared.gestureArena.sweep(1)
            tester.route(down1)
            tester.route(up1)
            XCTAssertEqual(events, ["down#1", "up#1"])
        }
    }
}
