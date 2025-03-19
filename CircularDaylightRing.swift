//
//  CircularDaylightRing.swift
//  Circadian
//  Created by Developer on 3/18/25.
//

import SwiftUI

struct CircularDaylightRing: View {
    var size: CGFloat
    var lineWidth: CGFloat
    var color: Color
    var currentTimePosition: CGFloat
    var sunrisePosition: CGFloat
    var sunsetPosition: CGFloat
    var icon: String
    var onPositionChanged: (CGFloat) -> Void
    
    @State private var isDragging = false
    @State private var lastFeedbackPosition: CGFloat = -1
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.gray.opacity(0.1), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size)
            
            // Daylight arc
            Circle()
                .trim(from: sunrisePosition, to: sunsetPosition)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(90)) // Adjust so 0 is at top (12 o'clock position)
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
}
