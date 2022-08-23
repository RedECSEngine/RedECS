public struct TiledObject: Codable, Equatable {
    public var id: Int
    public var name: String
    public var rotation: Double
    public var text: TiledText?
       
    public var type: String?
    public var visible: Bool

    public var width: Double
    public var height: Double
    public var x: Double
    public var y: Double
}
