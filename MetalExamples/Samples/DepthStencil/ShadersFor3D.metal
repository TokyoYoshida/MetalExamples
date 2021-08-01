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

struct VertexInput3 {
    float3      position    [[ attribute(0) ]]; // モデルの頂点の位置
    float3      normal      [[ attribute(1) ]]; // 法線マップ（＝ノーマルマップ）
    float2      texcoord    [[ attribute(2) ]]; // テクスチャ座標
};

struct VertexOut3D {
    float4 position [[position]];
    float3 worldNormal;
    float3 worldPosition;
    float2 texCoords;
};

struct Uniforms3D {
    float4x4 modelMatrix;
    float4x4 viewProjectionMatrix;
    float3x3 normalMatrix;
};

vertex VertexOut3D lambertVertex3(VertexInput3 in [[ stage_in ]],
                               constant Uniforms3D& uniforms [[ buffer(1) ]]) {
    float4 worldPosition = uniforms.modelMatrix * float4(in.position, 1);
    VertexOut3D vertexOut;
    vertexOut.position = uniforms.viewProjectionMatrix * worldPosition;
    vertexOut.worldPosition = worldPosition.xyz;
    vertexOut.worldNormal = uniforms.normalMatrix * in.normal;
    vertexOut.texCoords = in.texcoord;
    return vertexOut;
}

constant float3 ambientIntensity = 0.1;
constant float3 lightPosition(2, 2, 2);
constant float3 lightColor(1, 1, 1);
constant float3 baseColor(1.0, 0, 0);

fragment float4 fragment_main(VertexOut3D fragmentIn [[stage_in]]) {
    float3 N = normalize(fragmentIn.worldNormal.xyz);
    float3 L = normalize(lightPosition - fragmentIn.worldPosition.xyz);
    float3 diffuseIntensity = saturate(dot(N, L));
    float3 finalColor = saturate(ambientIntensity + diffuseIntensity) * lightColor * baseColor;
    return float4(finalColor, 1);
}
