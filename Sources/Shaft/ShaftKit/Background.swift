// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A `Background` widget that provides a background style and level to its
/// child widget.
///
/// This widget is a `StatelessWidget` that takes a child widget and wraps it
/// with a background style and level. The background level is incremented based
/// on the current context, and the style is applied accordingly.
///
/// Usage:
/// ```swift
/// Background {
///     // Your child widget here
/// }
/// ```
public final class Background: StatelessWidget {
    public init(
        root: Bool = false,
        @WidgetBuilder child: () -> Widget
    ) {
        self.level = root ? 0 : nil
        self.child = child()
    }

    public let child: Widget

    public let level: Int?

    public func build(context: BuildContext) -> Widget {
        let currentLevel = level ?? BackgroundLevel.maybeOf(context)?.level
        let nextLevel = currentLevel.map { $0 + 1 } ?? 0
        let style: any Background.Style = Inherited.valueOf(context) ?? .default
        return BackgroundLevel(level: nextLevel) {
            style.build(context: .init(level: nextLevel, child: child))
        }
    }

    /// Style for a ``Background`` widget.
    public protocol Style: Equatable {
        /// Creates a widget that represents the body of a button.
        func build(context: Self.Context) -> Widget

        typealias Context = StyleContext
    }

    public struct StyleContext {
        public let level: Int

        public let child: Widget
    }
}

public final class BackgroundLevel: InheritedWidget {
    public init(
        level: Int,
        @WidgetBuilder child: () -> Widget
    ) {
        self.level = level
        self.child = child()
    }

    public let level: Int
    public let child: Widget

    public func build() -> Widget {
        child
    }

    public func updateShouldNotify(_ oldWidget: BackgroundLevel) -> Bool {
        level != oldWidget.level
    }
}

extension Widget {
    /// Sets the style for ``Background``s within this view.
    public func backgroundStyle(_ style: any Background.Style) -> some Widget {
        Inherited(style) { self }
    }
}

public struct DefaultBackgroundStyle: Background.Style {
    public init() {}

    public func build(context: Background.StyleContext) -> Widget {
        let color =
            context.level % 2 == 0
            ? Color.argb(255, 255, 255, 255)
            : Color.argb(255, 242, 242, 247)
        return DecoratedBox(decoration: .box(color: color)) {
            context.child
        }
    }
}

extension Background.Style where Self == DefaultBackgroundStyle {
    /// The built-in style for ``Background``s.
    public static var `default`: DefaultBackgroundStyle {
        DefaultBackgroundStyle()
    }
}
