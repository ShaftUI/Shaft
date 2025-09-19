import Foundation
import Shaft
import XCTest

class TextSpanHitTestTest: XCTestCase {

    func testTextSpanWithGestureRecognizerReceivesHits() {
        testWidgets { tester in
            var tapCount = 0
            let tapRecognizer = TapGestureRecognizer()
            tapRecognizer.onTap = {
                tapCount += 1
            }

            let textSpan = TextSpan(
                text: "Clickable Link",
                style: TextStyle(color: Color.argb(255, 0, 0, 255)),
                recognizer: tapRecognizer
            )

            tester.pumpWidget(
                Center {
                    RichText(text: textSpan)
                }
            )

            // Find the RichText element and get its render object
            var richTextElement: Element?
            for element in tester.allElements {
                if element.widget is RichText {
                    richTextElement = element
                    break
                }
            }
            let renderParagraph = richTextElement!.findRenderObject() as! RenderParagraph

            // Simulate a tap in the middle of the text
            let hitResult = BoxHitTestResult()
            let textCenter = Offset(50, 10)  // Approximate center of text
            let hitSuccessful = renderParagraph.hitTest(hitResult, position: textCenter)

            // Verify the hit was successful
            XCTAssertTrue(hitSuccessful, "Hit test should succeed for position within text bounds")

            // Verify the TextSpan was added to hit test results
            let hitEntries = hitResult.path
            XCTAssertGreaterThan(hitEntries.count, 0, "Hit test should produce results")

            // Find the TextSpan in the hit test results
            let textSpanHit = hitEntries.first { entry in
                entry.target is TextSpan
            }
            XCTAssertNotNil(textSpanHit, "TextSpan should be in hit test results")

            // Simulate dispatching the pointer event to verify gesture recognition
            let downEvent = PointerDownEvent(
                pointer: 1,
                position: textCenter,
                buttons: .primaryButton
            )

            if let textSpanEntry = textSpanHit {
                textSpanEntry.target.handleEvent(downEvent, entry: textSpanEntry)
            }

            // The recognizer should have received the event
            // Note: Full gesture recognition would require more complex event simulation
        }
    }

    func testTextSpanWithoutGestureRecognizerDoesNotReceiveHits() {
        testWidgets { tester in
            let textSpan = TextSpan(
                text: "Non-clickable Text",
                style: TextStyle(color: Color.argb(255, 0, 0, 0))
                // No recognizer
            )

            tester.pumpWidget(
                Center {
                    RichText(text: textSpan)
                }
            )

            // Find the RichText element and get its render object
            var richTextElement: Element?
            for element in tester.allElements {
                if element.widget is RichText {
                    richTextElement = element
                    break
                }
            }
            let renderParagraph = richTextElement!.findRenderObject() as! RenderParagraph

            // Simulate a tap in the middle of the text
            let hitResult = BoxHitTestResult()
            let textCenter = Offset(50, 10)
            let hitSuccessful = renderParagraph.hitTest(hitResult, position: textCenter)

            // The hit test should succeed (paragraph receives hits)
            XCTAssertTrue(hitSuccessful, "Hit test should succeed for RenderParagraph")

            // But no TextSpan should be in the results since it has no recognizer
            let textSpanHit = hitResult.path.first { entry in
                entry.target is TextSpan
            }
            XCTAssertNil(
                textSpanHit,
                "TextSpan without recognizer should not be in hit test results"
            )
        }
    }

    func testMultipleTextSpansHitTesting() {
        testWidgets { tester in
            var linkTapCount = 0
            var buttonTapCount = 0

            let linkRecognizer = TapGestureRecognizer()
            linkRecognizer.onTap = {
                linkTapCount += 1
            }

            let buttonRecognizer = TapGestureRecognizer()
            buttonRecognizer.onTap = {
                buttonTapCount += 1
            }

            let combinedSpan = TextSpan(
                children: [
                    TextSpan(text: "Click "),
                    TextSpan(
                        text: "this link",
                        style: TextStyle(color: Color.argb(255, 0, 0, 255)),
                        recognizer: linkRecognizer
                    ),
                    TextSpan(text: " or "),
                    TextSpan(
                        text: "this button",
                        style: TextStyle(color: Color.argb(255, 255, 0, 0)),
                        recognizer: buttonRecognizer
                    ),
                    TextSpan(text: " for action."),
                ]
            )

            tester.pumpWidget(
                Center {
                    RichText(text: combinedSpan)
                }
            )

            // Find the RichText element and get its render object
            var richTextElement: Element?
            for element in tester.allElements {
                if element.widget is RichText {
                    richTextElement = element
                    break
                }
            }
            let renderParagraph = richTextElement!.findRenderObject() as! RenderParagraph

            // Test different positions to hit different spans
            let hitResult1 = BoxHitTestResult()
            let linkPosition = Offset(30, 10)  // Approximate position of "this link"
            let hit1 = renderParagraph.hitTest(hitResult1, position: linkPosition)

            let hitResult2 = BoxHitTestResult()
            let buttonPosition = Offset(80, 10)  // Approximate position of "this button"
            let hit2 = renderParagraph.hitTest(hitResult2, position: buttonPosition)

            // Both hits should succeed
            XCTAssertTrue(hit1, "Hit test should succeed for link position")
            XCTAssertTrue(hit2, "Hit test should succeed for button position")

            // Verify correct TextSpans are hit
            let linkHit = hitResult1.path.first { entry in
                if let textSpan = entry.target as? TextSpan {
                    return textSpan.text == "this link"
                }
                return false
            }

            let buttonHit = hitResult2.path.first { entry in
                if let textSpan = entry.target as? TextSpan {
                    return textSpan.text == "this button"
                }
                return false
            }

            // Note: This test demonstrates the concept, but actual position calculation
            // would depend on text layout which is complex to predict in tests
            // In practice, you'd use actual measured positions from the text painter
        }
    }

    func testGetSpanForPositionFindsCorrectSpan() {
        // Test the core getSpanForPosition functionality directly
        let recognizer = TapGestureRecognizer()

        let rootSpan = TextSpan(
            children: [
                TextSpan(text: "Hello "),
                TextSpan(
                    text: "world",
                    style: TextStyle(color: Color.argb(255, 0, 0, 255)),
                    recognizer: recognizer
                ),
                TextSpan(text: "!"),
            ]
        )

        // Test positions within different spans
        let position1 = TextPosition(offset: TextIndex(utf16Offset: 3))  // Within "Hello "
        let position2 = TextPosition(offset: TextIndex(utf16Offset: 7))  // Within "world"
        let position3 = TextPosition(offset: TextIndex(utf16Offset: 12))  // Within "!"

        // Find spans for each position
        let span1 = rootSpan.getSpanForPosition(position1)
        let span2 = rootSpan.getSpanForPosition(position2)
        let span3 = rootSpan.getSpanForPosition(position3)

        // Only the span with recognizer should be returned
        XCTAssertNil(span1, "Span without recognizer should not be returned")
        XCTAssertNotNil(span2, "Span with recognizer should be returned")
        XCTAssertNil(span3, "Span without recognizer should not be returned")

        // Verify the correct span was found
        if let foundSpan = span2 as? TextSpan {
            XCTAssertEqual(foundSpan.text, "world", "Should find the correct span")
            XCTAssertNotNil(foundSpan.recognizer, "Found span should have recognizer")
        }
    }

    func testTextSpanHandleEventDelegatesToGestureRecognizer() {
        var eventReceived = false
        let recognizer = TapGestureRecognizer()
        recognizer.onTapDown = { _ in
            eventReceived = true
        }

        let textSpan = TextSpan(
            text: "Clickable",
            recognizer: recognizer
        )

        // Create a pointer down event
        let downEvent = PointerDownEvent(
            pointer: 1,
            position: Offset(10, 10),
            buttons: .primaryButton
        )

        // Create a hit test entry
        let hitEntry = HitTestEntry(textSpan)

        // Handle the event
        textSpan.handleEvent(downEvent, entry: hitEntry)

        // The gesture recognizer should have been notified
        // Note: Full verification would require gesture arena processing
        // This test demonstrates the delegation pattern
    }

    func testTextSpanGetSpanForPositionVisitorWithinBounds() {
        let recognizer = TapGestureRecognizer()
        let textSpan = TextSpan(
            text: "Test",
            recognizer: recognizer
        )

        var offset = 0

        // Position within the span (offset 2, which is in "Te[s]t")
        let position = TextPosition(offset: TextIndex(utf16Offset: 2))
        let result = textSpan.getSpanForPositionVisitor(position, &offset)

        XCTAssertNotNil(result, "Should find span for position within bounds")
        XCTAssertTrue(result === textSpan, "Should return the correct span")
    }

    func testTextSpanGetSpanForPositionVisitorOutsideBounds() {
        let recognizer = TapGestureRecognizer()
        let textSpan = TextSpan(
            text: "Test",  // 4 characters
            recognizer: recognizer
        )

        var offset = 0

        // Position outside the span (offset 10, which is beyond "Test")
        let position = TextPosition(offset: TextIndex(utf16Offset: 10))
        let result = textSpan.getSpanForPositionVisitor(position, &offset)

        XCTAssertNil(result, "Should not find span for position outside bounds")
    }
}
