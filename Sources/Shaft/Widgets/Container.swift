// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A widget that paints a [Decoration] either before or after its child paints.
///
/// [Container] insets its child by the widths of the borders; this widget does
/// not.
///
/// Commonly used with [BoxDecoration].
///
/// The [child] is not clipped. To clip a child to the shape of a particular
/// [ShapeDecoration], consider using a [ClipPath] widget.
public class DecoratedBox: SingleChildRenderObjectWidget {
    public init(
        decoration: Decoration,
        position: DecorationPosition = .background,
        @WidgetBuilder child: () -> Widget
    ) {
        self.decoration = decoration
        self.position = position
        self.child = child()
    }

    /// What decoration to paint.
    ///
    /// Commonly a [BoxDecoration].
    public var decoration: Decoration

    /// Whether to paint the box decoration behind or in front of the child.
    public var position: DecorationPosition

    public var child: Widget?

    public func createRenderObject(context: BuildContext) -> RenderDecoratedBox {
        RenderDecoratedBox(
            decoration: decoration,
            position: position,
            configuration: ImageConfiguration.empty
        )
    }

    public func updateRenderObject(context: BuildContext, renderObject: RenderDecoratedBox) {
        renderObject.decoration = decoration
        renderObject.position = position
    }
}

extension Widget {
    /// Decorates this widget with a [Decoration].
    public func decoration(
        _ decoration: Decoration,
        position: DecorationPosition = .background
    ) -> DecoratedBox {
        DecoratedBox(decoration: decoration, position: position) {
            self
        }
    }

    /// Wraps this widget with a background. This is a shorthand for
    /// `decoratedBox(decoration: .box(color: color))`.
    public func background(_ color: Color) -> DecoratedBox {
        decoration(.box(color: color))
    }

    /// Wraps this widget with a box decoration. This is a shorthand for
    /// `decoration(.box(...))` with the specified parameters.
    ///
    /// - Parameters:
    ///   - color: The color to fill the box with.
    ///   - border: The border to draw around the box.
    ///   - borderRadius: The radii for each corner of the box.
    ///   - boxShadow: The shadows to paint behind the box.
    /// - Returns: A decorated box containing this widget.
    public func boxDecoration(
        color: Color? = nil,
        border: BoxBorder? = nil,
        borderRadius: (any BorderRadiusGeometry)? = nil,
        boxShadow: [BoxShadow]? = nil
    ) -> DecoratedBox {
        decoration(
            .box(color: color, border: border, borderRadius: borderRadius, boxShadow: boxShadow)
        )
    }
}
