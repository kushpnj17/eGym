import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }

  // Email link & Google callback URLs
  func application(_ app: UIApplication, open url: URL,
                   options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Email-link sign-in uses FirebaseAuth to check links; Google uses GIDSignIn
    // We’ll handle both in the SwiftUI App via onOpenURL as well, but having this is good for safety.
    return false
  }
}
