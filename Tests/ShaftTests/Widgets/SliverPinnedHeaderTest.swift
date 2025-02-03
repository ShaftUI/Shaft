import Foundation
import Shaft
import XCTest

class SliverPinnedHeaderTest: XCTestCase {
    func test_SliverPinnedHeader_basics() {
        testWidgets { tester in
            func buildFrame(axis: Axis, reverse: Bool) -> Widget {
                CustomScrollView(
                    scrollDirection: axis,
                    reverse: reverse
                ) {
                    SliverPinnedHeader {
                        Text("PinnedHeaderSliver")
                    }
                    SliverList(
                        delegate: SliverChildBuilderDelegate(
                            { context, index in Text("Item \(index)") },
                            childCount: 100
                        )
                    )
                }
            }

            func getHeaderRect() -> TRect<Float> {
                return tester.getRect(.text("PinnedHeaderSliver"))
            }
            func getItemRect(_ index: Int) -> TRect<Float> {
                return tester.getRect(.text("Item \(index)"))
            }

            // axis: Axis.vertical, reverse: false
            do {
                tester.pumpWidget(buildFrame(axis: .vertical, reverse: false))
                tester.forceFrame()
                let position = tester.findState(Scrollable.self)!.position!

                // The test viewport is 800 x 600 (width x height).
                // The header's child is at the top of the scroll view and all items are the same height.
                XCTAssertEqual(getHeaderRect().topLeft, .zero)
                XCTAssertEqual(getHeaderRect().width, 800)
                XCTAssertEqual(
                    getHeaderRect().height,
                    tester.getSize(.text("PinnedHeaderSliver")).height
                )

                // First and last visible items
                let itemHeight = getItemRect(0).height
                let visibleItemCount = Int(600 / itemHeight) - 1  // less 1 for the header
                XCTAssertEqual(tester.matchAll(.text("Item 0")).count, 1)
                XCTAssertEqual(tester.matchAll(.text("Item \(visibleItemCount - 1)")).count, 1)

                // Scrolling up and down leaves the header at the top.
                position.moveTo(itemHeight * 5)
                tester.forceFrame()
                XCTAssertEqual(getHeaderRect().top, 0)
                XCTAssertEqual(getHeaderRect().width, 800)
                position.moveTo(itemHeight * -5)
                XCTAssertEqual(getHeaderRect().top, 0)
                XCTAssertEqual(getHeaderRect().width, 800)
            }

            // axis: Axis.horizontal, reverse: false
            do {
                tester.pumpWidget(buildFrame(axis: .horizontal, reverse: false))
                tester.forceFrame()
                let position = tester.findState(Scrollable.self)!.position!

                XCTAssertEqual(getHeaderRect().topLeft, .zero)
                XCTAssertEqual(getHeaderRect().height, 600)
                XCTAssertEqual(
                    getHeaderRect().width,
                    tester.getSize(.text("PinnedHeaderSliver")).width
                )

                // First and last visible items (assuming < 10 items visible)
                let itemWidth = getItemRect(0).width
                let visibleItemCount = Int((800 - getHeaderRect().width) / itemWidth)
                XCTAssertEqual(tester.matchAll(.text("Item 0")).count, 1)
                XCTAssertEqual(tester.matchAll(.text("Item \(visibleItemCount - 1)")).count, 1)

                // Scrolling left and right leaves the header on the left.
                position.moveTo(itemWidth * 5)
                tester.forceFrame()
                XCTAssertEqual(getHeaderRect().left, 0)
                XCTAssertEqual(getHeaderRect().height, 600)
                position.moveTo(itemWidth * -5)
                XCTAssertEqual(getHeaderRect().left, 0)
                XCTAssertEqual(getHeaderRect().height, 600)
            }

            // axis: Axis.vertical, reverse: true
            do {
                tester.pumpWidget(buildFrame(axis: .vertical, reverse: true))
                tester.forceFrame()
                let position = tester.findState(Scrollable.self)!.position!

                XCTAssertEqual(getHeaderRect().bottomLeft, Offset(0, 600))
                XCTAssertEqual(getHeaderRect().width, 800)
                XCTAssertEqual(
                    getHeaderRect().height,
                    tester.getSize(.text("PinnedHeaderSliver")).height
                )

                // First and last visible items
                let itemHeight = getItemRect(0).height
                let visibleItemCount = Int(600 / itemHeight) - 1  // less 1 for the header
                XCTAssertEqual(tester.matchAll(.text("Item 0")).count, 1)
                XCTAssertEqual(tester.matchAll(.text("Item \(visibleItemCount - 1)")).count, 1)

                // Scrolling up and down leaves the header at the bottom.
                position.moveTo(itemHeight * 5)
                tester.forceFrame()
                XCTAssertEqual(getHeaderRect().bottomLeft, Offset(0, 600))
                XCTAssertEqual(getHeaderRect().width, 800)
                position.moveTo(itemHeight * -5)
                XCTAssertEqual(getHeaderRect().bottomLeft, Offset(0, 600))
                XCTAssertEqual(getHeaderRect().width, 800)
            }

            // axis: Axis.horizontal, reverse: true
            do {
                tester.pumpWidget(buildFrame(axis: .horizontal, reverse: true))
                tester.forceFrame()
                let position = tester.findState(Scrollable.self)!.position!

                XCTAssertEqual(getHeaderRect().topRight, Offset(800, 0))
                XCTAssertEqual(getHeaderRect().height, 600)
                XCTAssertEqual(
                    getHeaderRect().width,
                    tester.getSize(.text("PinnedHeaderSliver")).width,
                    accuracy: 0.0001
                )

                // First and last visible items (assuming < 10 items visible)
                let itemWidth = getItemRect(0).width
                let visibleItemCount = Int((800 - getHeaderRect().width) / itemWidth)
                XCTAssertEqual(tester.matchAll(.text("Item 0")).count, 1)
                XCTAssertEqual(tester.matchAll(.text("Item \(visibleItemCount - 1)")).count, 1)

                // Scrolling left and right leaves the header on the right.
                position.moveTo(itemWidth * 5)
                tester.forceFrame()
                XCTAssertEqual(getHeaderRect().topRight, Offset(800, 0))
                XCTAssertEqual(getHeaderRect().height, 600)
                position.moveTo(itemWidth * -5)
                XCTAssertEqual(getHeaderRect().topRight, Offset(800, 0))
                XCTAssertEqual(getHeaderRect().height, 600)
            }
        }
    }
}
