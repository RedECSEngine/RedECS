public extension ShaderRegistry {
    static let timeShaderDefinitions: [ShaderDefinition] = [
        rippleDefinition,
        wavesDefinition,
        liquidDefinition,
        turnOffDefinition,
        splitRowsDefinition,
        splitColsDefinition,
        shakyDefinition,
        shakyTilesDefinition,
        shuffleDefinition,
        fadeDefinition,
    ]

    internal static func timeShader(
        _ id: ShaderId,
        _ fn: String,
        _ glslBody: String,
        _ mslBody: String
    ) -> ShaderDefinition {
        ShaderDefinition(
            id: id,
            metalFragmentFunction: fn,
            metalSource: timeShaderMSL(fn, mslBody),
            webGLFragmentSource: timeShaderGLSL(glslBody)
        )
    }
}

func timeShaderGLSL(_ body: String) -> String {
    """
    precision mediump float;

    uniform sampler2D u_image;
    uniform vec2 u_textureSize;
    uniform float u_params[1];

    varying vec4 v_color;
    varying vec2 v_texCoord;

    float hash(vec2 p) {
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
    }

    void main() {
        float TIME = u_params[0];
        float CYCLE = 6.28318530718;
        float STEP = 12.0;
        vec2 FRAG = gl_FragCoord.xy;
        vec2 uv = v_texCoord;
        float mask = 1.0;

    \(body)

        if (u_textureSize.x == 1.0 && u_textureSize.y == 1.0) {
            gl_FragColor = vec4(v_color.xyz, v_color.w * mask);
            return;
        }
        vec4 c = texture2D(u_image, uv);
        if (c.w == 0.0) {
            gl_FragColor = c;
            return;
        }
        gl_FragColor = vec4(c.xyz, v_color.w * mask);
    }
    """
}

func hashMSL(_ arg: String) -> String {
    "fract(sin(dot(\(arg), float2(127.1, 311.7))) * 43758.5453)"
}

func timeShaderMSL(_ name: String, _ body: String) -> String {
    """
    fragment float4 \(name)(RasterizerData in [[stage_in]],
                            texture2d<half> colorMap [[ texture(TextureIndexColor) ]],
                            constant float *u_params [[ buffer(0) ]])
    {
        constexpr sampler smp(mip_filter::nearest,
                              mag_filter::nearest,
                              min_filter::nearest);
        float TIME = u_params[0];
        float CYCLE = 6.28318530718;
        float STEP = 12.0;
        float2 FRAG = in.position.xy;
        float2 uv = in.texCoord.xy;
        float mask = 1.0;

    \(body)

        if (colorMap.get_width() == 1 && colorMap.get_height() == 1) {
            return float4(in.color.xyz, in.color.w * mask);
        }
        half4 c = colorMap.sample(smp, uv);
        if (c.w == 0) {
            return float4(c);
        }
        return float4(float3(c.xyz), in.color.w * mask);
    }

    """
}
