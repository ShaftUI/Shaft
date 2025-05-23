// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Whether two doubles are within a given distance of each other.
///
/// The `epsilon` argument must be positive and not null.
/// The `a` and `b` arguments may be null. A null value is only considered
/// near-equal to another null value.
internal func nearEqual(_ a: Double?, _ b: Double?, _ epsilon: Double) -> Bool {
    assert(epsilon >= 0.0)
    if a == nil || b == nil {
        return a == b
    }
    return (a! > (b! - epsilon)) && (a! < (b! + epsilon)) || a == b
}

/// Whether a double is within a given distance of zero.
///
/// The epsilon argument must be positive.
internal func nearZero(_ a: Double, _ epsilon: Double) -> Bool { return nearEqual(a, 0.0, epsilon) }
