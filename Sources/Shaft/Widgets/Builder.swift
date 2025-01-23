// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A resultBuilder that builds a single widget.
@resultBuilder
public struct WidgetBuilder {
    public static func buildBlock(_ components: Widget...) -> Widget {
        assert(components.count == 1)
        return components[0]
    }

    public static func buildEither(first component: Widget) -> Widget {
        return component
    }

    public static func buildEither(second component: Widget) -> Widget {
        return component
    }

    // static func buildOptional(_ component: Widget?) -> Widget {
    //     return component ?? Text("")
    // }

    // static func buildArray(_ components: [Widget]) -> Widget {
    //     return WidgetGroup(components: components)
    // }

    public static func buildExpression(_ expression: Widget) -> Widget {
        return expression
    }

    // static func buildLimitedAvailability(_ component: Widget) -> Widget {
    //     return component
    // }

    // static func buildFinalResult(_ component: Widget) -> Widget {
    //     return component
    // }
}

@resultBuilder
public struct OptionalWidgetBuilder {
    public static func buildBlock(_ components: Widget?...) -> Widget? {
        if components.count == 0 {
            return nil
        } else {
            assert(components.count == 1)
            return components[0]
        }
    }

    public static func buildEither(first component: Widget?) -> Widget? {
        return component
    }

    public static func buildEither(second component: Widget?) -> Widget? {
        return component
    }

    public static func buildOptional(_ component: Widget?) -> Widget? {
        return component
    }

    // static func buildArray(_ components: [Widget]) -> Widget? {
    //     return WidgetGroup(components: components)
    // }

    public static func buildExpression(_ expression: Widget?) -> Widget? {
        return expression
    }

    // static func buildLimitedAvailability(_ component: Widget) -> Widget? {
    //     return component
    // }

    // static func buildFinalResult(_ component: Widget) -> Widget? {
    //     return component
    // }
}

/// A resultBuilder that builds a list of widgets.
@resultBuilder
public struct WidgetListBuilder {
    public static func buildBlock(_ components: [Widget]...) -> [Widget] {
        return components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Widget]?) -> [Widget] {
        return component ?? []
    }

    public static func buildEither(first component: [Widget]) -> [Widget] {
        return component
    }

    public static func buildEither(second component: [Widget]) -> [Widget] {
        return component
    }

    public static func buildExpression(_ expression: Widget) -> [Widget] {
        return [expression]
    }

    public static func buildExpression(_ expression: [Widget]) -> [Widget] {
        return expression
    }

    public static func buildArray(_ components: [[Widget]]) -> [Widget] {
        return components.flatMap { $0 }
    }

    // static func buildLimitedAvailability(_ component: [Widget]) -> [Widget] {
    //     return component
    // }

    // static func buildFinalResult(_ component: [Widget]) -> [Widget] {
    //     return component
    // }
}
