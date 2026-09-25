//
//  LocationPermissionManager.swift
//  Island
//
//  Created by Ahmed Gaafar on 25/09/2026.
//

import CoreLocation
import os
import Combine

@MainActor
final class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()
    
    var onAuthorized: (() -> Void)?
    var onDenied: (() -> Void)?
    
    @Published private(set) var lastLocation: CLLocation?
    
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestPermission() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            onAuthorized?()
            startUpdating()
        case .denied, .restricted:
            onDenied?()
        @unknown default:
            break
        }
    }
    
    private func startUpdating() {
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            Log.location.debug("Authorization status: \(status.rawValue)")
            
            if status == .authorizedAlways {
                self.onAuthorized?()
                self.startUpdating()
            } else if status == .denied || status == .restricted {
                self.onDenied?()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.lastLocation = location
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            Log.location.error("Location error: \(error.localizedDescription)")
        }
    }
}
