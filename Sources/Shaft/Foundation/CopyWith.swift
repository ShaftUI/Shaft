public protocol CopyWith {}

extension CopyWith where Self: Any {
    /// Returns a copy of the instance with the block executed.
    @inlinable
    public func with(_ block: (inout Self) throws -> Void) rethrows -> Self {
        var copy = self
        try block(&copy)
        return copy
    }
}
