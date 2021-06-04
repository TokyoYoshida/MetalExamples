//
//  MetalView.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/04.
//

import SwiftUI
import MetalKit

struct PersistentObjectsMetalView: UIViewRepresentable {
    typealias UIViewType = MTKView
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        return mtkView
    }
    func updateUIView(_ uiView: MTKView, context: Context) {
    }
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: PersistentObjectsMetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var texture: MTLTexture!

        init(_ parent: PersistentObjectsMetalView) {
            func loadTexture(_ device: MTLDevice) {
                let textureLoader = MTKTextureLoader(device: device)
                texture = try! textureLoader.newTexture(name: "sample_picture", scaleFactor: 1, bundle: nil)
            }
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
            loadTexture(self.metalDevice)
        }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable else {return}
            
            let commandBuffer = metalCommandQueue.makeCommandBuffer()!
         
            let w = min(texture.width, drawable.texture.width)
            let h = min(texture.height, drawable.texture.height)
            
            let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
            
            blitEncoder.copy(from: texture,
                              sourceSlice: 0,
                              sourceLevel: 0,
                              sourceOrigin: MTLOrigin(x:0, y:0 ,z:0),
                              sourceSize: MTLSizeMake(w, h, texture.depth),
                              to: drawable.texture,
                              destinationSlice: 0,
                              destinationLevel: 0,
                              destinationOrigin: MTLOrigin(x:0, y:0 ,z:0))
            
            blitEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            
            commandBuffer.commit()
        }
    }
}
