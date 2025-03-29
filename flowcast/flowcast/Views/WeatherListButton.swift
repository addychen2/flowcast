import SwiftUI

// Note: This component is no longer needed as the functionality
// has been integrated into the WeatherContentView directly.
// Keeping this file for reference.

struct WeatherListButton: View {
    @Binding var isListViewShowing: Bool
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Pagination dots
            HStack(spacing: 4) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.white : Color.gray.opacity(0.5))
                        .frame(width: 6, height: 6)
                }
            }
            
            Button(action: {
                isListViewShowing.toggle()
            }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray
            .ignoresSafeArea()
        WeatherListButton(
            isListViewShowing: .constant(false),
            currentPage: 0,
            totalPages: 5
        )
    }
}
