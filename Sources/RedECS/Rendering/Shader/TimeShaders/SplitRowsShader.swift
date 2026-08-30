public extension ShaderRegistry {
    static let splitRowsDefinition = timeShader(.splitRows, "splitRowsFragment", glslSplitRows, mslSplitRows)
}

private let glslSplitRows = """
    float row = floor(FRAG.y / 8.0);
    float dir = mod(row, 2.0) < 1.0 ? 1.0 : -1.0;
    uv.x += dir * (0.5 + 0.5 * sin(TIME * CYCLE)) * 0.02;
"""

private let mslSplitRows = """
    float row = floor(FRAG.y / 8.0);
    float dir = fmod(row, 2.0) < 1.0 ? 1.0 : -1.0;
    uv.x += dir * (0.5 + 0.5 * sin(TIME * CYCLE)) * 0.02;
"""
