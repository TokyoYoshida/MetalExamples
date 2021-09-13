//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct SimpleShapeView: View {
    var body: some View {
        VideoEffectMetalView(vertexShaderName: "simpleVertexShader", fragmentShaderName: "simpleShapeFragmentShader")
        .navigationBarTitle(Text("Simple Shape"), displayMode: .inline)
        .edgesIgnoringSafeArea(.all)
    }
}
