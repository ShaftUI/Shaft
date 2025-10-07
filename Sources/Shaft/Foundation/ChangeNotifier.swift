// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Observation

/// An object that maintains a list of listeners.
///
/// The listeners are typically used to notify clients that the object has been
/// updated.
public protocol Listenable: AnyObject {
    /// Register a closure to be called when the object notifies its listeners.
    func addListener(_ listener: AnyObject, callback: @escaping VoidCallback)

    /// Remove a previously registered closure from the list of closures that
    /// the object notifies.
    func removeListener(_ listener: AnyObject)
}

public protocol ValueListenable<Value>: Listenable {
    associatedtype Value

    var value: Value { get }
}

@Observable
@propertyWrapper public class ValueNotifier<Value>: ValueListenable {
    public init(_ wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public var value: Value {
        get { wrappedValue }
        set { wrappedValue = newValue }
    }

    public var wrappedValue: Value {
        didSet {
            observers.values.forEach { $0() }
        }
    }

    public var projectedValue: ValueNotifier {
        self
    }

    private var observers: [ObjectIdentifier: () -> Void] = [:]

    public func addListener(_ observer: AnyObject, callback: @escaping () -> Void) {
        let id = ObjectIdentifier(observer)
        assert(observers[id] == nil, "This observer is already registered")
        observers[id] = callback
    }

    public func removeListener(_ observer: AnyObject) {
        let id = ObjectIdentifier(observer)
        observers.removeValue(forKey: id)
    }

    public func dispose() {
        observers.removeAll()
    }
}

/// A class that can be extended that provides a change notification API using
/// ``VoidCallback`` for notifications.
///
/// It is O(1) for adding listeners and O(N) for removing listeners and
/// dispatching notifications (where N is the number of listeners).
open class ChangeNotifier: Listenable {
    public init() {}

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

    public func notifyListeners() {
        _listeners.values.forEach { $0() }
    }

    public func dispose() {
        _listeners.removeAll()
    }
}
