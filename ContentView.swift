//
//  ContentView.swift
//  Circadian
//  Created by Developer on 3/18/25.
//

import SwiftUI

@Observable class Model {
    var currentTime = Date()
    var currentTimePosition: CGFloat = 0
    var activeRing: String? = nil // Tracks which ring is currently being interacted with
    
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
            
            ///
            /// Circles
            ZStack {
                ClockDisplay()
                
                // Temperature Ring (outermost)
                if model.activeRing == nil || model.activeRing == "temperature" {
                    TemperatureRing(
                        size: ringSize(for: "temperature", baseSize: size),
                        lineWidth: ringWidth(for: "temperature"),
                        color: .red,
                        currentTimePosition: model.currentTimePosition,
                        temperatureData: model.temperatureModel.hourlyTemperaturesAsCGFloat,
                        minTemp: model.temperatureModel.minHourlyTemp,
                        maxTemp: model.temperatureModel.maxHourlyTemp,
                        icon: "thermometer.high",
                        onPositionChanged: { newPosition in
                            model.updateFromPosition(newPosition)
                        },
                        onDragStarted: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                model.activeRing = "temperature"
                            }
                        },
                        onDragEnded: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                // Update position back to current time
                                model.updateCurrentTimePosition()
                                model.updateFromPosition(model.currentTimePosition)
                                model.activeRing = nil
                                medHaptic()
                            }
                        }
                    )
                }
                
                // Daylight Ring (inner ring)
                if model.activeRing == nil || model.activeRing == "daylight" {
                    CircularDaylightRing(
                        size: ringSize(for: "daylight", baseSize: size),
                        lineWidth: ringWidth(for: "daylight"),
                        color: .orange,
                        currentTimePosition: model.currentTimePosition,
                        sunrisePosition: model.daylightModel.sunrisePosition,
                        sunsetPosition: model.daylightModel.sunsetPosition,
                        icon: "sun.max.fill",
                        onPositionChanged: { newPosition in
                            model.updateFromPosition(newPosition)
                        },
                        onDragStarted: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                model.activeRing = "daylight"
                            }
                        },
                        onDragEnded: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                // Update position back to current time
                                model.updateCurrentTimePosition()
                                model.updateFromPosition(model.currentTimePosition)
                                model.activeRing = nil
                                medHaptic()
                            }
                        }
                    )
                }
            }
            
            Spacer()
            
            ///
            /// Legend
            Card {
                if model.activeRing == nil || model.activeRing == "temperature" {
                    if model.activeRing == "temperature" {
                        // Show current temperature when sliding
                        WeatherRow("Temperature:", "\(Int(model.temperatureModel.currentTemp))°", .red)
                    } else {
                        // Show temperature range when not sliding
                        WeatherRow("Temperature:", "\(Int(model.temperatureModel.minHourlyTemp))° - \(Int(model.temperatureModel.maxHourlyTemp))°", .red)
                    }
                }
                
                if model.activeRing == nil {
                    Divider().padding(.horizontal, -16)
                }
                
                if model.activeRing == nil || model.activeRing == "daylight" {
                    WeatherRow("Daylight:", "\(model.daylightModel.formattedDaylightRange)", .orange)
                }
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: model.activeRing)
        }
    }
}
    
#Preview {
    ContentView()
}






