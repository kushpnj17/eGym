import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import UIKit

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
  // MARK: Published state
  @Published var user: FirebaseAuth.User?
  @Published var status: String = ""
  @Published var isLoading: Bool = false

  // MARK: Apple Sign-In nonce
  private var currentNonce: String?

  // MARK: Init
  override init() {
    super.init()

    // keep SwiftUI in sync with Firebase auth state
    Auth.auth().addStateDidChangeListener { [weak self] _, user in
      guard let self else { return }
      self.user = user
    }
  }

  // MARK: - Email / Password

  func register(email: String, password: String) {
    isLoading = true
    Task {
      do {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        self.user = result.user
        self.status = "Registered as \(result.user.email ?? "user")"
      } catch {
        self.status = "Registration failed: \(error.localizedDescription)"
      }
      self.isLoading = false
    }
  }

  func signIn(email: String, password: String) {
    isLoading = true
    Task {
      do {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.user = result.user
        self.status = "Signed in as \(result.user.email ?? "user")"
      } catch {
        self.status = "Login failed: \(error.localizedDescription)"
      }
      self.isLoading = false
    }
  }

  func sendPasswordReset(to email: String) {
    Task {
      do {
        try await Auth.auth().sendPasswordReset(withEmail: email)
        self.status = "Password reset email sent."
      } catch {
        self.status = "Reset failed: \(error.localizedDescription)"
      }
    }
  }

  func signOut() {
    do {
      try Auth.auth().signOut()
      self.user = nil
      self.status = "Signed out."
    } catch {
      self.status = "Sign out failed: \(error.localizedDescription)"
    }
  }

  // MARK: - Google Sign-In

  func signInWithGoogle() {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
      self.status = "Missing Google Client ID."
      return
    }

    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

    guard let rootVC = Self.topViewController() else {
      self.status = "Unable to present Google sign-in."
      return
    }

    isLoading = true

    GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
      guard let self = self else { return }

      if let error = error {
        self.status = "Google sign-in failed: \(error.localizedDescription)"
        self.isLoading = false
        return
      }

      guard
        let user = result?.user,
        let idToken = user.idToken?.tokenString
      else {
        self.status = "Google sign-in failed: missing token."
        self.isLoading = false
        return
      }

      let credential = GoogleAuthProvider.credential(
        withIDToken: idToken,
        accessToken: user.accessToken.tokenString
      )

      Task {
        do {
          let authResult = try await Auth.auth().signIn(with: credential)
          self.user = authResult.user
          self.status = "Signed in with Google as \(authResult.user.email ?? "user")"
        } catch {
          self.status = "Firebase sign-in failed: \(error.localizedDescription)"
        }
        self.isLoading = false
      }
    }
  }

  // MARK: - Sign in with Apple

  func startSignInWithApple() {
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
}

// MARK: - Apple Delegates

extension AuthViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    // best effort; falls back to a new window if needed
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: { $0.isKeyWindow }) ?? UIWindow()
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      self.status = "Apple sign-in failed: no credential."
      return
    }

    guard let nonce = currentNonce else {
      self.status = "Invalid state: missing nonce."
      return
    }

    guard let appleTokenData = appleIDCredential.identityToken,
          let idTokenString = String(data: appleTokenData, encoding: .utf8) else {
      self.status = "Unable to fetch Apple identity token."
      return
    }

    let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                              idToken: idTokenString,
                                              rawNonce: nonce)

    Task {
      do {
        let result = try await Auth.auth().signIn(with: credential)
        self.user = result.user
        self.status = "Signed in with Apple as \(result.user.email ?? "user")"
      } catch {
        self.status = "Apple sign-in failed: \(error.localizedDescription)"
      }
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    self.status = "Apple sign-in failed: \(error.localizedDescription)"
  }
}

// MARK: - Helpers

private extension AuthViewModel {
  static func topViewController(base: UIViewController? = {
    // try keyWindow, then root
    if let key = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })?.rootViewController {
      return key
    }
    return UIApplication.shared.windows.first?.rootViewController
  }()) -> UIViewController? {
    if let nav = base as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }
    if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(base: selected)
    }
    if let presented = base?.presentedViewController {
      return topViewController(base: presented)
    }
    return base
  }

  // Crypto-safe nonce for Apple Sign-In
  func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
      Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
      let randoms: [UInt8] = (0 ..< 16).map { _ in
        var rng: UInt8 = 0
        let status = SecRandomCopyBytes(kSecRandomDefault, 1, &rng)
        if status != errSecSuccess { fatalError("Unable to generate nonce. SecRandomCopyBytes failed.") }
        return rng
      }

      randoms.forEach { random in
        if remainingLength == 0 { return }
        if random < charset.count {
          result.append(charset[Int(random)])
          remainingLength -= 1
        }
      }
    }

    return result
  }

  func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
  }
}
