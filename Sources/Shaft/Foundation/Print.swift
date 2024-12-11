// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import Rainbow

public func mark(
    _ message: Any...,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    let message = message.map { "\($0)" }.joined(separator: " ")
    // time in 19:00:00.000 format
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    let time = formatter.string(from: Date())
    // let filename = file.split(separator: "/").last ?? ""
    let relativePath = file.replacingOccurrences(
        of: FileManager.default.currentDirectoryPath + "/Sources/",
        with: ""
    )
    let fileinfo = "[\(relativePath):\(line)]"
    print("\("INFO".green) \(time.cyan) \(fileinfo.magenta) \(function.yellow): \(message)")
}

// private func _toString<T>(_ value: T) -> String {
//     if let value = value as? CustomStringConvertible {
//         return value.description
//     } else {
//         return "\(value)"
//     }
// }
