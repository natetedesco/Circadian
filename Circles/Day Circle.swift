//
//  Day Circle.swift
//  Circadian
//  Created by Developer on 3/18/25.
//

import SwiftUI



@Observable class DaylightModel {
    var sunriseTime: Date
    var sunsetTime: Date
    
    var firstLightTime: Date = Date()
    var goldenHourMorningTime: Date = Date()
    var solarNoonTime: Date = Date()
    var goldenHourEveningTime: Date = Date()
    var lastLightTime: Date = Date()
    var solarMidnightTime: Date = Date()
    
    // Access to global layout constants
    var size: CGFloat { Circadian.size }
    var width: CGFloat { Circadian.width }
    
    // Calculate the midnight gap as a percentage for the model
    var midnightGapPercentage: CGFloat {
        // The daylight ring size is: size - width * 2 - 16
        let daylightRingSize: CGFloat = size - width * 2 - 16 // Using global constants from RingLayout.swift
        return midnightGapPixels / (CGFloat.pi * daylightRingSize)
    }
    
    // Get positions for all sun events
    var firstLightPosition: CGFloat { getPositionForTime(firstLightTime) }
    var goldenHourMorningPosition: CGFloat { getPositionForTime(goldenHourMorningTime) }
    var solarNoonPosition: CGFloat { getPositionForTime(solarNoonTime) }
    var goldenHourEveningPosition: CGFloat { getPositionForTime(goldenHourEveningTime) }
    var lastLightPosition: CGFloat { getPositionForTime(lastLightTime) }
    var solarMidnightPosition: CGFloat { getPositionForTime(solarMidnightTime) }
    
    init() {
        // Default sunrise at 6:30 AM
        var calendar = Calendar.current
        var sunriseComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        sunriseComponents.hour = 6
        sunriseComponents.minute = 30
        sunriseComponents.second = 0
        sunriseTime = calendar.date(from: sunriseComponents) ?? Date()
        
        // Default sunset at 7:30 PM
        var sunsetComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        sunsetComponents.hour = 19
        sunsetComponents.minute = 30
        sunsetComponents.second = 0
        sunsetTime = calendar.date(from: sunsetComponents) ?? Date()
        
        // Now that all properties are initialized, calculate sun events
        calculateSunEvents()
    }
    
    // Calculate all sun events based on sunrise and sunset times
    func calculateSunEvents() {
        let calendar = Calendar.current
        
        // First light (civil dawn) - about 30 minutes before sunrise
        firstLightTime = calendar.date(byAdding: .minute, value: -30, to: sunriseTime) ?? sunriseTime
        
        // Golden hour morning - starts at sunrise, lasts about 60 minutes
        goldenHourMorningTime = sunriseTime
        
        // Solar noon - midpoint between sunrise and sunset
        let sunriseSunsetDuration = calendar.dateComponents([.second], from: sunriseTime, to: sunsetTime).second ?? 0
        solarNoonTime = calendar.date(byAdding: .second, value: sunriseSunsetDuration / 2, to: sunriseTime) ?? sunriseTime
        
        // Golden hour evening - about 60 minutes before sunset
        goldenHourEveningTime = calendar.date(byAdding: .minute, value: -60, to: sunsetTime) ?? sunsetTime
        
        // Last light (civil dusk) - about 30 minutes after sunset
        lastLightTime = calendar.date(byAdding: .minute, value: 30, to: sunsetTime) ?? sunsetTime
        
        // Solar midnight - midpoint between sunset and next day's sunrise (opposite of solar noon)
        // First get the next day's sunrise by adding 24 hours to current sunrise
        let nextDaySunrise = calendar.date(byAdding: .hour, value: 24, to: sunriseTime) ?? sunriseTime
        let sunsetToNextSunriseDuration = calendar.dateComponents([.second], from: sunsetTime, to: nextDaySunrise).second ?? 0
        solarMidnightTime = calendar.date(byAdding: .second, value: sunsetToNextSunriseDuration / 2, to: sunsetTime) ?? sunsetTime
    }
    
    // Get sunrise position (0-1) on the 24-hour circle
    var sunrisePosition: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: sunriseTime)
        let minute = calendar.component(.minute, from: sunriseTime)
        let second = calendar.component(.second, from: sunriseTime)
        
        let totalSeconds = (hour * 3600) + (minute * 60) + second
        return CGFloat(totalSeconds) / CGFloat(24 * 3600)
    }
    
    // Get sunset position (0-1) on the 24-hour circle
    var sunsetPosition: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: sunsetTime)
        let minute = calendar.component(.minute, from: sunsetTime)
        let second = calendar.component(.second, from: sunsetTime)
        
        let totalSeconds = (hour * 3600) + (minute * 60) + second
        return CGFloat(totalSeconds) / CGFloat(24 * 3600)
    }
    
    // Update sunrise time based on position (0-1)
    func updateSunriseFromPosition(_ position: CGFloat) {
        let secondsInDay = 24 * 60 * 60
        let totalSeconds = Int(position * Double(secondsInDay))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hours
        components.minute = minutes
        components.second = 0
        
        if let newTime = calendar.date(from: components) {
            sunriseTime = newTime
            // Update all sun events when sunrise changes
            calculateSunEvents()
        }
    }
    
    // Update sunset time based on position (0-1)
    func updateSunsetFromPosition(_ position: CGFloat) {
        let secondsInDay = 24 * 60 * 60
        let totalSeconds = Int(position * Double(secondsInDay))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hours
        components.minute = minutes
        components.second = 0
        
        if let newTime = calendar.date(from: components) {
            sunsetTime = newTime
            // Update all sun events when sunset changes
            calculateSunEvents()
        }
    }
    
    // Generate hourly daylight intensity values (0-1)
    var hourlyDaylightIntensity: [CGFloat] {
        var intensities: [CGFloat] = Array(repeating: 0, count: 24)
        
        // Get hour components
        let calendar = Calendar.current
        let sunriseHour = calendar.component(.hour, from: sunriseTime)
        let sunsetHour = calendar.component(.hour, from: sunsetTime)
        
        // Fill in daylight hours with intensity values
        for hour in 0..<24 {
            if hour < sunriseHour || hour >= sunsetHour {
                // Night time
                intensities[hour] = 0.0
            } else if hour > sunriseHour && hour < sunsetHour - 1 {
                // Full daylight
                intensities[hour] = 1.0
            } else if hour == sunriseHour {
                // Sunrise transition
                intensities[hour] = 0.5
            } else if hour == sunsetHour - 1 {
                // Sunset transition
                intensities[hour] = 0.5
            }
        }
        
        return intensities
    }
    
    // Formatted sunrise time
    var formattedSunriseTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: sunriseTime).lowercased()
    }

    var formattedSunsetTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: sunsetTime).lowercased()
    }
    
    // Formatted daylight range
    var formattedDaylightRange: String {
        return "\(formattedSunriseTime) - \(formattedSunsetTime)"
    }
    
    // Helper method to get position (0-1) for any time
    func getPositionForTime(_ time: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        let second = calendar.component(.second, from: time)
        
        let totalSeconds = (hour * 3600) + (minute * 60) + second
        return CGFloat(totalSeconds) / CGFloat(24 * 3600)
    }
    
    // Get the current sun event based on time position
    func getSunEventForPosition(_ position: CGFloat) -> (name: String, time: String) {
        // Convert position to a date
        let secondsInDay = 24 * 60 * 60
        let totalSeconds = Int(position * Double(secondsInDay))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hours
        components.minute = minutes
        components.second = 0
        
        guard let currentTime = calendar.date(from: components) else {
            return ("Unknown", "")
        }
        
        // Format the time
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: currentTime)
        
        // Determine which sun event is closest
        let timePosition = getPositionForTime(currentTime)
        
        // Check exact matches first (or very close)
        let threshold: CGFloat = 0.005 // About 7 minutes
        
        if abs(timePosition - firstLightPosition) < threshold {
            return ("First Light", timeString)
        } else if abs(timePosition - goldenHourMorningPosition) < threshold {
            return ("Morning Golden Hour", timeString)
        } else if abs(timePosition - sunrisePosition) < threshold {
            return ("Sunrise", timeString)
        } else if abs(timePosition - solarNoonPosition) < threshold {
            return ("Solar Noon", timeString)
        } else if abs(timePosition - goldenHourEveningPosition) < threshold {
            return ("Evening Golden Hour", timeString)
        } else if abs(timePosition - sunsetPosition) < threshold {
            return ("Sunset", timeString)
        } else if abs(timePosition - lastLightPosition) < threshold {
            return ("Last Light", timeString)
        } else if abs(timePosition - solarMidnightPosition) < threshold {
            return ("Solar Midnight", timeString)
        }
        
        // Determine which specific sun event period we're in
        if (timePosition > lastLightPosition && timePosition < 1.0) || (timePosition >= 0 && timePosition < firstLightPosition) {
            // Between last light and first light
            return ("Night", timeString)
        } else if timePosition < sunrisePosition {
            // Between first light and sunrise
            return ("First Light", timeString)
        } else if timePosition < solarNoonPosition {
            // Between sunrise and solar noon
            if timePosition < sunrisePosition + 0.04 { // About an hour after sunrise
                return ("Morning Golden Hour", timeString)
            } else {
                return ("Sunrise", timeString)
            }
        } else if timePosition < goldenHourEveningPosition {
            // Between solar noon and evening golden hour
            return ("Solar Noon", timeString)
        } else if timePosition < sunsetPosition {
            // Between evening golden hour and sunset
            return ("Evening Golden Hour", timeString)
        } else if timePosition < lastLightPosition {
            // Between sunset and last light
            return ("Sunset", timeString)
        } else {
            // Should never reach here, but just in case
            return ("Last Light", timeString)
        }
    }
}

struct CircularDaylightRing: View {
    var size: CGFloat
    var lineWidth: CGFloat
    var color: Color
    var currentTimePosition: CGFloat
    var sunrisePosition: CGFloat
    var sunsetPosition: CGFloat
    var icon: String
    var onPositionChanged: (CGFloat) -> Void
    var onDragStarted: () -> Void = {}
    var onDragEnded: () -> Void = {}
    
    @State private var isDragging = false
    @State private var lastSunEvent: String = ""  // Track last sun event for haptic feedback
    
    // Calculate the peak sun time (midpoint between sunrise and sunset)
    var peakSunPosition: CGFloat {
        // Handle case where sunrise is after sunset (crosses midnight)
        if sunrisePosition > sunsetPosition {
            return (sunrisePosition + (sunsetPosition + 1.0)) / 2.0
        } else {
            return (sunrisePosition + sunsetPosition) / 2.0
        }
    }
    
    @Environment(Model.self) private var model
    
    // Calculate the gap as a percentage based on the ring size and active state
    private var midnightGap: CGFloat {
        // Use expanded gap size when ring is active
        let gapSize = model.activeRing == "daylight" ? midnightGapExpandedPixels : midnightGapPixels
        
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
                .rotationEffect(.degrees(90)) // Adjust so 0 is at top (12 o'clock position))
            
            // Daylight arc with gradient
            let startAngle = Angle(degrees: 0)
            let endAngle = Angle(degrees: 360)
            
            Circle()
                .trim(from: sunrisePosition, to: sunsetPosition)
                .stroke(
                    AngularGradient(
                        stops: [
                            .init(color: color.opacity(0.1), location: 0),
                            .init(color: color.opacity(1.0), location: 0.5),
                            .init(color: color.opacity(0.1), location: 1)
                        ],
                        center: .center,
                        startAngle: startAngle,
                        endAngle: endAngle
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(90)) // Adjust so 0 is at top (12 o'clock position)
            
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
                // Get the current sun event and provide haptic feedback only when it changes
                let daylightModel = DaylightModel()
                let currentSunEvent = daylightModel.getSunEventForPosition(percentage).name
                
                if currentSunEvent != lastSunEvent && !lastSunEvent.isEmpty {
                    medHaptic()
                }
                
                lastSunEvent = currentSunEvent
            }
        )
    }
}
