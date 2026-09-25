//
//  WeatherPane.swift
//  Island
//
//  Created by Ahmed Gaafar on 15/10/2026.
//

import SwiftUI

struct WeatherPane: View {
    @ObservedObject private var monitor = WeatherMonitor.shared
    
    var body: some View {
        Group {
            if let weather = monitor.weather {
                content(weather)
            } else if monitor.isLoading {
                loadingView
            } else {
                emptyView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            monitor.refresh()
        }
    }
    
    private func content(_ weather: WeatherData) -> some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: symbolFor(weather.weatherCode))
                .font(.system(size: 44))
                .foregroundStyle(iconColor(weather.weatherCode))
                .symbolRenderingMode(.hierarchical)
            
            // Temperature
            VStack(alignment: .leading, spacing: 2) {
                Text(monitor.displayTemp(weather.temperatureC))
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(conditionText(weather.weatherCode))
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            // High/Low + City
            VStack(alignment: .trailing, spacing: 4) {
                Text(weather.cityName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("H: \(monitor.displayTemp(weather.highC))")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("L: \(monitor.displayTemp(weather.lowC))")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Text(fetchedText(weather.fetchedAt))
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
    
    private var loadingView: some View {
        VStack(spacing: 6) {
            ProgressView()
                .controlSize(.small)
            Text("Fetching weather…")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.3))
            Text("Weather unavailable")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
    
    // MARK: - Weather Code Mapping
    
    private func conditionText(_ code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1: return "Mostly Clear"
        case 2: return "Partly Cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing Drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing Rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow Grains"
        case 80, 81, 82: return "Rain Showers"
        case 85, 86: return "Snow Showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm"
        default: return "—"
        }
    }
    
    private func symbolFor(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1: return "sun.max"
        case 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 56, 57: return "cloud.sleet.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 66, 67: return "cloud.sleet.fill"
        case 71, 73, 75: return "cloud.snow.fill"
        case 77: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 85, 86: return "cloud.snow.fill"
        case 95: return "cloud.bolt.rain.fill"
        case 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud"
        }
    }
    
    private func iconColor(_ code: Int) -> Color {
        switch code {
        case 0, 1: return .yellow
        case 2: return .white
        case 3, 45, 48: return .gray
        case 51...57, 61...67: return .blue
        case 71...77, 85, 86: return .cyan
        case 80...82: return .blue
        case 95, 96, 99: return .purple
        default: return .white
        }
    }
    
    private func fetchedText(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        return "\(Int(interval / 3600))h ago"
    }
}
