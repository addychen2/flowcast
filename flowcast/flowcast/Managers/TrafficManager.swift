import Foundation
import CoreLocation

class TrafficManager: ObservableObject {
    @Published var predictions: [TrafficPrediction] = []
    
    init() {
        generatePredictions()
    }
    
    func generatePredictions() {
        let calendar = Calendar.current
        let weekdaySymbols = calendar.weekdaySymbols
        
        predictions = (0..<5).map { dayOffset in
            let date = Date().addingTimeInterval(TimeInterval(86400 * dayOffset))
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let dayName = dayOffset == 0 ? "Today" :
                         dayOffset == 1 ? "Tomorrow" :
                         weekdaySymbols[weekdayIndex]
            
            // In a real app, this would use historical data and real-time traffic info
            return TrafficPrediction(
                dayName: dayName,
                morning: generateRandomCongestion(),
                afternoon: generateRandomCongestion(),
                evening: generateRandomCongestion()
            )
        }
    }
    
    private func generateRandomCongestion() -> CongestionLevel {
        let random = Double.random(in: 0...1)
        if random < 0.3 { return .low }
        if random < 0.7 { return .moderate }
        return .heavy
    }
    
    func refresh() {
        generatePredictions()
    }
}
