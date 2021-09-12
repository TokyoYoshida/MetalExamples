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
                    NavigationLink(destination: DrawToCAMetalLayerView()) {
                        Text("Draw to CAMetalLayer")
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
                    NavigationLink(destination: VideoEffectView()) {
                        Text("Video Effect")
                            .padding()
                    }
                    NavigationLink(destination: DrawIndexedPrimitiveView()) {
                        Text("Draw Indexed Primitive")
                            .padding()
                    }
                    NavigationLink(destination: Draw3DView()) {
                        Text("Draw 3D by Depth Stencil")
                            .padding()
                    }
                    Section(header: Text("MSL Shader Examples")) {
                        NavigationLink(destination: RainDropEffectView()) {
                            Text("Rain Drop")
                                .padding()
                        }
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
