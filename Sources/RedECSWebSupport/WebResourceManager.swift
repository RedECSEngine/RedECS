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
    public var textFiles: [String: String] = [:]

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
    public func startTextureLoadIfNeeded(_ resource: LoadableResource) -> Future<Void, Swift.Error> {
        assert(resource.type == .image, "\(resource.fileName) is not an image resource")
        let textureId = resource.name
        guard textures[textureId] == nil else {
            return .just(())
        }

        textures[textureId] = .loading
        print("starting texture load: \(textureId)")
        return loadImageFile(resource)
            .flatMap { _ -> Future<TextureMap, Swift.Error> in
                self.decodeJSON(LoadableResource(name: textureId, ext: "json", type: .json), as: TextureMap.self)
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

    public func loadTextFile(_ resource: LoadableResource) -> Future<String, Swift.Error> {
        assert(resource.type == .json || resource.type == .csv, "\(resource.fileName) is not a text resource")
        if let text = textFiles[resource.fileName] {
            return .just(text)
        }
        return fetchText(resource)
            .readValue { result in
                if case let .success(text) = result {
                    self.textFiles[resource.fileName] = text
                }
            }
    }

    public func loadJSONFile<T: Decodable>(
        _ resource: LoadableResource,
        decodedAs: T.Type
    ) -> Future<T, Swift.Error> {
        assert(resource.type == .json, "\(resource.fileName) is not a json resource")
        return decodeJSON(resource, as: T.self)
    }

    public func loadImageFile(
        _ resource: LoadableResource
    ) -> Future<JSValue, Swift.Error> {
        assert(resource.type == .image, "\(resource.fileName) is not an image resource")
        return Future { (resolve: @escaping (Result<JSValue, Swift.Error>) -> Void) in
            if let image = self.textureImages[resource.name] {
                resolve(.success(image))
                return
            }

            guard let url = self.url(for: resource) else {
                resolve(.failure(WebResourceManagerError.windowLocationOriginNotAvailable))
                return
            }
            guard let fetchFunc = JSObject.global.fetch.function else {
                resolve(.failure(WebResourceManagerError.jsFetchFunctionNotAvailable))
                return
            }

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
                        self.textureImages[resource.name] = value
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

    public func loadTiledMap(_ resource: LoadableResource) -> Future<TiledMapJSON, Swift.Error> {
        assert(resource.type == .tilemap, "\(resource.fileName) is not a tilemap resource")
        return decodeJSON(resource, as: TiledMapJSON.self)
            .flatMap { tileMap -> Future<TiledMapJSON, Swift.Error> in
                let loads = Set(tileMap.unresolvedTileSetSources).map { source in
                    self.loadTileSet(LoadableResource(fileName: source, type: .tileset)).toVoid()
                }
                return Future<Void, Swift.Error>.zip(loads).flatMap { _ -> Future<TiledMapJSON, Swift.Error> in
                    do {
                        return .just(try tileMap.resolvingTileSets(from: self.tileSets))
                    } catch {
                        return .fail(error)
                    }
                }
            }
            .flatMap { tileMap -> Future<TiledMapJSON, Swift.Error> in
                let imageFileNames = Set(tileMap.tileSets.compactMap { $0.tileSet?.imageFileName })
                return Future<Void, Swift.Error>.zip(imageFileNames.map { self.loadTileSetImage($0) })
                    .map { _ in tileMap }
            }
            .readValue { result in
                if case let .success(tileMap) = result {
                    self.tileMaps[resource.fileName] = tileMap
                }
            }
    }

    public func loadTileSet(_ resource: LoadableResource) -> Future<TiledTilesetJSON, Swift.Error> {
        assert(resource.type == .tileset, "\(resource.fileName) is not a tileset resource")
        return decodeJSON(resource, as: TiledTilesetJSON.self)
            .flatMap { tileSet -> Future<TiledTilesetJSON, Swift.Error> in
                guard let imageFileName = tileSet.imageFileName else {
                    return .just(tileSet)
                }
                return self.loadTileSetImage(imageFileName).map { _ in tileSet }
            }
            .readValue { result in
                if case let .success(tileSet) = result {
                    self.tileSets[resource.fileName] = tileSet
                }
            }
    }

    public func loadBitmapFontTextFile(_ resource: LoadableResource) -> Future<BitmapFont, Swift.Error> {
        assert(resource.type == .bitmapFont, "\(resource.fileName) is not a bitmap font resource")
        return fetchText(resource)
            .flatMap { text -> Future<BitmapFont, Swift.Error> in
                do {
                    return .just(try BitmapFont(fromString: text))
                } catch {
                    print(text)
                    return .fail(WebResourceManagerError.fileDecodeFailure("\(resource.fileName):" + String(describing: error)))
                }
            }
            .flatMap { font -> Future<BitmapFont, Swift.Error> in
                self.fonts[font.info.face] = font
                return self.loadImageFile(LoadableResource(fileName: font.page.file, type: .image))
                    .map { _ in font }
            }
    }

    private func loadTileSetImage(_ imageFileName: String) -> Future<Void, Swift.Error> {
        loadImageFile(LoadableResource(fileName: imageFileName, type: .image)).toVoid()
    }

    private func decodeJSON<T: Decodable>(_ resource: LoadableResource, as type: T.Type) -> Future<T, Swift.Error> {
        let text: Future<String, Swift.Error>
        if let cached = textFiles[resource.fileName] {
            text = .just(cached)
        } else {
            text = fetchText(resource)
        }
        return text.flatMap { text -> Future<T, Swift.Error> in
            do {
                let parse: ((ConvertibleToJSValue...) throws -> JSValue)? = JSObject.global.JSON.object?.throwing.parse
                guard let parse else {
                    return .fail(WebResourceManagerError.fileDecodeFailure("JSON.parse is not available"))
                }
                let json = try parse(text)
                return .just(try JSValueDecoder().decode(T.self, from: json))
            } catch {
                return .fail(WebResourceManagerError.fileDecodeFailure("couldn't decode \(T.self) from \(resource.fileName), \(error)"))
            }
        }
    }

    private func fetchText(_ resource: LoadableResource) -> Future<String, Swift.Error> {
        Future { (resolve: @escaping (Result<String, Swift.Error>) -> Void) in
            guard let url = self.url(for: resource) else {
                resolve(.failure(WebResourceManagerError.windowLocationOriginNotAvailable))
                return
            }
            guard let fetchFunc = JSObject.global.fetch.function else {
                resolve(.failure(WebResourceManagerError.jsFetchFunctionNotAvailable))
                return
            }

            (JSPromise(from: fetchFunc(url)))?
                .then(success: { response in
                    JSPromise(from: response.text())?.jsValue ?? .null
                })
                .then(success: { value in
                    guard let text = value.string else {
                        resolve(.failure(WebResourceManagerError.fileDecodeFailure("\(resource.fileName) is not text")))
                        return JSValue.null
                    }
                    print("Loaded \(resource.fileName)")
                    resolve(.success(text))
                    return JSValue.null
                }, failure: { error in
                    print("error", error)
                    resolve(.failure(WebResourceManagerError.jsError(String(describing: error.jsValue))))
                    return JSValue.null
                })
        }
    }

    private func url(for resource: LoadableResource) -> String? {
        guard let origin = JSObject.global.window.object?.location.object?.origin.string else {
            return nil
        }
        return origin + "/" + resourcePath + "/" + resource.fileName
    }
}
