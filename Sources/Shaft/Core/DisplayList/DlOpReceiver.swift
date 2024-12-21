// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// Defines how a new clip region should be merged with the existing clip
/// region.
public enum ClipOp {
    /// Subtract the new region from the existing region.
    case difference

    /// Intersect the new region from the existing region.
    case intersect
}

public protocol DlOpReceiver {
    func drawDisplayList(_ displayList: DisplayList)

    /// Saves a copy of the current transform and clip on the save stack.
    ///
    /// Call [restore] to pop the save stack.
    func save()

    /// Saves a copy of the current transform and clip on the save stack, and then
    /// creates a new group which subsequent calls will become a part of. When the
    /// save stack is later popped, the group will be flattened into a layer and
    /// have the given `paint`'s [Paint.colorFilter] and [Paint.blendMode]
    /// applied.
    ///
    /// This lets you create composite effects, for example making a group of
    /// drawing commands semi-transparent. Without using [saveLayer], each part of
    /// the group would be painted individually, so where they overlap would be
    /// darker than where they do not. By using [saveLayer] to group them
    /// together, they can be drawn with an opaque color at first, and then the
    /// entire group can be made transparent using the [saveLayer]'s paint.
    ///
    /// Call [restore] to pop the save stack and apply the paint to the group.
    ///
    /// ## Using saveLayer with clips
    ///
    /// When a rectangular clip operation (from [clipRect]) is not axis-aligned
    /// with the raster buffer, or when the clip operation is not rectilinear
    /// (e.g. because it is a rounded rectangle clip created by [clipRRect] or an
    /// arbitrarily complicated path clip created by [clipPath]), the edge of the
    /// clip needs to be anti-aliased.
    ///
    /// If two draw calls overlap at the edge of such a clipped region, without
    /// using [saveLayer], the first drawing will be anti-aliased with the
    /// background first, and then the second will be anti-aliased with the result
    /// of blending the first drawing and the background. On the other hand, if
    /// [saveLayer] is used immediately after establishing the clip, the second
    /// drawing will cover the first in the layer, and thus the second alone will
    /// be anti-aliased with the background when the layer is clipped and
    /// composited (when [restore] is called).
    ///
    /// ## Performance considerations
    ///
    /// Generally speaking, [saveLayer] is relatively expensive.
    ///
    /// There are a several different hardware architectures for GPUs (graphics
    /// processing units, the hardware that handles graphics), but most of them
    /// involve batching commands and reordering them for performance. When layers
    /// are used, they cause the rendering pipeline to have to switch render
    /// target (from one layer to another). Render target switches can flush the
    /// GPU's command buffer, which typically means that optimizations that one
    /// could get with larger batching are lost. Render target switches also
    /// generate a lot of memory churn because the GPU needs to copy out the
    /// current frame buffer contents from the part of memory that's optimized for
    /// writing, and then needs to copy it back in once the previous render target
    /// (layer) is restored.
    func saveLayer(_ bounds: Rect, paint: Paint?)

    /// Pops the current save stack, if there is anything to pop.
    /// Otherwise, does nothing.
    ///
    /// Use [save] and [saveLayer] to push state onto the stack.
    ///
    /// If the state was pushed with [saveLayer], then this call will also
    /// cause the new layer to be composited into the previous layer.
    func restore()

    /// Restores the save stack to a previous level as might be obtained from [getSaveCount].
    /// If [count] is less than 1, the stack is restored to its initial state.
    /// If [count] is greater than the current [getSaveCount] then nothing happens.
    ///
    /// Use [save] and [saveLayer] to push state onto the stack.
    ///
    /// If any of the state stack levels restored by this call were pushed with
    /// [saveLayer], then this call will also cause those layers to be composited
    /// into their previous layers.
    // void restoreToCount(int count);

    /// Returns the number of items on the save stack, including the
    /// initial state. This means it returns 1 for a clean canvas, and
    /// that each call to [save] and [saveLayer] increments it, and that
    /// each matching call to [restore] decrements it.
    ///
    /// This number cannot go below 1.
    // int getSaveCount();

    /// Add a translation to the current transform, shifting the coordinate space
    /// horizontally by the first argument and vertically by the second argument.
    func translate(_ dx: Float, _ dy: Float)

    /// Add an axis-aligned scale to the current transform, scaling by the first
    /// argument in the horizontal direction and the second in the vertical
    /// direction.
    ///
    /// If [sy] is unspecified, [sx] will be used for the scale in both
    /// directions.
    func scale(_ sx: Float, _ sy: Float)

    /// Add a rotation to the current transform. The argument is in radians clockwise.
    // void rotate(double radians);

    /// Add an axis-aligned skew to the current transform, with the first argument
    /// being the horizontal skew in rise over run units clockwise around the
    /// origin, and the second argument being the vertical skew in rise over run
    /// units clockwise around the origin.
    // void skew(double sx, double sy);

    /// Multiply the current transform by the specified 4⨉4 transformation matrix
    /// specified as a list of values in column-major order.
    func transform(_ transform: Matrix4x4f)

    /// Returns the current transform including the combined result of all transform
    /// methods executed since the creation of this [Canvas] object, and respecting the
    /// save/restore history.
    ///
    /// Methods that can change the current transform include [translate], [scale],
    /// [rotate], [skew], and [transform]. The [restore] method can also modify
    /// the current transform by restoring it to the same value it had before its
    /// associated [save] or [saveLayer] call.
    // Float64List getTransform();

    /// Reduces the clip region to the intersection of the current clip and the
    /// given rectangle.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/clip_rect.png)
    ///
    /// If [doAntiAlias] is true, then the clip will be anti-aliased.
    ///
    /// If multiple draw commands intersect with the clip boundary, this can result
    /// in incorrect blending at the clip boundary. See [saveLayer] for a
    /// discussion of how to address that.
    ///
    /// Use [ClipOp.difference] to subtract the provided rectangle from the
    /// current clip.
    // void clipRect(Rect rect, { ClipOp clipOp = ClipOp.intersect, bool doAntiAlias = true });
    func clipRect(_ rect: Rect, _ clipOp: ClipOp, _ doAntiAlias: Bool)

    /// Reduces the clip region to the intersection of the current clip and the
    /// given rounded rectangle.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/clip_rrect.png)
    ///
    /// If [doAntiAlias] is true, then the clip will be anti-aliased.
    ///
    /// If multiple draw commands intersect with the clip boundary, this can result
    /// in incorrect blending at the clip boundary. See [saveLayer] for a
    /// discussion of how to address that and some examples of using [clipRRect].
    // void clipRRect(RRect rrect, {bool doAntiAlias = true});

    /// Reduces the clip region to the intersection of the current clip and the
    /// given [Path].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/clip_path.png)
    ///
    /// If [doAntiAlias] is true, then the clip will be anti-aliased.
    ///
    /// If multiple draw commands intersect with the clip boundary, this can result
    /// in incorrect blending at the clip boundary. See [saveLayer] for a
    /// discussion of how to address that.
    // void clipPath(Path path, {bool doAntiAlias = true});

    /// Returns the conservative bounds of the combined result of all clip methods
    /// executed within the current save stack of this [Canvas] object, as measured
    /// in the local coordinate space under which rendering operations are currently
    /// performed.
    ///
    /// The combined clip results are rounded out to an integer pixel boundary before
    /// they are transformed back into the local coordinate space which accounts for
    /// the pixel roundoff in rendering operations, particularly when antialiasing.
    /// Because the [Picture] may eventually be rendered into a scene within the
    /// context of transforming widgets or layers, the result may thus be overly
    /// conservative due to premature rounding. Using the [getDestinationClipBounds]
    /// method combined with the external transforms and rounding in the true device
    /// coordinate system will produce more accurate results, but this value may
    /// provide a more convenient approximation to compare rendering operations to
    /// the established clip.
    // Rect getLocalClipBounds();

    /// Returns the conservative bounds of the combined result of all clip methods
    /// executed within the current save stack of this [Canvas] object, as measured
    /// in the destination coordinate space in which the [Picture] will be rendered.
    ///
    /// Unlike [getLocalClipBounds], the bounds are not rounded out to an integer
    /// pixel boundary as the Destination coordinate space may not represent pixels
    /// if the [Picture] being constructed will be further transformed when it is
    /// rendered or added to a scene. In order to determine the true pixels being
    /// affected, those external transforms should be applied first before rounding
    /// out the result to integer pixel boundaries. Most typically, [Picture] objects
    /// are rendered in a scene with a scale transform representing the Device Pixel
    /// Ratio.
    // Rect getDestinationClipBounds();

    /// Paints the given [Color] onto the canvas, applying the given
    /// [BlendMode], with the given color being the source and the background
    /// being the destination.
    // void drawColor(Color color, BlendMode blendMode);

    /// Draws a line between the given points using the given paint. The line is
    /// stroked, the value of the [Paint.style] is ignored for this call.
    ///
    /// The `p1` and `p2` arguments are interpreted as offsets from the origin.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_line.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_line_dark.png#gh-dark-mode-only)
    func drawLine(_ p0: Offset, _ p1: Offset, _ paint: Paint)

    /// Fills the canvas with the given [Paint].
    ///
    /// To fill the canvas with a solid color and blend mode, consider
    /// [drawColor] instead.
    // void drawPaint(Paint paint);

    /// Draws a rectangle with the given [Paint]. Whether the rectangle is filled
    /// or stroked (or both) is controlled by [Paint.style].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_rect.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_rect_dark.png#gh-dark-mode-only)
    func drawRect(_ rect: Rect, _ paint: Paint)

    /// Draws a rounded rectangle with the given [Paint]. Whether the rectangle is
    /// filled or stroked (or both) is controlled by [Paint.style].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_rrect.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_rrect_dark.png#gh-dark-mode-only)
    func drawRRect(_ rrect: RRect, _ paint: Paint)

    /// Draws a shape consisting of the difference between two rounded rectangles
    /// with the given [Paint]. Whether this shape is filled or stroked (or both)
    /// is controlled by [Paint.style].
    ///
    /// This shape is almost but not quite entirely unlike an annulus.
    func drawDRRect(_ outer: RRect, _ inner: RRect, _ paint: Paint)

    /// Draws an axis-aligned oval that fills the given axis-aligned rectangle
    /// with the given [Paint]. Whether the oval is filled or stroked (or both) is
    /// controlled by [Paint.style].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_oval.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_oval_dark.png#gh-dark-mode-only)
    // void drawOval(Rect rect, Paint paint);

    /// Draws a circle centered at the point given by the first argument and
    /// that has the radius given by the second argument, with the [Paint] given in
    /// the third argument. Whether the circle is filled or stroked (or both) is
    /// controlled by [Paint.style].
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_circle.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_circle_dark.png#gh-dark-mode-only)
    func drawCircle(_ center: Offset, _ radius: Float, _ paint: Paint)

    /// Draw an arc scaled to fit inside the given rectangle.
    ///
    /// It starts from `startAngle` radians around the oval up to
    /// `startAngle` + `sweepAngle` radians around the oval, with zero radians
    /// being the point on the right hand side of the oval that crosses the
    /// horizontal line that intersects the center of the rectangle and with positive
    /// angles going clockwise around the oval. If `useCenter` is true, the arc is
    /// closed back to the center, forming a circle sector. Otherwise, the arc is
    /// not closed, forming a circle segment.
    ///
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_draw_arc.png#gh-light-mode-only)
    /// ![](https://flutter.github.io/assets-for-api-docs/assets/dart-ui/canvas_draw_arc_dark.png#gh-dark-mode-only)
    ///
    /// This method is optimized for drawing arcs and should be faster than [Path.arcTo].
    // void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint);

    /// Draws the given [Path] with the given [Paint].
    ///
    /// Whether this shape is filled or stroked (or both) is controlled by
    /// [Paint.style]. If the path is filled, then sub-paths within it are
    /// implicitly closed (see [Path.close]).
    func drawPath(_ path: Path, _ paint: Paint)

    /// Draws the given [Image] into the canvas with its top-left corner at the
    /// given [Offset]. The image is composited into the canvas using the given [Paint].
    func drawImage(_ image: NativeImage, _ offset: Offset, _ paint: Paint)

    /// Draws the subset of the given image described by the `src` argument into
    /// the canvas in the axis-aligned rectangle given by the `dst` argument.
    ///
    /// This might sample from outside the `src` rect by up to half the width of
    /// an applied filter.
    ///
    /// Multiple calls to this method with different arguments (from the same
    /// image) can be batched into a single call to [drawAtlas] to improve
    /// performance.
    func drawImageRect(_ image: NativeImage, _ src: Rect, _ dst: Rect, _ paint: Paint)

    /// Draws the given [Image] into the canvas using the given [Paint].
    ///
    /// The image is drawn in nine portions described by splitting the image by
    /// drawing two horizontal lines and two vertical lines, where the `center`
    /// argument describes the rectangle formed by the four points where these
    /// four lines intersect each other. (This forms a 3-by-3 grid of regions,
    /// the center region being described by the `center` argument.)
    ///
    /// The four regions in the corners are drawn, without scaling, in the four
    /// corners of the destination rectangle described by `dst`. The remaining
    /// five regions are drawn by stretching them to fit such that they exactly
    /// cover the destination rectangle while maintaining their relative
    /// positions.
    func drawImageNine(_ image: NativeImage, _ center: Rect, _ dst: Rect, _ paint: Paint)

    /// Draw the given picture onto the canvas. To create a picture, see
    /// [PictureRecorder].
    // void drawPicture(Picture picture);

    /// Draws the text in the given [Paragraph] into this canvas at the given
    /// [Offset].
    ///
    /// The [Paragraph] object must have had [Paragraph.layout] called on it
    /// first.
    ///
    /// To align the text, set the `textAlign` on the [ParagraphStyle] object
    /// passed to the [ParagraphBuilder.new] constructor. For more details see
    /// [TextAlign] and the discussion at [ParagraphStyle.new].
    ///
    /// If the text is left aligned or justified, the left margin will be at the
    /// position specified by the `offset` argument's [Offset.dx] coordinate.
    ///
    /// If the text is right aligned or justified, the right margin will be at the
    /// position described by adding the [ParagraphConstraints.width] given to
    /// [Paragraph.layout], to the `offset` argument's [Offset.dx] coordinate.
    ///
    /// If the text is centered, the centering axis will be at the position
    /// described by adding half of the [ParagraphConstraints.width] given to
    /// [Paragraph.layout], to the `offset` argument's [Offset.dx] coordinate.
    func drawParagraph(_ paragraph: Paragraph, _ offset: Offset)

    /// Draws a sequence of points according to the given [PointMode].
    ///
    /// The `points` argument is interpreted as offsets from the origin.
    ///
    /// The `paint` is used for each point ([PointMode.points]) or line
    /// ([PointMode.lines] or [PointMode.polygon]), ignoring [Paint.style].
    ///
    /// See also:
    ///
    ///  * [drawRawPoints], which takes `points` as a [Float32List] rather than a
    ///    [List<Offset>].
    // void drawPoints(PointMode pointMode, List<Offset> points, Paint paint);

    /// Draws a sequence of points according to the given [PointMode].
    ///
    /// The `points` argument is interpreted as a list of pairs of floating point
    /// numbers, where each pair represents an x and y offset from the origin.
    ///
    /// The `paint` is used for each point ([PointMode.points]) or line
    /// ([PointMode.lines] or [PointMode.polygon]), ignoring [Paint.style].
    ///
    /// See also:
    ///
    ///  * [drawPoints], which takes `points` as a [List<Offset>] rather than a
    ///    [List<Float32List>].
    // void drawRawPoints(PointMode pointMode, Float32List points, Paint paint);

    /// Draws a set of [Vertices] onto the canvas as one or more triangles.
    ///
    /// The [Paint.color] property specifies the default color to use for the
    /// triangles.
    ///
    /// The [Paint.shader] property, if set, overrides the color entirely,
    /// replacing it with the colors from the specified [ImageShader], [Gradient],
    /// or other shader.
    ///
    /// The `blendMode` parameter is used to control how the colors in the
    /// `vertices` are combined with the colors in the `paint`. If there are no
    /// colors specified in `vertices` then the `blendMode` has no effect. If
    /// there are colors in the `vertices`, then the color taken from the
    /// [Paint.shader] or [Paint.color] in the `paint` is blended with the colors
    /// specified in the `vertices` using the `blendMode` parameter. For the
    /// purposes of this blending, the colors from the `paint` parameter are
    /// considered the source, and the colors from the `vertices` are considered
    /// the destination. [BlendMode.dst] ignores the `paint` and uses only the
    /// colors of the `vertices`; [BlendMode.src] ignores the colors of the
    /// `vertices` and uses only the colors in the `paint`.
    ///
    /// All parameters must not be null.
    ///
    /// See also:
    ///   * [Vertices.new], which creates a set of vertices to draw on the canvas.
    ///   * [Vertices.raw], which creates the vertices using typed data lists
    ///     rather than unencoded lists.
    ///   * [paint], Image shaders can be used to draw images on a triangular mesh.
    // void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint);

    /// Draws many parts of an image - the [atlas] - onto the canvas.
    ///
    /// This method allows for optimization when you want to draw many parts of an
    /// image onto the canvas, such as when using sprites or zooming. It is more efficient
    /// than using multiple calls to [drawImageRect] and provides more functionality
    /// to individually transform each image part by a separate rotation or scale and
    /// blend or modulate those parts with a solid color.
    ///
    /// The method takes a list of [Rect] objects that each define a piece of the
    /// [atlas] image to be drawn independently. Each [Rect] is associated with an
    /// [RSTransform] entry in the [transforms] list which defines the location,
    /// rotation, and (uniform) scale with which to draw that portion of the image.
    /// Each [Rect] can also be associated with an optional [Color] which will be
    /// composed with the associated image part using the [blendMode] before blending
    /// the result onto the canvas. The full operation can be broken down as:
    ///
    /// - Blend each rectangular portion of the image specified by an entry in the
    /// [rects] argument with its associated entry in the [colors] list using the
    /// [blendMode] argument (if a color is specified). In this part of the operation,
    /// the image part will be considered the source of the operation and the associated
    /// color will be considered the destination.
    /// - Blend the result from the first step onto the canvas using the translation,
    /// rotation, and scale properties expressed in the associated entry in the
    /// [transforms] list using the properties of the [Paint] object.
    ///
    /// If the first stage of the operation which blends each part of the image with
    /// a color is needed, then both the [colors] and [blendMode] arguments must
    /// not be null and there must be an entry in the [colors] list for each
    /// image part. If that stage is not needed, then the [colors] argument can
    /// be either null or an empty list and the [blendMode] argument may also be null.
    ///
    /// The optional [cullRect] argument can provide an estimate of the bounds of the
    /// coordinates rendered by all components of the atlas to be compared against
    /// the clip to quickly reject the operation if it does not intersect.
    // void drawAtlas(Image atlas,
    // List<RSTransform> transforms,
    // List<Rect> rects,
    // List<Color>? colors,
    // BlendMode? blendMode,
    // Rect? cullRect,
    // Paint paint);

    /// Draws many parts of an image - the [atlas] - onto the canvas.
    ///
    /// This method allows for optimization when you want to draw many parts of an
    /// image onto the canvas, such as when using sprites or zooming. It is more efficient
    /// than using multiple calls to [drawImageRect] and provides more functionality
    /// to individually transform each image part by a separate rotation or scale and
    /// blend or modulate those parts with a solid color. It is also more efficient
    /// than [drawAtlas] as the data in the arguments is already packed in a format
    /// that can be directly used by the rendering code.
    ///
    /// A full description of how this method uses its arguments to draw onto the
    /// canvas can be found in the description of the [drawAtlas] method.
    ///
    /// The [rstTransforms] argument is interpreted as a list of four-tuples, with
    /// each tuple being ([RSTransform.scos], [RSTransform.ssin],
    /// [RSTransform.tx], [RSTransform.ty]).
    ///
    /// The [rects] argument is interpreted as a list of four-tuples, with each
    /// tuple being ([Rect.left], [Rect.top], [Rect.right], [Rect.bottom]).
    ///
    /// The [colors] argument, which can be null, is interpreted as a list of
    /// 32-bit colors, with the same packing as [Color.value]. If the [colors]
    /// argument is not null then the [blendMode] argument must also not be null.
    // void drawRawAtlas(Image atlas,
    // Float32List rstTransforms,
    // Float32List rects,
    // Int32List? colors,
    // BlendMode? blendMode,
    // Rect? cullRect,
    // Paint paint);

    /// Draws a shadow for a [Path] representing the given material elevation.
    ///
    /// The `transparentOccluder` argument should be true if the occluding object
    /// is not opaque.
    ///
    /// The arguments must not be null.
    // void drawShadow(Path path, Color color, double elevation, bool transparentOccluder);

    /// Draws the given TextBlob at (x, y) using the current clip, current
    /// matrix, and the provided paint. The fonts used to draw TextBlob are part
    /// of the blob.
    func drawTextBlob(_ blob: TextBlob, _ offset: Offset, _ paint: Paint)

    /// Clears the entire canvas with the given [Color].
    func clear(color: Color)
}

extension DlOpReceiver {
    func clipRect(_ rect: Rect, clipOp: ClipOp = .intersect, doAntiAlias: Bool = true) {
        clipRect(rect, clipOp, doAntiAlias)
    }

    func scale(_ ratio: Float) {
        scale(ratio, ratio)
    }
}
