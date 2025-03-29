import SwiftUI
import FirebaseAuth

struct MultiFactorAuthView: View {
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var isRequestingCode = true // Start by requesting code
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var phoneHint = "your phone"
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Text("Two-Factor Authentication Required")
                    .font(.headline)
                    .padding(.top, 20)
                
                if isRequestingCode {
                    ProgressView("Sending verification code...")
                        .padding()
                } else {
                    Text("Enter the verification code sent to \(phoneHint)")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                    
                    TextField("Verification Code", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .modifier(AuthTextFieldStyle())
                    
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        Task {
                            await handleVerification()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Verify")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(AuthButtonStyle(backgroundColor: .blue, foregroundColor: .white))
                    .disabled(isLoading || verificationCode.isEmpty)
                    
                    Button("Request New Code") {
                        isRequestingCode = true
                        Task {
                            await requestVerificationCode()
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 10)
                }
                
                Button("Cancel") {
                    authManager.cancelMFA()
                    dismiss()
                }
                .foregroundColor(.blue)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        authManager.cancelMFA()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                // If this is the first appearance and we need to request a code
                Task {
                    await requestVerificationCode()
                }
            }
            .onDisappear {
                // Ensure we reset the state if the view is dismissed
                if authManager.isMFARequired {
                    authManager.cancelMFA()
                }
            }
        }
    }
    
    private func requestVerificationCode() async {
        isRequestingCode = true
        showError = false
        
        do {
            // Request verification code from the auth manager
            if let phoneNumber = try await authManager.requestMFAVerificationCode() {
                // Format phone for display
                phoneHint = formatPhoneNumber(phoneNumber)
            }
            
            isRequestingCode = false
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            isRequestingCode = false
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Format phone number for display, e.g., "+1 (555) 123-4567" -> "***-4567"
        let digits = number.filter { $0.isNumber }
        if digits.count >= 4 {
            let lastFour = String(digits.suffix(4))
            return "***-\(lastFour)"
        }
        return number
    }
    
    private func handleVerification() async {
        isLoading = true
        showError = false
        
        do {
            try await authManager.verifyMFACode(verificationCode)
            // Authentication will be completed and the sheet will be dismissed
            dismiss()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Previews
#Preview {
    MultiFactorAuthView()
        .environmentObject(AuthenticationManager())
}