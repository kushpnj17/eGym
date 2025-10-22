//
//  AuthViewModel.swift
//  eGym
//
//  Google-only AuthViewModel (stable).
//  Requirements:
//   - AppDelegate sets GIDSignIn.sharedInstance.configuration using FirebaseApp.app()?.options.clientID
//   - URL Types includes REVERSED_CLIENT_ID from GoogleService-Info.plist
//   - Packages linked to app target: FirebaseCore, FirebaseAuth, GoogleSignIn
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import UIKit

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
  // Firebase user (nil when signed out)
  @Published var user: User?
  // Surface short status/debug messages in UI
  @Published var status: String = ""

  override init() {
    super.init()
    self.user = Auth.auth().currentUser
    // Keep user in sync
    _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.user = user
    }
  }

  // MARK: - Google Sign-In
  func signInWithGoogle() {
    // Find a safe presenter VC (avoids NSException: presentingViewController must be set)
    guard let presenter = Self.topViewController() else {
      status = "Google: no presenter VC"
      return
    }

    // At app launch, AppDelegate should have set:
    // GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID)
    GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { [weak self] result, error in
      guard let self = self else { return }
      if let error = error {
        self.status = "Google error: \(error.localizedDescription)"
        return
      }

      guard
        let idToken = result?.user.idToken?.tokenString,
        let accessToken = result?.user.accessToken.tokenString
      else {
        self.status = "Google: missing tokens"
        return
      }

      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

      Task {
        do {
          let authRes = try await Auth.auth().signIn(with: credential)
          self.user = authRes.user
          self.status = "Signed in with Google as \(authRes.user.email ?? "")"
        } catch {
          self.status = "Firebase Google error: \(error.localizedDescription)"
        }
      }
    }
  }

  // MARK: - URL callback handler (keep this wired in eGymApp.onOpenURL)
  func handleOpenURL(_ url: URL) {
    _ = GIDSignIn.sharedInstance.handle(url)
  }

  // MARK: - Sign out
  func signOut() {
    do {
      try Auth.auth().signOut()
      self.user = nil
      self.status = "Signed out"
    } catch {
      self.status = "Sign out error: \(error.localizedDescription)"
    }
  }

  // MARK: - Presenter helper
  private static func topViewController(
    base: UIViewController? = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: { $0.isKeyWindow })?.rootViewController
  ) -> UIViewController? {
    if let nav = base as? UINavigationController { return topViewController(base: nav.visibleViewController) }
    if let tab = base as? UITabBarController { return topViewController(base: tab.selectedViewController) }
    if let presented = base?.presentedViewController { return topViewController(base: presented) }
    return base
  }
}
