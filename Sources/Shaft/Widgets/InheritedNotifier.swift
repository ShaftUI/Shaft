// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An inherited widget for a [Listenable] [notifier], which updates its
/// dependencies when the [notifier] is triggered.
///
/// This is a variant of [InheritedWidget], specialized for subclasses of
/// [Listenable], such as [ChangeNotifier] or [ValueNotifier].
///
/// Dependents are notified whenever the [notifier] sends notifications, or
/// whenever the identity of the [notifier] changes.
///
/// Multiple notifications are coalesced, so that dependents only rebuild once
/// even if the [notifier] fires multiple times between two frames.
///
/// Typically this class is subclassed with a class that provides an `of` static
/// method that calls [BuildContext.dependOnInheritedWidgetOfExactType] with
/// that class.
///
/// The [updateShouldNotify] method may also be overridden, to change the logic
/// in the cases where [notifier] itself is changed. The [updateShouldNotify]
/// method is called with the old [notifier] in the case of the [notifier] being
/// changed. When it returns true, the dependents are marked as needing to be
/// rebuilt this frame.
public class InheritedNotifier<T: Listenable>: InheritedWidget {
    internal init(notifier: T? = nil, child: Widget) {
        self.notifier = notifier
        self.child = child
    }

    public let child: Widget

    /// The [Listenable] object to which to listen.
    ///
    /// Whenever this object sends change notifications, the dependents of this
    /// widget are triggered.
    ///
    /// By default, whenever the [notifier] is changed (including when changing
    /// to or from null), if the old notifier is not equal to the new notifier
    /// (as determined by the `==` operator), notifications are sent. This
    /// behavior can be overridden by overriding [updateShouldNotify].
    ///
    /// While the [notifier] is null, no notifications are sent, since the null
    /// object cannot itself send notifications.
    public let notifier: T?

    public func updateShouldNotify(_ oldWidget: InheritedNotifier<T>) -> Bool {
        oldWidget.notifier !== notifier
    }

    public func createElement() -> Element {
        InheritedNotifierElement<T>(self)
    }

}

public class InheritedNotifierElement<T: Listenable>: InheritedElement {
    init(_ widget: InheritedNotifier<T>) {
        super.init(widget)
        widget.notifier?.addListener(self, callback: handleUpdate)
    }

    private var _dirty = false

    private func handleUpdate() {
        _dirty = true
        markNeedsBuild()
    }

    public override func update(_ newWidget: Widget) {
        let oldNotifier = (widget as! InheritedNotifier<T>).notifier
        let newNotifier = (newWidget as! InheritedNotifier<T>).notifier
        if oldNotifier !== newNotifier {
            oldNotifier?.removeListener(self)
            newNotifier?.addListener(self, callback: handleUpdate)
        }
        super.update(newWidget)
    }

    public override func build() -> Widget {
        if _dirty {
            notifyClients(widget as! InheritedNotifier<T>)
        }
        return super.build()
    }

    public override func unmount() {
        (widget as! InheritedNotifier<T>).notifier?.removeListener(self)
        super.unmount()
    }

    public override func notifyClients(_ oldWidget: ProxyWidget) {
        super.notifyClients(oldWidget)
        _dirty = false
    }
}
