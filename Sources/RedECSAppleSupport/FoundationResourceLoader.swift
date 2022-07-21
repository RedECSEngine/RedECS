import Foundation
import RedECS

public struct FoundationResourceLoader: ResourceLoader {
    public enum Error: Swift.Error {
        case fileNotFound
        case fileLoadFailure
        case fileDecodeFailure
    }
    
    public let resourceBundle: Bundle
    
    public init(resourceBundle: Bundle = .main) {
        self.resourceBundle = resourceBundle
    }
    
    public func loadJSONFile<T: Decodable>(
        _ name: String,
        decodedAs: T.Type
    ) -> Promise<T, Swift.Error> {
        Promise { resolve in
            guard let path = resourceBundle.path(forResource: name, ofType: "json") else {
                resolve(.failure(Error.fileNotFound))
                return
            }

            let url = URL(fileURLWithPath: path)

            guard let jsonData = try? Data(contentsOf: url, options: .mappedIfSafe) else {
                resolve(.failure(Error.fileLoadFailure))
                return
            }

            guard let decoded = try? JSONDecoder().decode(T.self, from: jsonData) else {
                resolve(.failure(Error.fileDecodeFailure))
                return
            }
            
            resolve(.success(decoded))
        }
    }
}
