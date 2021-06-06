//
//  SimpleShader.metal
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/05.
//

#include <metal_stdlib>
#include "ParticleShaderType.h"
using namespace metal;

vertex ColorInOut1 vertexShader1(
        const device float4 *positions [[ buffer(0 )]],
        uint vid [[ vertex_id ]]
    ) {
    ColorInOut1 out;
    out.position = positions[vid];
    return out;
}

fragment float4 fragmentShader1(ColorInOut1 in [[ stage_in ]]) {
    return float4(1,0,0,1);
}
