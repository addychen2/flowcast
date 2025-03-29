import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import SafariServices

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var authError: Error?
    @Published var verificationId: String?
    
    // MFA related properties
    @Published var isMFARequired = false
    @Published var mfaVerificationId: String?
    @Published var multiFactorResolver: MultiFactorResolver?
    
    // RecaptchaUIDelegate class that handles presentation conflicts properly
    private class RecaptchaUIDelegate: NSObject, AuthUIDelegate {
        func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            print("Preparing to present reCAPTCHA verification...")
            
            // Find the proper view controller to present on
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                print("Error: Cannot find root view controller")
                completion?()
                return
            }
            
            // Find the topmost view controller
            var topController = rootVC
            while let presentedVC = topController.presentedViewController {
                topController = presentedVC
            }
            
            // When a Safari view is already presented, dismiss it first
            if topController is SFSafariViewController {
                print("Dismissing existing Safari controller first...")
                topController.dismiss(animated: true) {
                    // Find root view controller again after dismissal
                    if let newScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let newRoot = newScene.windows.first?.rootViewController {
                        var newTop = newRoot
                        while let presentedVC = newTop.presentedViewController {
                            newTop = presentedVC
                        }
                        
                        // Present on the new topmost controller
                        print("Now presenting reCAPTCHA on new topmost controller...")
                        DispatchQueue.main.async {
                            newTop.present(viewControllerToPresent, animated: flag, completion: completion)
                        }
                    }
                }
                return
            }
            
            // Present on the topmost controller
            print("Presenting reCAPTCHA on topmost controller...")
            DispatchQueue.main.async {
                topController.present(viewControllerToPresent, animated: flag, completion: completion)
            }
        }
        
        func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
            print("Dismissing reCAPTCHA verification...")
            // Find the proper view controller to dismiss from
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                print("Error: Cannot find root view controller for dismissal")
                completion?()
                return
            }
            
            // Find the topmost view controller
            var topController = rootVC
            while let presentedVC = topController.presentedViewController {
                topController = presentedVC
            }
            
            // Dismiss from the topmost controller
            DispatchQueue.main.async {
                topController.dismiss(animated: flag, completion: completion)
            }
        }
    }
    
    // Shared UI delegate instance
    private let recaptchaUIDelegate = RecaptchaUIDelegate()
    
    init() {
        setupAuthStateHandler()
    }
    
    private func setupAuthStateHandler() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                
                // Reset state when auth state changes
                if user != nil {
                    self?.verificationId = nil
                    self?.isMFARequired = false
                    self?.mfaVerificationId = nil
                    self?.multiFactorResolver = nil
                }
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
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.googleSignInError
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            try await signInWithCredential(credential)
        } catch {
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            self.isAuthenticated = true
        } catch let error as NSError {
            // Handle multi-factor authentication
            if error.domain == AuthErrorDomain && 
               error.code == AuthErrorCode.secondFactorRequired.rawValue {
                
                if let resolver = error.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as? MultiFactorResolver {
                    // Store the resolver for the MFA flow
                    self.multiFactorResolver = resolver
                    self.isMFARequired = true
                    
                    // Signal that MFA is required but don't throw an error
                    throw AuthError.mfaRequired
                } else {
                    self.authError = error
                    throw AuthError.signInFailed
                }
            } else {
                self.authError = error
                throw AuthError.signInFailed
            }
        }
    }
    
    private func signInWithCredential(_ credential: AuthCredential) async throws {
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
            self.isAuthenticated = true
        } catch let error as NSError {
            // Handle multi-factor authentication
            if error.domain == AuthErrorDomain && 
               error.code == AuthErrorCode.secondFactorRequired.rawValue {
                
                if let resolver = error.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as? MultiFactorResolver {
                    // Store the resolver for the MFA flow
                    self.multiFactorResolver = resolver
                    self.isMFARequired = true
                    
                    // Signal that MFA is required
                    throw AuthError.mfaRequired
                } else {
                    throw AuthError.signInFailed
                }
            } else {
                throw error
            }
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
            // Use the shared RecaptchaUIDelegate
            let uiDelegate = self.recaptchaUIDelegate
            
            // This will show the reCAPTCHA verification if needed
            print("Starting phone verification for \(phoneNumber) with reCAPTCHA...")
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: uiDelegate)
            
            print("Verification code sent successfully to \(phoneNumber)")
            self.verificationId = verificationID
        } catch {
            self.authError = error
            print("Phone verification failed: \(error.localizedDescription)")
            throw AuthError.phoneVerificationFailed
        }
    }
    
    func verifyCode(_ code: String) async throws {
        // Handle phone auth verification
        if let verificationId = verificationId {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationId,
                verificationCode: code
            )
            
            do {
                try await signInWithCredential(credential)
                // Clear the verification ID after successful sign-in
                self.verificationId = nil
            } catch {
                self.authError = error
                throw AuthError.phoneSignInFailed
            }
        } else {
            throw AuthError.verificationCodeMissing
        }
    }
    
    // Request MFA verification code
    func requestMFAVerificationCode(phoneNumber: String? = nil) async throws -> String? {
        guard let resolver = multiFactorResolver else {
            throw AuthError.noMultiFactorSession
        }
        
        do {
            // Use the shared RecaptchaUIDelegate
            let uiDelegate = self.recaptchaUIDelegate
            
            // If there's a phone number hint from the resolver, use it
            let hint: PhoneMultiFactorInfo
            
            if let phoneHint = resolver.hints.first as? PhoneMultiFactorInfo {
                // Use the phone number from the resolver
                hint = phoneHint
            } else {
                throw AuthError.noPhoneNumberForMFA
            }
            
            print("Sending verification code to \(hint.phoneNumber)")
            
            // Send the verification code with a UI delegate for reCAPTCHA
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(
                with: hint,
                uiDelegate: uiDelegate,
                multiFactorSession: resolver.session
            )
            
            // Store the verification ID
            self.mfaVerificationId = verificationID
            
            return hint.phoneNumber
        } catch {
            print("Failed to send MFA verification code: \(error.localizedDescription)")
            throw AuthError.mfaVerificationFailed
        }
    }
    
    // Complete MFA with verification code
    func verifyMFACode(_ code: String) async throws {
        guard let resolver = multiFactorResolver, let verificationId = mfaVerificationId else {
            throw AuthError.noMultiFactorSession
        }
        
        do {
            // Create credential with the verification code
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationId,
                verificationCode: code
            )
            
            // Create assertion
            let assertion = PhoneMultiFactorGenerator.assertion(with: credential)
            
            // Complete sign-in with second factor
            let result = try await resolver.resolveSignIn(with: assertion)
            
            // Update user and authentication state
            self.user = result.user
            self.isAuthenticated = true
            
            // Reset MFA state
            self.isMFARequired = false
            self.mfaVerificationId = nil
            self.multiFactorResolver = nil
        } catch {
            print("Failed to verify MFA code: \(error.localizedDescription)")
            throw AuthError.mfaVerificationFailed
        }
    }
    
    // Add method to cancel MFA
    func cancelMFA() {
        self.isMFARequired = false
        self.mfaVerificationId = nil
        self.multiFactorResolver = nil
    }
    
    // Enroll a new phone for MFA
    func enrollPhoneInMFA(phoneNumber: String, displayName: String? = nil) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notSignedIn
        }
        
        do {
            print("Starting MFA enrollment for \(phoneNumber)")
            
            // Use the shared RecaptchaUIDelegate
            let uiDelegate = self.recaptchaUIDelegate
            
            // Get multi-factor session using the correct method name
            let mfaSession = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MultiFactorSession, Error>) in
                user.multiFactor.getSessionWithCompletion { (session, error) in
                    if let error = error {
                        print("Error getting MFA session: \(error)")
                        continuation.resume(throwing: error)
                    } else if let session = session {
                        continuation.resume(returning: session)
                    } else {
                        continuation.resume(throwing: AuthError.noMultiFactorSession)
                    }
                }
            }
            
            print("Successfully retrieved MFA session")
            
            // Send verification code with the session and a UI delegate for reCAPTCHA
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(
                phoneNumber,
                uiDelegate: uiDelegate,
                multiFactorSession: mfaSession
            )
            
            print("Verification code sent to \(phoneNumber)")
            
            // Store for later use
            self.mfaVerificationId = verificationID
            
            return
        } catch let nsError as NSError {
            // Print detailed error information
            print("MFA enrollment error details: \(nsError)")
            print("Error domain: \(nsError.domain), code: \(nsError.code)")
            print("Error description: \(nsError.localizedDescription)")
            print("User info: \(nsError.userInfo)")
            
            // If it's a Firebase auth error, print the specific error code
            if nsError.domain == AuthErrorDomain {
                print("Firebase Auth error code: \(nsError.code)")
                
                // Handle specific Firebase Auth errors based on code
                switch nsError.code {
                case 17042: // captchaCheckFailed
                    print("reCAPTCHA check failed")
                case 17043: // webContextCancelled
                    print("Web context cancelled - user may have dismissed reCAPTCHA")
                case 17044: // webNetworkRequestFailed
                    print("Web network request failed - check internet connection")
                case 17045: // webInternalError
                    print("Web internal error with reCAPTCHA")
                case 17048: // invalidMultiFactorSession
                    print("Invalid multi-factor session")
                case 17049: // missingMultiFactorSession
                    print("Missing multi-factor session")
                case 17051: // missingPhoneNumber
                    print("Missing phone number for verification")
                case 17057: // unverifiedEmail
                    print("Unverified email - email verification is required before enabling MFA")
                default:
                    print("Other Firebase Auth error: \(nsError.code)")
                }
            }
            
            // Show Firebase auth errors directly to the user instead of using a generic error
            if nsError.domain == AuthErrorDomain {
                throw nsError
            } else {
                throw AuthError.mfaEnrollmentFailed
            }
        } catch {
            print("Other error: \(error.localizedDescription)")
            throw AuthError.mfaEnrollmentFailed
        }
    }
    
    // Complete MFA enrollment with verification code
    func completePhoneEnrollment(verificationCode: String, displayName: String? = nil) async throws {
        guard let user = Auth.auth().currentUser, let verificationId = mfaVerificationId else {
            throw AuthError.notSignedIn
        }
        
        do {
            // Create credential to verify the code is correct
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationId,
                verificationCode: verificationCode
            )
            
            // Create assertion
            let assertion = PhoneMultiFactorGenerator.assertion(with: credential)
            
            // Try the enrollment
            print("Attempting to enroll phone in MFA...")
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                user.multiFactor.enroll(with: assertion, displayName: displayName ?? "Phone") { error in
                    if let error = error {
                        print("MFA enrollment error details: \(error)")
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
            
            print("Successfully enrolled phone in MFA")
            // Reset state
            self.mfaVerificationId = nil
            
        } catch {
            print("Failed to complete MFA enrollment: \(error.localizedDescription)")
            throw AuthError.mfaEnrollmentFailed
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
            self.verificationId = nil
            self.isMFARequired = false
            self.mfaVerificationId = nil
            self.multiFactorResolver = nil
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
    case mfaRequired
    case mfaVerificationFailed
    case mfaEnrollmentFailed
    case noMultiFactorSession
    case noPhoneNumberForMFA
    case notSignedIn
    
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
        case .mfaRequired:
            return "Multi-factor authentication is required. Please complete verification."
        case .mfaVerificationFailed:
            return "Failed to verify second factor. Please try again."
        case .mfaEnrollmentFailed:
            return "Failed to enroll in multi-factor authentication. Please try again."
        case .noMultiFactorSession:
            return "No multi-factor session available. Please sign in again."
        case .noPhoneNumberForMFA:
            return "No phone number available for multi-factor authentication."
        case .notSignedIn:
            return "You must be signed in to perform this action."
        }
    }
}
