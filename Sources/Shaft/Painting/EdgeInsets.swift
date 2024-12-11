// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Base class for [EdgeInsets] that allows for text-direction aware
/// resolution.
///
/// A property or argument of this type accepts classes created either with [
/// EdgeInsets.fromLTRB] and its variants, or [
/// EdgeInsetsDirectional.fromSTEB] and its variants.
///
/// To convert an [EdgeInsetsGeometry] object of indeterminate type into a
/// [EdgeInsets] object, call the [resolve] method.
public protocol EdgeInsetsGeometry {
    func resolve(_ direction: TextDirection?) -> EdgeInsets

    func isEqualTo(_ other: EdgeInsetsGeometry) -> Bool

    /// The total offset in the horizontal direction.
    var horizontal: Float { get }

    /// The total offset in the vertical direction.
    var vertical: Float { get }
}

public struct EdgeInsets: EdgeInsetsGeometry, Equatable {
    public init(left: Float, top: Float, right: Float, bottom: Float) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }

    /// Creates insets where all the offsets are `value`.
    public static func all(_ value: Float) -> EdgeInsets {
        EdgeInsets(left: value, top: value, right: value, bottom: value)
    }

    /// Creates insets with symmetrical vertical and horizontal offsets.
    public static func symmetric(
        vertical: Float = 0,
        horizontal: Float = 0
    ) -> EdgeInsets {
        EdgeInsets(left: horizontal, top: vertical, right: horizontal, bottom: vertical)
    }

    /// Creates insets with only the given values non-zero.
    ///
    /// Example:
    ///
    /// Left margin indent of 40 pixels:
    ///
    ///
    /// EdgeInsets.only(left: 40.0)
    ///
    public static func only(
        left: Float = 0.0,
        top: Float = 0.0,
        right: Float = 0.0,
        bottom: Float = 0.0
    ) -> EdgeInsets {
        EdgeInsets(left: left, top: top, right: right, bottom: bottom)
    }

    /// An EdgeInsets with zero offsets in each direction.
    public static let zero = EdgeInsets.only()

    /// The offset from the left.
    let left: Float

    /// The offset from the top.
    let top: Float

    /// The offset from the right.
    let right: Float

    /// The offset from the bottom.
    let bottom: Float

    public var horizontal: Float { (left + right) }

    public var vertical: Float { (top + bottom) }

    public func resolve(_ direction: TextDirection?) -> EdgeInsets {
        self
    }

    public func isEqualTo(_ other: EdgeInsetsGeometry) -> Bool {
        if let other = other as? Self {
            return self == other
        }
        return false
    }
}

extension EdgeInsetsGeometry where Self == EdgeInsets {
    /// Creates insets where all the offsets are `value`.
    public static func all(_ value: Float) -> Self {
        .all(value)
    }

    public static func only(
        left: Float = 0.0,
        top: Float = 0.0,
        right: Float = 0.0,
        bottom: Float = 0.0
    ) -> Self {
        .only(left: left, top: top, right: right, bottom: bottom)
    }

    public static func ltrb(_ left: Float, _ top: Float, _ right: Float, _ bottom: Float) -> Self {
        .init(left: left, top: top, right: right, bottom: bottom)
    }

    /// Creates insets with symmetrical vertical and horizontal offsets.
    public static func symmetric(vertical: Float = 0, horizontal: Float = 0) -> Self {
        .symmetric(vertical: vertical, horizontal: horizontal)
    }

    public static func horizontal(_ value: Float) -> Self {
        .symmetric(horizontal: value)
    }

    public static func vertical(_ value: Float) -> Self {
        .symmetric(vertical: value)
    }

    public static var zero: Self { .zero }
}
