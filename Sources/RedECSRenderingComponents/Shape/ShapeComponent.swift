import RedECS
import Geometry

public struct ShapeComponent: GameComponent {
    public let entity: EntityId
    public var shape: Shape {
        didSet {
            if oldValue != shape {
                needsRedraw = true
            }
        }
    }
    public var fillColor: Color {
        didSet {
            if oldValue != fillColor {
                needsRedraw = true
            }
        }
    }
    public var needsRedraw: Bool = true
    
    public init(
        entity: EntityId,
        shape: Shape,
        fillColor: Color = .white
    ) {
        self.entity = entity
        self.shape = shape
        self.fillColor = fillColor
    }
}
