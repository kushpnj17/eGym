import SwiftUI

@main
struct eGymApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject private var auth = AuthViewModel()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(auth)   // keep this
        .onOpenURL { url in auth.handleOpenURL(url) }
    }
  }
}
