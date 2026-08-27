public extension ShaderRegistry {
    static let fadeDefinition = timeShader(.fade, "fadeFragment", glslFade, mslFade)
}

private let glslFade = """
    mask = 1.0 - clamp(TIME, 0.0, 1.0);
"""

private let mslFade = """
    mask = 1.0 - clamp(TIME, 0.0, 1.0);
"""
