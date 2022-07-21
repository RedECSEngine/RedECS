public protocol ResourceLoader {
    func loadJSONFile<T: Decodable>(_ name: String, decodedAs: T.Type) -> Promise<T, Error>
}
