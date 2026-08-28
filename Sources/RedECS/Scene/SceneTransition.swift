public struct SceneTransition: Equatable, Codable {
    public enum Phasing: String, Equatable, Codable {
        case sequential
        case crossover
    }

    public var duration: Double
    public var phasing: Phasing
    public var outEffect: ShaderEffect.TimeBased?
    public var inEffect: ShaderEffect.TimeBased?

    public init(
        duration: Double,
        phasing: Phasing = .sequential,
        outEffect: ShaderEffect.TimeBased? = nil,
        inEffect: ShaderEffect.TimeBased? = nil
    ) {
        self.duration = duration
        self.phasing = phasing
        self.outEffect = outEffect
        self.inEffect = inEffect
    }
}

public extension SceneTransition {
    static func fade(duration: Double) -> SceneTransition {
        SceneTransition(duration: duration, phasing: .sequential, outEffect: .fade, inEffect: .fade)
    }

    static func crossFade(duration: Double) -> SceneTransition {
        SceneTransition(duration: duration, phasing: .crossover, outEffect: .fade)
    }

    static func dissolve(duration: Double) -> SceneTransition {
        SceneTransition(duration: duration, phasing: .crossover, outEffect: .turnOff)
    }

    static func blindsRows(duration: Double) -> SceneTransition {
        SceneTransition(duration: duration, phasing: .sequential, outEffect: .splitRows, inEffect: .splitRows)
    }

    static func blindsCols(duration: Double) -> SceneTransition {
        SceneTransition(duration: duration, phasing: .sequential, outEffect: .splitCols, inEffect: .splitCols)
    }

    static func shuffle(duration: Double) -> SceneTransition {
        SceneTransition(duration: duration, phasing: .sequential, outEffect: .shuffle, inEffect: .shuffle)
    }
}
