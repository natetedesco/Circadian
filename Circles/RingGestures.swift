//
//  RingGestures.swift
//  Circadian
//  Created by Developer on 3/19/25.
//

import SwiftUI

// Extension to provide reusable drag gesture functionality for rings
extension View {
    // Add a circular drag gesture to a ring
    func circularDragGesture(
        size: CGFloat,
        isDragging: Binding<Bool>,
        onDragStarted: @escaping () -> Void,
        onDragEnded: @escaping () -> Void,
        onPositionChanged: @escaping (CGFloat) -> Void,
        handleFeedback: @escaping (CGFloat) -> Void
    ) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 0.0)
                .onChanged({ value in
                    if !isDragging.wrappedValue {
                        isDragging.wrappedValue = true
                        onDragStarted()
                    }
                    
                    // Use the fixed center of the view
                    let centerPoint = CGPoint(x: size/2, y: size/2)
                    
                    // Skip if too close to center to avoid erratic behavior
                    if DragUtils.isTooCloseToCenter(dragLocation: value.location, center: centerPoint) {
                        return
                    }
                    
                    // Calculate angle from drag position
                    let normalizedAngle = DragUtils.calculateAngle(dragLocation: value.location, center: centerPoint)
                    
                    // Convert to percentage (0-1)
                    let percentage = DragUtils.angleToPercentage(normalizedAngle)
                    
                    // Handle feedback (different for each ring type)
                    handleFeedback(percentage)
                    
                    // Update position
                    onPositionChanged(percentage)
                })
                .onEnded({ _ in
                    isDragging.wrappedValue = false
                    
                    // Notify that dragging has ended
                    onDragEnded()
                    
                    // Snap back to current time
                    DragUtils.snapToCurrentTime(onPositionChanged: onPositionChanged)
                })
        )
    }
}
