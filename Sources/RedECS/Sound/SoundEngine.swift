public protocol SoundEngine: AnyObject {
    var volume: Double { get set }

    func preloadSoundSprite(_ name: String) -> Future<Void, Error>
    func play(_ sound: SoundId, loop: Bool?)
    func stop(_ sound: SoundId)
    func stopAllSounds()
}

public extension SoundEngine {
    func play(_ sound: SoundId) {
        play(sound, loop: nil)
    }
}
