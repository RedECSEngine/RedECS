import TiledInterpreter

public enum Resource<T> {
    case loading
    case failedToLoad(Error)
    case loaded(T)
}

public enum ResourceType {
    case image
    case sound
    case tilemap
    case bitmapFont
    // TODO: preload sprite animation dictionary
}

public protocol ResourceManager: AnyObject {
    var textures: [TextureId: Resource<TextureMap>] { get }
    var animations: [TextureId: SpriteAnimationDictionary] { get set }
    var tileMaps: [String: TiledMapJSON] { get set }
    var tileSets: [String: TiledTilesetJSON] { get set }
    var fonts: [String: BitmapFont] { get set }
    
    func preload(_ assets: [(String, ResourceType)]) -> Future<Void, Error>
    
    @discardableResult
    func startTextureLoadIfNeeded(textureId: TextureId) -> Future<Void, Error>
    
    func getTexture(textureId: TextureId) -> TextureMap?
    func animationsForTexture(_ textureId: TextureId) -> SpriteAnimationDictionary?
    
    func loadJSONFile<T: Decodable>(_ name: String, decodedAs: T.Type) -> Future<T, Error>
    func loadTiledMap(_ name: String) -> Future<TiledMapJSON, Error>
    func loadBitmapFontTextFile(_ name: String) -> Future<BitmapFont, Error>
}

public extension ResourceManager {
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
            print(error)
            return nil
        }
    }
}
