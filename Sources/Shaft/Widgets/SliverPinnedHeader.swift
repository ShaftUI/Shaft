/// A sliver that keeps its Widget child at the top of the a [CustomScrollView].
///
/// This sliver is preferable to the general purpose [SliverPersistentHeader]
/// for its relatively narrow use case because there's no need to create a
/// [SliverPersistentHeaderDelegate] or to predict the header's size.
///
/// {@tool dartpad}
/// This example demonstrates that the sliver's size can change. Pressing the
/// floating action button replaces the one line of header text with two lines.
///
/// ** See code in examples/api/lib/widgets/sliver/pinned_header_sliver.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// A more elaborate example which creates an app bar that's similar to the one
/// that appears in the iOS Settings app. In this example the pinned header
/// starts out transparent and the first item in the list serves as the app's
/// "Settings" title. When the title item has been scrolled completely behind
/// the pinned header, the header animates its opacity from 0 to 1 and its
/// (centered) "Settings" title appears. The fact that the header's opacity
/// depends on the height of the title item - which is unknown until the list
/// has been laid out - necessitates monitoring the title item's
/// [SliverGeometry.scrollExtent] and the header's [SliverConstraints.scrollOffset]
/// from a scroll [NotificationListener]. See the source code for more details.
///
/// ** See code in examples/api/lib/widgets/sliver/pinned_header_sliver.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SliverResizingHeader] - which similarly pins the header at the top
///    of the [CustomScrollView] but reacts to scrolling by resizing the header
///    between its minimum and maximum extent limits.
///  * [SliverFloatingHeader] - which animates the header in and out of view
///    in response to downward and upwards scrolls.
///  * [SliverPersistentHeader] - a general purpose header that can be
///    configured as a pinned, resizing, or floating header.
public class SliverPinnedHeader: SingleChildRenderObjectWidget {
    /// Creates a sliver whose [Widget] child appears at the top of a
    /// [CustomScrollView].
    public init(
        key: (any Key)? = nil,
        @WidgetBuilder child: () -> Widget
    ) {
        self.key = key
        self.child = child()
    }

    public let key: (any Key)?

    public let child: (any Widget)?

    public func createRenderObject(context: BuildContext) -> RenderObject {
        return _RenderSliverPinnedHeader()
    }
}

class _RenderSliverPinnedHeader: RenderSliverSingleBoxAdapter {
    var childExtent: Float {
        if child == nil {
            return 0.0
        }
        assert(child!.hasSize)
        return switch sliverConstraints.axis {
        case .vertical:
            child!.size.height
        case .horizontal:
            child!.size.width
        }
    }

    override func childMainAxisPosition(_ child: RenderObject) -> Float {
        return 0
    }

    override func performLayout() {
        let constraints = sliverConstraints
        child?.layout(constraints.asBoxConstraints(), parentUsesSize: true)

        let layoutExtent =
            (childExtent - constraints.scrollOffset).clamped(
                to: 0...constraints.remainingPaintExtent
            )
        let paintExtent = min(childExtent, constraints.remainingPaintExtent - constraints.overlap)
        geometry = SliverGeometry(
            scrollExtent: childExtent,
            paintExtent: paintExtent,
            paintOrigin: constraints.overlap,
            layoutExtent: layoutExtent,
            maxPaintExtent: childExtent,
            maxScrollObstructionExtent: childExtent,
            hasVisualOverflow: true,  // Conservatively say we do have overflow to avoid complexity.
            cacheExtent: calculateCacheOffset(constraints, from: 0.0, to: childExtent)
        )
    }
}
