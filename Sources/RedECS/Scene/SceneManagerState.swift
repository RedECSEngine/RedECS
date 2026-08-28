public struct SceneManagerState: Equatable, Codable {
    public var activeSceneId: EntityId?
    public var transition: ActiveSceneTransition?

    public init(
        activeSceneId: EntityId? = nil,
        transition: ActiveSceneTransition? = nil
    ) {
        self.activeSceneId = activeSceneId
        self.transition = transition
    }
}

public struct ActiveSceneTransition: Equatable, Codable {
    public var outgoingSceneId: EntityId?
    public var incomingSceneId: EntityId?
    public var transition: SceneTransition
    public var elapsed: Double

    public init(
        outgoingSceneId: EntityId?,
        incomingSceneId: EntityId?,
        transition: SceneTransition,
        elapsed: Double = 0
    ) {
        self.outgoingSceneId = outgoingSceneId
        self.incomingSceneId = incomingSceneId
        self.transition = transition
        self.elapsed = elapsed
    }

    public var isComplete: Bool {
        elapsed >= transition.duration
    }

    public var drawsOutgoing: Bool {
        switch transition.phasing {
        case .sequential: return progress < 0.5
        case .crossover: return true
        }
    }

    public var drawsIncoming: Bool {
        switch transition.phasing {
        case .sequential: return progress >= 0.5
        case .crossover: return true
        }
    }

    public func outgoingShader() -> ShaderEffect? {
        guard let effect = transition.outEffect else { return nil }
        switch transition.phasing {
        case .sequential: return effect.effect(at: clampedTime(progress * 2))
        case .crossover: return effect.effect(at: clampedTime(progress))
        }
    }

    public func incomingShader() -> ShaderEffect? {
        guard let effect = transition.inEffect else { return nil }
        switch transition.phasing {
        case .sequential: return effect.effect(at: clampedTime(1 - (progress - 0.5) * 2))
        case .crossover: return effect.effect(at: clampedTime(1 - progress))
        }
    }

    var progress: Double {
        guard transition.duration > 0 else { return 0.999 }
        return clampedTime(elapsed / transition.duration)
    }

    private func clampedTime(_ time: Double) -> Double {
        min(max(time, 0), 0.999)
    }
}
