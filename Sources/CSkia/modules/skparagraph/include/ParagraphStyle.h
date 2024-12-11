// Copyright 2019 Google LLC.
#ifndef ParagraphStyle_DEFINED
#define ParagraphStyle_DEFINED

#include "include/core/SkFontStyle.h"
#include "include/core/SkScalar.h"
#include "include/core/SkString.h"
#include "modules/skparagraph/include/DartTypes.h"
#include "modules/skparagraph/include/FontRastrSettings.h"
#include "modules/skparagraph/include/TextStyle.h"

#include <stddef.h>
#include <algorithm>
#include <limits>
#include <string>
#include <utility>
#include <vector>

namespace skia {
namespace textlayout {

struct StrutStyle {
    StrutStyle();

    const std::vector<SkString>& getFontFamilies() const { return fFontFamilies; }
    void setFontFamilies(std::vector<SkString> families) { fFontFamilies = std::move(families); }

    SkFontStyle getFontStyle() const { return fFontStyle; }
    void setFontStyle(SkFontStyle fontStyle) { fFontStyle = fontStyle; }

    SkScalar getFontSize() const { return fFontSize; }
    void setFontSize(SkScalar size) { fFontSize = size; }

    void setHeight(SkScalar height) { fHeight = height; }
    SkScalar getHeight() const { return fHeight; }

    void setLeading(SkScalar Leading) { fLeading = Leading; }
    SkScalar getLeading() const { return fLeading; }

    bool getStrutEnabled() const { return fEnabled; }
    void setStrutEnabled(bool v) { fEnabled = v; }

    bool getForceStrutHeight() const { return fForceHeight; }
    void setForceStrutHeight(bool v) { fForceHeight = v; }

    bool getHeightOverride() const { return fHeightOverride; }
    void setHeightOverride(bool v) { fHeightOverride = v; }

    void setHalfLeading(bool halfLeading) { fTopRatio = halfLeading ? 0.5f : -1.0f; }
    bool getHalfLeading() const { return fTopRatio == 0.5f; }

    void setTopRatio(SkScalar topRatio) { fTopRatio = topRatio; }
    SkScalar getTopRatio() const { return fTopRatio; }

    bool operator==(const StrutStyle& rhs) const {
        return this->fFontFamilies == rhs.fFontFamilies &&
               this->fFontStyle == rhs.fFontStyle &&
               nearlyEqual(this->fFontSize, rhs.fFontSize) &&
               nearlyEqual(this->fHeight, rhs.fHeight) &&
               nearlyEqual(this->fLeading, rhs.fLeading) &&
               nearlyEqual(this->fTopRatio, rhs.fTopRatio) &&
               this->fForceHeight == rhs.fForceHeight &&
               this->fEnabled == rhs.fEnabled &&
               this->fHeightOverride == rhs.fHeightOverride;
    }

private:
    std::vector<SkString> fFontFamilies;
    SkFontStyle fFontStyle;
    SkScalar fFontSize;
    SkScalar fHeight;
    SkScalar fLeading;
    // [0..1]: the ratio of ascent to ascent+descent
    // -1: proportional to the ascent/descent
    SkScalar fTopRatio;
    bool fForceHeight;
    bool fEnabled;
    bool fHeightOverride;
};

struct TextIndent {
    TextIndent();

    bool operator==(const TextIndent& rhs) const {
        return this->fFirstLine == rhs.fFirstLine &&
               this->fRestLine == rhs.fRestLine;
    }

    SkScalar getFirstLine() const { return fFirstLine; }
    void setFirstLine(SkScalar firstLine) { fFirstLine = firstLine; }

    SkScalar getRestLine() const { return fRestLine; }
    void setRestLine(SkScalar restLine) { fRestLine = restLine; }

private:
    SkScalar fFirstLine;
    SkScalar fRestLine;
};

struct ParagraphStyle {
    ParagraphStyle();

    bool equals(const ParagraphStyle& rhs) const;
    bool equalsByLayout(const ParagraphStyle& rhs) const;
    bool operator==(const ParagraphStyle& rhs) const { return this->equals(rhs); }

    const StrutStyle& getStrutStyle() const { return fStrutStyle; }
    void setStrutStyle(StrutStyle strutStyle) { fStrutStyle = std::move(strutStyle); }

    const FontRastrSettings& getFontRastrSettings() const { return fFontRastrSettings; }
    void setFontRastrSettings(const FontRastrSettings& fontRastrSettings) { fFontRastrSettings = fontRastrSettings; }

    const TextStyle& getTextStyle() const { return fDefaultTextStyle; }
    void setTextStyle(const TextStyle& textStyle) { fDefaultTextStyle = textStyle; }

    TextDirection getTextDirection() const { return fTextDirection; }
    void setTextDirection(TextDirection direction) { fTextDirection = direction; }

    TextAlign getTextAlign() const { return fTextAlign; }
    void setTextAlign(TextAlign align) { fTextAlign = align; }

    size_t getMaxLines() const { return fLinesLimit; }
    void setMaxLines(size_t maxLines) { fLinesLimit = maxLines; }

    SkString getEllipsis() const { return fEllipsis; }
    std::u16string getEllipsisUtf16() const { return fEllipsisUtf16; }
    void setEllipsis(const std::u16string& ellipsis) {  fEllipsisUtf16 = ellipsis; }
    void setEllipsis(const SkString& ellipsis) { fEllipsis = ellipsis; }

    SkScalar getHeight() const { return fHeight; }
    void setHeight(SkScalar height) { fHeight = height; }

    TextHeightBehavior getTextHeightBehavior() const { return fTextHeightBehavior; }
    void setTextHeightBehavior(TextHeightBehavior v) { fTextHeightBehavior = v; }

    bool unlimited_lines() const {
        return fLinesLimit == std::numeric_limits<size_t>::max();
    }
    bool ellipsized() const { return !fEllipsis.isEmpty() || !fEllipsisUtf16.empty(); }
    TextAlign effective_align() const;
    bool hintingIsOn() const { return fHintingIsOn; }
    void turnHintingOff() { fHintingIsOn = false; }

    bool getReplaceTabCharacters() const { return fReplaceTabCharacters; }
    void setReplaceTabCharacters(bool value) { fReplaceTabCharacters = value; }

    bool getApplyRoundingHack() const { return fApplyRoundingHack; }
    void setApplyRoundingHack(bool value) { fApplyRoundingHack = value; }

    const TextIndent& getTextIndent() const { return fTextIndent; }
    void setTextIndent(TextIndent textIndent) { fTextIndent = textIndent; }

private:
    StrutStyle fStrutStyle;
    TextStyle fDefaultTextStyle;
    TextAlign fTextAlign;
    TextDirection fTextDirection;
    size_t fLinesLimit;
    std::u16string fEllipsisUtf16;
    SkString fEllipsis;
    SkScalar fHeight;
    TextHeightBehavior fTextHeightBehavior;
    TextIndent fTextIndent;
    FontRastrSettings fFontRastrSettings;
    bool fHintingIsOn;
    bool fReplaceTabCharacters;
    bool fApplyRoundingHack = true;

    // common part of equals and equalsByLayout
    bool almostEquals(const ParagraphStyle& rhs) const;
};
}  // namespace textlayout
}  // namespace skia

#endif  // ParagraphStyle_DEFINED
