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
            .foregroundStyle(.primary)
            .padding(.top, 48)
            .padding(.bottom, 48)
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
            .font(model.activeRing != nil ? .system(size: 44) : .caption2)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
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
            
            // Show UV index under time when sliding UV ring
            if model.activeRing == "uv" {
                let riskLevel = model.uvModel.getUVRiskLevel(model.uvModel.currentUVIndex)
                Text("\(Int(model.uvModel.currentUVIndex)) (\(riskLevel))")
                    .font(.headline)
                    .foregroundColor(.yellow)
                    .fontWeight(.medium)
                    .transition(.opacity)
            }
            
            // Show rain probability under time when sliding rain ring
            if model.activeRing == "rain" {
                Text(model.rainModel.formattedRainProbability(model.rainModel.currentRainProbability))
                    .font(.headline)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
                    .transition(.opacity)
            }
            
            // Show wind information under time when sliding wind ring
            if model.activeRing == "wind" {
                Text(model.windModel.formattedWindInfo(model.windModel.currentWindSpeed, direction: model.windModel.windDirection))
                    .font(.headline)
                    .foregroundColor(.mint)
                    .fontWeight(.medium)
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
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(
                RadialGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.3), .white.opacity(0.05)]),
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
