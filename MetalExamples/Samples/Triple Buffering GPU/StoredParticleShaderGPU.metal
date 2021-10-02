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
                          texture2d<float, access::read>  inTexture  [[ texture(0) ]],
                          texture2d<float, access::write> outTexture [[ texture(1) ]],
                          uint2 gid [[ thread_position_in_grid ]]
                          )
{
    float4 inColor = inTexture.read(gid);
    outTexture.write(inColor, gid);
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
