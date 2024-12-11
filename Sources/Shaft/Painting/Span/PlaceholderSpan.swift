// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An immutable placeholder that is embedded inline within text.
///
/// [PlaceholderSpan] represents a placeholder that acts as a stand-in for other
/// content. A [PlaceholderSpan] by itself does not contain useful information
/// to change a [TextSpan]. [WidgetSpan] from the widgets library extends
/// [PlaceholderSpan] and may be used instead to specify a widget as the contents
/// of the placeholder.
///
/// Flutter widgets such as [TextField], [Text] and [RichText] do not recognize
/// [PlaceholderSpan] subclasses other than [WidgetSpan]. **Consider
/// implementing the [WidgetSpan] interface instead of the [Placeholder]
/// interface.**
// public class PlaceholderSpan: InlineSpan {
//     public var style: TextStyle?

//     public func build(
//         builder: ParagraphBuilder,
//         textScaler: any TextScaler,
//         dimensions: [PlaceholderDimensions]
//     ) {

//     }

//     public func compareTo(_ other: InlineSpan) -> RenderComparison {
//         return .identical
//     }

//     /// The unicode character to represent a placeholder.
//     static let placeholderCodeUnit: Int = 0xFFFC

//     public func getPlainText(
//         buffer: StringBuilder,
//         includeSemanticsLabels: Bool,
//         includePlaceholders: Bool
//     ) {
//         if includePlaceholders {
//             buffer.append(String(UnicodeScalar(Self.placeholderCodeUnit)!))
//         }
//     }
// }

public protocol PlaceholderSpan: InlineSpan {
}
