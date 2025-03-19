//
//  Wind Circle.swift
//  Circadian
//
//  Created by Developer on 3/18/25.
//

import SwiftUI

// Struct to represent a wind period
struct WindPeriod {
    var startPosition: CGFloat  // Position on the 24-hour circle (0-1)
    var endPosition: CGFloat    // Position on the 24-hour circle (0-1)
    var intensity: CGFloat      // Intensity of wind (0-1, normalized from speed)
}

@Observable class WindModel {
    var currentWindSpeed: Double = 0.0
    var windDirection: String = "N"
    
    // Threshold for showing wind on the ring (in mph)
    let windThreshold: Double = 5.0
    
    // Maximum wind speed for normalization (in mph)
    let maxWindSpeed: Double = 30.0
    
    // Hourly wind speeds (in mph)
    var hourlyWindSpeeds: [Double] = [
        2.0, 3.0, 3.0, 2.0, 2.0, 3.0,  // 12am-5am (midnight to pre-dawn)
        4.0, 6.0, 8.0, 10.0, 12.0, 15.0,  // 6am-11am (morning) - Wind picks up
        18.0, 20.0, 22.0, 18.0, 15.0, 10.0,  // 12pm-5pm (noon to afternoon) - Peak wind
        8.0, 6.0, 4.0, 3.0, 2.0, 2.0   // 6pm-11pm (evening) - Wind dies down
    ]
    
    // Wind directions for each hour
    var hourlyWindDirections: [String] = [
        "N", "N", "NE", "NE", "NE", "E",
        "E", "E", "SE", "SE", "S", "S",
        "S", "SW", "SW", "W", "W", "NW",
        "NW", "NW", "N", "N", "N", "N"
    ]
    
    // Get hourly wind speeds as CGFloat array
    var hourlyWindSpeedsAsCGFloat: [CGFloat] {
        return hourlyWindSpeeds.map { CGFloat($0) }
    }
    
    // Get wind periods (start and end positions of significant wind)
    var windPeriods: [WindPeriod] {
        var periods: [WindPeriod] = []
        var inWindPeriod = false
        var currentPeriod: WindPeriod? = nil
        var maxIntensity: CGFloat = 0.0
        
        // Find all wind periods above threshold
        for (index, speed) in hourlyWindSpeeds.enumerated() {
            let position = CGFloat(index) / CGFloat(hourlyWindSpeeds.count)
            
            if speed > windThreshold && !inWindPeriod {
                // Start of a wind period
                inWindPeriod = true
                let normalizedIntensity = min(1.0, speed / maxWindSpeed)
                currentPeriod = WindPeriod(startPosition: position, endPosition: position, intensity: CGFloat(normalizedIntensity))
                maxIntensity = CGFloat(normalizedIntensity)
            } else if speed > windThreshold && inWindPeriod {
                // Continuing wind period
                currentPeriod?.endPosition = position
                let normalizedIntensity = min(1.0, speed / maxWindSpeed)
                maxIntensity = max(maxIntensity, CGFloat(normalizedIntensity))
            } else if speed <= windThreshold && inWindPeriod {
                // End of a wind period
                if let period = currentPeriod {
                    var finalPeriod = period
                    finalPeriod.intensity = maxIntensity
                    periods.append(finalPeriod)
                }
                inWindPeriod = false
                currentPeriod = nil
                maxIntensity = 0.0
            }
        }
        
        // Add the last period if we're still in one
        if inWindPeriod, let period = currentPeriod {
            var finalPeriod = period
            finalPeriod.intensity = maxIntensity
            periods.append(finalPeriod)
        }
        
        return periods
    }
    
    // Update wind data based on time
    func updateWindFromTime(_ timePosition: CGFloat) {
        let hourIndex = Int(timePosition * 24) % 24
        currentWindSpeed = hourlyWindSpeeds[hourIndex]
        windDirection = hourlyWindDirections[hourIndex]
    }
    
    // Get formatted wind speed and direction
    func formattedWindInfo(_ speed: Double, direction: String) -> String {
        return "\(Int(speed))mph \(direction)"
    }
}

struct WindRing: View {
    var size: CGFloat
    var lineWidth: CGFloat
    var color: Color
    var currentTimePosition: CGFloat
    var windPeriods: [WindPeriod]
    var icon: String
    var onPositionChanged: (CGFloat) -> Void
    var onDragStarted: () -> Void = {}
    var onDragEnded: () -> Void = {}
    
    @State private var isDragging = false
    @State private var lastFeedbackPosition: CGFloat = -1
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(.gray.opacity(0.1), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size)
            
            // Draw each wind period as a separate arc
            ForEach(0..<windPeriods.count, id: \.self) { index in
                let period = windPeriods[index]
                
                Circle()
                    .trim(from: period.startPosition, to: period.endPosition)
                    .stroke(
                        AngularGradient(
                            stops: [
                                .init(color: color.opacity(0.3), location: 0),
                                .init(color: color.opacity(period.intensity), location: 0.5),
                                .init(color: color.opacity(0.3), location: 1)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90)) // Adjust so 0 is at top (12 o'clock position)
                    .frame(width: size)
            }
            
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
        .frame(width: size, height: size)
        .circularDragGesture(
            size: size,
            isDragging: $isDragging,
            onDragStarted: onDragStarted,
            onDragEnded: onDragEnded,
            onPositionChanged: onPositionChanged,
            handleFeedback: { percentage in
                // Provide haptic feedback when entering or exiting a wind period
                let isInWindPeriod = windPeriods.contains { period in
                    percentage >= period.startPosition && percentage <= period.endPosition
                }
                
                let wasInWindPeriod = windPeriods.contains { period in
                    lastFeedbackPosition >= period.startPosition && lastFeedbackPosition <= period.endPosition
                }
                
                if isInWindPeriod != wasInWindPeriod {
                    medHaptic()
                }
                
                lastFeedbackPosition = percentage
            }
        )
    }
}
