// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import SwiftSDL3

/// A NativeView implementation that uses SDL window as backend.
public class SDLOpenGLView: SDLView {
    internal required init?(backend: SDLBackend) {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3)
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0)
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES)

        super.init(backend: backend)

        sdlGLContext = SDL_GL_CreateContext(sdlWindow)!

        startResizeListener()
    }

    deinit {
        SDL_GL_DestroyContext(sdlGLContext)
    }

    /// The GL context created on top of the SDL window. Valid during the
    /// lifetime of the view.
    private var sdlGLContext: SDL_GLContext!

    /// The canvas used to paint the view. Created at the first render call and
    /// recreated whenever the window size changes.
    private var canvas: DirectCanvas!

    /// Recreates the surface to match the current window size.
    ///
    /// This method should only be called on the raster thread to avoid the
    /// surface being destroyed while it is being painted to.
    private func updateCanvas() {
        canvas = (backend!.renderer as! GLRenderer).createGLCanvas(fbo: 0, size: physicalSize)
    }

    /// The actual rendering logic that runs on the raster thread.
    override func performRender(_ layerTree: LayerTree) {
        guard SDL_GL_MakeCurrent(sdlWindow, sdlGLContext) else {
            assertionFailure(
                "Could not make GL context current: \(String(cString: SDL_GetError()))"
            )
            return
        }

        if canvas == nil || canvas!.size != physicalSize {
            updateCanvas()
        }

        // Record painting instructions to the canvas.
        // sk_canvas_clear(skCanvas, 0x0000_0000)
        canvas.clear(color: .init(0x0000_0000))

        layerTree.paint(
            context: LayerPaintContext(canvas: canvas)
        )

        // Submit painting commands
        canvas.flush()

        // Present the rendered frame to the screen.
        SDL_GL_SwapWindow(sdlWindow)
    }
}
