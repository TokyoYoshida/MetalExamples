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
    float2 texCords;
};

vertex ColorInOut simpleVertexShader(
                        const device Particle *particles [[ buffer(0)]],
                        const device float2 *texCords  [[ buffer(1)]],
                        constant Uniforms &uniforms [[buffer(2)]],
                        uint vid [[ vertex_id ]]
    ) {
    ColorInOut out;
    
    out.position = float4(0, 0, 0, 1);
    out.position.xy = particles[vid].position;
    out.size = 5.0f;
    out.texCords = texCords[vid];
    return out;
}

fragment float4 simpleFragmentShader(
                    ColorInOut in [[ stage_in ]],
                    texture2d<float, access::sample> texture [[texture(0)]]) {
    constexpr sampler colorSampler;
        
    float4 color = texture.sample(colorSampler, in.texCords);
    
    return color;
}
