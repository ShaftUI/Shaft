// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The singleton instance of the [Backend] used by the framework during the
/// entire lifetime of the application.
public var backend: Backend = SDLBackend.shared
