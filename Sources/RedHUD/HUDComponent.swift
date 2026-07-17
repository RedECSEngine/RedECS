import RedECS

/// Holds an entity's HUD view tree. The tree is *derived* data — game
/// reducers rebuild it from state whenever it should change — so it is
/// deliberately transient: it is skipped on encode, decodes to nil, and
/// equality is driven by `revision` (bump it when replacing `content` so
/// state diffing can observe the change; rendering itself always reads the
/// current tree).
public struct HUDComponent: GameComponent {
    public var entity: EntityId
    /// Draw order among HUDComponents; higher paints on top.
    public var zIndex: Int
    /// Content version for Equatable/state-diffing purposes.
    public var revision: Int
    public var content: AnyHUDView? = nil

    public init(entity: EntityId) {
        self.init(entity: entity, zIndex: 0, revision: 0, content: nil)
    }

    public init(
        entity: EntityId,
        zIndex: Int = 0,
        revision: Int = 0,
        content: AnyHUDView?
    ) {
        self.entity = entity
        self.zIndex = zIndex
        self.revision = revision
        self.content = content
    }

    public init(
        entity: EntityId,
        zIndex: Int = 0,
        revision: Int = 0,
        @HUDViewBuilder content: () -> [AnyHUDView]
    ) {
        let views = content()
        let root: AnyHUDView?
        if views.count == 1 {
            root = views[0]
        } else if views.isEmpty {
            root = nil
        } else {
            root = AnyHUDView(VStack { views })
        }
        self.init(entity: entity, zIndex: zIndex, revision: revision, content: root)
    }

    /// Replaces the view tree and bumps `revision`.
    public mutating func setContent(@HUDViewBuilder _ content: () -> [AnyHUDView]) {
        let views = content()
        if views.count == 1 {
            self.content = views[0]
        } else if views.isEmpty {
            self.content = nil
        } else {
            self.content = AnyHUDView(VStack { views })
        }
        revision += 1
    }

    enum CodingKeys: String, CodingKey {
        case entity
        case zIndex
        case revision
    }

    public static func == (lhs: HUDComponent, rhs: HUDComponent) -> Bool {
        lhs.entity == rhs.entity
            && lhs.zIndex == rhs.zIndex
            && lhs.revision == rhs.revision
    }
}
