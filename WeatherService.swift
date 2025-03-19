
import Foundation
import WeatherKit
import CoreLocation

@Observable class WeatherService {
    private let weatherService = WeatherKit.WeatherService()
    
    var currentWeather: CurrentWeather?
    var hourlyForecast: Forecast<HourWeather>?
    var dailyForecast: Forecast<DayWeather>?
    
    var isLoading = false
    var errorMessage: String?
    
    // Fetch current weather for a location
    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Request current weather
            let currentWeatherData = try await weatherService.weather(for: location, including: .current)
            currentWeather = currentWeatherData
            
            // Request hourly forecast for the next 24 hours
            let hourlyForecastData = try await weatherService.weather(for: location, including: .hourly)
            hourlyForecast = hourlyForecastData
            
            // Request daily forecast for the next 10 days
            let dailyForecastData = try await weatherService.weather(for: location, including: .daily)
            dailyForecast = dailyForecastData
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
            print("WeatherKit error: \(error)")
        }
    }
    
    // Test function to check if WeatherKit is working
    func testWeatherKit(for location: CLLocation) async -> String {
        do {
            let weather = try await weatherService.weather(for: location, including: .current)
            return "WeatherKit is working! Current temperature: \(weather.temperature.formatted())"
        } catch {
            return "WeatherKit error: \(error.localizedDescription)"
        }
    }
}
