//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct Draw3DView: View {
    var body: some View {
        Draw3DMetalView()
        .navigationBarTitle(Text("TripleBuffering"), displayMode: .inline)
    }
}
