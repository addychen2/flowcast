import SwiftUI

struct SpeedLimitView: View {
    let speedLimit: Int
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(.black, lineWidth: 3)
                .background(Circle().foregroundColor(.white))
                .frame(width: 45, height: 45)
            
            Text("\(speedLimit)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
        }
        .shadow(radius: 2)
    }
}

// Preview Provider
struct SpeedLimitView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
            SpeedLimitView(speedLimit: 45)
        }
    }
}
