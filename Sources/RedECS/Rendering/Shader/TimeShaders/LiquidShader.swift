public extension ShaderRegistry {
    static let liquidDefinition = timeShader(.liquid, "liquidFragment", glslLiquid, mslLiquid)
}

private let glslLiquid = """
    uv += vec2(sin(FRAG.y * 0.1 + TIME * CYCLE),
               sin(FRAG.x * 0.1 + TIME * CYCLE)) * 0.0025;
"""

private let mslLiquid = """
    uv += float2(sin(FRAG.y * 0.1 + TIME * CYCLE),
                 sin(FRAG.x * 0.1 + TIME * CYCLE)) * 0.0025;
"""
