//
//  SimpleShader.metal
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/05.
//

#include <metal_stdlib>
#include "SimpleShaderType.h"
using namespace metal;

vertex ColorInOut vertexShader(device float4 *positions [[ buffer(0 )]],
                               uint           vid       [[ vertex_id ]]) {
    ColorInOut out;
    out.position = positions[vid];
    return out;
}

fragment float4 fragmentShader(ColorInOut in [[ stage_in ]]) {
    return float4(1,0,0,1);
}
