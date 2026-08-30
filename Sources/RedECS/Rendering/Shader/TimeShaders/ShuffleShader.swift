public extension ShaderRegistry {
    static let shuffleDefinition = timeShader(.shuffle, "shuffleFragment", glslShuffle, mslShuffle)
}

private let glslShuffle = """
    vec2 tile = floor(FRAG / 16.0);
    float t = floor(TIME * STEP) * 13.0;
    uv += (vec2(hash(tile + t), hash(tile + t + 5.0)) - 0.5) * 0.03;
"""

private let mslShuffle = """
    float2 tile = floor(FRAG / 16.0);
    float t = floor(TIME * STEP) * 13.0;
    uv += (float2(\(hashMSL("tile + t")), \(hashMSL("tile + t + 5.0"))) - 0.5) * 0.03;
"""
