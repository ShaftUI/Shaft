// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import Shaft

#if canImport(Metal)

    import CSkia
    import Foundation
    import Metal

    public class SkiaMetalRenderer: SkiaRenderer, MetalRenderer {
        public init(device: MTLDevice, queue: MTLCommandQueue) {
            self.device = device
            self.queue = queue
            super.init()
        }

        public let device: MTLDevice

        public let queue: MTLCommandQueue

        lazy var grMtlBackendContext: GrMtlBackendContext = {
            var grMtlBackendContext = GrMtlBackendContext()
            grMtlBackendContext.fDevice.reset(Unmanaged.passRetained(device).toOpaque())
            grMtlBackendContext.fQueue.reset(Unmanaged.passRetained(queue).toOpaque())
            return grMtlBackendContext
        }()

        lazy var grMtlDirectContext: GrDirectContext_sp = {
            gr_mtl_direct_context_make(&grMtlBackendContext)
        }()

        public func createMetalCanvas(
            texture: MTLTexture,
            size: ISize
        ) -> DirectCanvas {
            var grMTLTextureInfo = GrMtlTextureInfo()
            grMTLTextureInfo.fTexture.reset(Unmanaged.passRetained(texture).toOpaque())

            let mtlBackendTexture = GrBackendTextures.MakeMtl(
                Int32(texture.width),
                Int32(texture.height),
                skgpu.Mipmapped.no,
                grMTLTextureInfo
            )

            let skSurface = SkSurfaces.WrapBackendTexture(
                gr_direct_context_unwrap(&grMtlDirectContext),  // Gr context
                mtlBackendTexture,  // render target
                GrSurfaceOrigin.init(0),  // GrSurfaceOrigin.kTopLeft_GrSurfaceOrigin,
                1,
                kBGRA_8888_SkColorType,  // color type
                color_space_new_null(),  // colorspace
                nil,  // surface properties
                nil,
                nil
            )

            return SkiaCanvas(skSurface, grMtlDirectContext, size)
        }

        public func createMetalImage(texture: any MTLTexture) -> any NativeImage {
            var grMtlTextureInfo = GrMtlTextureInfo()
            grMtlTextureInfo.fTexture.reset(Unmanaged.passRetained(texture).toOpaque())

            let grBackendTexture = GrBackendTextures.MakeMtl(
                Int32(texture.width),
                Int32(texture.height),
                skgpu.Mipmapped.no,
                grMtlTextureInfo
            )

            let skImage = SkImages.AdoptTextureFrom(
                gr_direct_context_unwrap(&grMtlDirectContext),
                grBackendTexture,
                GrSurfaceOrigin.init(0),
                kBGRA_8888_SkColorType
            )

            return SkiaImage(skImage: skImage)
        }
    }

#endif
