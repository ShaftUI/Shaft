// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

func assert(_ clousure: () -> Bool) {
    assert(clousure())
}

/// Asserts that the given function should be implemented.
func shouldImplement(_ function: String = #function, file: String = #file, line: Int = #line)
    -> Never
{
    preconditionFailure("Should implement \(function) in \(file) at line \(line)")
}
