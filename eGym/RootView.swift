import SwiftUI

struct RootView: View {
  @EnvironmentObject var auth: AuthViewModel
  @State private var showOnboarding = true

  var body: some View {
    if auth.user == nil {
      LoginView()
    } else {
      NavigationStack {
        if showOnboarding {
          ExerciseInterestsView()
        } else {
          HomeView()
        }
      }
    }
  }
}
