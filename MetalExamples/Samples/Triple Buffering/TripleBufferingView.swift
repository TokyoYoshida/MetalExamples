//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct TripleBufferingView: View {
    var body: some View {
        TripleBufferingMetalView()
        .navigationBarTitle(Text("TripleBuffering"), displayMode: .inline)
    }
}
