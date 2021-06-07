//
//  CommnShaders.metal
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/06.
//

#include <metal_stdlib>
using namespace metal;

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

float randFloat(float3 init_sheed)
{
    int seed = init_sheed.x + init_sheed.y * 57 + init_sheed.z * 241;
    seed= (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

float4 radialParticle(float4 pos, uint iid, float time) {
    float rand_num = randFloat(float3(iid, iid, iid));
    float4 moved = move(pos, float2(0,time/rand_num*0.1));
    float4 ret = rotatePosition(moved, iid*0.3);
    return ret;
}

float4 flowDownParticle(float4 pos, uint iid, float time) {
    float rand_num = randFloat(float3(iid, iid+1, iid+2));
    float rand_num2 = randFloat(float3(iid+3, iid+4, iid+5));
    float4 rotated = rotatePosition(pos, time*rand_num);
    float4 moved = move(rotated, float2(rand_num*2, rand_num2*10 + -1*abs(time+rand_num2)));
    return moved + float4(-1, -1, 0, 0);
}
