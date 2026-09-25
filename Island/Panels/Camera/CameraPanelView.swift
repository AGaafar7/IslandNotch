//
//  CameraPanelView.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import SwiftUI
import AVFoundation

struct CameraPanelView: View {
    var onClose: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            CameraPreviewRepresentable()
                .frame(width: 400, height: 225) // 16:9 aspect
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            
            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, .black.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(8)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(8)
        .onAppear {
            CompactState.shared.setCameraOpen(true)
        }
        .onDisappear {
            CompactState.shared.setCameraOpen(false)
        }
    }
}

// MARK: - AppKit Bridge

struct CameraPreviewRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> CameraPreviewNSView {
        return CameraPreviewNSView()
    }
    
    func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        // Nothing to update — the layer manages itself
    }
}

final class CameraPreviewNSView: NSView {
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var isConfigured = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupSession()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
        previewLayer.frame = bounds
    }
    
    private func setupSession() {
        guard !isConfigured else { return }
        isConfigured = true
        
        captureSession.sessionPreset = .medium
        
        // Find front camera
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {
            print("[CameraPanelView] No front camera available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard captureSession.canAddInput(input) else { return }
            captureSession.addInput(input)
        } catch {
            print("[CameraPanelView] Failed to create camera input: \(error)")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        layer?.addSublayer(previewLayer)
        
        // Start on a background queue — this blocks
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        
        if newWindow == nil {
            // View is being removed — stop the session
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
}
