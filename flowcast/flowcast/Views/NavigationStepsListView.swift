import SwiftUI
import MapKit

struct NavigationStepsListView: View {
    let route: MKRoute
    let currentStepIndex: Int
    let destination: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(route.steps.enumerated()), id: \.element) { index, step in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: getDirectionIcon(for: step))
                                .foregroundColor(index == currentStepIndex ? .blue : .gray)
                            
                            Text(step.instructions)
                                .font(.system(size: 16, weight: index == currentStepIndex ? .bold : .regular))
                            
                            Spacer()
                            
                            Text(formatDistance(step.distance))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        if index == currentStepIndex {
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(destination)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func getDirectionIcon(for step: MKRoute.Step) -> String {
        let instructions = step.instructions.lowercased()
        if instructions.contains("right") {
            return "arrow.turn.up.right"
        } else if instructions.contains("left") {
            return "arrow.turn.up.left"
        } else if instructions.contains("merge") {
            return "arrow.merge"
        } else if instructions.contains("exit") {
            return "arrow.up.right"
        } else if instructions.contains("u-turn") {
            return "arrow.uturn.right"
        } else {
            return "arrow.up"
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1609.34 {
            let miles = distance / 1609.34
            return String(format: "%.1f mi", miles)
        } else {
            let feet = Int(distance * 3.28084)
            return "\(feet) ft"
        }
    }
}
