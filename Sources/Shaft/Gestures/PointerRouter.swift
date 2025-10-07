// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// A object that receives ``PointerEvent``
public protocol PointerRoute: AnyObject {
    func handleEvent(event: PointerEvent)
}

private struct PointerRouteKey: Hashable {
    let value: PointerRoute

    init(_ value: PointerRoute) {
        self.value = value
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(value))
    }

    static func == (lhs: PointerRouteKey, rhs: PointerRouteKey) -> Bool {
        ObjectIdentifier(lhs.value) == ObjectIdentifier(rhs.value)
    }
}

/// A table recording the routes and associated transforms.
private class PointerRoutes: Sequence {
    private var routes: [PointerRouteKey: Matrix4x4f?] = [:]

    func add(_ route: PointerRoute, _ transform: Matrix4x4f? = nil) {
        let key = PointerRouteKey(route)
        assert(!routes.keys.contains(key))
        routes[key] = transform
    }

    func remove(_ route: PointerRoute) {
        let key = PointerRouteKey(route)
        assert(routes.keys.contains(key))
        routes.removeValue(forKey: key)
    }

    func contains(_ route: PointerRoute) -> Bool {
        let key = PointerRouteKey(route)
        return routes.keys.contains(key)
    }

    func copy() -> PointerRoutes {
        let copy = PointerRoutes()
        copy.routes = routes
        return copy
    }

    var isEmpty: Bool {
        routes.isEmpty
    }

    var count: Int {
        routes.count
    }

    func makeIterator() -> DictionaryIterator<PointerRouteKey, Matrix4x4f?> {
        routes.makeIterator()
    }
}

/// A routing table for ``PointerEvent`` events.
public final class PointerRouter {
    private var routeMap = [Int: PointerRoutes]()
    private var globalRoutes = PointerRoutes()

    /// Adds a route to the routing table.
    ///
    /// Whenever this object routes a ``PointerEvent`` corresponding to
    /// pointer, call route.
    ///
    /// Routes added reentrantly within ``PointerRouter/route`` will take effect when
    /// routing the next event.
    public func addRoute(
        _ pointer: Int,
        _ handler: PointerRoute,
        _ transform: Matrix4x4f? = nil
    ) {
        let routes = routeMap.putIfAbsent(pointer, { .init() })
        assert(!routes.contains(handler))
        routes.add(handler, transform)
    }

    /// Removes a route from the routing table.
    ///
    /// No longer call route when routing a ``PointerEvent`` corresponding to
    /// pointer. Requires that this route was previously added to the router.
    ///
    /// Routes removed reentrantly within ``PointerRouter/route`` will take effect
    /// immediately.
    public func removeRoute(_ pointer: Int, _ handler: PointerRoute) {
        assert(routeMap.keys.contains(pointer))
        let routes = routeMap[pointer]!
        assert(routes.contains(handler))
        routes.remove(handler)
        if routes.isEmpty {
            routeMap.removeValue(forKey: pointer)
        }
    }

    /// Adds a route to the global entry in the routing table.
    ///
    /// Whenever this object routes a ``PointerEvent``, call route.
    ///
    /// Routes added reentrantly within ``PointerRouter/route`` will take effect when
    /// routing the next event.
    public func addGlobalRoute(
        _ handler: PointerRoute,
        _ transform: Matrix4x4f? = nil
    ) {
        assert(!globalRoutes.contains(handler))
        globalRoutes.add(handler, transform)
    }

    /// Removes a route from the global entry in the routing table.
    ///
    /// No longer call route when routing a ``PointerEvent``. Requires that this
    /// route was previously added via ``addGlobalRoute``.
    ///
    /// Routes removed reentrantly within ``PointerRouter/route`` will take effect
    /// immediately.
    public func removeGlobalRoute(_ handler: PointerRoute) {
        assert(globalRoutes.contains(handler))
        globalRoutes.remove(handler)
    }

    /// The number of global routes that have been registered.
    internal var debugGlobalRouteCount: Int {
        globalRoutes.count
    }

    /// Calls the routes registered for this pointer event.
    ///
    /// Routes are called in the order in which they were added to the
    /// PointerRouter object.
    public func route(_ event: PointerEvent) {
        let routes = routeMap[event.pointer]
        let copiedGlobalRoutes = globalRoutes.copy()
        if let routes {
            dispatchEventToRoutes(event, routes, copiedRoutes: routes.copy())
        }
        dispatchEventToRoutes(event, globalRoutes, copiedRoutes: copiedGlobalRoutes)
    }

    private func dispatchEventToRoutes(
        _ event: PointerEvent,
        _ referenceRoutes: PointerRoutes,
        copiedRoutes: PointerRoutes
    ) {
        for (route, transform) in copiedRoutes {
            if referenceRoutes.contains(route.value) {
                dispatch(event: event, route: route, transform: transform)
            }
        }
    }

    private func dispatch(
        event: PointerEvent,
        route: PointerRouteKey,
        transform: Matrix4x4f?
    ) {
        let event = event.transformed(transform)
        route.value.handleEvent(event: event)
    }
}
