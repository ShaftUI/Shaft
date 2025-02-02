/// Asserts that the given context has a [MediaQuery] ancestor.
///
/// Used by various widgets to make sure that they are only used in an
/// appropriate context.
///
/// To invoke this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasMediaQuery(context));
/// ```
///
/// Always place this before any early returns, so that the invariant is checked
/// in all cases. This prevents bugs from hiding until a particular codepath is
/// hit.
///
/// Does nothing if asserts are disabled. Always returns true.
func debugCheckHasMediaQuery(_ context: BuildContext) -> Bool {
    assert {
        if !(context.widget is MediaQuery)
            && context.getElementForInheritedWidgetOfExactType(MediaQuery.self) == nil
        {
            preconditionFailure(
                """
                No MediaQuery widget ancestor found.
                \(String(describing: context.widget)) widgets require a MediaQuery widget ancestor.
                The specific widget that could not find a MediaQuery ancestor was
                No MediaQuery ancestor could be found starting from the context that was passed to MediaQuery.of(). This can happen because the context used is not a descendant of a View widget, which introduces a MediaQuery.
                """
            )
        }
        return true
    }
    return true
}
