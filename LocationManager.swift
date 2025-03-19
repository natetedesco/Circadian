import Foundation
import CoreLocation

// Extension to provide readable descriptions for CLAuthorizationStatus
extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized Always"
        case .authorizedWhenInUse: return "Authorized When In Use"
        @unknown default: return "Unknown"
        }
    }
}

@Observable class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus
    var errorMessage: String?
    
    override init() {
        print("🔍 LocationManager: Initializing")
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        print("🔍 LocationManager: Initial authorization status: \(authorizationStatus.description)")
    }
    
    func requestLocation() {
        print("🔍 LocationManager: Requesting location authorization")
        locationManager.requestWhenInUseAuthorization()
        print("🔍 LocationManager: Requesting location update")
        locationManager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ LocationManager: Authorization granted")
            print("🔍 LocationManager: Requesting location after authorization")
            locationManager.requestLocation()
        case .denied:
            print("❌ LocationManager: Authorization denied by user")
            errorMessage = "Location access denied. Please enable in Settings."
        case .restricted:
            print("⚠️ LocationManager: Authorization restricted")
            errorMessage = "Location access restricted."
        case .notDetermined:
            print("⏳ LocationManager: Authorization not determined yet")
        @unknown default:
            print("❓ LocationManager: Unknown authorization status")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.first else {
            print("⚠️ LocationManager: Received empty locations array")
            return
        }
        
        print("✅ LocationManager: Received location update - lat: \(newLocation.coordinate.latitude), long: \(newLocation.coordinate.longitude)")
        location = newLocation
        errorMessage = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
        print("❌ LocationManager: Failed with error: \(error.localizedDescription)")
        if let clError = error as? CLError {
            print("❌ LocationManager: CLError code: \(clError.code.rawValue)")
        }
    }
}
