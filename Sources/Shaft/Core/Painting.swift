// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

private func rectIsValid(_ rect: Rect) -> Bool {
    assert(!rect.hasNaN, "Rect argument contained a NaN value.")
    return true
}

private func rrectIsValid(_ rrect: RRect) -> Bool {
    assert(!rrect.hasNaN, "RRect argument contained a NaN value.")
    return true
}

private func offsetIsValid(_ offset: Offset) -> Bool {
    assert(!offset.dx.isNaN && !offset.dy.isNaN, "Offset argument contained a NaN value.")
    return true
}

private func matrix4IsValid(_ matrix4: [Float64]) -> Bool {
    assert(matrix4.count == 16, "Matrix4 must have 16 entries.")
    assert(matrix4.allSatisfy { $0.isFinite }, "Matrix4 entries must be finite.")
    return true
}

private func radiusIsValid(_ radius: Radius) -> Bool {
    assert(!radius.x.isNaN && !radius.y.isNaN, "Radius argument contained a NaN value.")
    return true
}

private func scaleAlpha(_ a: Color, _ factor: Float) -> Color {
    return a.withAlpha(UInt8(round(Float(a.alpha) * factor)).clamped(to: 0...255))
}

/// Algorithms to use when painting on the canvas.
///
/// When drawing a shape or image onto a canvas, different algorithms can be
/// used to blend the pixels. The different values of [BlendMode] specify
/// different such algorithms.
///
/// Each algorithm has two inputs, the _source_, which is the image being drawn,
/// and the _destination_, which is the image into which the source image is
/// being composited. The destination is often thought of as the _background_.
/// The source and destination both have four color channels, the red, green,
/// blue, and alpha channels. These are typically represented as numbers in the
/// range 0.0 to 1.0. The output of the algorithm also has these same four
/// channels, with values computed from the source and destination.
///
/// The documentation of each value below describes how the algorithm works. In
/// each case, an image shows the output of blending a source image with a
/// destination image. In the images below, the destination is represented by an
/// image with horizontal lines and an opaque landscape photograph, and the
/// source is represented by an image with vertical lines (the same lines but
/// rotated) and a bird clip-art image. The [src] mode shows only the source
/// image, and the [dst] mode shows only the destination image. In the
/// documentation below, the transparency is illustrated by a checkerboard
/// pattern. The [clear] mode drops both the source and destination, resulting
/// in an output that is entirely transparent (illustrated by a solid
/// checkerboard pattern).
///
/// The horizontal and vertical bars in these images show the red, green, and
/// blue channels with varying opacity levels, then all three color channels
/// together with those same varying opacity levels, then all three color
/// channels set to zero with those varying opacity levels, then two bars showing
/// a red/green/blue repeating gradient, the first with full opacity and the
/// second with partial opacity, and finally a bar with the three color channels
/// set to zero but the opacity varying in a repeating gradient.
///
/// ## Application to the [Canvas] API
///
/// When using [Canvas.saveLayer] and [Canvas.restore], the blend mode of the
/// [Paint] given to the [Canvas.saveLayer] will be applied when
/// [Canvas.restore] is called. Each call to [Canvas.saveLayer] introduces a new
/// layer onto which shapes and images are painted; when [Canvas.restore] is
/// called, that layer is then composited onto the parent layer, with the source
/// being the most-recently-drawn shapes and images, and the destination being
/// the parent layer. (For the first [Canvas.saveLayer] call, the parent layer
/// is the canvas itself.)
///
/// See also:
///
///  * [Paint.blendMode], which uses [BlendMode] to define the compositing
///    strategy.
public enum BlendMode {
    // This list comes from Skia's SkXfermode.h and the values (order) should be
    // kept in sync.
    // See: https://skia.org/docs/user/api/skpaint_overview/#SkXfermode

    /// Drop both the source and destination images, leaving nothing.
    ///
    /// This corresponds to the "clear" Porter-Duff operator.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_clear.png)
    case clear

    /// Drop the destination image, only paint the source image.
    ///
    /// Conceptually, the destination is first cleared, then the source image is
    /// painted.
    ///
    /// This corresponds to the "Copy" Porter-Duff operator.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_src.png)
    case src

    /// Drop the source image, only paint the destination image.
    ///
    /// Conceptually, the source image is discarded, leaving the destination
    /// untouched.
    ///
    /// This corresponds to the "Destination" Porter-Duff operator.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_dst.png)
    case dst

    /// Composite the source image over the destination image.
    ///
    /// This is the default value. It represents the most intuitive case, where
    /// shapes are painted on top of what is below, with transparent areas showing
    /// the destination layer.
    ///
    /// This corresponds to the "Source over Destination" Porter-Duff operator,
    /// also known as the Painter's Algorithm.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_srcOver.png)
    case srcOver

    /// Composite the source image under the destination image.
    ///
    /// This is the opposite of [srcOver].
    ///
    /// This corresponds to the "Destination over Source" Porter-Duff operator.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_dstOver.png)
    ///
    /// This is useful when the source image should have been painted before the
    /// destination image, but could not be.
    case dstOver

    /// Show the source image, but only where the two images overlap. The
    /// destination image is not rendered, it is treated merely as a mask. The
    /// color channels of the destination are ignored, only the opacity has an
    /// effect.
    ///
    /// To show the destination image instead, consider [dstIn].
    ///
    /// To reverse the semantic of the mask (only showing the source where the
    /// destination is absent, rather than where it is present), consider
    /// [srcOut].
    ///
    /// This corresponds to the "Source in Destination" Porter-Duff operator.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_srcIn.png)
    case srcIn

    /// Show the destination image, but only where the two images overlap. The
    /// source image is not rendered, it is treated merely as a mask. The color
    /// channels of the source are ignored, only the opacity has an effect.
    ///
    /// To show the source image instead, consider [srcIn].
    ///
    /// To reverse the semantic of the mask (only showing the source where the
    /// destination is present, rather than where it is absent), consider [dstOut].
    ///
    /// This corresponds to the "Destination in Source" Porter-Duff operator.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_dstIn.png)
    case dstIn

    /// Show the source image, but only where the two images do not overlap. The
    /// destination image is not rendered, it is treated merely as a mask. The color
    /// channels of the destination are ignored, only the opacity has an effect.
    ///
    /// To show the destination image instead, consider [dstOut].
    ///
    /// To reverse the semantic of the mask (only showing the source where the
    /// destination is present, rather than where it is absent), consider [srcIn].
    ///
    /// This corresponds to the "Source out Destination" Porter-Duff operator.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_srcOut.png)
    case srcOut

    /// Show the destination image, but only where the two images do not overlap. The
    /// source image is not rendered, it is treated merely as a mask. The color
    /// channels of the source are ignored, only the opacity has an effect.
    ///
    /// To show the source image instead, consider [srcOut].
    ///
    /// To reverse the semantic of the mask (only showing the destination where the
    /// source is present, rather than where it is absent), consider [dstIn].
    ///
    /// This corresponds to the "Destination out Source" Porter-Duff operator.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_dstOut.png)
    case dstOut

    /// Composite the source image over the destination image, but only where it
    /// overlaps the destination.
    ///
    /// This corresponds to the "Source atop Destination" Porter-Duff operator.
    ///
    /// This is essentially the [srcOver] operator, but with the output's opacity
    /// channel being set to that of the destination image instead of being a
    /// combination of both image's opacity channels.
    ///
    /// For a variant with the destination on top instead of the source, see
    /// [dstATop].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_srcATop.png)
    case srcATop

    /// Composite the destination image over the source image, but only where it
    /// overlaps the source.
    ///
    /// This corresponds to the "Destination atop Source" Porter-Duff operator.
    ///
    /// This is essentially the [dstOver] operator, but with the output's opacity
    /// channel being set to that of the source image instead of being a
    /// combination of both image's opacity channels.
    ///
    /// For a variant with the source on top instead of the destination, see
    /// [srcATop].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_dstATop.png)
    case dstATop

    /// Apply a bitwise `xor` operator to the source and destination images. This
    /// leaves transparency where they would overlap.
    ///
    /// This corresponds to the "Source xor Destination" Porter-Duff operator.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_xor.png)
    case xor

    /// Sum the components of the source and destination images.
    ///
    /// Transparency in a pixel of one of the images reduces the contribution of
    /// that image to the corresponding output pixel, as if the color of that
    /// pixel in that image was darker.
    ///
    /// This corresponds to the "Source plus Destination" Porter-Duff operator.
    ///
    /// This is the right blend mode for cross-fading between two images. Consider
    /// two images A and B, and an interpolation time variable _t_ (from 0.0 to
    /// 1.0). To cross fade between them, A should be drawn with opacity 1.0 - _t_
    /// into a new layer using [BlendMode.srcOver], and B should be drawn on top
    /// of it, at opacity _t_, into the same layer, using [BlendMode.plus].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_plus.png)
    case plus

    /// Multiply the color components of the source and destination images.
    ///
    /// This can only result in the same or darker colors (multiplying by white,
    /// 1.0, results in no change; multiplying by black, 0.0, results in black).
    ///
    /// When compositing two opaque images, this has similar effect to overlapping
    /// two transparencies on a projector.
    ///
    /// For a variant that also multiplies the alpha channel, consider [multiply].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_modulate.png)
    ///
    /// See also:
    ///
    ///  * [screen], which does a similar computation but inverted.
    ///  * [overlay], which combines [modulate] and [screen] to favor the
    ///    destination image.
    ///  * [hardLight], which combines [modulate] and [screen] to favor the
    ///    source image.
    case modulate

    // Following blend modes are defined in the CSS Compositing standard.

    /// Multiply the inverse of the components of the source and destination
    /// images, and inverse the result.
    ///
    /// Inverting the components means that a fully saturated channel (opaque
    /// white) is treated as the value 0.0, and values normally treated as 0.0
    /// (black, transparent) are treated as 1.0.
    ///
    /// This is essentially the same as [modulate] blend mode, but with the values
    /// of the colors inverted before the multiplication and the result being
    /// inverted back before rendering.
    ///
    /// This can only result in the same or lighter colors (multiplying by black,
    /// 1.0, results in no change; multiplying by white, 0.0, results in white).
    /// Similarly, in the alpha channel, it can only result in more opaque colors.
    ///
    /// This has similar effect to two projectors displaying their images on the
    /// same screen simultaneously.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_screen.png)
    ///
    /// See also:
    ///
    ///  * [modulate], which does a similar computation but without inverting the
    ///    values.
    ///  * [overlay], which combines [modulate] and [screen] to favor the
    ///    destination image.
    ///  * [hardLight], which combines [modulate] and [screen] to favor the
    ///    source image.
    case screen  // The last coeff mode.

    /// Multiply the components of the source and destination images after
    /// adjusting them to favor the destination.
    ///
    /// Specifically, if the destination value is smaller, this multiplies it with
    /// the source value, whereas is the source value is smaller, it multiplies
    /// the inverse of the source value with the inverse of the destination value,
    /// then inverts the result.
    ///
    /// Inverting the components means that a fully saturated channel (opaque
    /// white) is treated as the value 0.0, and values normally treated as 0.0
    /// (black, transparent) are treated as 1.0.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_overlay.png)
    ///
    /// See also:
    ///
    ///  * [modulate], which always multiplies the values.
    ///  * [screen], which always multiplies the inverses of the values.
    ///  * [hardLight], which is similar to [overlay] but favors the source image
    ///    instead of the destination image.
    case overlay

    /// Composite the source and destination image by choosing the lowest value
    /// from each color channel.
    ///
    /// The opacity of the output image is computed in the same way as for
    /// [srcOver].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_darken.png)
    case darken

    /// Composite the source and destination image by choosing the highest value
    /// from each color channel.
    ///
    /// The opacity of the output image is computed in the same way as for
    /// [srcOver].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_lighten.png)
    case lighten

    /// Divide the destination by the inverse of the source.
    ///
    /// Inverting the components means that a fully saturated channel (opaque
    /// white) is treated as the value 0.0, and values normally treated as 0.0
    /// (black, transparent) are treated as 1.0.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_colorDodge.png)
    case colorDodge

    /// Divide the inverse of the destination by the source, and inverse the result.
    ///
    /// Inverting the components means that a fully saturated channel (opaque
    /// white) is treated as the value 0.0, and values normally treated as 0.0
    /// (black, transparent) are treated as 1.0.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_colorBurn.png)
    case colorBurn

    /// Multiply the components of the source and destination images after
    /// adjusting them to favor the source.
    ///
    /// Specifically, if the source value is smaller, this multiplies it with the
    /// destination value, whereas is the destination value is smaller, it
    /// multiplies the inverse of the destination value with the inverse of the
    /// source value, then inverts the result.
    ///
    /// Inverting the components means that a fully saturated channel (opaque
    /// white) is treated as the value 0.0, and values normally treated as 0.0
    /// (black, transparent) are treated as 1.0.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_hardLight.png)
    ///
    /// See also:
    ///
    ///  * [modulate], which always multiplies the values.
    ///  * [screen], which always multiplies the inverses of the values.
    ///  * [overlay], which is similar to [hardLight] but favors the destination
    ///    image instead of the source image.
    case hardLight

    /// Use [colorDodge] for source values below 0.5 and [colorBurn] for source
    /// values above 0.5.
    ///
    /// This results in a similar but softer effect than [overlay].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_softLight.png)
    ///
    /// See also:
    ///
    ///  * [color], which is a more subtle tinting effect.
    case softLight

    /// Subtract the smaller value from the bigger value for each channel.
    ///
    /// Compositing black has no effect; compositing white inverts the colors of
    /// the other image.
    ///
    /// The opacity of the output image is computed in the same way as for
    /// [srcOver].
    ///
    /// The effect is similar to [exclusion] but harsher.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_difference.png)
    case difference

    /// Subtract double the product of the two images from the sum of the two
    /// images.
    ///
    /// Compositing black has no effect; compositing white inverts the colors of
    /// the other image.
    ///
    /// The opacity of the output image is computed in the same way as for
    /// [srcOver].
    ///
    /// The effect is similar to [difference] but softer.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_exclusion.png)
    case exclusion

    /// Multiply the components of the source and destination images, including
    /// the alpha channel.
    ///
    /// This can only result in the same or darker colors (multiplying by white,
    /// 1.0, results in no change; multiplying by black, 0.0, results in black).
    ///
    /// Since the alpha channel is also multiplied, a fully-transparent pixel
    /// (opacity 0.0) in one image results in a fully transparent pixel in the
    /// output. This is similar to [dstIn], but with the colors combined.
    ///
    /// For a variant that multiplies the colors but does not multiply the alpha
    /// channel, consider [modulate].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_multiply.png)
    case multiply  // The last separable mode.

    /// Take the hue of the source image, and the saturation and luminosity of
    /// the destination image.
    ///
    /// The effect is to tint the destination image with the source image.
    ///
    /// The opacity of the output image is computed in the same way as for
    /// [srcOver]. Regions that are entirely transparent in the source image
    /// take their hue from the destination.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_hue.png)
    ///
    /// See also:
    ///
    ///  * [color], which is a similar but stronger effect as it also applies
    ///    the saturation of the source image.
    ///  * [HSVColor], which allows colors to be expressed using Hue rather than
    ///    the red/green/blue channels of [Color].
    case hue

    /// Take the saturation of the source image, and the hue and luminosity of the
    /// destination image.
    ///
    /// The opacity of the output image is computed in the same way as for
    /// [srcOver]. Regions that are entirely transparent in the source image take
    /// their saturation from the destination.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_hue.png)
    ///
    /// See also:
    ///
    ///  * [color], which also applies the hue of the source image.
    ///  * [luminosity], which applies the luminosity of the source image to the
    ///    destination.
    case saturation

    /// Take the hue and saturation of the source image, and the luminosity of the
    /// destination image.
    ///
    /// The effect is to tint the destination image with the source image.
    ///
    /// The opacity of the output image is computed in the same way as for
    /// [srcOver]. Regions that are entirely transparent in the source image take
    /// their hue and saturation from the destination.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_color.png)
    ///
    /// See also:
    ///
    ///  * [hue], which is a similar but weaker effect.
    ///  * [softLight], which is a similar tinting effect but also tints white.
    ///  * [saturation], which only applies the saturation of the source image.
    case color

    /// Take the luminosity of the source image, and the hue and saturation of the
    /// destination image.
    ///
    /// The opacity of the output image is computed in the same way as for
    /// [srcOver]. Regions that are entirely transparent in the source image take
    /// their luminosity from the destination.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/blend_mode_luminosity.png)
    ///
    /// See also:
    ///
    ///  * [saturation], which applies the saturation of the source image to the
    ///    destination.
    ///  * [ImageFilter.blur], which can be used with [BackdropFilter] for a
    ///    related effect.
    case luminosity
}

/// Styles to use for blurs in [MaskFilter] objects.
// These enum values must be kept in sync with DlBlurStyle.
public enum BlurStyle {
    /// Fuzzy inside and outside. This is useful for painting shadows that are
    /// offset from the shape that ostensibly is casting the shadow.
    case normal

    /// Solid inside, fuzzy outside. This corresponds to drawing the shape, and
    /// additionally drawing the blur. This can make objects appear brighter,
    /// maybe even as if they were fluorescent.
    case solid

    /// Nothing inside, fuzzy outside. This is useful for painting shadows for
    /// partially transparent shapes, when they are painted separately but without
    /// an offset, so that the shadow doesn't paint below the shape.
    case outer

    /// Fuzzy inside, nothing outside. This can make shapes appear to be lit from
    /// within.
    case inner
}

/// An immutable 32 bit color value in ARGB format.
public struct Color: Hashable {
    public init(_ value: UInt32) {
        self.value = value
    }

    /// Construct a color from the lower 8 bits of four integers.
    ///
    /// * `a` is the alpha value, with 0 being transparent and 255 being fully
    ///   opaque.
    /// * `r` is [red], from 0 to 255.
    /// * `g` is [green], from 0 to 255.
    /// * `b` is [blue], from 0 to 255.
    ///
    /// Out of range values are brought into range using modulo 255.
    ///
    /// See also [fromRGBO], which takes the alpha value as a floating point
    /// value.
    public static func argb(_ a: UInt8, _ r: UInt8, _ g: UInt8, _ b: UInt8) -> Color {
        Color(
            ((UInt32(a) & 0xff) << 24)
                | ((UInt32(r) & 0xff) << 16)
                | ((UInt32(g) & 0xff) << 8)
                | ((UInt32(b) & 0xff) << 0)
        )
    }

    /// Create a color from red, green, blue, and opacity, similar to `rgba()` in CSS.
    ///
    /// * `r` is [red], from 0 to 255.
    /// * `g` is [green], from 0 to 255.
    /// * `b` is [blue], from 0 to 255.
    /// * `opacity` is alpha channel of this color as a double, with 0.0 being
    ///   transparent and 1.0 being fully opaque.
    ///
    /// Out of range values are brought into range using modulo 255.
    ///
    /// See also [fromARGB], which takes the opacity as an integer value.
    public static func rgbo(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ opacity: Float) -> Color {
        Color(
            ((UInt32((opacity * 0xff).rounded()) & 0xff) << 24)
                | ((UInt32(r) & 0xff) << 16)
                | ((UInt32(g) & 0xff) << 8)
                | ((UInt32(b) & 0xff) << 0)
        )
    }

    public static func random(solid: Bool = false) -> Color {
        Color.argb(
            solid ? 255 : .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255),
            .random(in: 0...255)
        )
    }

    /// A 32 bit value representing this color.
    ///
    /// * Bits 24-31 are the alpha value.
    /// * Bits 16-23 are the red value.
    /// * Bits 8-15 are the green value.
    /// * Bits 0-7 are the blue value.
    public var value: UInt32

    /// The alpha channel of this color in an 8 bit value.
    ///
    /// A value of 0 means this color is fully transparent. A value of 255 means
    /// this color is fully opaque.
    public var alpha: UInt8 {
        UInt8((value >> 24) & 0xff)
    }

    /// The red channel of this color in an 8 bit value.
    public var red: UInt8 {
        UInt8((value >> 16) & 0xff)
    }

    /// The green channel of this color in an 8 bit value.
    public var green: UInt8 {
        UInt8((value >> 8) & 0xff)
    }

    /// The blue channel of this color in an 8 bit value.
    public var blue: UInt8 {
        UInt8(value & 0xff)
    }

    /// Returns a new color that matches this color with the alpha channel
    /// replaced with `a` (which ranges from 0 to 255).
    ///
    /// Out of range values will have unexpected effects.
    public func withAlpha(_ a: UInt8) -> Color {
        Color.argb(a, red, green, blue)
    }

    /// Returns a new color that matches this color with the alpha channel
    /// replaced with the given `opacity` (which ranges from 0.0 to 1.0).
    ///
    /// Out of range values will have unexpected effects.
    public func withOpacity(_ opacity: Float) -> Self {
        assert(opacity >= 0.0 && opacity <= 1.0)
        return withAlpha(UInt8((255.0 * opacity).rounded()))
    }

    /// Returns a new color that matches this color with the red channel replaced
    /// with `r` (which ranges from 0 to 255).
    ///
    /// Out of range values will have unexpected effects.
    public func withRed(_ r: UInt8) -> Self {
        return Self.argb(alpha, r, green, blue)
    }

    /// Returns a new color that matches this color with the green channel
    /// replaced with `g` (which ranges from 0 to 255).
    ///
    /// Out of range values will have unexpected effects.
    public func withGreen(_ g: UInt8) -> Self {
        return Self.argb(alpha, red, g, blue)
    }

    /// Returns a new color that matches this color with the blue channel replaced
    /// with `b` (which ranges from 0 to 255).
    ///
    /// Out of range values will have unexpected effects.
    public func withBlue(_ b: UInt8) -> Self {
        return Self.argb(alpha, red, green, b)
    }

    /// Linearly interpolate between two colors.
    ///
    /// This is intended to be fast but as a result may be ugly. Consider
    /// [HSVColor] or writing custom logic for interpolating colors.
    ///
    /// If either color is null, this function linearly interpolates from a
    /// transparent instance of the other color. This is usually preferable to
    /// interpolating from [material.Colors.transparent] (`const
    /// Color(0x00000000)`), which is specifically transparent _black_.
    ///
    /// The `t` argument represents position on the timeline, with 0.0 meaning
    /// that the interpolation has not started, returning `a` (or something
    /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
    /// returning `b` (or something equivalent to `b`), and values in between
    /// meaning that the interpolation is at the relevant point on the timeline
    /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
    /// 1.0, so negative values and values greater than 1.0 are valid (and can
    /// easily be generated by curves such as [Curves.elasticInOut]). Each channel
    /// will be clamped to the range 0 to 255.
    ///
    /// Values for `t` are usually obtained from an [Animation<double>], such as
    /// an [AnimationController].
    public static func lerp(_ a: Color?, _ b: Color?, _ t: Float) -> Color? {
        guard let b else {
            guard let a else {
                return nil
            }
            return scaleAlpha(a, 1.0 - t)
        }
        guard let a else {
            return scaleAlpha(b, t)
        }
        return Color.argb(
            UInt8(clampInt(Int(lerpInt(a.alpha, b.alpha, t: t)), 0, 255)),
            UInt8(clampInt(Int(lerpInt(a.red, b.red, t: t)), 0, 255)),
            UInt8(clampInt(Int(lerpInt(a.green, b.green, t: t)), 0, 255)),
            UInt8(clampInt(Int(lerpInt(a.blue, b.blue, t: t)), 0, 255))
        )
    }
}

/// Different ways to clip a widget's content.
public enum Clip {
    /// No clip at all.
    ///
    /// This is the default option for most widgets: if the content does not
    /// overflow the widget boundary, don't pay any performance cost for clipping.
    ///
    /// If the content does overflow, please explicitly specify the following
    /// [Clip] options:
    ///  * [hardEdge], which is the fastest clipping, but with lower fidelity.
    ///  * [antiAlias], which is a little slower than [hardEdge], but with smoothed edges.
    ///  * [antiAliasWithSaveLayer], which is much slower than [antiAlias], and should
    ///    rarely be used.
    case none

    /// Clip, but do not apply anti-aliasing.
    ///
    /// This mode enables clipping, but curves and non-axis-aligned straight lines will be
    /// jagged as no effort is made to anti-alias.
    ///
    /// Faster than other clipping modes, but slower than [none].
    ///
    /// This is a reasonable choice when clipping is needed, if the container is an axis-
    /// aligned rectangle or an axis-aligned rounded rectangle with very small corner radii.
    ///
    /// See also:
    ///
    ///  * [antiAlias], which is more reasonable when clipping is needed and the shape is not
    ///    an axis-aligned rectangle.
    case hardEdge

    /// Clip with anti-aliasing.
    ///
    /// This mode has anti-aliased clipping edges to achieve a smoother look.
    ///
    /// It' s much faster than [antiAliasWithSaveLayer], but slower than [hardEdge].
    ///
    /// This will be the common case when dealing with circles and arcs.
    ///
    /// Different from [hardEdge] and [antiAliasWithSaveLayer], this clipping may have
    /// bleeding edge artifacts.
    /// (See https://fiddle.skia.org/c/21cb4c2b2515996b537f36e7819288ae for an example.)
    ///
    /// See also:
    ///
    ///  * [hardEdge], which is a little faster, but with lower fidelity.
    ///  * [antiAliasWithSaveLayer], which is much slower, but can avoid the
    ///    bleeding edges if there's no other way.
    ///  * [Paint.isAntiAlias], which is the anti-aliasing switch for general draw operations.
    case antiAlias

    /// Clip with anti-aliasing and saveLayer immediately following the clip.
    ///
    /// This mode not only clips with anti-aliasing, but also allocates an offscreen
    /// buffer. All subsequent paints are carried out on that buffer before finally
    /// being clipped and composited back.
    ///
    /// This is very slow. It has no bleeding edge artifacts (that [antiAlias] has)
    /// but it changes the semantics as an offscreen buffer is now introduced.
    /// (See https://github.com/flutter/flutter/issues/18057#issuecomment-394197336
    /// for a difference between paint without saveLayer and paint with saveLayer.)
    ///
    /// This will be only rarely needed. One case where you might need this is if
    /// you have an image overlaid on a very different background color. In these
    /// cases, consider whether you can avoid overlaying multiple colors in one
    /// spot (e.g. by having the background color only present where the image is
    /// absent). If you can, [antiAlias] would be fine and much faster.
    ///
    /// See also:
    ///
    ///  * [antiAlias], which is much faster, and has similar clipping results.
    case antiAliasWithSaveLayer
}

/// Quality levels for image sampling in [ImageFilter] and [Shader] objects that sample
/// images and for [Canvas] operations that render images.
///
/// When scaling up typically the quality is lowest at [none], higher at [low] and [medium],
/// and for very large scale factors (over 10x) the highest at [high].
///
/// When scaling down, [medium] provides the best quality especially when scaling an
/// image to less than half its size or for animating the scale factor between such
/// reductions. Otherwise, [low] and [high] provide similar effects for reductions of
/// between 50% and 100% but the image may lose detail and have dropouts below 50%.
///
/// To get high quality when scaling images up and down, or when the scale is
/// unknown, [medium] is typically a good balanced choice.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/filter_quality.png)
///
/// When building for the web using the `--web-renderer=html` option, filter
/// quality has no effect. All images are rendered using the respective
/// browser's default setting.
///
/// See also:
///
///  * [Paint.filterQuality], which is used to pass [FilterQuality] to the
///    engine while using drawImage calls on a [Canvas].
///  * [ImageShader].
///  * [ImageFilter.matrix].
///  * [Canvas.drawImage].
///  * [Canvas.drawImageRect].
///  * [Canvas.drawImageNine].
///  * [Canvas.drawAtlas].
public enum FilterQuality {
    // This list and the values (order) should be kept in sync with the equivalent list
    // in lib/ui/painting/image_filter.cc

    /// The fastest filtering method, albeit also the lowest quality.
    ///
    /// This value results in a "Nearest Neighbor" algorithm which just
    /// repeats or eliminates pixels as an image is scaled up or down.
    case none

    /// Better quality than [none], faster than [medium].
    ///
    /// This value results in a "Bilinear" algorithm which smoothly
    /// interpolates between pixels in an image.
    case low

    /// The best all around filtering method that is only worse than [high]
    /// at extremely large scale factors.
    ///
    /// This value improves upon the "Bilinear" algorithm specified by [low]
    /// by utilizing a Mipmap that pre-computes high quality lower resolutions
    /// of the image at half (and quarter and eighth, etc.) sizes and then
    /// blends between those to prevent loss of detail at small scale sizes.
    case medium

    /// Best possible quality when scaling up images by scale factors larger than
    /// 5-10x.
    ///
    /// When images are scaled down, this can be worse than [medium] for scales
    /// smaller than 0.5x, or when animating the scale factor.
    ///
    /// This option is also the slowest.
    ///
    /// This value results in a standard "Bicubic" algorithm which uses a 3rd order
    /// equation to smooth the abrupt transitions between pixels while preserving
    /// some of the sense of an edge and avoiding sharp peaks in the result.
    case high
}

/// A mask filter to apply to shapes as they are painted. A mask filter is a
/// function that takes a bitmap of color pixels, and returns another bitmap of
/// color pixels.
///
/// Instances of this class are used with [Paint.maskFilter] on [Paint] objects.
/// A blur is an expensive operation and should therefore be used sparingly.
public struct MaskFilter: Equatable {
    /// Creates a mask filter that takes the shape being drawn and blurs it.
    ///
    /// This is commonly used to approximate shadows.
    ///
    /// The `style` argument controls the kind of effect to draw; see [BlurStyle].
    ///
    /// The `sigma` argument controls the size of the effect. It is the standard
    /// deviation of the Gaussian blur to apply. The value must be greater than
    /// zero. The sigma corresponds to very roughly half the radius of the effect
    /// in pixels.
    ///
    /// A blur is an expensive operation and should therefore be used sparingly.
    public init(style: BlurStyle, sigma: Float) {
        self.style = style
        self.sigma = sigma
    }

    /// Controls the kind of effect to draw; see [BlurStyle].
    public let style: BlurStyle

    /// Controls the size of the effect. It is the standard
    /// deviation of the Gaussian blur to apply. The value must be greater than
    /// zero. The sigma corresponds to very roughly half the radius of the effect
    /// in pixels.
    public let sigma: Float
}

/// Strategies for painting shapes and paths on a canvas.
///
/// See [Paint.style].
// These enum values must be kept in sync with DlDrawStyle.
public enum PaintingStyle {
    // This list comes from dl_paint.h and the values (order) should be kept
    // in sync.

    /// Apply the [Paint] to the inside of the shape. For example, when
    /// applied to the [Canvas.drawCircle] call, this results in a disc
    /// of the given size being painted.
    case fill

    /// Apply the [Paint] to the edge of the shape. For example, when
    /// applied to the [Canvas.drawCircle] call, this results is a hoop
    /// of the given size being painted. The line drawn on the edge will
    /// be the width given by the [Paint.strokeWidth] property.
    case stroke
}

private enum PaintOffset: Int, CaseIterable {
    case color = 0
}

public struct Paint: Equatable {
    public init() {}

    /// Whether to apply anti-aliasing to lines and images drawn on the
    /// canvas.
    ///
    /// Defaults to true.
    public var isAntiAlias: Bool = true

    /// The color to use when stroking or filling a shape.
    ///
    /// Defaults to opaque black.
    public var color: Color = Color(0xFF00_0000)

    /// A blend mode to apply when a shape is drawn or a layer is composited.
    ///
    /// The source colors are from the shape being drawn (e.g. from
    /// [Canvas.drawPath]) or layer being composited (the graphics that were
    /// drawn between the [Canvas.saveLayer] and [Canvas.restore] calls), after
    /// applying the [colorFilter], if any.
    ///
    /// The destination colors are from the background onto which the shape or
    /// layer is being composited.
    ///
    /// Defaults to [BlendMode.srcOver].
    public var blendMode: BlendMode = .srcOver

    /// Whether to paint inside shapes, the edges of shapes, or both.
    ///
    /// Defaults to [PaintingStyle.fill].
    public var style: PaintingStyle = .fill

    /// How wide to make edges drawn when [style] is set to
    /// [PaintingStyle.stroke]. The width is given in logical pixels measured in
    /// the direction orthogonal to the direction of the path.
    ///
    /// Defaults to 0.0, which correspond to a hairline width.
    public var strokeWidth: Float = 0.0

    /// The kind of finish to place on the end of lines drawn when
    /// [style] is set to [PaintingStyle.stroke].
    ///
    /// Defaults to [StrokeCap.butt], i.e. no caps.
    public var strokeCap: StrokeCap = .butt

    /// The kind of finish to place on the joins between segments.
    ///
    /// This applies to paths drawn when [style] is set to [PaintingStyle.stroke],
    /// It does not apply to points drawn as lines with [Canvas.drawPoints].
    ///
    /// Defaults to [StrokeJoin.miter], i.e. sharp corners.
    public var strokeJoin: StrokeJoin = .miter

    /// The limit for miters to be drawn on segments when the join is set to
    /// [StrokeJoin.miter] and the [style] is set to [PaintingStyle.stroke]. If
    /// this limit is exceeded, then a [StrokeJoin.bevel] join will be drawn
    /// instead. This may cause some 'popping' of the corners of a path if the
    /// angle between line segments is animated, as seen in the diagrams below.
    ///
    /// This limit is expressed as a limit on the length of the miter.
    ///
    /// Defaults to 4.0.  Using zero as a limit will cause a [StrokeJoin.bevel]
    /// join to be used all the time.
    public var strokeMiterLimit: Float = 4.0

    /// A mask filter (for example, a blur) to apply to a shape after it has been
    /// drawn but before it has been composited into the image.
    public var maskFilter: MaskFilter?

    /// Controls the performance vs quality trade-off to use when sampling bitmaps,
    /// as with an [ImageShader], or when drawing images, as with [Canvas.drawImage],
    /// [Canvas.drawImageRect], [Canvas.drawImageNine] or [Canvas.drawAtlas].
    ///
    /// Defaults to [FilterQuality.none].
    public var filterQuality: FilterQuality = .none

    /// The shader to use when stroking or filling a shape.
    ///
    /// When this is null, the [color] is used instead.
    // public var shader: Shader?

    /// A color filter to apply when a shape is drawn or when a layer is
    /// composited.
    ///
    /// See [ColorFilter] for details.
    // public var colorFilter: ColorFilter?

    /// The [ImageFilter] to use when drawing raster images.
    ///
    /// For example, to blur an image using [Canvas.drawImage], apply an
    /// [ImageFilter.blur]:
    // public var imageFilter: ImageFilter?
}

/// A single shadow.
///
/// Multiple shadows are stacked together in a [TextStyle].
public struct Shadow: Equatable {
    /// Construct a shadow.
    ///
    /// The default shadow is a black shadow with zero offset and zero blur.
    /// Default shadows should be completely covered by the casting element,
    /// and not be visible.
    ///
    /// Transparency should be adjusted through the [color] alpha.
    ///
    /// Shadow order matters due to compositing multiple translucent objects not
    /// being commutative.
    internal init(
        color: Color = kColorDefault,
        offset: Offset = Offset.zero,
        blurRadius: Double = 0.0
    ) {
        self.color = color
        self.offset = offset
        self.blurRadius = blurRadius
    }

    private static let kColorDefault = Color(0xFF00_0000)

    /// Color that the shadow will be drawn with.
    ///
    /// The shadows are shapes composited directly over the base canvas, and do not
    /// represent optical occlusion.
    public let color: Color

    /// The displacement of the shadow from the casting element.
    ///
    /// Positive x/y offsets will shift the shadow to the right and down, while
    /// negative offsets shift the shadow to the left and up. The offsets are
    /// relative to the position of the element that is casting it.
    public let offset: Offset

    /// The standard deviation of the Gaussian to convolve with the shadow's shape.
    public let blurRadius: Double

    /// Converts a blur radius in pixels to sigmas.
    ///
    /// See the sigma argument to [MaskFilter.blur].
    ///
    // See SkBlurMask::ConvertRadiusToSigma().
    // <https://github.com/google/skia/blob/bb5b77db51d2e149ee66db284903572a5aac09be/src/effects/SkBlurMask.cpp#L23>
    public static func convertRadiusToSigma(radius: Double) -> Double {
        return radius > 0 ? radius * 0.57735 + 0.5 : 0
    }

    /// The [blurRadius] in sigmas instead of logical pixels.
    ///
    /// See the sigma argument to [MaskFilter.blur].
    public var blurSigma: Double { Self.convertRadiusToSigma(radius: blurRadius) }
}

/// Styles to use for line endings.
///
/// See also:
///
///  * [Paint.strokeCap] for how this value is used.
///  * [StrokeJoin] for the different kinds of line segment joins.
// These enum values must be kept in sync with DlStrokeCap.
public enum StrokeCap {
    /// Begin and end contours with a flat edge and no extension.
    ///
    /// ![A butt cap ends line segments with a square end that stops at the end
    /// of the line
    /// segment.](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/butt_cap.png)
    ///
    /// Compare to the [square] cap, which has the same shape, but extends past
    /// the end of the line by half a stroke width.
    case butt

    /// Begin and end contours with a semi-circle extension.
    ///
    /// ![A round cap adds a rounded end to the line segment that protrudes by
    /// one half of the thickness of the line (which is the radius of the cap)
    /// past the end of the
    /// segment.](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/round_cap.png)
    ///
    /// The cap is colored in the diagram above to highlight it: in normal use
    /// it is the same color as the line.
    case round

    /// Begin and end contours with a half square extension. This is similar to
    /// extending each contour by half the stroke width (as given by
    /// [Paint.strokeWidth]).
    ///
    /// ![A square cap has a square end that effectively extends the line length
    /// by half of the stroke
    /// width.](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/square_cap.png)
    ///
    /// The cap is colored in the diagram above to highlight it: in normal use
    /// it is the same color as the line.
    ///
    /// Compare to the [butt] cap, which has the same shape, but doesn't extend
    /// past the end of the line.
    case square
}

/// Styles to use for line segment joins.
///
/// This only affects line joins for polygons drawn by [Canvas.drawPath] and
/// rectangles, not points drawn as lines with [Canvas.drawPoints].
///
/// See also:
///
/// * [Paint.strokeJoin] and [Paint.strokeMiterLimit] for how this value is
///   used.
/// * [StrokeCap] for the different kinds of line endings.
// These enum values must be kept in sync with DlStrokeJoin.
public enum StrokeJoin {
    /// Joins between line segments form sharp corners.
    ///
    /// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/dart-ui/miter_4_join.mp4}
    ///
    /// The center of the line segment is colored in the diagram above to
    /// highlight the join, but in normal usage the join is the same color as
    /// the line.
    ///
    /// See also:
    ///
    ///   * [Paint.strokeJoin], used to set the line segment join style to this
    ///     value.
    ///   * [Paint.strokeMiterLimit], used to define when a miter is drawn
    ///     instead of a bevel when the join is set to this value.
    case miter

    /// Joins between line segments are semi-circular.
    ///
    /// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/dart-ui/round_join.mp4}
    ///
    /// The center of the line segment is colored in the diagram above to
    /// highlight the join, but in normal usage the join is the same color as
    /// the line.
    ///
    /// See also:
    ///
    ///   * [Paint.strokeJoin], used to set the line segment join style to this
    ///     value.
    case round

    /// Joins between line segments connect the corners of the butt ends of the
    /// line segments to give a beveled appearance.
    ///
    /// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/dart-ui/bevel_join.mp4}
    ///
    /// The center of the line segment is colored in the diagram above to
    /// highlight the join, but in normal usage the join is the same color as
    /// the line.
    ///
    /// See also:
    ///
    ///   * [Paint.strokeJoin], used to set the line segment join style to this
    ///     value.
    case bevel
}

/// A handle to a loaded image.
public protocol AnimatedImage: AnyObject {
    /// Number of frames in this image.
    var frameCount: UInt { get }

    /// Number of times to repeat the animation.
    ///
    /// * 0 when the animation should be played once.
    /// * nil for infinity repetitions.
    var repetitionCount: UInt? { get }

    /// Fetches the next animation frame.
    ///
    /// Wraps back to the first frame after returning the last frame.
    ///
    /// Returns nil if there is an error decoding the image.
    func getNextFrame() -> FrameInfo?
}

/// Information for a single frame of an animation.
///
/// To obtain an instance of the [FrameInfo] interface, see
/// [AnimatedImage.getNextFrame].
public struct FrameInfo {
    public init(duration: Duration?, image: NativeImage) {
        self.duration = duration
        self.image = image
    }

    /// The duration this frame should be shown.
    ///
    /// A nil duration indicates that the frame should be shown indefinitely.
    public let duration: Duration?

    /// The [Image] object for this frame.
    ///
    /// This object must be disposed by the recipient of this frame info.
    ///
    /// To share this image with other interested parties, use [Image.clone].
    public let image: NativeImage
}

/// Opaque handle to a decoded image that the renderer can use to draw
/// immidiately. The image can potentially live on the GPU memory based on the
/// renderer implementation.
public protocol NativeImage: AnyObject {
    /// The number of image pixels along the image's horizontal axis.
    var width: UInt { get }

    /// The number of image pixels along the image's vertical axis.
    var height: UInt { get }
}

/// A complex, one-dimensional subset of a plane.
///
/// A path consists of a number of sub-paths, and a _current point_.
///
/// Sub-paths consist of segments of various types, such as lines,
/// arcs, or beziers. Sub-paths can be open or closed, and can
/// self-intersect.
///
/// Closed sub-paths enclose a (possibly discontiguous) region of the
/// plane based on the current [fillType].
///
/// The _current point_ is initially at the origin. After each
/// operation adding a segment to a sub-path, the current point is
/// updated to the end of that segment.
///
/// Paths can be drawn on canvases using [Canvas.drawPath], and can
/// used to create clip regions using [Canvas.clipPath].
public protocol Path {

    /// Determines how the interior of this path is calculated.
    ///
    /// Defaults to the non-zero winding rule, [PathFillType.nonZero].
    // var fillType: PathFillType { get set }

    /// Starts a new sub-path at the given coordinate.
    func moveTo(_ x: Float, _ y: Float)

    /// Starts a new sub-path at the given offset from the current point.
    // func relativeMoveTo(_ dx: Float, _ dy: Float)

    /// Adds a straight line segment from the current point to the given
    /// point.
    func lineTo(_ x: Float, _ y: Float)

    /// Adds a straight line segment from the current point to the point
    /// at the given offset from the current point.
    // func relativeLineTo(_ dx: Float, _ dy: Float)

    /// Adds a quadratic bezier segment that curves from the current
    /// point to the given point (x2,y2), using the control point
    /// (x1,y1).
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/path_quadratic_to.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/path_quadratic_to_dark.png#gh-dark-mode-only)
    // func quadraticBezierTo(_ x1: Float, _ y1: Float, _ x2: Float, _ y2: Float)

    /// Adds a quadratic bezier segment that curves from the current
    /// point to the point at the offset (x2,y2) from the current point,
    /// using the control point at the offset (x1,y1) from the current
    /// point.
    // func relativeQuadraticBezierTo(_ x1: Float, _ y1: Float, _ x2: Float, _ y2: Float)

    /// Adds a cubic bezier segment that curves from the current point
    /// to the given point (x3,y3), using the control points (x1,y1) and
    /// (x2,y2).
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/path_cubic_to.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/path_cubic_to_dark.png#gh-dark-mode-only)
    // func cubicTo(_ x1: Float, _ y1: Float, _ x2: Float, _ y2: Float, _ x3: Float, _ y3: Float)

    /// Adds a cubic bezier segment that curves from the current point
    /// to the point at the offset (x3,y3) from the current point, using
    /// the control points at the offsets (x1,y1) and (x2,y2) from the
    /// current point.
    // func relativeCubicTo(
    //     _ x1: Float,
    //     _ y1: Float,
    //     _ x2: Float,
    //     _ y2: Float,
    //     _ x3: Float,
    //     _ y3: Float
    // )

    /// Adds a bezier segment that curves from the current point to the
    /// given point (x2,y2), using the control points (x1,y1) and the
    /// weight w. If the weight is greater than 1, then the curve is a
    /// hyperbola; if the weight equals 1, it's a parabola; and if it is
    /// less than 1, it is an ellipse.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/path_conic_to.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/path_conic_to_dark.png#gh-dark-mode-only)
    // func conicTo(_ x1: Float, _ y1: Float, _ x2: Float, _ y2: Float, _ w: Float)

    /// Adds a bezier segment that curves from the current point to the
    /// point at the offset (x2,y2) from the current point, using the
    /// control point at the offset (x1,y1) from the current point and
    /// the weight w. If the weight is greater than 1, then the curve is
    /// a hyperbola; if the weight equals 1, it's a parabola; and if it
    /// is less than 1, it is an ellipse.
    // func relativeConicTo(_ x1: Float, _ y1: Float, _ x2: Float, _ y2: Float, _ w: Float)

    /// If the `forceMoveTo` argument is false, adds a straight line
    /// segment and an arc segment.
    ///
    /// If the `forceMoveTo` argument is true, starts a new sub-path
    /// consisting of an arc segment.
    ///
    /// In either case, the arc segment consists of the arc that follows
    /// the edge of the oval bounded by the given rectangle, from
    /// startAngle radians around the oval up to startAngle + sweepAngle
    /// radians around the oval, with zero radians being the point on
    /// the right hand side of the oval that crosses the horizontal line
    /// that intersects the center of the rectangle and with positive
    /// angles going clockwise around the oval.
    ///
    /// The line segment added if `forceMoveTo` is false starts at the
    /// current point and ends at the start of the arc.
    // func arcTo(_ rect: Rect, _ startAngle: Float, _ sweepAngle: Float, _ forceMoveTo: Bool)
    /// Appends up to four conic curves weighted to describe an oval of `radius`
    /// and rotated by `rotation` (measured in degrees and clockwise).
    ///
    /// The first curve begins from the last point in the path and the last ends
    /// at `arcEnd`. The curves follow a path in a direction determined by
    /// `clockwise` and `largeArc` in such a way that the sweep angle
    /// is always less than 360 degrees.
    ///
    /// A simple line is appended if either radii are zero or the last
    /// point in the path is `arcEnd`. The radii are scaled to fit the last path
    /// point if both are greater than zero but too small to describe an arc.
    // func arcToPoint(
    //     _ arcEnd: Offset,
    //     radius: Radius,
    //     rotation: Float,
    //     largeArc: Bool,
    //     clockwise: Bool
    // )

    /// Appends up to four conic curves weighted to describe an oval of `radius`
    /// and rotated by `rotation` (measured in degrees and clockwise).
    ///
    /// The last path point is described by (px, py).
    ///
    /// The first curve begins from the last point in the path and the last ends
    /// at `arcEndDelta.dx + px` and `arcEndDelta.dy + py`. The curves follow a
    /// path in a direction determined by `clockwise` and `largeArc`
    /// in such a way that the sweep angle is always less than 360 degrees.
    ///
    /// A simple line is appended if either radii are zero, or, both
    /// `arcEndDelta.dx` and `arcEndDelta.dy` are zero. The radii are scaled to
    /// fit the last path point if both are greater than zero but too small to
    /// describe an arc.
    // func relativeArcToPoint(
    //     _ arcEndDelta: Offset,
    //     radius: Radius,
    //     rotation: Float,
    //     largeArc: Bool,
    //     clockwise: Bool
    // )

    /// Adds a new sub-path that consists of four lines that outline the
    /// given rectangle.
    // func addRect(_ rect: Rect)

    /// Adds a new sub-path that consists of a curve that forms the
    /// ellipse that fills the given rectangle.
    ///
    /// To add a circle, pass an appropriate rectangle as `oval`. [Rect.fromCircle]
    /// can be used to easily describe the circle's center [Offset] and radius.
    // func addOval(_ oval: Rect)

    /// Adds a new sub-path with one arc segment that consists of the arc
    /// that follows the edge of the oval bounded by the given
    /// rectangle, from startAngle radians around the oval up to
    /// startAngle + sweepAngle radians around the oval, with zero
    /// radians being the point on the right hand side of the oval that
    /// crosses the horizontal line that intersects the center of the
    /// rectangle and with positive angles going clockwise around the
    /// oval.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/path_add_arc.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/path_add_arc_dark.png#gh-dark-mode-only)
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/path_add_arc_ccw.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/path_add_arc_ccw_dark.png#gh-dark-mode-only)
    // func addArc(_ oval: Rect, _ startAngle: Float, _ sweepAngle: Float)

    /// Adds a new sub-path with a sequence of line segments that connect the given
    /// points.
    ///
    /// If `close` is true, a final line segment will be added that connects the
    /// last point to the first point.
    ///
    /// The `points` argument is interpreted as offsets from the origin.
    // func addPolygon(_ points: [Offset], _ close: Bool)

    /// Adds a new sub-path that consists of the straight lines and
    /// curves needed to form the rounded rectangle described by the
    /// argument.
    // func addRRect(_ rrect: RRect)

    /// Adds the sub-paths of `path`, offset by `offset`, to this path.
    ///
    /// If `matrix4` is specified, the path will be transformed by this matrix
    /// after the matrix is translated by the given offset. The matrix is a 4x4
    /// matrix stored in column major order.
    // func addPath(_ path: Path, _ offset: Offset, matrix4: [Float64]?)

    /// Adds the sub-paths of `path`, offset by `offset`, to this path.
    /// The current sub-path is extended with the first sub-path
    /// of `path`, connecting them with a lineTo if necessary.
    ///
    /// If `matrix4` is specified, the path will be transformed by this matrix
    /// after the matrix is translated by the given `offset`.  The matrix is a 4x4
    /// matrix stored in column major order.
    // func extendWithPath(_ path: Path, _ offset: Offset, matrix4: [Float64]?)

    /// Closes the last sub-path, as if a straight line had been drawn
    /// from the current point to the first point of the sub-path.
    // func close()

    /// Clears the [Path] object of all sub-paths, returning it to the
    /// same state it had when it was created. The _current point_ is
    /// reset to the origin.
    func reset()

    /// Tests to see if the given point is within the path. (That is, whether the
    /// point would be in the visible portion of the path if the path was used
    /// with [Canvas.clipPath].)
    ///
    /// The `point` argument is interpreted as an offset from the origin.
    ///
    /// Returns true if the point is in the path, and false otherwise.
    // func contains(_ point: Offset) -> Bool

    /// Returns a copy of the path with all the segments of every
    /// sub-path translated by the given offset.
    // func shift(_ offset: Offset) -> Path

    /// Returns a copy of the path with all the segments of every
    /// sub-path transformed by the given matrix.
    // func transform(_ matrix4: [Float64]) -> Path

    /// Computes the bounding rectangle for this path.
    ///
    /// A path containing only axis-aligned points on the same straight line will
    /// have no area, and therefore `Rect.isEmpty` will return true for such a
    /// path. Consider checking `rect.width + rect.height > 0.0` instead, or
    /// using the [computeMetrics] API to check the path length.
    ///
    /// For many more elaborate paths, the bounds may be inaccurate.  For example,
    /// when a path contains a circle, the points used to compute the bounds are
    /// the circle's implied control points, which form a square around the circle;
    /// if the circle has a transformation applied using [transform] then that
    /// square is rotated, and the (axis-aligned, non-rotated) bounding box
    /// therefore ends up grossly overestimating the actual area covered by the
    /// circle.
    // see https://skia.org/user/api/SkPath_Reference#SkPath_getBounds
    // func getBounds() -> Rect

    /// Creates a [PathMetrics] object for this path, which can describe various
    /// properties about the contours of the path.
    ///
    /// A [Path] is made up of zero or more contours. A contour is made up of
    /// connected curves and segments, created via methods like [lineTo],
    /// [cubicTo], [arcTo], [quadraticBezierTo], their relative counterparts, as
    /// well as the add* methods such as [addRect]. Creating a new [Path] starts
    /// a new contour once it has any drawing instructions, and another new
    /// contour is started for each [moveTo] instruction.
    ///
    /// A [PathMetric] object describes properties of an individual contour,
    /// such as its length, whether it is closed, what the tangent vector of a
    /// particular offset along the path is. It also provides a method for
    /// creating sub-paths: [PathMetric.extractPath].
    ///
    /// Calculating [PathMetric] objects is not trivial. The [PathMetrics] object
    /// returned by this method is a lazy [Iterable], meaning it only performs
    /// calculations when the iterator is moved to the next [PathMetric]. Callers
    /// that wish to memoize this iterable can easily do so by using
    /// [Iterable.toList] on the result of this method. In particular, callers
    /// looking for information about how many contours are in the path should
    /// either store the result of `path.computeMetrics().length`, or should use
    /// `path.computeMetrics().toList()` so they can repeatedly check the length,
    /// since calling `Iterable.length` causes traversal of the entire iterable.
    ///
    /// In particular, callers should be aware that [PathMetrics.length] is the
    /// number of contours, **not the length of the path**. To get the length of
    /// a contour in a path, use [PathMetric.length].
    ///
    /// If `forceClosed` is set to true, the contours of the path will be measured
    /// as if they had been closed, even if they were not explicitly closed.
    // func computeMetrics(forceClosed: Bool) -> PathMetrics
}

/// Determines the winding rule that decides how the interior of a [Path] is
/// calculated.
///
/// This enum is used by the [Path.fillType] property.
public enum PathFillType {
    /// The interior is defined by a non-zero sum of signed edge crossings.
    ///
    /// For a given point, the point is considered to be on the inside of the path
    /// if a line drawn from the point to infinity crosses lines going clockwise
    /// around the point a different number of times than it crosses lines going
    /// counter-clockwise around that point.
    ///
    /// See: <https://en.wikipedia.org/wiki/Nonzero-rule>
    case nonZero

    /// The interior is defined by an odd number of edge crossings.
    ///
    /// For a given point, the point is considered to be on the inside of the path
    /// if a line drawn from the point to infinity crosses an odd number of lines.
    ///
    /// See: <https://en.wikipedia.org/wiki/Even-odd_rule>
    case evenOdd
}

/// Strategies for combining paths.
///
/// See also:
///
/// * [Path.combine], which uses this enum to decide how to combine two paths.
// Must be kept in sync with SkPathOp
public enum PathOperation {
    /// Subtract the second path from the first path.
    ///
    /// For example, if the two paths are overlapping circles of equal diameter
    /// but differing centers, the result would be a crescent portion of the
    /// first circle that was not overlapped by the second circle.
    ///
    /// See also:
    ///
    ///  * [reverseDifference], which is the same but subtracting the first path
    ///    from the second.
    case difference

    /// Create a new path that is the intersection of the two paths, leaving the
    /// overlapping pieces of the path.
    ///
    /// For example, if the two paths are overlapping circles of equal diameter
    /// but differing centers, the result would be only the overlapping portion
    /// of the two circles.
    ///
    /// See also:
    ///  * [xor], which is the inverse of this operation
    case intersect

    /// Create a new path that is the union (inclusive-or) of the two paths.
    ///
    /// For example, if the two paths are overlapping circles of equal diameter
    /// but differing centers, the result would be a figure-eight like shape
    /// matching the outer boundaries of both circles.
    case union

    /// Create a new path that is the exclusive-or of the two paths, leaving
    /// everything but the overlapping pieces of the path.
    ///
    /// For example, if the two paths are overlapping circles of equal diameter
    /// but differing centers, the figure-eight like shape less the overlapping parts
    ///
    /// See also:
    ///  * [intersect], which is the inverse of this operation
    case xor

    /// Subtract the first path from the second path.
    ///
    /// For example, if the two paths are overlapping circles of equal diameter
    /// but differing centers, the result would be a crescent portion of the
    /// second circle that was not overlapped by the first circle.
    ///
    /// See also:
    ///
    ///  * [difference], which is the same but subtracting the second path
    ///    from the first.
    case reverseDifference
}
