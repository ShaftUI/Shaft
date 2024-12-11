import Foundation
import Shaft
import XCTest

class VelocityTrackerTest: XCTestCase {
    static let expected: [Offset] = [
        Offset(219.59280094228163, 1304.701682306001),
        Offset(355.71046950050845, 967.2112857054104),
        Offset(12.657970884022308, -36.90447839251946),
        Offset(714.1399654786744, -2561.534447931869),
        Offset(-19.668121066218564, -2910.105747052462),
        Offset(646.8690114934209, 2976.977762577527),
        Offset(396.6988447819592, 2106.225572911095),
        Offset(298.31594440044495, -3660.8315955215294),
        Offset(-1.7334232785165882, -3288.13174127454),
        Offset(384.6361280392334, -2645.6612524779835),
        Offset(176.37900397918557, 2711.2542876273264),
        Offset(396.9328560260098, 4280.651578291764),
        Offset(-71.51939428321249, 3716.7385187526947),
    ]

    func testVelocityTracker() {
        let tracker = VelocityTracker(kind: .touch)
        var i = 0
        for event in velocityEventData {
            if event is PointerDownEvent || event is PointerMoveEvent {
                tracker.addPosition(event.timeStamp, event.position)
            }
            if event is PointerUpEvent {
                XCTAssertTrue(_checkVelocity(tracker.getVelocity(), Self.expected[i]))
                i += 1
            }
        }
    }
}

func _withinTolerance(actual: Float, expected: Float) -> Bool {
    let kTolerance: Float = 0.001  // Within .1% of expected value
    let diff = (actual - expected) / expected
    return abs(diff) < kTolerance
}

func _checkVelocity(_ actual: Velocity, _ expected: Offset) -> Bool {
    return _withinTolerance(actual: actual.pixelsPerSecond.dx, expected: expected.dx)
        && _withinTolerance(actual: actual.pixelsPerSecond.dy, expected: expected.dy)
}
