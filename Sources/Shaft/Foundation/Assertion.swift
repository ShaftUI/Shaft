// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

func assert(_ clousure: () -> Bool) {
    assert(clousure())
}

// func assert(clousure: () -> Void) {
//     assert(
//         {
//             clousure()
//             return true
//         }()
//     )
// }
