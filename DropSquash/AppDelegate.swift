//
//  AppDelegate.swift
//  DropSquash
//
//  Created by 0 on 2/1/2026.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var dropWindow: DropWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        dropWindow = DropWindow()
        dropWindow.makeKeyAndOrderFront(nil)
    }
}

