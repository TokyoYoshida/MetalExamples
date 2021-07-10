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
    
    let vertexShaderName: String
    let fragmentShaderName: String

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
        var renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
        var uniforms: Uniforms!
        var preferredFramesTime: Float!

        var ciContext : CIContext!
        var texture: MTLTexture!
        let videoRecorder =  FrameVideoRecorder()
        var textureCache : CVMetalTextureCache?
        var cgImage: CGImage?

        let vertexData: [Float] = [
            -1, -1, 0, 1,
             1, -1, 0, 1,
            -1,  1, 0, 1,
             1,  1, 0, 1,
        ]
        let textureCordinatedata: [Float] = [
            0,1,
            1,1,
            0,0,
            1,0
        ]
        var vertextBuffer: MTLBuffer!
        var texCordBuffer: MTLBuffer!

        
        init(_ parent: VideoEffectMetalView) {
            func buildPipeline() {
                guard let library = self.metalDevice.makeDefaultLibrary() else {fatalError()}
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = library.makeFunction(name: parent.vertexShaderName)
                descriptor.fragmentFunction = library.makeFunction(name: parent.fragmentShaderName)
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
                renderPipeline = try! self.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            }
            func initUniform() {
                uniforms = Uniforms(time: Float(0.0), aspectRatio: Float(0.0), touch: SIMD2<Float>(), resolution: SIMD4<Float>())
                uniforms.aspectRatio = Float(parent.mtkView.frame.size.width / parent.mtkView.frame.size.height)
                preferredFramesTime = 1.0 / Float(parent.mtkView.preferredFramesPerSecond)
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
            func makeBuffers() {
                let size = vertexData.count * MemoryLayout<Float>.size
                vertextBuffer = metalDevice.makeBuffer(bytes: vertexData, length: size, options: [])
                
                let texSize = textureCordinatedata.count * MemoryLayout<Float>.size
                texCordBuffer = metalDevice.makeBuffer(bytes: textureCordinatedata, length: texSize, options: [])
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
            setupVideoRecorder()
            setFrameTextureCapture()
            makeBuffers()
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
            uniforms.resolution.x = Float(size.width)
            uniforms.resolution.y = Float(size.height)
        }
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable else {return}
            
            let commandBuffer = metalCommandQueue.makeCommandBuffer()!
            
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.7, 0.1, 1.0)

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

            guard let renderPipeline = renderPipeline else {fatalError()}


            renderEncoder.setRenderPipelineState(renderPipeline)
            uniforms.time += preferredFramesTime

            renderEncoder.setVertexBuffer(vertextBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(texCordBuffer, offset: 0, index: 1)
            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 2)

            renderEncoder.setFragmentTexture(texture, index: 0)
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)

            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            

            renderEncoder.endEncoding()

            commandBuffer.present(drawable)
            
            commandBuffer.commit()
            
            commandBuffer.waitUntilCompleted()
        }
    }
}
