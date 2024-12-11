// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CSkia
import Foundation

/// An implementation of ``Renderer`` using Skia as the backend.
public class SkiaGLRenderer: SkiaRenderer, GLRenderer {
    /// Cached GrDirectContext for creating surfaces.
    private lazy var glGrDirectContext: GrDirectContext_sp = {
        var interface = gr_glinterface_create_native_interface()
        return gr_direct_context_make_gl(&interface)
    }()

    public func createGLCanvas(fbo: UInt, size: ISize) -> DirectCanvas {
        let grGLInfo = GrGLFramebufferInfo(
            fFBOID: 0,
            fFormat: 0x8058,  // UInt32(GL_RGBA8)
            fProtected: skgpu.Protected.no
        )

        let grRenderTarget = GrBackendRenderTargets.MakeGL(
            Int32(size.width),
            Int32(size.height),
            0,
            0,
            grGLInfo
        )

        // let colorSpace = color_space_new_srgb()
        let colorSpace = color_space_new_null()

        let skSurface = SkSurfaces.WrapBackendRenderTarget(
            gr_direct_context_unwrap(&glGrDirectContext),  // Gr context
            grRenderTarget,  // render target
            GrSurfaceOrigin.init(1),  // GrSurfaceOrigin.kBottomLeft_GrSurfaceOrigin,
            kRGBA_8888_SkColorType,  // color type
            colorSpace,  // colorspace
            nil,  // surface properties
            nil,
            nil
        )

        return SkiaCanvas(skSurface, glGrDirectContext, size)
    }
}
