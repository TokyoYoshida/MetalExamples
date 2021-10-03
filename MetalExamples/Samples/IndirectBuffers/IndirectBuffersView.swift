//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct IndirectBuffersView: View {
    var body: some View {
        IndirectBuffersMetalView()
        .navigationBarTitle(Text("Indirect Buffers"), displayMode: .inline)
    }
}
