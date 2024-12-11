// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Called on each span as [InlineSpan.visitChildren] walks the [InlineSpan] tree.
///
/// Returns true when the walk should continue, and false to stop visiting further
/// [InlineSpan]s.
public typealias InlineSpanVisitor = (InlineSpan) -> Bool

/// An immutable span of inline content which forms part of a paragraph.
///
///  * The subclass [TextSpan] specifies text and may contain child [InlineSpan]s.
///  * The subclass [PlaceholderSpan] represents a placeholder that may be
///    filled with non-text content. [PlaceholderSpan] itself defines a
///    [ui.PlaceholderAlignment] and a [TextBaseline]. To be useful,
///    [PlaceholderSpan] must be extended to define content. An instance of
///    this is the [WidgetSpan] class in the widgets library.
///  * The subclass [WidgetSpan] specifies embedded inline widgets.
public protocol InlineSpan: AnyObject {
    /// The [TextStyle] to apply to this span.
    ///
    /// The [style] is also applied to any child spans when this is an instance
    /// of [TextSpan].
    var style: TextStyle? { get }

    /// Apply the properties of this object to the given [ParagraphBuilder], from
    /// which a [Paragraph] can be obtained.
    ///
    /// The `textScaler` parameter specifies a [TextScaler] that the text and
    /// placeholders will be scaled by. The scaling is performed before layout,
    /// so the text will be laid out with the scaled glyphs and placeholders.
    ///
    /// The `dimensions` parameter specifies the sizes of the placeholders.
    /// Each [PlaceholderSpan] must be paired with a [PlaceholderDimensions]
    /// in the same order as defined in the [InlineSpan] tree.
    ///
    /// [Paragraph] objects can be drawn on [Canvas] objects.
    func build(
        builder: ParagraphBuilder,
        textScaler: any TextScaler,
        dimensions: [PlaceholderDimensions]
    )

    /// Walks this [InlineSpan] and any descendants in pre-order and calls `visitor`
    /// for each span that has content.
    ///
    /// When `visitor` returns true, the walk will continue. When `visitor` returns
    /// false, then the walk will end.
    ///
    /// See also:
    ///
    ///  * [visitDirectChildren], which preforms `build`-order traversal on the
    ///    immediate children of this [InlineSpan], regardless of whether they
    ///    have content.
    func visitChildren(_ visitor: InlineSpanVisitor) -> Bool

    /// Calls `visitor` for each immediate child of this [InlineSpan].
    ///
    /// The immediate children are visited in the same order they are added to
    /// a [ui.ParagraphBuilder] in the [build] method, which is also the logical
    /// order of the child [InlineSpan]s in the text.
    ///
    /// The traversal stops when all immediate children are visited, or when the
    /// `visitor` callback returns `false` on an immediate child. This method
    /// itself returns a `bool` indicating whether the visitor callback returned
    /// `true` on all immediate children.
    ///
    /// See also:
    ///
    ///  * [visitChildren], which performs preorder traversal on this [InlineSpan]
    ///    if it has content, and all its descendants with content.
    func visitDirectChildren(_ visitor: InlineSpanVisitor) -> Bool

    /// Describe the difference between this span and another, in terms of
    /// how much damage it will make to the rendering. The comparison is deep.
    ///
    /// Comparing [InlineSpan] objects of different types, for example, comparing
    /// a [TextSpan] to a [WidgetSpan], always results in [RenderComparison.layout].
    func compareTo(_ other: InlineSpan) -> RenderComparison

    /// Walks the [InlineSpan] tree and writes the plain text representation to
    /// `buffer`.
    ///
    /// This method should not be directly called. Use [toPlainText] instead.
    ///
    /// Styles are not honored in this process. If `includeSemanticsLabels` is
    /// true, then the text returned will include the [TextSpan.semanticsLabel]s
    /// instead of the text contents for [TextSpan]s.
    ///
    /// When `includePlaceholders` is true, [PlaceholderSpan]s in the tree will
    /// be represented as a 0xFFFC 'object replacement character'.
    ///
    /// The plain-text representation of this [InlineSpan] is written into the
    /// `buffer`. This method will then recursively call [computeToPlainText] on
    /// its children [InlineSpan]s if available.
    func getPlainText(
        buffer: StringBuilder,
        includeSemanticsLabels: Bool,
        includePlaceholders: Bool
    )

    /// Performs the check at each [InlineSpan] for if the `index` falls within the range
    /// of the span and returns the corresponding code unit. Returns nil otherwise.
    ///
    /// The `offset` parameter tracks the current index offset in the text buffer formed
    /// if the contents of the [InlineSpan] tree were concatenated together starting
    /// from the root [InlineSpan].
    ///
    /// This method should not be directly called. Use [codeUnitAt] instead.
    func codeUnitAtVisitor(_ index: TextIndex, _ offset: inout TextIndex) -> Int?
}

extension InlineSpan {
    /// Flattens the [InlineSpan] tree into a single string.
    ///
    /// Styles are not honored in this process. If `includeSemanticsLabels` is
    /// true, then the text returned will include the [TextSpan.semanticsLabel]s
    /// instead of the text contents for [TextSpan]s.
    ///
    /// When `includePlaceholders` is true, [PlaceholderSpan]s in the tree will
    /// be represented as a 0xFFFC 'object replacement character'.
    public func toPlainText(
        includeSemanticsLabels: Bool = true,
        includePlaceholders: Bool = true
    ) -> String {
        let buffer = StringBuilder()
        getPlainText(
            buffer: buffer,
            includeSemanticsLabels: includeSemanticsLabels,
            includePlaceholders: includePlaceholders
        )
        return buffer.build()
    }

    /// Returns the UTF-16 code unit at the given `index` in the flattened string.
    ///
    /// This only accounts for the [TextSpan.text] values and ignores [PlaceholderSpan]s.
    ///
    /// Returns nil if the `index` is out of bounds.
    func codeUnitAt(_ index: TextIndex) -> Int? {
        if index < .zero {
            return nil
        }
        var offset = TextIndex.zero
        var result: Int?
        _ = visitChildren { span in
            result = span.codeUnitAtVisitor(index, &offset)
            return result == nil
        }
        return result
    }

}
