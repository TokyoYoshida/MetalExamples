//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct TripleBufferingGPUIndirectArgumentsView: View {
    var body: some View {
        TripleBufferingMetalViewGPUIndirectArguments()
        .navigationBarTitle(Text("TripleBuffering"), displayMode: .inline)
    }
}
