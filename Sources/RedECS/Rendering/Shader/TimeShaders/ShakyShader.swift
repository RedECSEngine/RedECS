public extension ShaderRegistry {
    static let shakyDefinition = timeShader(.shaky, "shakyFragment", glslShaky, mslShaky)
}

private let glslShaky = """
    vec2 cell = floor(FRAG / 4.0);
    float t = floor(TIME * STEP);
    uv += (vec2(hash(cell + t), hash(cell + t + 7.0)) - 0.5) * 0.004;
"""

private let mslShaky = """
    float2 cell = floor(FRAG / 4.0);
    float t = floor(TIME * STEP);
    uv += (float2(\(hashMSL("cell + t")), \(hashMSL("cell + t + 7.0"))) - 0.5) * 0.004;
"""
