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

bool inCircle(float2 position, float2 offset, float size) {
    float len = length(position - offset);
    if (len < size) {
        return true;
    }
    return false;
}

bool inRect(float2 position, float2 offset, float size) {
    float2 q = (position - offset) / size;
    if (abs(q.x) < 1.0 && abs(q.y) < 1.0) {
        return true;
    }
    return false;
}

bool inEllipse(float2 position, float2 offset, float2 prop, float size) {
    float2 q = (position - offset) / prop;
    if (length(q) < size) {
        return true;
    }
    return false;
}

fragment float4 simpleShapeFragmentShader(
                    ColorInOut in [[ stage_in ]],
                    constant Uniforms &uniforms [[buffer(1)]]) {
    float3 destColor = float3(1.0, 1.0, 1.0);
    float2 position = (in.position.xy * 2.0 - uniforms.resolution.xy) / min(uniforms.resolution.x, uniforms.resolution.y);

    if (inCircle (position, float2( 0.1, -0.1), 0.5)) {
        destColor *= float3(1.0, 0.0, 0.0);
    }

    if (inRect(position, float2(0.5, -0.5), 0.25)) {
        destColor *= float3(0.0, 0.0, 1.0);
    }
    if (inEllipse(position, float2(-0.5, -0.5), float2(1.0, 1.0), 0.3)) {
        destColor *= float3(0.0, 1.0, 0.0);
    }
    
    return float4(destColor, 1);
}
