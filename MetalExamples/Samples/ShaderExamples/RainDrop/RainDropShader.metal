//
//  SimpleShader.metal
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/05.
//

#include <metal_stdlib>
#include "../../Common/CommonShadersType.h"
using namespace metal;

struct ColorInOut
{
    float4 position [[ position ]];
    float size [[point_size]];
    float2 texCords;
};

fragment float4 rainDropFragmentShader(
                    ColorInOut in [[ stage_in ]],
                    texture2d<float, access::sample> texture [[texture(0)]]) {
    constexpr sampler colorSampler;
        
    float4 color = texture.sample(colorSampler, in.texCords);
    color.r += 0.2;
    
    return color;
}
