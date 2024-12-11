// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Describes how [Scrollable] widgets should behave.
///
/// Used by [ScrollConfiguration] to configure the [Scrollable] widgets in a
/// subtree.
///
/// This class can be extended to further customize a [ScrollBehavior] for a
/// subtree. For example, overriding [ScrollBehavior.getScrollPhysics] sets the
/// default [ScrollPhysics] for [Scrollable]s that inherit this
/// [ScrollConfiguration]. Overriding [ScrollBehavior.buildOverscrollIndicator]
/// can be used to add or change the default [GlowingOverscrollIndicator]
/// decoration, while [ScrollBehavior.buildScrollbar] can be changed to modify
/// the default [Scrollbar].
///
/// When looking to easily toggle the default decorations, you can use
/// [ScrollBehavior.copyWith] instead of creating your own [ScrollBehavior]
/// class. The `scrollbar` and `overscrollIndicator` flags can turn these
/// decorations off.
public class ScrollBehavior {
    /// Called whenever a [ScrollConfiguration] is rebuilt with a new
    /// [ScrollBehavior] of the same [runtimeType].
    ///
    /// If the new instance represents different information than the old
    /// instance, then the method should return true, otherwise it should return
    /// false.
    ///
    /// If this method returns true, all the widgets that inherit from the
    /// [ScrollConfiguration] will rebuild using the new [ScrollBehavior]. If this
    /// method returns false, the rebuilds might be optimized away.
    public func shouldNotify(_ oldDelegate: ScrollBehavior) -> Bool {
        return false
    }

}

public class ScrollConfiguration {
    /// The [ScrollBehavior] for [Scrollable] widgets in the given [BuildContext].
    ///
    /// If no [ScrollConfiguration] widget is in scope of the given `context`,
    /// a default [ScrollBehavior] instance is returned.
    public static func of(_ context: BuildContext) -> ScrollBehavior {
        // let configuration = context.dependOnInheritedWidgetOfExactType(ScrollConfiguration.self)
        // return configuration?.behavior ?? ScrollBehavior()
        return ScrollBehavior()
    }

}
