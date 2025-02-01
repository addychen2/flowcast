import SwiftUI

struct AuthTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
    }
}

struct AuthButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(10)
            .padding(.horizontal)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct AuthenticationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSignUp = false
    @State private var showPhoneAuth = false
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Logo and Title
                VStack(spacing: 15) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Flowcast")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text(isSignUp ? "Create your account" : "Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                // Input Fields
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .modifier(AuthTextFieldStyle())
                    
                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .modifier(AuthTextFieldStyle())
                    
                    if isSignUp {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .modifier(AuthTextFieldStyle())
                    }
                }
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Main Action Button
                Button(action: {
                    Task {
                        if isSignUp {
                            await handleSignUp()
                        } else {
                            await handleSignIn()
                        }
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(AuthButtonStyle(backgroundColor: .blue, foregroundColor: .white))
                .disabled(isLoading || !isValidInput)
                
                // Separator
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                    Text("OR")
                        .foregroundColor(.gray)
                        .font(.footnote)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal)
                
                // Social Sign In Options
                if !isSignUp {
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await handleGoogleSignIn()
                            }
                        }) {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                Text("Continue with Google")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(AuthButtonStyle(backgroundColor: .white, foregroundColor: .black))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .padding(.horizontal)
                        )
                        .disabled(isLoading)
                        
                        // Phone Sign In Button
                        Button(action: { showPhoneAuth = true }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                Text("Continue with Phone")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(AuthButtonStyle(backgroundColor: .white, foregroundColor: .black))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .padding(.horizontal)
                        )
                        .disabled(isLoading)
                    }
                }
                
                // Toggle Button
                Button(action: {
                    withAnimation {
                        isSignUp.toggle()
                        email = ""
                        password = ""
                        confirmPassword = ""
                        showError = false
                    }
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                .padding(.top, 10)
                
                if !isSignUp {
                    Button(action: {
                        // Handle forgot password
                    }) {
                        Text("Forgot Password?")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 5)
                }
            }
            .padding(.bottom, 50)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showPhoneAuth) {
            PhoneAuthView()
        }
    }
    
    private var isValidInput: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty &&
                   password.count >= 6 && password == confirmPassword
        }
        return !email.isEmpty && !password.isEmpty
    }
    
    private func handleSignIn() async {
        isLoading = true
        do {
            try await authManager.signIn(email: email, password: password)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func handleSignUp() async {
        guard password == confirmPassword else {
            showError = true
            errorMessage = "Passwords don't match"
            return
        }
        
        isLoading = true
        do {
            try await authManager.signUp(email: email, password: password)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func handleGoogleSignIn() async {
        isLoading = true
        do {
            try await authManager.signInWithGoogle()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// Preview
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AuthenticationManager())
    }
}
