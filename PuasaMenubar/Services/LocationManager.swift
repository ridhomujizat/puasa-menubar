import Foundation
import CoreLocation
import AppKit

@MainActor
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var cityName: String = "Unknown"
    @Published var countryName: String = "Unknown"
    @Published var isRequestingPermission = false
    @Published var permissionRequested = false
    
    var hasPermission: Bool {
        return authorizationStatus == .authorized || authorizationStatus == .authorizedAlways
    }
    
    var latitude: Double? {
        return location?.coordinate.latitude
    }
    
    var longitude: Double? {
        return location?.coordinate.longitude
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = locationManager.authorizationStatus
        
        print("LocationManager initialized, status: \(authorizationStatus.rawValue)")
    }
    
    func requestPermission() {
        print("Requesting location permission...")
        
        // Activate the app to ensure dialog appears
        NSApp.activate(ignoringOtherApps: true)
        NSApp.setActivationPolicy(.accessory)
        
        isRequestingPermission = true
        permissionRequested = true
        locationManager.requestWhenInUseAuthorization()
        
        print("Permission request sent")
    }
    
    func startUpdatingLocation() {
        if hasPermission {
            print("Starting location updates...")
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func reverseGeocode() async {
        guard let location = location else { return }
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            await MainActor.run {
                if let placemark = placemarks.first {
                    self.cityName = placemark.locality ?? placemark.administrativeArea ?? "Unknown"
                    self.countryName = placemark.country ?? "Unknown"
                    print("Location: \(self.cityName), \(self.countryName)")
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to get location name"
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            print("Location updated: \(locations.first?.coordinate.latitude ?? 0), \(locations.first?.coordinate.longitude ?? 0)")
            location = locations.first
            errorMessage = nil
            isRequestingPermission = false
            // One fix is enough — stop draining GPS/battery
            manager.stopUpdatingLocation()

            Task {
                await reverseGeocode()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("Location error: \(error.localizedDescription)")
            errorMessage = "Location error: \(error.localizedDescription)"
            isRequestingPermission = false
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            isRequestingPermission = false
            
            print("Location auth status changed to: \(manager.authorizationStatus.rawValue)")
            
            switch manager.authorizationStatus {
            case .authorized, .authorizedAlways:
                print("Location permission granted!")
                errorMessage = nil
                startUpdatingLocation()
            case .denied:
                print("Location permission DENIED by user")
                errorMessage = "Location access denied. Please enable in System Settings → Privacy & Security → Location Services."
            case .restricted:
                print("Location permission RESTRICTED")
                errorMessage = "Location access restricted."
            case .notDetermined:
                print("Location permission NOT DETERMINED")
                // Auto-request if not yet requested
                if !permissionRequested {
                    requestPermission()
                }
            @unknown default:
                break
            }
        }
    }
}
