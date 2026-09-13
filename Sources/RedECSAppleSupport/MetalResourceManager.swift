import Foundation
import RedECS
import RedHUD
import TiledInterpreter
import MetalKit

public final class MetalResourceManager: ResourceManager {
    public enum MetalResourceManagerError: Swift.Error {
        case fileNotFound(String)
        case fileLoadFailure(String)
        case fileDecodeFailure(String)
    }

    public var textures: [TextureId: Resource<TextureMap>]  = [:]
    public var animations: [TextureId: SpriteAnimationDictionary] = [:]
    public var tileMaps: [String: TiledMapJSON] = [:]
    public var tileSets: [String: TiledTilesetJSON] = [:]
    public var fonts: [String: BitmapFont] = [:]
    public var textFiles: [String: String] = [:]

    // Apple Specific
    public var resourceBundle: Bundle
    public let metalDevice: MTLDevice
    public var textureImages: [TextureId: MTLTexture] = [:]

    public init(resourceBundle: Bundle = .main, metalDevice: MTLDevice) {
        self.resourceBundle = resourceBundle
        self.metalDevice = metalDevice
        registerDefaultHUDFont()
    }

    /// Makes RedHUD's embedded fallback font renderable with no game-side
    /// setup: the metrics go into `fonts` and the embedded atlas page into
    /// `textureImages`. A game that later preloads the same face overwrites
    /// the metrics; the atlas entry short-circuits that load's image fetch.
    private func registerDefaultHUDFont() {
        let font = DefaultHUDFont.font
        fonts[font.info.face] = font
        guard let data = Data(base64Encoded: DefaultHUDFont.pageImageBase64) else {
            assertionFailure("embedded default HUD font atlas is not valid base64")
            return
        }
        let textureLoader = MTKTextureLoader(device: metalDevice)
        do {
            textureImages[font.pageTextureName] = try textureLoader.newTexture(
                data: data,
                options: [
                    .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                    .textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue),
                    .SRGB: NSNumber(value: false)
                ]
            )
        } catch {
            print("⚠️ failed to load default HUD font atlas:", error)
        }
    }

    public func loadTextFile(_ resource: LoadableResource) -> Future<String, Swift.Error> {
        assert(resource.type == .json || resource.type == .csv, "\(resource.fileName) is not a text resource")
        if let text = textFiles[resource.fileName] {
            return .just(text)
        }
        return readText(resource)
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
        return readText(resource)
            .flatMap { text -> Future<BitmapFont, Swift.Error> in
                do {
                    return .just(try BitmapFont(fromString: text))
                } catch {
                    print(text)
                    return .fail(MetalResourceManagerError.fileDecodeFailure("\(resource.fileName):" + String(describing: error)))
                }
            }
            .flatMap { font -> Future<BitmapFont, Swift.Error> in
                self.fonts[font.info.face] = font
                return self.loadImageFile(LoadableResource(fileName: font.page.file, type: .image))
                    .map { _ in font }
            }
    }

    public func loadImageFile(
        _ resource: LoadableResource
    ) -> Future<MTLTexture, Swift.Error> {
        assert(resource.type == .image, "\(resource.fileName) is not an image resource")
        return Future { [weak self] (resolve: @escaping (Result<MTLTexture, Swift.Error>) -> Void) in
            guard let self = self else { return }
            if let image = self.textureImages[resource.name] {
                resolve(.success(image))
                return
            }

            let textureLoader = MTKTextureLoader(device: self.metalDevice)
            let textureLoaderOptions: [MTKTextureLoader.Option: NSNumber] = [
                .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                .textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue),
                .SRGB: NSNumber(value: false)
            ]

            do {
                let texture = try self.loadTexture(
                    resource,
                    textureLoader: textureLoader,
                    options: textureLoaderOptions
                )
                self.textureImages[resource.name] = texture
                resolve(.success(texture))
            } catch {
                resolve(.failure(error))
            }
        }
    }

    private func loadTileSetImage(_ imageFileName: String) -> Future<Void, Swift.Error> {
        loadImageFile(LoadableResource(fileName: imageFileName, type: .image)).toVoid()
    }

    /// Prefer the loose image file over an asset catalog entry: the catalog
    /// is only compiled by Xcode, and its compiler re-encodes/color-manages
    /// the image, so the same texture sampled from a catalog build has
    /// subtly different texels than the raw file — which broke snapshot
    /// references between Xcode and `swift test` (see known-issues.md).
    /// The raw file is byte-identical in both environments; the catalog
    /// remains the fallback for resources shipped only that way.
    private func loadTexture(
        _ resource: LoadableResource,
        textureLoader: MTKTextureLoader,
        options: [MTKTextureLoader.Option: NSNumber]
    ) throws -> MTLTexture {
        if let url = resourceBundle.url(forResource: resource.name, withExtension: resource.ext) {
            return try textureLoader.newTexture(URL: url, options: options)
        }
        return try textureLoader.newTexture(
            name: resource.name,
            scaleFactor: 1.0,
            bundle: resourceBundle,
            options: options
        )
    }

    private func decodeJSON<T: Decodable>(_ resource: LoadableResource, as type: T.Type) -> Future<T, Swift.Error> {
        let text: Future<String, Swift.Error>
        if let cached = textFiles[resource.fileName] {
            text = .just(cached)
        } else {
            text = readText(resource)
        }
        return text.flatMap { text -> Future<T, Swift.Error> in
            do {
                return .just(try JSONDecoder().decode(T.self, from: Data(text.utf8)))
            } catch {
                print(text)
                return .fail(MetalResourceManagerError.fileDecodeFailure("\(resource.fileName):" + String(describing: error)))
            }
        }
    }

    private func readText(_ resource: LoadableResource) -> Future<String, Swift.Error> {
        Future { (resolve: (Result<String, Swift.Error>) -> Void) in
            guard let url = self.resourceBundle.url(forResource: resource.name, withExtension: resource.ext) else {
                resolve(.failure(MetalResourceManagerError.fileNotFound("\(resource.fileName) in \(self.resourceBundle.description)")))
                return
            }
            guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
                  let text = String(data: data, encoding: .utf8) else {
                resolve(.failure(MetalResourceManagerError.fileLoadFailure(url.absoluteString)))
                return
            }
            resolve(.success(text))
        }
    }
}
