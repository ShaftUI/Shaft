// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftSDL3

/// A single fixed-height row that typically contains some text as well as a
/// leading or trailing icon.
public final class ListTile<T: Hashable>: StatefulWidget {
    public init(
        _ data: T,
        onPressed: VoidCallback? = nil,
        @WidgetListBuilder children: () -> [Widget]
    ) {
        self.data = data
        self.onPressed = onPressed
        self.children = children()
    }

    /// The data that the list tile represents.
    public let data: T

    /// The callback that is called when the list tile is tapped or otherwise
    /// activated.
    ///
    /// If this is set to null, the list tile will be disabled.
    public let onPressed: VoidCallback?

    public let children: [Widget]

    public func createState() -> some State<ListTile> {
        ListTileState<T>()
    }
}

/// The state for a [ListTile] widget.
private final class ListTileState<T: Hashable>: State<ListTile<T>>, ListTileStyleContext {
    public var isHovered: Bool = false

    public var isFocused: Bool { false }

    public var isEnabled: Bool { widget.onPressed != nil }

    public var isSelected: Bool { isInSelection() }

    public var selectionEnabled: Bool {
        selectionDelegate != nil
    }

    public var children: [Widget] { widget.children }

    public private(set) var isPressed = false

    private func onTapDown(_ event: TapDownDetails) {
        setState { isPressed = true }
        updateSelectionIfNeeded()
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

    private var selectionDelegate: (any SelectionDelegate<T>)? {
        return SelectionScope.maybeOf(context)?.delegate as? any SelectionDelegate<T>
    }

    private func updateSelectionIfNeeded() {
        if let selectionDelegate {
            selectionDelegate.addSelection(widget.data)
        }
    }

    private func isInSelection() -> Bool {
        if let selectionDelegate {
            return selectionDelegate.isInSelection(widget.data)
        }
        return false
    }

    public override func build(context: BuildContext) -> Widget {
        MouseRegion(onEnter: onMouseEnter, onExit: onMouseExit) {
            Focus {
                GestureDetector(
                    onTapDown: onTapDown,
                    onTapUp: onTapUp
                ) {
                    let style: any ListTileStyle = Inherited.valueOf(context) ?? .default
                    style.build(context: self)
                }
            }
        }
    }
}

extension Widget {
    /// Sets the style for list tiles within this view to a list tile style with
    /// a custom appearance and custom interaction behavior.
    public func listTileStyle(_ style: any ListTileStyle) -> some Widget {
        Inherited(style) { self }
    }
}

/// A type that applies custom interaction behavior and a custom appearance to
/// all list tiles within a view hierarchy.
public protocol ListTileStyle: Equatable {
    /// Creates a widget that represents the body of a list tile.
    func build(context: Self.Context) -> Widget

    typealias Context = ListTileStyleContext
}

/// The properties of a list tile.
public protocol ListTileStyleContext {
    /// Whether the list tile is currently being pressed.
    var isPressed: Bool { get }

    /// Whether the list tile is currently being hovered over by the user's
    /// pointer.
    var isHovered: Bool { get }

    /// Whether the list tile is currently focused.
    var isFocused: Bool { get }

    /// Whether the list tile is currently enabled.
    var isEnabled: Bool { get }

    /// Whether the list tile is currently selected.
    var isSelected: Bool { get }

    /// Whether the list tile allows selection.
    var selectionEnabled: Bool { get }

    ///  The children of the list tile.
    var children: [Widget] { get }
}

/// The default list tile style.
public struct DefaultListTileStyle: ListTileStyle {
    public func build(context: any ListTileStyleContext) -> any Widget {
        if !context.selectionEnabled {
            return Row {
                context.children
            }
        }

        let color =
            context.isSelected || context.isHovered
            ? Color(0xFF_E8E8E8)
            : Color(0x00)
        return Row {
            context.children
        }
        .decoration(.box(color: color, borderRadius: .all(.circular(5))))
    }
}

extension ListTileStyle where Self == DefaultListTileStyle {
    /// The default list tile style.
    public static var `default`: Self {
        Self()
    }
}
