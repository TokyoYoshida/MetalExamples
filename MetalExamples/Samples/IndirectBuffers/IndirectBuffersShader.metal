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

struct PipelineStateContainer {
    render_pipeline_state pipelineState;
};

struct ColorInOut
{
    float4 position [[ position ]];
    float size [[point_size]];
};

kernel void particleComputeICBShader(
                        device Particle *beforeParticles [[ buffer(0)]],
                        device Particle *particles [[ buffer(1)]],
                        const device int *numberOfParticles [[ buffer(2)]],
                        const device PipelineStateContainer *pipelineStateContaner [[ buffer(3)]],
                        device ICBContainer *icbContainer [[buffer(4)]],
                        uint gid [[thread_position_in_grid]]
){
    
    if (gid < uint(*numberOfParticles)) {
        render_command cmd(icbContainer->icb, gid);
        cmd.set_render_pipeline_state(pipelineStateContaner->pipelineState);
        cmd.set_vertex_buffer(particles, 0);
        cmd.draw_primitives(primitive_type::point, 0, 1, 1);
    }
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
