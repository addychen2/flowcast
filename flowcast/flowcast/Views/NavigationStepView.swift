import SwiftUI
import MapKit

struct NavigationStepView: View {
    let step: MKRoute.Step
    var onNextStep: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.turn.up.right")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                Text(step.instructions)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal)
            
            HStack {
                Text(String(format: "%.1f km", step.distance / 1000))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: onNextStep) {
                    HStack {
                        Text("Next Step")
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
}
