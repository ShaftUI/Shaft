// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CSkia
import Foundation

public class SkiaImage: NativeImage {
    public init(skImage: SkImage_sp) {
        self.skImage = skImage
    }

    public var skImage: SkImage_sp

    public var width: UInt {
        UInt(sk_image_get_width(&skImage))
    }

    public var height: UInt {
        UInt(sk_image_get_height(&skImage))
    }
}

/// A skia-based implementation of [AnimatedImage].
public class SkiaAnimatedImage: AnimatedImage {
    public static func decode(_ data: Data) -> AnimatedImage? {
        // use sk_animated_image_decode(data, 1)
        let skAnimatedImage = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            sk_animated_image_create(ptr.baseAddress, ptr.count)
        }

        if skAnimatedImage.__convertToBool() == false {
            return nil
        }

        return SkiaAnimatedImage(skAnimatedImage: skAnimatedImage)
    }

    private init(skAnimatedImage: SkAnimatedImage_sp) {
        self.skAnimatedImage = skAnimatedImage
    }

    private var skAnimatedImage: SkAnimatedImage_sp

    public var frameCount: UInt {
        UInt(sk_animated_image_get_frame_count(&skAnimatedImage))
    }

    public var repetitionCount: UInt? {
        let count = sk_animated_image_get_repetition_count(&skAnimatedImage)
        return count < 0 ? nil : UInt(count)
    }

    public func getNextFrame() -> FrameInfo? {
        let duration = sk_animated_image_decode_next_frame(&skAnimatedImage)
        let skImage = sk_animated_image_get_current_frame(&skAnimatedImage)
        if skImage.__convertToBool() == false {
            return nil
        }
        return FrameInfo(
            duration: duration > 0 ? Duration.milliseconds(duration) : nil,
            image: SkiaImage(skImage: skImage)
        )
    }
}
