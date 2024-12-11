// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CSkia
import Foundation

/// An implementation of ``Renderer`` using Skia as the backend.
public class SkiaRenderer: Renderer {
    public init() {
        loadICU()
    }

    public func createParagraphBuilder(_ style: ParagraphStyle) -> ParagraphBuilder {
        SkiaParagraphBuilder(style)
    }

    public func decodeImageFromData(_ data: Data) -> AnimatedImage? {
        SkiaAnimatedImage.decode(data)
    }

    public func createPath() -> any Path {
        SkiaPath()
    }
}
