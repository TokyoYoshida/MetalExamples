//
//  MetalView.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/04.
//

import SwiftUI
import MetalKit

struct VideoEffectMetalView: UIViewRepresentable {
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
        static let numberOfParticles = 10000
        static let maxBuffers = 3
        var parent: VideoEffectMetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var renderPipeline: MTLRenderPipelineState!
        var particleBuffers:[MTLBuffer] = []
        var renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
        var uniforms: Uniforms!
        var preferredFramesTime: Float!
        let semaphore = DispatchSemaphore(value: Coordinator.maxBuffers)
        var currentBufferIndex = 0
        var beforeBufferIndex: Int {
            currentBufferIndex == 0 ? Coordinator.maxBuffers - 1 : currentBufferIndex - 1
        }

        var ciContext : CIContext!
        var texture: MTLTexture!
        let videoRecorder =  FrameVideoRecorder()
        var textureCache : CVMetalTextureCache?
        var cgImage: CGImage?

        init(_ parent: VideoEffectMetalView) {
            func buildPipeline() {
                guard let library = self.metalDevice.makeDefaultLibrary() else {fatalError()}
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = library.makeFunction(name: "storedParticleVertexShader")
                descriptor.fragmentFunction = library.makeFunction(name: "storedParticleFragmentShader")
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
                renderPipeline = try! self.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            }
            func initUniform() {
                uniforms = Uniforms(time: Float(0.0), aspectRatio: Float(0.0), touch: SIMD2<Float>())
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
            func setupVideoRecorder() {
                do {
                    try videoRecorder.prepare()
                } catch {
                    fatalError("Cannot prepare video recoreder.")
                }
            }
            func setFrameTextureCapture() {
                CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textureCache)
                videoRecorder.imageBufferHandler = {[unowned self] (imageBuffer, timestamp, outputBuffer) in
                    guard let textureCache = self.textureCache else {return}
                    self.texture = imageBuffer.createTexture(pixelFormat: parent.mtkView.colorPixelFormat, planeIndex: 0, capturedImageTextureCache: textureCache)
    //                let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                    if let ciImage = CIImage(mtlTexture: self.texture, options: nil) {
                        self.cgImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent)
                    }
                }
            }

            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            ciContext = CIContext.init(mtlDevice: metalDevice)
            super.init()
            buildPipeline()
            initUniform()
            initParticles()
            setupVideoRecorder()
            setFrameTextureCapture()
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
                let p = particleBuffers[currentBufferIndex].contents()
                let b = particleBuffers[beforeBufferIndex].contents()
                let stride = MemoryLayout<Particle>.stride
                for i in 0..<Coordinator.numberOfParticles {
                    var particle = b.load(fromByteOffset: i*stride, as: Particle.self)
                    if particle.position.y > -1 {
                        particle.position.y -= 0.01
                    } else {
                        particle.position.y += 2 - 0.01
                    }
                    p.storeBytes(of: particle,toByteOffset: i*stride,  as: Particle.self)
                }
            }
            guard let drawable = view.currentDrawable else {return}
            
            semaphore.wait()
            let commandBuffer = metalCommandQueue.makeCommandBuffer()!
            
            currentBufferIndex = (currentBufferIndex + 1) % Coordinator.maxBuffers
            calcParticlePostion()
            
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.7, 0.1, 1.0)

//            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

//            guard let renderPipeline = renderPipeline else {fatalError()}
//
//
//            renderEncoder.setRenderPipelineState(renderPipeline)
//            uniforms.time += preferredFramesTime
//
//            renderEncoder.setVertexBuffer(particleBuffers[currentBufferIndex], offset: 0, index: 0)
//
//            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 2)

//            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Coordinator.numberOfParticles)
            
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

//            renderEncoder.endEncoding()
            blitEncoder.endEncoding()

            commandBuffer.present(drawable)
            
            commandBuffer.addCompletedHandler {[weak self] _ in
                self?.semaphore.signal()
            }
            commandBuffer.commit()
        }
    }
}
