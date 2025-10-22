import Foundation
import Combine
import FirebaseAuth
import AuthenticationServices
import CryptoKit
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
import UIKit

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
  @Published var user: User?
  @Published var email: String = ""
  @Published var password: String = ""
  @Published var status: String = ""

  // For Apple nonce
  private var currentNonce: String?

  override init() {
      super.init()
    self.user = Auth.auth().currentUser
    Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.user = user
    }
  }

  // MARK: - Email/Password
  func signUpWithEmail() async {
    do {
      let result = try await Auth.auth().createUser(withEmail: email, password: password)
      self.user = result.user
      self.status = "Signed up as \(result.user.email ?? "")"
    } catch {
      self.status = "Sign up error: \(error.localizedDescription)"
    }
  }

  func signInWithEmail() async {
    do {
      let result = try await Auth.auth().signIn(withEmail: email, password: password)
      self.user = result.user
      self.status = "Signed in as \(result.user.email ?? "")"
    } catch {
      self.status = "Sign in error: \(error.localizedDescription)"
    }
  }

  func signOut() {
    do {
      try Auth.auth().signOut()
      self.user = nil
      self.status = "Signed out"
    } catch {
      self.status = "Sign out error: \(error.localizedDescription)"
    }
  }

  // MARK: - Handle incoming URLs (email links / Google)
  func handleOpenURL(_ url: URL) {
    // 1) Email-link sign in (if you enable email link)
    if Auth.auth().isSignIn(withEmailLink: url.absoluteString),
       !email.isEmpty {
      Task {
        do {
          let result = try await Auth.auth().signIn(withEmail: email, link: url.absoluteString)
          self.user = result.user
          self.status = "Signed in via email link"
        } catch {
          self.status = "Email link error: \(error.localizedDescription)"
        }
      }
    }

    // 2) Google handled via GIDSignIn (iOS 13+ new API uses scene-based presentation)
#if canImport(GoogleSignIn)
    GIDSignIn.sharedInstance.handle(url)
#endif
  }

  // MARK: - Sign in with Apple
  func startSignInWithAppleFlow() {
    let nonce = randomNonceString()
    currentNonce = nonce
    let request = ASAuthorizationAppleIDProvider().createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)

    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.delegate = self
    controller.presentationContextProvider = self
    controller.performRequests()
  }

  // MARK: - Google Sign-In
  func signInWithGoogle() {
#if canImport(GoogleSignIn)
    guard let rootVC = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })?.rootViewController else {
      status = "Google: no root VC"
      return
    }

    GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
      guard let self = self else { return }
      if let error = error {
        self.status = "Google error: \(error.localizedDescription)"
        return
      }
      guard let idToken = result?.user.idToken?.tokenString,
            let accessToken = result?.user.accessToken.tokenString else {
        self.status = "Google: missing tokens"
        return
      }
      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
      Task {
        do {
          let authResult = try await Auth.auth().signIn(with: credential)
          self.user = authResult.user
          self.status = "Signed in with Google as \(authResult.user.email ?? "")"
        } catch {
          self.status = "Firebase Google error: \(error.localizedDescription)"
        }
      }
    }
#else
    status = "GoogleSignIn package not added."
#endif
  }
}

// MARK: - Apple helpers
extension AuthViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow } ?? UIWindow()
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
          let nonce = currentNonce,
          let appleIDToken = appleIDCredential.identityToken,
          let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
      status = "Apple: missing credentials"
      return
    }
    let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                              rawNonce: nonce,
                                              fullName: nil)
    Task {
      do {
        let result = try await Auth.auth().signIn(with: credential)
        self.user = result.user
        self.status = "Signed in with Apple"
      } catch {
        self.status = "Firebase Apple error: \(error.localizedDescription)"
      }
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    status = "Apple sign-in failed: \(error.localizedDescription)"
  }
}

// MARK: - Nonce / SHA helpers for Apple
private func sha256(_ input: String) -> String {
  let inputData = Data(input.utf8)
  let hashed = SHA256.hash(data: inputData)
  return hashed.compactMap { String(format: "%02x", $0) }.joined()
}

private func randomNonceString(length: Int = 32) -> String {
  precondition(length > 0)
  let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
  var result = ""
  var remainingLength = length

  while remainingLength > 0 {
    var random: UInt8 = 0
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
    if errorCode != errSecSuccess {
      fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
    }
    if random < charset.count {
      result.append(charset[Int(random)])
      remainingLength -= 1
    }
  }
  return result
}
