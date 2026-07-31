// Stable string key identifying a shader *program*; both backends look up their
// pipeline/program by this. Expressible by a string literal so `"monochrome"`
// stands in for a registered program id.
public struct ShaderId: Hashable, Sendable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    // Built-in program ids.
    public static let passthrough = ShaderId(rawValue: "passthrough") // default: texture RGB as-is
    public static let tint = ShaderId(rawValue: "tint")               // multiply texel by a color
    public static let paletteRemap = ShaderId(rawValue: "paletteRemap") // swap specific source colors

    public static let ripple = ShaderId(rawValue: "ripple")
    public static let waves = ShaderId(rawValue: "waves")
    public static let liquid = ShaderId(rawValue: "liquid")
    public static let turnOff = ShaderId(rawValue: "turnOff")
    public static let splitRows = ShaderId(rawValue: "splitRows")
    public static let splitCols = ShaderId(rawValue: "splitCols")
    public static let shaky = ShaderId(rawValue: "shaky")
    public static let shakyTiles = ShaderId(rawValue: "shakyTiles")
    public static let shuffle = ShaderId(rawValue: "shuffle")
}

// The per-sprite fragment effect a sprite/RenderGroup carries: which program
// draws it, plus that program's parameters as data. A `nil` shader (see
// SpriteComponent/RenderGroup) means passthrough. The program's *behaviour*
// (source, compilation) lives in ShaderRegistry, keyed by `programId`.
public enum ShaderEffect: Equatable, Codable, Sendable {
    case tint(Color)                       // multiply texel by a colour
    case paletteRemap([ColorKey])          // swap specific source colours
    case custom(ShaderId, params: [Float]) // game-registered program + raw u_params

    case ripple(time: Double)
    case waves(time: Double)
    case liquid(time: Double)
    case turnOff(time: Double)
    case splitRows(time: Double)
    case splitCols(time: Double)
    case shaky(time: Double)
    case shakyTiles(time: Double)
    case shuffle(time: Double)

    // One source→destination colour substitution for paletteRemap.
    public struct ColorKey: Equatable, Codable, Sendable {
        public var from: Color
        public var to: Color
        public init(from: Color, to: Color) {
            self.from = from
            self.to = to
        }
    }

    // Which compiled program draws this effect — the pipeline/program lookup key.
    public var programId: ShaderId {
        switch self {
        case .tint:              return .tint
        case .paletteRemap:      return .paletteRemap
        case .custom(let id, _): return id
        case .ripple:            return .ripple
        case .waves:             return .waves
        case .liquid:            return .liquid
        case .turnOff:           return .turnOff
        case .splitRows:         return .splitRows
        case .splitCols:         return .splitCols
        case .shaky:             return .shaky
        case .shakyTiles:        return .shakyTiles
        case .shuffle:           return .shuffle
        }
    }

    // Packs this effect's parameters into the flat u_params float uniform both
    // backends bind. A custom effect passes its floats through verbatim.
    public func encodeUniforms() -> [Float] {
        switch self {
        case .tint(let c):
            return [Float(c.red), Float(c.green), Float(c.blue), Float(c.alpha)]
        case .paletteRemap(let keys):
            let keys = keys.prefix(ShaderRegistry.paletteRemapMaxKeys) // GLSL can't index past its array
            var out: [Float] = [Float(keys.count)]
            for key in keys {
                out.append(contentsOf: [
                    Float(key.from.red), Float(key.from.green), Float(key.from.blue),
                    Float(key.to.red), Float(key.to.green), Float(key.to.blue)
                ])
            }
            return out
        case .custom(_, let params):
            return params
        case .ripple(let t), .waves(let t), .liquid(let t), .turnOff(let t),
             .splitRows(let t), .splitCols(let t), .shaky(let t),
             .shakyTiles(let t), .shuffle(let t):
            return [Float(t)]
        }
    }
}

// A registered shader *program*: its id and both platform implementations.
// Parameter packing lives on ShaderEffect.encodeUniforms(), not here.
public struct ShaderDefinition: Sendable {
    public let id: ShaderId
    public let metalFragmentFunction: String // function name in the compiled Metal library
    public let metalSource: String           // MSL appended to the base source (empty = already in base)
    public let webGLFragmentSource: String   // full GLSL ES 1.0 fragment shader

    public init(
        id: ShaderId,
        metalFragmentFunction: String,
        metalSource: String,
        webGLFragmentSource: String
    ) {
        self.id = id
        self.metalFragmentFunction = metalFragmentFunction
        self.metalSource = metalSource
        self.webGLFragmentSource = webGLFragmentSource
    }
}

// The set of shaders a renderer builds pipelines/programs from. Starts with the
// builtins; games register extra effects before renderer construction.
public final class ShaderRegistry {
    public private(set) var definitions: [ShaderId: ShaderDefinition]

    public init(_ defs: [ShaderDefinition] = ShaderRegistry.builtins) {
        definitions = Dictionary(uniqueKeysWithValues: defs.map { ($0.id, $0) })
    }

    // Add or replace a shader by id.
    public func register(_ definition: ShaderDefinition) {
        definitions[definition.id] = definition
    }

    public subscript(_ id: ShaderId) -> ShaderDefinition? {
        definitions[id]
    }

    // Deterministic order for building pipelines and concatenating Metal source.
    public var ordered: [ShaderDefinition] {
        definitions.values.sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public static let builtins: [ShaderDefinition] = [
        passthroughDefinition,
        tintDefinition,
        paletteRemapDefinition
    ] + timeShaderDefinitions
}

public extension ShaderRegistry {
    // Upper bound on remap pairs; must match the GLSL loop/array size below.
    static let paletteRemapMaxKeys = 16

    // Passthrough: the base fragmentShader already in the base source; no uniforms.
    static let passthroughDefinition = ShaderDefinition(
        id: .passthrough,
        metalFragmentFunction: "fragmentShader",
        metalSource: "",
        webGLFragmentSource: passthroughWebGLSource
    )

    // Tint: multiplies the texel by a colour (packed by ShaderEffect.encodeUniforms).
    static let tintDefinition = ShaderDefinition(
        id: .tint,
        metalFragmentFunction: "tintFragment",
        metalSource: tintMetalSource,
        webGLFragmentSource: tintWebGLSource
    )

    // Palette remap: swaps [count, from.rgb, to.rgb, ...] source colours.
    static let paletteRemapDefinition = ShaderDefinition(
        id: .paletteRemap,
        metalFragmentFunction: "paletteRemapFragment",
        metalSource: paletteRemapMetalSource,
        webGLFragmentSource: paletteRemapWebGLSource
    )
}

// Passthrough GLSL: 1x1 texture means a solid-colour draw, otherwise texture RGB
// with the vertex-colour alpha (the engine's original textured-sprite behaviour).
private let passthroughWebGLSource = """
precision mediump float;

uniform sampler2D u_image;
uniform vec2 u_textureSize;

varying vec4 v_color;
varying vec2 v_texCoord;

void main() {
    if (u_textureSize.x == 1.0 && u_textureSize.y == 1.0) {
        gl_FragColor = v_color;
    } else {
        vec4 color = texture2D(u_image, v_texCoord);
        if(color.w == 0.0) {
            gl_FragColor = color;
        } else {
            gl_FragColor = vec4(color.xyz, v_color.w);
        }
    }
}
"""

// Tint GLSL: multiply texel RGB by the tint colour; alpha convention unchanged so
// white text stays pixel-identical to passthrough.
private let tintWebGLSource = """
precision mediump float;

uniform sampler2D u_image;
uniform vec2 u_textureSize;
uniform float u_params[4];

varying vec4 v_color;
varying vec2 v_texCoord;

void main() {
    vec4 color = texture2D(u_image, v_texCoord);
    if (color.w == 0.0) {
        gl_FragColor = color;
    } else {
        vec3 tint = vec3(u_params[0], u_params[1], u_params[2]);
        gl_FragColor = vec4(color.xyz * tint, v_color.w);
    }
}
"""

// Palette-remap GLSL: for each key, replace texels matching from.rgb with to.rgb.
// Fixed loop bound + array size are required by WebGL1.
private let paletteRemapWebGLSource = """
precision mediump float;

uniform sampler2D u_image;
uniform vec2 u_textureSize;
uniform float u_params[97];

varying vec4 v_color;
varying vec2 v_texCoord;

const int MAX_KEYS = 16;

void main() {
    vec4 color = texture2D(u_image, v_texCoord);
    if (color.w == 0.0) {
        gl_FragColor = color;
        return;
    }
    vec3 rgb = color.xyz;
    int count = int(u_params[0]);
    for (int i = 0; i < MAX_KEYS; i++) {
        if (i >= count) { break; }
        int base = 1 + i * 6;
        vec3 from = vec3(u_params[base], u_params[base + 1], u_params[base + 2]);
        vec3 to = vec3(u_params[base + 3], u_params[base + 4], u_params[base + 5]);
        if (distance(color.xyz, from) < 0.02) {
            rgb = to;
        }
    }
    gl_FragColor = vec4(rgb, v_color.w);
}
"""

// Metal counterpart of the tint shader; reads RasterizerData/TextureIndexColor
// from the base source it's concatenated into.
private let tintMetalSource = """
fragment float4 tintFragment(RasterizerData in [[stage_in]],
                             texture2d<half> colorMap [[ texture(TextureIndexColor) ]],
                             constant float *u_params [[ buffer(0) ]])
{
    constexpr sampler colorSampler(mip_filter::nearest,
                                   mag_filter::nearest,
                                   min_filter::nearest);
    half4 colorSample = colorMap.sample(colorSampler, in.texCoord.xy);
    if (colorSample.w == 0) {
        return float4(colorSample);
    }
    float3 tint = float3(u_params[0], u_params[1], u_params[2]);
    return float4(float3(colorSample.xyz) * tint, in.color.w);
}
"""

// Metal counterpart of the palette-remap shader; Metal allows the dynamic loop
// bound and indexing that WebGL1 does not.
private let paletteRemapMetalSource = """
fragment float4 paletteRemapFragment(RasterizerData in [[stage_in]],
                                     texture2d<half> colorMap [[ texture(TextureIndexColor) ]],
                                     constant float *u_params [[ buffer(0) ]])
{
    constexpr sampler colorSampler(mip_filter::nearest,
                                   mag_filter::nearest,
                                   min_filter::nearest);
    half4 colorSample = colorMap.sample(colorSampler, in.texCoord.xy);
    if (colorSample.w == 0) {
        return float4(colorSample);
    }
    float3 rgb = float3(colorSample.xyz);
    int count = int(u_params[0]);
    for (int i = 0; i < count; i++) {
        int base = 1 + i * 6;
        float3 from = float3(u_params[base], u_params[base + 1], u_params[base + 2]);
        float3 to = float3(u_params[base + 3], u_params[base + 4], u_params[base + 5]);
        if (distance(rgb, from) < 0.02) {
            rgb = to;
        }
    }
    return float4(rgb, in.color.w);
}
"""
