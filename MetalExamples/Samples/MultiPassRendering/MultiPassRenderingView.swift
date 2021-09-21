//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct MultiPassRenderingView: View {
    var body: some View {
        GeometryReader { proxy in
            MultiPassRenderingMetalView(frame: proxy.frame(in: .local))
            .navigationBarTitle(Text("Simple Shader"), displayMode: .inline)
        }
    }
}
