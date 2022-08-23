import RedECS
import Geometry

public enum HUDAction<Formatter: HUDElementFormattable>: Equatable & Codable {
    case inputDown(Point)
    case inputUp(Point)
    case onHUDElementInputDown(Formatter.ElementId)
}

public protocol HUDRenderingCapable: GameState where Formatter.State == Self {
    associatedtype Formatter: HUDElementFormattable
    var hud: [EntityId: HUDComponent<Formatter>] { get set }
}

public protocol HUDElementFormattable: Equatable & Codable {
    associatedtype ElementId: Hashable & Codable
    associatedtype State: GameState
    func format(_ elementId: ElementId, _ state: State) -> String
}

public struct HUDComponent<Formatter: HUDElementFormattable>: GameComponent {
    public var entity: EntityId
    public var children: [HUDElement<Formatter>]
    
    public init (
        entity: EntityId,
        children: [HUDElement<Formatter>]
    ) {
        self.entity =  entity
        self.children = children
    }
}

public struct HUDElement<Formatter: HUDElementFormattable>: Equatable & Codable {
    public var id: Formatter.ElementId
    public var position: Point
    public var type: HUDElementType<Formatter>
    
    public init(
        id: Formatter.ElementId,
        position: Point,
        type: HUDElementType<Formatter>
    ) {
        self.id = id
        self.position = position
        self.type = type
    }
}

public indirect enum HUDElementType<Formatter: HUDElementFormattable>: Equatable & Codable {
    case label(HUDLabel<Formatter>)
    case button(HUDButton<Formatter>)
}

public struct HUDLabel<Formatter: HUDElementFormattable>: Equatable & Codable {
    public var size: Double
    public var strategy: HUDLabelStrategy<Formatter>
    
    public init(
        size: Double,
        strategy: HUDLabelStrategy<Formatter>
    ) {
        self.size = size
        self.strategy = strategy
    }
}

public enum HUDLabelStrategy<Formatter: HUDElementFormattable>: Equatable & Codable {
    case fixed(String)
    case dynamic(Formatter)
}

public struct HUDButton<Formatter: HUDElementFormattable>: Equatable & Codable {
    public var shape: Shape
    public var fillColor: Color
    public var labelStrategy: HUDLabelStrategy<Formatter>?
    
    public init(
        shape: Shape,
        fillColor: Color,
        labelStrategy: HUDLabelStrategy<Formatter>? = nil
    ) {
        self.shape = shape
        self.fillColor = fillColor
        self.labelStrategy = labelStrategy
    }
}
