// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CSkia
import CxxStdlib

extension Paint {
    func copyToSkia(paint: inout SkPaint) {
        paint.setAntiAlias(isAntiAlias)
        paint.setColor(color.value)
        // paint.setBlender(blender)
        paint.setBlendMode(blendMode.toSkia())
        paint.setStyle(style.toSkia())
        paint.setStrokeWidth(strokeWidth)
        paint.setStrokeCap(strokeCap.toSkia())
        paint.setStrokeJoin(strokeJoin.toSkia())
        paint.setStrokeMiter(strokeMiterLimit)
        if let maskFilter {
            sk_paint_set_maskfilter_blur(&paint, maskFilter.style.toSkia(), maskFilter.sigma)
        }
        // filterQuality
    }
}

extension BoxWidthStyle {
    func toSkia() -> skia.textlayout.RectWidthStyle {
        return switch self {
        case .tight:
            skia.textlayout.RectWidthStyle.tight
        case .max:
            skia.textlayout.RectWidthStyle.max
        }
    }
}

extension BoxHeightStyle {
    func toSkia() -> skia.textlayout.RectHeightStyle {
        return switch self {
        case .max:
            skia.textlayout.RectHeightStyle.max
        case .tight:
            skia.textlayout.RectHeightStyle.tight
        case .includeLineSpacingMiddle:
            skia.textlayout.RectHeightStyle.includeLineSpacingMiddle
        case .includeLineSpacingTop:
            skia.textlayout.RectHeightStyle.includeLineSpacingTop
        case .includeLineSpacingBottom:
            skia.textlayout.RectHeightStyle.includeLineSpacingBottom
        case .strut:
            skia.textlayout.RectHeightStyle.strut
        }
    }
}

extension ParagraphStyle {
    func copyToSkia(_ style: inout skia.textlayout.ParagraphStyle) {
        if let strutStyle {
            var skiaStrutStyle = skia.textlayout.StrutStyle()
            strutStyle.copyToSkia(&skiaStrutStyle)
            style.setStrutStyle(skiaStrutStyle)
        }
        if let defaultSpanStyle {
            var textStyle = skia.textlayout.TextStyle()
            defaultSpanStyle.copyToSkia(&textStyle)
            style.setTextStyle(textStyle)
        }
        if let textAlign {
            style.setTextAlign(textAlign.toSkia())
        }
        if let textDirection {
            style.setTextDirection(textDirection.toSkia())
        }
        if let maxLines {
            style.setMaxLines(Int(maxLines))
        }
        if let ellipsis {
            style.setEllipsis(SkString(ellipsis))
        }
        if let height {
            style.setHeight(height)
        }
        if let textHeightBehavior {
            style.setTextHeightBehavior(textHeightBehavior.toSkia())
        }
    }
}

extension PaintingStyle {
    func toSkia() -> SkPaint.Style {
        //  enum Style : uint8_t {
        //     kFill_Style,          //!< set to fill geometry
        //     kStroke_Style,        //!< set to stroke geometry
        //     kStrokeAndFill_Style, //!< sets to stroke and fill geometry
        // };
        switch self {
        case .fill:
            return SkPaint.Style.init(0)
        case .stroke:
            return SkPaint.Style.init(1)
        }
    }
}

extension BlendMode {
    func toSkia() -> SkBlendMode {
        switch self {
        case .clear: .clear
        case .src: .src
        case .dst: .dst
        case .srcOver: .srcOver
        case .dstOver: .dstOver
        case .srcIn: .srcIn
        case .dstIn: .dstIn
        case .srcOut: .srcOut
        case .dstOut: .dstOut
        case .srcATop: .srcATop
        case .dstATop: .dstATop
        case .xor: .xor
        case .plus: .plus
        case .modulate: .modulate
        case .screen: .screen
        case .overlay: .overlay
        case .darken: .darken
        case .lighten: .lighten
        case .colorDodge: .colorDodge
        case .colorBurn: .colorBurn
        case .hardLight: .hardLight
        case .softLight: .softLight
        case .difference: .difference
        case .exclusion: .exclusion
        case .multiply: .multiply
        case .hue: .hue
        case .saturation: .saturation
        case .color: .color
        case .luminosity: .luminosity
        }
    }
}

extension StrokeCap {
    func toSkia() -> SkPaint.Cap {
        // enum Cap {
        //     kButt_Cap,                  //!< no stroke extension
        //     kRound_Cap,                 //!< adds circle
        //     kSquare_Cap,                //!< adds square
        //     kLast_Cap    = kSquare_Cap, //!< largest Cap value
        //     kDefault_Cap = kButt_Cap,   //!< equivalent to kButt_Cap
        // };
        switch self {
        case .butt:
            return SkPaint.Cap.init(0)
        case .round:
            return SkPaint.Cap.init(1)
        case .square:
            return SkPaint.Cap.init(2)
        }
    }
}

extension StrokeJoin {
    func toSkia() -> SkPaint.Join {
        // enum Join : uint8_t {
        //     kMiter_Join,                 //!< extends to miter limit
        //     kRound_Join,                 //!< adds circle
        //     kBevel_Join,                 //!< connects outside edges
        //     kLast_Join    = kBevel_Join, //!< equivalent to the largest value for Join
        //     kDefault_Join = kMiter_Join, //!< equivalent to kMiter_Join
        // };
        switch self {
        case .miter:
            return SkPaint.Join.init(0)
        case .round:
            return SkPaint.Join.init(1)
        case .bevel:
            return SkPaint.Join.init(2)
        }
    }
}

extension BlurStyle {
    func toSkia() -> SkBlurStyle {
        switch self {
        case .normal:
            return kNormal_SkBlurStyle
        case .solid:
            return kSolid_SkBlurStyle
        case .outer:
            return kOuter_SkBlurStyle
        case .inner:
            return kInner_SkBlurStyle
        }
    }
}

extension StrutStyle {
    func copyToSkia(_ style: inout skia.textlayout.StrutStyle) {
        if let fontFamilies {
            var skFontFamilies = skstring_vector_new()
            for fontFamily in fontFamilies {
                skFontFamilies.push_back(SkString(fontFamily))
            }
            style.setFontFamilies(skFontFamilies)
        }
        if let fontSize {
            style.setFontSize(fontSize)
        }
        if let fontStyle {
            style.setFontStyle(toSkiaFontStyle(fontStyle: fontStyle, fontWeight: FontWeight.normal))
        }
        if let height {
            style.setHeight(height)
        }
        if let leading {
            style.setLeading(leading)
        }
        if let forceHeight {
            style.setForceStrutHeight(forceHeight)
        }
    }
}

extension FontStyle {
    func toSkia() -> SkFontStyle.Slant {
        // enum Slant {
        //     kUpright_Slant,
        //     kItalic_Slant,
        //     kOblique_Slant,
        // };
        switch self {
        case .normal:
            return SkFontStyle.Slant(0)
        case .italic:
            return SkFontStyle.Slant(1)
        }
    }
}

extension SpanStyle {
    func copyToSkia(_ style: inout skia.textlayout.TextStyle) {
        if let color {
            style.setColor(color.value)
        }
        if let decoration {
            style.setDecoration(decoration.toSkia())
        }
        if let decorationColor {
            style.setDecorationColor(decorationColor.value)
        }
        if let decorationStyle {
            style.setDecorationStyle(decorationStyle.toSkia())
        }
        style.setFontStyle(
            toSkiaFontStyle(
                fontStyle: fontStyle ?? FontStyle.normal,
                fontWeight: fontWeight ?? FontWeight.normal
            )
        )
        if let textBaseline {
            style.setTextBaseline(textBaseline.toSkia())
        }
        if let fontFamilies {
            var vector = skstring_vector_new()
            for fontFamily in fontFamilies {
                vector.push_back(SkString(fontFamily))
            }
            style.setFontFamilies(vector)
        }
        if let fontSize {
            style.setFontSize(fontSize)
        }
        if let letterSpacing {
            style.setLetterSpacing(letterSpacing)
        }
        if let wordSpacing {
            style.setWordSpacing(wordSpacing)
        }
        if let height {
            style.setHeight(height)
            style.setHeightOverride(true)
        }
        if let leadingDistribution {
            style.setHalfLeading(leadingDistribution == .even)
        }
        if let background {
            var paint = SkPaint()
            background.copyToSkia(paint: &paint)
            style.setBackgroundPaint(paint)
        }
        if let foreground {
            var paint = SkPaint()
            foreground.copyToSkia(paint: &paint)
            style.setForegroundPaint(paint)
        }
        // if let shadows {
        //     var vector = skshadows_new()
        //     for shadow in shadows {
        //         vector.push_back(shadow.toSkia())
        //     }
        //     style.setShadows(vector)
        // }

    }
}

extension TextDecoration {
    func toSkia() -> skia.textlayout.TextDecoration {
        // enum TextDecoration {
        //     kNoDecoration = 0x0,
        //     kUnderline = 0x1,
        //     kOverline = 0x2,
        //     kLineThrough = 0x4,
        // };
        var decoration = skia.textlayout.TextDecoration(0)
        if self.contains(.underline) {
            decoration.rawValue |= 0x01
        }
        if self.contains(.overline) {
            decoration.rawValue |= 0x02
        }
        if self.contains(.lineThrough) {
            decoration.rawValue |= 0x04
        }
        return decoration
    }
}

extension TextDecorationStyle {
    func toSkia() -> skia.textlayout.TextDecorationStyle {
        // enum TextDecorationStyle { kSolid, kDouble, kDotted, kDashed, kWavy };
        switch self {
        case .solid:
            return skia.textlayout.TextDecorationStyle(0)
        case .double:
            return skia.textlayout.TextDecorationStyle(1)
        case .dotted:
            return skia.textlayout.TextDecorationStyle(2)
        case .dashed:
            return skia.textlayout.TextDecorationStyle(3)
        case .wavy:
            return skia.textlayout.TextDecorationStyle(4)
        }
    }
}

extension TextBaseline {
    func toSkia() -> skia.textlayout.TextBaseline {
        switch self {
        case .alphabetic:
            return skia.textlayout.TextBaseline.alphabetic
        case .ideographic:
            return skia.textlayout.TextBaseline.ideographic
        }
    }
}

extension TextAlign {
    func toSkia() -> skia.textlayout.TextAlign {
        switch self {
        case .left:
            return skia.textlayout.TextAlign.left
        case .right:
            return skia.textlayout.TextAlign.right
        case .center:
            return skia.textlayout.TextAlign.center
        case .justify:
            return skia.textlayout.TextAlign.justify
        case .start:
            return skia.textlayout.TextAlign.start
        case .end:
            return skia.textlayout.TextAlign.end
        }
    }
}

extension TextDirection {
    func toSkia() -> skia.textlayout.TextDirection {
        switch self {
        case .ltr:
            return skia.textlayout.TextDirection.ltr
        case .rtl:
            return skia.textlayout.TextDirection.rtl
        }
    }
}

extension TextHeightBehavior {
    func toSkia() -> skia.textlayout.TextHeightBehavior {
        // enum TextHeightBehavior {
        //     kAll = 0x0,
        //     kDisableFirstAscent = 0x1,
        //     kDisableLastDescent = 0x2,
        //     kDisableAll = 0x1 | 0x2,
        // };
        if !applyHeightToFirstAscent && !applyHeightToLastDescent {
            return skia.textlayout.TextHeightBehavior(0x1 | 0x2)  // kDisableAll
        } else if !applyHeightToLastDescent {
            return skia.textlayout.TextHeightBehavior(0x2)  // kDisableLastDescent
        } else if !applyHeightToFirstAscent {
            return skia.textlayout.TextHeightBehavior(0x1)  // kDisableFirstAscent
        } else {
            return skia.textlayout.TextHeightBehavior(0x0)  // kAll
        }
    }
}

extension ClipOp {
    func toSkia() -> SkClipOp {
        switch self {
        case .difference:
            return SkClipOp.difference
        case .intersect:
            return SkClipOp.intersect
        }
    }
}

func toSkiaFontStyle(fontStyle: FontStyle, fontWeight: FontWeight) -> SkFontStyle {
    let width = Int32(5)  // kNormal_Width
    let weight = Int32(fontWeight.value)
    let slant = fontStyle.toSkia()
    return SkFontStyle(weight, width, slant)
}
