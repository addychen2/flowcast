import SwiftUI

struct TrafficPredictionView: View {
    @StateObject private var trafficManager = TrafficManager()
    
    var body: some View {
        ZStack {
            // Background color matching Weather app
            Color.black.opacity(0.95)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Location header
                    LocationHeaderView()
                        .padding(.top, 44)
                    
                    // Today's traffic
                    if let todayPrediction = trafficManager.predictions.first {
                        HourlyTrafficView(prediction: todayPrediction)
                    }
                    
                    // 5-day forecast
                    DailyTrafficView(predictions: Array(trafficManager.predictions.dropFirst()))
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
        }
        .background(
            // This ensures the gradient extends behind the tab bar
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.95),
                    Color.black.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        )
        .preferredColorScheme(.dark)
    }
}

struct LocationHeaderView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("TRAFFIC PREDICTIONS")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Text("Hacienda Heights")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HourlyTrafficView: View {
    let prediction: TrafficPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("TODAY'S TRAFFIC")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 50) {
                TimeSlotView(time: "Morning", level: prediction.morning)
                TimeSlotView(time: "Afternoon", level: prediction.afternoon)
                TimeSlotView(time: "Evening", level: prediction.evening)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
}

struct DailyTrafficView: View {
    let predictions: [TrafficPrediction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("5-DAY FORECAST")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            VStack(spacing: 0) {
                ForEach(predictions, id: \.dayName) { prediction in
                    DailyRowView(prediction: prediction)
                    if prediction.dayName != predictions.last?.dayName {
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }
}

struct DailyRowView: View {
    let prediction: TrafficPrediction
    
    var body: some View {
        HStack {
            Text(prediction.dayName)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 12) {
                CongestionPill(level: prediction.morning)
                CongestionPill(level: prediction.afternoon)
                CongestionPill(level: prediction.evening)
            }
        }
        .padding(.vertical, 12)
    }
}

struct TimeSlotView: View {
    let time: String
    let level: CongestionLevel
    
    var body: some View {
        VStack(spacing: 8) {
            Text(time)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            CongestionPill(level: level)
        }
    }
}

struct CongestionPill: View {
    let level: CongestionLevel
    
    var body: some View {
        Text(level.rawValue)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(pillBackground)
            .cornerRadius(16)
    }
    
    private var pillBackground: some View {
        backgroundColor
            .opacity(0.15)
            .overlay(
                Color.white.opacity(0.05)
            )
    }
    
    private var backgroundColor: Color {
        switch level {
        case .low: return .green
        case .moderate: return .orange
        case .heavy: return .red
        }
    }
    
    private var textColor: Color {
        switch level {
        case .low: return .green
        case .moderate: return .orange
        case .heavy: return .red
        }
    }
}
