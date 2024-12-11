// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

private let controlSynonyms = LogicalKeyboardKey.expandSynonyms(Set([LogicalKeyboardKey.control]))
private let shiftSynonyms = LogicalKeyboardKey.expandSynonyms(Set([LogicalKeyboardKey.shift]))
private let altSynonyms = LogicalKeyboardKey.expandSynonyms(Set([LogicalKeyboardKey.alt]))
private let metaSynonyms = LogicalKeyboardKey.expandSynonyms(Set([LogicalKeyboardKey.meta]))

/// Determines how the state of a lock key is used to accept a shortcut.
public enum LockState {
    /// The lock key state is not used to determine [SingleActivator.accepts] result.
    case ignored
    /// The lock key must be locked to trigger the shortcut.
    case locked
    /// The lock key must be unlocked to trigger the shortcut.
    case unlocked
}

/// An interface to define the keyboard key combination to trigger a shortcut.
///
/// [ShortcutActivator]s are used by [Shortcuts] widgets, and are mapped to
/// [Intent]s, the intended behavior that the key combination should trigger.
/// When a [Shortcuts] widget receives a key event, its [ShortcutManager] looks
/// up the first matching [ShortcutActivator], and signals the corresponding
/// [Intent], which might trigger an action as defined by a hierarchy of
/// [Actions] widgets. For a detailed introduction on the mechanism and use of
/// the shortcut-action system, see [Actions].
///
/// The matching [ShortcutActivator] is looked up in the following way:
///
///  * Find the registered [ShortcutActivator]s whose [triggers] contain the
///    incoming event.
///  * Of the previous list, finds the first activator whose [accepts] returns
///    true in the order of insertion.
///
/// See also:
///
///  * [SingleActivator], an implementation that represents a single key combined
///    with modifiers (control, shift, alt, meta).
///  * [CharacterActivator], an implementation that represents key combinations
///    that result in the specified character, such as question mark.
///  * [LogicalKeySet], an implementation that requires one or more
///    [LogicalKeyboardKey]s to be pressed at the same time. Prefer
///    [SingleActivator] when possible.
public protocol ShortcutActivator {
    /// An optional property to provide all the keys that might be the final event
    /// to trigger this shortcut.
    ///
    /// For example, for `Ctrl-A`, [LogicalKeyboardKey.keyA] is the only trigger,
    /// while [LogicalKeyboardKey.control] is not, because the shortcut should
    /// only work by pressing KeyA *after* Ctrl, but not before. For `Ctrl-A-E`,
    /// on the other hand, both KeyA and KeyE should be triggers, since either of
    /// them is allowed to trigger.
    ///
    /// If provided, trigger keys can be used as a first-pass filter for incoming
    /// events in order to optimize lookups, as [Intent]s are stored in a [Map]
    /// and indexed by trigger keys. It is up to the individual implementors of
    /// this interface to decide if they ignore triggers or not.
    ///
    /// Subclasses should make sure that the return value of this method does not
    /// change throughout the lifespan of this object.
    ///
    /// This method might also return null, which means this activator declares
    /// all keys as trigger keys. Activators whose [triggers] return null will be
    /// tested with [accepts] on every event. Since this becomes a linear search,
    /// and having too many might impact performance, it is preferred to return
    /// non-null [triggers] whenever possible.
    var triggers: [LogicalKeyboardKey]? { get }

    /// Whether the triggering `event` and the keyboard `state` at the time of the
    /// event meet required conditions, providing that the event is a triggering
    /// event.
    ///
    /// For example, for `Ctrl-A`, it has to check if the event is a
    /// [KeyDownEvent], if either side of the Ctrl key is pressed, and none of the
    /// Shift keys, Alt keys, or Meta keys are pressed; it doesn't have to check
    /// if KeyA is pressed, since it's already guaranteed.
    ///
    /// As a possible performance improvement, implementers of this function are
    /// encouraged (but not required) to check the [triggers] member, if it is
    /// non-null, to see if it contains the event's logical key before doing more
    /// complicated work.
    ///
    /// This method must not cause any side effects for the `state`. Typically
    /// this is only used to query whether [HardwareKeyboard.logicalKeysPressed]
    /// contains a key.
    ///
    /// See also:
    ///
    /// * [LogicalKeyboardKey.collapseSynonyms], which helps deciding whether a
    ///   modifier key is pressed when the side variation is not important.
    func accepts(_ event: KeyEvent, _ state: HardwareKeyboard) -> Bool
}

/// A shortcut key combination of a single key and modifiers.
///
/// The [SingleActivator] implements typical shortcuts such as:
///
///  * ArrowLeft
///  * Shift + Delete
///  * Control + Alt + Meta + Shift + A
///
/// More specifically, it creates shortcut key combinations that are composed of a
/// [trigger] key, and zero, some, or all of the four modifiers (control, shift,
/// alt, meta). The shortcut is activated when the following conditions are met:
///
///  * The incoming event is a down event for a [trigger] key.
///  * If [control] is true, then at least one control key must be held.
///    Otherwise, no control keys must be held.
///  * Similar conditions apply for the [alt], [shift], and [meta] keys.
///
/// This resembles the typical behavior of most operating systems, and handles
/// modifier keys differently from [LogicalKeySet] in the following way:
///
///  * [SingleActivator]s allow additional non-modifier keys being pressed in
///    order to activate the shortcut. For example, pressing key X while holding
///    ControlLeft *and key A* will be accepted by
///    `SingleActivator(LogicalKeyboardKey.keyX, control: true)`.
///  * [SingleActivator]s do not consider modifiers to be a trigger key. For
///    example, pressing ControlLeft while holding key X *will not* activate a
///    `SingleActivator(LogicalKeyboardKey.keyX, control: true)`.
///
/// See also:
///
///  * [CharacterActivator], an activator that represents key combinations
///    that result in the specified character, such as question mark.
public class SingleActivator: ShortcutActivator {
    /// Triggered when the [trigger] key is pressed while the modifiers are held.
    ///
    /// The [trigger] should be the non-modifier key that is pressed after all the
    /// modifiers, such as [LogicalKeyboardKey.keyC] as in `Ctrl+C`. It must not
    /// be a modifier key (sided or unsided).
    ///
    /// The [control], [shift], [alt], and [meta] flags represent whether the
    /// respective modifier keys should be held (true) or released (false). They
    /// default to false.
    ///
    /// By default, the activator is checked on all [KeyDownEvent] events for the
    /// [trigger] key. If [includeRepeats] is false, only [trigger] key events
    /// which are not [KeyRepeatEvent]s will be considered.
    ///
    /// {@tool dartpad}
    /// In the following example, the shortcut `Control + C` increases the
    /// counter:
    ///
    /// ** See code in examples/api/lib/widgets/shortcuts/single_activator.0.dart **
    /// {@end-tool}
    init(
        _ trigger: LogicalKeyboardKey,
        control: Bool = false,
        alt: Bool = false,
        meta: Bool = false,
        shift: Bool = false,
        numLock: LockState = .ignored,
        includeRepeats: Bool = true
    ) {
        self.trigger = trigger
        self.control = control
        self.shift = shift
        self.alt = alt
        self.meta = meta
        self.numLock = numLock
        self.includeRepeats = includeRepeats

        assert(
            !(trigger == LogicalKeyboardKey.control) && !(trigger == LogicalKeyboardKey.controlLeft)
                && !(trigger == LogicalKeyboardKey.controlRight)
                && !(trigger == LogicalKeyboardKey.shift)
                && !(trigger == LogicalKeyboardKey.shiftLeft)
                && !(trigger == LogicalKeyboardKey.shiftRight)
                && !(trigger == LogicalKeyboardKey.alt) && !(trigger == LogicalKeyboardKey.altLeft)
                && !(trigger == LogicalKeyboardKey.altRight)
                && !(trigger == LogicalKeyboardKey.meta)
                && !(trigger == LogicalKeyboardKey.metaLeft)
                && !(trigger == LogicalKeyboardKey.metaRight)
        )
    }

    /// The non-modifier key of the shortcut that is pressed after all modifiers
    /// to activate the shortcut.
    ///
    /// For example, for `Control + C`, [trigger] should be
    /// [LogicalKeyboardKey.keyC].
    public let trigger: LogicalKeyboardKey

    /// Whether either (or both) control keys should be held for [trigger] to
    /// activate the shortcut.
    ///
    /// It defaults to false, meaning all Control keys must be released when the
    /// event is received in order to activate the shortcut. If it's true, then
    /// either or both Control keys must be pressed.
    ///
    /// See also:
    ///
    ///  * [LogicalKeyboardKey.controlLeft], [LogicalKeyboardKey.controlRight].
    public let control: Bool

    /// Whether either (or both) shift keys should be held for [trigger] to
    /// activate the shortcut.
    ///
    /// It defaults to false, meaning all Shift keys must be released when the
    /// event is received in order to activate the shortcut. If it's true, then
    /// either or both Shift keys must be pressed.
    ///
    /// See also:
    ///
    ///  * [LogicalKeyboardKey.shiftLeft], [LogicalKeyboardKey.shiftRight].
    public let shift: Bool

    /// Whether either (or both) alt keys should be held for [trigger] to
    /// activate the shortcut.
    ///
    /// It defaults to false, meaning all Alt keys must be released when the
    /// event is received in order to activate the shortcut. If it's true, then
    /// either or both Alt keys must be pressed.
    ///
    /// See also:
    ///
    ///  * [LogicalKeyboardKey.altLeft], [LogicalKeyboardKey.altRight].
    public let alt: Bool

    /// Whether either (or both) meta keys should be held for [trigger] to
    /// activate the shortcut.
    ///
    /// It defaults to false, meaning all Meta keys must be released when the
    /// event is received in order to activate the shortcut. If it's true, then
    /// either or both Meta keys must be pressed.
    ///
    /// See also:
    ///
    ///  * [LogicalKeyboardKey.metaLeft], [LogicalKeyboardKey.metaRight].
    public let meta: Bool

    /// Whether the NumLock key state should be checked for [trigger] to activate
    /// the shortcut.
    ///
    /// It defaults to [LockState.ignored], meaning the NumLock state is ignored
    /// when the event is received in order to activate the shortcut.
    /// If it's [LockState.locked], then the NumLock key must be locked.
    /// If it's [LockState.unlocked], then the NumLock key must be unlocked.
    ///
    /// See also:
    ///
    ///  * [LogicalKeyboardKey.numLock].
    public let numLock: LockState

    /// Whether this activator accepts repeat events of the [trigger] key.
    ///
    /// If [includeRepeats] is true, the activator is checked on all
    /// [KeyDownEvent] or [KeyRepeatEvent]s for the [trigger] key. If
    /// [includeRepeats] is false, only [trigger] key events which are
    /// [KeyDownEvent]s will be considered.
    public let includeRepeats: Bool

    public var triggers: [LogicalKeyboardKey]? {
        return [trigger]
    }

    private func shouldAcceptModifiers(_ pressed: Set<LogicalKeyboardKey>) -> Bool {
        return control == !pressed.intersection(controlSynonyms).isEmpty
            && shift == !pressed.intersection(shiftSynonyms).isEmpty
            && alt == !pressed.intersection(altSynonyms).isEmpty
            && meta == !pressed.intersection(metaSynonyms).isEmpty
    }

    private func shouldAcceptNumLock(_ state: HardwareKeyboard) -> Bool {
        switch numLock {
        case .ignored: return true
        case .locked: return state.lockModesEnabled.contains(KeyboardLockMode.numLock)
        case .unlocked: return !state.lockModesEnabled.contains(KeyboardLockMode.numLock)
        }
    }

    public func accepts(_ event: KeyEvent, _ state: HardwareKeyboard) -> Bool {
        return (event.type == .down || (includeRepeats && event.type == .repeating))
            && triggers!.contains(event.logicalKey)
            && shouldAcceptModifiers(state.logicalKeysPressed)
            && shouldAcceptNumLock(state)
    }
}

/// A manager of keyboard shortcut bindings used by [Shortcuts] to handle key
/// events.
///
/// The manager may be listened to (with [addListener]/[removeListener]) for
/// change notifications when the shortcuts change.
///
/// Typically, a [Shortcuts] widget supplies its own manager, but in uncommon
/// cases where overriding the usual shortcut manager behavior is desired, a
/// subclassed [ShortcutManager] may be supplied.
public class ShortcutManager: ChangeNotifier {
    /// Constructs a [ShortcutManager].
    init(shortcuts: [ActivatorIntentPair] = [], modal: Bool = false) {
        self.shortcuts = shortcuts
        self.modal = modal
    }

    /// True if the [ShortcutManager] should not pass on keys that it doesn't
    /// handle to any key-handling widgets that are ancestors to this one.
    ///
    /// Setting [modal] to true will prevent any key event given to this manager
    /// from being given to any ancestor managers, even if that key doesn't appear
    /// in the [shortcuts] list.
    ///
    /// The net effect of setting [modal] to true is to return
    /// [KeyEventResult.skipRemainingHandlers] from [handleKeypress] if it does
    /// not exist in the shortcut list, instead of returning
    /// [KeyEventResult.ignored].
    public let modal: Bool

    /// Returns the shortcut list.
    ///
    /// When the list is changed, listeners to this manager will be notified.
    public var shortcuts: [ActivatorIntentPair] {
        didSet {
            _indexedShortcutsCache = nil
            notifyListeners()
        }
    }

    private static func _indexShortcuts(_ source: [ActivatorIntentPair])
        -> [LogicalKeyboardKey?: [ActivatorIntentPair]]
    {
        var result: [LogicalKeyboardKey?: [ActivatorIntentPair]] = [:]
        for (activator, intent) in source {
            // This intermediate variable is necessary to comply with Swift analyzer
            let nullableTriggers: [LogicalKeyboardKey?] = activator.triggers ?? [nil]
            for trigger in nullableTriggers {
                if result[trigger] == nil {
                    result[trigger] = []
                }
                result[trigger]!.append((activator, intent))
            }
        }
        return result
    }

    private var _indexedShortcuts: [LogicalKeyboardKey?: [ActivatorIntentPair]] {
        if _indexedShortcutsCache == nil {
            _indexedShortcutsCache = Self._indexShortcuts(shortcuts)
        }
        return _indexedShortcutsCache!
    }

    private var _indexedShortcutsCache: [LogicalKeyboardKey?: [ActivatorIntentPair]]?

    private func _getCandidates(_ key: LogicalKeyboardKey) -> [ActivatorIntentPair] {
        return (_indexedShortcuts[key] ?? []) + (_indexedShortcuts[nil] ?? [])
    }

    /// Returns the [Intent], if any, that matches the current set of pressed
    /// keys.
    ///
    /// Returns null if no intent matches the current set of pressed keys.
    private func _find(_ event: KeyEvent, _ state: HardwareKeyboard) -> Intent? {
        for (activator, intent) in _getCandidates(event.logicalKey) {
            if activator.accepts(event, state) {
                return intent
            }
        }
        return nil
    }
    /// Handles a key press `event` in the given `context`.
    ///
    /// If a key mapping is found, then the associated action will be invoked
    /// using the [Intent] activated by the [ShortcutActivator] in the [shortcuts]
    /// map, and the currently focused widget's context (from
    /// [FocusManager.primaryFocus]).
    ///
    /// Returns a [KeyEventResult.handled] if an action was invoked, otherwise a
    /// [KeyEventResult.skipRemainingHandlers] if [modal] is true, or if it maps
    /// to a [DoNothingAction] with [DoNothingAction.consumesKey] set to false,
    /// and in all other cases returns [KeyEventResult.ignored].
    ///
    /// In order for an action to be invoked (and [KeyEventResult.handled]
    /// returned), a [ShortcutActivator] must accept the given [KeyEvent], be
    /// mapped to an [Intent], the [Intent] must be mapped to an [Action], and the
    /// [Action] must be enabled.
    func handleKeypress(_ context: BuildContext, _ event: KeyEvent) -> KeyEventResult {
        if let matchedIntent = _find(event, HardwareKeyboard.shared) {
            if let primaryContext = primaryFocus?.context {
                if let result = invokeAction(primaryContext, matchedIntent) {
                    return result
                }
            }
        }
        return modal ? KeyEventResult.skipRemainingHandlers : KeyEventResult.ignored
    }

    private func invokeAction<T: Intent>(
        _ context: BuildContext,
        _ intent: T
    ) -> KeyEventResult? {
        if let action: Action<T> = Actions.maybeFind(context) {
            let (enabled, invokeResult) = Actions.of(context).invokeActionIfEnabled(
                action,
                intent,
                context
            )
            if enabled {
                return action.toKeyEventResult(intent, invokeResult: invokeResult)
            }
        }
        return nil
    }
}

public typealias ActivatorIntentPair = (ShortcutActivator, Intent)

/// A widget that creates key bindings to specific actions for its
/// descendants.
///
/// This widget establishes a [ShortcutManager] to be used by its descendants
/// when invoking an [Action] via a keyboard key combination that maps to an
/// [Intent].
///
/// This is similar to but more powerful than the [CallbackShortcuts] widget.
/// Unlike [CallbackShortcuts], this widget separates key bindings and their
/// implementations. This separation allows [Shortcuts] to have key bindings
/// that adapt to the focused context. For example, the desired action for a
/// deletion intent may be to delete a character in a text input, or to delete
/// a file in a file menu.
///
/// See the article on
/// [Using Actions and Shortcuts](https://flutter.dev/to/actions-shortcuts)
/// for a detailed explanation.
///
/// See also:
///
///  * [CallbackShortcuts], a simpler but less flexible widget that defines key
///    bindings that invoke callbacks.
///  * [Intent], a class for containing a description of a user action to be
///    invoked.
///  * [Action], a class for defining an invocation of a user action.
///  * [CallbackAction], a class for creating an action from a callback.
public final class Shortcuts: StatefulWidget {
    /// Creates a const [Shortcuts] widget that owns the map of shortcuts and
    /// creates its own manager.
    ///
    /// When using this constructor, [manager] will return null.
    ///
    /// The [child] and [shortcuts] arguments are required.
    ///
    /// See also:
    ///
    ///  * [Shortcuts.manager], a constructor that uses a [ShortcutManager] to
    ///    manage the shortcuts list instead.
    public init(
        shortcuts: [ActivatorIntentPair],
        debugLabel: String? = nil,
        @WidgetBuilder child: () -> Widget
    ) {
        self._shortcuts = shortcuts
        self.debugLabel = debugLabel
        self.child = child()
        self.manager = nil
    }

    /// Creates a const [Shortcuts] widget that uses the [manager] to
    /// manage the map of shortcuts.
    ///
    /// If this constructor is used, [shortcuts] will return the contents of
    /// [ShortcutManager.shortcuts].
    ///
    /// The [child] and [manager] arguments are required.
    public init(
        manager: ShortcutManager,
        debugLabel: String? = nil,
        @WidgetBuilder child: () -> Widget
    ) {
        self.manager = manager
        self.debugLabel = debugLabel
        self.child = child()
        self._shortcuts = []
    }

    /// The [ShortcutManager] that will manage the mapping between key
    /// combinations and [Action]s.
    ///
    /// If this widget was created with [Shortcuts.manager], then
    /// [ShortcutManager.shortcuts] will be used as the source for shortcuts. If
    /// the unnamed constructor is used, this manager will be null, and a
    /// default-constructed [ShortcutManager] will be used.
    public let manager: ShortcutManager?

    /// {@template flutter.widgets.shortcuts.shortcuts}
    /// The map of shortcuts that describes the mapping between a key sequence
    /// defined by a [ShortcutActivator] and the [Intent] that will be emitted
    /// when that key sequence is pressed.
    /// {@endtemplate}
    public var shortcuts: [ActivatorIntentPair] {
        return manager == nil ? _shortcuts : manager!.shortcuts
    }
    private let _shortcuts: [ActivatorIntentPair]

    /// The child widget for this [Shortcuts] widget.
    public let child: Widget

    /// The debug label that is printed for this node when logged.
    ///
    /// If this label is set, then it will be displayed instead of the shortcut
    /// map when logged.
    ///
    /// This allows simplifying the diagnostic output to avoid cluttering it
    /// unnecessarily with large default shortcut maps.
    public let debugLabel: String?

    public func createState() -> some State<Shortcuts> {
        return ShortcutsState()
    }
}

private class ShortcutsState: State<Shortcuts> {
    private var _internalManager: ShortcutManager?
    private var manager: ShortcutManager {
        return widget.manager ?? _internalManager!
    }

    override func initState() {
        super.initState()
        if widget.manager == nil {
            _internalManager = ShortcutManager()
            _internalManager!.shortcuts = widget.shortcuts
        }
    }

    override func didUpdateWidget(_ oldWidget: Shortcuts) {
        super.didUpdateWidget(oldWidget)
        if widget.manager !== oldWidget.manager {
            if widget.manager != nil {
                _internalManager = nil
            } else {
                _internalManager = _internalManager ?? ShortcutManager()
            }
        }
        _internalManager?.shortcuts = widget.shortcuts
    }

    override func dispose() {
        super.dispose()
    }

    private func _handleOnKeyEvent(_ node: FocusNode, _ event: KeyEvent) -> KeyEventResult {
        if node.context == nil {
            return .ignored
        }
        return manager.handleKeypress(node.context!, event)
    }

    override func build(context: BuildContext) -> Widget {
        return Focus(
            onKeyEvent: _handleOnKeyEvent,
            canRequestFocus: false,
            debugLabel: "\(Shortcuts.self)"
        ) {
            widget.child
        }
    }
}
