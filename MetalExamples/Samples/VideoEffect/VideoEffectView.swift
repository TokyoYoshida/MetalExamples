//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct VideoEffectView: View {
    var body: some View {
        VideoEffectMetalView()
        .navigationBarTitle(Text("ShaderExamplesView"), displayMode: .inline)
        .edgesIgnoringSafeArea(.all)
    }
}
