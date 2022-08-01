import JavaScriptKit
import RedECS
import RedECSRenderingComponents
import TiledInterpreter

public final class WebResourceManager: ResourceManager {
    public enum Error: Swift.Error {
        case fileNotFound
        case fileLoadFailure
        case fileDecodeFailure
        case windowLocationOriginNotAvailable
        case jsFetchFunctionNotAvailable
        case jsError(JSValue)
    }
    
    let resourcePath: String
    
    public var textures: [TextureId: Resource<TextureMap>] = [:]
    public var animations: [TextureId: SpriteAnimationDictionary] = [:]
    public var tileMaps: [String: TiledMapJSON] = [:]
    public var tileSets: [String: TiledTilesetJSON] = [:]
    
    /// Web Specific Storage for image resources
    public var textureImages: [TextureId: JSValue] = [:]
    
    public init(resourcePath: String) {
        self.resourcePath = resourcePath
    }
    
    @discardableResult
    public func startTextureLoadIfNeeded(textureId: TextureId) -> Future<Void, Swift.Error> {
        guard textures[textureId] == nil else {
            return .just(())
        }
        
        textures[textureId] = .loading
        print("starting texture load: \(textureId)")
        return loadImageFile(name: textureId + ".png")
            .flatMap { value -> Future<TextureMap, Swift.Error> in
                self.textureImages[textureId] = value
                return self.loadJSONFile(textureId + ".json", decodedAs: TextureMap.self)
            }
            .readValue { result in
                switch result {
                case .success(let value):
                    print("texture loaded: \(textureId)")
                    self.textures[textureId] = .loaded(value)
                case .failure(let error):
                    self.textureImages[textureId] = nil
                    self.textures[textureId] = .failedToLoad(error)
                    print("error loading texture", error)
                }
            }
            .toVoid()
    }
    
    public func loadJSONFile<T: Decodable>(
        _ name: String,
        decodedAs: T.Type
    ) -> Future<T, Swift.Error> {
        Future { (resolve: @escaping (Result<T, Swift.Error>) -> Void) in
            guard let origin = JSObject.global.window.object?.location.object?.origin.string else {
                resolve(.failure(Error.windowLocationOriginNotAvailable))
                return
            }
            guard let fetchFunc = JSObject.global.fetch.function else {
                resolve(.failure(Error.jsFetchFunctionNotAvailable))
                return
            }
            
            let url = origin + "/" + self.resourcePath + "/" + name
            
            (JSPromise(from: fetchFunc(url)))?
                .then(success: { response in
                    JSPromise(from: response.json())
                })
                .then(success: { json in
                    do {
                        let parsed = try JSValueDecoder().decode(T.self, from: json)
                        print("Loaded \(name)")
                        resolve(.success(parsed))
                    } catch {
                        print("couldn't decode \(T.self)", error)
                        resolve(.failure(Error.fileDecodeFailure))
                    }
                    return JSValue.null
                }, failure: { error in
                    print("error", error)
                    resolve(.failure(Error.jsError(error.jsValue)))
                    return JSValue.null
                })
        }
    }
    
    public func loadImageFile(
        name: String
    ) -> Future<JSValue, Swift.Error> {
        Future { (resolve: @escaping (Result<JSValue, Swift.Error>) -> Void) in
            if let image = self.textureImages[name] {
                resolve(.success(image))
                return
            }
            
            guard let origin = JSObject.global.window.object?.location.object?.origin.string else {
                resolve(.failure(Error.fileNotFound))
                return
            }
            guard let fetchFunc = JSObject.global.fetch.function else {
                resolve(.failure(Error.jsFetchFunctionNotAvailable))
                return
            }
            
            let url = origin + "/" + self.resourcePath + "/" + name
            (JSPromise(from: fetchFunc(url)))?
                .then(success: { response in
                    JSPromise(from: response.blob())
                })
                .then(success: { value in
                    let url = JSObject.global.URL.function?.createObjectURL.function?(value)
                    let image = JSObject.global.Image.function?.new()
                    image?.src = url ?? .null
                    image?.onload = JSClosure({ args in
                        guard let value = image?.jsValue else {
                            resolve(.failure(Error.jsError(.undefined)))
                            return .undefined
                        }
                        self.textureImages[name] = value
                        resolve(.success(value))
                        return .undefined
                    }).jsValue
                    return JSValue.null
                }, failure: { error in
                    print("error", error)
                    resolve(.failure(Error.jsError(error.jsValue)))
                    return JSValue.null
                })
        }
    }
    
    public func loadTiledMap(_ name: String) -> Future<TiledMapJSON, Swift.Error> {
        return loadJSONFile(
            name,
            decodedAs: TiledMapJSON.self
        )
        .flatMap { mapInfo in
            let tileSetSources = Set(mapInfo.tileSets.map { $0.source })
            let tileSetFutures: [Future<Void, Swift.Error>] = tileSetSources
                .map { filename -> Future<Void, Swift.Error>  in
                    self.loadJSONFile(filename, decodedAs: TiledTilesetJSON.self)
                        .flatMap { tileSet -> Future<JSValue, Swift.Error> in
                            self.tileSets[filename] = tileSet
                            return self.loadImageFile(name: tileSet.image)
                        }
                        .toVoid()
                }
            return .zip(tileSetFutures)
                .flatMap { tileSets in
                    self.tileMaps[name] = mapInfo
                    return .just(mapInfo)
                }
        }
    }
    
    public func preload(_ assets: [(String, ResourceType)]) -> Future<Void, Swift.Error> {
        let futures = assets.map { (id, type) -> Future<Void, Swift.Error> in
            switch type {
            case .image:
                return self.startTextureLoadIfNeeded(textureId: id)
            case .sound:
                return .just(())
            case .tilemap:
                return self.loadTiledMap(id).toVoid()
            }
        }
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
    
}
