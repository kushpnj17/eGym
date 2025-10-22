import Foundation
import FirebaseAuth
import GoogleSignIn
import UIKit

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
  @Published var user: User?
  @Published var status: String = ""

  override init() {
    super.init()
    self.user = Auth.auth().currentUser
    _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.user = user
    }
  }

  // Google
  func signInWithGoogle() {
    guard let rootVC = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })?.rootViewController else {
      status = "Google: no root VC"
      return
    }

    GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
      guard let self = self else { return }
      if let error = error { self.status = "Google error: \(error.localizedDescription)"; return }

      guard let idToken = result?.user.idToken?.tokenString,
            let accessToken = result?.user.accessToken.tokenString else {
        self.status = "Google: missing tokens"
        return
      }

      let cred = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
      Task {
        do {
          let authRes = try await Auth.auth().signIn(with: cred)
          self.user = authRes.user
          self.status = "Signed in with Google as \(authRes.user.email ?? "")"
        } catch {
          self.status = "Firebase Google error: \(error.localizedDescription)"
        }
      }
    }
  }

  // Optional: handle Google callback (safe to keep)
  func handleOpenURL(_ url: URL) {
    _ = GIDSignIn.sharedInstance.handle(url)
  }

  func signOut() {
    do { try Auth.auth().signOut(); user = nil; status = "Signed out" }
    catch { status = "Sign out error: \(error.localizedDescription)" }
  }
}
