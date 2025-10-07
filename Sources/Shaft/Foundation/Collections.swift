// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extension Array {
    /// Returns true if the array is not empty
    public var isNotEmpty: Bool {
        return !isEmpty
    }
}

extension Set {
    /// Returns true if the set is not empty
    public var isNotEmpty: Bool {
        return !isEmpty
    }
}

extension Array where Element: AnyObject {
    mutating func remove(object: Element) {
        if let index = firstIndex(where: { $0 === object }) {
            remove(at: index)
        }
    }

    func contains(object: Element) -> Bool {
        return firstIndex(where: { $0 === object }) != nil
    }
}

extension Dictionary {
    /// Returns true if the dictionary is not empty
    var isNotEmpty: Bool {
        return !isEmpty
    }

    mutating func putIfAbsent(_ key: Key, _ value: () -> Value) -> Value {
        if let value = self[key] {
            return value
        }
        let value = value()
        self[key] = value
        return value
    }
}

public protocol HashableObject: AnyObject, Hashable {
    func hash(into hasher: inout Hasher)
}

extension HashableObject {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs === rhs
    }
}

extension String {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

/// A wrapper around a type that makes it conform to ``Hashable``.
struct HashableType: Hashable {
    init(_ base: AnyObject.Type) {
        self.base = base
    }

    let base: AnyObject.Type

    static func == (lhs: HashableType, rhs: HashableType) -> Bool {
        return lhs.base == rhs.base
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(base))
    }
}
