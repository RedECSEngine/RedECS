public struct TiledLayer: Codable, Equatable {
    public var id: Int
    public var name: String
    public var type: TiledLayerType?
    
    public var data: [Int]?
    
    public var opacity: Double
    public var visible: Bool

    public var width: Int?
    public var height: Int?
    public var x: Double
    public var y: Double
    
    public var objects: [TiledObject]?

    public init(
        id: Int,
        name: String,
        type: TiledLayerType?,
        data: [Int]? = nil,
        opacity: Double = 1,
        visible: Bool = true,
        width: Int? = nil,
        height: Int? = nil,
        x: Double = 0,
        y: Double = 0,
        objects: [TiledObject]? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.data = data
        self.opacity = opacity
        self.visible = visible
        self.width = width
        self.height = height
        self.x = x
        self.y = y
        self.objects = objects
    }
}

public extension TiledLayer {
    
    func tileDataAt(column: Int, row: Int, flipY: Bool = false) -> Int? {
        guard let data = data, let totalCols = width, let totalRows = width else { return nil }
        let c = column
        var r = row
        if flipY {
            r = (totalRows - 1) - row
        }
        let flatIndex = (totalCols * r) + c
        return data[flatIndex]
    }
    
    func flipYDataIterator() -> AnyIterator<Int> {
        guard let data = data,
                let totalCols = width,
                let totalRows = height else {
            return AnyIterator { nil }
        }
        var row = 0
        var col = 0
        return AnyIterator {
            if row == totalRows {
                return nil
            }
            
            let flippedYRow = (totalRows - 1) - row
            let flatIndex = (totalCols * flippedYRow) + col
            
            let value = data[flatIndex]
            
            col += 1
            if col == totalCols {
                col = 0
                row += 1
            }
            
            return value
        }
    }
}
