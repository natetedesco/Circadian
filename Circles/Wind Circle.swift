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
    
    // Access to global layout constants
    var size: CGFloat { Circadian.size }
    var width: CGFloat { Circadian.width }
    
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
    // Calculate the midnight gap as a percentage for the model
    var midnightGapPercentage: CGFloat {
        // The wind ring is the innermost ring with size = size - width * 8 - 64
        let windRingSize: CGFloat = size - width * 8 - 64 // Using global constants from RingLayout.swift
        return midnightGapPixels / (CGFloat.pi * windRingSize)
    }
    
    var windPeriods: [WindPeriod] {
        // Print the wind speeds for debugging
        print("💨 Wind speeds: \(hourlyWindSpeeds.map { String(format: "%.1f", $0) })")
        
        // Find continuous periods of significant wind for the current day (midnight to midnight)
        var periods: [WindPeriod] = []
        var currentPeriodStart: Int? = nil
        var currentMaxSpeed = 0.0
        
        // Get the midnight gap percentage
        let midnightGap = midnightGapPercentage
        
        // Function to add a period to our list with midnight gap enforcement
        func addPeriod(start: Int, end: Int, maxSpeed: Double) {
            let startPosition = CGFloat(start) / 24.0
            let endPosition = CGFloat(end + 1) / 24.0  // Add 1 to include the full hour
            let intensity = min(1.0, maxSpeed / maxWindSpeed)
            
            // Check if this period crosses midnight
            if start == 0 || end == 23 {
                if start == 0 && end == 23 {
                    // Period spans the entire day, split it at midnight
                    periods.append(WindPeriod(
                        startPosition: startPosition + midnightGap,
                        endPosition: 1.0 - midnightGap,
                        intensity: CGFloat(intensity)
                    ))
                    periods.append(WindPeriod(
                        startPosition: 0.0 + midnightGap,
                        endPosition: endPosition - midnightGap,
                        intensity: CGFloat(intensity)
                    ))
                } else if start == 0 {
                    // Period starts at midnight
                    periods.append(WindPeriod(
                        startPosition: startPosition + midnightGap,
                        endPosition: endPosition,
                        intensity: CGFloat(intensity)
                    ))
                } else if end == 23 {
                    // Period ends at midnight
                    periods.append(WindPeriod(
                        startPosition: startPosition,
                        endPosition: endPosition - midnightGap,
                        intensity: CGFloat(intensity)
                    ))
                }
            } else {
                // Normal period that doesn't touch midnight
                periods.append(WindPeriod(
                    startPosition: startPosition,
                    endPosition: endPosition,
                    intensity: CGFloat(intensity)
                ))
            }
        }
        
        // Scan through all 24 hours
        for hour in 0..<24 {
            if hourlyWindSpeeds[hour] > windThreshold {
                // This hour has significant wind
                if currentPeriodStart == nil {
                    // Start a new period
                    currentPeriodStart = hour
                    currentMaxSpeed = hourlyWindSpeeds[hour]
                } else {
                    // Continue the current period
                    currentMaxSpeed = max(currentMaxSpeed, hourlyWindSpeeds[hour])
                }
            } else if currentPeriodStart != nil {
                // This hour doesn't have significant wind, but we were in a period
                // End the current period
                addPeriod(start: currentPeriodStart!, end: hour - 1, maxSpeed: currentMaxSpeed)
                currentPeriodStart = nil
                currentMaxSpeed = 0.0
            }
        }
        
        // If we ended the 24 hours still in a wind period, add it
        if let start = currentPeriodStart {
            addPeriod(start: start, end: 23, maxSpeed: currentMaxSpeed)
        }
        
        // Now merge any periods that are close to each other (within 3 hours)
        // But don't merge across midnight
        if periods.count > 1 {
            var mergedPeriods: [WindPeriod] = []
            var currentMergedPeriod = periods[0]
            
            for i in 1..<periods.count {
                let nextPeriod = periods[i]
                
                // Skip merging if either period touches midnight
                let currentTouchesMidnight = currentMergedPeriod.endPosition > 0.99 || currentMergedPeriod.startPosition < 0.01
                let nextTouchesMidnight = nextPeriod.endPosition > 0.99 || nextPeriod.startPosition < 0.01
                
                if currentTouchesMidnight || nextTouchesMidnight {
                    // Don't merge periods that touch midnight
                    mergedPeriods.append(currentMergedPeriod)
                    currentMergedPeriod = nextPeriod
                    continue
                }
                
                // Calculate the gap between periods in hours
                let currentEndHour = Int(currentMergedPeriod.endPosition * 24)
                let nextStartHour = Int(nextPeriod.startPosition * 24)
                let gap = nextStartHour - currentEndHour
                
                if gap <= 3 {
                    // Merge the periods
                    currentMergedPeriod = WindPeriod(
                        startPosition: currentMergedPeriod.startPosition,
                        endPosition: nextPeriod.endPosition,
                        intensity: max(currentMergedPeriod.intensity, nextPeriod.intensity)
                    )
                    print("🌬️ Merging periods with gap of \(gap) hours")
                } else {
                    // Add the current merged period and start a new one
                    mergedPeriods.append(currentMergedPeriod)
                    currentMergedPeriod = nextPeriod
                }
            }
            
            // Add the last merged period
            mergedPeriods.append(currentMergedPeriod)
            periods = mergedPeriods
        }
        
        print("🌬️ Created \(periods.count) wind periods")
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
    
    @Environment(Model.self) private var model
    
    // Calculate the gap as a percentage based on the ring size and active state
    private var midnightGap: CGFloat {
        // Use expanded gap size when ring is active
        let gapSize = model.activeRing == "wind" ? midnightGapExpandedPixels : midnightGapPixels
        
        // Convert fixed pixel gap to a percentage of the circumference
        // Circumference = π * diameter = π * size
        // Gap percentage = gap size / circumference
        return gapSize / (CGFloat.pi * size)
    }
    
    var body: some View {
        ZStack {
            // Background track with gap at midnight
            Circle()
                .trim(from: midnightGap, to: 1.0 - midnightGap)
                .stroke(.gray.opacity(0.1), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(90)) // Adjust so 0 is at top (12 o'clock position)
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
