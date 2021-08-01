//
//  Matrix.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/01/28.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import Foundation
import simd

func radians(fromDegrees degrees: Float) -> Float {
    return Float(Double(degrees / 180) * M_PI)
}

class Matrix {
    static func perspective(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
        let ys = 1 / tanf(fovyRadians * 0.5)
        let xs = ys / aspect
        let zs = farZ / (nearZ - farZ)
        return matrix_float4x4(columns: (vector_float4(xs, 0, 0, 0),
                                         vector_float4(0, ys, 0, 0),
                                         vector_float4(0, 0, zs, -1),
                                         vector_float4(0, 0, zs * nearZ, 0)))
    }
    
    static func lookAt(eye: float3, center: float3, up: float3) -> matrix_float4x4 {
        let z = normalize(eye - center)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        let t = float3(-dot(x, eye), -dot(y, eye), -dot(z, eye))
        return matrix_float4x4(columns: (vector_float4(x.x, y.x, z.x, 0),
                                         vector_float4(x.y, y.y, z.y, 0),
                                         vector_float4(x.z, y.z, z.z, 0),
                                         vector_float4(t.x, t.y, t.z, 1)))
    }
    
    static func rotation(radians: Float, axis: float3) -> matrix_float4x4 {
        let normalizeAxis = normalize(axis)
        let ct = cosf(radians)
        let st = sinf(radians)
        let ci = 1 - ct
        let x = normalizeAxis.x
        let y = normalizeAxis.y
        let z = normalizeAxis.z
        return matrix_float4x4(columns: (
            vector_float4(ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
            vector_float4(x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st, 0),
            vector_float4(x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci, 0),
            vector_float4(0, 0, 0, 1)))
    }
    
    static func scale(x: Float, y: Float, z: Float) -> matrix_float4x4 {
        return matrix_float4x4(columns: (vector_float4(x, 0, 0, 0),
                                         vector_float4(0, y, 0, 0),
                                         vector_float4(0, 0, z, 0),
                                         vector_float4(0, 0, 0, 1)))
    }

    static func translation(x: Float, y: Float, z: Float) -> matrix_float4x4 {
        return matrix_float4x4(columns: (vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(x, y, z, 1)))
    }
    
    static func toUpperLeft3x3(from4x4 m: matrix_float4x4) -> matrix_float3x3 {
        let x = m.columns.0
        let y = m.columns.1
        let z = m.columns.2
        
        return matrix_float3x3(columns: (vector_float3(x.x, x.y, x.z),
                                         vector_float3(y.x, y.y, y.z),
                                         vector_float3(z.x, z.y, z.z)))
    }
}
