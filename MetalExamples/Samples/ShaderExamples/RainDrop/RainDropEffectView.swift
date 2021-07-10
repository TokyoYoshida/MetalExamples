//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct RainDropEffectView: View {
    var body: some View {
        VideoEffectMetalView(vertexShaderName: "simpleVertexShader", fragmentShaderName: "rainDropFragmentShader")
        .navigationBarTitle(Text("Rain Drop"), displayMode: .inline)
        .edgesIgnoringSafeArea(.all)
    }
}
