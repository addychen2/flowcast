import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var authError: Error?
    @Published var verificationId: String?
    
    init() {
        setupAuthStateHandler()
    }
    
    private func setupAuthStateHandler() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.configError
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw AuthError.presentationError
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.googleSignInError
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        
        let authResult = try await Auth.auth().signIn(with: credential)
        self.user = authResult.user
        self.isAuthenticated = true
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
        } catch {
            self.authError = error
            throw AuthError.signInFailed
        }
    }
    
    func signUp(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
        } catch {
            self.authError = error
            throw AuthError.signUpFailed
        }
    }
    
    func signInWithPhone(phoneNumber: String) async throws {
        do {
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            self.verificationId = verificationID
        } catch {
            self.authError = error
            throw AuthError.phoneVerificationFailed
        }
    }
    
    func verifyCode(_ code: String) async throws {
        guard let verificationId = verificationId else {
            throw AuthError.verificationCodeMissing
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationId,
            verificationCode: code
        )
        
        do {
            let result = try await Auth.auth().signIn(with: credential)
            self.user = result.user
            self.isAuthenticated = true
            // Clear the verification ID after successful sign-in
            self.verificationId = nil
        } catch {
            self.authError = error
            throw AuthError.phoneSignInFailed
        }
    }
    
    func signOut() throws {
        // Sign out from Google
        GIDSignIn.sharedInstance.signOut()
        
        // Sign out from Firebase
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
        } catch {
            self.authError = error
            throw AuthError.signOutFailed
        }
    }
}

enum AuthError: LocalizedError {
    case signInFailed
    case signOutFailed
    case signUpFailed
    case googleSignInError
    case configError
    case presentationError
    case phoneVerificationFailed
    case phoneSignInFailed
    case verificationCodeMissing
    
    var errorDescription: String? {
        switch self {
        case .signInFailed:
            return "Failed to sign in. Please check your credentials and try again."
        case .signOutFailed:
            return "Failed to sign out. Please try again."
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .googleSignInError:
            return "Google sign in failed. Please try again."
        case .configError:
            return "App configuration error."
        case .presentationError:
            return "Could not present sign in screen."
        case .phoneVerificationFailed:
            return "Failed to verify phone number. Please try again."
        case .phoneSignInFailed:
            return "Failed to sign in with phone number. Please try again."
        case .verificationCodeMissing:
            return "Verification code is missing. Please request a new code."
        }
    }
}
