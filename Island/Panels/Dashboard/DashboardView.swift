//
//  DashboardView.swift
//  Island
//
//  Created by Ahmed Gaafar on 10/10/2026.
//

import SwiftUI

struct DashboardView: View {
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showDots = true
    @State private var dotsTimer: Timer?
    
    var onClose: () -> Void
    
    private let pageWidth: CGFloat = 720
    private let pageHeight: CGFloat = 160
    private let pageCount = 6  // Home, Weather, Stats, Screenshots, Clock, Usage
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Paging content
            HStack(spacing: 0) {
                HomePane()
                    .frame(width: pageWidth, height: pageHeight)
                
                WeatherPane()
                    .frame(width: pageWidth, height: pageHeight)
                
                StatsPane()
                    .frame(width: pageWidth, height: pageHeight)
                
                ScreenshotsPane()
                    .frame(width: pageWidth, height: pageHeight)
                
                ClockPane()
                    .frame(width: pageWidth, height: pageHeight)
                
                UsagePane()
                    .frame(width: pageWidth, height: pageHeight)
            }
            .frame(width: pageWidth * CGFloat(pageCount), alignment: .leading)
            .offset(x: -CGFloat(currentPage) * pageWidth + dragOffset)
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.85), value: currentPage)
            .frame(width: pageWidth, alignment: .leading)
            .clipped()
            .onReceive(NotificationCenter.default.publisher(for: .pagingDragChanged)) { notif in
                guard let dx = notif.userInfo?["dx"] as? CGFloat else { return }
                dragOffset = dx
                revealDots()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pagingDragEnded)) { notif in
                guard let dx = notif.userInfo?["dx"] as? CGFloat else { return }
                let threshold: CGFloat = 60
                if dx < -threshold {
                    currentPage = min(currentPage + 1, pageCount - 1)
                } else if dx > threshold {
                    currentPage = max(currentPage - 1, 0)
                }
                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.85)) {
                    dragOffset = 0
                }
            }
            .onAppear { print("[Dashboard] appeared") }
            .onDisappear { print("[Dashboard] disappeared") }
            
            // Close button (top-right)
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                    .padding(.trailing, 12)
                    .padding(.top, 10)
                }
                Spacer()
            }
            
            // Dots
            if showDots {
                HStack(spacing: 6) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.trailing, 14)
                .padding(.bottom, 12)
                .transition(.opacity)
            }
        }
        .frame(width: pageWidth, height: pageHeight)
    }
    
    private func revealDots() {
        dotsTimer?.invalidate()
        showDots = true
        dotsTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                showDots = false
            }
        }
    }
}

struct HomePane: View {
    var body: some View {
        HStack(spacing: 0) {
            MusicPane()
                .frame(width: 240)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            Divider().background(Color.white.opacity(0.12))
            
            CalendarPane()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            Divider().background(Color.white.opacity(0.12))
            
            MirrorPane()
                .frame(width: 100)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }
}
