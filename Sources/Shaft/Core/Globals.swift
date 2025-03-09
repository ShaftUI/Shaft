// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The singleton instance of the [Backend] used by the framework during the
/// entire lifetime of the application.
public var backend: Backend {
    get {
        guard let backend = _backend else {
            preconditionFailure(
                "No backend has been set. In most cases you can simply call `useDefaultBackend()` to configure the default backend and renderer."
            )
        }
        return backend
    }
    set {
        if _backend != nil {
            preconditionFailure("The backend has already been set.")
        }
        _backend = newValue
    }
}
private var _backend: Backend?

/// The singleton instance of the [Renderer] used by the framework during the
/// entire lifetime of the application. This is a convenience property that
/// returns the renderer of the current backend.
public var renderer: Renderer {
    backend.renderer
}
