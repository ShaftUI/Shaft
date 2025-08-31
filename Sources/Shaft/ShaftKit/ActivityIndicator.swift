// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A circular progress indicator which spins to indicate that the application
/// is busy.
public final class ActivityIndicator: StatelessWidget {
    public init(
        color: Color? = nil,
        animating: Bool = true,
        radius: Float = 10.0,
    ) {
        self.color = color
        self.animating = animating
        self.radius = radius
    }

    public let color: Color?
    public let animating: Bool
    public let radius: Float

    public func build(context: BuildContext) -> Widget {
        let style: any Style = Inherited.valueOf(context) ?? .default
        return style.build(
            context: .init(
                color: color,
                animating: animating,
                radius: radius,
            )
        )
    }

    public struct StyleContext {
        public let color: Color?
        public let animating: Bool
        public let radius: Float
    }

    public protocol Style {
        func build(context: StyleContext) -> Widget
    }
}

extension ActivityIndicator.Style where Self == DefaultActivityIndicatorStyle {
    public static var `default`: DefaultActivityIndicatorStyle {
        DefaultActivityIndicatorStyle()
    }
}

public struct DefaultActivityIndicatorStyle: ActivityIndicator.Style {
    public func build(context: ActivityIndicator.StyleContext) -> Widget {
        CupertinoActivityIndicator(
            color: context.color,
            animating: context.animating,
            radius: context.radius,
        )
    }
}

/// An iOS-style activity indicator that spins clockwise.
public final class CupertinoActivityIndicator: StatefulWidget {
    public static let defaultIndicatorRadius: Float = 10.0

    public let color: Color?
    public let animating: Bool
    public let radius: Float
    public let progress: Float

    /// Creates an iOS-style activity indicator that spins clockwise.
    public init(
        color: Color? = nil,
        animating: Bool = true,
        radius: Float = CupertinoActivityIndicator.defaultIndicatorRadius
    ) {
        assert(radius > 0.0, "Radius must be positive")
        self.color = color
        self.animating = animating
        self.radius = radius
        self.progress = 1.0
    }

    /// Creates a non-animated iOS-style activity indicator that displays
    /// a partial count of ticks based on the value of progress.
    ///
    /// When provided, the value of progress must be between 0.0 (zero ticks
    /// will be shown) and 1.0 (all ticks will be shown) inclusive.
    public static func partiallyRevealed(
        color: Color? = nil,
        radius: Float = CupertinoActivityIndicator.defaultIndicatorRadius,
        progress: Float = 1.0
    ) -> CupertinoActivityIndicator {
        assert(radius > 0.0, "Radius must be positive")
        assert(progress >= 0.0, "Progress must be non-negative")
        assert(progress <= 1.0, "Progress must not exceed 1.0")
        return Self(color: color, animating: false, radius: radius, progress: progress)
    }

    private init(
        color: Color?,
        animating: Bool,
        radius: Float,
        progress: Float
    ) {
        self.color = color
        self.animating = animating
        self.radius = radius
        self.progress = 1.0
    }

    public func createState() -> some State<CupertinoActivityIndicator> {
        return CupertinoActivityIndicatorState()
    }
}

private final class CupertinoActivityIndicatorState: State<CupertinoActivityIndicator> {
    // Extracted from iOS 13.2 Beta.
    private static let activeTickColor = Color.rgb(60, 60, 68)  // Light mode color
    private static let activeTickColorDark = Color.rgb(235, 235, 245)  // Dark mode color

    required init() {
        super.init()
        registerMixin(tickerProvider)
    }

    private var controller: AnimationController!

    private var tickerProvider = TickerProviderStateMixin()

    override func initState() {
        super.initState()
        controller = AnimationController(duration: .seconds(1), vsync: tickerProvider)

        if widget.animating {
            let _ = controller.repeat()
        }
    }

    override func didUpdateWidget(_ oldWidget: CupertinoActivityIndicator) {
        super.didUpdateWidget(oldWidget)

        if widget.animating != oldWidget.animating {
            if widget.animating {
                let _ = controller.repeat()
            } else {
                controller.stop()
            }
        }
    }

    override func dispose() {
        controller.stop()
        super.dispose()
    }

    override func build(context: BuildContext) -> Widget {
        let effectiveColor = widget.color ?? Self.activeTickColor

        return SizedBox(
            width: widget.radius * 2,
            height: widget.radius * 2
        ) {
            CustomPaint(
                painter: CupertinoActivityIndicatorPainter(
                    position: controller,
                    activeColor: effectiveColor,
                    radius: widget.radius,
                    progress: widget.progress
                )
            )
        }
    }
}

private let twoPI = 2.0 * Float.pi

/// Alpha values extracted from the native component (for both dark and light mode) to
/// draw the spinning ticks.
private let alphaValues = [47, 47, 47, 47, 72, 97, 122, 147]

/// The alpha value that is used to draw the partially revealed ticks.
private let partiallyRevealedAlpha = 147

private class CupertinoActivityIndicatorPainter: CustomPainterBase {
    init(
        position: any Animation<Double>,
        activeColor: Color,
        radius: Float,
        progress: Float? = nil
    ) {
        self.position = position
        self.activeColor = activeColor
        self.radius = radius
        self.progress = progress ?? 1.0

        // Use a RRect instead of RSuperellipse since this shape is really small
        // and should make little visual difference.
        self.tickFundamentalShape = RRect.fromLTRBXY(
            -radius / CupertinoActivityIndicator.defaultIndicatorRadius,
            -radius / 3.0,
            radius / CupertinoActivityIndicator.defaultIndicatorRadius,
            -radius,
            radius / CupertinoActivityIndicator.defaultIndicatorRadius,
            radius / CupertinoActivityIndicator.defaultIndicatorRadius
        )
        super.init(repaint: position)
    }

    let position: any Animation<Double>
    let activeColor: Color
    let radius: Float
    let progress: Float

    // Use a RRect instead of RSuperellipse since this shape is really small
    // and should make little visual difference.
    let tickFundamentalShape: RRect

    override func paint(canvas: Canvas, size: Size) {
        var paint = Paint()
        let tickCount = alphaValues.count

        canvas.save()
        canvas.translate(size.width / 2.0, size.height / 2.0)

        let activeTick = Int(Float(tickCount) * Float(position.value))

        for i in 0..<Int(Float(tickCount) * progress) {
            let t = ((i - activeTick) % tickCount + tickCount) % tickCount
            paint.color = activeColor.withAlpha(
                .init(progress < 1 ? partiallyRevealedAlpha : alphaValues[t]),
            )
            canvas.drawRRect(tickFundamentalShape, paint)
            canvas.rotate(Float(twoPI / Float(tickCount)))
        }

        canvas.restore()
    }

    override func shouldRepaint(_ oldPainter: CustomPainter) -> Bool {
        guard let oldPainter = oldPainter as? CupertinoActivityIndicatorPainter else {
            return true
        }
        return oldPainter.position !== position
            || oldPainter.activeColor != activeColor
            || oldPainter.progress != progress
    }
}
