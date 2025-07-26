// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Fetch
import Foundation

/// Configuration information passed to the [ImageProvider.resolve] method to
/// select a specific image.
public struct ImageConfiguration: Equatable {
    /// Creates an object holding the configuration information for an [ImageProvider].
    ///
    /// All the arguments are optional. Configuration information is merely
    /// advisory and best-effort.
    public init(
        // bundle: AssetBundle? = nil,
        devicePixelRatio: Float? = nil,
        // locale: Locale? = nil,
        textDirection: TextDirection? = nil,
        size: Size? = nil
            // platform: TargetPlatform? = nil
    ) {
        // self.bundle = bundle
        self.devicePixelRatio = devicePixelRatio
        // self.locale = locale
        self.textDirection = textDirection
        self.size = size
        // self.platform = platform
    }

    /// The preferred [AssetBundle] to use if the [ImageProvider] needs one and
    /// does not have one already selected.
    //   let bundle: AssetBundle?

    /// The device pixel ratio where the image will be shown.
    let devicePixelRatio: Float?

    /// The language and region for which to select the image.
    //   let locale: ui.Locale?

    /// The reading direction of the language for which to select the image.
    let textDirection: TextDirection?

    /// The size at which the image will be rendered.
    let size: Size?

    /// The [TargetPlatform] for which assets should be used. This allows images
    /// to be specified in a platform-neutral fashion yet use different assets on
    /// different platforms, to match local conventions e.g. for color matching or
    /// shadows.
    //   let platform: TargetPlatform?

    /// An image configuration that provides no additional information.
    ///
    /// Useful when resolving an [ImageProvider] without any context.
    static let empty = Self()

    public func copyWith(
        // bundle: AssetBundle? = nil,
        devicePixelRatio: Float? = nil,
        // locale: Locale? = nil,
        textDirection: TextDirection? = nil,
        size: Size? = nil
            // platform: TargetPlatform? = nil
    ) -> Self {
        Self(
            // bundle: bundle ?? self.bundle,
            devicePixelRatio: devicePixelRatio ?? self.devicePixelRatio,
            // locale: locale ?? self.locale,
            textDirection: textDirection ?? self.textDirection,
            size: size ?? self.size
                // platform: platform ?? self.platform
        )
    }
}

public protocol ImageProvider: Equatable {
    func resolve(configuration: ImageConfiguration) -> AsyncStream<NativeImage>

    func isEqualTo(_ other: any ImageProvider) -> Bool
}

extension ImageProvider {
    public func isEqualTo(_ other: any ImageProvider) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}

// Decode and stream an image from a data provider.
private func decodeAndStreamImage(from dataProvider: @escaping () async throws -> Data)
    -> AsyncStream<NativeImage>
{
    AsyncStream { continuation in
        Task {
            let data: Data
            do {
                data = try await dataProvider()
            } catch {
                // Optionally handle error (e.g., log or yield a placeholder image)
                return
            }
            let animatedImage = backend.renderer.decodeImageFromData(data)
            guard let animatedImage else {
                return
            }
            while let frame = animatedImage.getNextFrame() {
                continuation.yield(frame.image)
                if let duration = frame.duration {
                    try? await Task.sleep(for: duration)
                } else {
                    break
                }
            }
        }
    }
}

public struct NetworkImage: Equatable, ImageProvider {
    public init(url: URL) {
        self.url = url
    }

    public let url: URL

    public func resolve(configuration: ImageConfiguration) -> AsyncStream<NativeImage> {
        decodeAndStreamImage(from: { try await fetch(self.url) })
    }
}

public struct MemoryImage: Equatable, ImageProvider {
    public init(data: Data) {
        self.data = data
    }

    public let data: Data

    public func resolve(configuration: ImageConfiguration) -> AsyncStream<NativeImage> {
        decodeAndStreamImage(from: { self.data })
    }
}
