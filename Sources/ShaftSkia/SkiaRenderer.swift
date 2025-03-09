// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CSkia
import Foundation
import Shaft

/// An implementation of ``Renderer`` using Skia as the backend.
public class SkiaRenderer: Renderer {
    public init() {
    }

    public func createParagraphBuilder(_ style: ParagraphStyle) -> ParagraphBuilder {
        SkiaParagraphBuilder(style, fontCollection: _fontCollection)
    }

    public func createTextBlob(_ glyphs: [GlyphID], positions: [Offset], font: any Font)
        -> any TextBlob
    {
        SkiaTextBlob(glyphs, positions: positions, font: font)
    }

    public func decodeImageFromData(_ data: Data) -> AnimatedImage? {
        SkiaAnimatedImage.decode(data)
    }

    public func createPath() -> any Path {
        SkiaPath()
    }

    public let _fontCollection = SkiaFontCollection()
    public var fontCollection: FontCollection { _fontCollection }
}

#if canImport(Metal)
    import Metal
    public func defaultSkiaRenderer() -> Renderer {
        let metalDevice = MTLCreateSystemDefaultDevice()!
        let metalCommandQueue = metalDevice.makeCommandQueue()!
        return SkiaMetalRenderer(
            device: metalDevice,
            queue: metalCommandQueue
        )
    }
#else
    public func defaultSkiaRenderer() -> Renderer {
        return SkiaGLRenderer()
    }
#endif
