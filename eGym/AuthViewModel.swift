import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit
import FirebaseFirestore
import os

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
  @Published var user: User?
  @Published var status: String = ""
  @Published var profile: UserProfile?

  private let profileService = ProfileService()
  private let logger = Logger(subsystem: "com.egym.app", category: "auth")

  override init() {
    super.init()
    self.user = Auth.auth().currentUser
    logger.info("AuthViewModel init. currentUser: \(self.user?.uid ?? "nil", privacy: .public)")
    status = self.user != nil ? "Restored session" : "Signed out"

    _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      guard let self else { return }
      Task { @MainActor in
        self.user = user
        if let uid = user?.uid {
          self.logger.info("Auth state change → signed in as \(uid, privacy: .public)")
          self.status = "Signed in (state listener)"
          do {
            self.logger.info("Loading profile for uid \(uid, privacy: .public)")
            self.profile = try await self.profileService.getOrCreate(uid: uid)
            self.logger.info("Profile loaded. onboardingCompleted=\(self.profile?.onboardingCompleted ?? false, privacy: .public)")
          } catch {
            self.logger.error("Profile load error: \(error.localizedDescription, privacy: .public)")
            self.status = "Profile load error: \(error.localizedDescription)"
          }
        } else {
          self.logger.info("Auth state change → signed OUT")
          self.profile = nil
          self.status = "Signed out"
        }
      }
    }
  }

  // MARK: Google Sign-In
    func signInWithGoogle() {
      logger.info("signInWithGoogle tapped")

      guard let presenter = Self.topViewController() else {
        Task { @MainActor in self.status = "Google: no presenter VC" }
        logger.error("No presenter VC")
        return
      }

      let gidClient = GIDSignIn.sharedInstance.configuration?.clientID ?? "nil"
      let fbClient  = FirebaseApp.app()?.options.clientID ?? "nil"
      logger.info("GID=\(gidClient, privacy: .public) | FB=\(fbClient, privacy: .public)")

      GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { [weak self] result, error in
        guard let self = self else { return }

        if let error = error as NSError? {
          Task { @MainActor in
            self.status = (error.domain == kGIDSignInErrorDomain &&
                           error.code == GIDSignInError.canceled.rawValue)
                          ? "Google: cancelled"
                          : "Google error: \(error.localizedDescription)"
          }
          self.logger.error("Google sign-in error: \(error.localizedDescription, privacy: .public)")
          return
        }

        guard
          let gidUser = result?.user,
          let idToken = gidUser.idToken?.tokenString
        else {
          Task { @MainActor in self.status = "Google: missing tokens" }
          self.logger.error("Missing Google tokens")
          return
        }

        let credential = GoogleAuthProvider.credential(
          withIDToken: idToken,
          accessToken: gidUser.accessToken.tokenString
        )

        Task {
          do {
            let authRes = try await Auth.auth().signIn(with: credential)
            await MainActor.run {
              self.user = authRes.user
              self.status = "Signed in as \(authRes.user.email ?? authRes.user.uid)"
            }
            self.logger.info("Firebase signIn success uid \(authRes.user.uid, privacy: .public)")
            // profile loads via state listener
          } catch {
            let e = error as NSError
            await MainActor.run { self.status = "Firebase Google error: \(e.code)" }
            self.logger.error("Firebase signIn error \(e.code, privacy: .public) \(e.localizedDescription, privacy: .public)")
          }
        }
      }
    }

  func handleOpenURL(_ url: URL) {
    logger.info("handleOpenURL: \(url.absoluteString, privacy: .public)")
    _ = GIDSignIn.sharedInstance.handle(url)
  }

  func signOut() {
    do {
      try Auth.auth().signOut()
      self.user = nil
      self.profile = nil
      self.status = "Signed out"
      logger.info("Manual sign out complete")
    } catch {
      self.status = "Sign out error: \(error.localizedDescription)"
      logger.error("Sign out error: \(error.localizedDescription, privacy: .public)")
    }
  }

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
