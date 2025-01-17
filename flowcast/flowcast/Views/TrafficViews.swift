import SwiftUI

struct TrafficPredictionView: View {
    @StateObject private var trafficManager = TrafficManager()
    
    var body: some View {
        ZStack {
            // Night sky background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Star effect overlay
            StarsOverlay()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Main location and temperature-style display
                    VStack(spacing: 4) {
                        Text("MY LOCATION")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(1.5)
                        
                        Text("Hacienda Heights")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Current congestion level display
                        Text("\(getCurrentCongestionLevel())")
                            .font(.system(size: 96, weight: .thin))
                            .foregroundColor(.white)
                        
                        Text("Currently \(getCurrentDescription())")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .padding(.top, -10)
                            
                        HStack {
                            Text("Peak: Heavy")
                            Text("Low: Light")
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 44)
                    
                    // Hourly traffic forecast
                    VStack(alignment: .leading, spacing: 16) {
                        Text("HOURLY TRAFFIC")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(1.5)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HourlyTrafficScrollView(hours: generateHourlyTraffic())
                        }
                    }
                    .padding(.top, 20)
                    
                    // 5-day forecast
                    VStack(alignment: .leading, spacing: 16) {
                        Text("5-DAY TRAFFIC FORECAST")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(1.5)
                        
                        VStack(spacing: 16) {
                            ForEach(trafficManager.predictions, id: \.dayName) { prediction in
                                DailyTrafficRow(prediction: prediction)
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func getCurrentCongestionLevel() -> String {
        "70%"  // Example value
    }
    
    private func getCurrentDescription() -> String {
        "Moderate Traffic"
    }
    
    private func generateHourlyTraffic() -> [(String, Double)] {
        let hours = ["Now", "11PM", "12AM", "1AM", "2AM", "3AM"]
        return hours.map { ($0, Double.random(in: 30...90)) }
    }
}

struct HourlyTrafficScrollView: View {
    let hours: [(String, Double)]
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(hours, id: \.0) { hour, congestion in
                VStack(spacing: 8) {
                    Text(hour)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                    Image(systemName: getTrafficIcon(for: congestion))
                        .font(.system(size: 24))
                        .foregroundColor(getTrafficColor(for: congestion))
                    
                    Text("\(Int(congestion))%")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 60)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func getTrafficIcon(for congestion: Double) -> String {
        if congestion < 40 { return "car" }
        if congestion < 70 { return "car.fill" }
        return "exclamationmark.triangle.fill"
    }
    
    private func getTrafficColor(for congestion: Double) -> Color {
        if congestion < 40 { return .green }
        if congestion < 70 { return .orange }
        return .red
    }
}

struct DailyTrafficRow: View {
    let prediction: TrafficPrediction
    
    var body: some View {
        HStack {
            Text(prediction.dayName)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 12) {
                TrafficIndicator(level: prediction.morning)
                TrafficIndicator(level: prediction.afternoon)
                TrafficIndicator(level: prediction.evening)
            }
        }
    }
}

struct TrafficIndicator: View {
    let level: CongestionLevel
    
    var body: some View {
        HStack {
            Image(systemName: getIcon())
                .foregroundColor(getColor())
        }
        .frame(width: 40)
    }
    
    private func getIcon() -> String {
        switch level {
        case .low: return "car"
        case .moderate: return "car.fill"
        case .heavy: return "exclamationmark.triangle.fill"
        }
    }
    
    private func getColor() -> Color {
        switch level {
        case .low: return .green
        case .moderate: return .orange
        case .heavy: return .red
        }
    }
}

struct StarsOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<100) { _ in
                Circle()
                    .fill(Color.white)
                    .frame(width: 1, height: 1)
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .opacity(Double.random(in: 0.1...0.5))
            }
        }
    }
}
