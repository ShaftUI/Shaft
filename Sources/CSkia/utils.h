#define SK_GL
#define SK_METAL
#define SK_GANESH

#include "include/android/SkAnimatedImage.h"
#include "include/codec/SkAndroidCodec.h"
#include "include/codec/SkBmpDecoder.h"
#include "include/codec/SkGifDecoder.h"
#include "include/codec/SkIcoDecoder.h"
#include "include/codec/SkJpegDecoder.h"
#include "include/codec/SkPngDecoder.h"
#include "include/codec/SkWbmpDecoder.h"
#include "include/codec/SkWebpDecoder.h"
#include "include/core/SkBlurTypes.h"
#include "include/core/SkCanvas.h"
#include "include/core/SkColorSpace.h"
#include "include/core/SkRefCnt.h"
#include "include/core/SkData.h"
#include "include/core/SkDocument.h"
#include "include/core/SkFontMetrics.h"
#include "include/core/SkFontMgr.h"
#include "include/core/SkMaskFilter.h"
#include "include/core/SkPath.h"
#include "include/core/SkPathUtils.h"
#include "include/core/SkPoint3.h"
#include "include/core/SkRRect.h"
#include "include/core/SkStream.h"
#include "include/core/SkSurface.h"
#include "include/core/SkTextBlob.h"
#include "include/core/SkTypes.h"

#include "include/docs/SkPDFDocument.h"

#include "include/effects/Sk1DPathEffect.h"
#include "include/effects/Sk2DPathEffect.h"
#include "include/effects/SkColorMatrixFilter.h"
#include "include/effects/SkCornerPathEffect.h"
#include "include/effects/SkDashPathEffect.h"
#include "include/effects/SkDiscretePathEffect.h"
#include "include/effects/SkGradientShader.h"
#include "include/effects/SkHighContrastFilter.h"
#include "include/effects/SkImageFilters.h"
#include "include/effects/SkLumaColorFilter.h"
#include "include/effects/SkPerlinNoiseShader.h"
#include "include/effects/SkShaderMaskFilter.h"
#include "include/effects/SkTableMaskFilter.h"
#include "include/effects/SkTrimPathEffect.h"

#include "include/encode/SkJpegEncoder.h"
#include "include/encode/SkPngEncoder.h"
#include "include/encode/SkWebpEncoder.h"
// #include "include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "include/gpu/ganesh/SkImageGanesh.h"
#include "include/gpu/ganesh/SkSurfaceGanesh.h"
#include "include/gpu/gl/GrGLAssembleInterface.h"
#include "include/gpu/GrBackendSurface.h"
#include "include/gpu/GrContextOptions.h"
#include "include/gpu/GrDirectContext.h"

#include "include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "include/gpu/ganesh/gl/GrGLDirectContext.h"

#include "include/pathops/SkPathOps.h"
#include "include/utils/SkParsePath.h"

#include "modules/skparagraph/include/Paragraph.h"
#include "modules/skparagraph/include/ParagraphBuilder.h"
#include "modules/skparagraph/include/FontCollection.h"
#include "modules/skparagraph/include/TypefaceFontProvider.h"

#include "src/core/SkYUVAInfoLocation.h"

#if defined(SK_FONTMGR_FONTCONFIG_AVAILABLE)
#include "include/ports/SkFontMgr_fontconfig.h"
#endif

#if defined(SK_BUILD_FOR_MAC)
#include "include/ports/SkFontMgr_mac_ct.h"
#include "include/gpu/ganesh/mtl/GrMtlDirectContext.h"
#include "include/gpu/ganesh/mtl/GrMtlBackendSurface.h"
#include "include/gpu/ganesh/mtl/GrMtlBackendContext.h"
#elif defined(SK_BUILD_FOR_WIN)
#include "include/ports/SkTypeface_win.h"
#endif

#if defined(SK_FONTMGR_DIRECTWRITE_AVAILABLE)
#include "include/ports/SkTypeface_win.h"
#endif

#if defined(SK_FONTMGR_FREETYPE_DIRECTORY_AVAILABLE)
#include "include/ports/SkFontMgr_directory.h"
#endif

#if !defined(CSKIA_UTILS_H)
#define CSKIA_UTILS_H

using namespace skia::textlayout;

// Define some specializations for sk_sp<T> so that we can use them in Swift

typedef sk_sp<SkSurface> SkSurface_sp;
typedef sk_sp<SkImage> SkImage_sp;
typedef sk_sp<SkAnimatedImage> SkAnimatedImage_sp;
typedef sk_sp<const GrGLInterface> GrGLInterface_sp;
typedef sk_sp<GrDirectContext> GrDirectContext_sp;
typedef sk_sp<FontCollection> FontCollection_sp;
typedef sk_sp<ParagraphBuilder> ParagraphBuilder_sp;
typedef sk_sp<SkTypeface> SkTypeface_sp;
typedef sk_sp<SkTextBlob> SkTextBlob_sp;

// FontCollection_sp test_font_collection();

// MARK: - ParagraphBuilder

ParagraphBuilder *paragraph_builder_new(ParagraphStyle &style, const FontCollection_sp &fontCollection);
void paragraph_builder_add_text(ParagraphBuilder *builder, const char *text);
void paragraph_builder_push_style(ParagraphBuilder *builder, const TextStyle *style);
void paragraph_builder_pop(ParagraphBuilder *builder);
Paragraph *paragraph_builder_build(ParagraphBuilder *builder);
void paragraph_builder_unref(ParagraphBuilder *builder);

// MARK: - Paragraph

std::vector<Paragraph::FontInfo> paragraph_get_fonts(Paragraph *paragraph);
void paragraph_layout(Paragraph *paragraph, float width);
void paragraph_paint(Paragraph *paragraph, SkCanvas *canvas, float x, float y);
PositionWithAffinity paragraph_get_glyph_position_at_coordinate(Paragraph *paragraph, SkScalar dx, SkScalar dy);
SkRange<size_t> paragraph_get_word_boundary(Paragraph *paragraph, unsigned offset);
std::vector<LineMetrics> paragraph_get_line_metrics(Paragraph *paragraph);
LineMetrics paragraph_get_line_metrics_at(Paragraph *paragraph, unsigned lineNumber);
size_t paragraph_get_line_count(Paragraph *paragraph);
int paragraph_get_line_number_at(Paragraph *paragraph, size_t codeUnitIndex);
std::vector<TextBox> paragraph_get_rects_for_range(Paragraph *paragraph, size_t start, size_t end, RectHeightStyle boxHeightStyle, RectWidthStyle boxWidthStyle);
std::vector<TextBox> paragraph_get_rects_for_placeholders(Paragraph *paragraph);
bool paragraph_get_glyph_info_at(Paragraph *paragraph, size_t codeUnitIndex, Paragraph::GlyphInfo *glyphInfo);
Paragraph::GlyphInfo paragraph_get_closest_glyph_info_at(Paragraph *paragraph, SkScalar dx, SkScalar dy);
void paragraph_unref(Paragraph *paragraph);

// MARK: - Font

FontCollection_sp sk_fontcollection_new();
void sk_fontcollection_register_typeface(FontCollection_sp &collection, SkTypeface_sp &typeface);
SkTypeface_sp sk_typeface_create_from_data(const FontCollection_sp &collection, const char *data, size_t length);
std::vector<SkTypeface_sp> sk_fontcollection_find_typefaces(const FontCollection_sp &collection, const std::vector<SkString> &families, SkFontStyle style);
SkTypeface_sp sk_fontcollection_default_fallback(const FontCollection_sp &collection, SkUnichar unicode, SkFontStyle style, const SkString &locale);
std::vector<SkGlyphID> sk_typeface_get_glyphs(SkTypeface_sp &typeface, const SkUnichar *text, size_t length);
SkGlyphID sk_typeface_get_glyph(SkTypeface_sp &typeface, SkUnichar unicode);
int sk_typeface_count_glyphs(SkTypeface_sp &typeface);
void sk_typeface_get_family_name(SkTypeface_sp &typeface, SkString *familyName);
SkFont sk_font_new(SkTypeface_sp &typeface, float size);
float sk_font_get_size(SkFont &font);
SkTextBlob_sp sk_text_blob_make_from_glyphs(const SkGlyphID *glyphs, const SkPoint *positions, size_t length, const SkFont &font);

// MARK: - TextStyle

void sk_textstyle_set_font_arguments(TextStyle *style, SkFontArguments fontArguments);

// MARK: - Canvas

void sk_canvas_concat(SkCanvas *canvas, const SkM44 &matrix);
void sk_canvas_save(SkCanvas *canvas);
void sk_canvas_save_layer(SkCanvas *canvas, const SkRect *bounds, const SkPaint *paint);
void sk_canvas_restore(SkCanvas *canvas);
int sk_canvas_get_save_count(SkCanvas *canvas);
void sk_canvas_clear(SkCanvas *canvas, SkColor color);
void sk_canvas_draw_line(SkCanvas *canvas, float x0, float y0, float x1, float y1, const SkPaint &paint);
void sk_canvas_draw_rect(SkCanvas *canvas, const SkRect &rect, const SkPaint &paint);
void sk_canvas_draw_rrect(SkCanvas *canvas, const SkRRect &rrect, const SkPaint &paint);
void sk_canvas_draw_drrect(SkCanvas *canvas, const SkRRect &outer, const SkRRect &inner, const SkPaint &paint);
void sk_canvas_draw_circle(SkCanvas *canvas, float x, float y, float radius, const SkPaint &paint);
void sk_canvas_draw_path(SkCanvas *canvas, const SkPath &path, const SkPaint &paint);
void sk_canvas_draw_image(SkCanvas *canvas, SkImage_sp &image, float x, float y, const SkPaint *paint);
void sk_canvas_draw_image_rect(SkCanvas *canvas, SkImage_sp &image, const SkRect &src, const SkRect &dst, const SkPaint *paint);
void sk_canvas_draw_image_nine(SkCanvas *canvas, SkImage_sp &image, const SkIRect &center, const SkRect &dst, const SkPaint *paint);
void sk_canvas_draw_text_blob(SkCanvas *canvas, SkTextBlob_sp &blob, float x, float y, const SkPaint &paint);
void sk_canvas_clip_rect(SkCanvas *canvas, const SkRect &rect, SkClipOp op, bool doAntiAlias);
void sk_canvas_clip_rrect(SkCanvas *canvas, const SkRRect &rrect, SkClipOp op, bool doAntiAlias);
void sk_canvas_translate(SkCanvas *canvas, float dx, float dy);
void sk_canvas_scale(SkCanvas *canvas, float sx, float sy);
void sk_canvas_rotate(SkCanvas *canvas, float radians);

// MARK: - Paint

void sk_paint_set_maskfilter_blur(SkPaint *paint, SkBlurStyle style, SkScalar sigma);
void sk_paint_clear_maskfilter(SkPaint *paint);

// MARK: - Path

void sk_path_move_to(SkPath *path, SkScalar x, SkScalar y);
void sk_path_line_to(SkPath *path, SkScalar x, SkScalar y);
void sk_path_reset(SkPath *path);

// MARK: - Surface

SkCanvas *sk_surface_get_canvas(const sk_sp<SkSurface> &surface);

// MARK: - Image

SkAnimatedImage_sp sk_animated_image_create(const void *data, size_t length);
int sk_animated_image_get_frame_count(SkAnimatedImage_sp &image);
int sk_animated_image_get_repetition_count(SkAnimatedImage_sp &image);
int sk_animated_image_decode_next_frame(SkAnimatedImage_sp &image);
SkImage_sp sk_animated_image_get_current_frame(SkAnimatedImage_sp &image);

int sk_image_get_width(sk_sp<SkImage> &image);
int sk_image_get_height(SkImage_sp &image);

// MARK: - GL

GrGLInterface_sp gr_glinterface_create_native_interface();
GrDirectContext_sp gr_direct_context_make_gl(GrGLInterface_sp &glInterface);
const GrDirectContext *gr_direct_context_unwrap(GrDirectContext_sp &context);
void gr_direct_context_flush_and_submit(GrDirectContext_sp &context, GrSyncCpu syncCPU);

// MARK: - Metal

#if defined(SK_BUILD_FOR_MAC)
GrDirectContext_sp gr_mtl_direct_context_make(GrMtlBackendContext &context);
#endif

// MARK: - Misc

std::vector<SkString> skstring_vector_new();
void skstring_c_str(const SkString &string, const char **out);
sk_sp<SkColorSpace> color_space_new_srgb();

sk_sp<SkColorSpace> color_space_new_null();

#endif // CSKIA_UTILS_H