/// An easing curve mapping normalized progress (0...1) to eased progress.
/// Shared vocabulary for world-side operations (`TimingOperation`) and HUD
/// animation transactions.
public enum TimingFunction: Equatable, Codable, Sendable {
    case linear
    case easeIn
    case easeOut
    case easeInOut

    public func callAsFunction(_ t: Double) -> Double {
        switch self {
        case .linear:
            return t
        case .easeIn:
            return t * t
        case .easeOut:
            return flip(square(flip(t)))
        case .easeInOut:
            // lerp(easeIn, easeOut, t) — algebraically smoothstep (3t² − 2t³)
            let a = t * t
            let b = flip(square(flip(t)))
            return ((b - a) * t) + a
        }
    }

    private func flip(_ t: Double) -> Double { 1 - t }
    private func square(_ t: Double) -> Double { t * t }
}
