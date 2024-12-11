// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// A renderer converts high-level drawing operations into low-level drawing
/// commands that can be executed by the underlying graphics API.
public protocol Renderer {
    func createParagraphBuilder(_ style: ParagraphStyle) -> ParagraphBuilder

    func decodeImageFromData(_ data: Data) -> AnimatedImage?

    func createPath() -> Path
}

public protocol GLRenderer: Renderer {
    func createGLCanvas(fbo: UInt, size: ISize) -> DirectCanvas
}

#if canImport(Metal)

    import Foundation
    import Metal

    public protocol MetalRenderer: Renderer {
        var device: MTLDevice { get }

        var queue: MTLCommandQueue { get }

        func createMetalCanvas(texture: MTLTexture, size: ISize) -> DirectCanvas

        func createMetalImage(texture: MTLTexture) -> NativeImage

    }

#endif
