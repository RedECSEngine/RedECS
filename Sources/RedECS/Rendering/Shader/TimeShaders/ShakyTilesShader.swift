public extension ShaderRegistry {
    static let shakyTilesDefinition = timeShader(.shakyTiles, "shakyTilesFragment", glslShakyTiles, mslShakyTiles)
}

private let glslShakyTiles = """
    vec2 tile = floor(FRAG / 16.0);
    float t = floor(TIME * STEP);
    uv += (vec2(hash(tile + t), hash(tile + t + 3.0)) - 0.5) * 0.01;
"""

private let mslShakyTiles = """
    float2 tile = floor(FRAG / 16.0);
    float t = floor(TIME * STEP);
    uv += (float2(\(hashMSL("tile + t")), \(hashMSL("tile + t + 3.0"))) - 0.5) * 0.01;
"""
