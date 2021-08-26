//
//  Simple.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct DrawToCAMetalLayerView: View {
    var body: some View {
        CAMetalLayerView()
        .navigationBarTitle(Text("Draw to CAMetalLayer"), displayMode: .inline)
    }
}
