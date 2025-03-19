//
//  Rain Circle.swift
//  Circadian
//
//  Created by Developer on 3/18/25.
//

import SwiftUI

// Struct to represent a rain period
struct RainPeriod {
    var startPosition: CGFloat  // Position on the 24-hour circle (0-1)
    var endPosition: CGFloat    // Position on the 24-hour circle (0-1)
    var intensity: CGFloat      // Intensity of rain (0-1)
}

@Observable class RainModel {
    var currentRainProbability: Double = 0.0
    
    // Access to global layout constants
    var size: CGFloat { Circadian.size }
    var width: CGFloat { Circadian.width }
    
    // Calculate the midnight gap as a percentage for the model
    var midnightGapPercentage: CGFloat {
        // The rain ring size is: size - width * 6 - 48
        let rainRingSize: CGFloat = size - width * 6 - 48 // Using global constants from RingLayout.swift
        return midnightGapPixels / (CGFloat.pi * rainRingSize)
    }
    
    // Hourly rain probabilities (0-1)
    var hourlyRainProbabilities: [Double] = [
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,  // 12am-5am (midnight to pre-dawn)
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,  // 6am-11am (morning)
        0.0, 0.7, 0.8, 0.6, 0.5, 0.0,  // 12pm-5pm (noon to afternoon) - Rain from 1pm-3pm
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0   // 6pm-11pm (evening) - Rain from 8pm-10pm
    ]
    
    // Get hourly rain probabilities as CGFloat array
    var hourlyRainProbabilitiesAsCGFloat: [CGFloat] {
        return hourlyRainProbabilities.map { CGFloat($0) }
    }
    
    // Get rain periods (start and end positions of rain)
    var rainPeriods: [RainPeriod] {
        var periods: [RainPeriod] = []
        var inRainPeriod = false
        var currentPeriod: RainPeriod? = nil
        var maxIntensity: CGFloat = 0.0
        
        // Threshold for considering it's raining
        let rainThreshold: Double = 0.1
        
        // Get the midnight gap percentage
        let midnightGap = midnightGapPercentage
        
        // Function to add a period with midnight gap enforcement
        func addPeriod(start: CGFloat, end: CGFloat, intensity: CGFloat) {
            // Check if this period crosses midnight (0.0 or 1.0)
            let startHour = Int(start * 24)
            let endHour = Int(end * 24)
            
            if startHour == 0 || endHour == 23 {
                if startHour == 0 && endHour == 23 {
                    // Period spans the entire day, split it at midnight
                    periods.append(RainPeriod(
                        startPosition: start + midnightGap,
                        endPosition: 1.0 - midnightGap,
                        intensity: intensity
                    ))
                    periods.append(RainPeriod(
                        startPosition: 0.0 + midnightGap,
                        endPosition: end - midnightGap,
                        intensity: intensity
                    ))
                } else if startHour == 0 {
                    // Period starts at midnight
                    periods.append(RainPeriod(
                        startPosition: start + midnightGap,
                        endPosition: end,
                        intensity: intensity
                    ))
                } else if endHour == 23 {
                    // Period ends at midnight
                    periods.append(RainPeriod(
                        startPosition: start,
                        endPosition: end - midnightGap,
                        intensity: intensity
                    ))
                }
            } else {
                // Normal period that doesn't touch midnight
                periods.append(RainPeriod(
                    startPosition: start,
                    endPosition: end,
                    intensity: intensity
                ))
            }
        }
        
        // Find all rain periods
        for (index, probability) in hourlyRainProbabilities.enumerated() {
            let position = CGFloat(index) / CGFloat(hourlyRainProbabilities.count)
            
            if probability > rainThreshold && !inRainPeriod {
                // Start of a rain period
                inRainPeriod = true
                currentPeriod = RainPeriod(startPosition: position, endPosition: position, intensity: CGFloat(probability))
                maxIntensity = CGFloat(probability)
            } else if probability > rainThreshold && inRainPeriod {
                // Continuing rain period
                currentPeriod?.endPosition = position
                maxIntensity = max(maxIntensity, CGFloat(probability))
            } else if probability <= rainThreshold && inRainPeriod {
                // End of a rain period
                if let period = currentPeriod {
                    // Use our helper function to add the period with midnight gap
                    addPeriod(start: period.startPosition, end: period.endPosition, intensity: maxIntensity)
                }
                inRainPeriod = false
                currentPeriod = nil
                maxIntensity = 0.0
            }
        }
        
        // Add the last period if we're still in one
        if inRainPeriod, let period = currentPeriod {
            // Use our helper function to add the period with midnight gap
            addPeriod(start: period.startPosition, end: period.endPosition, intensity: maxIntensity)
        }
        
        return periods
    }
    
    // Update rain probability based on time
    func updateRainFromTime(_ timePosition: CGFloat) {
        let hourIndex = Int(timePosition * 24) % 24
        currentRainProbability = hourlyRainProbabilities[hourIndex]
    }
    
    // Get formatted rain probability
    func formattedRainProbability(_ probability: Double) -> String {
        return "\(Int(probability * 100))% Chance"
    }
}

struct RainRing: View {
    var size: CGFloat
    var lineWidth: CGFloat
    var color: Color
    var currentTimePosition: CGFloat
    var rainPeriods: [RainPeriod]
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
        let gapSize = model.activeRing == "rain" ? midnightGapExpandedPixels : midnightGapPixels
        
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
            
            // Draw each rain period as a separate arc
            ForEach(0..<rainPeriods.count, id: \.self) { index in
                let period = rainPeriods[index]
                
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
                // Provide haptic feedback when entering or exiting a rain period
                let isInRainPeriod = rainPeriods.contains { period in
                    percentage >= period.startPosition && percentage <= period.endPosition
                }
                
                let wasInRainPeriod = rainPeriods.contains { period in
                    lastFeedbackPosition >= period.startPosition && lastFeedbackPosition <= period.endPosition
                }
                
                if isInRainPeriod != wasInRainPeriod {
                    medHaptic()
                }
                
                lastFeedbackPosition = percentage
            }
        )
    }
}
