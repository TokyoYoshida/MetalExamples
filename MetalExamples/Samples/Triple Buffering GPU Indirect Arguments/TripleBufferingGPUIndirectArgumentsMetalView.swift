//
//  MetalView.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/04.
//

import SwiftUI
import MetalKit

struct TripleBufferingMetalViewGPUIndirectArguments: UIViewRepresentable {
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
        var parent: TripleBufferingMetalViewGPUIndirectArguments
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var renderPipeline: MTLRenderPipelineState!
        var computePipeline: MTLComputePipelineState!
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
        lazy var indexes = makeParticleIndexes()
        lazy var indexBuffer: MTLBuffer = metalDevice.makeBuffer(length: MemoryLayout<UInt32>.stride * indexes.count, options: .storageModeShared)!

        init(_ parent: TripleBufferingMetalViewGPUIndirectArguments) {
            func buildRenderPipeline() {
                guard let library = self.metalDevice.makeDefaultLibrary() else {fatalError()}
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = library.makeFunction(name: "storedParticleVertexShader")
                descriptor.fragmentFunction = library.makeFunction(name: "storedParticleFragmentShader")
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
                renderPipeline = try! self.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            }
            func buildComputePipeline() {
                guard let library = self.metalDevice.makeDefaultLibrary() else {fatalError()}
                let function = library.makeFunction(name: "particleComputeShader")!
                computePipeline = try! self.metalDevice.makeComputePipelineState(function: function)
            }
            func calcThreadGroup() {
                let maxTotalThreadsPerThreadgroup =  computePipeline.maxTotalThreadsPerThreadgroup
                let threadExecutionWidth = computePipeline.threadExecutionWidth
                let groupsWidth  = maxTotalThreadsPerThreadgroup / threadExecutionWidth * threadExecutionWidth

                threadgroupsPerGrid = MTLSize(width: groupsWidth, height: 1, depth: 1)
                
                let threadsWidth = ((Coordinator.numberOfParticles + groupsWidth - 1) / groupsWidth)
                threadsPerThreadgroup = MTLSize(width: threadsWidth, height: 1, depth: 1)
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
            func initIndexBuffer() {
                self.indexBuffer.contents().copyMemory(from: indexes, byteCount: MemoryLayout<UInt32>.stride * indexes.count)
            }
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
            buildRenderPipeline()
            buildComputePipeline()
            calcThreadGroup()
            initUniform()
            initParticles()
            initIndexBuffer()
        }
        
        func makeParticleIndexes() -> [UInt32] {
            return [UInt32](0..<UInt32(Coordinator.numberOfParticles))
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
            func calcParticlePostion() {
                computeSemaphore.wait()

                let commandBuffer = metalCommandQueue.makeCommandBuffer()!

                let encoder = commandBuffer.makeComputeCommandEncoder()!
                
                encoder.setComputePipelineState(computePipeline)

                encoder.setBuffer(particleBuffers[beforeBufferIndex], offset: 0, index: 0)
                encoder.setBuffer(particleBuffers[currentBufferIndex], offset: 0, index: 1)
                encoder.setBytes(&Coordinator.numberOfParticles, length: MemoryLayout<Int>.stride, index: 2)
                
                encoder.dispatchThreadgroups(threadgroupsPerGrid,
                                                 threadsPerThreadgroup: threadsPerThreadgroup)
                
                encoder.endEncoding()

                commandBuffer.addCompletedHandler {[weak self] _ in
                    self?.computeSemaphore.signal()
                }
                commandBuffer.commit()
            }
            guard let drawable = view.currentDrawable else {return}
            
            renderSemaphore.wait()
            let commandBuffer = metalCommandQueue.makeCommandBuffer()!
            
            currentBufferIndex = (currentBufferIndex + 1) % Coordinator.maxBuffers
            calcParticlePostion()
            
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.7, 0.1, 1.0)

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

            guard let renderPipeline = renderPipeline else {fatalError()}

            
            renderEncoder.setRenderPipelineState(renderPipeline)
            uniforms.time += preferredFramesTime

            renderEncoder.setVertexBuffer(particleBuffers[currentBufferIndex], offset: 0, index: 0)
            
            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 2)            

            renderEncoder.drawIndexedPrimitives(type: .point,
                                                indexCount: indexes.count,
                                                indexType: .uint32,
                                                indexBuffer: indexBuffer,
                                                indexBufferOffset: 0,
                                                instanceCount: 1)

            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            
            commandBuffer.addCompletedHandler {[weak self] _ in
                self?.renderSemaphore.signal()
            }
            commandBuffer.commit()
        }
    }
}