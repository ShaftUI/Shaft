import Foundation
import Shaft
import XCTest

class ElementTest: XCTestCase {
    func testGlobalKey() {
        let key = GlobalKey()

        testWidgets { tester in
            tester.pumpWidget(
                Stack {
                    KeyedSubtree(key: key) {
                        Text("A")
                    }
                    Text("B")
                }
            )

            // element and renderObject at the first build
            let element1 = key.currentContext
            let renderObject1 = element1!.findRenderObject() as! RenderParagraph
            XCTAssertEqual(renderObject1.text.toPlainText(), "A")
            XCTAssertEqual(tester.findWidgets(Text.self).count, 2)

            tester.pumpWidget(
                Stack {
                    Text("A")
                    KeyedSubtree(key: key) {
                        Text("B")
                    }
                }
            )
            tester.forceFrame()

            // element and renderObject at the second build
            let element2 = key.currentContext
            let renderObject2 = element2!.findRenderObject() as! RenderParagraph
            XCTAssertEqual(renderObject2.text.toPlainText(), "B")
            XCTAssertIdentical(element1, element2)
            XCTAssertIdentical(renderObject1, renderObject2)
            XCTAssertEqual(
                WidgetsBinding.shared.buildOwner.globalKeyRegistry,
                [key: element2 as! Element]
            )
            XCTAssertEqual(tester.findWidgets(Text.self).count, 2)

            tester.pumpWidget(
                Stack {
                    Text("A")
                    SizedBox {
                        KeyedSubtree(key: key) {
                            Text("B")
                        }
                    }
                }
            )
            tester.forceFrame()

            // element and renderObject at the third build
            let element3 = key.currentContext
            let renderObject3 = element3!.findRenderObject() as! RenderParagraph
            XCTAssertEqual(renderObject3.text.toPlainText(), "B")
            XCTAssertIdentical(element2, element3)
            XCTAssertIdentical(renderObject2, renderObject3)
            XCTAssertEqual(
                WidgetsBinding.shared.buildOwner.globalKeyRegistry,
                [key: element3 as! Element]
            )
            XCTAssertEqual(tester.findWidgets(Text.self).count, 2)
        }
    }

    func testAnyKey() {
        let key1 = GlobalKey()
        let key2 = GlobalKey()

        XCTAssertTrue(AnyKey(key1) == AnyKey(key1))
        XCTAssertFalse(AnyKey(key1) == AnyKey(key2))

        let key3: any Key = GlobalKey()

        XCTAssertTrue(AnyKey(key3) == AnyKey(key3))

        var map: [AnyKey: String] = [:]

        // XCTAssertEqual(map[AnyKey(key1)], "A")
        map[AnyKey(key3)] = "A"
        map[AnyKey(key3)] = "A"

        XCTAssertEqual(map.count, 1)
        XCTAssertEqual(map[AnyKey(key3)], "A")
    }
}
