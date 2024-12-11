public final class Resizable: StatefulWidget {
    public init(
        direction: Axis = .horizontal,
        leftRange: ClosedRange<Float> = 200...400,
        @WidgetBuilder left: () -> Widget,
        @WidgetBuilder right: () -> Widget
    ) {
        self.direction = direction
        self.leftRange = leftRange
        self.left = left()
        self.right = right()
    }

    public let direction: Axis

    public let leftRange: ClosedRange<Float>

    public let left: Widget

    public let right: Widget

    public func createState() -> ResizableState {
        ResizableState()
    }
}

public final class ResizableState: State<Resizable> {
    private var leftSize: Float = 200
    private var isDragging = false

    public override func initState() {
        super.initState()
    }

    public override func build(context: any BuildContext) -> any Widget {
        return MouseRegion(cursor: isDragging ? .system(.resizeLeftRight) : .defer) {
            Flex(direction: widget.direction, crossAxisAlignment: .stretch) {
                SizedBox(width: leftSize) {
                    widget.left
                }
                SizedBox(width: 2) {
                    DragHandle(
                        direction: widget.direction,
                        onDragUpdate: handleDragUpdate,
                        onDragStateChanged: handleDragStateChange
                    )
                }
                Expanded {
                    widget.right
                }
            }
        }
    }

    private func handleDragUpdate(offset: Offset) {
        let globalPosition = (context.findRenderObject() as! RenderBox).localToGlobal(.zero)
        let offsetToLeftTop = offset - globalPosition
        setState {
            leftSize = offsetToLeftTop.dx.clamped(to: widget.leftRange)
        }
    }

    private func handleDragStateChange(isDragging: Bool) {
        setState { self.isDragging = isDragging }
    }

}

private final class DragHandle: StatelessWidget {
    init(
        direction: Axis,
        onDragUpdate: @escaping (Offset) -> Void,
        onDragStateChanged: @escaping (Bool) -> Void
    ) {
        self.direction = direction
        self.onDragUpdate = onDragUpdate
        self.onDragStateChanged = onDragStateChanged
    }

    let direction: Axis
    let onDragUpdate: (Offset) -> Void
    let onDragStateChanged: (Bool) -> Void

    func build(context: any BuildContext) -> any Widget {
        MouseRegion(cursor: .system(.resizeLeftRight)) {
            GestureDetector(
                onPanStart: onPanStart,
                onPanUpdate: onPanUpdate,
                onPanEnd: onPanEnd
            ) {
                SizedBox()
                    .decoration(.box(color: Color(0xFF_E4E4E4)))
            }
        }
    }

    private func onPanStart(details: DragStartDetails) {
        onDragUpdate(details.globalPosition)
        onDragStateChanged(true)
    }

    private func onPanUpdate(details: DragUpdateDetails) {
        onDragUpdate(details.globalPosition)
    }

    private func onPanEnd(details: DragEndDetails) {
        onDragUpdate(details.globalPosition)
        onDragStateChanged(false)
    }
}
