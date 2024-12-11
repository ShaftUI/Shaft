// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The platform that user interaction should adapt to target.
///
/// The [defaultTargetPlatform] getter returns the current platform.
///
/// When using the "flutter run" command, the "o" key will toggle between
/// values of this enum when updating [debugDefaultTargetPlatformOverride].
/// This lets one test how the application will work on various platforms
/// without having to switch emulators or physical devices.
//
// When you add values here, make sure to also add them to
// nextPlatform() in flutter_tools/lib/src/resident_runner.dart so that
// the tool can support the new platform for its "o" option.
public enum TargetPlatform {
    /// Android: <https://www.android.com/>
    case android

    /// Fuchsia: <https://fuchsia.dev/fuchsia-src/concepts>
    case fuchsia

    /// iOS: <https://www.apple.com/ios/>
    case iOS

    /// Linux: <https://www.linux.org>
    case linux

    /// macOS: <https://www.apple.com/macos>
    case macOS

    /// Windows: <https://www.windows.com>
    case windows
}
