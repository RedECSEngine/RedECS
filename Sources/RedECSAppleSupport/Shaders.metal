/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef enum AAPLVertexInputIndex
{
    AAPLVertexInputIndexVertices     = 0,
    BufferIndexUniforms      = 1,
    TextureCoordinates  = 2
} AAPLVertexInputIndex;

typedef enum TextureIndex
{
    TextureIndexColor = 0
} TextureIndex;

//  This structure defines the layout of vertices sent to the vertex
//  shader. This header is shared between the .metal shader and C code, to guarantee that
//  the layout of the vertex array in the C code matches the layout that the .metal
//  vertex shader expects.
typedef struct
{
    vector_float2 position;
    vector_float4 color;
} AAPLVertex;

typedef struct
{
    vector_float2 texCoord;
    vector_float2 texSize;
} TextureInfo;

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} Uniforms;

// Vertex shader outputs and fragment shader inputs
struct RasterizerData
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];

    // Since this member does not have a special attribute, the rasterizer
    // interpolates its value with the values of the other triangle vertices
    // and then passes the interpolated value to the fragment shader for each
    // fragment in the triangle.
    float4 color;
    
    float2 texCoord;
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant AAPLVertex *vertices [[buffer(AAPLVertexInputIndexVertices)]],
             constant TextureInfo *textureInfo [[buffer(TextureCoordinates)]],
             constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    RasterizerData out;
    float2 pixelSpacePosition = vertices[vertexID].position.xy;

    float4 position = float4(pixelSpacePosition, 0.0, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;

    vector_float2 texCoord = textureInfo[vertexID].texCoord;
    texCoord.y = textureInfo[vertexID].texSize.y - texCoord.y;
    texCoord = texCoord / textureInfo[vertexID].texSize;
    
    out.texCoord = float2(texCoord.x, texCoord.y);
    out.color = vertices[vertexID].color;

    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorMap     [[ texture(TextureIndexColor) ]])
{
    if (colorMap.get_width() == 1 && colorMap.get_height() == 1) {
        return in.color;
    }
    
    constexpr sampler colorSampler(mip_filter::nearest,
                                       mag_filter::nearest,
                                       min_filter::nearest);

    half4 colorSample = colorMap.sample(colorSampler, in.texCoord.xy);
    if(colorSample.w == 0) {
        return float4(colorSample);
    }
    return float4(colorSample.x, colorSample.y, colorSample.z, in.color.w);
}
