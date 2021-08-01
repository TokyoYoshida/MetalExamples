//
//  ShadersFor3D.metal
//  MetalTest
//
//  Created by TokyoYoshida on 2021/01/17.
//  Copyright © 2021 TokyoMac. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#define lightDirection float3(1, -4, -5)

struct VertexInput2 {
    float3      position    [[ attribute(0) ]]; // モデルの頂点の位置
    float3      normal      [[ attribute(1) ]]; // 法線マップ（＝ノーマルマップ）
    float2      texcoord    [[ attribute(2) ]]; // テクスチャ座標
};

struct VertexUniforms2 {
    float4x4    projectionViewMatrix; // 透視投影法の行列
    float3x3    normalMatrix; // 法線マップ用の行列
};

struct VertexOut2 {
    float4      position    [[ position ]];
    float3      normal;
    float2      texcoord;
};

vertex VertexOut2 lambertVertex2(VertexInput2 in [[ stage_in ]],
                               constant VertexUniforms2& uniforms [[ buffer(1) ]]) {
    VertexOut2 out;
    out.position = uniforms.projectionViewMatrix * float4(in.position, 1);
    out.texcoord = float2(in.texcoord.x, in.texcoord.y);
    out.normal = uniforms.normalMatrix * in.normal;
    return out;
}

fragment half4 lambertFragment2(VertexOut2 in [[ stage_in ]]) {
    float diffuseFactor = saturate(dot(in.normal, -lightDirection));
    return half4(diffuseFactor);
}
