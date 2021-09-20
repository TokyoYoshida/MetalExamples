//
//  MetalView.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/04.
//

import SwiftUI
import MetalKit

final class MultiPassRenderingMetalView: UIViewRepresentable {
    let frame: CGRect
    let mtkView = MTKView()
    typealias UIViewType = MTKView
    var coordinator: Coordinator!
    
    init(frame: CGRect) {
        self.frame = frame
    }
    
    func makeCoordinator() -> Coordinator {
        self.coordinator = Coordinator(self)
        return coordinator
    }
    func makeUIView(context: Context) -> MTKView {
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = frame.size
//        mtkView.enableSetNeedsDisplay = true
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        coordinator.prepare()
        return mtkView
    }
    func updateUIView(_ uiView: MTKView, context: Context) {
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: MultiPassRenderingMetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var offScreenRenderPipeline: MTLRenderPipelineState!
        var onScreenRenderPipeline: MTLRenderPipelineState!
        var texture: MTLTexture!
        var vertextBuffer: MTLBuffer!
        let vertexData: [Float] = [
            -1, -1, 0, 1,
             1, -1, 0, 1,
            -1,  1, 0, 1,
             1,  1, 0, 1,
        ]
        var offScreenRenderPassDescriptor: MTLRenderPassDescriptor?
        var pixcelFormat:MTLPixelFormat {
            parent.mtkView.colorPixelFormat
        }
        var size: CGSize {
            parent.mtkView.drawableSize
        }
        
        init(_ parent: MultiPassRenderingMetalView) {
            func buildOffscreenRenderPipeline() {
                guard let library = self.metalDevice.makeDefaultLibrary() else {fatalError()}
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
                descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
                offScreenRenderPipeline = try! self.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            }
            func buildScreenRenderPipeline() {
                guard let library = self.metalDevice.makeDefaultLibrary() else {fatalError()}
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
                descriptor.fragmentFunction = library.makeFunction(name: "redFilterFragmentShader")
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
                onScreenRenderPipeline = try! self.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            }
            func buildBuffers() {
                let size = vertexData.count * MemoryLayout<Float>.size
                vertextBuffer = self.metalDevice.makeBuffer(bytes: vertexData, length: size)
            }
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
            buildOffscreenRenderPipeline()
            buildScreenRenderPipeline()
            buildBuffers()
        }
        func prepare() {
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
                texture = buildTexture()
                offScreenRenderPassDescriptor = MTLRenderPassDescriptor()
                offScreenRenderPassDescriptor?.colorAttachments[0].texture = texture
                offScreenRenderPassDescriptor?.renderTargetWidth = Int(size.width)
                offScreenRenderPassDescriptor?.renderTargetHeight = Int(size.height)
            }
            buildOffscreenRenderPass()
        }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let offScreenRenderPassDescriptor = self.offScreenRenderPassDescriptor,
                  let onScreenRenderPassDescriptor = parent.mtkView.currentRenderPassDescriptor

            else {return}
            let commandBuffer = metalCommandQueue.makeCommandBuffer()!

            func doOffScreenRender() {
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: offScreenRenderPassDescriptor)!

                guard let renderPipeline = offScreenRenderPipeline else {fatalError()}
                
                renderEncoder.setRenderPipelineState(renderPipeline)
                renderEncoder.setVertexBuffer(vertextBuffer, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

                renderEncoder.endEncoding()
            }
            func doOnScreenRender() {
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: onScreenRenderPassDescriptor)!

                guard let renderPipeline = onScreenRenderPipeline else {fatalError()}
                
                renderEncoder.setRenderPipelineState(renderPipeline)
                renderEncoder.setVertexBuffer(vertextBuffer, offset: 0, index: 0)
                renderEncoder.setFragmentTexture(texture, index: 0)
                renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

                renderEncoder.endEncoding()
                
                commandBuffer.present(drawable)
                
                commandBuffer.commit()
                
                commandBuffer.waitUntilCompleted()
            }
            doOffScreenRender()
            doOnScreenRender()
        }
    }
}
