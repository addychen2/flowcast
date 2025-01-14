import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @Binding var isActive: Bool
    var onSubmit: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search destination", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSubmit()
                }
                .submitLabel(.search)  // Shows search on keyboard
                .autocorrectionDisabled()  // Disable autocorrection
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    isActive = false
                    // Dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                 to: nil, from: nil, for: nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
        .padding(.horizontal)
        .background(Color.white)
        .cornerRadius(10)
    }
}
