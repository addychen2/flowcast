import SwiftUI

struct PhoneAuthView: View {
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var showVerificationView = false
    @State private var showError = false
    @State private var errorMessage = ""
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Text("Enter your phone number")
                    .font(.headline)
                    .padding(.top, 40)
                
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .modifier(AuthTextFieldStyle())
                    .onChange(of: phoneNumber) { newValue in
                        // Format phone number as user types
                        phoneNumber = formatPhoneNumber(newValue)
                    }
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    Task {
                        await handlePhoneSignIn()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(AuthButtonStyle(backgroundColor: .blue, foregroundColor: .white))
                .disabled(isLoading || !isValidPhoneNumber)
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.blue)
                
                Spacer()
            }
            .navigationTitle("Phone Sign In")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showVerificationView) {
            VerificationView(phoneNumber: phoneNumber)
        }
    }
    
    private var isValidPhoneNumber: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count == 10
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        if digits.count > 10 {
            return phoneNumber
        }
        
        var formatted = ""
        for (index, digit) in digits.enumerated() {
            if index == 0 {
                formatted = "(" + String(digit)
            } else if index == 3 {
                formatted += ") " + String(digit)
            } else if index == 6 {
                formatted += "-" + String(digit)
            } else {
                formatted += String(digit)
            }
        }
        return formatted
    }
    
    private func handlePhoneSignIn() async {
        isLoading = true
        showError = false
        
        do {
            // Format phone number for Firebase
            let formattedNumber = "+1" + phoneNumber.filter { $0.isNumber }
            try await authManager.signInWithPhone(phoneNumber: formattedNumber)
            showVerificationView = true
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct VerificationView: View {
    let phoneNumber: String
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Enter verification code")
                .font(.headline)
                .padding(.top, 40)
            
            Text("A 6-digit code has been sent to\n\(phoneNumber)")
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
            .disabled(isLoading || verificationCode.count != 6)
            
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.blue)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func handleVerification() async {
        isLoading = true
        showError = false
        
        do {
            try await authManager.verifyCode(verificationCode)
            dismiss()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// Preview
struct PhoneAuthView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneAuthView()
            .environmentObject(AuthenticationManager())
    }
}
