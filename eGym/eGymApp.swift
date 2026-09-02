import SwiftUI
import FirebaseCore

@main
struct eGymApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject private var auth = AuthViewModel()
    @StateObject private var homeVM = HomeVM()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(auth)
        .environmentObject(homeVM)
        .onOpenURL { url in
          auth.handleOpenURL(url)   // for Google + email-link flows
        }
    }
  }
}
