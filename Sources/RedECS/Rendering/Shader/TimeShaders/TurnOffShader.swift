public extension ShaderRegistry {
    static let turnOffDefinition = timeShader(.turnOff, "turnOffFragment", glslTurnOff, mslTurnOff)
}

private let glslTurnOff = """
    vec2 tile = floor(FRAG / 12.0);
    mask = hash(tile) > fract(TIME) ? 1.0 : 0.0;
"""

private let mslTurnOff = """
    float2 tile = floor(FRAG / 12.0);
    mask = \(hashMSL("tile")) > fract(TIME) ? 1.0 : 0.0;
"""
