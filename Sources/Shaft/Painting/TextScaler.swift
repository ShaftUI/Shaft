// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A object that describes how textual contents should be scaled for better
/// readability.
///
/// The [scale] function computes the scaled font size given the original
/// unscaled font size specified by app developers.
///
/// The [==] operator defines the equality of 2 [TextScaler]s, which the
/// framework uses to determine whether text widgets should rebuild when their
/// [TextScaler] changes. Consider overridding the [==] operator if applicable
/// to avoid unnecessary rebuilds.
public protocol TextScaler: Equatable {
    /// Computes the scaled font size (in logical pixels) with the given unscaled
    /// `fontSize` (in logical pixels).
    ///
    /// The input `fontSize` must be finite and non-negative.
    ///
    /// When given the same `fontSize` input, this method returns the same value.
    /// The output of a larger input `fontSize` is typically larger than that of a
    /// smaller input, but on unusual occasions they may produce the same output.
    /// For example, some platforms use single-precision floats to represent font
    /// sizes, as a result of truncation two different unscaled font sizes can be
    /// scaled to the same value.
    func scale(_ fontSize: Float) -> Float

    /// Returns a new [TextScaler] that restricts the scaled font size to within
    /// the range `[minScaleFactor * fontSize, maxScaleFactor * fontSize]`.
    //   TextScaler clamp({ double minScaleFactor = 0, double maxScaleFactor = double.infinity }) {
    //     assert(maxScaleFactor >= minScaleFactor);
    //     assert(!maxScaleFactor.isNaN);
    //     assert(minScaleFactor.isFinite);
    //     assert(minScaleFactor >= 0);

    //     return minScaleFactor == maxScaleFactor
    //       ? TextScaler.linear(minScaleFactor)
    //       : _ClampedTextScaler(this, minScaleFactor, maxScaleFactor);
    //   }
}

extension TextScaler where Self == LinearTextScaler {
    /// Creates a proportional [TextScaler] that scales the incoming font size by
    /// multiplying it with the given `textScaleFactor`.
    public static func linear(_ textScaleFactor: Float) -> LinearTextScaler {
        LinearTextScaler(textScaleFactor: textScaleFactor)
    }

    /// A [TextScaler] that doesn't scale the input font size.
    ///
    /// This is equivalent to `TextScaler.linear(1.0)`, the [TextScaler.scale]
    /// implementation always returns the input font size as-is.
    public static var noScaling: LinearTextScaler {
        LinearTextScaler(textScaleFactor: 1.0)
    }
}

extension TextScaler {
    public func isEqualTo(_ other: any TextScaler) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}

public struct LinearTextScaler: TextScaler {
    let textScaleFactor: Float

    public func scale(_ fontSize: Float) -> Float {
        return fontSize * textScaleFactor
    }
}
