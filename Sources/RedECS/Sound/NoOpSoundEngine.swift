public final class NoOpSoundEngine: SoundEngine {
    public var volume: Double = 1

    public init() {}

    public func preloadSoundSprite(_ resource: LoadableResource) -> Future<Void, Error> {
        .just(())
    }

    public func play(_ sound: SoundId, loop: Bool?) {}

    public func stop(_ sound: SoundId) {}

    public func stopAllSounds() {}
}
