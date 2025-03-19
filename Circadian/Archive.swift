//VStack(alignment: .leading, spacing: 20) {
//    // Temperature
//    HStack {
//        Text("Temperature:")
//            .foregroundColor(.white)
//        Spacer()
//        Text("\(Int(model.currentTemp)) Degrees")
//            .foregroundColor(.red)
//            .bold()
//    }
//    
//    Divider().padding(.horizontal, -16)
//    
//    // Daylight
//    HStack {
//        Text("Day:")
//            .foregroundColor(.white)
//        Spacer()
//        Text("6:24am - 7:35pm")
//            .foregroundColor(.orange)
//            .bold()
//    }
//    
//    Divider().padding(.horizontal, -16)
//    
//    // UV
//    HStack {
//        Text("UV Index:")
//            .foregroundColor(.white)
//        Spacer()
//        Text("\(Int(model.uvIndex)) Peak")
//            .foregroundColor(.yellow)
//            .bold()
//    }
//    
//    Divider().padding(.horizontal, -16)
//    
//    // Rain
//    HStack {
//        Text("Rain:")
//            .foregroundColor(.white)
//        Spacer()
//        Text("\(Int(model.rainChance * 100))% Chance")
//            .foregroundColor(.blue)
//            .bold()
//    }
//    
//    // Wind (conditional)
//    Divider().padding(.horizontal, -16)
//    
//    HStack {
//        Text("Wind:")
//            .foregroundColor(.white)
//        Spacer()
//        Text("\(Int(model.windSpeed))-12 mph")
//            .foregroundColor(.mint)
//            .bold()
//    }
//}

//@Observable class Model {
//    // Temperature
//    var currentTemp: Double = 72.0
//    var maxTemp: Double = 85.0
//    var minTemp: Double = 55.0
//    let tempColor = Color.red
//    
//    // Sunrise
//    var dayProgress: Double = 0.6 // Represents current point in daylight hours
//    let sunriseTime: CGFloat = 0.25 // 6am (25% through the day)
//    let sunsetTime: CGFloat = 0.75 // 6pm (75% through the day)
//    let dayPeakTime: CGFloat = 0.5 // Middle of the day (noon)
//    let dayColor = Color.orange
//    
//    // UV
//    var uvIndex: Double = 6.0
//    var maxUV: Double = 10.0
//    let uvStartTime: CGFloat = 0.3 // 7:12am
//    let uvEndTime: CGFloat = 0.7 // 4:48pm
//    let uvPeakTime: CGFloat = 0.5 // Peak UV at noon
//    let uvColor = Color.yellow
//    
//    // Rain
//    var rainChance: Double = 0.6 // 60% chance of rain
//    let rainStartTime: CGFloat = 0.45 // Around 10:45am
//    let rainEndTime: CGFloat = 0.55 // Around 1:15pm
//    let rainPeakTime: CGFloat = 0.5 // Peak rain chance
//    let rainColor = Color.blue
//    
//    // Wind
//    var maxWind: Double = 20.0
//    var windSpeed: Double = 8.0
//    let windStartTime: CGFloat = 0.3 // Around 7:12am
//    let windEndTime: CGFloat = 0.8 // Around 7:12pm
//    let windThreshold: Double = 5.0 // mph
//    let windPeakTime: CGFloat = 0.6 // Peak wind speed
//    let windColor = Color.mint
//    
//    // Peak positions (normalized within their respective ranges)
//    let tempPeakTime: CGFloat = 0.7 // When the highest temperature is expected
//    
//    var size: CGFloat = 280
//    var width: CGFloat = 18
//    
//    var currentTime = Date()
//    
//    // Calculate percentages
//    var tempPercentage: CGFloat {
//        let range = maxTemp - minTemp
//        let position = currentTemp - minTemp
//        return CGFloat(position / range)
//    }
//    
//    var uvPercentage: CGFloat {
//        return CGFloat(uvIndex / maxUV)
//    }
//    
//    var windPercentage: CGFloat {
//        return CGFloat(windSpeed / maxWind)
//    }
//    
//    var rainPercentage: CGFloat {
//        return CGFloat(rainChance)
//    }
//    
//    var currentTimePercentage: CGFloat {
//        let calendar = Calendar.current
//        let hour = calendar.component(.hour, from: currentTime)
//        let minute = calendar.component(.minute, from: currentTime)
//        let second = calendar.component(.second, from: currentTime)
//        
//        let totalSeconds = (hour * 3600) + (minute * 60) + second
//        // Offset by 0.5 to make noon at top (12 o'clock) and midnight at bottom (6 o'clock)
//        return (CGFloat(totalSeconds) / CGFloat(24 * 3600) + 0.1).truncatingRemainder(dividingBy: 1.0)
//    }
//    
//    var shouldShowWind: Bool {
//        return windSpeed >= windThreshold
//    }
//    
//    var formattedTime: String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "h:mm"
//        return formatter.string(from: currentTime)
//    }
//    
//    var amPm: String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "a"
//        return formatter.string(from: currentTime).lowercased()
//    }
//}
