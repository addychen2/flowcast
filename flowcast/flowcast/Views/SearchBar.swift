import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @Binding var isActive: Bool
    var onSubmit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            TextField("Search destination", text: $text)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .font(.system(size: 16))
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    isActive = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                 to: nil, from: nil, for: nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
            }
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 2)
    }
}
