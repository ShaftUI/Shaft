import Shaft
import XCTest

class TapGestureRecognizerTest: XCTestCase {
    // Down/up pair 1: normal tap sequence
    let down1 = PointerDownEvent(
        pointer: 1,
        position: Offset(10.0, 10.0)
    )

    let up1 = PointerUpEvent(
        pointer: 1,
        position: Offset(11.0, 9.0)
    )

    // Down/up pair 2: normal tap sequence far away from pair 1
    let down2 = PointerDownEvent(
        pointer: 2,
        position: Offset(30.0, 30.0)
    )

    let up2 = PointerUpEvent(
        pointer: 2,
        position: Offset(31.0, 29.0)
    )

    func testRecongnizeTap() {
        testGesture { tester in
            let tap = TapGestureRecognizer()
            defer { tap.dispose() }

            var tapRecognized = false
            tap.onTap = {
                tapRecognized = true
            }

            tap.addPointer(event: self.down1)
            tester.closeArena(1)
            XCTAssertFalse(tapRecognized)

            tester.route(self.down1)
            XCTAssertFalse(tapRecognized)

            tester.route(self.up1)
            XCTAssertTrue(tapRecognized)
            tester.sweepArena(1)
            XCTAssertTrue(tapRecognized)
        }
    }

    func testRecongizeSupportedDeviceOnly() {
        testGesture { tester in
            let tap = TapGestureRecognizer(
                supportedDevices: Set([.mouse, .stylus])
            )
            defer { tap.dispose() }

            var tapRecognized = false
            tap.onTap = {
                tapRecognized = true
            }

            let touchDown = PointerDownEvent(
                pointer: 1,
                kind: .touch,
                position: Offset(10.0, 10.0)
            )
            let touchUp = PointerUpEvent(
                pointer: 1,
                kind: .touch,
                position: Offset(11.0, 9.0)
            )

            tap.addPointer(event: touchDown)
            tester.closeArena(1)
            XCTAssertFalse(tapRecognized)
            tester.route(touchDown)
            XCTAssertFalse(tapRecognized)

            tester.route(touchUp)
            XCTAssertFalse(tapRecognized)
            tester.sweepArena(1)
            XCTAssertFalse(tapRecognized)

            let mouseDown = PointerDownEvent(
                pointer: 1,
                kind: .mouse,
                position: Offset(10.0, 10.0)
            )
            let mouseUp = PointerUpEvent(
                pointer: 1,
                kind: .mouse,
                position: Offset(11.0, 9.0)
            )

            tap.addPointer(event: mouseDown)
            tester.closeArena(1)
            XCTAssertFalse(tapRecognized)
            tester.route(mouseDown)
            XCTAssertFalse(tapRecognized)

            tester.route(mouseUp)
            XCTAssertTrue(tapRecognized)
            tester.sweepArena(1)
            XCTAssertTrue(tapRecognized)

            tapRecognized = false

            let stylusDown = PointerDownEvent(
                pointer: 1,
                kind: .stylus,
                position: Offset(10.0, 10.0)
            )
            let stylusUp = PointerUpEvent(
                pointer: 1,
                kind: .stylus,
                position: Offset(11.0, 9.0)
            )

            tap.addPointer(event: stylusDown)
            tester.closeArena(1)
            XCTAssertFalse(tapRecognized)
            tester.route(stylusDown)
            XCTAssertFalse(tapRecognized)

            tester.route(stylusUp)
            XCTAssertTrue(tapRecognized)
            GestureBinding.shared.gestureArena.sweep(1)
            XCTAssertTrue(tapRecognized)
        }
    }
}
