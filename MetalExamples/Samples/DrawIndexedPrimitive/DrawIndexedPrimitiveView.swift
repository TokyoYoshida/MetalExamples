//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct DrawIndexedPrimitiveView: View {
    var body: some View {
        DrawIndexedPrimitiveMetalView()
        .navigationBarTitle(Text("TripleBuffering"), displayMode: .inline)
    }
}
