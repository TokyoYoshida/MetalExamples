//
//  MetalView.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/04.
//

import SwiftUI
import MetalKit

struct CAMetalLayerView: UIViewRepresentable {
    typealias UIViewType = UIView

    let metalLayer: CAMetalLayer = CAMetalLayer()
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    let renderPassDescriptor = MTLRenderPassDescriptor()

    init() {
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
        }
        self.metalCommandQueue = metalDevice.makeCommandQueue()!

        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        return coordinator
    }
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        metalLayer.device = metalDevice
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame

        view.layer.addSublayer(metalLayer)

        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        draw()
    }

    func draw() {
        autoreleasepool {
            guard let drawable = metalLayer.nextDrawable() else { return }
            let commandBuffer = metalCommandQueue.makeCommandBuffer()

            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            let re = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            re?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }

    class Coordinator : NSObject {}
}
