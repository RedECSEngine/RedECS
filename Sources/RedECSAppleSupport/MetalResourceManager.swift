import Foundation
import RedECS
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
    
    // Apple Specific
    public var resourceBundle: Bundle
    public let metalDevice: MTLDevice
    public var textureImages: [TextureId: MTLTexture] = [:]
    
    public init(resourceBundle: Bundle = .main, metalDevice: MTLDevice) {
        self.resourceBundle = resourceBundle
        self.metalDevice = metalDevice
    }
    
    public func loadJSONFile<T: Decodable>(
        _ name: String,
        decodedAs: T.Type
    ) -> Future<T, Swift.Error> {
        let nameSplit = name.split(separator: ".")
        var name = name
        var ext = "json"
        if nameSplit.count > 1 {
            name = String(nameSplit.dropLast().joined(separator: "."))
            ext = String(nameSplit[nameSplit.count - 1])
        }
        return Future { resolve in
            guard let path = self.resourceBundle.path(forResource: name, ofType: ext) else {
                resolve(.failure(MetalResourceManagerError.fileNotFound("\(name).\(ext) in \(self.resourceBundle.description)")))
                return
            }

            let url = URL(fileURLWithPath: path)

            guard let jsonData = try? Data(contentsOf: url, options: .mappedIfSafe) else {
                resolve(.failure(MetalResourceManagerError.fileLoadFailure(url.absoluteString)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: jsonData)
                resolve(.success(decoded))
            } catch {
                print(String(data: jsonData, encoding: .utf8))
                resolve(.failure(MetalResourceManagerError.fileDecodeFailure("\(name).\(ext):" + String(describing: error))))
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
            case .bitmapFont:
                return self.loadBitmapFontTextFile(id).toVoid()
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
    
    @discardableResult
    public func startTextureLoadIfNeeded(textureId: TextureId) -> Future<Void, Swift.Error> {
        guard textures[textureId] == nil else {
            return .just(())
        }
        
        textures[textureId] = .loading
        print("starting texture load: \(textureId)")
        return loadImageFile(name: textureId)
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
                        .flatMap { tileSet -> Future<MTLTexture, Swift.Error> in
                            self.tileSets[filename] = tileSet
                            let imageName = tileSet.image.split(separator: ".").dropLast().joined(separator: ".")
                            return self.loadImageFile(name: String(imageName))
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
    
    public func loadImageFile(
        name: String
    ) -> Future<MTLTexture, Swift.Error> {
        Future { [weak self] (resolve: @escaping (Result<MTLTexture, Swift.Error>) -> Void) in
            guard let self = self else { return }
            if let image = self.textureImages[name] {
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
                let texture = try textureLoader.newTexture(
                    name: name,
                    scaleFactor: 1.0,
                    bundle: self.resourceBundle,
                    options: textureLoaderOptions
                )
                self.textureImages[name] = texture
                resolve(.success(texture))
            } catch {
                resolve(.failure(error))
            }
        }
    }
    
    public func loadBitmapFontTextFile(_ name: String) -> Future<BitmapFont, Swift.Error> {
        var name = name
        var ext = "fnt"
        let nameSplit = name.split(separator: ".")
        if nameSplit.count > 1 {
            name = String(nameSplit.dropLast().joined(separator: "."))
            ext = String(nameSplit[nameSplit.count - 1])
        }
        return Future { (resolve: (Result<BitmapFont, Error>) -> Void) in
            guard let path = self.resourceBundle.path(forResource: name, ofType: ext) else {
                resolve(.failure(MetalResourceManagerError.fileNotFound("\(name).\(ext) in \(self.resourceBundle.description)")))
                return
            }

            let url = URL(fileURLWithPath: path)

            guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
                  let string = String(data: data, encoding: .utf8) else {
                resolve(.failure(MetalResourceManagerError.fileLoadFailure(url.absoluteString)))
                return
            }
           
            do {
                let decoded = try BitmapFont(fromString: string)
                
                resolve(.success(decoded))
            } catch {
                print(String(data: data, encoding: .utf8))
                resolve(.failure(MetalResourceManagerError.fileDecodeFailure("\(name).\(ext):" + String(describing: error))))
            }
        }
        .flatMap { font -> Future<BitmapFont, Swift.Error> in
            self.fonts[font.info.face] = font
            let imageName = font.page.file.split(separator: ".").dropLast().joined(separator: ".")
            return self.loadImageFile(name: String(imageName))
                .map { _ in
                    font
                }
        }
    }
}
