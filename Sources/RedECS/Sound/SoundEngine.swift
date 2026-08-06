public protocol SoundEngine: AnyObject {
    var volume: Double { get set }

    func preloadSoundSprite(_ name: String) -> Future<Void, Error>
    func play(_ sound: SoundId)
    func stopAllSounds()
}
