import SwiftUI

enum CongestionLevel: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case heavy = "Heavy"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .orange
        case .heavy: return .red
        }
    }
}

struct TrafficPrediction {
    let dayName: String
    let morning: CongestionLevel
    let afternoon: CongestionLevel
    let evening: CongestionLevel
}
