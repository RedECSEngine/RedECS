import SpriteKit

public extension SKTileMapNode {
    func fill(tiledData: [Int]) {
        let tileGroupDict = tileSet
            .tileGroups
            .reduce(into: [String: SKTileGroup](), { $0[$1.name ?? ""] = $1 })
        for (i, tileValue) in tiledData.enumerated() {
            let row = numberOfRows - (i / numberOfColumns) - 1
            let col = i % numberOfColumns
            let key = (tileSet.name.map({ "\($0)-" }) ?? "") + "\(tileValue)"
            setTileGroup(
                tileGroupDict[key],
                forColumn: col,
                row: row
            )
        }
    }
}
