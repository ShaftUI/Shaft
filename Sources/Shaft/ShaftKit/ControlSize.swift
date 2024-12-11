/// The size to apply to controls within a view.
public enum ControlSize: CaseIterable, Hashable {
    /// A control version that is minimally sized.
    case mini

    /// A control version that is proportionally smaller size for space-constrained views.
    case small

    /// A control version that is the default size.
    case regular

    /// A control version that is prominently sized.
    case large
}

extension Widget {
    /// Sets the size for controls within this view.
    public func controlSize(_ size: ControlSize) -> some Widget {
        Inherited(size) { self }
    }
}
