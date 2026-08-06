public final class NoOpSoundEngine: SoundEngine {
    public var volume: Double = 1

    public init() {}

    public func preloadSoundSprite(_ name: String) -> Future<Void, Error> {
        .just(())
    }

    public func play(_ sound: SoundId) {}

    public func stopAllSounds() {}
}
