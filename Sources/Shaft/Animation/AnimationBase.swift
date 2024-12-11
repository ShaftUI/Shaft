public class AnimationBase: Listenable {
    private var _listeners: [ObjectIdentifier: () -> Void] = [:]

    public func addListener(_ listener: AnyObject, callback: @escaping VoidCallback) {
        let id = ObjectIdentifier(listener)
        assert(_listeners[id] == nil, "This listener is already registered")
        _listeners[id] = callback
    }

    public func removeListener(_ listener: AnyObject) {
        let id = ObjectIdentifier(listener)
        _listeners.removeValue(forKey: id)
    }

    /// Removes all listeners added with [addListener].
    ///
    /// This method is typically called from the `dispose` method of the class
    /// using this mixin if the class also uses the [AnimationEagerListenerMixin].
    func clearListeners() {
        _listeners.removeAll()
    }

    /// Calls all the listeners.
    ///
    /// If listeners are added or removed during this function, the modifications
    /// will not change which listeners are called during this iteration.
    func notifyListeners() {
        let localListeners = _listeners
        for listener in localListeners.values {
            listener()
        }
    }

    private var _statusListeners: [ObjectIdentifier: AnimationStatusListener] = [:]

    /// Calls listener every time the status of the animation changes.
    ///
    /// Listeners can be removed with [removeStatusListener].
    public func addStatusListener(
        _ listener: AnyObject,
        callback: @escaping AnimationStatusListener
    ) {
        let id = ObjectIdentifier(listener)
        assert(_statusListeners[id] == nil, "This listener is already registered")
        _statusListeners[id] = callback
    }

    /// Stops calling the listener every time the status of the animation changes.
    ///
    /// Listeners can be added with [addStatusListener].
    public func removeStatusListener(_ listener: AnyObject) {
        let id = ObjectIdentifier(listener)
        _statusListeners.removeValue(forKey: id)
    }

    /// Removes all listeners added with [addStatusListener].
    ///
    /// This method is typically called from the `dispose` method of the class
    /// using this mixin if the class also uses the [AnimationEagerListenerMixin].
    func clearStatusListeners() {
        _statusListeners.removeAll()
    }

    /// Calls all the status listeners.
    ///
    /// If listeners are added or removed during this function, the modifications
    /// will not change which listeners are called during this iteration.
    func notifyStatusListeners(status: AnimationStatus) {
        let localListeners = _statusListeners
        for listener in localListeners.values {
            listener(status)
        }
    }
}
