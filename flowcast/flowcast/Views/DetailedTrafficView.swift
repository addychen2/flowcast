import SwiftUI

struct DetailedTrafficView: View {
    let date: Date
    let prediction: TrafficPrediction
    @Environment(\.dismiss) private var dismiss
    
    private let hourlyTraffic: [(String, Int)] = [
        ("12AM", 25), ("3AM", 15), ("6AM", 45),
        ("9AM", 75), ("12PM", 65), ("3PM", 85),
        ("6PM", 70), ("9PM", 40), ("11PM", 30)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with date
                    VStack {
                        Text(date.formatted(date: .complete, time: .omitted))
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding(.top)
                    
                    // Current congestion level
                    VStack(spacing: 8) {
                        Text("\(Int.random(in: 25...75))%")
                            .font(.system(size: 96, weight: .thin))
                            .foregroundColor(.white)
                        
                        Text(getCongestionDescription(for: prediction.afternoon))
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text("Peak: \(prediction.evening.rawValue)")
                            Text("Low: \(prediction.morning.rawValue)")
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                    
                    // Traffic graph
                    VStack(alignment: .leading, spacing: 8) {
                        Text("24-HOUR TRAFFIC")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.leading)
                        
                        TrafficGraph(data: hourlyTraffic)
                            .frame(height: 200)
                            .padding(.horizontal)
                    }
                    
                    // Detailed predictions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TRAFFIC CONDITIONS")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.leading)
                        
                        VStack(spacing: 20) {
                            TrafficPeriodView(period: "Morning", level: prediction.morning)
                            TrafficPeriodView(period: "Afternoon", level: prediction.afternoon)
                            TrafficPeriodView(period: "Evening", level: prediction.evening)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
            .overlay(StarsOverlay())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private func getCongestionDescription(for level: CongestionLevel) -> String {
        switch level {
        case .low: return "Light Traffic"
        case .moderate: return "Moderate Traffic"
        case .heavy: return "Heavy Traffic"
        }
    }
}

struct TrafficGraph: View {
    let data: [(String, Int)]
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width / CGFloat(data.count - 1)
                    let height = geometry.size.height
                    
                    path.move(to: CGPoint(
                        x: 0,
                        y: height * (1 - CGFloat(data[0].1) / 100)
                    ))
                    
                    for i in 1..<data.count {
                        let point = CGPoint(
                            x: width * CGFloat(i),
                            y: height * (1 - CGFloat(data[i].1) / 100)
                        )
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                
                // Time labels
                HStack {
                    ForEach(data, id: \.0) { time, _ in
                        Text(time)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .offset(y: geometry.size.height + 8)
            }
            .padding(.bottom, 20) // Space for labels
        }
    }
}

struct TrafficPeriodView: View {
    let period: String
    let level: CongestionLevel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(period)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(getTimeRange(for: period))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: getIcon(for: level))
                    .foregroundColor(level.color)
                Text(level.rawValue)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func getTimeRange(for period: String) -> String {
        switch period {
        case "Morning": return "6 AM - 12 PM"
        case "Afternoon": return "12 PM - 5 PM"
        case "Evening": return "5 PM - 10 PM"
        default: return ""
        }
    }
    
    private func getIcon(for level: CongestionLevel) -> String {
        switch level {
        case .low: return "car"
        case .moderate: return "car.fill"
        case .heavy: return "exclamationmark.triangle.fill"
        }
    }
}
