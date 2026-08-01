import JavaScriptKit
import RedECS
import RedHUD
import TiledInterpreter

public final class WebResourceManager: ResourceManager {
    public enum WebResourceManagerError: Swift.Error {
        case fileNotFound
        case fileLoadFailure
        case fileDecodeFailure(String?)
        case windowLocationOriginNotAvailable
        case jsFetchFunctionNotAvailable
        case jsError(String)
    }
    
    public var textures: [TextureId: Resource<TextureMap>] = [:]
    public var animations: [TextureId: SpriteAnimationDictionary] = [:]
    public var tileMaps: [String: TiledMapJSON] = [:]
    public var tileSets: [String: TiledTilesetJSON] = [:]
    public var fonts: [String: BitmapFont] = [:]
    
    /// Web Specific
    public var textureImages: [TextureId: JSValue] = [:]
    let resourcePath: String
    
    public init(resourcePath: String) {
        self.resourcePath = resourcePath
        registerDefaultHUDFont()
    }

    /// Makes RedHUD's embedded fallback font renderable with no game-side
    /// setup: the metrics go into `fonts` and the embedded atlas page is
    /// decoded from a data URL into `textureImages`. A game that later
    /// preloads the same face overwrites the metrics; the atlas entries
    /// short-circuit that load's image fetch.
    private func registerDefaultHUDFont() {
        let font = DefaultHUDFont.font
        fonts[font.info.face] = font
        guard let image = JSObject.global.Image.function?.new() else {
            print("⚠️ failed to create image for default HUD font atlas")
            return
        }
        image.src = .string("data:image/png;base64," + DefaultHUDFont.pageImageBase64)
        textureImages[font.pageTextureName] = image.jsValue
        // loadBitmapFontTextFile fetches the page by file name; alias it so
        // a later preload of the same face reuses this image.
        textureImages[font.page.file] = image.jsValue
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
                resolve(.failure(WebResourceManagerError.windowLocationOriginNotAvailable))
                return
            }
            guard let fetchFunc = JSObject.global.fetch.function else {
                resolve(.failure(WebResourceManagerError.jsFetchFunctionNotAvailable))
                return
            }
            
            let url = origin + "/" + self.resourcePath + "/" + name
            
            (JSPromise(from: fetchFunc(url)))?
                .then(success: { response in
                    JSPromise(from: response.json())?.jsValue ?? .null
                })
                .then(success: { json in
                    do {
                        let parsed = try JSValueDecoder().decode(T.self, from: json)
                        print("Loaded \(name)")
                        resolve(.success(parsed))
                    } catch {
                        resolve(.failure(WebResourceManagerError.fileDecodeFailure("couldn't decode \(T.self), \(error)")))
                    }
                    return JSValue.null
                }, failure: { error in
                    print("error", error)
                    resolve(.failure(WebResourceManagerError.jsError(String(describing: error.jsValue))))
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
                resolve(.failure(WebResourceManagerError.fileNotFound))
                return
            }
            guard let fetchFunc = JSObject.global.fetch.function else {
                resolve(.failure(WebResourceManagerError.jsFetchFunctionNotAvailable))
                return
            }
            
            let url = origin + "/" + self.resourcePath + "/" + name
            (JSPromise(from: fetchFunc(url)))?
                .then(success: { response in
                    JSPromise(from: response.blob())?.jsValue ?? .null
                })
                .then(success: { value in
                    let url = JSObject.global.URL.function?.createObjectURL.function?(value)
                    let image = JSObject.global.Image.function?.new()
                    image?.src = url ?? .null
                    image?.onload = JSClosure({ args in
                        guard let value = image?.jsValue else {
                            resolve(.failure(WebResourceManagerError.jsError("undefined")))
                            return .undefined
                        }
                        self.textureImages[name] = value
                        resolve(.success(value))
                        return .undefined
                    }).jsValue
                    return JSValue.null
                }, failure: { error in
                    print("error", error)
                    resolve(.failure(WebResourceManagerError.jsError(String(describing: error.jsValue))))
                    return JSValue.null
                })
        }
    }
    
    public func loadTiledMap(_ name: String) -> Future<TiledMapJSON, Swift.Error> {
        return loadJSONFile(name, decodedAs: TiledMapJSON.self)
            .flatMap { map -> Future<TiledMapJSON, Swift.Error> in
                let loads = Set(map.unresolvedTileSetSources).map { source -> Future<Void, Swift.Error> in
                    self.loadJSONFile(source, decodedAs: TiledTilesetJSON.self)
                        .readValue { result in
                            if case let .success(tileSet) = result {
                                self.tileSets[source] = tileSet
                            }
                        }
                        .toVoid()
                }
                return Future<Void, Swift.Error>.zip(loads).flatMap { _ -> Future<TiledMapJSON, Swift.Error> in
                    do {
                        return .just(try map.resolvingTileSets(from: self.tileSets))
                    } catch {
                        return .fail(error)
                    }
                }
            }
            .flatMap { map -> Future<TiledMapJSON, Swift.Error> in
                let images = map.tileSets.compactMap { reference -> (String, String)? in
                    guard let tileSet = reference.tileSet,
                          let fileName = tileSet.imageFileName,
                          let textureId = tileSet.textureId else { return nil }
                    return (textureId, fileName)
                }
                let loads = Dictionary(images, uniquingKeysWith: { first, _ in first })
                    .map { textureId, fileName -> Future<Void, Swift.Error> in
                        self.loadImageFile(name: fileName)
                            .readValue { result in
                                if case let .success(value) = result {
                                    self.textureImages[textureId] = value
                                }
                            }
                            .toVoid()
                    }
                return Future<Void, Swift.Error>.zip(loads).map { _ in map }
            }
            .readValue { result in
                if case let .success(map) = result {
                    self.tileMaps[name] = map
                }
            }
    }
    
    public func preload(_ assets: [LoadableResource]) -> Future<Void, Error> {
        let futures = assets.map { asset -> Future<Void, Swift.Error> in
            switch asset.type {
            case .image:
                return self.startTextureLoadIfNeeded(textureId: asset.name)
            case .sound:
                return .just(())
            case .tilemap:
                return self.loadTiledMap(asset.name).toVoid()
            case .bitmapFont:
                return self.loadBitmapFontTextFile(asset.name).toVoid()
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
    
    public func loadBitmapFontTextFile(_ name: String) -> Future<BitmapFont, Swift.Error> {
        return Future { (resolve: @escaping (Result<BitmapFont, Swift.Error>) -> Void) in
            if let font = self.fonts[name] {
                resolve(.success(font))
                return
            }
            
            guard let origin = JSObject.global.window.object?.location.object?.origin.string else {
                resolve(.failure(WebResourceManagerError.fileNotFound))
                return
            }
            guard let fetchFunc = JSObject.global.fetch.function else {
                resolve(.failure(WebResourceManagerError.jsFetchFunctionNotAvailable))
                return
            }
            
            let url = origin + "/" + self.resourcePath + "/" + name
            (JSPromise(from: fetchFunc(url)))?
                .then(success: { response in
                    JSPromise(from: response.text())?.jsValue ?? .null
                })
                .then(success: { value in
                    guard let fontText = value.string else {
                        resolve(.failure(WebResourceManagerError.fileDecodeFailure("\(name):")))
                        return JSValue.null
                    }
                    do {
                        let decoded = try BitmapFont(fromString: fontText)
                        resolve(.success(decoded))
                    } catch {
                        print(fontText)
                        resolve(.failure(WebResourceManagerError.fileDecodeFailure("\(name):" + String(describing: error))))
                    }
                    return JSValue.null
                }, failure: { error in
                    print("error", error)
                    resolve(.failure(WebResourceManagerError.jsError(String(describing: error.jsValue))))
                    return JSValue.null
                })
        }
        .flatMap { font -> Future<BitmapFont, Swift.Error> in
            self.fonts[font.info.face] = font
            let textureName = font.page.file.split(separator: ".").dropLast().joined(separator: ".")
            return self.loadImageFile(name: String(font.page.file))
                .map { value -> Void in
                    self.textureImages[textureName] = value
                    return
                }
                .map { _ in
                    font
                }
        }
    }
    
}
