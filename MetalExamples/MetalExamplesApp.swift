//
//  MetalExamplesApp.swift
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/03.
//

import SwiftUI
import GDPerformanceView

@main
struct MetalExamplesApp: App {
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { scene in
            PerformanceMonitor.shared().start()
        }
    }
}
