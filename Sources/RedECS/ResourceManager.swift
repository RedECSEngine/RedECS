import TiledInterpreter

public enum Resource<T> {
    case loading
    case failedToLoad(Error)
    case loaded(T)
}

public enum ResourceType: Equatable, Hashable, Codable, Sendable {
    case image
    case tilemap
    case tileset
    case bitmapFont
    case json
    case csv
    case soundSprite
    // TODO: preload sprite animation dictionary
}

public struct LoadableResource: Equatable, Hashable, Codable, Sendable {
    public var name: String
    public var ext: String
    public var type: ResourceType

    public init(name: String, ext: String, type: ResourceType) {
        self.name = name
        self.ext = ext
        self.type = type
    }

    public init(fileName: String, type: ResourceType) {
        if let dot = fileName.lastIndex(of: "."), dot != fileName.startIndex {
            self.init(
                name: String(fileName[..<dot]),
                ext: String(fileName[fileName.index(after: dot)...]),
                type: type
            )
        } else {
            self.init(name: fileName, ext: "", type: type)
        }
    }

    public var fileName: String {
        ext.isEmpty ? name : "\(name).\(ext)"
    }
}

public enum ResourceLoadingError: Error, Equatable {
    case notPreloadable(LoadableResource)
}

public protocol ResourceManager: AnyObject {
    var textures: [TextureId: Resource<TextureMap>] { get }
    var animations: [TextureId: SpriteAnimationDictionary] { get set }
    var tileMaps: [String: TiledMapJSON] { get set }
    var tileSets: [String: TiledTilesetJSON] { get set }
    var fonts: [String: BitmapFont] { get set }
    var textFiles: [String: String] { get set }

    func preload(_ resources: [LoadableResource]) -> Future<Void, Error>

    @discardableResult
    func startTextureLoadIfNeeded(_ resource: LoadableResource) -> Future<Void, Error>

    func getTexture(textureId: TextureId) -> TextureMap?
    func animationsForTexture(_ textureId: TextureId) -> SpriteAnimationDictionary?

    func loadJSONFile<T: Decodable>(_ resource: LoadableResource, decodedAs: T.Type) -> Future<T, Error>
    func loadTextFile(_ resource: LoadableResource) -> Future<String, Error>
    func loadTiledMap(_ resource: LoadableResource) -> Future<TiledMapJSON, Error>
    func loadTileSet(_ resource: LoadableResource) -> Future<TiledTilesetJSON, Error>
    func loadBitmapFontTextFile(_ resource: LoadableResource) -> Future<BitmapFont, Error>
}

public extension ResourceManager {
    func preload(_ resources: [LoadableResource]) -> Future<Void, Error> {
        let futures = resources.map(preloadFuture)
        if futures.isEmpty {
            return .just(())
        }
        print("⚙️ -- Starting assets preload")
        return .zip(futures)
            .readValue({ result in
                if case .success = result {
                    print("⚙️ -- Assets preloading complete")
                }
            })
            .toVoid()
    }

    private func preloadFuture(_ resource: LoadableResource) -> Future<Void, Error> {
        switch resource.type {
        case .image:
            return startTextureLoadIfNeeded(resource)
        case .tilemap:
            return loadTiledMap(resource).toVoid()
        case .tileset:
            return loadTileSet(resource).toVoid()
        case .bitmapFont:
            return loadBitmapFontTextFile(resource).toVoid()
        case .json, .csv:
            return loadTextFile(resource).toVoid()
        case .soundSprite:
            assertionFailure("\(resource.fileName) is a sound sprite; load it with SoundEngine.preloadSoundSprite")
            return .fail(ResourceLoadingError.notPreloadable(resource))
        }
    }

    func getTexture(textureId: TextureId) -> TextureMap? {
        guard let resource = textures[textureId] else { return nil }
        switch resource {
        case .loaded(let textureMap):
            return textureMap
        case .loading, .failedToLoad:
            return nil
        }
    }

    func animationsForTexture(_ textureId: TextureId) -> SpriteAnimationDictionary? {
        if let dict = animations[textureId] {
            return dict
        }
        guard let textureMap = getTexture(textureId: textureId) else {
            return nil
        }
        do {
            let dict = try SpriteAnimationDictionary(name: textureId, textureMap: textureMap)
            self.animations[textureId] = dict
            return dict
        } catch {
            print(textureId, error)
            return nil
        }
    }
}
