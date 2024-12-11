// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A single shadow.
///
/// Multiple shadows are stacked together in a [TextStyle].
public struct BoxShadow {
    public init(
        color: Color,
        offset: Offset,
        blurRadius: Float,
        spreadRadius: Float,
        blurStyle: BlurStyle
    ) {
        self.color = color
        self.offset = offset
        self.blurRadius = blurRadius
        self.spreadRadius = spreadRadius
        self.blurStyle = blurStyle
    }

    public let color: Color

    public let offset: Offset

    public let blurRadius: Float

    /// The amount the box should be inflated prior to applying the blur.
    public let spreadRadius: Float

    /// The [BlurStyle] to use for this shadow.
    ///
    /// Defaults to [BlurStyle.normal].
    public let blurStyle: BlurStyle

    /// The [blurRadius] in sigmas instead of logical pixels.
    ///
    /// See the sigma argument to [MaskFilter.blur].
    public var blurSigma: Float {
        convertRadiusToSigma(blurRadius)
    }

    /// Create the Paint object that corresponds to this shadow description.
    ///
    /// The offset and spreadRadius are not represented in the Paint object.
    /// To honor those as well, the shape should be inflated by spreadRadius pixels
    /// in every direction and then translated by offset before being filled using
    /// this Paint.
    ///
    /// The blurStyle is ignored if debugDisableShadows is true. This causes
    /// an especially significant change to the rendering when BlurStyle.outer
    /// is used; the caller is responsible for adjusting for that case if
    /// necessary. (This only matters when using debugDisableShadows, e.g. in
    /// tests that use matchesGoldenFile.)
    public func toPaint() -> Paint {
        var result = Paint()
        result.color = color
        result.maskFilter = MaskFilter(style: blurStyle, sigma: blurSigma)
        return result
    }
}

/// Converts a blur radius in pixels to sigmas.
///
/// See the sigma argument to [MaskFilter.blur].
///
/// See SkBlurMask::ConvertRadiusToSigma().
/// <https://github.com/google/skia/blob/bb5b77db51d2e149ee66db284903572a5aac09be/src/effects/SkBlurMask.cpp#L23>
public func convertRadiusToSigma(_ radius: Float) -> Float {
    radius > 0 ? radius * 0.57735 + 0.5 : 0
}
