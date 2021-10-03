//
//  SimpleShader.metal
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/05.
//

#include <metal_stdlib>
#include "../Common/CommonShadersType.h"
using namespace metal;

struct ICBContainer {
  command_buffer icb [[id(0)]];
};

struct ColorInOut
{
    float4 position [[ position ]];
    float size [[point_size]];
};

kernel void particleComputeICBShader(
            device ICBContainer *icbContainer [[buffer(0)]]
){
}

vertex ColorInOut indirectBuffersVertexShader(
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

fragment float4 indirectBuffersFragmentShader(
                    ColorInOut in [[ stage_in ]]
    ){
    return float4(0,0,1,1);
}
