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
                }
                Section(header: Text("Metal Best Practices Code Samples")) {
                    Section(header: Text("Persistent Objects")) {
                        NavigationLink(destination: PersistentObjects1View()) {
                            Text("Pattern1: Generate Every Frame")
                                .padding()
                        }
                        NavigationLink(destination: PersistentObjects2View()) {
                            Text("Pattern2: Reuse")
                                .padding()
                        }
                    }
                    Section(header: Text("Resource Options")) {
                        NavigationLink(destination:
                            ResourceOptions1View()) {
                            Text("Pattern1")
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
