// #if defined(SK_BUILD_FOR_MAC)

#if !defined(CSKIA_UTILS_MACOS_H)
#define CSKIA_UTILS_MACOS_H

#include "modules/skparagraph/include/TypefaceFontProvider.h"

template <class T>
class CFRef
{
public:
    CFRef() : instance_(nullptr) {}

    // NOLINTNEXTLINE(google-explicit-constructor)
    CFRef(T instance) : instance_(instance) {}

    CFRef(const CFRef &other) : instance_(other.instance_)
    {
        if (instance_)
        {
            CFRetain(instance_);
        }
    }

    CFRef(CFRef &&other) : instance_(other.instance_)
    {
        other.instance_ = nullptr;
    }

    CFRef &operator=(CFRef &&other)
    {
        Reset(other.Release());
        return *this;
    }

    ~CFRef()
    {
        if (instance_ != nullptr)
        {
            CFRelease(instance_);
        }
        instance_ = nullptr;
    }

    void Reset(T instance = nullptr)
    {
        if (instance_ != nullptr)
        {
            CFRelease(instance_);
        }

        instance_ = instance;
    }

    [[nodiscard]] T Release()
    {
        auto instance = instance_;
        instance_ = nullptr;
        return instance;
    }

    // NOLINTNEXTLINE(google-explicit-constructor)
    operator T() const { return instance_; }

    explicit operator bool() const { return instance_ != nullptr; }

private:
    T instance_;

    CFRef &operator=(const CFRef &) = delete;
};

void RegisterSystemFonts(skia::textlayout::TypefaceFontProvider &dynamic_font_manager);

#endif // CSKIA_UTILS_MACOS_H