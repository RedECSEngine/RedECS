import JavaScriptKit
import RedECS

public struct WebResourceLoader: ResourceLoader {
    public enum Error: Swift.Error {
        case fileNotFound
        case fileLoadFailure
        case fileDecodeFailure
        case jsFetchFunctionNotAvailable
        case jsError(JSValue)
    }
    
    let resourcePath: String
    
    public init(resourcePath: String) {
        self.resourcePath = resourcePath
    }
    
    public func loadJSONFile<T: Decodable>(
        _ name: String,
        decodedAs: T.Type
    ) -> Promise<T, Swift.Error> {
        Promise { (resolve: @escaping (Result<T, Swift.Error>) -> Void) in
            guard let origin = JSObject.global.window.object?.location.object?.origin.string else {
                resolve(.failure(Error.fileNotFound))
                return
            }
            guard let fetchFunc = JSObject.global.fetch.function else {
                resolve(.failure(Error.jsFetchFunctionNotAvailable))
                return
            }
            
            let url = origin + "/" + resourcePath + "/" + name
            
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
    ) -> Promise<JSValue, Swift.Error> {
        Promise { (resolve: @escaping (Result<JSValue, Swift.Error>) -> Void) in
            guard let origin = JSObject.global.window.object?.location.object?.origin.string else {
                resolve(.failure(Error.fileNotFound))
                return
            }
            guard let fetchFunc = JSObject.global.fetch.function else {
                resolve(.failure(Error.jsFetchFunctionNotAvailable))
                return
            }
            
            let url = origin + "/" + resourcePath + "/" + name
            
            (JSPromise(from: fetchFunc(url)))?
                .then(success: { response in
                    JSPromise(from: response.blob())
                })
                .then(success: { value in
                    let url = JSObject.global.URL.function?.createObjectURL.function?(value)
                    let image = JSObject.global.Image.function?.new()
                    image?.src = url ?? .null
                    image?.onload = JSClosure({ args in
                        resolve(.success(image?.jsValue ?? .null))
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
