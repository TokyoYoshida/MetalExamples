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
};

kernel void particleComputeShader(
                          device Particle *beforeParticles [[ buffer(0)]],
                          device Particle *particles [[ buffer(1)]],
                          const uint gid [[ thread_position_in_grid ]]
                          )
{
    float2 position = particles[gid].position;
    particles[gid].position.x = beforeParticles[gid].position.x + 0.1;
}

vertex ColorInOut storedParticleVertexGPUShader(
                        const device Particle *particles [[ buffer(0)]],
                        constant Uniforms &uniforms [[buffer(2)]],
                        uint vid [[ vertex_id ]]
    ) {
    ColorInOut out;
    
    out.position = float4(0, 0, 0, 1);
    out.position.xy = particles[vid].position;
    out.size = 5.0f;
    return out;
}

fragment float4 storedParticleFragmentGPUShader(
                    ColorInOut in [[ stage_in ]]
    ){
    return float4(0,0,1,1);
}
