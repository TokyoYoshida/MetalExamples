//
//  MTLTexture+Ext.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/05/24.
//

import MetalKit

extension CVPixelBuffer {
    func createTexture(pixelFormat: MTLPixelFormat, planeIndex: Int, capturedImageTextureCache: CVMetalTextureCache) -> MTLTexture? {
        var mtlTexture: MTLTexture? = nil
        let width = CVPixelBufferGetWidthOfPlane(self, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(self, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, capturedImageTextureCache, self, nil, pixelFormat, width, height, planeIndex, &texture)
        if status == kCVReturnSuccess {
            mtlTexture = CVMetalTextureGetTexture(texture!)
        }
        
        return mtlTexture
    }
}
