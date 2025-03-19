//
//  RingLayout.swift
//  Circadian
//  Created by Developer on 3/19/25.
//

import SwiftUI

// Global constants for ring dimensions
let size: CGFloat = 280
let width: CGFloat = 18

// Extension for ring layout calculations
extension ContentView {
    // Helper function to calculate ring size based on active state
    func ringSize(for ringType: String, baseSize: CGFloat = size) -> CGFloat {
        if model.activeRing == ringType {
            return baseSize // When active, all rings grow to the maximum size
        } else {
            // When not active, rings have their original size
            return ringType == "temperature" ? baseSize : baseSize - width * 2 - 16
        }
    }
    
    // Helper function to calculate ring width based on active state
    func ringWidth(for ringType: String) -> CGFloat {
        return width + (model.activeRing == ringType ? 4 : 0) // Increase width by 4 when active
    }
}
