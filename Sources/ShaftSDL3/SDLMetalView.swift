// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Shaft

#if os(macOS)
    import Foundation
    import Metal
    import QuartzCore
    import SwiftSDL3

    /// A NativeView implementation that uses SDL window as backend and Metal for
    /// rendering.
    public class SDLMetalView: SDLView {

        internal required init?(backend: SDLBackend) {
            super.init(backend: backend)

            self.sdlMetalView = SDL_Metal_CreateView(sdlWindow)

            self.metalLayer = unsafeBitCast(
                SDL_Metal_GetLayer(sdlMetalView)!,
                to: CAMetalLayer.self
            )
            self.metalLayer.device = (backend.renderer as! MetalRenderer).device
            self.metalLayer.pixelFormat = .bgra8Unorm
            self.metalLayer.presentsWithTransaction = true

            // This must be added after SDL_Metal_CreateView to ensure the drawable
            // size is updated before the callback is invoked.
            startResizeListener()
        }

        /// The Metal layer used for rendering.
        public var metalLayer: CAMetalLayer!

        private var sdlMetalView: SDL_MetalView!

        private func acquireCanvas(_ texture: MTLTexture) -> DirectCanvas {
            return (backend!.renderer as! MetalRenderer).createMetalCanvas(
                texture: texture,
                size: physicalSize
            )
        }

        /// The actual rendering logic that runs on the raster thread.
        override func performRender(_ layerTree: LayerTree) {
            autoreleasepool {
                let drawable = metalLayer.nextDrawable()!
                let texture = drawable.texture
                let canvas = acquireCanvas(texture)

                canvas.clear(color: .init(0x0000_0000))

                // Record painting instructions to the canvas.
                layerTree.paint(
                    context: LayerPaintContext(canvas: canvas)
                )

                // Submit painting commands
                canvas.flush()

                drawable.present()
            }
        }

        public override var rawView: UnsafeMutableRawPointer? {
            sdlMetalView
        }
    }

#endif
