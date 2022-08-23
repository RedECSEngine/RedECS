import RedECS

public struct HUDRenderingContext<
    Formatter: HUDElementFormattable,
    Action: Equatable & Codable
>: GameState {
    public var entities: EntityRepository = .init()
    public var hud: [EntityId: HUDComponent<Formatter>]
    
    public init(
        entities: EntityRepository = .init(),
        hud: [EntityId: HUDComponent<Formatter>]
    ) {
        self.entities = entities
        self.hud = hud
    }
}
