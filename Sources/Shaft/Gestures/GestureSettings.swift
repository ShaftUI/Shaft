// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The device specific gesture settings scaled into logical pixels.
///
/// This configuration can be retrieved from the window, or more commonly from a
/// [MediaQuery] widget.
public struct DeviceGestureSettings: Equatable {
    public init(touchSlop: Float?) {
        self.touchSlop = touchSlop
    }

    /// The touch slop value in logical pixels, or `null` if it was not set.
    public let touchSlop: Float?

    /// The touch slop value for pan gestures, in logical pixels, or `null` if it
    /// was not set.
    public var panSlop: Float? {
        if let touchSlop = touchSlop {
            return touchSlop * 2
        } else {
            return nil
        }
    }
}
