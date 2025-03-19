//
//  DragUtils.swift
//  Circadian
//  Created by Developer on 3/19/25.
//

import SwiftUI

// Common utility functions for drag gestures
struct DragUtils {
    // Calculate current time position from Date
    static func getCurrentTimePosition() -> CGFloat {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        
        let totalSeconds = (hour * 3600) + (minute * 60) + second
        return CGFloat(totalSeconds) / CGFloat(24 * 3600)
    }
    
    // Convert angle to percentage (0-1) for ring position
    static func angleToPercentage(_ angle: CGFloat) -> CGFloat {
        return (angle / (2 * .pi) + 0.5).truncatingRemainder(dividingBy: 1.0)
    }
    
    // Animate to a position with spring animation
    static func animateToPosition(position: CGFloat, onPositionChanged: @escaping (CGFloat) -> Void) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            onPositionChanged(position)
        }
    }
    
    // Snap back to current time
    static func snapToCurrentTime(onPositionChanged: @escaping (CGFloat) -> Void) {
        let currentPosition = getCurrentTimePosition()
        animateToPosition(position: currentPosition, onPositionChanged: onPositionChanged)
    }
    
    // Calculate angle from drag position
    static func calculateAngle(dragLocation: CGPoint, center: CGPoint) -> CGFloat {
        // Calculate the position relative to center
        let relativeX = dragLocation.x - center.x
        let relativeY = dragLocation.y - center.y
        
        // Calculate the angle, with y inverted
        let angle = atan2(-relativeY, relativeX)
        
        // Convert to clockwise angle starting from top (midnight)
        let clockwiseAngleFrom12 = (.pi/2 - angle).truncatingRemainder(dividingBy: 2 * .pi)
        
        // Normalize to 0-2π
        return clockwiseAngleFrom12 < 0 ? clockwiseAngleFrom12 + 2 * .pi : clockwiseAngleFrom12
    }
    
    // Check if drag point is too close to center
    static func isTooCloseToCenter(dragLocation: CGPoint, center: CGPoint, minDistance: CGFloat = 10) -> Bool {
        let relativeX = dragLocation.x - center.x
        let relativeY = dragLocation.y - center.y
        let distance = sqrt(pow(relativeX, 2) + pow(relativeY, 2))
        return distance < minDistance
    }
}
