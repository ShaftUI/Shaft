// Copyright 2025 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A `TextSpan` that can change its visual style when hovered.
///
/// This is a simpler implementation that uses the normal TextSpan hover style
/// without trying to dynamically update styles.
public final class HoverableTextSpan: TextSpan {
    public init(
        text: String? = nil,
        children: [InlineSpan]? = nil,
        normalStyle: TextStyle? = nil,
        hoverStyle: TextStyle? = nil,
        recognizer: GestureRecognizer? = nil,
        cursor: MouseCursor = .system(.click)
    ) {
        super.init(
            text: text,
            children: children,
            style: normalStyle,
            recognizer: recognizer,
            mouseCursor: cursor,
            onEnter: nil,
            onExit: nil,
            semanticsLabel: nil,
            spellOut: nil
        )
    }

}
