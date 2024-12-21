// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The singleton instance of the [Backend] used by the framework during the
/// entire lifetime of the application.
public var backend: Backend = SDLBackend.shared

/// The singleton instance of the [Renderer] used by the framework during the
/// entire lifetime of the application. This is a convenience property that
/// returns the renderer of the current backend.
public var renderer: Renderer {
    backend.renderer
}
