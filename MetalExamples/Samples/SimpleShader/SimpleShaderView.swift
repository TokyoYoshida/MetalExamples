//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct SimpleShaderViewv: View {
    var body: some View {
        SimpleShaderMetalView()
        .navigationBarTitle(Text("Simple Shader"), displayMode: .inline)
    }
}
