//
//  MirrorPane.swift
//  Island
//
//  Created by Ahmed Gaafar on 10/10/2026.
//

import SwiftUI

struct MirrorPane: View {
    @State private var shouldStartCamera = false
    
    var body: some View {
        VStack(spacing: 6) {
            Group {
                if shouldStartCamera {
                    CameraPreviewRepresentable()
                } else {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundStyle(.white.opacity(0.3))
                        )
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
            
            Image(systemName: "lock.fill")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.4))
        }
        .task {
            // Wait 400ms before spinning up the camera
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            shouldStartCamera = true
        }
    }
}
