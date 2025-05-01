// #if defined(SK_BUILD_FOR_MAC)

#include "utils_macos.h"
#include "include/ports/SkTypeface_mac.h"
#include <CoreText/CoreText.h>

const FourCharCode kWeightTag = 'wght';
// Apple system font larger than size 29 returns SFProDisplay typeface.
static const CGFloat kSFProDisplayBreakPoint = 29;
// Font name represents the "SF Pro Display" system font on Apple platforms.
static const std::string kSFProDisplayName = "CupertinoSystemDisplay";
// Font weight representing Regular
float kNormalWeightValue = 400;

CFRef<CTFontRef> MatchSystemUIFont(float desired_weight, float size) {
  CFRef<CTFontRef> ct_font(
      CTFontCreateUIFontForLanguage(kCTFontUIFontSystem, size, nullptr));

  if (desired_weight == kNormalWeightValue) {
    return ct_font;
  }

  CFRef<CFMutableDictionaryRef> variations(CFDictionaryCreateMutable(
      kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks,
      &kCFTypeDictionaryValueCallBacks));

  auto add_axis_to_variations = [&variations](const FourCharCode tag,
                                              float desired_value,
                                              float normal_value) {
    if (desired_value != normal_value) {
      CFRef<CFNumberRef> tag_number(
          CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &tag));
      CFRef<CFNumberRef> value_number(CFNumberCreate(
          kCFAllocatorDefault, kCFNumberFloatType, &desired_value));
      CFDictionarySetValue(variations, tag_number, value_number);
    }
  };
  add_axis_to_variations(kWeightTag, desired_weight, kNormalWeightValue);

  CFRef<CFMutableDictionaryRef> attributes(CFDictionaryCreateMutable(
      kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks,
      &kCFTypeDictionaryValueCallBacks));
  CFDictionarySetValue(attributes, kCTFontVariationAttribute, variations);

  CFRef<CTFontDescriptorRef> var_font_desc(
      CTFontDescriptorCreateWithAttributes(attributes));

  return CFRef<CTFontRef>(
      CTFontCreateCopyWithAttributes(ct_font, size, nullptr, var_font_desc));
}

void RegisterSystemFonts(
    skia::textlayout::TypefaceFontProvider &dynamic_font_manager) {
  // iOS loads different system fonts when size is greater than 28 or lower
  // than 17. The "familyName" property returned from CoreText stays the same
  // despite the typeface is different.
  //
  // Below code manually loads and registers the larger font. The existing
  // fallback correctly loads the smaller font. The code also iterates through
  // the possible font weights from 100 - 900 to correctly load all of them, as
  // a CTFont object for the large system font does not include all of the font
  // weights by default.
  //
  // Darwin system fonts from 17 to 28 also have dynamic spacing based on sizes.
  // These two fonts do not match the spacings when sizes are from 17 to 28.
  // The spacing should be handled by the app or the framework.
  //
  // See https://www.wwdcnotes.com/notes/wwdc20/10175/ for Apple's document on
  // this topic.
  auto register_weighted_font = [&dynamic_font_manager](const int weight) {
    sk_sp<SkTypeface> large_system_font_weighted = SkMakeTypefaceFromCTFont(
        MatchSystemUIFont(weight, kSFProDisplayBreakPoint));
    if (large_system_font_weighted) {
      dynamic_font_manager.registerTypeface(large_system_font_weighted,
                                            SkString(kSFProDisplayName));
    }
  };
  for (int i = 0; i < 8; i++) {
    const int font_weight = i * 100;
    register_weighted_font(font_weight);
  }
  // The value 780 returns a font weight of 800.
  register_weighted_font(780);
  // The value of 810 returns a font weight of 900.
  register_weighted_font(810);
}

// #endif