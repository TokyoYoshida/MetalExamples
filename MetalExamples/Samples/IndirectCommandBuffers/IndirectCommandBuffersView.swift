//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct IndirectCommandBuffersView: View {
    var body: some View {
        IndirectCommandBuffersMetalView()
        .navigationBarTitle(Text("Indirect Buffers"), displayMode: .inline)
    }
}
