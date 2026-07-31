public extension ShaderRegistry {
    static let rippleDefinition = timeShader(.ripple, "rippleFragment", glslRipple, mslRipple)
}

private let glslRipple = """
    vec2 d = v_texCoord - 0.5;
    float r = length(d);
    vec2 dir = r > 0.0001 ? d / r : vec2(0.0);
    uv += dir * sin(r * 40.0 - TIME * CYCLE) * 0.002;
"""

private let mslRipple = """
    float2 d = in.texCoord.xy - 0.5;
    float r = length(d);
    float2 dir = r > 0.0001 ? d / r : float2(0.0);
    uv += dir * sin(r * 40.0 - TIME * CYCLE) * 0.002;
"""
