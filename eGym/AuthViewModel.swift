import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import UIKit

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
  // MARK: - Published state
  @Published var user: FirebaseAuth.User?
  @Published var status: String = ""
  @Published var isLoading: Bool = false

  // MARK: - Init
  override init() {
    super.init()
    // Keep SwiftUI in sync with Firebase auth state
    Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.user = user
    }
  }

  // MARK: - Google Sign-In
  func signInWithGoogle() {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
      self.status = "Missing Google Client ID."
      return
    }
    // Configure Google Sign-In with your Firebase client ID
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
        let gUser = result?.user,
        let idToken = gUser.idToken?.tokenString
      else {
        self.status = "Google sign-in failed: missing token."
        self.isLoading = false
        return
      }

      let credential = GoogleAuthProvider.credential(
        withIDToken: idToken,
        accessToken: gUser.accessToken.tokenString
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

  // MARK: - Sign Out
  func signOut() {
    do {
      try Auth.auth().signOut()
      self.user = nil
      self.status = "Signed out."
    } catch {
      self.status = "Sign out failed: \(error.localizedDescription)"
    }
  }
}

// MARK: - Helpers
private extension AuthViewModel {
  static func topViewController(base: UIViewController? = {
    if let keyRoot = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })?.rootViewController {
      return keyRoot
    }
    return UIApplication.shared.windows.first?.rootViewController
  }()) -> UIViewController? {
    if let nav = base as? UINavigationController { return topViewController(base: nav.visibleViewController) }
    if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(base: selected)
    }
    if let presented = base?.presentedViewController { return topViewController(base: presented) }
    return base
  }
}
