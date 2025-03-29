import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var routeManager: RouteManager
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showMFAEnrollment = false
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var mfaEnrollmentStep = 0 // 0: not started, 1: phone entered, 2: verification code needed
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        if let email = authManager.user?.email {
                            Text(email)
                                .font(.headline)
                        } else if let phoneNumber = authManager.user?.phoneNumber {
                            Text(phoneNumber)
                                .font(.headline)
                        } else {
                            Text("User")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                Section("Account") {
                    NavigationLink(destination: SavedTripsView()
                        .environmentObject(routeManager)
                        .environmentObject(authManager)
                    ) {
                        Label("Saved Routes", systemImage: "bookmark.fill")
                    }
                    
                    Button(action: {
                        showMFAEnrollment = true
                    }) {
                        Label("Set Up Two-Factor Authentication", systemImage: "lock.shield")
                    }
                    
                    Button(action: {
                        requestSignOut()
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showMFAEnrollment) {
                mfaEnrollmentView
            }
        }
    }
    
    // MFA Enrollment View
    private var mfaEnrollmentView: some View {
        NavigationView {
            VStack(spacing: 20) {
                if mfaEnrollmentStep == 0 {
                    // Phone number entry step
                    Text("Set up Two-Factor Authentication")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    TextField("Phone Number (with country code)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Text("Enter your full phone number with country code (e.g., +1 for US)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button("Send Verification Code") {
                        Task {
                            await sendMFAVerificationCode()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .disabled(phoneNumber.isEmpty)
                    
                } else if mfaEnrollmentStep == 1 {
                    // Verification code entry step
                    Text("Enter verification code")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                        
                    Text("Enter the 6-digit code sent to your phone")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    TextField("Verification Code", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Button("Verify and Enable 2FA") {
                        Task {
                            await completeMFAEnrollment()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .disabled(verificationCode.isEmpty)
                    
                    Button("Request New Code") {
                        Task {
                            mfaEnrollmentStep = 0
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 10)
                } else if mfaEnrollmentStep == 2 {
                    // Success view
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .padding()
                        
                        Text("Two-Factor Authentication Enabled")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("Your account is now more secure. You'll be asked for a verification code when signing in.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Button("Done") {
                            showMFAEnrollment = false
                            mfaEnrollmentStep = 0
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Two-Factor Authentication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showMFAEnrollment = false
                        mfaEnrollmentStep = 0
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // Send verification code for MFA enrollment
    private func sendMFAVerificationCode() async {
        do {
            print("Attempting to enroll phone: \(phoneNumber) in MFA")
            try await authManager.enrollPhoneInMFA(phoneNumber: phoneNumber)
            print("Successfully sent verification code, moving to next step")
            mfaEnrollmentStep = 1
        } catch let nsError as NSError {
            // Print detailed error in console
            print("MFA enrollment error: \(nsError)")
            print("Error domain: \(nsError.domain), code: \(nsError.code)")
            
            // Show a more detailed error to the user
            if nsError.domain == AuthErrorDomain {
                // For Firebase Auth errors, show the actual error description
                alertMessage = "Firebase error: \(nsError.localizedDescription)"
            } else {
                // For other errors, show a more generic message with details
                alertMessage = "Error sending verification code: \(nsError.localizedDescription)\nCode: \(nsError.code)"
            }
            
            showAlert = true
        } catch {
            print("Unknown error: \(error)")
            alertMessage = "Error sending verification code: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // Complete MFA enrollment with verification code
    private func completeMFAEnrollment() async {
        do {
            print("Attempting to complete MFA enrollment with code: \(verificationCode)")
            try await authManager.completePhoneEnrollment(verificationCode: verificationCode, displayName: "Primary Phone")
            print("Successfully completed MFA enrollment")
            mfaEnrollmentStep = 2 // Success
        } catch let nsError as NSError {
            // Print detailed error in console
            print("MFA enrollment completion error: \(nsError)")
            print("Error domain: \(nsError.domain), code: \(nsError.code)")
            
            // Show a more detailed error to the user
            if nsError.domain == AuthErrorDomain {
                // For Firebase Auth errors, show the actual error description
                alertMessage = "Firebase error: \(nsError.localizedDescription)"
            } else {
                // For other errors, show a more generic message with details
                alertMessage = "Error verifying code: \(nsError.localizedDescription)\nCode: \(nsError.code)"
            }
            
            showAlert = true
        } catch {
            print("Unknown error completing enrollment: \(error)")
            alertMessage = "Error verifying code: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func requestSignOut() {
        do {
            try authManager.signOut()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
        .environmentObject(RouteManager(locationManager: LocationManager()))
}
