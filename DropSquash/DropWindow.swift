//
//  DropWindow.swift
//  DropSquash
//
//  Created by 0 on 2/1/2026.
//

import Cocoa
import SwiftUI

class DropWindow: NSWindow {
    init() {
        let screen = NSScreen.main!.frame
        let size: CGFloat = 120
        let x = screen.maxX - size - 100
        let y = screen.maxY - size - 100

        super.init(
            contentRect: NSRect(x: x, y: y, width: size, height: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.isMovableByWindowBackground = true

        self.contentView = NSHostingView(rootView: DropZoneView())
    }
}

