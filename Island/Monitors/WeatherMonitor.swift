//
//  WeatherMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 15/10/2026.
//

import Foundation
import Combine
import CoreLocation
import MapKit

struct WeatherData: Codable, Equatable {
    let temperatureC: Double
    let apparentTemperatureC: Double
    let weatherCode: Int
    let highC: Double
    let lowC: Double
    let cityName: String
    let fetchedAt: Date
}

@MainActor
final class WeatherMonitor: ObservableObject {
    static let shared = WeatherMonitor()
    
    @Published private(set) var weather: WeatherData?
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?
    
    private var refreshTimer: Timer?
    private var locationCancellable: AnyCancellable?
    
    private let cacheKey = "weather.cachedData"
    
    private init() {
        loadFromCache()
    }
    
    func start() {
        // Observe location changes
        locationCancellable = LocationPermissionManager.shared
            .$lastLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                Task { await self?.fetch(for: location) }
            }
        
        // Kick off location
        LocationPermissionManager.shared.requestPermission()
        
        // Refresh every 15 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if let location = LocationPermissionManager.shared.lastLocation {
                    await self?.fetch(for: location)
                }
            }
        }
    }
    
    func refresh() {
        guard let location = LocationPermissionManager.shared.lastLocation else { return }
        Task { await fetch(for: location) }
    }
    
    private func fetch(for location: CLLocation) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude", value: "\(lat)"),
            .init(name: "longitude", value: "\(lon)"),
            .init(name: "current", value: "temperature_2m,apparent_temperature,weather_code"),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "1")
        ]
        
        guard let url = components.url else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(OpenMeteoResponse.self, from: data)
            
            let cityName = await reverseGeocode(location: location)
            
            let weatherData = WeatherData(
                temperatureC: response.current.temperature_2m,
                apparentTemperatureC: response.current.apparent_temperature,
                weatherCode: response.current.weather_code,
                highC: response.daily.temperature_2m_max.first ?? 0,
                lowC: response.daily.temperature_2m_min.first ?? 0,
                cityName: cityName,
                fetchedAt: Date()
            )
            
            self.weather = weatherData
            saveToCache(weatherData)
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    private func reverseGeocode(location: CLLocation) async -> String {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return "Unknown"
        }
        
        do {
            let mapItems = try await request.mapItems
            guard let mapItem = mapItems.first else { return "Unknown" }
            
            // Try to get the city name from address representations
            let representations = mapItem.addressRepresentations
            return representations?.cityName ?? representations?.cityWithContext ?? "Unknown"
        } catch {
            return "Unknown"
        }
    }
    
    private func saveToCache(_ data: WeatherData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(WeatherData.self, from: data) else {
            return
        }
        self.weather = cached
    }
    
    // MARK: - Unit Conversion
    
    func displayTemp(_ celsius: Double) -> String {
        let useFahrenheit = Locale.current.measurementSystem == .us
        let value = useFahrenheit ? (celsius * 9/5 + 32) : celsius
        return "\(Int(value.rounded()))°"
    }
    
    func displayTempWithUnit(_ celsius: Double) -> String {
        let useFahrenheit = Locale.current.measurementSystem == .us
        let value = useFahrenheit ? (celsius * 9/5 + 32) : celsius
        return "\(Int(value.rounded()))°\(useFahrenheit ? "F" : "C")"
    }
}

// MARK: - Open-Meteo Response

private struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let daily: DailyWeather
    
    struct CurrentWeather: Codable {
        let temperature_2m: Double
        let apparent_temperature: Double
        let weather_code: Int
    }
    
    struct DailyWeather: Codable {
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
    }
}
