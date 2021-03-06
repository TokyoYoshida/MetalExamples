//
//  MetalView.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/04.
//

import SwiftUI
import MetalKit

struct TripleBufferingMetalViewGPU: UIViewRepresentable {
    typealias UIViewType = MTKView
    let mtkView = MTKView()

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
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        return mtkView
    }
    func updateUIView(_ uiView: MTKView, context: Context) {
    }
    class Coordinator : NSObject, MTKViewDelegate {
        static var numberOfParticles:Int = 100_000
        static let maxBuffers = 3
        var parent: TripleBufferingMetalViewGPU
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var renderPipeline: MTLRenderPipelineState!
        var particleBuffers:[MTLBuffer] = []
        var renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
        var uniforms: Uniforms!
        var preferredFramesTime: Float!
        let computeSemaphore = DispatchSemaphore(value: Coordinator.maxBuffers)
        let renderSemaphore = DispatchSemaphore(value: Coordinator.maxBuffers)
        var currentBufferIndex = 0
        var beforeBufferIndex: Int {
            currentBufferIndex == 0 ? Coordinator.maxBuffers - 1 : currentBufferIndex - 1
        }
        var threadgroupsPerGrid: MTLSize!
        var threadsPerThreadgroup: MTLSize!
        lazy var computeShaderExecuter = ComputeShaderExecuter(device: self.metalDevice, computeShaderName: "particleComputeShader", numberOfParticles: Coordinator.numberOfParticles, maxBuffers: Coordinator.maxBuffers)

        init(_ parent: TripleBufferingMetalViewGPU) {
            func buildRenderPipeline() {
                guard let library = self.metalDevice.makeDefaultLibrary() else {fatalError()}
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = library.makeFunction(name: "storedParticleVertexShader")
                descriptor.fragmentFunction = library.makeFunction(name: "storedParticleFragmentShader")
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
                renderPipeline = try! self.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            }
            func initUniform() {
                uniforms = Uniforms(time: Float(0.0), aspectRatio: Float(0.0), touch: SIMD2<Float>(), resolution: SIMD4<Float>())
                uniforms.aspectRatio = Float(parent.mtkView.frame.size.width / parent.mtkView.frame.size.height)
                preferredFramesTime = 1.0 / Float(parent.mtkView.preferredFramesPerSecond)
            }
            func initParticles() {
                func allocBuffer() -> [MTLBuffer] {
                    var buffers:[MTLBuffer] = []
                    for _ in 0..<Coordinator.maxBuffers {
                        let length = MemoryLayout<Particle>.stride * Coordinator.numberOfParticles
                        guard let buffer = metalDevice.makeBuffer(length: length, options: .storageModeShared) else {
                            fatalError("Cannot make particle buffer.")
                        }
                        buffers.append(buffer)
                    }
                    return buffers
                }
                func initParticlePosition(_ particleBuffer: MTLBuffer) {
                    let particles = makeParticlePositions()
                    self.particleBuffers[0].contents().copyMemory(from: particles, byteCount: MemoryLayout<Particle>.stride * particles.count)
                }
                particleBuffers = allocBuffer()
                initParticlePosition(particleBuffers[0])
            }
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
            buildRenderPipeline()
            initUniform()
            initParticles()
        }
        
        func makeRandomPosition() -> Particle {
            var particle = Particle()
            particle.position.x = Float.random(in: -1...1)
            particle.position.y = Float.random(in: -1...1)
            return particle
        }

        func makeParticlePositions() -> [Particle]{
            return [Particle](repeating: Particle(), count: Coordinator.numberOfParticles).map {_ in
                return makeRandomPosition()
            }
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable else {return}
            
            renderSemaphore.wait()
            let commandBuffer = metalCommandQueue.makeCommandBuffer()!
            
            currentBufferIndex = (currentBufferIndex + 1) % Coordinator.maxBuffers
            computeShaderExecuter.calcParticlePostion(metalCommandQueue: metalCommandQueue, particleBuffers: particleBuffers, beforeBufferIndex: beforeBufferIndex, currentBufferIndex: currentBufferIndex)
            
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.7, 0.1, 1.0)

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

            guard let renderPipeline = renderPipeline else {fatalError()}

            
            renderEncoder.setRenderPipelineState(renderPipeline)
            uniforms.time += preferredFramesTime

            renderEncoder.setVertexBuffer(particleBuffers[currentBufferIndex], offset: 0, index: 0)
            
            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 2)            

            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Coordinator.numberOfParticles)
            
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            
            commandBuffer.addCompletedHandler {[weak self] _ in
                self?.renderSemaphore.signal()
            }
            commandBuffer.commit()
        }
    }
}
