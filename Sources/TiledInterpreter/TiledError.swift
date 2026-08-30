public enum TiledError: Error, Equatable, Sendable {
    case unsupportedLayerDataEncoding(layer: String, encoding: String)
    case compressedLayerDataUnsupported(layer: String, compression: String)
    case malformedLayerData(layer: String)
    case infiniteMapsUnsupported(layer: String)
    case unresolvedTileSet(source: String)
}
