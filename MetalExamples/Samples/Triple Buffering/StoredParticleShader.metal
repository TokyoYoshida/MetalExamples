//
//  SimpleShader.metal
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/05.
//

#include <metal_stdlib>
#include "../Common/CommonShadersType.h"
using namespace metal;

struct ColorInOut
{
    float4 position [[ position ]];
    float size [[point_size]];
    float2 texCoords;
};

vertex ColorInOut storedParticleVertexShader(
                        const device Particle *particles [[ buffer(0)]],
                        const device float2 *texCoords [[ buffer(1) ]],
                        constant Uniforms &uniforms [[buffer(2)]],
                        uint vid [[ vertex_id ]]
    ) {
    ColorInOut out;
    
    out.position = float4(0, 0, 0, 1);
    out.position.xy = particles[vid].position;
    out.texCoords = texCoords[vid];
    out.size = 5.0f;
    return out;
}

fragment float4 storedParticleFragmentShader(
                    ColorInOut in [[ stage_in ]],
                    texture2d<float> texture [[ texture(0) ]]
    ){
//    float r = randFloat(float3(iid));
//    float g = randFloat(float3(iid+1, iid+2, iid+3));
//    float b = randFloat(float3(iid+4, iid+5, iid+6));

//    float4 color = sample_color + float4(float3(r, g, b)*l,1);
    return float4(1,0,0,1);
}
