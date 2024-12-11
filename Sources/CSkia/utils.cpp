#include "utils.h"

using namespace skia::textlayout;

// FontCollection_sp test_font_collection()
// {
//     // auto c = SkCanvas();
//     auto fontCollection = sk_make_sp<FontCollection>();
//     // auto fontMgr = SkFontMgr::RefDefault()
//     auto fontMgr = SkFontMgr::RefEmpty();
//     assert(fontMgr != nullptr);
//     fontCollection->setDefaultFontManager(fontMgr);
//     return fontCollection;
//     // return nullptr;
// }

template struct sk_sp<FontCollection>;
template struct sk_sp<SkSurface>;
template struct sk_sp<SkImage>;
template struct sk_sp<SkTypeface>;

// MARK: - ParagraphBuilder

#if defined(SK_BUILD_FOR_MAC)
auto fontMgr = SkFontMgr_New_CoreText(nullptr);
#elif defined(SK_BUILD_FOR_WIN)
auto fontMgr = SkFontMgr_New_DirectWrite(nullptr);
#elif defined(SK_FONTMGR_FONTCONFIG_AVAILABLE)
auto fontMgr = SkFontMgr_New_FontConfig(nullptr);
#endif

// The singleton font collection that will be used by all paragraph builders.
auto fontCollection1 = sk_make_sp<FontCollection>();

ParagraphBuilder *paragraph_builder_new(ParagraphStyle &style)
{
    // auto fontCollection1 = sk_make_sp<FontCollection>();
    fontCollection1->setDefaultFontManager(fontMgr);

    auto result = ParagraphBuilder::make(style, fontCollection1);
    // auto result = ParagraphBuilder::make(*style, font_collection);
    auto result2 = result.release();
    return result2;
}

void paragraph_builder_add_text(ParagraphBuilder *builder, const char *text)
{
    builder->addText(text);
    // builder->addText(text, strlen(text));
}

void paragraph_builder_push_style(ParagraphBuilder *builder, const TextStyle *style)
{
    builder->pushStyle(*style);
}

void paragraph_builder_pop(ParagraphBuilder *builder)
{
    builder->pop();
}

Paragraph *paragraph_builder_build(ParagraphBuilder *builder)
{
    return builder->Build().release();
}

void paragraph_builder_unref(ParagraphBuilder *builder)
{
    std::default_delete<ParagraphBuilder>()(builder);
}

// MARK: - Paragraph

std::vector<Paragraph::FontInfo> paragraph_get_fonts(Paragraph *paragraph)
{
    return paragraph->getFonts();
}

void paragraph_layout(Paragraph *paragraph, float width)
{
    paragraph->layout(width);
}

void paragraph_paint(Paragraph *paragraph, SkCanvas *canvas, float x, float y)
{
    paragraph->paint(canvas, x, y);
}

PositionWithAffinity paragraph_get_glyph_position_at_coordinate(Paragraph *paragraph, SkScalar dx, SkScalar dy)
{
    PositionWithAffinity position = paragraph->getGlyphPositionAtCoordinate(dx, dy);
    return position;
}

SkRange<size_t> paragraph_get_word_boundary(Paragraph *paragraph, unsigned offset)
{
    return paragraph->getWordBoundary(offset);
}

std::vector<LineMetrics> paragraph_get_line_metrics(Paragraph *paragraph)
{
    std::vector<LineMetrics> metrics;
    paragraph->getLineMetrics(metrics);
    return metrics;
}

LineMetrics paragraph_get_line_metrics_at(Paragraph *paragraph, unsigned lineNumber)
{
    LineMetrics metrics;
    paragraph->getLineMetricsAt(lineNumber, &metrics);
    return metrics;
}

size_t paragraph_get_line_count(Paragraph *paragraph)
{
    return paragraph->lineNumber();
}

int paragraph_get_line_number_at(Paragraph *paragraph, size_t codeUnitIndex)
{
    return paragraph->getLineNumberAt(codeUnitIndex);
}

std::vector<TextBox> paragraph_get_rects_for_range(Paragraph *paragraph, size_t start, size_t end, RectHeightStyle boxHeightStyle, RectWidthStyle boxWidthStyle)
{
    return paragraph->getRectsForRange(start, end, boxHeightStyle, boxWidthStyle);
}

std::vector<TextBox> paragraph_get_rects_for_placeholders(Paragraph *paragraph)
{
    return paragraph->getRectsForPlaceholders();
}

bool paragraph_get_glyph_info_at(Paragraph *paragraph, size_t codeUnitIndex, Paragraph::GlyphInfo *glyphInfo)
{
    return paragraph->getGlyphInfoAtUTF16Offset(codeUnitIndex, glyphInfo);
}

Paragraph::GlyphInfo paragraph_get_closest_glyph_info_at(Paragraph *paragraph, SkScalar dx, SkScalar dy)
{
    Paragraph::GlyphInfo info;
    paragraph->getClosestUTF16GlyphInfoAt(dx, dy, &info);
    return info;
}

void paragraph_unref(Paragraph *paragraph)
{
    std::default_delete<Paragraph>()(paragraph);
}

std::vector<SkString> skstring_vector_new()
{
    return std::vector<SkString>();
}

sk_sp<SkColorSpace> color_space_new_srgb()
{
    return SkColorSpace::MakeSRGB();
}

sk_sp<SkColorSpace> color_space_new_null()
{
    return nullptr;
}

SkCanvas *sk_surface_get_canvas(const sk_sp<SkSurface> &surface)
{
    return surface->getCanvas();
}

// MARK: - Canvas

void sk_canvas_concat(SkCanvas *canvas, const SkM44 &matrix)
{
    canvas->concat(matrix);
}

void sk_canvas_save(SkCanvas *canvas)
{
    canvas->save();
}

void sk_canvas_save_layer(SkCanvas *canvas, const SkRect *bounds, const SkPaint *paint)
{
    canvas->saveLayer(bounds, paint);
}

void sk_canvas_restore(SkCanvas *canvas)
{
    canvas->restore();
}

int sk_canvas_get_save_count(SkCanvas *canvas)
{
    return canvas->getSaveCount();
}

void sk_canvas_clear(SkCanvas *canvas, SkColor color)
{
    canvas->clear(color);
}

void sk_canvas_draw_line(SkCanvas *canvas, float x0, float y0, float x1, float y1, const SkPaint &paint)
{
    canvas->drawLine(x0, y0, x1, y1, paint);
}

void sk_canvas_draw_rect(SkCanvas *canvas, const SkRect &rect, const SkPaint &paint)
{
    canvas->drawRect(rect, paint);
}

void sk_canvas_draw_rrect(SkCanvas *canvas, const SkRRect &rrect, const SkPaint &paint)
{
    canvas->drawRRect(rrect, paint);
}

void sk_canvas_draw_drrect(SkCanvas *canvas, const SkRRect &outer, const SkRRect &inner, const SkPaint &paint)
{
    canvas->drawDRRect(outer, inner, paint);
}

void sk_canvas_draw_circle(SkCanvas *canvas, float x, float y, float radius, const SkPaint &paint)
{
    canvas->drawCircle(x, y, radius, paint);
}

void sk_canvas_draw_path(SkCanvas *canvas, const SkPath &path, const SkPaint &paint)
{
    canvas->drawPath(path, paint);
}

void sk_canvas_draw_image(SkCanvas *canvas, SkImage_sp &image, float x, float y, const SkPaint *paint)
{
    canvas->drawImage(image.get(), x, y, SkSamplingOptions(), paint);
}

void sk_canvas_draw_image_rect(SkCanvas *canvas, SkImage_sp &image, const SkRect &src, const SkRect &dst, const SkPaint *paint)
{
    canvas->drawImageRect(image, src, dst, SkSamplingOptions(), paint, SkCanvas::kFast_SrcRectConstraint);
}

void sk_canvas_draw_image_nine(SkCanvas *canvas, SkImage_sp &image, const SkIRect &center, const SkRect &dst, const SkPaint *paint)
{
    canvas->drawImageNine(image.get(), center, dst, SkFilterMode::kLinear, paint);
}

void sk_canvas_clip_rect(SkCanvas *canvas, const SkRect &rect, SkClipOp op, bool doAntiAlias)
{
    canvas->clipRect(rect, op, doAntiAlias);
}

void sk_canvas_translate(SkCanvas *canvas, float dx, float dy)
{
    canvas->translate(dx, dy);
}

void sk_canvas_scale(SkCanvas *canvas, float sx, float sy)
{
    canvas->scale(sx, sy);
}

// MARK: - Paint

void sk_paint_set_maskfilter_blur(SkPaint *paint, SkBlurStyle style, SkScalar sigma)
{
    // Setting the mask filter involves sk_sp. To avoid memory leaks, we need to
    // do this in c rather than swift.
    paint->setMaskFilter(SkMaskFilter::MakeBlur(style, sigma));
}

// MARK: - Path

void sk_path_move_to(SkPath *path, SkScalar x, SkScalar y)
{
    path->moveTo(x, y);
}

void sk_path_line_to(SkPath *path, SkScalar x, SkScalar y)
{
    path->lineTo(x, y);
}

void sk_path_reset(SkPath *path)
{
    path->reset();
}

// MARK: - Image

SkAnimatedImage_sp sk_animated_image_create(const void *data, size_t length)
{
    auto bytes = SkData::MakeWithCopy(data, length);
    auto aCodec = SkAndroidCodec::MakeFromData(std::move(bytes));
    if (aCodec == nullptr)
    {
        return nullptr;
    }
    return SkAnimatedImage::Make(std::move(aCodec));
}

int sk_animated_image_get_frame_count(SkAnimatedImage_sp &image)
{
    return image->getFrameCount();
}

int sk_animated_image_get_repetition_count(SkAnimatedImage_sp &image)
{
    return image->getRepetitionCount();
}

int sk_animated_image_decode_next_frame(SkAnimatedImage_sp &image)
{
    return image->decodeNextFrame();
}

SkImage_sp sk_animated_image_get_current_frame(SkAnimatedImage_sp &image)
{
    return image->getCurrentFrame();
}

int sk_image_get_width(SkImage_sp &image)
{
    return image->width();
}

int sk_image_get_height(SkImage_sp &image)
{
    return image->height();
}

// MARK: - GL

GrGLInterface_sp gr_glinterface_create_native_interface()
{
    return GrGLMakeNativeInterface();
}

GrDirectContext_sp gr_direct_context_make_gl(GrGLInterface_sp &glInterface)
{
    return GrDirectContexts::MakeGL(glInterface);
}

const GrDirectContext *gr_direct_context_unwrap(GrDirectContext_sp &context)
{
    return context.get();
}

void gr_direct_context_flush_and_submit(GrDirectContext_sp &context, GrSyncCpu syncCPU)
{
    context->flushAndSubmit(syncCPU);
}

// MARK: - Metal

#if defined(SK_BUILD_FOR_MAC)
GrDirectContext_sp gr_mtl_direct_context_make(GrMtlBackendContext &context)
{
    return GrDirectContexts::MakeMetal(context);
}
#endif

// An hack to avoid linking error on Linux
#if defined(__linux__)
namespace swift
{
    namespace threading
    {

        void fatal(const char *msg, ...)
        {
            std::va_list val;

            va_start(val, msg);
            std::vfprintf(stderr, msg, val);
            va_end(val);

            std::abort();
        }

    } // namespace threading
} // namespace swift
#endif