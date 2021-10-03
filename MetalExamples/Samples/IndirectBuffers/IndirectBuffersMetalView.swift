//
//  MetalView.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/04.
//

import SwiftUI
import MetalKit

class PipelineStateContainer {
    var pipelineState: MTLRenderPipelineState

    internal init(pipelineState: MTLRenderPipelineState) {
        self.pipelineState = pipelineState
    }
}

struct IndirectBuffersMetalView: UIViewRepresentable {
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
        var parent: IndirectBuffersMetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var renderPipeline: MTLRenderPipelineState!
        var computePipeline: MTLComputePipelineState!
        var icbPipeline: MTLComputePipelineState!
        var particleBuffers:[MTLBuffer] = []
        var renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
        var uniforms: Uniforms!
        var preferredFramesTime: Float!
        let semaphore = DispatchSemaphore(value: Coordinator.maxBuffers)
        var currentBufferIndex = 0
        var beforeBufferIndex: Int {
            currentBufferIndex == 0 ? Coordinator.maxBuffers - 1 : currentBufferIndex - 1
        }
        var threadgroupsPerGrid: MTLSize!
        var threadsPerThreadgroup: MTLSize!

        var icb: MTLIndirectCommandBuffer!
        var icbFunction: MTLFunction!
        var icbBuffer: MTLBuffer!
        lazy var pipelineStateContainer = PipelineStateContainer(pipelineState: renderPipeline)

        init(_ parent: IndirectBuffersMetalView) {
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
            func buildICB() {
                guard let library = self.metalDevice.makeDefaultLibrary() else {fatalError()}

                let icbDescriptor = MTLIndirectCommandBufferDescriptor()
                icbDescriptor.commandTypes = [.draw]
                icbDescriptor.inheritBuffers = false
                icbDescriptor.inheritPipelineState = false
                
                guard let icb = metalDevice.makeIndirectCommandBuffer(descriptor: icbDescriptor, maxCommandCount: 1, options: []) else {
                    fatalError()
                }
                self.icb = icb
                
                icbFunction = library.makeFunction(name: "particleComputeICBShader")
                icbPipeline = try! metalDevice.makeComputePipelineState(function: icbFunction)
                
                let icbEncoder = icbFunction.makeArgumentEncoder(bufferIndex: 4)
                icbBuffer = metalDevice.makeBuffer(length: icbEncoder.encodedLength, options: [])
               
                icbEncoder.setArgumentBuffer(icbBuffer, offset: 0)
                icbEncoder.setIndirectCommandBuffer(icb, index: 0)
            }
            func calcThreadGroup() {
                let maxTotalThreadsPerThreadgroup =  computePipeline.maxTotalThreadsPerThreadgroup
                let threadExecutionWidth = computePipeline.threadExecutionWidth
                let groupsWidth  = maxTotalThreadsPerThreadgroup / threadExecutionWidth * threadExecutionWidth

                threadgroupsPerGrid = MTLSize(width: groupsWidth, height: 1, depth: 1)
                
                let threadsWidth = ((Coordinator.numberOfParticles + groupsWidth - 1) / groupsWidth)*2
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
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
            buildRenderPipeline()
            buildComputePipeline()
            calcThreadGroup()
            buildICB()
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
            func calcParticlePostion(_ commandBuffer: MTLCommandBuffer) {
                let encoder = commandBuffer.makeComputeCommandEncoder()!
                
                encoder.setComputePipelineState(icbPipeline)

                encoder.setBuffer(particleBuffers[beforeBufferIndex], offset: 0, index: 0)
                encoder.setBuffer(particleBuffers[currentBufferIndex], offset: 0, index: 1)
                encoder.setBytes(&Coordinator.numberOfParticles, length: MemoryLayout<Int>.stride, index: 2)
                encoder.setBytes(&pipelineStateContainer, length: MemoryLayout<PipelineStateContainer>.stride, index: 3)
                
                encoder.dispatchThreadgroups(threadgroupsPerGrid,
                                                 threadsPerThreadgroup: threadsPerThreadgroup)
                
                encoder.useResource(icb, usage: .write)
                encoder.useResource(particleBuffers[beforeBufferIndex], usage: .read)
                encoder.useResource(particleBuffers[currentBufferIndex], usage: .write)

                encoder.endEncoding()
            }
            guard let drawable = view.currentDrawable else {return}
            
            semaphore.wait()
            let commandBuffer = metalCommandQueue.makeCommandBuffer()!
            
            currentBufferIndex = (currentBufferIndex + 1) % Coordinator.maxBuffers
            calcParticlePostion(commandBuffer)

            let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
            blitEncoder.optimizeIndirectCommandBuffer(icb, range: 0..<1)
            blitEncoder.endEncoding()

            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.7, 0.1, 1.0)

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

            guard let renderPipeline = renderPipeline else {fatalError()}

            
//            renderEncoder.setRenderPipelineState(renderPipeline)
//            uniforms.time += preferredFramesTime
//
//            renderEncoder.setVertexBuffer(particleBuffers[currentBufferIndex], offset: 0, index: 0)
//
//            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 2)
//
//            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Coordinator.numberOfParticles)
            
            renderEncoder.executeCommandsInBuffer(icb, range: 0..<1)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            
            commandBuffer.addCompletedHandler {[weak self] _ in
                self?.semaphore.signal()
            }
            commandBuffer.commit()
        }
    }
}
