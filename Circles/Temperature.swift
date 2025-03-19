//
//  Temperature Circle.swift
//  Circadian
//  Created by Developer on 3/18/25.
//

import SwiftUI

@Observable class TemperatureModel {
    var currentTemp: Double = 72.0
    var maxTemp: Double = 85.0
    var minTemp: Double = 55.0
    
    // Access global layout constants
    var size: CGFloat { Circadian.size }
    var width: CGFloat { Circadian.width }
    
    var hourlyTemperatures: [Double] = [
        62, 60, 58, 57, 55, 56,  // 12am-5am (midnight to pre-dawn)
        58, 60, 64, 68, 72, 76,  // 6am-11am (morning)
        80, 83, 85, 84, 82, 78,  // 12pm-5pm (noon to afternoon)
        74, 70, 68, 66, 64, 62   // 6pm-11pm (evening)
    ]
    
    // Get hourly temperatures as CGFloat array
    var hourlyTemperaturesAsCGFloat: [CGFloat] {
        return hourlyTemperatures.map { CGFloat($0) }
    }
    
    // Get min and max temperatures from hourly data
    var minHourlyTemp: CGFloat {
        return CGFloat(hourlyTemperatures.min() ?? minTemp)
    }
    
    var maxHourlyTemp: CGFloat {
        return CGFloat(hourlyTemperatures.max() ?? maxTemp)
    }
    
    // Update temperature based on time
    func updateTemperatureFromTime(_ timePosition: CGFloat) {
        let hourIndex = Int(timePosition * 24) % 24
        currentTemp = hourlyTemperatures[hourIndex]
    }
}

struct TemperatureRing: View {
    var size: CGFloat
    var lineWidth: CGFloat
    var color: Color
    var currentTimePosition: CGFloat
    var temperatureData: [CGFloat]  // Array of temperature values for 24 hours
    var minTemp: CGFloat
    var maxTemp: CGFloat
    var icon: String
    var onPositionChanged: (CGFloat) -> Void
    var onDragStarted: () -> Void = {}
    var onDragEnded: () -> Void = {}
    
    @State private var isDragging = false
    @State private var lastFeedbackPosition: CGFloat = -1  // Track last haptic feedback position
    private func createTemperatureGradient() -> Gradient {
        var stops: [Gradient.Stop] = []
        
        // Create gradient stops for each hour
        for (index, temp) in temperatureData.enumerated() {
            // Adjust position to have midnight at top (shift by 0.5)
            let position = (CGFloat(index) / CGFloat(temperatureData.count))
            
            // Calculate opacity based on temperature (0 at minTemp, 1 at maxTemp)
            let normalizedTemp = (temp - minTemp) / (maxTemp - minTemp)
            let opacity = max(0.1, normalizedTemp) // Ensure minimum opacity of 0.1 for visibility
            
            stops.append(Gradient.Stop(color: color.opacity(Double(opacity)), location: position))
        }
        
        return Gradient(stops: stops)
    }
    
    @Environment(Model.self) private var model
    
    // Calculate the gap as a percentage based on the ring size and active state
    private var midnightGap: CGFloat {
        // Use expanded gap size when ring is active
        let gapSize = model.activeRing == "temperature" ? midnightGapExpandedPixels : midnightGapPixels
        
        // Convert fixed pixel gap to a percentage of the circumference
        // Circumference = π * diameter = π * size
        // Gap percentage = gap size / circumference
        return gapSize / (CGFloat.pi * size)
    }
    
    var body: some View {
        ZStack {
            // Background ring with gap at midnight
            Circle()
                .trim(from: midnightGap, to: 1.0 - midnightGap)
                .stroke(Color.gray.opacity(0.05), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(90)) // Adjust so 0 is at top (12 o'clock position)
                .frame(width: size)
            
            // Temperature gradient ring with gap at midnight
            Circle()
                .trim(from: midnightGap, to: 1.0 - midnightGap)
                .stroke(
                    AngularGradient(
                        gradient: createTemperatureGradient(),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(90)) // Adjust so 0 is at top (12 o'clock position)
                .frame(width: size)
            
            // Current time position indicator with icon
            ZStack {
                Circle()
                    .fill(.regularMaterial)
                    .colorScheme(.light)
                    .frame(width: lineWidth * 1.2, height: lineWidth * 1.2)
                    .shadow(color: .black.opacity(0.2), radius: isDragging ? 4 : 2, x: 0, y: 0)
                
                // Add the icon inside the position indicator circle
                Image(systemName: icon)
                    .font(.system(size: lineWidth * 0.6))
                    .foregroundColor(color)
                    .colorScheme(.light)
                    .fontWeight(.bold)
            }
            .offset(y: -size / 2)
            .rotationEffect(.degrees(360 * Double(currentTimePosition) + 180)) // Adjusted to match new orientation
        }
        .circularDragGesture(
            size: size,
            isDragging: $isDragging,
            onDragStarted: onDragStarted,
            onDragEnded: onDragEnded,
            onPositionChanged: onPositionChanged,
            handleFeedback: { percentage in
                // Provide haptic feedback every hour (1/24 of the circle)
                let hourPosition = Int(percentage * 24)
                if hourPosition != Int(lastFeedbackPosition * 24) {
                    medHaptic()
                    lastFeedbackPosition = percentage
                }
            }
        )
    }
}


//#Preview {
//    CircularRing()
//}
