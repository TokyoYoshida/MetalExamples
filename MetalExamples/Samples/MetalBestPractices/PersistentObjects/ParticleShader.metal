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
    float2 texCoords;
    uint instanceId;
};

vertex ColorInOut persistentObjectsVertexShader(
                        const device float4 *positions [[ buffer(0)]],
                        const device float2 *texCoords [[ buffer(1) ]],
                        constant Uniforms &uniforms [[buffer(2)]],
                        uint vid [[ vertex_id ]],
                        uint iid [[ instance_id ]]
    ) {
    ColorInOut out;
    
    float t = uniforms.time;
    float4 pos =  positions[vid];
    float4 converted = flowDownParticle(pos, iid, t);
    out.position = converted;
    out.texCoords = texCoords[vid];
    out.instanceId = iid;
    return out;
}

fragment float4 persistentObjectsFragmentShader(
                    ColorInOut in [[ stage_in ]],
                    texture2d<float> texture [[ texture(0) ]]
    ){
    constexpr sampler colorSampler;
    uint iid = in.instanceId;
    float2 p = ((in.texCoords.xy * 2) - 1)*float2(1,-1);
    float2 converted = p;
    float4 sample_color = texture.sample(colorSampler, in.texCoords);
    float l = 1.0 - step(0, heart2(converted*1.3));
    if(l == 0){
        discard_fragment();
    }
    float r = randFloat(float3(iid, iid, iid));
    float g = randFloat(float3(iid+1, iid+2, iid+3));
    float b = randFloat(float3(iid+4, iid+5, iid+6));

    float4 color = sample_color + float4(float3(r, g, b)*l,1);
    return color;
}
