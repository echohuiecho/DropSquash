//
//  DropZoneView.swift
//  DropSquash
//
//  Created by 0 on 2/1/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @StateObject private var dropState = DropState()

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: dropState.isHovering ?
                            [Color.blue.opacity(0.6), Color.purple.opacity(0.6)] :
                            [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 10)

            // Icon/Status
            VStack(spacing: 8) {
                if dropState.isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(.circular)
                } else if dropState.showSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: dropState.isHovering ? "arrow.down.circle.fill" : "doc.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }

                if !dropState.statusText.isEmpty {
                    Text(dropState.statusText)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .frame(width: 120, height: 120)
        .scaleEffect(dropState.isHovering ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: dropState.isHovering)
        .animation(.spring(response: 0.3), value: dropState.showSuccess)
        .onDrop(of: [.fileURL], isTargeted: $dropState.isHovering) { providers in
            dropState.handleDrop(providers: providers)
            return true
        }
    }
}

