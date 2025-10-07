// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Signature for frame-related callbacks from the scheduler.
///
/// The `timeStamp` is the number of milliseconds since the beginning of the
/// scheduler's epoch. Use timeStamp to determine how far to advance animation
/// timelines so that all the animations in the system are synchronized to a
/// common time base.
public typealias FrameCallback = (Duration) -> Void

/// Signature of callbacks that have no arguments and return no data.
public typealias VoidCallback = () -> Void

/// Signature for callbacks that report that an underlying value has changed.
///
/// See also:
///
///  * ``ValueSetter``, for callbacks that report that a value has been set.
public typealias ValueChanged<T> = (T) -> Void

struct CallbackList {
    private var callbacks: [VoidCallback] = []

    mutating func add(_ callback: @escaping VoidCallback) {
        callbacks.append(callback)
    }

    // mutating func remove(_ callback: @escaping VoidCallback) {
    //     callbacks.removeAll { $0 === callback }
    // }

    func call() {
        for callback in callbacks {
            callback()
        }
    }
}

struct CallbackList1<T> {
    private var callbacks: [ValueChanged<T>] = []

    mutating func add(_ callback: @escaping ValueChanged<T>) {
        callbacks.append(callback)
    }

    // mutating func remove(_ callback: @escaping ValueChanged<T>) {
    //     callbacks.removeAll { $0 === callback }
    // }

    func call(_ value: T) {
        for callback in callbacks {
            callback(value)
        }
    }
}

struct CallbackList2<T1, T2> {
    private var callbacks: [(T1, T2) -> Void] = []

    mutating func add(_ callback: @escaping (T1, T2) -> Void) {
        callbacks.append(callback)
    }

    // mutating func remove(_ callback: @escaping (T1, T2) -> Void) {
    //     callbacks.removeAll { $0 === callback }
    // }

    func call(_ value1: T1, _ value2: T2) {
        for callback in callbacks {
            callback(value1, value2)
        }
    }
}
