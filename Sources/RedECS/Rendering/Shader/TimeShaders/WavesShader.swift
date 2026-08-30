public extension ShaderRegistry {
    static let wavesDefinition = timeShader(.waves, "wavesFragment", glslWaves, mslWaves)
}

private let glslWaves = """
    uv.x += sin(FRAG.y * 0.15 + TIME * CYCLE) * 0.003;
"""

private let mslWaves = """
    uv.x += sin(FRAG.y * 0.15 + TIME * CYCLE) * 0.003;
"""
