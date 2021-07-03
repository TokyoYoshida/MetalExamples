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
                Section(header: Text("Samples")) {
                    NavigationLink(destination: SimpleView()) {
                        Text("Simple")
                            .padding()
                    }
                    NavigationLink(destination: DrawTextureView()) {
                        Text("Draw Texture")
                            .padding()
                    }
                    NavigationLink(destination: SimpleShaderViewv()) {
                        Text("Simple Shader")
                            .padding()
                    }
                    NavigationLink(destination: ParticleView()) {
                        Text("Particle")
                            .padding()
                    }
                    NavigationLink(destination: TripleBufferingView()) {
                        Text("TripleBuffering")
                            .padding()
                    }
                }
            }
            .listStyle(SidebarListStyle())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
