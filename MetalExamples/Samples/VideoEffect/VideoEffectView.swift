//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct VideoEffectView: View {
    var body: some View {
        VideoEffectMetalView(vertexShaderName: "simpleVertexShader", fragmentShaderName: "redFilterFragmentShader")
        .navigationBarTitle(Text("Video Effect"), displayMode: .inline)
        .edgesIgnoringSafeArea(.all)
    }
}
