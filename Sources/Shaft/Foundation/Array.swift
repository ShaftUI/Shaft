extension Array {
    /// Returns a new array containing the elements of the array, interspersed
    /// with the specified separator.
    public func separated(by separator: Element) -> [Element] {
        var result: [Element] = []
        for (index, element) in self.enumerated() {
            if index > 0 {
                result.append(separator)
            }
            result.append(element)
        }
        return result
    }
}
