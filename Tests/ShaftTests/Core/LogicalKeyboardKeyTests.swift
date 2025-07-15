import XCTest

@testable import Shaft

final class LogicalKeyboardKeyTests: XCTestCase {

    // MARK: - Unicode Character Tests

    func testKeyLabelForPrintableCharacters() {
        // Test lowercase letters should return uppercase
        XCTAssertEqual(LogicalKeyboardKey.keyA.keyLabel, "A")
        XCTAssertEqual(LogicalKeyboardKey.keyB.keyLabel, "B")
        XCTAssertEqual(LogicalKeyboardKey.keyZ.keyLabel, "Z")

        // Test digits
        XCTAssertEqual(LogicalKeyboardKey.digit0.keyLabel, "0")
        XCTAssertEqual(LogicalKeyboardKey.digit1.keyLabel, "1")
        XCTAssertEqual(LogicalKeyboardKey.digit9.keyLabel, "9")

        // Test special characters
        XCTAssertEqual(LogicalKeyboardKey.space.keyLabel, " ")
        XCTAssertEqual(LogicalKeyboardKey.exclamation.keyLabel, "!")
        XCTAssertEqual(LogicalKeyboardKey.dollar.keyLabel, "$")
        XCTAssertEqual(LogicalKeyboardKey.percent.keyLabel, "%")
    }

    // MARK: - Function Key Tests

    func testKeyLabelForFunctionKeys() {
        XCTAssertEqual(LogicalKeyboardKey.f1.keyLabel, "F1")
        XCTAssertEqual(LogicalKeyboardKey.f2.keyLabel, "F2")
        XCTAssertEqual(LogicalKeyboardKey.f12.keyLabel, "F12")
        XCTAssertEqual(LogicalKeyboardKey.f24.keyLabel, "F24")
    }

    // MARK: - Modifier Key Tests

    func testKeyLabelForModifierKeys() {
        XCTAssertEqual(LogicalKeyboardKey.shiftLeft.keyLabel, "Shift Left")
        XCTAssertEqual(LogicalKeyboardKey.shiftRight.keyLabel, "Shift Right")
        XCTAssertEqual(LogicalKeyboardKey.controlLeft.keyLabel, "Control Left")
        XCTAssertEqual(LogicalKeyboardKey.controlRight.keyLabel, "Control Right")
        XCTAssertEqual(LogicalKeyboardKey.altLeft.keyLabel, "Alt Left")
        XCTAssertEqual(LogicalKeyboardKey.altRight.keyLabel, "Alt Right")
        XCTAssertEqual(LogicalKeyboardKey.metaLeft.keyLabel, "Meta Left")
        XCTAssertEqual(LogicalKeyboardKey.metaRight.keyLabel, "Meta Right")

        // Test synonym keys
        XCTAssertEqual(LogicalKeyboardKey.control.keyLabel, "Control")
        XCTAssertEqual(LogicalKeyboardKey.shift.keyLabel, "Shift")
        XCTAssertEqual(LogicalKeyboardKey.alt.keyLabel, "Alt")
        XCTAssertEqual(LogicalKeyboardKey.meta.keyLabel, "Meta")
    }

    // MARK: - Navigation Key Tests

    func testKeyLabelForNavigationKeys() {
        XCTAssertEqual(LogicalKeyboardKey.arrowUp.keyLabel, "Arrow Up")
        XCTAssertEqual(LogicalKeyboardKey.arrowDown.keyLabel, "Arrow Down")
        XCTAssertEqual(LogicalKeyboardKey.arrowLeft.keyLabel, "Arrow Left")
        XCTAssertEqual(LogicalKeyboardKey.arrowRight.keyLabel, "Arrow Right")
        XCTAssertEqual(LogicalKeyboardKey.home.keyLabel, "Home")
        XCTAssertEqual(LogicalKeyboardKey.end.keyLabel, "End")
        XCTAssertEqual(LogicalKeyboardKey.pageUp.keyLabel, "Page Up")
        XCTAssertEqual(LogicalKeyboardKey.pageDown.keyLabel, "Page Down")
    }

    // MARK: - Common Key Tests

    func testKeyLabelForCommonKeys() {
        XCTAssertEqual(LogicalKeyboardKey.enter.keyLabel, "Enter")
        XCTAssertEqual(LogicalKeyboardKey.escape.keyLabel, "Escape")
        XCTAssertEqual(LogicalKeyboardKey.backspace.keyLabel, "Backspace")
        XCTAssertEqual(LogicalKeyboardKey.delete.keyLabel, "Delete")
        XCTAssertEqual(LogicalKeyboardKey.tab.keyLabel, "Tab")
        XCTAssertEqual(LogicalKeyboardKey.capsLock.keyLabel, "Caps Lock")
    }

    // MARK: - Media Key Tests

    func testKeyLabelForMediaKeys() {
        XCTAssertEqual(LogicalKeyboardKey.audioVolumeUp.keyLabel, "Audio Volume Up")
        XCTAssertEqual(LogicalKeyboardKey.audioVolumeDown.keyLabel, "Audio Volume Down")
        XCTAssertEqual(LogicalKeyboardKey.audioVolumeMute.keyLabel, "Audio Volume Mute")
        XCTAssertEqual(LogicalKeyboardKey.mediaPlay.keyLabel, "Media Play")
        XCTAssertEqual(LogicalKeyboardKey.mediaPause.keyLabel, "Media Pause")
        XCTAssertEqual(LogicalKeyboardKey.mediaPlayPause.keyLabel, "Media Play Pause")
    }

    // MARK: - Edge Cases

    func testKeyLabelForUnidentifiedKey() {
        XCTAssertEqual(LogicalKeyboardKey.unidentified.keyLabel, "Unidentified")
    }

    // Test that all defined keys have non-empty labels
    func testAllDefinedKeysHaveLabels() {
        let keysToTest: [LogicalKeyboardKey] = [
            .space, .enter, .escape, .backspace, .delete, .tab,
            .f1, .f12, .shiftLeft, .controlRight, .altLeft, .metaRight,
            .arrowUp, .home, .pageDown, .audioVolumeUp,
        ]

        for key in keysToTest {
            XCTAssertFalse(key.keyLabel.isEmpty, "Key \(key) should have a non-empty label")
        }
    }

    // Test that labels are consistent (no leading/trailing whitespace)
    func testKeyLabelsAreClean() {
        let keysToTest: [LogicalKeyboardKey] = [
            .space, .f1, .shiftLeft, .arrowUp, .enter,
        ]

        for key in keysToTest {
            if key == .space {
                continue
            }

            let label = key.keyLabel
            XCTAssertEqual(
                label,
                label.trimmingCharacters(in: .whitespacesAndNewlines),
                "Key label '\(label)' should not have leading/trailing whitespace"
            )
        }
    }
}
