public struct InputSourceTransitionTracker: Sendable {
    public private(set) var lastSource: InputSource?

    public init() {}

    @discardableResult
    public mutating func observe(_ source: InputSource) -> Bool {
        guard lastSource != source else {
            return false
        }
        lastSource = source
        return true
    }

    public mutating func reset(to source: InputSource? = nil) {
        lastSource = source
    }
}
