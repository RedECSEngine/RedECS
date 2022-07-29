public struct TiledLayer<TOT: TiledObjectType>: Codable, Equatable {
    public var id: Int
    public var name: String
    public var type: TiledLayerType
    
    public var data: [Int]?
    
    public var opacity: Double
    public var visible: Bool

    public var width: Int
    public var height: Int
    public var x: Double
    public var y: Double
    
    public var objects: [TiledObject<TOT>]?
}
