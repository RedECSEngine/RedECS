import Foundation
import AVFoundation
import RedECS

public final class AppleSoundEngine: SoundEngine {
    public enum AppleSoundEngineError: Swift.Error {
        case fileNotFound(String)
        case emptySpriteSource(String)
    }

    private struct LoadedSound {
        var file: AVAudioFile
        var segment: SoundSpriteMap.Segment
    }

    public var volume: Double {
        get { Double(engine.mainMixerNode.outputVolume) }
        set { engine.mainMixerNode.outputVolume = Float(newValue) }
    }

    public var resourceBundle: Bundle

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayerIndex = 0
    private var loadedSprites: Set<String> = []
    private var sounds: [SoundId: LoadedSound] = [:]
    private var activePlayers: [SoundId: AVAudioPlayerNode] = [:]

    public init(resourceBundle: Bundle = .main, playerCount: Int = 8) {
        self.resourceBundle = resourceBundle
        for _ in 0..<playerCount {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)
            players.append(player)
        }
    }

    public func preloadSoundSprite(_ name: String) -> Future<Void, Error> {
        if loadedSprites.contains(name) {
            return .just(())
        }
        return Future { resolve in
            do {
                let map = try self.loadMap(named: name)
                guard let source = map.src.first else {
                    throw AppleSoundEngineError.emptySpriteSource(name)
                }
                let file = try AVAudioFile(forReading: self.audioURL(for: source))
                for (segmentName, segment) in map.sprite {
                    let soundId = SoundId(rawValue: segmentName)
                    assert(self.sounds[soundId] == nil, "duplicate sound '\(segmentName)' while loading sprite '\(name)'")
                    self.sounds[soundId] = LoadedSound(file: file, segment: segment)
                }
                self.loadedSprites.insert(name)
                print("sound sprite loaded: \(name)")
                resolve(.success(()))
            } catch {
                print("error loading sound sprite \(name):", error)
                resolve(.failure(error))
            }
        }
    }

    public func play(_ sound: SoundId, loop: Bool?) {
        guard let loaded = sounds[sound] else {
            assertionFailure("unknown sound '\(sound.rawValue)'")
            return
        }
        let sampleRate = loaded.file.processingFormat.sampleRate
        let startFrame = AVAudioFramePosition(loaded.segment.offsetMs / 1000 * sampleRate)
        let requestedFrames = AVAudioFramePosition(loaded.segment.durationMs / 1000 * sampleRate)
        guard startFrame >= 0, startFrame < loaded.file.length, requestedFrames > 0 else {
            assertionFailure("sound '\(sound.rawValue)' is outside its audio file")
            return
        }
        startEngineIfNeeded()
        let frameCount = AVAudioFrameCount(min(requestedFrames, loaded.file.length - startFrame))
        let player = nextAvailablePlayer()
        if player.outputFormat(forBus: 0) != loaded.file.processingFormat {
            engine.connect(player, to: engine.mainMixerNode, format: loaded.file.processingFormat)
        }
        if loop ?? loaded.segment.loops {
            guard let buffer = loopBuffer(for: loaded, startFrame: startFrame, frameCount: frameCount) else {
                assertionFailure("could not read sound '\(sound.rawValue)' into a loop buffer")
                return
            }
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        } else {
            player.scheduleSegment(
                loaded.file,
                startingFrame: startFrame,
                frameCount: frameCount,
                at: nil,
                completionHandler: nil
            )
        }
        activePlayers = activePlayers.filter { $0.value !== player }
        activePlayers[sound] = player
        player.play()
    }

    public func stop(_ sound: SoundId) {
        guard let player = activePlayers[sound] else { return }
        player.stop()
        activePlayers[sound] = nil
    }

    public func stopAllSounds() {
        players.forEach { $0.stop() }
        activePlayers.removeAll()
    }

    private func loadMap(named name: String) throws -> SoundSpriteMap {
        guard let url = resourceBundle.url(forResource: name, withExtension: "json") else {
            throw AppleSoundEngineError.fileNotFound("\(name).json in \(resourceBundle.description)")
        }
        return try JSONDecoder().decode(SoundSpriteMap.self, from: try Data(contentsOf: url))
    }

    private func audioURL(for source: String) throws -> URL {
        let nameSplit = source.split(separator: ".")
        var name = source
        var ext: String? = nil
        if nameSplit.count > 1 {
            name = String(nameSplit.dropLast().joined(separator: "."))
            ext = String(nameSplit[nameSplit.count - 1])
        }
        guard let url = resourceBundle.url(forResource: name, withExtension: ext) else {
            throw AppleSoundEngineError.fileNotFound("\(source) in \(resourceBundle.description)")
        }
        return url
    }

    private func loopBuffer(for loaded: LoadedSound, startFrame: AVAudioFramePosition, frameCount: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: loaded.file.processingFormat, frameCapacity: frameCount) else {
            return nil
        }
        do {
            loaded.file.framePosition = startFrame
            try loaded.file.read(into: buffer, frameCount: frameCount)
            return buffer
        } catch {
            print("error reading loop buffer:", error)
            return nil
        }
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            print("error starting sound engine:", error)
        }
    }

    private func nextAvailablePlayer() -> AVAudioPlayerNode {
        if let idle = players.first(where: { !$0.isPlaying }) {
            return idle
        }
        let player = players[nextPlayerIndex]
        nextPlayerIndex = (nextPlayerIndex + 1) % players.count
        player.stop()
        return player
    }
}
