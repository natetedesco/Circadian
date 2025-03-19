//
//  UV Circle.swift
//  Circadian
//
//  Created by Developer on 3/18/25.
//

import SwiftUI

@Observable class UVModel {
    var currentUVIndex: Double = 5.0
    var maxUVIndex: Double = 11.0
    var minUVIndex: Double = 0.0
    
    var hourlyUVIndices: [Double] = [
        0, 0, 0, 0, 0, 0, 0,    // 12am-6am (midnight to dawn)
        0, 1, 2, 4, 6, 9,       // 7am-12pm (morning to noon)
        10, 11, 10, 8, 6, 3,    // 1pm-6pm (afternoon)
        1, 0, 0, 0, 0, 0        // 7pm-12am (evening to midnight)
    ]
    
    // Get hourly UV indices as CGFloat array
    var hourlyUVIndicesAsCGFloat: [CGFloat] {
        return hourlyUVIndices.map { CGFloat($0) }
    }
    
    // Get min and max UV indices from hourly data
    var minHourlyUV: CGFloat {
        return CGFloat(hourlyUVIndices.min() ?? minUVIndex)
    }
    
    var maxHourlyUV: CGFloat {
        return CGFloat(hourlyUVIndices.max() ?? maxUVIndex)
    }
    
    // Get UV risk level as a string
    func getUVRiskLevel(_ uvIndex: Double) -> String {
        switch uvIndex {
        case 0..<3:
            return "Low"
        case 3..<6:
            return "Moderate"
        case 6..<8:
            return "High"
        case 8..<11:
            return "Very High"
        default:
            return "Extreme"
        }
    }
    
    // Get color for UV index
    func getUVColor(_ uvIndex: Double) -> Color {
        switch uvIndex {
        case 0..<3:
            return .green
        case 3..<6:
            return .yellow
        case 6..<8:
            return .orange
        case 8..<11:
            return .red
        default:
            return .purple
        }
    }
    
    // Update UV index based on time
    func updateUVFromTime(_ timePosition: CGFloat) {
        let hourIndex = Int(timePosition * 24) % 24
        currentUVIndex = hourlyUVIndices[hourIndex]
    }
}

struct UVRing: View {
    var size: CGFloat
    var lineWidth: CGFloat
    var color: Color
    var currentTimePosition: CGFloat
    var uvData: [CGFloat]  // Array of UV index values for 24 hours
    var minUV: CGFloat
    var maxUV: CGFloat
    var icon: String
    var onPositionChanged: (CGFloat) -> Void
    var onDragStarted: () -> Void = {}
    var onDragEnded: () -> Void = {}
    
    @State private var isDragging = false
    @State private var lastFeedbackPosition: CGFloat = -1  // Track last haptic feedback position
    
    // Calculate the peak UV time (typically around noon)
    private var peakUVPosition: CGFloat {
        // Find the position of the maximum UV index
        if let maxIndex = uvData.firstIndex(of: maxUV) {
            return CGFloat(maxIndex) / CGFloat(uvData.count)
        }
        // Default to noon if not found
        return 0.5
    }
    
    // Calculate the start and end positions for the UV range
    private var uvStartPosition: CGFloat {
        // Find the first position where UV index > 0
        for (index, uv) in uvData.enumerated() {
            if uv > 0 {
                return CGFloat(index) / CGFloat(uvData.count)
            }
        }
        return 0.25 // Default to 6am if not found
    }
    
    private var uvEndPosition: CGFloat {
        // Find the last position where UV index > 0
        for index in stride(from: uvData.count - 1, through: 0, by: -1) {
            if uvData[index] > 0 {
                return CGFloat(index) / CGFloat(uvData.count)
            }
        }
        return 0.75 // Default to 6pm if not found
    }
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(.gray.opacity(0.1), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size)
            
            // UV arc with gradient
            let startAngle = Angle(degrees: 0)
            let endAngle = Angle(degrees: 360)
            
            Circle()
                .trim(from: uvStartPosition, to: uvEndPosition)
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
//    UVRing()
//}
