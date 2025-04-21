//
//  BlurWindow.swift
//  PrabhatsPersonalTimeTracker
//
//  Created by Pravat on 21/04/2025.
//

import SwiftUI

struct BlurWindow: NSViewRepresentable {
    func updateNSView(_ nsView: NSViewType, context: Context) {
    }
    
    func makeNSView(context: Context) -> some NSView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.material = .sidebar  // This provides a stronger blur effect
        
        return view
    }
}

#Preview {
    BlurWindow()
}
