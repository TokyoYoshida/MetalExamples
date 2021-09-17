//
//  MetalView.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/04.
//

import SwiftUI
import MetalKit

struct MultiPassRenderingMetalView: UIViewRepresentable {
    let mtkView = MTKView()
    typealias UIViewType = MTKView
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: Context) -> MTKView {
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
//        mtkView.enableSetNeedsDisplay = true
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        return mtkView
    }
    func updateUIView(_ uiView: MTKView, context: Context) {
    }
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: MultiPassRenderingMetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var renderPipeline: MTLRenderPipelineState!
        var texture: MTLTexture!
        var vertextBuffer: MTLBuffer!
        let vertexData: [Float] = [
            -1, -1, 0, 1,
             1, -1, 0, 1,
            -1,  1, 0, 1,
             1,  1, 0, 1,
        ]
        var offscreenRenderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
        var pixcelFormat:MTLPixelFormat {
            parent.mtkView.colorPixelFormat
        }
        var size: CGSize {
            parent.mtkView.drawableSize
        }
        
        init(_ parent: MultiPassRenderingMetalView) {
            func buildTexture() -> MTLTexture {
                let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixcelFormat , width: Int(size.width), height: Int(size.height), mipmapped: false)
                descriptor.usage = [.shaderRead, .renderTarget]
                descriptor.storageMode = .private
                guard let texture = metalDevice.makeTexture(descriptor: descriptor) else {
                    fatalError()
                }
                return texture
            }
            func buildOffscreenRenderPass() {
                
//                offscreenRenderPassDescriptor.colorAttachments[0].texture
            }
            func buildPipeline() {
                guard let library = self.metalDevice.makeDefaultLibrary() else {fatalError()}
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
                descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
                renderPipeline = try! self.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            }
            func buildBuffers() {
                let size = vertexData.count * MemoryLayout<Float>.size
                vertextBuffer = self.metalDevice.makeBuffer(bytes: vertexData, length: size)
            }
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
            buildPipeline()
            buildBuffers()
            loadTexture(self.metalDevice)
        }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = parent.mtkView.currentRenderPassDescriptor
            else {return}
            
            let commandBuffer = metalCommandQueue.makeCommandBuffer()!
            
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

            guard let renderPipeline = renderPipeline else {fatalError()}

            
            renderEncoder.setRenderPipelineState(renderPipeline)
            renderEncoder.setVertexBuffer(vertextBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            
            commandBuffer.commit()
            
            commandBuffer.waitUntilCompleted()
        }
    }
}
