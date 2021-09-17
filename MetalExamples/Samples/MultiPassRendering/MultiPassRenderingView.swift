//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct MultiPassRenderingView: View {
    var body: some View {
        MultiPassRenderingMetalView()
        .navigationBarTitle(Text("Simple Shader"), displayMode: .inline)
    }
}
