// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extension BinaryInteger {
    /// Casts the integer to whatever type is needed.
    public func cast() -> UInt32 {
        return UInt32(self)
    }

    /// Casts the integer to whatever type is needed.
    public func cast() -> Int32 {
        return Int32(self)
    }
}
