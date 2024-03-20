//
//  CompressumApp.swift
//  Compressum
//
//  Created by Henrik Öberg on 2024-03-11.
//

import SwiftUI

@main
struct CompressumApp: App {
    @State private var isDarkMode = true
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .frame(minWidth: 500, idealWidth: 500, maxWidth: .infinity, minHeight: 400, idealHeight: 400, maxHeight: .infinity)
                .onAppear {
                    isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                }
        }
    }
}

struct BackgroundView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow // Set blending mode to behind window
        view.material = .underWindowBackground // Use dark material for visual effect
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // Update view if needed
    }
}

struct BlurView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow // Set blending mode to behind window
        view.material = .underWindowBackground
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}


