//
//  Temperature Circle.swift
//  Circadian
//
//  Created by Developer on 3/18/25.
//

import SwiftUI

@Observable class TemperatureModel {
    // Temperature
    var currentTemp: Double = 72.0
    var maxTemp: Double = 85.0
    var minTemp: Double = 55.0
    let tempColor = Color.red
    
    // Simulated hourly temperatures, adjusted for midnight at top (index 0 = midnight)
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
    
    @State private var isDragging = false
    @State private var lastFeedbackPosition: CGFloat = -1  // Track last haptic feedback position
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .trim(from: 0, to: 1)
                .stroke(Color.gray.opacity(0.1), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size)
            
            // Temperature gradient ring
            Circle()
                .trim(from: 0, to: 1)
                .stroke(
                    AngularGradient(
                        gradient: createTemperatureGradient(),
                        center: .center,
                        startAngle: .degrees(90),    // Start at top (midnight)
                        endAngle: .degrees(90+360)   // Full circle
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size)
            
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
        .gesture(
            DragGesture(minimumDistance: 0.0)
                .onChanged({ value in
                    isDragging = true
                    
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
                    
                    // Snap back to current time position
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onPositionChanged(currentTimePosition)
                    }
                })
        )
    }
    
    // Create a gradient based on temperature data for 24 hours
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
}


//#Preview {
//    CircularRing()
//}
