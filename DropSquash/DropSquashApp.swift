//
//  DropSquashApp.swift
//  DropSquash
//
//  Created by 0 on 2/1/2026.
//

import SwiftUI

@main
struct DropSquashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
