// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// An object that can handle events.
public protocol HitTestTarget {
    /// Implement this method to receive events.
    func handleEvent(_ event: PointerEvent, entry: HitTestEntry)
}

/// Data collected during a hit test about a specific [HitTestTarget].
///
/// Subclass this object to pass additional information from the hit test phase
/// to the event propagation phase.
public class HitTestEntry {
    init(_ target: HitTestTarget) {
        self.target = target
    }

    /// The [HitTestTarget] encountered during the hit test.
    let target: HitTestTarget

    /// Returns a matrix describing how [PointerEvent]s delivered to this
    /// [HitTestEntry] should be transformed from the global coordinate space of
    /// the screen to the local coordinate space of [target].
    public fileprivate(set) var transform: Matrix4x4f?
}

extension HitTestEntry: CustomStringConvertible {
    public var description: String {
        "HitTestEntry(target: \(target))"
    }
}

// A type of data that can be applied to a matrix by left-multiplication.
private enum TransformPart {
    case matrix(Matrix4x4f)
    case offset(Offset)

    /// Apply this transform part to `rhs` from the left.
    ///
    /// This should work as if this transform part is first converted to a
    /// matrix and then left-multiplied to `rhs`.
    func multiply(_ rhs: Matrix4x4f) -> Matrix4x4f {
        switch self {
        case .matrix(let lhs):
            return lhs * rhs
        case .offset(let lhs):
            return Matrix4x4f.translate(tx: lhs.dx, ty: lhs.dy, tz: 0) * rhs
        }
    }
}

/// The result of performing a hit test.
public class HitTestResult {
    public init() {
        self.storage = Storage()
    }

    /// Wraps `result` (usually a subtype of [HitTestResult]) to create a
    /// generic [HitTestResult].
    ///
    /// The [HitTestEntry]s added to the returned [HitTestResult] are also
    /// added to the wrapped `result` (both share the same underlying data
    /// structure to store [HitTestEntry]s).
    public init(wrap: HitTestResult) {
        self.storage = wrap.storage
    }

    private class Storage {
        var path: [HitTestEntry] = []

        /// A stack of transform parts.
        ///
        /// The transform part stack leading from global to the current object
        /// is stored in 2 parts:
        ///
        ///  * `_transforms` are globalized matrices, meaning they have been
        ///    multiplied by the ancestors and are thus relative to the global
        ///    coordinate space.
        ///  * `localTransforms` are local transform parts, which are relative
        ///    to the parent's coordinate space.
        ///
        /// When new transform parts are added they're appended to
        /// `localTransforms`, and are converted to global ones and moved to
        /// `_transforms` only when used.
        var transforms: [Matrix4x4f] = [Matrix4x4f.identity]
        var localTransforms: [TransformPart] = []
    }

    /// The underlying data structure to store [HitTestEntry]s. Might be shared
    /// by multiple [HitTestResult]s.
    private var storage: Storage

    /// An list of [HitTestEntry] objects recorded during the hit test.
    ///
    /// The first entry in the path is the most specific, typically the one at
    /// the leaf of tree being hit tested. Event propagation starts with the
    /// most specific (i.e., first) entry and proceeds in order through the path.
    public var path: [HitTestEntry] { storage.path }

    // Globalize all transform parts in `localTransforms` and move them to
    // transforms.
    private func globalizeTransforms() {
        if storage.localTransforms.isEmpty {
            return
        }
        var last = storage.transforms.last!
        for part in storage.localTransforms {
            last = part.multiply(last)
            storage.transforms.append(last)
        }
        storage.localTransforms.removeAll()
    }

    private var lastTransform: Matrix4x4f {
        globalizeTransforms()
        assert(storage.localTransforms.isEmpty)
        return storage.transforms.last!
    }

    /// Add a [HitTestEntry] to the path.
    ///
    /// The new entry is added at the end of the path, which means entries should
    /// be added in order from most specific to least specific, typically during an
    /// upward walk of the tree being hit tested.
    func add(_ entry: HitTestEntry) {
        assert(entry.transform == nil)
        entry.transform = lastTransform
        storage.path.append(entry)
    }

    /// Pushes a new transform matrix that is to be applied to all future
    /// [HitTestEntry]s added via [add] until it is removed via [popTransform].
    ///
    /// This method is only to be used by subclasses, which must provide
    /// coordinate space specific public wrappers around this function for their
    /// users (see [BoxHitTestResult.addWithPaintTransform] for such an example).
    ///
    /// The provided `transform` matrix should describe how to transform
    /// [PointerEvent]s from the coordinate space of the method caller to the
    /// coordinate space of its children. In most cases `transform` is derived
    /// from running the inverted result of [RenderObject.applyPaintTransform]
    /// through [PointerEvent.removePerspectiveTransform] to remove
    /// the perspective component.
    ///
    /// If the provided `transform` is a translation matrix, it is much faster
    /// to use [pushOffset] with the translation offset instead.
    ///
    /// [HitTestable]s need to call this method indirectly through a convenience
    /// method defined on a subclass before hit testing a child that does not
    /// have the same origin as the parent. After hit testing the child,
    /// [popTransform] has to be called to remove the child-specific `transform`.
    func pushTransform(_ transform: Matrix4x4f) {
        // assert(
        // _debugVectorMoreOrLessEquals(transform.getRow(2), Vector4(0, 0, 1, 0)) &&
        // _debugVectorMoreOrLessEquals(transform.getColumn(2), Vector4(0, 0, 1, 0)),
        // 'The third row and third column of a transform matrix for pointer '
        // 'events must be Vector4(0, 0, 1, 0) to ensure that a transformed '
        // 'point is directly under the pointing device. Did you forget to run the paint '
        // 'matrix through PointerEvent.removePerspectiveTransform? '
        // 'The provided matrix is:\n$transform',
        // );
        storage.localTransforms.append(.matrix(transform))
    }

    /// Pushes a new translation offset that is to be applied to all future
    /// [HitTestEntry]s added via [add] until it is removed via [popTransform].
    ///
    /// This method is only to be used by subclasses, which must provide
    /// coordinate space specific public wrappers around this function for their
    /// users (see [BoxHitTestResult.addWithPaintOffset] for such an example).
    ///
    /// The provided `offset` should describe how to transform [PointerEvent]s from
    /// the coordinate space of the method caller to the coordinate space of its
    /// children. Usually `offset` is the inverse of the offset of the child
    /// relative to the parent.
    ///
    /// [HitTestable]s need to call this method indirectly through a convenience
    /// method defined on a subclass before hit testing a child that does not
    /// have the same origin as the parent. After hit testing the child,
    /// [popTransform] has to be called to remove the child-specific `transform`.
    func pushOffset(_ offset: Offset) {
        storage.localTransforms.append(.offset(offset))
    }

    /// Removes the last transform added via [pushTransform] or [pushOffset].
    ///
    /// This method is only to be used by subclasses, which must provide
    /// coordinate space specific public wrappers around this function for their
    /// users (see [BoxHitTestResult.addWithPaintTransform] for such an example).
    ///
    /// This method must be called after hit testing is done on a child that
    /// required a call to [pushTransform] or [pushOffset].
    func popTransform() {
        if storage.localTransforms.isNotEmpty {
            storage.localTransforms.removeLast()
        } else {
            storage.transforms.removeLast()
        }
        assert(storage.transforms.isNotEmpty)
    }
}

extension HitTestResult: CustomStringConvertible {
    public var description: String {
        "HitTestResult(path: \(path.map { $0.target }))"
    }
}
