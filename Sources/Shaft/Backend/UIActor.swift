// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @globalActor
// public actor UIActor {
//     public static let shared = UIActor()

//     public nonisolated var unownedExecutor: UnownedSerialExecutor {
//         print("Getting unowned executor")
//         return UIThreadExecutor.sharedUnownedExecutor
//     }
// }

// final class UIThreadExecutor: SerialExecutor {
//     func enqueue(_ job: consuming ExecutorJob) {
//         print("Enqueueing job on UI thread")
//         let unownedJob = UnownedJob(job)
//         backend.postTask {
//             unownedJob.runSynchronously(on: Self.sharedUnownedExecutor)
//         // }
//     }

//     func asUnownedSerialExecutor() -> UnownedSerialExecutor {
//         print("Creating unowned executor")
//         return UnownedSerialExecutor(ordinary: self)
//     }

//     static let sharedUnownedExecutor = UIThreadExecutor().asUnownedSerialExecutor()
// }
