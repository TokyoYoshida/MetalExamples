//
//  ComputeShaderExecuter.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/10/22.
//

import MetalKit

class ComputeShaderExecuter {
    private var computePipeline: MTLComputePipelineState!
    private var threadgroupsPerGrid: MTLSize!
    private var threadsPerThreadgroup: MTLSize!
    private var computeSemaphore: DispatchSemaphore!
    private var numberOfParticles:Int

    init(device: MTLDevice, computeShaderName: String, numberOfParticles: Int, maxBuffers: Int) {
        func buildComputePipeline() {
            guard let library = device.makeDefaultLibrary() else {fatalError()}
            let function = library.makeFunction(name: computeShaderName)!
            computePipeline = try! device.makeComputePipelineState(function: function)
        }
        func calcThreadGroup() {
            let maxTotalThreadsPerThreadgroup =  computePipeline.maxTotalThreadsPerThreadgroup
            let threadExecutionWidth = computePipeline.threadExecutionWidth
            let groupsWidth  = maxTotalThreadsPerThreadgroup / threadExecutionWidth * threadExecutionWidth

            threadgroupsPerGrid = MTLSize(width: groupsWidth, height: 1, depth: 1)
            
            let threadsWidth = ((numberOfParticles + groupsWidth - 1) / groupsWidth)
            threadsPerThreadgroup = MTLSize(width: threadsWidth, height: 1, depth: 1)
        }
        func buildSemaphore() {
            computeSemaphore = DispatchSemaphore(value: maxBuffers)
        }

        self.numberOfParticles = numberOfParticles

        buildComputePipeline()
        calcThreadGroup()
        buildSemaphore()
    }
    
    func calcParticlePostion(metalCommandQueue: MTLCommandQueue, particleBuffers: [MTLBuffer], beforeBufferIndex:Int ,currentBufferIndex: Int) {
        computeSemaphore.wait()

        let commandBuffer = metalCommandQueue.makeCommandBuffer()!

        let encoder = commandBuffer.makeComputeCommandEncoder()!
        
        encoder.setComputePipelineState(computePipeline)

        encoder.setBuffer(particleBuffers[beforeBufferIndex], offset: 0, index: 0)
        encoder.setBuffer(particleBuffers[currentBufferIndex], offset: 0, index: 1)
        encoder.setBytes(&numberOfParticles, length: MemoryLayout<Int>.stride, index: 2)
        
        encoder.dispatchThreadgroups(threadgroupsPerGrid,
                                         threadsPerThreadgroup: threadsPerThreadgroup)
        
        encoder.endEncoding()

        commandBuffer.addCompletedHandler {[weak self] _ in
            self?.computeSemaphore.signal()
        }
        commandBuffer.commit()
    }
}
