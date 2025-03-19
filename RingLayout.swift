//
//  RingLayout.swift
//  Circadian
//  Created by Developer on 3/19/25.
//

import SwiftUI

// Global constants for ring dimensions
let size: CGFloat = 280
let width: CGFloat = 16

// Extension for ring layout calculations
extension ContentView {
    // Helper function to calculate ring size based on active state
    func ringSize(for ringType: String, baseSize: CGFloat = size) -> CGFloat {
        if model.activeRing == ringType {
            return baseSize // When active, all rings grow to the maximum size
        } else {
            // When not active, rings have their original size based on their position
            switch ringType {
            case "temperature":
                return baseSize
            case "daylight":
                return baseSize - width * 2 - 16
            case "uv":
                return baseSize - width * 4 - 32
            case "rain":
                return baseSize - width * 6 - 48
            case "wind":
                return baseSize - width * 8 - 64
            default:
                return baseSize
            }
        }
    }
    
    // Helper function to calculate ring width based on active state
    func ringWidth(for ringType: String) -> CGFloat {
        return width + (model.activeRing == ringType ? 4 : 0) // Increase width by 4 when active
    }
}
