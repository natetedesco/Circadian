//
//  Components.swift
//  Circadian
//  Created by Developer on 3/18/25.
//

import SwiftUI

struct TodayHeaderView: View {
    var body: some View {
        Text("Today")
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.top, 48)
            .padding(.bottom, 64)
    }
}

struct ClockDisplay: View {
    @Environment(Model.self) var model
    
    var body: some View {
        VStack(spacing: 4) {
            // Time display
            HStack(spacing: 0) {
                Text(model.formattedTime)
                    .monospacedDigit()
                Text(model.amPm)
                    .font(model.activeRing != nil ? .caption : .caption2)
            }
            .font(model.activeRing != nil ? .system(size: 44) : .footnote)
            .fontWeight(.medium)
            .fontDesign(.rounded)
            .contentShape(Rectangle()) // Make the entire area tappable
            .onTapGesture {
                // Force update to current time by using the Date() directly
                let calendar = Calendar.current
                let now = Date()
                let hour = calendar.component(.hour, from: now)
                let minute = calendar.component(.minute, from: now)
                let second = calendar.component(.second, from: now)
                
                let totalSeconds = (hour * 3600) + (minute * 60) + second
                let currentPosition = CGFloat(totalSeconds) / CGFloat(24 * 3600)
                
                // Update position and deactivate ring
                model.updateFromPosition(currentPosition)
                model.activeRing = nil
                medHaptic()
            }
            
            // Show temperature under time when sliding temperature ring
            if model.activeRing == "temperature" {
                Text("\(Int(model.temperatureModel.currentTemp))°")
                    .font(.title)
                    .foregroundColor(.red)
                    .fontWeight(.medium)
                    .transition(.opacity)
            }
            
            // Show sun event under time when sliding daylight ring
            if model.activeRing == "daylight" {
                let sunEvent = model.daylightModel.getSunEventForPosition(model.currentTimePosition)
                VStack(spacing: 0) {
                    Text(sunEvent.name)
                        .font(.headline)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                        .fontDesign(.rounded)
                    
                        // No second clock display
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.activeRing)
        .frame(width: 200, height: 200)
        .padding(.bottom, model.activeRing == nil ? 0 : -36)
    }
}

struct WeatherRow: View {
    var label: String
    var value: String
    var color: Color
    
    init(_ label: String, _ value: String, _ color: Color) {
        self.label = label
        self.value = value
        self.color = color
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
                .fontDesign(.rounded)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .bold()
        }
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            content
        }
        .padding()
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(32)
        .font(.callout)
    }
}

struct ContentContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(
                RadialGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.2), .white.opacity(0.05)]),
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 500
                )
            )
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}

func medHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.prepare()
    generator.impactOccurred()
}
