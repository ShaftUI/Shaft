// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The interface used by [CustomPaint] (in the widgets library) and
/// [RenderCustomPaint] (in the rendering library).
///
/// To implement a custom painter, either subclass or implement this interface
/// to define your custom paint delegate. [CustomPainter] subclasses must
/// implement the [paint] and [shouldRepaint] methods, and may optionally also
/// implement the [hitTest] and [shouldRebuildSemantics] methods, and the
/// [semanticsBuilder] getter.
///
/// The [paint] method is called whenever the custom object needs to be repainted.
///
/// The [shouldRepaint] method is called when a new instance of the class
/// is provided, to check if the new instance actually represents different
/// information.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=vvI_NUXK00s}
///
/// The most efficient way to trigger a repaint is to either:
///
/// * Extend this class and supply a `repaint` argument to the constructor of
///   the [CustomPainter], where that object notifies its listeners when it is
///   time to repaint.
/// * Extend [Listenable] (e.g. via [ChangeNotifier]) and implement
///   [CustomPainter], so that the object itself provides the notifications
///   directly.
///
/// In either case, the [CustomPaint] widget or [RenderCustomPaint]
/// render object will listen to the [Listenable] and repaint whenever the
/// animation ticks, avoiding both the build and layout phases of the pipeline.
///
/// The [hitTest] method is called when the user interacts with the underlying
/// render object, to determine if the user hit the object or missed it.
///
/// The [semanticsBuilder] is called whenever the custom object needs to rebuild
/// its semantics information.
///
/// The [shouldRebuildSemantics] method is called when a new instance of the
/// class is provided, to check if the new instance contains different
/// information that affects the semantics tree.
///
/// {@tool snippet}
///
/// This sample extends the same code shown for [RadialGradient] to create a
/// custom painter that paints a sky.
///
/// ```dart
/// class Sky extends CustomPainter {
///   @override
///   void paint(Canvas canvas, Size size) {
///     final Rect rect = Offset.zero & size;
///     const RadialGradient gradient = RadialGradient(
///       center: Alignment(0.7, -0.6),
///       radius: 0.2,
///       colors: <Color>[Color(0xFFFFFF00), Color(0xFF0099FF)],
///       stops: <double>[0.4, 1.0],
///     );
///     canvas.drawRect(
///       rect,
///       Paint()..shader = gradient.createShader(rect),
///     );
///   }
///
///   @override
///   SemanticsBuilderCallback get semanticsBuilder {
///     return (Size size) {
///       // Annotate a rectangle containing the picture of the sun
///       // with the label "Sun". When text to speech feature is enabled on the
///       // device, a user will be able to locate the sun on this picture by
///       // touch.
///       Rect rect = Offset.zero & size;
///       final double width = size.shortestSide * 0.4;
///       rect = const Alignment(0.8, -0.9).inscribe(Size(width, width), rect);
///       return <CustomPainterSemantics>[
///         CustomPainterSemantics(
///           rect: rect,
///           properties: const SemanticsProperties(
///             label: 'Sun',
///             textDirection: TextDirection.ltr,
///           ),
///         ),
///       ];
///     };
///   }
///
///   // Since this Sky painter has no fields, it always paints
///   // the same thing and semantics information is the same.
///   // Therefore we return false here. If we had fields (set
///   // from the constructor) then we would return true if any
///   // of them differed from the same fields on the oldDelegate.
///   @override
///   bool shouldRepaint(Sky oldDelegate) => false;
///   @override
///   bool shouldRebuildSemantics(Sky oldDelegate) => false;
/// }
/// ```
/// {@end-tool}
///
/// ## Composition and the sharing of canvases
///
/// Widgets (or rather, render objects) are composited together using a minimum
/// number of [Canvas]es, for performance reasons. As a result, a
/// [CustomPainter]'s [Canvas] may be the same as that used by other widgets
/// (including other [CustomPaint] widgets).
///
/// This is mostly unnoticeable, except when using unusual [BlendMode]s. For
/// example, trying to use [BlendMode.dstOut] to "punch a hole" through a
/// previously-drawn image may erase more than was intended, because previous
/// widgets will have been painted onto the same canvas.
///
/// To avoid this issue, consider using [Canvas.saveLayer] and
/// [Canvas.restore] when using such blend modes. Creating new layers is
/// relatively expensive, however, and should be done sparingly to avoid
/// introducing jank.
///
/// See also:
///
///  * [Canvas], the class that a custom painter uses to paint.
///  * [CustomPaint], the widget that uses [CustomPainter], and whose sample
///    code shows how to use the above `Sky` class.
///  * [RadialGradient], whose sample code section shows a different take
///    on the sample code above.
/// A protocol for drawing custom graphics.
public protocol CustomPainter: Listenable {
    /// The listenable that this painter forwards listener calls to.
    var repaint: Listenable? { get }

    /// Called whenever the object needs to paint. The given [Canvas] has its
    /// coordinate space configured such that the origin is at the top left of the
    /// box. The area of the box is the size of the [size] argument.
    ///
    /// Paint operations should remain inside the given area. Graphical
    /// operations outside the bounds may be silently ignored, clipped, or not
    /// clipped. It may sometimes be difficult to guarantee that a certain
    /// operation is inside the bounds (e.g., drawing a rectangle whose size is
    /// determined by user inputs). In that case, consider calling
    /// [Canvas.clipRect] at the beginning of [paint] so everything that follows
    /// will be guaranteed to only draw within the clipped area.
    ///
    /// Implementations should be wary of correctly pairing any calls to
    /// [Canvas.save]/[Canvas.saveLayer] and [Canvas.restore], otherwise all
    /// subsequent painting on this canvas may be affected, with potentially
    /// hilarious but confusing results.
    ///
    /// To paint text on a [Canvas], use a [TextPainter].
    ///
    /// To paint an image on a [Canvas]:
    ///
    /// 1. Obtain an [ImageStream], for example by calling [ImageProvider.resolve]
    ///    on an [AssetImage] or [NetworkImage] object.
    ///
    /// 2. Whenever the [ImageStream]'s underlying [ImageInfo] object changes
    ///    (see [ImageStream.addListener]), create a new instance of your custom
    ///    paint delegate, giving it the new [ImageInfo] object.
    ///
    /// 3. In your delegate's [paint] method, call the [Canvas.drawImage],
    ///    [Canvas.drawImageRect], or [Canvas.drawImageNine] methods to paint the
    ///    [ImageInfo.image] object, applying the [ImageInfo.scale] value to
    ///    obtain the correct rendering size.
    func paint(canvas: Canvas, size: Size)

    /// Called whenever a new instance of the custom painter delegate class is
    /// provided to the [RenderCustomPaint] object, or any time that a new
    /// [CustomPaint] object is created with a new instance of the custom painter
    /// delegate class (which amounts to the same thing, because the latter is
    /// implemented in terms of the former).
    ///
    /// If the new instance represents different information than the old
    /// instance, then the method should return true, otherwise it should return
    /// false.
    ///
    /// If the method returns false, then the [paint] call might be optimized
    /// away.
    ///
    /// It's possible that the [paint] method will get called even if
    /// [shouldRepaint] returns false (e.g. if an ancestor or descendant needed to
    /// be repainted). It's also possible that the [paint] method will get called
    /// without [shouldRepaint] being called at all (e.g. if the box changes
    /// size).
    ///
    /// If a custom delegate has a particularly expensive paint function such that
    /// repaints should be avoided as much as possible, a [RepaintBoundary] or
    /// [RenderRepaintBoundary] (or other render object with
    /// [RenderObject.isRepaintBoundary] set to true) might be helpful.
    ///
    /// The `oldDelegate` argument will never be null.
    func shouldRepaint(_ oldDelegate: CustomPainter) -> Bool

    /// Called whenever a hit test is being performed on an object that is using
    /// this custom paint delegate.
    ///
    /// The given point is relative to the same coordinate space as the last
    /// [paint] call.
    ///
    /// The default behavior is to consider all points to be hits for
    /// background painters, and no points to be hits for foreground painters.
    ///
    /// Return true if the given position corresponds to a point on the drawn
    /// image that should be considered a "hit", false if it corresponds to a
    /// point that should be considered outside the painted image, and null to use
    /// the default behavior.
    func hitTest(_ position: Offset) -> Bool?
}

extension CustomPainter {
    /// Register a closure to be notified when it is time to repaint.
    ///
    /// The [CustomPainter] implementation merely forwards to the same method on
    /// the [Listenable] provided to the constructor in the `repaint` argument, if
    /// it was not null.
    public func addListener(_ listener: AnyObject, callback: @escaping VoidCallback) {
        repaint?.addListener(listener, callback: callback)
    }

    /// Remove a previously registered closure from the list of closures that the
    /// object notifies when it is time to repaint.
    ///
    /// The [CustomPainter] implementation merely forwards to the same method on
    /// the [Listenable] provided to the constructor in the `repaint` argument, if
    /// it was not null.
    public func removeListener(_ listener: AnyObject) {
        repaint?.removeListener(listener)
    }

    /// Called whenever a hit test is being performed on an object that is using
    /// this custom paint delegate.
    ///
    /// The default behavior is to consider all points to be hits for
    /// background painters, and no points to be hits for foreground painters.
    ///
    /// Return true if the given position corresponds to a point on the drawn
    /// image that should be considered a "hit", false if it corresponds to a
    /// point that should be considered outside the painted image, and null to use
    /// the default behavior.
    public func hitTest(_ position: Offset) -> Bool? {
        return nil
    }
}

/// A base class for custom painters that provides a default implementation.
///
/// This class implements the [CustomPainter] protocol and provides a concrete
/// base that can be subclassed when you need to store the repaint listenable.
open class CustomPainterBase: CustomPainter {
    public let repaint: Listenable?

    /// Creates a custom painter.
    ///
    /// The painter will repaint whenever `repaint` notifies its listeners.
    public init(repaint: Listenable? = nil) {
        self.repaint = repaint
    }

    /// Called whenever the object needs to paint. Subclasses must override this method.
    open func paint(canvas: Canvas, size: Size) {
        fatalError("Subclasses must implement paint(canvas:size:)")
    }

    /// Called whenever a new instance of the custom painter delegate class is provided.
    /// Subclasses must override this method.
    open func shouldRepaint(_ oldDelegate: CustomPainter) -> Bool {
        fatalError("Subclasses must implement shouldRepaint(_:)")
    }
}

extension CustomPainterBase: CustomStringConvertible {
    public var description: String {
        let repaintDescription: String
        if let repaint = repaint {
            repaintDescription = String(describing: repaint)
        } else {
            repaintDescription = ""
        }
        return "\(describeIdentity(self))(\(repaintDescription))"
    }
}

/// Provides a canvas on which to draw during the paint phase.
///
/// When asked to paint, [RenderCustomPaint] first asks its [painter] to paint
/// on the current canvas, then it paints its child, and then, after painting
/// its child, it asks its [foregroundPainter] to paint. The coordinate system of
/// the canvas matches the coordinate system of the [CustomPaint] object. The
/// painters are expected to paint within a rectangle starting at the origin and
/// encompassing a region of the given size. (If the painters paint outside
/// those bounds, there might be insufficient memory allocated to rasterize the
/// painting commands and the resulting behavior is undefined.)
///
/// Painters are implemented by subclassing or implementing [CustomPainter].
///
/// Because custom paint calls its painters during paint, you cannot mark the
/// tree as needing a new layout during the callback (the layout for this frame
/// has already happened).
///
/// Custom painters normally size themselves to their child. If they do not have
/// a child, they attempt to size themselves to the [preferredSize], which
/// defaults to [Size.zero].
///
/// See also:
///
///  * [CustomPainter], the class that custom painter delegates should extend.
///  * [Canvas], the API provided to custom painter delegates.
public class RenderCustomPaint: RenderProxyBox {
    /// Creates a render object that delegates its painting.
    public init(
        painter: CustomPainter? = nil,
        foregroundPainter: CustomPainter? = nil,
        preferredSize: Size = .zero,
        isComplex: Bool = false,
        willChange: Bool = false,
        child: RenderBox? = nil
    ) {
        self.painter = painter
        self.foregroundPainter = foregroundPainter
        self.preferredSize = preferredSize
        self.isComplex = isComplex
        self.willChange = willChange
        super.init(child: child)
    }

    /// The background custom paint delegate.
    ///
    /// This painter, if non-null, is called to paint behind the children.
    public var painter: CustomPainter? {
        didSet {
            if painter === oldValue {
                return
            }
            _didUpdatePainter(painter, oldValue)
        }
    }

    /// The foreground custom paint delegate.
    ///
    /// This painter, if non-null, is called to paint in front of the children.
    public var foregroundPainter: CustomPainter? {
        didSet {
            if foregroundPainter === oldValue {
                return
            }
            _didUpdatePainter(foregroundPainter, oldValue)
        }
    }

    private func _didUpdatePainter(_ newPainter: CustomPainter?, _ oldPainter: CustomPainter?) {
        // Check if we need to repaint.
        if newPainter == nil {
            assert(oldPainter != nil)  // We should be called only for changes.
            markNeedsPaint()
        } else if oldPainter == nil || type(of: newPainter!) != type(of: oldPainter!)
            || newPainter!.shouldRepaint(oldPainter!)
        {
            markNeedsPaint()
        }
        if attached {
            oldPainter?.removeListener(self)
            newPainter?.addListener(self, callback: markNeedsPaint)
        }
    }

    /// The size that this [RenderCustomPaint] should aim for, given the layout
    /// constraints, if there is no child.
    ///
    /// Defaults to [Size.zero].
    ///
    /// If there's a child, this is ignored, and the size of the child is used
    /// instead.
    public var preferredSize: Size {
        didSet {
            if preferredSize == oldValue {
                return
            }
            markNeedsLayout()
        }
    }

    /// Whether to hint that this layer's painting should be cached.
    ///
    /// The compositor contains a raster cache that holds bitmaps of layers in
    /// order to avoid the cost of repeatedly rendering those layers on each
    /// frame. If this flag is not set, then the compositor will apply its own
    /// heuristics to decide whether the layer containing this render object is
    /// complex enough to benefit from caching.
    public var isComplex: Bool

    /// Whether the raster cache should be told that this painting is likely
    /// to change in the next frame.
    ///
    /// This hint tells the compositor not to cache the layer containing this
    /// render object because the cache will not be used in the future. If this
    /// hint is not set, the compositor will apply its own heuristics to decide
    /// whether this layer is likely to be reused in the future.
    public var willChange: Bool

    // public override func computeMinIntrinsicWidth(_ height: Double) -> Double {
    //     if child == nil {
    //         return preferredSize.width.isFinite ? preferredSize.width : 0
    //     }
    //     return super.computeMinIntrinsicWidth(height)
    // }

    // public override func computeMaxIntrinsicWidth(_ height: Double) -> Double {
    //     if child == nil {
    //         return preferredSize.width.isFinite ? preferredSize.width : 0
    //     }
    //     return super.computeMaxIntrinsicWidth(height)
    // }

    // public override func computeMinIntrinsicHeight(_ width: Double) -> Double {
    //     if child == nil {
    //         return preferredSize.height.isFinite ? preferredSize.height : 0
    //     }
    //     return super.computeMinIntrinsicHeight(width)
    // }

    // public override func computeMaxIntrinsicHeight(_ width: Double) -> Double {
    //     if child == nil {
    //         return preferredSize.height.isFinite ? preferredSize.height : 0
    //     }
    //     return super.computeMaxIntrinsicHeight(width)
    // }

    public override func attach(_ owner: RenderOwner) {
        super.attach(owner)
        painter?.addListener(self, callback: markNeedsPaint)
        foregroundPainter?.addListener(self, callback: markNeedsPaint)
    }

    public override func detach() {
        painter?.removeListener(self)
        foregroundPainter?.removeListener(self)
        super.detach()
    }

    public override func hitTestChildren(_ result: HitTestResult, position: Offset) -> Bool {
        if let foregroundPainter = foregroundPainter, foregroundPainter.hitTest(position) ?? false {
            return true
        }
        return super.hitTestChildren(result, position: position)

    }

    public override func hitTestSelf(_ position: Offset) -> Bool {
        return painter != nil && (painter!.hitTest(position) ?? true)
    }

    public override func performLayout() {
        super.performLayout()
    }

    public override func computeSizeForNoChild(_ constraints: BoxConstraints) -> Size {
        return constraints.constrain(preferredSize)
    }

    private func _paintWithPainter(_ canvas: Canvas, _ offset: Offset, _ painter: CustomPainter) {
        let debugPreviousCanvasSaveCount: Int
        canvas.save()
        debugPreviousCanvasSaveCount = canvas.getSaveCount()
        if offset != .zero {
            canvas.translate(offset.dx, offset.dy)
        }
        painter.paint(canvas: canvas, size: size)

        // Debug canvas save/restore validation
        let debugNewCanvasSaveCount = canvas.getSaveCount()
        if debugNewCanvasSaveCount > debugPreviousCanvasSaveCount {
            fatalError(
                """
                The \(painter) custom painter called canvas.save() or canvas.saveLayer() at least \
                \(debugNewCanvasSaveCount - debugPreviousCanvasSaveCount) more \
                time\(debugNewCanvasSaveCount - debugPreviousCanvasSaveCount == 1 ? "" : "s") \
                than it called canvas.restore().

                This leaves the canvas in an inconsistent state and will probably result in a broken display.

                You must pair each call to save()/saveLayer() with a later matching call to restore().
                """
            )
        }
        if debugNewCanvasSaveCount < debugPreviousCanvasSaveCount {
            fatalError(
                """
                The \(painter) custom painter called canvas.restore() \
                \(debugPreviousCanvasSaveCount - debugNewCanvasSaveCount) more \
                time\(debugPreviousCanvasSaveCount - debugNewCanvasSaveCount == 1 ? "" : "s") \
                than it called canvas.save() or canvas.saveLayer().

                This leaves the canvas in an inconsistent state and will result in a broken display.

                You should only call restore() if you first called save() or saveLayer().
                """
            )
        }
        assert(debugNewCanvasSaveCount == debugPreviousCanvasSaveCount)
        canvas.restore()
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        if let painter = painter {
            _paintWithPainter(context.canvas, offset, painter)
            _setRasterCacheHints(context)
        }
        super.paint(context: context, offset: offset)
        if let foregroundPainter = foregroundPainter {
            _paintWithPainter(context.canvas, offset, foregroundPainter)
            _setRasterCacheHints(context)
        }
    }

    private func _setRasterCacheHints(_ context: PaintingContext) {
        // if isComplex {
        //     context.setIsComplexHint()
        // }
        // if willChange {
        //     context.setWillChangeHint()
        // }
    }
}
