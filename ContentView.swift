//
//  ContentView.swift
//  Circadian
//  Created by Developer on 3/18/25.
//

import SwiftUI

@Observable class Model {
    var currentTime = Date()
    var currentTimePosition: CGFloat = 0
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: currentTime)
    }
    var amPm: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: currentTime).lowercased()
    }
    var currentTimePercentage: CGFloat {
        return currentTimePosition
    }
    
    var temperatureModel = TemperatureModel()
    var daylightModel = DaylightModel()
    
    init() {
        updateCurrentTimePosition()
        updateModelsFromTime()
    }
    
    // Update current time position based on actual time
    func updateCurrentTimePosition() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let second = calendar.component(.second, from: currentTime)
        
        let totalSeconds = (hour * 3600) + (minute * 60) + second
        currentTimePosition = CGFloat(totalSeconds) / CGFloat(24 * 3600)
    }
    
    // Update all models based on current time
    func updateModelsFromTime() {
        temperatureModel.updateTemperatureFromTime(currentTimePosition)
    }
    
    // Update time and all models based on position
    func updateFromPosition(_ position: CGFloat) {
        currentTimePosition = position
        
        // Calculate time from position
        let secondsInDay = 24 * 60 * 60
        let totalSeconds = Int(position * Double(secondsInDay))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        // Create a date with these hours and minutes
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hours
        components.minute = minutes
        components.second = 0
        
        if let newTime = calendar.date(from: components) {
            currentTime = newTime
        }
        
        // Update all models based on new position
        updateModelsFromTime()
    }
}

struct ContentView: View {
    @Environment(Model.self) var model
    
    var body: some View {
        VStack {
            TodayHeaderView()
            
            Spacer()
            
            ///
            /// Circles
            ZStack {
                ClockDisplay()
                
                // Temperature Ring (outermost)
                TemperatureRing(
                    size: size,
                    lineWidth: width,
                    color: model.temperatureModel.tempColor,
                    currentTimePosition: model.currentTimePercentage,
                    temperatureData: model.temperatureModel.hourlyTemperaturesAsCGFloat,
                    minTemp: model.temperatureModel.minHourlyTemp,
                    maxTemp: model.temperatureModel.maxHourlyTemp,
                    icon: "thermometer.high",
                    onPositionChanged: { newPosition in
                        model.updateFromPosition(newPosition)
                    }
                )
                
                // Daylight Ring (inner ring)
                CircularDaylightRing(
                    size: size - width * 2 - 16, // Make it smaller than temperature ring
                    lineWidth: width,
                    color: model.daylightModel.daylightColor,
                    currentTimePosition: model.currentTimePercentage,
                    sunrisePosition: model.daylightModel.sunrisePosition,
                    sunsetPosition: model.daylightModel.sunsetPosition,
                    icon: "sun.max",
                    onPositionChanged: { newPosition in
                        model.updateFromPosition(newPosition)
                    }
                )
            }
            
            Spacer()
            
            ///
            /// Legend
            Card {
                WeatherRow("Temperature:", "\(Int(model.temperatureModel.currentTemp))°", .red)
                
                Divider().padding(.horizontal, -16)
                
                WeatherRow("Daylight:", "\(model.daylightModel.formattedDaylightRange)", .orange)
            }
        }
    }
}
    
#Preview {
    ContentView()
}






