// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CSkia
import SwiftSDL3

/// A button role provides a description of a button’s purpose.
public enum ButtonRole {
    /// A role that indicates a primary button.
    case primary

    /// A role that indicates a secondary button.
    case secondary

    /// A role that indicates a button that cancels an operation.
    case cancel

    /// A role that indicates a destructive button.
    case destructive

    /// A role that indicates a button that serves as a link.
    case link
}

/// A control that initiates an action.
public final class Button: StatefulWidget {
    public init(
        role: ButtonRole = .primary,
        onPressed: VoidCallback? = nil,
        @WidgetBuilder child: () -> Widget
    ) {
        self.role = role
        self.onPressed = onPressed
        self.child = child()
    }

    /// The role of the button.
    public let role: ButtonRole

    /// The callback that is called when the button is tapped or otherwise
    /// activated.
    ///
    /// If this is set to null, the button will be disabled.
    public let onPressed: VoidCallback?

    public let child: Widget

    public func createState() -> some State<Button> {
        ButtonState()
    }

    /// A type that applies custom interaction behavior and a custom appearance to
    /// all buttons within a view hierarchy.
    public protocol Style: Equatable {
        /// Creates a widget that represents the body of a button.
        func build(context: Self.Context) -> Widget

        typealias Context = StyleContext
    }

    /// The properties of a button.
    public protocol StyleContext {
        /// Whether the button is currently being pressed.
        var isPressed: Bool { get }

        /// Whether the button is currently being hovered over by the user's
        /// pointer.
        var isHovered: Bool { get }

        /// Whether the button is currently focused.
        var isFocused: Bool { get }

        /// Whether the button is currently enabled.
        var isEnabled: Bool { get }

        /// The role of the button.
        var role: ButtonRole { get }

        /// The control size that should be used for the button.
        var controlSize: ControlSize { get }

        ///  The child of the button.
        var child: Widget { get }
    }
}

/// The state for a [Button] widget.
private final class ButtonState: State<Button>, Button.StyleContext {
    public var isHovered: Bool = false

    public var isFocused: Bool { false }

    public var isEnabled: Bool { widget.onPressed != nil }

    public var role: ButtonRole { widget.role }

    public var controlSize: ControlSize { Inherited.valueOf(context) ?? .regular }

    public var child: any Widget { widget.child }

    public private(set) var isPressed = false

    private func onTapDown(_ event: TapDownDetails) {
        setState { isPressed = true }
    }

    private func onTapUp(_ event: TapUpDetails) {
        setState { isPressed = false }
        widget.onPressed?()
    }

    private func onMouseEnter(_ event: PointerEnterEvent) {
        setState { isHovered = true }
    }

    private func onMouseExit(_ event: PointerExitEvent) {
        setState { isHovered = false }
    }

    public override func build(context: BuildContext) -> Widget {
        MouseRegion(onEnter: onMouseEnter, onExit: onMouseExit, cursor: .system(.click)) {
            Focus {
                GestureDetector(
                    onTapDown: onTapDown,
                    onTapUp: onTapUp
                ) {
                    let style: any Button.Style = Inherited.valueOf(context) ?? .default
                    style.build(context: self)
                }
            }
        }
    }
}

extension Widget {
    /// Sets the style for buttons within this view to a button style with a
    /// custom appearance and custom interaction behavior.
    public func buttonStyle(_ style: any Button.Style) -> some Widget {
        Inherited(style) { self }
    }
}

/// The default button style.
public struct DefaultButtonStyle: Button.Style {
    private func padding(_ size: ControlSize) -> EdgeInsets {
        return switch size {
        case .mini: .symmetric(horizontal: 6.0)
        case .small: .symmetric(vertical: 1.0, horizontal: 7.0)
        case .regular: .symmetric(vertical: 3.0, horizontal: 7.0)
        case .large: .symmetric(vertical: 4.0, horizontal: 8.0)
        }
    }

    private func radius(_ size: ControlSize) -> BorderRadius {
        return switch size {
        case .mini: .circular(2.0)
        case .small: .circular(2.0)
        case .regular: .circular(5.0)
        case .large: .circular(7.0)
        }
    }

    public func build(context: any Button.StyleContext) -> any Widget {
        let color = Color.argb(255, 0, 122, 255)
        let textColor = Color.argb(255, 255, 255, 255)

        let shadowColor1: Color
        let shadowColor2: Color

        if context.role == .primary {
            shadowColor1 = color.withOpacity(0.24)
            shadowColor2 = color.withOpacity(0.12)
        } else {
            shadowColor1 = .rgbo(0, 0, 0, 0.05)
            shadowColor2 = .rgbo(0, 0, 0, 0.3)
        }

        return context.child
            .textStyle(.init(color: textColor))
            .padding(padding(context.controlSize))
            .decoration(
                .box(
                    color: context.isPressed ? color.withAlpha(127) : color,
                    borderRadius: radius(context.controlSize),
                    boxShadow: [
                        .init(
                            color: shadowColor1,
                            offset: Offset(0.0, 0.5),
                            blurRadius: 2.5,
                            spreadRadius: 0.0,
                            blurStyle: .normal
                        ),
                        .init(
                            color: shadowColor2,
                            offset: Offset(0.0, 0.0),
                            blurRadius: 0.0,
                            spreadRadius: 0.5,
                            blurStyle: .normal
                        ),
                    ]
                )
            )
    }
}

extension Button.Style where Self == DefaultButtonStyle {
    /// The default button style.
    public static var `default`: Self {
        Self()
    }
}
