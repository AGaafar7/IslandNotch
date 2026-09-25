//
//  WelcomeView.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import SwiftUI

struct WelcomeView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.blue)
                .padding(.top, 30)
            
            Text("Welcome to Island")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("A dynamic notch for your Mac. Island will ask for a few permissions on first launch so it can show you what's happening.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            VStack(alignment: .leading, spacing: 10) {
                permissionRow(
                    icon: "location",
                    title: "Location",
                    description: "To detect Wi-Fi network changes"
                )
                
                permissionRow(
                    icon: "folder",
                    title: "Desktop access",
                    description: "To detect new screenshots"
                )
                
                permissionRow(
                    icon: "camera",
                    title: "Camera",
                    description: "For the mirror preview"
                )
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
        }
        .frame(width: 460, height: 520)
    }
    
    private func permissionRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
