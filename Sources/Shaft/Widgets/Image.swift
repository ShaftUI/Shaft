// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Signature used by [Image.frameBuilder] to control the widget that will be
/// used when an [Image] is built.
///
/// The `child` argument contains the default image widget and is guaranteed to
/// be non-null. Typically, this builder will wrap the `child` widget in some
/// way and return the wrapped widget. If this builder returns `child` directly,
/// it will yield the same result as if [Image.frameBuilder] was null.
///
/// The `frame` argument specifies the index of the current image frame being
/// rendered. It will be null before the first image frame is ready, and zero
/// for the first image frame. For single-frame images, it will never be greater
/// than zero. For multi-frame images (such as animated GIFs), it will increase
/// by one every time a new image frame is shown (including when the image
/// animates in a loop).
///
/// The `wasSynchronouslyLoaded` argument specifies whether the image was
/// available synchronously (on the same
/// [rendering pipeline frame](rendering/RendererBinding/drawFrame.html) as the
/// `Image` widget itself was created) and thus able to be painted immediately.
/// If this is false, then there was one or more rendering pipeline frames where
/// the image wasn't yet available to be painted. For multi-frame images (such
/// as animated GIFs), the value of this argument will be the same for all image
/// frames. In other words, if the first image frame was available immediately,
/// then this argument will be true for all image frames.
///
/// This builder must not return null.
///
/// See also:
///
///  * [Image.frameBuilder], which makes use of this signature in the [Image]
///    widget.
public typealias ImageFrameBuilder = (
    _ context: BuildContext,
    _ child: Widget,
    _ frame: Int?,
    _ wasSynchronouslyLoaded: Bool
) -> Widget

/// A widget that displays an image.
///
/// Several constructors are provided for the various ways that an image can be
/// specified:
///
///  * [Image.new], for obtaining an image from an [ImageProvider].
///  * [Image.asset], for obtaining an image from an [AssetBundle]
///    using a key.
///  * [Image.network], for obtaining an image from a URL.
///  * [Image.file], for obtaining an image from a [File].
///  * [Image.memory], for obtaining an image from a [Uint8List].
public final class Image: StatefulWidget {
    public init(
        image: any ImageProvider,
        frameBuilder: ImageFrameBuilder? = nil,
        width: Float? = nil,
        height: Float? = nil,
        color: Color? = nil,
        opacity: (any Animation<Double>)? = nil,
        filterQuality: FilterQuality = .low,
        colorBlendMode: BlendMode = .srcIn,
        fit: BoxFit? = nil,
        alignment: any AlignmentGeometry = .center,
        `repeat`: ImageRepeat = .noRepeat,
        centerSlice: Rect? = nil,
        matchTextDirection: Bool = false,
        gaplessPlayback: Bool = false,
        // semanticLabel: String? = nil,
        // excludeFromSemantics: Bool,
        isAntiAlias: Bool = false
    ) {
        self.image = image
        self.frameBuilder = frameBuilder
        self.width = width
        self.height = height
        self.color = color
        self.opacity = opacity
        self.filterQuality = filterQuality
        self.colorBlendMode = colorBlendMode
        self.fit = fit
        self.alignment = alignment
        self.`repeat` = `repeat`
        self.centerSlice = centerSlice
        self.matchTextDirection = matchTextDirection
        self.gaplessPlayback = gaplessPlayback
        // self.semanticLabel = semanticLabel
        // self.excludeFromSemantics = excludeFromSemantics
        self.isAntiAlias = isAntiAlias
    }

    public static func network(
        url: URL,
        frameBuilder: ImageFrameBuilder? = nil,
        width: Float? = nil,
        height: Float? = nil,
        color: Color? = nil,
        opacity: (any Animation<Double>)? = nil,
        filterQuality: FilterQuality = .low,
        colorBlendMode: BlendMode = .srcIn,
        fit: BoxFit? = nil,
        alignment: any AlignmentGeometry = .center,
        `repeat`: ImageRepeat = .noRepeat,
        centerSlice: Rect? = nil,
        matchTextDirection: Bool = false,
        gaplessPlayback: Bool = false,
        // semanticLabel: String? = nil,
        // excludeFromSemantics: Bool,
        isAntiAlias: Bool = false
    ) -> Image {
        Image(
            image: NetworkImage(url: url),
            frameBuilder: frameBuilder,
            width: width,
            height: height,
            color: color,
            opacity: opacity,
            filterQuality: filterQuality,
            colorBlendMode: colorBlendMode,
            fit: fit,
            alignment: alignment,
            repeat: `repeat`,
            centerSlice: centerSlice,
            matchTextDirection: matchTextDirection,
            gaplessPlayback: gaplessPlayback,
            // semanticLabel: semanticLabel,
            // excludeFromSemantics: excludeFromSemantics,
            isAntiAlias: isAntiAlias
        )
    }

    /// The image to display.
    public let image: any ImageProvider

    /// A builder function responsible for creating the widget that represents
    /// this image.
    ///
    /// If this is null, this widget will display an image that is painted as
    /// soon as the first image frame is available (and will appear to "pop" in
    /// if it becomes available asynchronously). Callers might use this builder to
    /// add effects to the image (such as fading the image in when it becomes
    /// available) or to display a placeholder widget while the image is loading.
    ///
    /// To have finer-grained control over the way that an image's loading
    /// progress is communicated to the user, see [loadingBuilder].
    ///
    /// ## Chaining with [loadingBuilder]
    ///
    /// If a [loadingBuilder] has _also_ been specified for an image, the two
    /// builders will be chained together: the _result_ of this builder will
    /// be passed as the `child` argument to the [loadingBuilder]. For example,
    /// consider the following builders used in conjunction:
    ///
    /// ```swift
    /// Image(
    ///   image: _image,
    ///   frameBuilder: (BuildContext context, Widget child, int? frame, bool? wasSynchronouslyLoaded) {
    ///     return Padding(
    ///       padding: const EdgeInsets.all(8.0),
    ///       child: child,
    ///     );
    ///   },
    ///   loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    ///     return Center(child: child);
    ///   },
    /// )
    ///
    ///
    /// In this example, the widget hierarchy will contain the following:
    ///
    ///
    /// Center(
    ///   child: Padding(
    ///     padding: const EdgeInsets.all(8.0),
    ///     child: image,
    ///   ),
    /// ),
    /// ```
    public let frameBuilder: ImageFrameBuilder?

    /// A builder that specifies the widget to display to the user while an image
    /// is still loading.
    ///
    /// If this is null, and the image is loaded incrementally (e.g. over a
    /// network), the user will receive no indication of the progress as the
    /// bytes of the image are loaded.
    ///
    /// For more information on how to interpret the arguments that are passed to
    /// this builder, see the documentation on [ImageLoadingBuilder].
    ///
    /// ## Performance implications
    ///
    /// If a [loadingBuilder] is specified for an image, the [Image] widget is
    /// likely to be rebuilt on every
    /// [rendering pipeline frame](rendering/RendererBinding/drawFrame.html) until
    /// the image has loaded. This is useful for cases such as displaying a loading
    /// progress indicator, but for simpler cases such as displaying a placeholder
    /// widget that doesn't depend on the loading progress (e.g. static "loading"
    /// text), [frameBuilder] will likely work and not incur as much cost.
    ///
    /// ## Chaining with [frameBuilder]
    ///
    /// If a [frameBuilder] has _also_ been specified for an image, the two
    /// builders will be chained together: the `child` argument to this
    /// builder will contain the _result_ of the [frameBuilder]. For example,
    /// consider the following builders used in conjunction:
    ///
    /// Run against a real-world image on a slow network, the previous example
    /// renders the following loading progress indicator while the image loads
    /// before rendering the completed image.
    ///
    /// {@animation 400 400 https://flutter.github.io/assets-for-api-docs/assets/widgets/loading_progress_image.mp4}
    // public let loadingBuilder: ImageLoadingBuilder?

    /// A builder function that is called if an error occurs during image loading.
    ///
    /// If this builder is not provided, any exceptions will be reported to
    /// [FlutterError.onError]. If it is provided, the caller should either handle
    /// the exception by providing a replacement widget, or rethrow the exception.
    // public let errorBuilder: ImageErrorWidgetBuilder?

    /// If non-null, require the image to have this width (in logical pixels).
    ///
    /// If null, the image will pick a size that best preserves its intrinsic
    /// aspect ratio.
    ///
    /// It is strongly recommended that either both the [width] and the [height]
    /// be specified, or that the widget be placed in a context that sets tight
    /// layout constraints, so that the image does not change size as it loads.
    /// Consider using [fit] to adapt the image's rendering to fit the given width
    /// and height if the exact image dimensions are not known in advance.
    public let width: Float?

    /// If non-null, require the image to have this height (in logical pixels).
    ///
    /// If null, the image will pick a size that best preserves its intrinsic
    /// aspect ratio.
    ///
    /// It is strongly recommended that either both the [width] and the [height]
    /// be specified, or that the widget be placed in a context that sets tight
    /// layout constraints, so that the image does not change size as it loads.
    /// Consider using [fit] to adapt the image's rendering to fit the given width
    /// and height if the exact image dimensions are not known in advance.
    public let height: Float?

    /// If non-null, this color is blended with each image pixel using [colorBlendMode].
    public let color: Color?

    /// If non-null, the value from the [Animation] is multiplied with the opacity
    /// of each image pixel before painting onto the canvas.
    ///
    /// This is more efficient than using [FadeTransition] to change the opacity
    /// of an image, since this avoids creating a new composited layer. Composited
    /// layers may double memory usage as the image is painted onto an offscreen
    /// render target.
    ///
    /// See also:
    ///
    ///  * [AlwaysStoppedAnimation], which allows you to create an [Animation]
    ///    from a single opacity value.
    public let opacity: (any Animation<Double>)?

    /// The rendering quality of the image.
    ///
    /// {@template flutter.widgets.image.filterQuality}
    /// If the image is of a high quality and its pixels are perfectly aligned
    /// with the physical screen pixels, extra quality enhancement may not be
    /// necessary. If so, then [FilterQuality.none] would be the most efficient.
    ///
    /// If the pixels are not perfectly aligned with the screen pixels, or if the
    /// image itself is of a low quality, [FilterQuality.none] may produce
    /// undesirable artifacts. Consider using other [FilterQuality] values to
    /// improve the rendered image quality in this case. Pixels may be misaligned
    /// with the screen pixels as a result of transforms or scaling.
    ///
    /// Defaults to [FilterQuality.medium].
    ///
    /// See also:
    ///
    ///  * [FilterQuality], the enum containing all possible filter quality
    ///    options.
    /// {@endtemplate}
    public let filterQuality: FilterQuality

    /// Used to combine [color] with this image.
    ///
    /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
    /// the source and this image is the destination.
    ///
    /// See also:
    ///
    ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
    public let colorBlendMode: BlendMode

    /// How to inscribe the image into the space allocated during layout.
    ///
    /// The default varies based on the other fields. See the discussion at
    /// [paintImage].
    public let fit: BoxFit?

    /// How to align the image within its bounds.
    ///
    /// The alignment aligns the given position in the image to the given position
    /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
    /// -1.0) aligns the image to the top-left corner of its layout bounds, while an
    /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
    /// image with the bottom right corner of its layout bounds. Similarly, an
    /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
    /// middle of the bottom edge of its layout bounds.
    ///
    /// To display a subpart of an image, consider using a [CustomPainter] and
    /// [Canvas.drawImageRect].
    ///
    /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
    /// [AlignmentDirectional]), then an ambient [Directionality] widget
    /// must be in scope.
    ///
    /// Defaults to [Alignment.center].
    ///
    /// See also:
    ///
    ///  * [Alignment], a class with convenient constants typically used to
    ///    specify an [AlignmentGeometry].
    ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
    ///    relative to text direction.
    public let alignment: any AlignmentGeometry

    /// How to paint any portions of the layout bounds not covered by the image.
    public let `repeat`: ImageRepeat

    /// The center slice for a nine-patch image.
    ///
    /// The region of the image inside the center slice will be stretched both
    /// horizontally and vertically to fit the image into its destination. The
    /// region of the image above and below the center slice will be stretched
    /// only horizontally and the region of the image to the left and right of
    /// the center slice will be stretched only vertically.
    public let centerSlice: Rect?

    /// Whether to paint the image in the direction of the [TextDirection].
    ///
    /// If this is true, then in [TextDirection.ltr] contexts, the image will be
    /// drawn with its origin in the top left (the "normal" painting direction for
    /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
    /// a scaling factor of -1 in the horizontal direction so that the origin is
    /// in the top right.
    ///
    /// This is occasionally used with images in right-to-left environments, for
    /// images that were designed for left-to-right locales. Be careful, when
    /// using this, to not flip images with integral shadows, text, or other
    /// effects that will look incorrect when flipped.
    ///
    /// If this is true, there must be an ambient [Directionality] widget in
    /// scope.
    public let matchTextDirection: Bool

    /// Whether to continue showing the old image (true), or briefly show nothing
    /// (false), when the image provider changes. The default value is false.
    ///
    /// ## Design discussion
    ///
    /// ### Why is the default value of [gaplessPlayback] false?
    ///
    /// Having the default value of [gaplessPlayback] be false helps prevent
    /// situations where stale or misleading information might be presented.
    /// Consider the following case:
    ///
    /// We have constructed a 'Person' widget that displays an avatar [Image] of
    /// the currently loaded person along with their name. We could request for a
    /// new person to be loaded into the widget at any time. Suppose we have a
    /// person currently loaded and the widget loads a new person. What happens
    /// if the [Image] fails to load?
    ///
    /// * Option A ([gaplessPlayback] = false): The new person's name is coupled
    /// with a blank image.
    ///
    /// * Option B ([gaplessPlayback] = true): The widget displays the avatar of
    /// the previous person and the name of the newly loaded person.
    ///
    /// This is why the default value is false. Most of the time, when you change
    /// the image provider you're not just changing the image, you're removing the
    /// old widget and adding a new one and not expecting them to have any
    /// relationship. With [gaplessPlayback] on you might accidentally break this
    /// expectation and re-use the old widget.
    public let gaplessPlayback: Bool

    /// A Semantic description of the image.
    ///
    /// Used to provide a description of the image to TalkBack on Android, and
    /// VoiceOver on iOS.
    // public let semanticLabel: String?

    /// Whether to exclude this image from semantics.
    ///
    /// Useful for images which do not contribute meaningful information to an
    /// application.
    // public let excludeFromSemantics: Bool

    /// Whether to paint the image with anti-aliasing.
    ///
    /// Anti-aliasing alleviates the sawtooth artifact when the image is rotated.
    public let isAntiAlias: Bool

    public func createState() -> some State<Image> {
        ImageState()
    }
}

public final class ImageState: State<Image> {
    public override func initState() {
        super.initState()
    }

    public override func didChangeDependencies() {
        super.didChangeDependencies()
        listener?.cancel()
        resolveImage()
    }

    public override func didUpdateWidget(_ oldWidget: Image) {
        super.didUpdateWidget(oldWidget)
        if !widget.image.isEqualTo(oldWidget.image) {
            listener?.cancel()
            resolveImage()
        }
    }

    public override func dispose() {
        listener?.cancel()
        super.dispose()
    }

    var listener: Task<(), Never>?

    private func resolveImage() {
        frameNumber = 0

        let size: Size? =
            if let width = widget.width, let height = widget.height {
                Size(width, height)
            } else {
                nil
            }

        let configuration = ImageConfiguration(
            size: size
        )

        let stream = widget.image.resolve(configuration: configuration)

        listener = Task {
            for await image in stream {
                if Task.isCancelled {
                    return
                }
                backend.runOnMainThread { [self] in
                    handleImageFrame(image)
                }
            }
        }
    }

    private var image: NativeImage?

    private var frameNumber = 0

    private func handleImageFrame(_ image: NativeImage) {
        setState {
            self.image = image
            frameNumber += 1
        }
    }

    public override func build(context: BuildContext) -> Widget {
        var result: Widget = RawImage(
            // Do not clone the image, because RawImage is a stateless wrapper.
            // The image will be disposed by this state object when it is not needed
            // anymore, such as when it is unmounted or when the image stream pushes
            // a new image.
            image: image,
            width: widget.width,
            height: widget.height,
            scale: 1.0,
            color: widget.color,
            // opacity: widget.opacity,
            filterQuality: widget.filterQuality,
            colorBlendMode: widget.colorBlendMode,
            fit: widget.fit,
            alignment: widget.alignment,
            repeat: widget.repeat,
            centerSlice: widget.centerSlice,
            matchTextDirection: widget.matchTextDirection,
            isAntiAlias: widget.isAntiAlias
        )

        if let frameBuilder = widget.frameBuilder {
            result = frameBuilder(context, result, frameNumber, false)
        }

        return result
    }
}
