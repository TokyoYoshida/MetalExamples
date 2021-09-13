//
//  SimpleShader.metal
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/05.
//

#include <metal_stdlib>
#include "../../Common/CommonShadersType.h"
using namespace metal;

#define S(a, b, t) smoothstep(a, b, t)

struct ColorInOut
{
    float4 position [[ position ]];
    float size [[point_size]];
    float2 texCords;
};

fragment float4 simpleShapeFragmentShader(
                    ColorInOut in [[ stage_in ]]) {
    return float4(1,0,0,1);
}
