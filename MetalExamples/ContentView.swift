//
//  ContentView.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: SimpleView()) {
                    Text("Simple")
                        .padding()
                }
                NavigationLink(destination: DrawTextureView()) {
                    Text("Draw Texture")
                        .padding()
                }
            }
         }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
