// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

public struct DisplayList {
    var buffer: [DisplayListOp]

    /// Replay recorded operations to the given receiver.
    public func dispatch(to receiver: DlOpReceiver) {
        for op in buffer {
            switch op {
            case let .drawRect(rect, paint):
                receiver.drawRect(rect, paint)
            case let .drawLine(p0, p1, paint):
                receiver.drawLine(p0, p1, paint)
            case let .drawDisplayList(displayList):
                receiver.drawDisplayList(displayList)
            case let .drawParagraph(paragraph, offset):
                receiver.drawParagraph(paragraph, offset)
            case let .drawTextBlob(textBlob, offset, paint):
                receiver.drawTextBlob(textBlob, offset, paint)
            case let .transform(transform):
                receiver.transform(transform)
            case let .drawRRect(rrect, paint):
                receiver.drawRRect(rrect, paint)
            case let .drawDRRect(outer, inner, paint):
                receiver.drawDRRect(outer, inner, paint)
            case let .drawCircle(center, radius, paint):
                receiver.drawCircle(center, radius, paint)
            case let .drawPath(path, paint):
                receiver.drawPath(path, paint)
            case let .drawImage(image, offset, paint):
                receiver.drawImage(image, offset, paint)
            case let .drawImageRect(image, src, dst, paint):
                receiver.drawImageRect(image, src, dst, paint)
            case let .drawImageNine(image, center, dst, paint):
                receiver.drawImageNine(image, center, dst, paint)
            case let .clipRect(rect: rect, clipOp: clipOp, doAntiAlias: doAntiAlias):
                receiver.clipRect(rect, clipOp, doAntiAlias)
            case let .clipRRect(rrect, doAntiAlias):
                receiver.clipRRect(rrect, doAntiAlias)
            case let .translate(dx, dy):
                receiver.translate(dx, dy)
            case let .scale(sx, sy):
                receiver.scale(sx, sy)
            case .save:
                receiver.save()
            case let .saveLayer(bounds, paint):
                receiver.saveLayer(bounds, paint: paint)
            case .restore:
                receiver.restore()
            case let .clear(color):
                receiver.clear(color: color)
            }
        }
    }

    // private func peek<T>(_: T.Type, offset: Int) -> T {
    //     storage.withUnsafeBytes { $0.load(fromByteOffset: offset, as: T.self) }
    // }

    // private func read<T>(_: T.Type, offset: inout Int) -> T {
    //     let value = peek(T.self, offset: offset)
    //     offset += MemoryLayout<T>.size
    //     return value
    // }
}
