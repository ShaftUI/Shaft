/// Calls callbacks in response to pointer events that are exclusive to mice.
///
/// It responds to events that are related to hovering, i.e. when the mouse
/// enters, exits (with or without pressing buttons), or moves over a region
/// without pressing buttons.
///
/// It does not respond to common events that construct gestures, such as when
/// the pointer is pressed, moved, then released or canceled. For these events,
/// use [RenderPointerListener].
///
/// If it has a child, it defers to the child for sizing behavior.
///
/// If it does not have a child, it grows to fit the parent-provided constraints.
///
/// See also:
///
///  * [MouseRegion], a widget that listens to hover events using
///    [RenderMouseRegion].
public class RenderMouseRegion: RenderProxyBoxWithHitTestBehavior, MouseTrackerAnnotation {
    /// Creates a render object that forwards pointer events to callbacks.
    ///
    /// All parameters are optional. By default this method creates an opaque
    /// mouse region with no callbacks and cursor being [MouseCursor.defer].
    public init(
        onEnter: PointerEnterEventListener? = nil,
        onHover: PointerHoverEventListener? = nil,
        onExit: PointerExitEventListener? = nil,
        cursor: MouseCursor = .defer,
        validForMouseTracker: Bool = true,
        opaque: Bool = true,
        child: RenderBox? = nil,
        hitTestBehavior: HitTestBehavior? = .opaque
    ) {
        self.onEnter = onEnter
        self.onHover = onHover
        self.onExit = onExit
        self.cursor = cursor
        self.validForMouseTracker = validForMouseTracker
        self.opaque = opaque
        super.init(behavior: hitTestBehavior ?? .opaque, child: child)
    }

    public override func hitTest(_ result: HitTestResult, position: Offset) -> Bool {
        return super.hitTest(result, position: position) && opaque
    }

    public override func handleEvent(_ event: PointerEvent, entry: HitTestEntry) {
        // assert(debugHandleEvent(event, entry))
        if let onHover = onHover, event is PointerHoverEvent {
            onHover(event as! PointerHoverEvent)
        }
    }

    /// Whether this object should prevent [RenderMouseRegion]s visually behind it
    /// from detecting the pointer, thus affecting how their [onHover], [onEnter],
    /// and [onExit] behave.
    ///
    /// If [opaque] is true, this object will absorb the mouse pointer and
    /// prevent this object's siblings (or any other objects that are not
    /// ancestors or descendants of this object) from detecting the mouse
    /// pointer even when the pointer is within their areas.
    ///
    /// If [opaque] is false, this object will not affect how [RenderMouseRegion]s
    /// behind it behave, which will detect the mouse pointer as long as the
    /// pointer is within their areas.
    ///
    /// This defaults to true.
    public var opaque: Bool {
        didSet {
            if opaque != oldValue {
                // Trigger [MouseTracker]'s device update to recalculate mouse states.
                markNeedsPaint()
            }
        }
    }

    /// How to behave during hit testing.
    ///
    /// This defaults to [HitTestBehavior.opaque] if nil.
    public var hitTestBehavior: HitTestBehavior? {
        get { behavior }
        set {
            let newBehavior = newValue ?? .opaque
            if behavior != newBehavior {
                behavior = newBehavior
                // Trigger [MouseTracker]'s device update to recalculate mouse states.
                markNeedsPaint()
            }
        }
    }

    public var onEnter: PointerEnterEventListener?

    /// Triggered when a pointer has moved onto or within the region without
    /// buttons pressed.
    ///
    /// This callback is not triggered by the movement of the object.
    public var onHover: PointerHoverEventListener?

    public var onExit: PointerExitEventListener?

    public var cursor: MouseCursor {
        didSet {
            if cursor != oldValue {
                // A repaint is needed in order to trigger a device update of
                // [MouseTracker] so that this new value can be found.
                markNeedsPaint()
            }
        }
    }

    public private(set) var validForMouseTracker: Bool

    public override func attach(_ owner: RenderOwner) {
        super.attach(owner)
        validForMouseTracker = true
    }

    public override func detach() {
        // It's possible that the renderObject be detached during mouse events
        // dispatching, set the [MouseTrackerAnnotation.validForMouseTracker] false to prevent
        // the callbacks from being called.
        validForMouseTracker = false
        super.detach()
    }

    public override func computeSizeForNoChild(_ constraints: BoxConstraints) -> Size {
        return constraints.biggest
    }
}
