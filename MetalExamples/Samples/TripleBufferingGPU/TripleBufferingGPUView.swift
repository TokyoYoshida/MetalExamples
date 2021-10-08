//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct TripleBufferingGPUView: View {
    var body: some View {
        TripleBufferingMetalViewGPU()
        .navigationBarTitle(Text("TripleBuffering"), displayMode: .inline)
    }
}
