import SwiftUI
import CoreLocation
import WeatherKit

struct WeatherKitTest: View {
    @Environment(LocationManager.self) var locationManager
    @Environment(WeatherService.self) var weatherService
    @State private var testResult: String = "Tap to test WeatherKit"
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("WeatherKit Test")
                .font(.title)
                .fontWeight(.bold)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            }
            
            Text(testResult)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.5))
                .cornerRadius(16)
                .padding(.horizontal)
            
            Button(action: {
                requestLocationAndTestWeatherKit()
            }) {
                Text("Test WeatherKit")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.mint)
                    .cornerRadius(16)
                    .padding(.horizontal)
            }
        }
        .padding()
        .onAppear {
            // Request location when view appears
            locationManager.requestLocation()
        }
    }
    
    private func requestLocationAndTestWeatherKit() {
        isLoading = true
        testResult = "Requesting location..."
        
        // Check if we have location permission
        if locationManager.authorizationStatus != .authorizedWhenInUse && 
           locationManager.authorizationStatus != .authorizedAlways {
            isLoading = false
            testResult = "Location permission denied. Please enable location services for this app in Settings."
            return
        }
        
        // Check if we have a location
        guard let location = locationManager.location else {
            locationManager.requestLocation()
            isLoading = false
            testResult = "Waiting for location... Please try again in a moment."
            return
        }
        
        // Test WeatherKit with the location
        Task {
            let result = await weatherService.testWeatherKit(for: location)
            
            // Update UI on main thread
            await MainActor.run {
                isLoading = false
                testResult = result
            }
        }
    }
}
