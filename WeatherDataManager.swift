import Foundation
import WeatherKit
import CoreLocation
import SwiftUI

@Observable class WeatherDataManager {
    private let weatherService = WeatherKit.WeatherService()
    private var locationManager: LocationManager?
    
    // Weather data
    var currentWeather: CurrentWeather?
    var hourlyForecast: Forecast<HourWeather>?
    var dailyForecast: Forecast<DayWeather>?
    
    // Status
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?
    
    init() {
        // Simple initialization with no dependencies
    }
    
    func setLocationManager(_ manager: LocationManager) {
        self.locationManager = manager
    }
    
    // Fetch weather data and update all models
    func fetchWeatherData(temperatureModel: TemperatureModel? = nil, daylightModel: DaylightModel? = nil, 
                         uvModel: UVModel? = nil, rainModel: RainModel? = nil, windModel: WindModel? = nil) async {
        print("📍 WeatherDataManager: Starting fetch with location manager: \(locationManager != nil ? "available" : "nil")")
        
        guard let locationManager = locationManager, let location = locationManager.location else {
            errorMessage = "Location not available. Please enable location services."
            print("❌ WeatherDataManager: Location not available")
            return
        }
        
        print("📍 WeatherDataManager: Using location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 WeatherDataManager: Fetching weather data from WeatherKit...")
            // Fetch all weather data in parallel
            async let currentWeatherTask = weatherService.weather(for: location, including: .current)
            async let hourlyForecastTask = weatherService.weather(for: location, including: .hourly)
            async let dailyForecastTask = weatherService.weather(for: location, including: .daily)
            
            // Wait for all requests to complete
            let (current, hourly, daily) = try await (currentWeatherTask, hourlyForecastTask, dailyForecastTask)
            print("✅ WeatherDataManager: Successfully fetched weather data")
            
            // Store the raw data
            self.currentWeather = current
            self.hourlyForecast = hourly
            self.dailyForecast = daily
            
            print("📊 WeatherDataManager: Current temperature: \(current.temperature.converted(to: .fahrenheit).value)°F")
            print("📊 WeatherDataManager: Current condition: \(current.condition.description)")
            
            // Update all models with the new data if they were provided
            if let temperatureModel = temperatureModel {
                print("🌡️ WeatherDataManager: Updating temperature model")
                updateTemperatureModel(temperatureModel: temperatureModel, hourly: hourly)
            }
            
            if let daylightModel = daylightModel {
                print("☀️ WeatherDataManager: Updating daylight model")
                updateDaylightModel(daylightModel: daylightModel, daily: daily)
            }
            
            if let uvModel = uvModel {
                print("🌞 WeatherDataManager: Updating UV model")
                updateUVModel(uvModel: uvModel, hourly: hourly)
            }
            
            if let rainModel = rainModel {
                print("🌧️ WeatherDataManager: Updating rain model")
                updateRainModel(rainModel: rainModel, hourly: hourly)
            }
            
            if let windModel = windModel {
                print("💨 WeatherDataManager: Updating wind model")
                updateWindModel(windModel: windModel, hourly: hourly)
            }
            
            lastUpdated = Date()
            isLoading = false
            print("✅ WeatherDataManager: Weather data update completed at \(lastUpdated!)")
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
            print("❌ WeatherDataManager: Error fetching weather: \(error)")
            print("❌ WeatherDataManager: Error details: \(error.localizedDescription)")
        }
    }
    
    // Update temperature model with real data
    private func updateTemperatureModel(temperatureModel: TemperatureModel, hourly: Forecast<HourWeather>) {
        // Get the current date for reference
        let now = Date.now
        let calendar = Calendar.current
        
        // Create a 24-hour array aligned to midnight
        var alignedTemperatures = Array(repeating: 0.0, count: 24)
        
        // Extract temperatures and place them at the correct hour positions
        for hour in hourly.forecast.prefix(48) { // Look at more hours to ensure we have a full day
            let hourDate = hour.date
            let hourOfDay = calendar.component(.hour, from: hourDate)
            let tempInFahrenheit = hour.temperature.converted(to: .fahrenheit).value
            
            // Only use data for the next 24 hours
            let hoursSinceNow = calendar.dateComponents([.hour], from: now, to: hourDate).hour ?? 0
            if hoursSinceNow >= 0 && hoursSinceNow < 24 {
                alignedTemperatures[hourOfDay] = tempInFahrenheit
            }
        }
        
        // Update the model
        temperatureModel.hourlyTemperatures = alignedTemperatures
    }
    
    // Update daylight model with real data
    private func updateDaylightModel(daylightModel: DaylightModel, daily: Forecast<DayWeather>) {
        guard let today = daily.forecast.first else { return }
        
        if let sunrise = today.sun.sunrise, let sunset = today.sun.sunset {
            // Update the model with the actual sunrise and sunset times
            // The positions will be automatically calculated by the computed properties
            daylightModel.sunriseTime = sunrise
            daylightModel.sunsetTime = sunset
            
            // Recalculate sun events based on new times
            daylightModel.calculateSunEvents()
        }
    }
    
    // Update UV model with real data
    private func updateUVModel(uvModel: UVModel, hourly: Forecast<HourWeather>) {
        // Get the current date for reference
        let now = Date.now
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        print("🌞 WeatherDataManager: Current hour is \(currentHour)")
        print("🌞 WeatherDataManager: First forecast hour is \(hourly.forecast.first?.date ?? now)")
        
        // Create a 24-hour array aligned to midnight
        var alignedUVIndices = Array(repeating: 0.0, count: 24)
        
        // Extract UV indices and place them at the correct hour positions
        for hour in hourly.forecast.prefix(48) { // Look at more hours to ensure we have a full day
            let hourDate = hour.date
            let hourOfDay = calendar.component(.hour, from: hourDate)
            let uvValue = Double(hour.uvIndex.value)
            
            // Only use data for the next 24 hours
            let hoursSinceNow = calendar.dateComponents([.hour], from: now, to: hourDate).hour ?? 0
            if hoursSinceNow >= 0 && hoursSinceNow < 24 {
                print("🌞 WeatherDataManager: Hour \(hoursSinceNow) from now (\(hourOfDay):00): UV: \(uvValue)")
                alignedUVIndices[hourOfDay] = uvValue
            }
        }
        
        // Log the aligned array
        print("🌞 WeatherDataManager: Aligned UV array (by hour of day): \(alignedUVIndices)")
        
        // Update the model
        uvModel.hourlyUVIndices = alignedUVIndices
    }
    
    // Update rain model with real data
    private func updateRainModel(rainModel: RainModel, hourly: Forecast<HourWeather>) {
        // Get the current date for reference
        let now = Date.now
        let calendar = Calendar.current
        
        // Create a 24-hour array aligned to midnight
        var alignedRainProbabilities = Array(repeating: 0.0, count: 24)
        
        // Extract precipitation chances and place them at the correct hour positions
        for hour in hourly.forecast.prefix(48) { // Look at more hours to ensure we have a full day
            let hourDate = hour.date
            let hourOfDay = calendar.component(.hour, from: hourDate)
            let probability = hour.precipitationChance
            
            // Only use data for the next 24 hours
            let hoursSinceNow = calendar.dateComponents([.hour], from: now, to: hourDate).hour ?? 0
            if hoursSinceNow >= 0 && hoursSinceNow < 24 {
                alignedRainProbabilities[hourOfDay] = probability
            }
        }
        
        // Update the model
        rainModel.hourlyRainProbabilities = alignedRainProbabilities
    }
    
    // Update wind model with real data
    private func updateWindModel(windModel: WindModel, hourly: Forecast<HourWeather>) {
        // Get the current date for reference
        let now = Date.now
        let calendar = Calendar.current
        
        // Create 24-hour arrays aligned to midnight
        var alignedWindSpeeds = Array(repeating: 0.0, count: 24)
        var alignedWindDirections = Array(repeating: "N", count: 24)
        
        // Extract wind data and place it at the correct hour positions
        for hour in hourly.forecast.prefix(48) { // Look at more hours to ensure we have a full day
            let hourDate = hour.date
            let hourOfDay = calendar.component(.hour, from: hourDate)
            
            // Convert to mph as required by user preference
            let speedInMPH = hour.wind.speed.converted(to: .milesPerHour).value
            
            // Only use data for the next 24 hours
            let hoursSinceNow = calendar.dateComponents([.hour], from: now, to: hourDate).hour ?? 0
            if hoursSinceNow >= 0 && hoursSinceNow < 24 {
                alignedWindSpeeds[hourOfDay] = speedInMPH
                // Convert full compass direction to abbreviated form
                alignedWindDirections[hourOfDay] = abbreviateWindDirection(hour.wind.compassDirection.description)
            }
        }
        
        // Update the model
        windModel.hourlyWindSpeeds = alignedWindSpeeds
        windModel.hourlyWindDirections = alignedWindDirections
    }
    
    // Helper function to convert full compass directions to abbreviated form
    private func abbreviateWindDirection(_ fullDirection: String) -> String {
        switch fullDirection.lowercased() {
        case "north": return "N"
        case "northeast": return "NE"
        case "east": return "E"
        case "southeast": return "SE"
        case "south": return "S"
        case "southwest": return "SW"
        case "west": return "W"
        case "northwest": return "NW"
        default: return fullDirection.prefix(2).uppercased() // Fallback to first 2 chars if unknown
        }
    }
}
