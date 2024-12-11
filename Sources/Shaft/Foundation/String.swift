// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A convenience class for building strings.
public class StringBuilder {
    private var buffer: String = ""

    /// Appends the given string to the buffer.
    func append(_ string: String) {
        buffer.append(string)
    }

    /// Takes the current contents of the buffer and returns them as a string.
    /// After calling this method, the buffer is reset to empty.
    func build() -> String {
        let result = buffer
        buffer = ""
        return result
    }
}

extension String {
    /// Returns the UTF-16 code unit at the given index. The return value is
    /// in the range of uint16.
    internal func codeUnitAt(_ index: TextIndex) -> Int {
        return Int(utf16[utf16.index(utf16.startIndex, offsetBy: index.utf16Offset)])
    }
}
