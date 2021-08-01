//
//  MetalView.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/04.
//

import SwiftUI
import MetalKit

struct FrameUniforms {
    var projectionViewMatrinx: matrix_float4x4
    var normalMatrinx: matrix_float3x3
}

struct DepthStencilMetalView: UIViewRepresentable {
    typealias UIViewType = MTKView
    var mtkView:MTKView = {
        let _mtkView = MTKView()
        _mtkView.preferredFramesPerSecond = 60
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            _mtkView.device = metalDevice
        }
        _mtkView.framebufferOnly = false
        _mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        _mtkView.drawableSize = _mtkView.frame.size
        _mtkView.colorPixelFormat = .bgra8Unorm_srgb
        _mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        return _mtkView
    }()

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: Context) -> MTKView {
        mtkView.delegate = context.coordinator
        return mtkView
    }
    func updateUIView(_ uiView: MTKView, context: Context) {
    }
    class Coordinator : NSObject, MTKViewDelegate {
        static let numberOfParticles = 100_000
        static let maxBuffers = 3
        lazy var indexes = makeParticleIndexes()
        var parent: DepthStencilMetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var renderPipeline: MTLRenderPipelineState!
        var particleBuffers:[MTLBuffer] = []
        lazy var indexBuffer: MTLBuffer = metalDevice.makeBuffer(length: MemoryLayout<UInt32>.stride * indexes.count, options: .storageModeShared)!
        var renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
        var uniforms: Uniforms!
        var preferredFramesTime: Float!
        let semaphore = DispatchSemaphore(value: Coordinator.maxBuffers)
        var currentBufferIndex = 0
        var beforeBufferIndex: Int {
            currentBufferIndex == 0 ? Coordinator.maxBuffers - 1 : currentBufferIndex - 1
        }
        lazy var frameUniformBuffer = metalDevice.makeBuffer(length: MemoryLayout<FrameUniforms>.size, options: [])!
        var mesh: MTKMesh!
        private var modelMatrix = matrix_identity_float4x4
        private var depthStencilState: MTLDepthStencilState!

        init(_ parent: DepthStencilMetalView) {
            func loadModel() {
                let allocator = MTKMeshBufferAllocator(device: metalDevice)
                let mdlMesh = MDLMesh.newBox(withDimensions: vector_float3(repeating: 1),
                                             segments: vector_uint3(repeating: 2),
                                             geometryType: .triangles,
                                             inwardNormals: false,
                                             allocator: allocator)
                mesh = try! MTKMesh(mesh: mdlMesh, device: metalDevice)
            }
            func buildPipeline() {
                loadModel()
                guard let library = self.metalDevice.makeDefaultLibrary() else {fatalError()}
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
                descriptor.sampleCount = parent.mtkView.sampleCount
                descriptor.vertexFunction = library.makeFunction(name: "lambertVertex3")
                descriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
                descriptor.depthAttachmentPixelFormat = parent.mtkView.depthStencilPixelFormat
                descriptor.stencilAttachmentPixelFormat = parent.mtkView.depthStencilPixelFormat
                renderPipeline = try! self.metalDevice.makeRenderPipelineState(descriptor: descriptor)
            }
            func buildDepthStencilState() {
                let depthDescriptor = MTLDepthStencilDescriptor()
                depthDescriptor.depthCompareFunction = .less
                depthDescriptor.isDepthWriteEnabled = true
                depthStencilState = metalDevice.makeDepthStencilState(descriptor: depthDescriptor)
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
                func initIndexBuffer() {
                    let indexes = makeParticleIndexes()
                    self.indexBuffer.contents().copyMemory(from: indexes, byteCount: MemoryLayout<UInt32>.stride * indexes.count)
                }
                particleBuffers = allocBuffer()
                initParticlePosition(particleBuffers[0])
                initIndexBuffer()
            }
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
            buildPipeline()
            initUniform()
            buildDepthStencilState()
            initParticles()
        }
        
        func makeRandomPosition() -> Particle {
            var particle = Particle()
            particle.position.x = Float.random(in: -1...1)
            particle.position.y = Float.random(in: -1...1)
            return particle
        }
        
        func calcLayoutParams() -> (deltaX: UInt32, deltaY: UInt32, spacing: Float) {
            let width: Float = 2
            let height: Float = 2
            let gridArea = width * height
            let spacing = sqrt(gridArea / Float(Coordinator.numberOfParticles))
            let deltaX = UInt32(round(width / spacing))
            let deltaY = UInt32(round(height / spacing))
            
            return (deltaX: deltaX, deltaY: deltaY, spacing: spacing)
        }

        func makeParticlePositions() -> [Particle] {
            var particles: [Particle] = []

            let (deltaX, deltaY, spacing) = calcLayoutParams()
            
            for gridY in 0 ..< deltaY {
                let alternatingOffsetX: Float = -1
                for gridX in 0 ..< deltaX {
                    let position = SIMD2<Float>(alternatingOffsetX + (Float(gridX) + 0.5) * spacing, (Float(gridY) + 0.5) * spacing - 1)
                    let particle = Particle(position: position)
                    particles.append(particle)
                }
            }
            
            return particles
        }
        
        func makeParticleIndexes() -> [UInt32] {
            let (deltaX, deltaY, _) = calcLayoutParams()

            var indexes: [UInt32] = []
            for gridY in 0 ..< deltaY - 1 {
                for gridX in 0 ..< deltaX - 1 {
                    let topLeft = gridY * deltaY + gridX
                    let topRight = topLeft + 1
                    let bottomLeft = topLeft + deltaY
                    let bottomRight = bottomLeft + 1
                    let leftTriangle = [topLeft, bottomLeft, topRight]
                    let rightTriangle = [topRight, bottomRight, bottomLeft]
                    indexes += (leftTriangle + rightTriangle)
                }
            }
            
            return indexes
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        private func updateFramUniforms() {
            // ポインタの取得
            let p = frameUniformBuffer.contents().assumingMemoryBound(to: FrameUniforms.self)
            // カメラの向く位置を決める
            let cameraMatrix = Matrix.lookAt(eye: SIMD3<Float>(0, 2, 1), center: SIMD3<Float>(), up: SIMD3<Float>(0, 1, 0))
            // パースペクティブ（透視投影法）射影変換行列を得る
            let projectionMatrix = Matrix.perspective(fovyRadians: radians(fromDegrees: 75),
                                                      aspect: Float(parent.mtkView.drawableSize.width / parent.mtkView.drawableSize.height),
                                                      nearZ: 0.1,
                                                      farZ: 100)
            let viewModelMatrix = matrix_multiply(cameraMatrix, modelMatrix)
            p.pointee.projectionViewMatrinx = matrix_multiply(projectionMatrix, viewModelMatrix)
            let mat3 = Matrix.toUpperLeft3x3(from4x4: viewModelMatrix)
            p.pointee.normalMatrinx = mat3.transpose.inverse
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
            
//            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
//            renderPassDescriptor.colorAttachments[0].loadAction = .clear
//            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.8, 0.7, 0.1, 1.0)

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: parent.mtkView.currentRenderPassDescriptor!)!

            guard let renderPipeline = renderPipeline else {fatalError()}

            
            updateFramUniforms()

            renderEncoder.setRenderPipelineState(renderPipeline)
            renderEncoder.setDepthStencilState(depthStencilState)

            uniforms.time += preferredFramesTime

            renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
//            renderEncoder.setVertexBuffer(particleBuffers[currentBufferIndex], offset: 0, index: 0)
            
            renderEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
            
//            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 2)

            renderEncoder.drawIndexedPrimitives(type: mesh.submeshes[0].primitiveType,
                                                indexCount: mesh.submeshes[0].indexCount,
                                                indexType: mesh.submeshes[0].indexType,
                                                indexBuffer: mesh.submeshes[0].indexBuffer.buffer,
                                                indexBufferOffset: mesh.submeshes[0].indexBuffer.offset)

            //            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Coordinator.numberOfParticles)
            
//            renderEncoder.drawIndexedPrimitives(type: .triangle,
//                                                indexCount: indexes.count,
//                                                indexType: .uint32,
//                                                indexBuffer: indexBuffer,
//                                                indexBufferOffset: 0,
//                                                instanceCount: 1)

            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            
            commandBuffer.addCompletedHandler {[weak self] _ in
                self?.semaphore.signal()
            }
            commandBuffer.commit()
        }
    }
}
