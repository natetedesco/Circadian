//
//  CircadianApp.swift
//  Circadian
//
//  Created by Developer on 3/18/25.
//

import SwiftUI
import WeatherKit
import CoreLocation

@main
struct CircadianApp: App {
    @State var model = Model()
    @State var locationManager = LocationManager()
    @State var weatherService = WeatherService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .environment(locationManager)
                .environment(weatherService)
                .modifier(ContentContainerModifier())
                .onAppear {
                    print("🚀 App launched - starting weather data fetch process")
                    
                    // Request location permissions when app starts
                    locationManager.requestLocation()
                    print("📍 Location permission requested")
                    
                    // Connect the location manager to our model
                    model.setupLocationManager(locationManager)
                    print("🔗 Location manager connected to model")
                    
                    // Fetch weather data once we have location
                    Task {
                        print("⏳ Waiting for location data...")
                        // Wait a bit for location to be available
                        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                        
                        print("🌤️ Starting weather data fetch")
                        await model.fetchWeatherData()
                        print("✅ Weather data fetch completed")
                        
                        // Print debug info about the weather data
                        if let error = model.weatherError {
                            print("❌ Weather fetch error: \(error)")
                        } else if model.lastWeatherUpdate != nil {
                            print("🌡️ Temperature data: \(model.temperatureModel.hourlyTemperatures)")
                            print("☀️ Sunrise: \(model.daylightModel.sunriseTime), Sunset: \(model.daylightModel.sunsetTime)")
                            print("🌞 UV data: \(model.uvModel.hourlyUVIndices)")
                            print("🌧️ Rain data: \(model.rainModel.hourlyRainProbabilities)")
                            print("💨 Wind data: \(model.windModel.hourlyWindSpeeds)")
                        }
                    }
                }
        }
    }
}
