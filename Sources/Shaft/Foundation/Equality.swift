// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Compares two values for equality, handling type differences.
///
/// This function compares two values for equality, even if they are of
/// different types, as long as the types are equatable.
internal func isEqual<T1: Equatable, T2: Equatable>(_ a: T1, _ b: T2) -> Bool {
    if let a = a as? T2 {
        return a == b
    }
    return false
}

internal func objectsEqual(_ a: [AnyObject], _ b: [AnyObject]) -> Bool {
    guard a.count == b.count else {
        return false
    }
    for (i, a) in a.enumerated() {
        if a !== b[i] {
            return false
        }
    }
    return true
}
