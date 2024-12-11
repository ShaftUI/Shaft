// Copyright 2019 Google LLC.
#ifndef FontRastrSettings_DEFINED
#define FontRastrSettings_DEFINED

#include "include/core/SkFont.h"
#include "include/core/SkFontTypes.h"

namespace skia {
namespace textlayout {

struct FontRastrSettings {

    /** Whether edge pixels draw opaque or with partial transparency. */
    SkFont::Edging fEdging = SkFont::Edging::kAntiAlias;

    /** Level of glyph outline adjustment. */
    SkFontHinting fHinting = SkFontHinting::kSlight;

    /** Whether glyphs respect sub-pixel positioning. */
    bool fSubpixel = true;

    bool operator==(const FontRastrSettings& rhs) const {
        return this->fEdging == rhs.fEdging &&
               this->fHinting == rhs.fHinting &&
               this->fSubpixel == rhs.fSubpixel;
    }
};


}  // namespace textlayout
}  // namespace skia

#endif  // Metrics_DEFINED
