import JavaScriptKit
import RedECS
import RedECSRenderingComponents

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
    var textureImages: [TextureId: JSValue] = [:]
    
    public init(resourcePath: String) {
        self.resourcePath = resourcePath
    }
    
    public func startTextureLoadIfNeeded(textureId: TextureId) {
        guard textures[textureId] == nil else {
            return
        }
        
        textures[textureId] = .loading
        print("starting texture load: \(textureId)")
        loadImageFile(name: textureId)
            .flatMap { value -> Future<TextureMap, Swift.Error> in
                self.textureImages[textureId] = value
                return self.loadJSONFile(textureId, decodedAs: TextureMap.self)
            }
            .subscribe { result in
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
            
            let url = origin + "/" + self.resourcePath + "/" + name + ".json"
            
            (JSPromise(from: fetchFunc(url)))?
                .then(success: { response in
                    JSPromise(from: response.json())
                })
                .then(success: { json in
                    do {
                        let parsed = try JSValueDecoder().decode(T.self, from: json)
                        resolve(.success(parsed))
                    } catch {
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
            
            let url = origin + "/" + self.resourcePath + "/" + name + ".png"
            
            print("Load image: \(url)")
            
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
}
