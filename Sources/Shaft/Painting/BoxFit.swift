// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// How a box should be inscribed into another box.
///
/// See also:
///
///  * [applyBoxFit], which applies the sizing semantics of these values (though
///    not the alignment semantics).
public enum BoxFit {
    /// Fill the target box by distorting the source's aspect ratio.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/painting/box_fit_fill.png)
    case fill

    /// As large as possible while still containing the source entirely within the
    /// target box.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/painting/box_fit_contain.png)
    case contain

    /// As small as possible while still covering the entire target box.
    ///
    /// {@template flutter.painting.BoxFit.cover}
    /// To actually clip the content, use `clipBehavior: Clip.hardEdge` alongside
    /// this in a [FittedBox].
    /// {@endtemplate}
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/painting/box_fit_cover.png)
    case cover

    /// Make sure the full width of the source is shown, regardless of
    /// whether this means the source overflows the target box vertically.
    ///
    /// {@macro flutter.painting.BoxFit.cover}
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/painting/box_fit_fitWidth.png)
    case fitWidth

    /// Make sure the full height of the source is shown, regardless of
    /// whether this means the source overflows the target box horizontally.
    ///
    /// {@macro flutter.painting.BoxFit.cover}
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/painting/box_fit_fitHeight.png)
    case fitHeight

    /// Align the source within the target box (by default, centering) and discard
    /// any portions of the source that lie outside the box.
    ///
    /// The source image is not resized.
    ///
    /// {@macro flutter.painting.BoxFit.cover}
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/painting/box_fit_none.png)
    case none

    /// Align the source within the target box (by default, centering) and, if
    /// necessary, scale the source down to ensure that the source fits within the
    /// box.
    ///
    /// This is the same as `contain` if that would shrink the image, otherwise it
    /// is the same as `none`.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/painting/box_fit_scaleDown.png)
    case scaleDown
}

/// The pair of sizes returned by [applyBoxFit].
public struct FittedSizes {
    /// The size of the part of the input to show on the output.
    public let source: Size

    /// The size of the part of the output on which to show the input.
    public let destination: Size

    /// Creates an object to store a pair of sizes,
    /// as would be returned by [applyBoxFit].
    public init(source: Size, destination: Size) {
        self.source = source
        self.destination = destination
    }
}

/// Apply a [BoxFit] value.
///
/// The arguments to this method, in addition to the [BoxFit] value to apply,
/// are two sizes, ostensibly the sizes of an input box and an output box.
/// Specifically, the `inputSize` argument gives the size of the complete source
/// that is being fitted, and the `outputSize` gives the size of the rectangle
/// into which the source is to be drawn.
///
/// This function then returns two sizes, combined into a single [FittedSizes]
/// object.
///
/// The [FittedSizes.source] size is the subpart of the `inputSize` that is to
/// be shown. If the entire input source is shown, then this will equal the
/// `inputSize`, but if the input source is to be cropped down, this may be
/// smaller.
///
/// The [FittedSizes.destination] size is the subpart of the `outputSize` in
/// which to paint the (possibly cropped) source. If the
/// [FittedSizes.destination] size is smaller than the `outputSize` then the
/// source is being letterboxed (or pillarboxed).
///
/// This method does not express an opinion regarding the alignment of the
/// source and destination sizes within the input and output rectangles.
/// Typically they are centered (this is what [BoxDecoration] does, for
/// instance, and is how [BoxFit] is defined). The [Alignment] class provides a
/// convenience function, [Alignment.inscribe], for resolving the sizes to
/// rects, as shown in the example below.
public func applyBoxFit(_ fit: BoxFit, inputSize: Size, outputSize: Size) -> FittedSizes {
    if inputSize.height <= 0.0 || inputSize.width <= 0.0 || outputSize.height <= 0.0
        || outputSize.width <= 0.0
    {
        return FittedSizes(source: Size.zero, destination: Size.zero)
    }

    var sourceSize: Size
    var destinationSize: Size
    switch fit {
    case .fill:
        sourceSize = inputSize
        destinationSize = outputSize
    case .contain:
        sourceSize = inputSize
        if outputSize.width / outputSize.height > sourceSize.width / sourceSize.height {
            destinationSize = Size(
                sourceSize.width * outputSize.height / sourceSize.height,
                outputSize.height
            )
        } else {
            destinationSize = Size(
                outputSize.width,
                sourceSize.height * outputSize.width / sourceSize.width
            )
        }
    case .cover:
        if outputSize.width / outputSize.height > inputSize.width / inputSize.height {
            sourceSize = Size(
                inputSize.width,
                inputSize.width * outputSize.height / outputSize.width
            )
        } else {
            sourceSize = Size(
                inputSize.height * outputSize.width / outputSize.height,
                inputSize.height
            )
        }
        destinationSize = outputSize
    case .fitWidth:
        if outputSize.width / outputSize.height > inputSize.width / inputSize.height {
            // Like "cover"
            sourceSize = Size(
                inputSize.width,
                inputSize.width * outputSize.height / outputSize.width
            )
            destinationSize = outputSize
        } else {
            // Like "contain"
            sourceSize = inputSize
            destinationSize = Size(
                outputSize.width,
                sourceSize.height * outputSize.width / sourceSize.width
            )
        }
    case .fitHeight:
        if outputSize.width / outputSize.height > inputSize.width / inputSize.height {
            // Like "contain"
            sourceSize = inputSize
            destinationSize = Size(
                sourceSize.width * outputSize.height / sourceSize.height,
                outputSize.height
            )
        } else {
            // Like "cover"
            sourceSize = Size(
                inputSize.height * outputSize.width / outputSize.height,
                inputSize.height
            )
            destinationSize = outputSize
        }
    case .none:
        sourceSize = Size(
            min(inputSize.width, outputSize.width),
            min(inputSize.height, outputSize.height)
        )
        destinationSize = sourceSize
    case .scaleDown:
        sourceSize = inputSize
        destinationSize = inputSize
        let aspectRatio = inputSize.width / inputSize.height
        if destinationSize.height > outputSize.height {
            destinationSize = Size(
                outputSize.height * aspectRatio,
                outputSize.height
            )
        }
        if destinationSize.width > outputSize.width {
            destinationSize = Size(outputSize.width, outputSize.width / aspectRatio)
        }
    }
    return FittedSizes(source: sourceSize, destination: destinationSize)
}
