import SwiftUI

struct MapControlButton: View {
    let icon: String
    let action: () -> Void
    var backgroundColor: Color = .white
    var iconColor: Color = .black
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .padding(12)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(radius: 2)
        }
    }
}
