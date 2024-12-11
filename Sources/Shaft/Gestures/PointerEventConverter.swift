// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Signature for a callback that returns the device pixel ratio of a
/// [FlutterView] identified by the provided `viewId`.
///
/// Returns null if no view with the provided ID exists.
///
/// Used by [PointerEventConverter.expand].
typealias DevicePixelRatioGetter = (Int) -> Double?

// Add `kPrimaryButton` to [buttons] when a pointer of certain devices is down.
//
// TODO(tongmu): This patch is supposed to be done by embedders. Patching it
// in framework is a workaround before [PointerEventConverter] is moved to embedders.
/// Converts from engine pointer data to framework pointer events.
private func _synthesiseDownButtons(_ buttons: PointerButtons, _ kind: PointerDeviceKind)
    -> PointerButtons
{
    switch kind {
    case .mouse,
        .trackpad:
        return buttons
    case .touch,
        .stylus,
        .invertedStylus:
        return buttons == .init() ? .primaryButton : buttons
    }
}
///
/// This takes [PointerDataPacket] objects, as received from the backend, and
/// converts them to [PointerEvent] objects.
final class PointerEventConverter {
    static func convert(_ data: PointerData, devicePixelRatioForView: DevicePixelRatioGetter)
        -> PointerEvent?
    {
        guard let devicePixelRatio = devicePixelRatioForView(data.viewId) else {
            return nil
        }

        let position: Offset =
            Offset(
                Float(data.physicalX),
                Float(data.physicalY)
            ) / Float(devicePixelRatio)
        let delta =
            Offset(
                Float(data.physicalDeltaX),
                Float(data.physicalDeltaY)
            ) / Float(devicePixelRatio)
        // let radiusMinor = toLogicalPixels(data.radiusMinor, devicePixelRatio)
        // let radiusMajor = toLogicalPixels(data.radiusMajor, devicePixelRatio)
        // let radiusMin = toLogicalPixels(data.radiusMin, devicePixelRatio)
        // let radiusMax = toLogicalPixels(data.radiusMax, devicePixelRatio)

        switch data.signalKind {
        case .none:
            switch data.change {
            case .add:
                return PointerAddedEvent(
                    viewId: data.viewId,
                    timeStamp: data.timeStamp,
                    kind: data.kind,
                    device: data.device,
                    position: position
                )
            case .hover:
                return PointerHoverEvent(
                    viewId: data.viewId,
                    timeStamp: data.timeStamp,
                    pointer: data.pointerIdentifier,
                    kind: data.kind,
                    device: data.device,
                    position: position,
                    delta: delta,
                    buttons: data.buttons
                )
            case .down:
                return PointerDownEvent(
                    viewId: data.viewId,
                    timeStamp: data.timeStamp,
                    pointer: data.pointerIdentifier,
                    kind: data.kind,
                    device: data.device,
                    position: position,
                    delta: delta,
                    buttons: _synthesiseDownButtons(data.buttons, data.kind)
                )
            case .move:
                return PointerMoveEvent(
                    viewId: data.viewId,
                    timeStamp: data.timeStamp,
                    pointer: data.pointerIdentifier,
                    kind: data.kind,
                    device: data.device,
                    position: position,
                    delta: delta,
                    buttons: _synthesiseDownButtons(data.buttons, data.kind)
                )
            case .up:
                return PointerUpEvent(
                    viewId: data.viewId,
                    timeStamp: data.timeStamp,
                    pointer: data.pointerIdentifier,
                    kind: data.kind,
                    device: data.device,
                    position: position,
                    buttons: data.buttons
                )
            case .cancel:
                return PointerCancelEvent(
                    viewId: data.viewId,
                    timeStamp: data.timeStamp,
                    pointer: data.pointerIdentifier,
                    kind: data.kind,
                    device: data.device,
                    position: position,
                    buttons: data.buttons
                )
            case .remove:
                return PointerRemovedEvent(
                    viewId: data.viewId,
                    timeStamp: data.timeStamp,
                    pointer: data.pointerIdentifier,
                    kind: data.kind,
                    device: data.device,
                    position: position
                )
            case .panZoomEnd, .panZoomStart, .panZoomUpdate, .none:
                fatalError("\(data.change) not implemented")
            }
        case .scroll:
            let scrollDelta =
                Offset(
                    Float(data.scrollDeltaX),
                    Float(data.scrollDeltaY)
                ) / Float(devicePixelRatio)
            return PointerScrollEvent(
                viewId: data.viewId,
                timeStamp: data.timeStamp,
                kind: data.kind,
                device: data.device,
                position: position,
                scrollDelta: scrollDelta
            )
        case .scrollInertiaCancel:
            fatalError("scrollInertiaCancel is not implemented")
        case .scale:
            fatalError("scale is not implemented")
        }
    }

    //   static private toLogicalPixels(_ physicalPixels: Double, _ devicePixelRatio: Double) -> Double {
    //     return physicalPixels / devicePixelRatio;
    //   }

}
