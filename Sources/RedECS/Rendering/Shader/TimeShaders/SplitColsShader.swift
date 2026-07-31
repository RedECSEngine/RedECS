public extension ShaderRegistry {
    static let splitColsDefinition = timeShader(.splitCols, "splitColsFragment", glslSplitCols, mslSplitCols)
}

private let glslSplitCols = """
    float col = floor(FRAG.x / 8.0);
    float dir = mod(col, 2.0) < 1.0 ? 1.0 : -1.0;
    uv.y += dir * (0.5 + 0.5 * sin(TIME * CYCLE)) * 0.02;
"""

private let mslSplitCols = """
    float col = floor(FRAG.x / 8.0);
    float dir = fmod(col, 2.0) < 1.0 ? 1.0 : -1.0;
    uv.y += dir * (0.5 + 0.5 * sin(TIME * CYCLE)) * 0.02;
"""
