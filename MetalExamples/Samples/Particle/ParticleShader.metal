//
//  SimpleShader.metal
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/05.
//

#include <metal_stdlib>
#include "../Common/CommonShaderType.h"
using namespace metal;

struct ColorInOut
{
    float4 position [[ position ]];
    float2 texCoords;
    uint instanceId;
};

float heart2(float2 p){
 return pow(p.x*p.x+p.y*p.y-1.,3.)-p.x*p.x*p.y*p.y*p.y;
}

float4 rotatePosition(float4 pos, float theta) {
    float nx = pos.x * cos(theta) - pos.y * sin(theta);
    float ny = pos.x * sin(theta) + pos.y * cos(theta);
    return float4(nx, ny, pos.z, pos.w);
}

float4 move(float4 pos, float2 step) {
    float nx = pos.x + step.x;
    float ny = pos.y + step.y;
    return float4(nx, ny, pos.z, pos.w);
}

float rand(float3 init_sheed)
{
    int seed = init_sheed.x + init_sheed.y * 57 + init_sheed.z * 241;
    seed= (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

float4 radialParticle(float4 pos, uint iid, float time) {
    float rand_num = rand(float3(iid, iid, iid));
    float4 moved = move(pos, float2(0,time/rand_num*0.1));
    float4 ret = rotatePosition(moved, iid*0.3);
    return ret;
}

float4 flowDownParticle(float4 pos, uint iid, float time) {
    float rand_num = rand(float3(iid, iid+1, iid+2));
    float rand_num2 = rand(float3(iid+3, iid+4, iid+5));
    float4 rotated = rotatePosition(pos, time*rand_num);
    float4 moved = move(rotated, float2(rand_num*2, rand_num2*10 + -1*abs(time+rand_num2)));
    return moved + float4(-1, -1, 0, 0);
}

vertex ColorInOut vertexShader5(
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

fragment float4 fragmentShader6(
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
    float r = rand(float3(iid, iid, iid));
    float g = rand(float3(iid+1, iid+2, iid+3));
    float b = rand(float3(iid+4, iid+5, iid+6));

    float4 color = sample_color + float4(float3(r, g, b)*l,1);
    return color;
}
