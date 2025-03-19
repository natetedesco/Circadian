//
//  Day Circle.swift
//  Circadian
//  Created by Developer on 3/18/25.
//

import SwiftUI

@Observable class DaylightModel {
    // Daylight data
    var sunriseTime: Date
    var sunsetTime: Date
    let daylightColor = Color.orange
    
    // Initialize with default sunrise/sunset times
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
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: sunriseTime)
    }
    
    // Formatted sunset time
    var formattedSunsetTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: sunsetTime)
    }
    
    // Formatted daylight range
    var formattedDaylightRange: String {
        return "\(formattedSunriseTime) - \(formattedSunsetTime)"
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
    @State private var lastFeedbackPosition: CGFloat = -1
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(.gray.opacity(0.1), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            
            // Daylight arc
            Circle()
                .trim(from: sunrisePosition, to: sunsetPosition)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(90)) // Adjust so 0 is at top (12 o'clock position)
            
            // Current time position indicator with icon
            ZStack {
                Circle()
                    .fill(.thickMaterial)
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
        .gesture(
            DragGesture(minimumDistance: 0.0)
                .onChanged({ value in
                    if !isDragging {
                        isDragging = true
                        onDragStarted()
                    }
                    
                    // Use the fixed center of the view
                    let centerPoint = CGPoint(x: size/2, y: size/2)
                    
                    // Calculate the position relative to center
                    let relativeX = value.location.x - centerPoint.x
                    let relativeY = value.location.y - centerPoint.y
                    
                    // Skip if too close to center to avoid erratic behavior
                    let distance = sqrt(pow(relativeX, 2) + pow(relativeY, 2))
                    if distance < 10 {
                        return
                    }
                    
                    // Calculate the angle, with y inverted
                    let angle = atan2(-relativeY, relativeX)
                    
                    // Convert to clockwise angle starting from top (midnight)
                    let clockwiseAngleFrom12 = (.pi/2 - angle).truncatingRemainder(dividingBy: 2 * .pi)
                    
                    // Normalize to 0-2π
                    let normalizedAngle = clockwiseAngleFrom12 < 0 ? clockwiseAngleFrom12 + 2 * .pi : clockwiseAngleFrom12
                    
                    // Convert to percentage (0-1)
                    let percentage = (normalizedAngle / (2 * .pi) + 0.5).truncatingRemainder(dividingBy: 1.0)
                    // Offset by 0.5 to align midnight at top
                    
                    // Provide haptic feedback every hour (1/24 of the circle)
                    let hourPosition = Int(percentage * 24)
                    if hourPosition != Int(lastFeedbackPosition * 24) {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        lastFeedbackPosition = percentage
                    }
                    
                    onPositionChanged(percentage)
                })
                .onEnded({ _ in
                    isDragging = false
                    // Reset feedback tracking
                    lastFeedbackPosition = -1
                    
                    // Notify that dragging has ended
                    onDragEnded()
                    
                    // Snap back to current time position
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onPositionChanged(currentTimePosition)
                    }
                })
        )
    }
}
