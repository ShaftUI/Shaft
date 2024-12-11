// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Signature for a function that takes a [RenderBox] and returns the [Size]
/// that the [RenderBox] would have if it were laid out with the given
/// [BoxConstraints].
///
/// The methods of [ChildLayoutHelper] adhere to this signature.
typealias ChildLayouter = (_ child: RenderBox, _ constraints: BoxConstraints) -> Size

/// A collection of static functions to layout a [RenderBox] child with the
/// given set of [BoxConstraints].
///
/// All of the functions adhere to the [ChildLayouter] signature.
final class ChildLayoutHelper {
    /// Returns the [Size] that the [RenderBox] would have if it were to
    /// be laid out with the given [BoxConstraints].
    ///
    /// This method calls [RenderBox.getDryLayout] on the given [RenderBox].
    ///
    /// This method should only be called by the parent of the provided
    /// [RenderBox] child as it binds parent and child together (if the child
    /// is marked as dirty, the child will also be marked as dirty).
    ///
    /// See also:
    ///
    ///  * [layoutChild], which actually lays out the child with the given
    ///    constraints.
    static func dryLayoutChild(_ child: RenderBox, _ constraints: BoxConstraints) -> Size {
        // return child.getDryLayout(constraints)
        fatalError()
    }

    /// Lays out the [RenderBox] with the given constraints and returns its
    /// [Size].
    ///
    /// This method calls [RenderBox.layout] on the given [RenderBox] with
    /// `parentUsesSize` set to true to receive its [Size].
    ///
    /// This method should only be called by the parent of the provided
    /// [RenderBox] child as it binds parent and child together (if the child
    /// is marked as dirty, the child will also be marked as dirty).
    ///
    /// See also:
    ///
    ///  * [dryLayoutChild], which does not perform a real layout of the child.
    static func layoutChild(child: RenderBox, constraints: BoxConstraints) -> Size {
        child.layout(constraints, parentUsesSize: true)
        return child.size
    }
}
