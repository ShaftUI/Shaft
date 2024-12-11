import Foundation
import Shaft
import XCTest

class StackTest: XCTestCase {
    func testLayout() {
        testWidgets { tester in
            tester.pumpWidget(
                Stack {
                    Positioned(left: 0, top: 0) {
                        Text("A")
                    }
                    Positioned(left: 100, top: 100) {
                        Text("B")
                    }
                    Positioned(left: 200, top: 200) {
                        Text("C")
                    }
                }
            )

            XCTAssertEqual(tester.findWidgets(Text.self).count, 3)
        }
    }
}
