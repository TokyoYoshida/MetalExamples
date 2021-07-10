//
//  SimpleShaderType.h
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/05.
//

#ifndef ParticleShaderType
#define ParticleShaderType


#endif /* ParticleShaderType */

#include <simd/simd.h>

struct Uniforms {
    float time;
    float aspectRatio;
    vector_float2 touch;
    vector_float4 resolution;
};

struct Particle {
    vector_float2 position;
};


float heart2(vector_float2 p);
vector_float4 rotatePosition(vector_float4 pos, float theta);
vector_float4 move(vector_float4 pos, vector_float2 step);
float randFloat(vector_float3 init_sheed);
vector_float4 radialParticle(vector_float4 pos, uint iid, float time);
vector_float4 flowDownParticle(vector_float4 pos, uint iid, float time);
