import SwiftUI

struct CompassView: View {
    let heading: Double?
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .shadow(radius: 2)
            
            Image(systemName: "location.north.fill")
                .font(.system(size: 20))
                .foregroundColor(.black)
                .rotationEffect(.degrees(-(heading ?? 0)))
        }
    }
}
