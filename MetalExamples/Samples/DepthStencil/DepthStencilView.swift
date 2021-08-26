//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct DepthStencilView: View {
    var body: some View {
        DepthStencilMetalView()
        .navigationBarTitle(Text("TripleBuffering"), displayMode: .inline)
    }
}
