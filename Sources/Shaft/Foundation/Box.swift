// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An utility class to warp a struct value and pass it as a reference.
class Box<T> {
    /// The wrapped value.
    var value: T

    init(_ value: T) {
        self.value = value
    }
}
