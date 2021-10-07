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
                    Section(header: Text("Simple")) {
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
                        NavigationLink(destination: VideoEffectView()) {
                            Text("Video Effect")
                                .padding()
                        }
                        NavigationLink(destination: DrawIndexedPrimitiveView()) {
                            Text("Draw Indexed Primitive")
                                .padding()
                        }
                        NavigationLink(destination: MultiPassRenderingView()) {
                            Text("Multi Pass Rendering")
                                .padding()
                        }
                    }
                    Section(header: Text("Particle")) {
                        NavigationLink(destination: ParticleView()) {
                            Text("Particle")
                                .padding()
                        }
                        NavigationLink(destination: TripleBufferingView()) {
                            Text("Triple Buffering(Compute on CPU)")
                                .padding()
                        }
                        NavigationLink(destination: TripleBufferingGPUView()) {
                            Text("Triple Buffering(Compute on GPU)")
                                .padding()
                        }
                        NavigationLink(destination: TripleBufferingGPUIndirectArgumentsView()) {
                            Text("Triple Buffering(Compute on GPU) using IndirectArguments")
                                .padding()
                        }
                        NavigationLink(destination: IndirectBuffersView()) {
                            Text("Indirect Buffers")
                                .padding()
                        }
                    }
                    Section(header: Text("3D")) {
                        NavigationLink(destination: Draw3DView()) {
                            Text("Draw 3D by Depth Stencil")
                                .padding()
                        }
                    }
                    Section(header: Text("MSL Shader Examples")) {
                        NavigationLink(destination: SimpleShapeView()) {
                            Text("Simple Shape")
                                .padding()
                        }
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
