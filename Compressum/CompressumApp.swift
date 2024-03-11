//
//  CompressumApp.swift
//  Compressum
//
//  Created by Henrik Öberg on 2024-03-11.
//

import SwiftUI

@main
struct CompressumApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 500, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity) // Set frame to fill entire window
                .background(BackgroundView()) // Use custom background view
                .handlesExternalEvents(preferring: Set(arrayLiteral: "dragAndDrop"), allowing: Set(arrayLiteral: "dragAndDrop")) // Enable drag and drop
        }
    }
}

struct BackgroundView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow // Set blending mode to behind window
        view.material = .ultraDark // Use dark material for visual effect
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // Update view if needed
    }
}
