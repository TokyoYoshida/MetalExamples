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
                }
                Section(header: Text("Metal Best Practices Code Samples")) {
                    NavigationLink(destination: PersistentObjectsView()) {
                        Text("Persistent Objects")
                            .padding()
                    }
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
