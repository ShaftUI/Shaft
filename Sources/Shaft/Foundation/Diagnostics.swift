// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

public protocol Diagnosticable {
    func toStringShort() -> String

    func debugFillProperties() -> [String: String]
}

extension Diagnosticable {
    public func toStringShort() -> String {
        return describeIdentity(self)
    }

    public func debugFillProperties() -> [String: String] {
        let mirror = Mirror(reflecting: self)
        var properties = [String: String]()
        for child in mirror.children {
            if let label = child.label {
                properties[label] = "\(child.value)"
            }
        }
        return properties
    }
}

public func describeIdentity(_ object: Any) -> String {
    let mirror = Mirror(reflecting: object)
    let address = Unmanaged.passUnretained(object as AnyObject).toOpaque()
    return "\(mirror.subjectType)#\(address)"
}

/// Returns the runtime type of the object without the module prefix.
public func objectRuntimeType(_ object: Any) -> String {
    let mirror = Mirror(reflecting: object)
    return "\(mirror.subjectType)"
}

public protocol DiagnosticableTree: Diagnosticable {
    func debugDescribeChildren() -> [DiagnosticableTree]
}

extension DiagnosticableTree {
    // public func debugDescribeChildren() -> [DiagnosticableTree] {
    //     return []
    // }

    public func toStringDeep() -> String {
        var result = ""
        result.append(toStringShort() + "\n")

        // let properties = debugFillProperties()
        let children = debugDescribeChildren()
        for (index, child) in children.enumerated() {
            let isLastChild = index == children.count - 1

            let subtree = child.toStringDeep()
            let lines = subtree.split(separator: "\n")
            for (index, line) in lines.enumerated() {
                if line.isEmpty {
                    continue
                }

                let isFirstLine = index == 0
                let linePrefix =
                    isLastChild
                    ? (isFirstLine ? "└─" : "  ")
                    : (isFirstLine ? "├─" : "│ ")

                result.append("\(linePrefix)\(line)\n")
            }
        }

        return result
    }
}
