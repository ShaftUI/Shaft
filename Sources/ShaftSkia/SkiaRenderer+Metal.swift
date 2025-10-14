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

        /// Maps MTLPixelFormat to the corresponding SkColorType.
        /// Returns the appropriate Skia color type for the given Metal pixel format,
        /// or BGRA_8888 as a safe fallback for unsupported formats.
        private func skColorType(from pixelFormat: MTLPixelFormat) -> SkColorType {
            switch pixelFormat {
            case .bgra8Unorm, .bgra8Unorm_srgb:
                return kBGRA_8888_SkColorType
            case .rgba8Unorm, .rgba8Unorm_srgb:
                return kRGBA_8888_SkColorType
            case .rgba16Float:
                return kRGBA_F16_SkColorType
            case .rgba32Float:
                return kRGBA_F32_SkColorType
            case .bgra10_xr, .bgr10_xr:
                return kBGR_101010x_XR_SkColorType
            case .r8Unorm:
                return kR8_unorm_SkColorType
            case .rg8Unorm:
                return kR8G8_unorm_SkColorType
            case .rgba16Unorm:
                return kR16G16B16A16_unorm_SkColorType
            default:
                // Fallback to most common format for compatibility
                return kBGRA_8888_SkColorType
            }
        }

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

            // Detect the color type from the texture's pixel format
            let colorType = skColorType(from: texture.pixelFormat)

            let skImage = SkImages.AdoptTextureFrom(
                gr_direct_context_unwrap(&grMtlDirectContext),
                grBackendTexture,
                GrSurfaceOrigin.init(0),
                colorType,
                kPremul_SkAlphaType,
            )

            return SkiaImage(skImage: skImage)
        }
    }

#endif
