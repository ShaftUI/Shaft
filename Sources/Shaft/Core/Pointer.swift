// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The kind of pointer device.
public enum PointerDeviceKind {
    /// A touch-based pointer device.
    ///
    /// The most common case is a touch screen.
    ///
    /// When the user is operating with a trackpad on iOS, clicking will also
    /// dispatch events with kind ``touch`` if
    /// `UIApplicationSupportsIndirectInputEvents` is not present in `Info.plist`
    /// or returns NO.
    ///
    /// See also:
    ///
    ///  * [UIApplicationSupportsIndirectInputEvents](https://developer.apple.com/documentation/bundleresources/information_property_list/uiapplicationsupportsindirectinputevents?language=objc).
    case touch

    /// A mouse-based pointer device.
    ///
    /// The most common case is a mouse on the desktop or Web.
    ///
    /// When the user is operating with a trackpad on iOS, moving the pointing
    /// cursor will also dispatch events with kind ``mouse``, and clicking will
    /// dispatch events with kind ``mouse`` if
    /// `UIApplicationSupportsIndirectInputEvents` is not present in `Info.plist`
    /// or returns NO.
    ///
    /// See also:
    ///
    ///  * [UIApplicationSupportsIndirectInputEvents](https://developer.apple.com/documentation/bundleresources/information_property_list/uiapplicationsupportsindirectinputevents?language=objc).
    case mouse

    /// A pointer device with a stylus.
    case stylus

    /// A pointer device with a stylus that has been inverted.
    case invertedStylus

    /// Gestures from a trackpad.
    ///
    /// A trackpad here is defined as a touch-based pointer device with an
    /// indirect surface (the user operates the screen by touching something that
    /// is not the screen).
    ///
    /// When the user makes zoom, pan, scroll or rotate gestures with a physical
    /// trackpad, supporting platforms dispatch events with kind ``trackpad``.
    ///
    /// Events with kind ``trackpad`` can only have a ``PointerChange`` of `add`,
    /// `remove`, and pan-zoom related values.
    ///
    /// Some platforms don't support (or don't fully support) trackpad
    /// gestures, and might convert trackpad gestures into fake pointer events
    /// that simulate dragging. These events typically have kind ``touch`` or
    /// ``mouse`` instead of ``trackpad``. This includes (but is not limited to) Web,
    /// and iOS when `UIApplicationSupportsIndirectInputEvents` isn't present in
    /// `Info.plist` or returns NO.
    ///
    /// Moving the pointing cursor or clicking with a trackpad typically triggers
    /// ``touch`` or ``mouse`` events, but never triggers ``trackpad`` events.
    ///
    /// See also:
    ///
    ///  * [UIApplicationSupportsIndirectInputEvents](https://developer.apple.com/documentation/bundleresources/information_property_list/uiapplicationsupportsindirectinputevents?language=objc).
    case trackpad
}

/// The kind of pointer signal event.
public enum PointerSignalKind {
    /// The event is not associated with a pointer signal.
    case none

    /// A pointer-generated scroll (e.g., mouse wheel or trackpad scroll).
    case scroll

    /// A pointer-generated scroll-inertia cancel.
    case scrollInertiaCancel

    /// A pointer-generated scale event (e.g. trackpad pinch).
    case scale
}

/// How the pointer has changed since the last report.
public enum PointerChange {
    /// The input from the pointer is no longer directed towards this receiver.
    case cancel

    /// The device has started tracking the pointer.
    ///
    /// For example, the pointer might be hovering above the device, having not yet
    /// made contact with the surface of the device.
    case add

    /// The device is no longer tracking the pointer.
    ///
    /// For example, the pointer might have drifted out of the device's hover
    /// detection range or might have been disconnected from the system entirely.
    case remove

    /// The pointer has moved with respect to the device while not in contact with
    /// the device.
    case hover

    /// The pointer has made contact with the device.
    case down

    /// The pointer has moved with respect to the device while in contact with the
    /// device.
    case move

    /// The pointer has stopped making contact with the device.
    case up

    /// A pan/zoom has started on this pointer.
    ///
    /// This type of event will always have kind ``PointerDeviceKind/trackpad``.
    case panZoomStart

    /// The pan/zoom on this pointer has updated.
    ///
    /// This type of event will always have kind ``PointerDeviceKind/trackpad``.
    case panZoomUpdate

    /// The pan/zoom on this pointer has ended.
    ///
    /// This type of event will always have kind ``PointerDeviceKind/trackpad``.
    case panZoomEnd

    /// No change has occurred since the last report.
    case none
}

public struct PointerButtons: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The number of buttons currently pressed.
    public var count: Int {
        return rawValue.nonzeroBitCount
    }

    /// Whether no buttons are currently pressed.
    public var isEmpty: Bool {
        return rawValue == 0
    }

    /// The bit of ``PointerEvent/buttons`` that corresponds to a cross-device
    /// behavior of "primary operation".
    ///
    /// More specifically, it includes:
    ///
    ///  * [kTouchContact]: The pointer contacts the touch screen.
    ///  * [kStylusContact]: The stylus contacts the screen.
    ///  * [kPrimaryMouseButton]: The primary mouse button.
    public static let primaryButton = Self(rawValue: 1 << 0)

    /// The bit of ``PointerEvent/buttons`` that corresponds to a cross-device
    /// behavior of "secondary operation".
    ///
    /// It is equivalent to:
    ///
    ///  * [kPrimaryStylusButton]: The stylus contacts the screen.
    ///  * [kSecondaryMouseButton]: The secondary mouse button.
    public static let secondaryButton = Self(rawValue: 1 << 1)

    /// The bit of ``PointerEvent/buttons`` that corresponds to the primary mouse
    /// button.
    ///
    /// The primary mouse button is typically the left button on the top of the
    /// mouse but can be reconfigured to be a different physical button.
    public static let primaryMouseButton = primaryButton

    /// The bit of ``PointerEvent/buttons`` that corresponds to the secondary
    /// mouse button.
    ///
    /// The secondary mouse button is typically the right button on the top of
    /// the mouse but can be reconfigured to be a different physical button.
    public static let secondaryMouseButton = secondaryButton

    /// The bit of ``PointerEvent/buttons`` that corresponds to when a stylus
    /// contacting the screen.
    public static let stylusContact = primaryButton

    /// The bit of ``PointerEvent/buttons`` that corresponds to the primary stylus
    /// button.
    ///
    /// The primary stylus button is typically the top of the stylus and near
    /// the tip but can be reconfigured to be a different physical button.
    public static let primaryStylusButton = secondaryButton

    /// The bit of ``PointerEvent/buttons`` that corresponds to a cross-device
    /// behavior of "tertiary operation".
    ///
    /// It is equivalent to:
    ///
    ///  * [kMiddleMouseButton]: The tertiary mouseButton.
    ///  * [kSecondaryStylusButton]: The secondary button on a stylus. This is
    ///    considered a tertiary button as the primary button of a stylus already
    ///    corresponds to a "secondary operation" (where stylus contact is the
    ///    primary operation).
    public static let tertiaryButton = Self(rawValue: 1 << 2)

    /// The bit of ``PointerEvent/buttons`` that corresponds to the middle mouse
    /// button.
    ///
    /// The middle mouse button is typically between the left and right buttons
    /// on the top of the mouse but can be reconfigured to be a different
    /// physical button.
    public static let middleMouseButton = tertiaryButton

    /// The bit of ``PointerEvent/buttons`` that corresponds to the secondary
    /// stylus button.
    ///
    /// The secondary stylus button is typically on the end of the stylus
    /// farthest from the tip but can be reconfigured to be a different physical
    /// button.
    public static let secondaryStylusButton = tertiaryButton

    /// The bit of ``PointerEvent/buttons`` that corresponds to the back mouse
    /// button.
    ///
    /// The back mouse button is typically on the left side of the mouse but can
    /// be reconfigured to be a different physical button.
    public static let backMouseButton = Self(rawValue: 1 << 3)

    /// The bit of ``PointerEvent/buttons`` that corresponds to the forward mouse
    /// button.
    ///
    /// The forward mouse button is typically on the right side of the mouse but
    /// can be reconfigured to be a different physical button.
    public static let forwardMouseButton = Self(rawValue: 1 << 4)

    /// The bit of ``PointerEvent/buttons`` that corresponds to the pointer
    /// contacting a touch screen.
    public static let touchContact = primaryButton
}

/// Information about the state of a pointer.
public struct PointerData {
    public init(
        viewId: Int,
        timeStamp: Duration,
        change: PointerChange = .none,
        kind: PointerDeviceKind,
        signalKind: PointerSignalKind = .none,
        device: Int,
        pointerIdentifier: Int,
        physicalX: Int = 0,
        physicalY: Int = 0,
        physicalDeltaX: Int = 0,
        physicalDeltaY: Int = 0,
        buttons: PointerButtons,
        synthesized: Bool = false,
        scrollDeltaX: Double = 0.0,
        scrollDeltaY: Double = 0.0
    ) {
        self.viewId = viewId
        self.timeStamp = timeStamp
        self.change = change
        self.kind = kind
        self.signalKind = signalKind
        self.device = device
        self.pointerIdentifier = pointerIdentifier
        self.physicalX = physicalX
        self.physicalY = physicalY
        self.physicalDeltaX = physicalDeltaX
        self.physicalDeltaY = physicalDeltaY
        self.buttons = buttons
        self.synthesized = synthesized
        self.scrollDeltaX = scrollDeltaX
        self.scrollDeltaY = scrollDeltaY
    }

    /// The ID of the ``NativeView`` this ``PointerEvent`` originated from.
    public var viewId: Int

    /// Time of event dispatch, relative to an arbitrary timeline.
    public var timeStamp: Duration

    /// How the pointer has changed since the last report.
    public var change: PointerChange = .none

    /// The kind of input device for which the event was generated.
    public var kind: PointerDeviceKind

    /// The kind of signal for a pointer signal event.
    public var signalKind: PointerSignalKind = .none

    /// Unique identifier for the pointing device, reused across interactions.
    public var device = 0

    /// Unique identifier for the pointer.
    ///
    /// This field changes for each new pointer down event. Framework uses this
    /// identifier to determine hit test result.
    public var pointerIdentifier: Int

    /// X coordinate of the position of the pointer, in physical pixels in the
    /// global coordinate space.
    public var physicalX: Int = 0

    /// Y coordinate of the position of the pointer, in physical pixels in the
    /// global coordinate space.
    public var physicalY: Int = 0

    /// The distance of pointer movement on X coordinate in physical pixels.
    public var physicalDeltaX: Int = 0

    /// The distance of pointer movement on Y coordinate in physical pixels.
    public var physicalDeltaY: Int = 0

    /// Bit field using the *Button constants (primaryMouseButton,
    /// secondaryStylusButton, etc). For example, if this has the value 6 and the
    /// ``kind`` is ``PointerDeviceKind/invertedStylus``, then this indicates an
    /// upside-down stylus with both its primary and secondary buttons pressed.
    public var buttons: PointerButtons

    /// Set if this pointer data was synthesized by pointer data packet converter.
    /// pointer data packet converter will synthesize additional pointer datas if
    /// the input sequence of pointer data is illegal.
    ///
    /// For example, a down pointer data will be synthesized if the converter
    /// receives a move pointer data while the pointer is not previously down.
    public var synthesized: Bool = false

    /// For events with signalKind of PointerSignalKind.scroll:
    ///
    /// The amount to scroll in the x direction, in physical pixels.
    public var scrollDeltaX = 0.0

    /// For events with signalKind of PointerSignalKind.scroll:
    ///
    /// The amount to scroll in the y direction, in physical pixels.
    public var scrollDeltaY = 0.0
}
