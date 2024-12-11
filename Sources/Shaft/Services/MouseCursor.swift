// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Maintains the state of mouse cursors and manages how cursors are searched
/// for.
///
/// This is typically created as a global singleton and owned by [MouseTracker].
public class MouseCursorManager {
    /// Create a [MouseCursorManager] by specifying the fallback cursor.
    ///
    /// The `fallbackMouseCursor` must not be [MouseCursor.defer] (typically
    /// [SystemMouseCursors.basic]).
    public init(fallbackMouseCursor: MouseCursor) {
        precondition(fallbackMouseCursor != MouseCursor.defer)
        self.fallbackMouseCursor = fallbackMouseCursor
    }

    /// The mouse cursor to use if all cursor candidates choose to defer.
    ///
    /// See also:
    ///
    ///  * [MouseCursor.defer], the mouse cursor object to use to defer.
    public let fallbackMouseCursor: MouseCursor

    private var _lastSession: [Int: MouseCursorSession] = [:]

    /// Handles the changes that cause a pointer device to have a new list of mouse
    /// cursor candidates.
    ///
    /// This change can be caused by a pointer event, in which case
    /// `triggeringEvent` should not be null, or by other changes, such as when a
    /// widget has moved under a still mouse, which is detected after the current
    /// frame is complete. In either case, `cursorCandidates` should be the list of
    /// cursors at the location of the mouse in hit-test order.
    func handleDeviceCursorUpdate(
        device: Int,
        triggeringEvent: PointerEvent?,
        cursorCandidates: [MouseCursor]
    ) {
        if triggeringEvent is PointerRemovedEvent {
            _lastSession.removeValue(forKey: device)
            return
        }

        let lastSession = _lastSession[device]
        let nextCursor = firstNonDeferred(cursorCandidates) ?? fallbackMouseCursor
        assert(nextCursor != .defer)
        if lastSession?.cursor == nextCursor {
            return
        }

        let nativeCursor: NativeMouseCursor? =
            switch nextCursor {
            case .system(let systemCursor):
                backend.createCursor(systemCursor)
            default:
                nil
            }

        let nextSession = MouseCursorSession(
            cursor: nextCursor,
            nativeCursor: nativeCursor
        )
        _lastSession[device] = nextSession

        nextSession.activate()
    }

    private func firstNonDeferred(_ cursors: [MouseCursor]) -> MouseCursor? {
        for cursor in cursors {
            if cursor != .defer {
                return cursor
            }
        }
        return nil
    }
}

/// An interface for mouse cursor definitions.
///
/// A mouse cursor is a graphical image on the screen that echoes the movement
/// of a pointing device, such as a mouse or a stylus. A [MouseCursor] object
/// defines a kind of mouse cursor, such as an arrow, a pointing hand, or an
/// I-beam.
///
/// During the painting phase, [MouseCursor] objects are assigned to regions on
/// the screen via annotations. Later during a device update (e.g. when a mouse
/// moves), [MouseTracker] finds the _active cursor_ of each mouse device, which
/// is the front-most region associated with the position of each mouse cursor,
/// or defaults to [SystemMouseCursors.basic] if no cursors are associated with
/// the position. [MouseTracker] changes the cursor of the pointer if the new
/// active cursor is different from the previous active cursor, whose effect is
/// defined by the session created by [createSession].
public enum MouseCursor: Equatable {
    /// A [SystemMouseCursor] is a cursor that is natively supported by the
    /// platform that the program is running on. All supported system mouse
    /// cursors are enumerated in [SystemMouseCursors].
    case system(SystemMouseCursor)

    /// A special value that indicates that the region with this cursor defers
    /// the choice of cursor to the next region behind it.
    ///
    /// When an event occurs, [MouseTracker] will update each pointer's cursor
    /// by finding the list of regions that contain the pointer's location, from
    /// front to back in hit-test order. The pointer's cursor will be the first
    /// cursor in the list that is not a [MouseCursor.defer].
    case `defer`

    /// A special value that doesn't change cursor by itself, but make a region
    /// that blocks other regions behind it from changing the cursor.
    ///
    /// When a pointer enters a region with a cursor of [uncontrolled], the
    /// pointer retains its previous cursor and keeps so until it moves out of
    /// the region. Technically, this region absorb the mouse cursor hit test
    /// without changing the pointer's cursor.
    ///
    /// This is useful in a region that displays a platform view, which let the
    /// operating system handle pointer events and change cursors accordingly.
    /// To achieve this, the region's cursor must not be any Flutter cursor,
    /// since that might overwrite the system request upon pointer entering; the
    /// cursor must not be null either, since that allows the widgets behind the
    /// region to change cursors.
    case uncontrolled
}

/// Manages the duration that a pointing device should display a specific mouse
/// cursor.
///
/// While [MouseCursor] classes describe the kind of cursors,
/// [MouseCursorSession] classes represents a continuous use of the cursor on a
/// pointing device. The [MouseCursorSession] classes can be stateful. For
/// example, a cursor that needs to load resources might want to set a temporary
/// cursor first, then switch to the correct cursor after the load is completed.
private class MouseCursorSession {
    init(cursor: MouseCursor, nativeCursor: NativeMouseCursor?) {
        self.cursor = cursor
        self.nativeCursor = nativeCursor
    }

    let cursor: MouseCursor
    let nativeCursor: NativeMouseCursor?

    func activate() {
        nativeCursor?.activate()
    }
}
