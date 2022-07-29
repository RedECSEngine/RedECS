public struct Tile<TTC: TiledTileClass>: Codable, Equatable {
    public var id: Int
    public var `class`: TTC
}
