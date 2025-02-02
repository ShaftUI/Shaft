import SwiftMath

/// A delegate used by [RenderSliverMultiBoxAdaptor] to manage its children.
///
/// [RenderSliverMultiBoxAdaptor] objects reify their children lazily to avoid
/// spending resources on children that are not visible in the viewport. This
/// delegate lets these objects create and remove children as well as estimate
/// the total scroll offset extent occupied by the full child list.
public protocol RenderSliverBoxChildManager {
    /// Called during layout when a new child is needed. The child should be
    /// inserted into the child list in the appropriate position, after the
    /// `after` child (at the start of the list if `after` is null). Its index and
    /// scroll offsets will automatically be set appropriately.
    ///
    /// The `index` argument gives the index of the child to show. It is possible
    /// for negative indices to be requested. For example: if the user scrolls
    /// from child 0 to child 10, and then those children get much smaller, and
    /// then the user scrolls back up again, this method will eventually be asked
    /// to produce a child for index -1.
    ///
    /// If no child corresponds to `index`, then do nothing.
    ///
    /// Which child is indicated by index zero depends on the [GrowthDirection]
    /// specified in the `constraints` of the [RenderSliverMultiBoxAdaptor]. For
    /// example if the children are the alphabet, then if
    /// [SliverConstraints.growthDirection] is [GrowthDirection.forward] then
    /// index zero is A, and index 25 is Z. On the other hand if
    /// [SliverConstraints.growthDirection] is [GrowthDirection.reverse] then
    /// index zero is Z, and index 25 is A.
    ///
    /// During a call to [createChild] it is valid to remove other children from
    /// the [RenderSliverMultiBoxAdaptor] object if they were not created during
    /// this frame and have not yet been updated during this frame. It is not
    /// valid to add any other children to this render object.
    func createChild(_ index: Int, after: RenderBox?)

    /// Remove the given child from the child list.
    ///
    /// Called by [RenderSliverMultiBoxAdaptor.collectGarbage], which itself is
    /// called from [RenderSliverMultiBoxAdaptor]'s `performLayout`.
    ///
    /// The index of the given child can be obtained using the
    /// [RenderSliverMultiBoxAdaptor.indexOf] method, which reads it from the
    /// [SliverMultiBoxAdaptorParentData.index] field of the child's
    /// [RenderObject.parentData].
    func removeChild(_ child: RenderBox)

    /// Called to estimate the total scrollable extents of this object.
    ///
    /// Must return the total distance from the start of the child with the
    /// earliest possible index to the end of the child with the last possible
    /// index.
    func estimateMaxScrollOffset(
        _ constraints: SliverConstraints,
        firstIndex: Int?,
        lastIndex: Int?,
        leadingScrollOffset: Float?,
        trailingScrollOffset: Float?
    ) -> Float

    /// Called to obtain a precise measure of the total number of children.
    ///
    /// Must return the number that is one greater than the greatest `index` for
    /// which `createChild` will actually create a child.
    ///
    /// This is used when [createChild] cannot add a child for a positive `index`,
    /// to determine the precise dimensions of the sliver. It must return an
    /// accurate and precise non-null value. It will not be called if
    /// [createChild] is always able to create a child (e.g. for an infinite
    /// list).
    var childCount: Int { get }

    /// The best available estimate of [childCount], or null if no estimate is available.
    ///
    /// This differs from [childCount] in that [childCount] never returns null (and must
    /// not be accessed if the child count is not yet available, meaning the [createChild]
    /// method has not been provided an index that does not create a child).
    ///
    /// See also:
    ///
    ///  * [SliverChildDelegate.estimatedChildCount], to which this getter defers.
    var estimatedChildCount: Int? { get }

    /// Called during [RenderSliverMultiBoxAdaptor.adoptChild] or
    /// [RenderSliverMultiBoxAdaptor.move].
    ///
    /// Subclasses must ensure that the [SliverMultiBoxAdaptorParentData.index]
    /// field of the child's [RenderObject.parentData] accurately reflects the
    /// child's index in the child list after this function returns.
    func didAdoptChild(_ child: RenderBox)

    /// Called during layout to indicate whether this object provided insufficient
    /// children for the [RenderSliverMultiBoxAdaptor] to fill the
    /// [SliverConstraints.remainingPaintExtent].
    ///
    /// Typically called unconditionally at the start of layout with false and
    /// then later called with true when the [RenderSliverMultiBoxAdaptor]
    /// fails to create a child required to fill the
    /// [SliverConstraints.remainingPaintExtent].
    ///
    /// Useful for subclasses to determine whether newly added children could
    /// affect the visible contents of the [RenderSliverMultiBoxAdaptor].
    func setDidUnderflow(_ value: Bool)

    /// Called at the beginning of layout to indicate that layout is about to
    /// occur.
    func didStartLayout()

    /// Called at the end of layout to indicate that layout is now complete.
    func didFinishLayout()

    /// In debug mode, asserts that this manager is not expecting any
    /// modifications to the [RenderSliverMultiBoxAdaptor]'s child list.
    ///
    /// This function always returns true.
    ///
    /// The manager is not required to track whether it is expecting modifications
    /// to the [RenderSliverMultiBoxAdaptor]'s child list and can return
    /// true without making any assertions.
    func debugAssertChildListLocked() -> Bool
}

extension RenderSliverBoxChildManager {
    var estimatedChildCount: Int? { nil }

    func debugAssertChildListLocked() -> Bool { true }

    func didStartLayout() {}

    func didFinishLayout() {}
}
/// Parent data structure used by [RenderSliverWithKeepAliveMixin].
public protocol KeepAliveParentDataMixin: ParentData {
    /// Whether to keep the child alive even when it is no longer visible.
    var keepAlive: Bool { get set }

    /// Whether the widget is currently being kept alive, i.e. has [keepAlive] set
    /// to true and is offscreen.
    var keptAlive: Bool { get }
}

// /// This class exists to dissociate [KeepAlive] from [RenderSliverMultiBoxAdaptor].
// ///
// /// [RenderSliverWithKeepAliveMixin.setupParentData] must be implemented to use
// /// a parentData class that uses the right mixin or whatever is appropriate.
public protocol RenderSliverWithKeepAliveMixin: RenderSliver {
    //   /// Alerts the developer that the child's parentData needs to be of type
    //   /// [KeepAliveParentDataMixin].
    //   @override
    //   void setupParentData(RenderObject child) {
    //     assert(child.parentData is KeepAliveParentDataMixin);
    //   }
}

/// Parent data structure used by [RenderSliverMultiBoxAdaptor].
public class SliverMultiBoxAdaptorParentData: SliverLogicalParentData, ContainerParentData,
    KeepAliveParentDataMixin
{
    public var keepAlive: Bool = false

    /// The index of this child according to the [RenderSliverBoxChildManager].
    public var index: Int?

    public fileprivate(set) var keptAlive: Bool = false

    public var nextSibling: RenderBox?

    public var previousSibling: RenderBox?
}

// /// A sliver with multiple box children.
// ///
// /// [RenderSliverMultiBoxAdaptor] is a base class for slivers that have multiple
// /// box children. The children are managed by a [RenderSliverBoxChildManager],
// /// which lets subclasses create children lazily during layout. Typically
// /// subclasses will create only those children that are actually needed to fill
// /// the [SliverConstraints.remainingPaintExtent].
// ///
// /// The contract for adding and removing children from this render object is
// /// more strict than for normal render objects:
// ///
// /// * Children can be removed except during a layout pass if they have already
// ///   been laid out during that layout pass.
// /// * Children cannot be added except during a call to [childManager], and
// ///   then only if there is no child corresponding to that index (or the child
// ///   corresponding to that index was first removed).
// ///
// /// See also:
// ///
// ///  * [RenderSliverToBoxAdapter], which has a single box child.
// ///  * [RenderSliverList], which places its children in a linear
// ///    array.
// ///  * [RenderSliverFixedExtentList], which places its children in a linear
// ///    array with a fixed extent in the main axis.
// ///  * [RenderSliverGrid], which places its children in arbitrary positions.
public class RenderSliverMultiBoxAdaptor: RenderSliver, RenderObjectWithChildren,
    RenderSliverWithKeepAliveMixin
{
    public typealias ChildType = RenderBox
    public typealias ParentDataType = SliverMultiBoxAdaptorParentData
    public var childMixin = RenderContainerMixin<RenderBox>()

    /// Creates a sliver with multiple box children.
    public init(childManager: RenderSliverBoxChildManager) {
        self.childManager = childManager
    }

    public override func setupParentData(_ child: RenderObject) {
        if !(child.parentData is SliverMultiBoxAdaptorParentData) {
            child.parentData = SliverMultiBoxAdaptorParentData()
        }
    }

    /// The delegate that manages the children of this object.
    ///
    /// Rather than having a concrete list of children, a
    /// [RenderSliverMultiBoxAdaptor] uses a [RenderSliverBoxChildManager] to
    /// create children during layout in order to fill the
    /// [SliverConstraints.remainingPaintExtent].
    public let childManager: RenderSliverBoxChildManager

    /// The nodes being kept alive despite not being visible.
    private var _keepAliveBucket: [Int: RenderBox] = [:]

    private var _debugDanglingKeepAlives: [RenderBox] = []

    /// Indicates whether integrity check is enabled.
    ///
    /// Setting this property to true will immediately perform an integrity check.
    ///
    /// The integrity check consists of:
    ///
    /// 1. Verify that the children index in childList is in ascending order.
    /// 2. Verify that there is no dangling keepalive child as the result of [move].
    public private(set) var debugChildIntegrityEnabled: Bool = true {
        didSet {
            assert {
                return _debugVerifyChildOrder()
                    && (!debugChildIntegrityEnabled || _debugDanglingKeepAlives.isEmpty)
            }
        }
    }

    public override func adoptChild(child: RenderObject) {
        super.adoptChild(child: child)
        let childParentData = child.parentData as! SliverMultiBoxAdaptorParentData
        if !childParentData.keptAlive {
            childManager.didAdoptChild(child as! RenderBox)
        }
    }

    private func _debugAssertChildListLocked() -> Bool {
        return childManager.debugAssertChildListLocked()
    }

    /// Verify that the child list index is in strictly increasing order.
    ///
    /// This has no effect in release builds.
    private func _debugVerifyChildOrder() -> Bool {
        if debugChildIntegrityEnabled {
            var child = firstChild
            var index: Int
            while child != nil {
                index = indexOf(child!)
                child = childAfter(child!)
                assert(child == nil || indexOf(child!) > index)
            }
        }
        return true
    }

    public func insert(_ child: RenderBox, after: RenderBox? = nil) {
        assert(!_keepAliveBucket.values.contains(where: { $0 === child }))
        _insert(child, after: after)
        assert(firstChild != nil)
        assert(_debugVerifyChildOrder())
    }

    public func move(child: RenderBox, after: RenderBox? = nil) {
        // There are two scenarios:
        //
        // 1. The child is not keptAlive.
        // The child is in the childList maintained by ContainerRenderObjectMixin.
        // We can call super.move and update parentData with the new slot.
        //
        // 2. The child is keptAlive.
        // In this case, the child is no longer in the childList but might be stored in
        // [_keepAliveBucket]. We need to update the location of the child in the bucket.
        let childParentData = child.parentData as! SliverMultiBoxAdaptorParentData
        if !childParentData.keptAlive {
            _move (child, after: after)
            childManager.didAdoptChild(child)  // updates the slot in the parentData
            // Its slot may change even if super.move does not change the position.
            // In this case, we still want to mark as needs layout.
            markNeedsLayout()
        } else {
            // If the child in the bucket is not current child, that means someone has
            // already moved and replaced current child, and we cannot remove this child.
            if _keepAliveBucket[childParentData.index!] === child {
                _keepAliveBucket.removeValue(forKey: childParentData.index!)
            }
            assert {
                _debugDanglingKeepAlives.removeAll(where: { $0 === child })
                return true
            }
            // Update the slot and reinsert back to _keepAliveBucket in the new slot.
            childManager.didAdoptChild(child)
            // If there is an existing child in the new slot, that mean that child will
            // be moved to other index. In other cases, the existing child should have been
            // removed by updateChild. Thus, it is ok to overwrite it.
            assert {
                if _keepAliveBucket[childParentData.index!] != nil {
                    _debugDanglingKeepAlives.append(_keepAliveBucket[childParentData.index!]!)
                }
                return true
            }
            _keepAliveBucket[childParentData.index!] = child
        }
    }

    public func remove(child: RenderBox) {
        let childParentData = child.parentData as! SliverMultiBoxAdaptorParentData
        if !childParentData.keptAlive {
            _remove(child)
            return
        }
        assert(_keepAliveBucket[childParentData.index!] === child)
        assert {
            _debugDanglingKeepAlives.removeAll(where: { $0 === child })
            return true
        }
        _keepAliveBucket.removeValue(forKey: childParentData.index!)
        dropChild(child: child)
    }

    public func removeAll() {
        _removeAll()
        _keepAliveBucket.values.forEach { dropChild(child: $0) }
        _keepAliveBucket.removeAll()
    }

    private func _createOrObtainChild(_ index: Int, after: RenderBox?) {
        invokeLayoutCallback { (constraints: SliverConstraints) in
            assert(constraints == self.sliverConstraints)
            if _keepAliveBucket.keys.contains(index) {
                let child = _keepAliveBucket.removeValue(forKey: index)!
                let childParentData = child.parentData as! SliverMultiBoxAdaptorParentData
                assert(childParentData.keptAlive)
                dropChild(child: child)
                child.parentData = childParentData
                insert(child, after: after)
                childParentData.keptAlive = false
            } else {
                childManager.createChild(index, after: after)
            }
        }
    }

    private func _destroyOrCacheChild(_ child: RenderBox) {
        let childParentData = child.parentData as! SliverMultiBoxAdaptorParentData
        if childParentData.keepAlive {
            assert(!childParentData.keptAlive)
            remove(child: child)
            _keepAliveBucket[childParentData.index!] = child
            child.parentData = childParentData
            super.adoptChild(child: child)
            childParentData.keptAlive = true
        } else {
            assert(child.parent === self)
            childManager.removeChild(child)
            assert(child.parent == nil)
        }
    }

    public override func attach(_ owner: RenderOwner) {
        super.attach(owner)
        for child in _keepAliveBucket.values {
            child.attach(owner)
        }
    }

    public override func detach() {
        super.detach()
        for child in _keepAliveBucket.values {
            child.detach()
        }
    }

    public func redepthChildren() {
        visitChildren { redepthChild($0) }
        _keepAliveBucket.values.forEach { redepthChild($0) }
    }

    public func visitChildren(_ visitor: (RenderBox) -> Void) {
        _visitChildren(visitor: visitor)
        _keepAliveBucket.values.forEach(visitor)
    }

    //   @override
    //   void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    //     super.visitChildren(visitor);
    //     // Do not visit children in [_keepAliveBucket].
    //   }

    /// Called during layout to create and add the child with the given index and
    /// scroll offset.
    ///
    /// Calls [RenderSliverBoxChildManager.createChild] to actually create and add
    /// the child if necessary. The child may instead be obtained from a cache;
    /// see [SliverMultiBoxAdaptorParentData.keepAlive].
    ///
    /// Returns false if there was no cached child and `createChild` did not add
    /// any child, otherwise returns true.
    ///
    /// Does not layout the new child.
    ///
    /// When this is called, there are no visible children, so no children can be
    /// removed during the call to `createChild`. No child should be added during
    /// that call either, except for the one that is created and returned by
    /// `createChild`.
    public func addInitialChild(index: Int = 0, layoutOffset: Float = 0.0) -> Bool {
        assert(_debugAssertChildListLocked())
        assert(firstChild == nil)
        _createOrObtainChild(index, after: nil)
        if firstChild != nil {
            assert(firstChild === lastChild)
            assert(indexOf(firstChild!) == index)
            let firstChildParentData = firstChild!.parentData as! SliverMultiBoxAdaptorParentData
            firstChildParentData.layoutOffset = layoutOffset
            return true
        }
        childManager.setDidUnderflow(true)
        return false
    }

    /// Called during layout to create, add, and layout the child before
    /// [firstChild].
    ///
    /// Calls [RenderSliverBoxChildManager.createChild] to actually create and add
    /// the child if necessary. The child may instead be obtained from a cache;
    /// see [SliverMultiBoxAdaptorParentData.keepAlive].
    ///
    /// Returns the new child or null if no child was obtained.
    ///
    /// The child that was previously the first child, as well as any subsequent
    /// children, may be removed by this call if they have not yet been laid out
    /// during this layout pass. No child should be added during that call except
    /// for the one that is created and returned by `createChild`.
    func insertAndLayoutLeadingChild(
        _ childConstraints: BoxConstraints,
        parentUsesSize: Bool = false
    ) -> RenderBox? {
        assert(_debugAssertChildListLocked())
        let index = indexOf(firstChild!) - 1
        _createOrObtainChild(index, after: nil)
        if indexOf(firstChild!) == index {
            firstChild!.layout(childConstraints, parentUsesSize: parentUsesSize)
            return firstChild
        }
        childManager.setDidUnderflow(true)
        return nil
    }

    /// Called during layout to create, add, and layout the child after
    /// the given child.
    ///
    /// Calls [RenderSliverBoxChildManager.createChild] to actually create and add
    /// the child if necessary. The child may instead be obtained from a cache;
    /// see [SliverMultiBoxAdaptorParentData.keepAlive].
    ///
    /// Returns the new child. It is the responsibility of the caller to configure
    /// the child's scroll offset.
    ///
    /// Children after the `after` child may be removed in the process. Only the
    /// new child may be added.
    func insertAndLayoutChild(
        _ childConstraints: BoxConstraints,
        after: RenderBox?,
        parentUsesSize: Bool = false
    ) -> RenderBox? {
        assert(_debugAssertChildListLocked())
        assert(after != nil)
        let index = indexOf(after!) + 1
        _createOrObtainChild(index, after: after)
        let child = childAfter(after!)
        if child != nil && indexOf(child!) == index {
            child!.layout(childConstraints, parentUsesSize: parentUsesSize)
            return child
        }
        childManager.setDidUnderflow(true)
        return nil
    }

    /// Returns the number of children preceding the `firstIndex` that need to be
    /// garbage collected.
    ///
    /// See also:
    ///
    ///   * [collectGarbage], which takes the leading and trailing number of
    ///     children to be garbage collected.
    ///   * [calculateTrailingGarbage], which similarly returns the number of
    ///     trailing children to be garbage collected.
    public func calculateLeadingGarbage(firstIndex: Int) -> Int {
        var walker = firstChild
        var leadingGarbage = 0
        while walker != nil && indexOf(walker!) < firstIndex {
            leadingGarbage += 1
            walker = childAfter(walker!)
        }
        return leadingGarbage
    }

    /// Returns the number of children following the `lastIndex` that need to be
    /// garbage collected.
    ///
    /// See also:
    ///
    ///   * [collectGarbage], which takes the leading and trailing number of
    ///     children to be garbage collected.
    ///   * [calculateLeadingGarbage], which similarly returns the number of
    ///     leading children to be garbage collected.
    public func calculateTrailingGarbage(lastIndex: Int) -> Int {
        var walker = lastChild
        var trailingGarbage = 0
        while walker != nil && indexOf(walker!) > lastIndex {
            trailingGarbage += 1
            walker = childBefore(walker!)
        }
        return trailingGarbage
    }

    /// Called after layout with the number of children that can be garbage
    /// collected at the head and tail of the child list.
    ///
    /// Children whose [SliverMultiBoxAdaptorParentData.keepAlive] property is
    /// set to true will be removed to a cache instead of being dropped.
    ///
    /// This method also collects any children that were previously kept alive but
    /// are now no longer necessary. As such, it should be called every time
    /// [performLayout] is run, even if the arguments are both zero.
    ///
    /// See also:
    ///
    ///   * [calculateLeadingGarbage], which can be used to determine
    ///     `leadingGarbage` here.
    ///   * [calculateTrailingGarbage], which can be used to determine
    ///     `trailingGarbage` here.
    func collectGarbage(_ leadingGarbage: Int, _ trailingGarbage: Int) {
        assert(_debugAssertChildListLocked())
        assert(childCount >= leadingGarbage + trailingGarbage)
        invokeLayoutCallback { (constraints: SliverConstraints) in
            var leadingGarbage = leadingGarbage
            var trailingGarbage = trailingGarbage
            while leadingGarbage > 0 {
                _destroyOrCacheChild(firstChild!)
                leadingGarbage -= 1
            }
            while trailingGarbage > 0 {
                _destroyOrCacheChild(lastChild!)
                trailingGarbage -= 1
            }
            // Ask the child manager to remove the children that are no longer being
            // kept alive. (This should cause _keepAliveBucket to change, so we have
            // to prepare our list ahead of time.)
            _keepAliveBucket.values.filter { child in
                let childParentData = child.parentData as! SliverMultiBoxAdaptorParentData
                return !childParentData.keepAlive
            }.forEach { childManager.removeChild($0) }
            assert(
                _keepAliveBucket.values.filter { child in
                    let childParentData = child.parentData as! SliverMultiBoxAdaptorParentData
                    return !childParentData.keepAlive
                }.isEmpty
            )
        }
    }

    /// Returns the index of the given child, as given by the
    /// [SliverMultiBoxAdaptorParentData.index] field of the child's [parentData].
    public func indexOf(_ child: RenderBox) -> Int {
        let childParentData = child.parentData as! SliverMultiBoxAdaptorParentData
        assert(childParentData.index != nil)
        return childParentData.index!
    }

    /// Returns the dimension of the given child in the main axis, as given by the
    /// child's [RenderBox.size] property. This is only valid after layout.
    public func paintExtentOf(_ child: RenderBox) -> Float {
        assert(child.hasSize)
        switch sliverConstraints.axis {
        case .horizontal:
            return child.size.width
        case .vertical:
            return child.size.height
        }
    }

    public override func hitTestChildren(
        _ result: SliverHitTestResult,
        mainAxisPosition: Float,
        crossAxisPosition: Float
    ) -> Bool {
        var child = lastChild
        let boxResult = BoxHitTestResult(wrap: result)
        while child != nil {
            if hitTestBoxChild(
                boxResult,
                child!,
                mainAxisPosition: mainAxisPosition,
                crossAxisPosition: crossAxisPosition
            ) {
                return true
            }
            child = childBefore(child!)
        }
        return false
    }

    public override func childMainAxisPosition(_ child: RenderObject) -> Float {
        return childScrollOffset(child)! - sliverConstraints.scrollOffset
    }

    public override func childScrollOffset(_ child: RenderObject) -> Float? {
        assert(child.parent === self)
        let childParentData = child.parentData as! SliverMultiBoxAdaptorParentData
        return childParentData.layoutOffset
    }

    public override func paintsChild(_ child: RenderObject) -> Bool {
        let childParentData = child.parentData as? SliverMultiBoxAdaptorParentData
        return childParentData?.index != nil
            && !_keepAliveBucket.keys.contains(childParentData!.index!)
    }

    public override func applyPaintTransform(_ child: RenderObject, transform: inout Matrix4x4f) {

        if !paintsChild(child) {
            // This can happen if some child asks for the global transform even though
            // they are not getting painted. In that case, the transform sets set to
            // zero since [applyPaintTransformForBoxChild] would end up throwing due
            // to the child not being configured correctly for applying a transform.
            // There's no assert here because asking for the paint transform is a
            // valid thing to do even if a child would not be painted, but there is no
            // meaningful non-zero matrix to use in this case.
            transform.setZero()
        } else {
            let child = child as! RenderBox
            applyPaintTransformForBoxChild(child, &transform)
        }
    }

    public override func paint(context: PaintingContext, offset: Offset) {
        if firstChild == nil {
            return
        }
        // offset is to the top-left corner, regardless of our axis direction.
        // originOffset gives us the delta from the real origin to the origin in the axis direction.
        let mainAxisUnit: Offset
        let crossAxisUnit: Offset
        let originOffset: Offset
        let addExtent: Bool

        switch applyGrowthDirectionToAxisDirection(
            sliverConstraints.axisDirection,
            sliverConstraints.growthDirection
        ) {
        case .up:
            mainAxisUnit = Offset(0.0, -1.0)
            crossAxisUnit = Offset(1.0, 0.0)
            originOffset = offset + Offset(0.0, geometry!.paintExtent)
            addExtent = true
        case .right:
            mainAxisUnit = Offset(1.0, 0.0)
            crossAxisUnit = Offset(0.0, 1.0)
            originOffset = offset
            addExtent = false
        case .down:
            mainAxisUnit = Offset(0.0, 1.0)
            crossAxisUnit = Offset(1.0, 0.0)
            originOffset = offset
            addExtent = false
        case .left:
            mainAxisUnit = Offset(-1.0, 0.0)
            crossAxisUnit = Offset(0.0, 1.0)
            originOffset = offset + Offset(geometry!.paintExtent, 0.0)
            addExtent = true
        }

        var child = firstChild
        while child != nil {
            let mainAxisDelta = Float(childMainAxisPosition(child!))
            let crossAxisDelta = Float(childCrossAxisPosition(child!))
            var childOffset = Offset(
                originOffset.dx + mainAxisUnit.dx * mainAxisDelta + crossAxisUnit.dx
                    * crossAxisDelta,
                originOffset.dy + mainAxisUnit.dy * mainAxisDelta + crossAxisUnit.dy
                    * crossAxisDelta
            )
            if addExtent {
                childOffset = childOffset + mainAxisUnit * paintExtentOf(child!)
            }

            // If the child's visible interval (mainAxisDelta, mainAxisDelta + paintExtentOf(child))
            // does not intersect the paint extent interval (0, constraints.remainingPaintExtent), it's hidden.
            if mainAxisDelta < sliverConstraints.remainingPaintExtent
                && mainAxisDelta + paintExtentOf(child!) > 0
            {
                context.paintChild(child!, offset: childOffset)
            }

            child = childAfter(child!)
        }
    }

    /// Asserts that the reified child list is not empty and has a contiguous
    /// sequence of indices.
    ///
    /// Always returns true.
    public func debugAssertChildListIsNonEmptyAndContiguous() -> Bool {
        assert {
            assert(firstChild != nil)
            var index = indexOf(firstChild!)
            var child = childAfter(firstChild!)
            while child != nil {
                index += 1
                assert(indexOf(child!) == index)
                child = childAfter(child!)
            }
            return true
        }
        return true
    }
}
