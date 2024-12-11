import Shaft
import XCTest

class TextBoundaryTest: XCTestCase {
    func testEqual() {
        XCTAssertEqual(1 + 1, 2)
    }

    func testCharacterBoundaryWorks() {
        let boundary = CharacterBoundary("abc")
        // XCTAssertTrue(boundary._hasConsistentTexstRangeImplementationWithinRange(3))

        XCTAssertNil(boundary.getLeadingTextBoundaryAt(.init(utf16Offset: -1)))
        XCTAssertEqual(boundary.getTrailingTextBoundaryAt(.init(utf16Offset: -1)), .zero)

        XCTAssertEqual(boundary.getLeadingTextBoundaryAt(.init(utf16Offset: 0))!.utf16Offset, 0)
        XCTAssertEqual(boundary.getTrailingTextBoundaryAt(.init(utf16Offset: 0))!.utf16Offset, 1)

        XCTAssertEqual(boundary.getLeadingTextBoundaryAt(.init(utf16Offset: 1))!.utf16Offset, 1)
        XCTAssertEqual(boundary.getTrailingTextBoundaryAt(.init(utf16Offset: 1))!.utf16Offset, 2)

        XCTAssertEqual(boundary.getLeadingTextBoundaryAt(.init(utf16Offset: 2))!.utf16Offset, 2)
        XCTAssertEqual(boundary.getTrailingTextBoundaryAt(.init(utf16Offset: 2))!.utf16Offset, 3)

        XCTAssertEqual(boundary.getLeadingTextBoundaryAt(.init(utf16Offset: 3))!.utf16Offset, 3)
        XCTAssertNil(boundary.getTrailingTextBoundaryAt(.init(utf16Offset: 3)))

        XCTAssertEqual(boundary.getLeadingTextBoundaryAt(.init(utf16Offset: 4))!.utf16Offset, 3)
        XCTAssertNil(boundary.getTrailingTextBoundaryAt(.init(utf16Offset: 4)))
    }
}
