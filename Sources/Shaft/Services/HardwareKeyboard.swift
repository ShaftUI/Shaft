// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Setting to true will cause extensive logging to occur when key events are
/// received.
///
/// Can be used to debug keyboard issues: each time a key event is received on
/// the framework side, the event details and the current pressed state will
/// be printed.
public var debugPrintKeyboardEvents = false

// When using keyboardDebug, always call it like so:
//
// assert(keyboardDebug { "Blah \(foo)" })
//
// It needs to be inside the assert in order to be removed in release mode, and
// it needs to use a closure to generate the string in order to avoid string
// interpolation when debugPrintKeyboardEvents is false.
//
// It will throw an error if you try to call it when the app is in release
// mode.
private func keyboardDebug(
    _ messageFunc: @escaping () -> String,
    detailsFunc: (() -> [Any])? = nil
) -> Bool {
    #if !DEBUG
        fatalError(
            "keyboardDebug was called in Release mode, which means they are called "
                + "without being wrapped in an assert. Always call keyboardDebug like so:\n"
                + "  assert(keyboardDebug { \"Blah \\(foo)\" })"
        )
    #endif

    if !debugPrintKeyboardEvents {
        return true
    }
    debugPrint("KEYBOARD: \(messageFunc())")
    let details = detailsFunc?() ?? []
    if !details.isEmpty {
        for detail in details {
            debugPrint("    \(detail)")
        }
    }
    // Return true so that it can be used inside of an assert.
    return true
}

/// Represents a lock mode of a keyboard, such as `KeyboardLockMode.capsLock.`
///
/// A lock mode locks some of a keyboard's keys into a distinct mode of operation,
/// depending on the lock settings selected. The status of the mode is toggled
/// with each key down of its corresponding logical key. A `KeyboardLockMode`
/// object is used to query whether this mode is enabled on the keyboard.
public enum KeyboardLockMode {
    /// Represents the number lock mode on the keyboard.
    ///
    /// On supporting systems, enabling number lock mode usually allows key
    /// presses of the number pad to input numbers, instead of acting as up, down,
    /// left, right, page up, end, etc.
    case numLock

    /// Represents the scrolling lock mode on the keyboard.
    ///
    /// On supporting systems and applications (such as a spreadsheet), enabling
    /// scrolling lock mode usually allows key presses of the cursor keys to
    /// scroll the document instead of the cursor.
    case scrollLock

    /// Represents the capital letters lock mode on the keyboard.
    ///
    /// On supporting systems, enabling capital lock mode allows key presses of
    /// the letter keys to input uppercase letters instead of lowercase.
    case capsLock

    // KeyboardLockMode has a fixed pool of supported keys.
    private init(_ logicalKey: LogicalKeyboardKey) {
        switch logicalKey {
        case LogicalKeyboardKey.numLock:
            self = .numLock
        case LogicalKeyboardKey.scrollLock:
            self = .scrollLock
        case LogicalKeyboardKey.capsLock:
            self = .capsLock
        default:
            fatalError("Unknown logical key for lock mode: \(logicalKey)")
        }
    }

    /// The logical key that triggers this lock mode.
    public var logicalKey: LogicalKeyboardKey {
        switch self {
        case .numLock:
            return LogicalKeyboardKey.numLock
        case .scrollLock:
            return LogicalKeyboardKey.scrollLock
        case .capsLock:
            return LogicalKeyboardKey.capsLock
        }
    }

    private static let knownLockModes: [LogicalKeyboardKey: KeyboardLockMode] = [
        LogicalKeyboardKey.numLock: .numLock,
        LogicalKeyboardKey.scrollLock: .scrollLock,
        LogicalKeyboardKey.capsLock: .capsLock,
    ]

    /// Returns the KeyboardLockMode constant from the logical key, or
    /// nil, if not found.
    public static func findLockByLogicalKey(_ logicalKey: LogicalKeyboardKey) -> KeyboardLockMode? {
        return knownLockModes[logicalKey]
    }
}

/// Manages key events from hardware keyboards.
///
/// [HardwareKeyboard] manages all key events of the Flutter application from
/// hardware keyboards (in contrast to on-screen keyboards). It receives key
/// data from the native platform, dispatches key events to registered
/// handlers, and records the keyboard state.
///
/// To stay notified whenever keys are pressed, held, or released, add a
/// handler with [addHandler]. To only be notified when a specific part of the
/// app is focused, use a [Focus] widget's `onFocusChanged` attribute instead
/// of [addHandler]. Handlers should be removed with [removeHandler] when
/// notification is no longer necessary, or when the handler is being disposed.
///
/// To query whether a key is being held, or a lock mode is enabled, use
/// [physicalKeysPressed], [logicalKeysPressed], or [lockModesEnabled].
/// These states will have been updated with the event when used during a key
/// event handler.
///
/// The singleton [HardwareKeyboard] instance is held by the [ServicesBinding]
/// as [ServicesBinding.keyboard], and can be conveniently accessed using the
/// [HardwareKeyboard.instance] static accessor.
///
/// ## Event model
///
/// Flutter uses a universal event model ([KeyEvent]) and key options
/// ([LogicalKeyboardKey] and [PhysicalKeyboardKey]) regardless of the native
/// platform, while preserving platform-specific features as much as
/// possible.
///
/// [HardwareKeyboard] guarantees that the key model is "regularized": The key
/// event stream consists of "key tap sequences", where a key tap sequence is
/// defined as one [KeyDownEvent], zero or more [KeyRepeatEvent]s, and one
/// [KeyUpEvent] in order, all with the same physical key and logical key.
///
/// Example:
///
///  * Tap and hold key A, US layout:
///     * KeyDownEvent(physicalKey: keyA, logicalKey: keyA, character: "a")
///     * KeyRepeatEvent(physicalKey: keyA, logicalKey: keyA, character: "a")
///     * KeyUpEvent(physicalKey: keyA, logicalKey: keyA)
///  * Press ShiftLeft, tap key A, then release ShiftLeft, US layout:
///     * KeyDownEvent(physicalKey: shiftLeft, logicalKey: shiftLeft)
///     * KeyDownEvent(physicalKey: keyA, logicalKey: keyA, character: "A")
///     * KeyRepeatEvent(physicalKey: keyA, logicalKey: keyA, character: "A")
///     * KeyUpEvent(physicalKey: keyA, logicalKey: keyA)
///     * KeyUpEvent(physicalKey: shiftLeft, logicalKey: shiftLeft)
///  * Tap key Q, French layout:
///     * KeyDownEvent(physicalKey: keyA, logicalKey: keyQ, character: "q")
///     * KeyUpEvent(physicalKey: keyA, logicalKey: keyQ)
///  * Tap CapsLock:
///     * KeyDownEvent(physicalKey: capsLock, logicalKey: capsLock)
///     * KeyUpEvent(physicalKey: capsLock, logicalKey: capsLock)
///
/// When the Flutter application starts, all keys are released, and all lock
/// modes are disabled. Upon key events, [HardwareKeyboard] will update its
/// states, then dispatch callbacks: [KeyDownEvent]s and [KeyUpEvent]s set
/// or reset the pressing state, while [KeyDownEvent]s also toggle lock modes.
///
/// Flutter will try to synchronize with the ground truth of keyboard states
/// using synthesized events ([KeyEvent.synthesized]), subject to the
/// availability of the platform. The desynchronization can be caused by
/// non-empty initial state or a change in the focused window or application.
/// For example, if CapsLock is enabled when the application starts, then
/// immediately before the first key event, a synthesized [KeyDownEvent] and
/// [KeyUpEvent] of CapsLock will be dispatched.
///
/// The resulting event stream does not map one-to-one to the native key event
/// stream. Some native events might be skipped, while some events might be
/// synthesized and do not correspond to native events. Synthesized events will
/// be indicated by [KeyEvent.synthesized].
///
/// Example:
///
///  * Flutter starts with CapsLock on, the first press of keyA:
///     * KeyDownEvent(physicalKey: capsLock, logicalKey: capsLock, synthesized: true)
///     * KeyUpEvent(physicalKey: capsLock, logicalKey: capsLock, synthesized: true)
///     * KeyDownEvent(physicalKey: keyA, logicalKey: keyA, character: "a")
///  * While holding ShiftLeft, lose window focus, release shiftLeft, then focus
///    back and press keyA:
///     * KeyUpEvent(physicalKey: shiftLeft, logicalKey: shiftLeft, synthesized: true)
///     * KeyDownEvent(physicalKey: keyA, logicalKey: keyA, character: "a")
///
/// Flutter does not distinguish between multiple keyboards. Flutter will
/// process all events as if they come from a single keyboard, and try to
/// resolve any conflicts and provide a regularized key event stream, which
/// can deviate from the ground truth.
///
/// See also:
///
///  * [KeyDownEvent], [KeyRepeatEvent], and [KeyUpEvent], the classes used to
///    describe specific key events.
///  * [instance], the singleton instance of this class.
public class HardwareKeyboard {
    /// A protocol that defines a handler for key events.
    public protocol Handler: AnyObject {
        /// Handles a key event. Returns `true` if the event was handled, or
        /// `false` if it was not.
        func handleKeyEvent(_ event: KeyEvent) -> Bool
    }

    /// The singleton instance of the `HardwareKeyboard` class.
    ///
    /// This provides access to the shared instance of the `HardwareKeyboard`
    /// class, which manages the state of the hardware keyboard and dispatches
    /// key events.
    public static let shared = HardwareKeyboard()

    private init() {
        backend.onKeyEvent = handleKeyEvent
    }

    private var pressedKeys: [PhysicalKeyboardKey: LogicalKeyboardKey] = [:]

    /// The set of [PhysicalKeyboardKey]s that are pressed.
    ///
    /// If called from a key event handler, the result will already include the effect
    /// of the event.
    ///
    /// See also:
    ///
    ///  * [logicalKeysPressed], which tells if a logical key is being pressed.
    public var physicalKeysPressed: Set<PhysicalKeyboardKey> {
        return Set(pressedKeys.keys)
    }

    /// The set of [LogicalKeyboardKey]s that are pressed.
    ///
    /// If called from a key event handler, the result will already include the effect
    /// of the event.
    ///
    /// See also:
    ///
    ///  * [physicalKeysPressed], which tells if a physical key is being pressed.
    public var logicalKeysPressed: Set<LogicalKeyboardKey> {
        return Set(pressedKeys.values)
    }

    /// Returns the logical key that corresponds to the given pressed physical key.
    ///
    /// Returns null if the physical key is not currently pressed.
    private func lookUpLayout(_ physicalKey: PhysicalKeyboardKey) -> LogicalKeyboardKey? {
        return pressedKeys[physicalKey]
    }

    private var _lockModes: Set<KeyboardLockMode> = []
    /// The set of [KeyboardLockMode] that are enabled.
    ///
    /// Lock keys, such as CapsLock, are logical keys that toggle their
    /// respective boolean states on key down events. Such flags are usually used
    /// as modifier to other keys or events.
    ///
    /// If called from a key event handler, the result will already include the effect
    /// of the event.
    public var lockModesEnabled: Set<KeyboardLockMode> {
        return _lockModes
    }

    /// Returns true if the given [LogicalKeyboardKey] is pressed, according to
    /// the [HardwareKeyboard].
    public func isLogicalKeyPressed(_ key: LogicalKeyboardKey) -> Bool {
        return pressedKeys.values.contains(key)
    }

    /// Returns true if the given [PhysicalKeyboardKey] is pressed, according to
    /// the [HardwareKeyboard].
    public func isPhysicalKeyPressed(_ key: PhysicalKeyboardKey) -> Bool {
        return pressedKeys.keys.contains(key)
    }

    /// Returns true if a logical CTRL modifier key is pressed, regardless of
    /// which side of the keyboard it is on.
    ///
    /// Use [isLogicalKeyPressed] if you need to know which control key was
    /// pressed.
    public var isControlPressed: Bool {
        return isLogicalKeyPressed(LogicalKeyboardKey.controlLeft)
            || isLogicalKeyPressed(LogicalKeyboardKey.controlRight)
    }

    /// Returns true if a logical SHIFT modifier key is pressed, regardless of
    /// which side of the keyboard it is on.
    ///
    /// Use [isLogicalKeyPressed] if you need to know which shift key was pressed.
    public var isShiftPressed: Bool {
        return isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft)
            || isLogicalKeyPressed(LogicalKeyboardKey.shiftRight)
    }

    /// Returns true if a logical ALT modifier key is pressed, regardless of which
    /// side of the keyboard it is on.
    ///
    /// The `AltGr` key that appears on some keyboards is considered to be the
    /// same as [LogicalKeyboardKey.altRight] on some platforms (notably Android).
    /// On platforms that can distinguish between `altRight` and `altGr`, a press
    /// of `AltGr` will not return true here, and will need to be tested for
    /// separately.
    ///
    /// Use [isLogicalKeyPressed] if you need to know which alt key was pressed.
    public var isAltPressed: Bool {
        return isLogicalKeyPressed(LogicalKeyboardKey.altLeft)
            || isLogicalKeyPressed(LogicalKeyboardKey.altRight)
    }

    /// Returns true if a logical META modifier key is pressed, regardless of
    /// which side of the keyboard it is on.
    ///
    /// Use [isLogicalKeyPressed] if you need to know which meta key was pressed.
    public var isMetaPressed: Bool {
        return isLogicalKeyPressed(LogicalKeyboardKey.metaLeft)
            || isLogicalKeyPressed(LogicalKeyboardKey.metaRight)
    }

    private func assertEventIsRegular(_ event: KeyEvent) {
        assert {
            let common =
                "If this occurs in real application, please report this "
                + "bug to Flutter. If this occurs in unit tests, please ensure that "
                + "simulated events follow Flutter's event model as documented in "
                + "`HardwareKeyboard`. This was the event: "
            if event.type == .down {
                assert(
                    !pressedKeys.keys.contains(event.physicalKey),
                    "A \(type(of: event)) is dispatched, but the state shows that the physical "
                        + "key is already pressed. \(common)\(event)"
                )
            } else if event.type == .repeating || event.type == .up {
                assert(
                    pressedKeys.keys.contains(event.physicalKey),
                    "A \(type(of: event)) is dispatched, but the state shows that the physical "
                        + "key is not pressed. \(common)\(event)"
                )
                assert(
                    pressedKeys[event.physicalKey] == event.logicalKey,
                    "A \(type(of: event)) is dispatched, but the state shows that the physical "
                        + "key is pressed on a different logical key. \(common)\(event) "
                        + "and the recorded logical key \(pressedKeys[event.physicalKey]!)"
                )
            } else {
                assert(false, "Unexpected key event class \(type(of: event))")
            }
            return true
        }
    }

    private var _handlers: [Handler] = []
    private var _duringDispatch = false
    private var _modifiedHandlers: [Handler]?

    /// Register a listener that is called every time a hardware key event
    /// occurs.
    ///
    /// All registered handlers will be invoked in order regardless of
    /// their return value. The return value indicates whether Flutter
    /// "handles" the event. If any handler returns true, the event
    /// will not be propagated to other native components in the add-to-app
    /// scenario.
    ///
    /// If an object added a handler, it must remove the handler before it is
    /// disposed.
    ///
    /// If used during event dispatching, the addition will not take effect
    /// until after the dispatching.
    ///
    /// See also:
    ///
    ///  * [removeHandler], which removes the handler.
    public func addHandler(_ handler: Handler) {
        if _duringDispatch {
            _modifiedHandlers = _modifiedHandlers ?? _handlers
            _modifiedHandlers!.append(handler)
        } else {
            _handlers.append(handler)
        }
    }

    /// Stop calling the given listener every time a hardware key event
    /// occurs.
    ///
    /// The `handler` argument must be [identical] to the one used in
    /// [addHandler]. If multiple exist, the first one will be removed.
    /// If none is found, then this method is a no-op.
    ///
    /// If used during event dispatching, the removal will not take effect
    /// until after the event has been dispatched.
    public func removeHandler(_ handler: Handler) {
        if _duringDispatch {
            _modifiedHandlers = _modifiedHandlers ?? _handlers
            _modifiedHandlers!.removeAll { $0 === handler }
        } else {
            _handlers.removeAll { $0 === handler }
        }
    }

    /// Query the engine and update _pressedKeys accordingly to the engine answer.
    ///
    /// Both the framework and the engine maintain a state of the current pressed
    /// keys. There are edge cases, related to startup and restart, where the framework
    /// needs to resynchronize its keyboard state.
    private func syncKeyboardState() async {
        if let keyboardState = backend.getKeyboardState() {
            for (physicalKey, logicalKey) in keyboardState {
                pressedKeys[physicalKey] = logicalKey
            }
        }
    }

    private func dispatchKeyEvent(_ event: KeyEvent) -> Bool {
        // This dispatching could have used the same algorithm as [ChangeNotifier],
        // but since 1) it shouldn't be necessary to support reentrantly
        // dispatching, 2) there shouldn't be many handlers (most apps should use
        // only 1, this function just uses a simpler algorithm.
        assert(!_duringDispatch, "Nested keyboard dispatching is not supported")
        _duringDispatch = true
        var handled = false
        for handler in _handlers {
            let thisResult = handler.handleKeyEvent(event)
            handled = handled || thisResult
        }
        _duringDispatch = false
        if let modifiedHandlers = _modifiedHandlers {
            _handlers = modifiedHandlers
            _modifiedHandlers = nil
        }
        return handled
    }

    private func _debugPressedKeysDetails() -> [String] {
        if pressedKeys.isEmpty {
            return ["Empty"]
        } else {
            return pressedKeys.map { "\($0.key): \($0.value)" }
        }
    }

    /// Process a new [KeyEvent] by recording the state changes and dispatching
    /// to handlers.
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        assert(keyboardDebug { "Key event received: \(event)" })
        assert(
            keyboardDebug { [self] in
                "Pressed state before processing the event: \(_debugPressedKeysDetails())"
            }
        )
        assertEventIsRegular(event)
        let physicalKey = event.physicalKey
        let logicalKey = event.logicalKey
        switch event.type {
        case .down:
            pressedKeys[physicalKey] = logicalKey
            if let lockMode = KeyboardLockMode.findLockByLogicalKey(event.logicalKey) {
                if _lockModes.contains(lockMode) {
                    _lockModes.remove(lockMode)
                } else {
                    _lockModes.insert(lockMode)
                }
            }
        case .up:
            pressedKeys.removeValue(forKey: physicalKey)
        case .repeating:
            ()  // Empty
        }

        assert(
            keyboardDebug { [self] in
                "Pressed state after processing the event: \(_debugPressedKeysDetails())"
            }
        )
        return dispatchKeyEvent(event)
    }

    /// Clear all keyboard states and additional handlers.
    ///
    /// All handlers are removed except for the first one, which is added by
    /// [ServicesBinding].
    ///
    /// This is used by the testing framework to make sure that tests are hermetic.
    package func clearState() {
        pressedKeys.removeAll()
        _lockModes.removeAll()
        _handlers.removeAll()
        assert(_modifiedHandlers == nil)
    }
}
