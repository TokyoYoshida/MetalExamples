//
//  MetalView.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/04.
//

import SwiftUI
import MetalKit

struct TripleBufferingMetalView: UIViewRepresentable {
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
        static let numberOfParticles = 100
        static let maxBuffers = 3
        var parent: TripleBufferingMetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var renderPipeline: MTLRenderPipelineState!
        var texture: MTLTexture!
        var vertextBuffer: MTLBuffer!
        private let vertexDatas: [[Float]] = [
            [
                -0.01, -0.01, 0, 1,
                0.01, -0.01, 0, 1,
                -0.01,  0.01, 0, 1,
                0.01,  0.01, 0, 1,
            ]
        ]
        let textureCoordinateData: [Float] = [0, 1,
                                              1, 1,
                                              0, 0,
                                              1, 0]
        var particleBuffers:[MTLBuffer] = []
        var renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
        var uniforms: Uniforms!
        var preferredFramesTime: Float!
        var vertextBuffers: [MTLBuffer] = []
        var texCoordBuffer: MTLBuffer!

        init(_ parent: TripleBufferingMetalView) {
            func buildPipeline() {
                guard let library = self.metalDevice.makeDefaultLibrary() else {fatalError()}
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = library.makeFunction(name: "storedParticleVertexShader")
                descriptor.fragmentFunction = library.makeFunction(name: "storedParticleFragmentShader")
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
                renderPipeline = try! self.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            }
            func initTexture() {
                func makeRenderTexture() -> MTLTexture {
                    let texDesc = MTLTextureDescriptor()
                    texDesc.width =  100//(parent.mtkView.currentDrawable?.texture.width)!
                    texDesc.height =  100//(parent.mtkView.currentDrawable?.texture.height)!
                    texDesc.depth = 1
                    texDesc.textureType = MTLTextureType.type2D

                    texDesc.usage = [MTLTextureUsage.renderTarget, MTLTextureUsage.shaderRead]
                    texDesc.storageMode = .private
                    texDesc.pixelFormat = .bgra8Unorm

                    texDesc.usage = .unknown

                    return metalDevice.makeTexture(descriptor: texDesc)!
                }
                texture = makeRenderTexture()
            }
            func initUniform() {
                uniforms = Uniforms(time: Float(0.0), aspectRatio: Float(0.0), touch: SIMD2<Float>())
                uniforms.aspectRatio = Float(parent.mtkView.frame.size.width / parent.mtkView.frame.size.height)
                preferredFramesTime = 1.0 / Float(parent.mtkView.preferredFramesPerSecond)
            }
            func makeBuffers() {
                func makeVertexBuffer() {
                    vertextBuffers = vertexDatas.map {vertextData in
                        let size = vertextData.count * MemoryLayout<Float>.size
                        return metalDevice.makeBuffer(bytes: vertextData, length: size)!
                    }
                }
                func makeTextureDataBuffer(){
                    let size = textureCoordinateData.count * MemoryLayout<Float>.size
                    texCoordBuffer = metalDevice.makeBuffer(bytes: textureCoordinateData, length: size)
                }
                makeVertexBuffer()
                makeTextureDataBuffer()
            }
            func initParticles() {
                func makeParticlePositions() -> [Particle]{
                    func makeRandomPosition() -> Particle {
                        var particle = Particle()
                        particle.position.x = Float.random(in: 0..<2) - 1
                        particle.position.y = Float.random(in: 0..<2) - 1
                        return particle
                    }
                    return [Particle](repeating: Particle(), count: Coordinator.numberOfParticles).map {_ in
                        return makeRandomPosition()
                    }
                }
                func buildBuffer() -> [MTLBuffer] {
                    var buffers:[MTLBuffer] = []
                    for _ in 0..<Coordinator.maxBuffers {
                        let particles = makeParticlePositions()
                        let length = MemoryLayout<Particle>.stride * particles.count
                        guard let buffer = metalDevice.makeBuffer(bytes: particles, length: length, options: .storageModeShared) else {
                            fatalError("Cannot make particle buffer.")
                        }
                        buffers.append(buffer)
                    }
                    return buffers
                }
                self.particleBuffers = buildBuffer()
            }
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
            buildPipeline()
            initUniform()
            initTexture()
            makeBuffers()
            initParticles()
        }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        func draw(in view: MTKView) {
            func calcParticlePostion() {
                
            }
            guard let drawable = view.currentDrawable else {return}
            
            let commandBuffer = metalCommandQueue.makeCommandBuffer()!
            
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.7, 0.1, 1.0)

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

            guard let renderPipeline = renderPipeline else {fatalError()}

            
            renderEncoder.setRenderPipelineState(renderPipeline)
            uniforms.time += preferredFramesTime

            renderEncoder.setVertexBuffer(particleBuffers[0], offset: 0, index: 0)
            
            renderEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)

            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 2)            

            renderEncoder.setFragmentTexture(texture, index: 0)

            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Coordinator.numberOfParticles)
            
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            
            commandBuffer.commit()
            
            commandBuffer.waitUntilCompleted()
        }
    }
}
