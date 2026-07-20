extension Comparable {
    /// This value confined to `range` (returns the nearest bound when outside).
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
