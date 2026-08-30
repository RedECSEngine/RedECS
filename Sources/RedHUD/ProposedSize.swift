import Geometry

/// A size proposal from parent to child; a nil dimension means the parent
/// makes no proposal along that axis and the child should use its ideal size.
public struct ProposedSize: Equatable {
    public var width: Double?
    public var height: Double?

    public init(width: Double? = nil, height: Double? = nil) {
        self.width = width
        self.height = height
    }

    public init(_ size: Size) {
        self.init(width: size.width, height: size.height)
    }

    public func orDefault(_ fallback: Size = Size(width: 100, height: 100)) -> Size {
        Size(width: width ?? fallback.width, height: height ?? fallback.height)
    }
}
