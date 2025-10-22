import UIKit
import FirebaseCore
import GoogleSignIn   // ← add

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()

    // ✅ Make sure GoogleSignIn has a clientID
    if let clientID = FirebaseApp.app()?.options.clientID {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    } else {
      print("❌ Missing Firebase clientID; check GoogleService-Info.plist target membership.")
    }

    return true
  }
}
