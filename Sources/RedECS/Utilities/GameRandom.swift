public struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

public enum GameRandom {
    nonisolated(unsafe) private static var generator = SeededRandomNumberGenerator(
        seed: .random(in: .min ... .max)
    )

    public static func seed(_ seed: UInt64) {
        generator = SeededRandomNumberGenerator(seed: seed)
    }

    public static func next() -> UInt64 {
        generator.next()
    }

    public static func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &generator)
    }

    public static func int(in range: Range<Int>) -> Int {
        Int.random(in: range, using: &generator)
    }

    public static func double(in range: Range<Double>) -> Double {
        Double.random(in: range, using: &generator)
    }
}
