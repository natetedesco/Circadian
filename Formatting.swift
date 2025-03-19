//
//  Untitled.swift
//  Circadian
//  Created by Developer on 3/19/25.
//

import SwiftUI

// Extension for time formatting methods
extension Model {
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: currentTime)
    }
    
    var amPm: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: currentTime).lowercased()
    }
}
