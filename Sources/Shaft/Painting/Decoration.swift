// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A description of a box decoration (a decoration applied to a [Rect]).
///
/// This class presents the abstract interface for all decorations. See
/// [BoxDecoration] for a concrete example.
///
/// To actually paint a [Decoration], use the [createBoxPainter] method to
/// obtain a [BoxPainter]. [Decoration] objects can be shared between boxes;
/// [BoxPainter] objects can cache resources to make painting on a particular
/// surface faster.
public protocol Decoration: AnyObject {
    /// Tests whether the given point, on a rectangle of a given size, would be
    /// considered to hit the decoration or not. For example, if the decoration
    /// only draws a circle, this function might return true if the point was
    /// inside the circle and false otherwise.
    ///
    /// The decoration may be sensitive to the [TextDirection]. The
    /// `textDirection` argument should therefore be provided. If it is known
    /// that the decoration is not affected by the text direction, then the
    /// argument may be omitted or set to null.
    ///
    /// When a [Decoration] is painted in a [Container] or [DecoratedBox] (which
    /// is what [Container] uses), the `textDirection` parameter will be
    /// populated based on the ambient [Directionality] (by way of the
    /// [RenderDecoratedBox] renderer).
    func hitTest(_ size: Size, _ position: Offset, textDirection: TextDirection?) -> Bool

    /// Returns a [BoxPainter] that will paint this decoration.
    ///
    /// The `onChanged` argument configures [BoxPainter.onChanged]. It can be
    /// omitted if there is no chance that the painter will change (for example,
    /// if it is a [BoxDecoration] with definitely no [DecorationImage]).
    func createBoxPainter(onChanged: VoidCallback?) -> BoxPainter
}

/// A stateful class that can paint a particular [Decoration].
///
/// [BoxPainter] objects can cache resources so that they can be used multiple
/// times.
///
/// Some resources used by [BoxPainter] may load asynchronously. When this
/// happens, the [onChanged] callback will be invoked. To stop this callback
/// from being called after the painter has been discarded, call [dispose].
public protocol BoxPainter: AnyObject {
    /// Paints the [Decoration] for which this object was created on the given
    /// canvas using the given configuration.
    ///
    /// The [ImageConfiguration] object passed as the third argument must, at a
    /// minimum, have a non-null [Size].
    ///
    /// If this object caches resources for painting (e.g. [Paint] objects), the
    /// cache may be flushed when [paint] is called with a new configuration.
    /// For this reason, it may be more efficient to call
    /// [Decoration.createBoxPainter] for each different rectangle that is being
    /// painted in a particular frame.
    ///
    /// For example, if a decoration's owner wants to paint a particular
    /// decoration once for its whole size, and once just in the bottom right,
    /// it might get two [BoxPainter] instances, one for each. However, when its
    /// size changes, it could continue using those same instances, since the
    /// previous resources would no longer be relevant and thus losing them
    /// would not be an issue.
    ///
    /// Implementations should paint their decorations on the canvas in a
    /// rectangle whose top left corner is at the given `offset` and whose size
    /// is given by `configuration.size`.
    ///
    /// When a [Decoration] is painted in a [Container] or [DecoratedBox] (which
    /// is what [Container] uses), the [ImageConfiguration.textDirection]
    /// property will be populated based on the ambient [Directionality].
    func paint(_ canvas: Canvas, _ offset: Offset, configuration: ImageConfiguration)

    /// Callback that is invoked if an asynchronously-loading resource used by the
    /// decoration finishes loading. For example, an image. When this is invoked,
    /// the [paint] method should be called again.
    ///
    /// Resources might not start to load until after [paint] has been called,
    /// because they might depend on the configuration.
    var onChanged: VoidCallback? { get }

}
