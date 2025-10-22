import SwiftUI

struct RootView: View {
  @EnvironmentObject var auth: AuthViewModel

  var body: some View {
    if auth.user == nil {
      LoginView()
    } else {
      ExerciseInterestsView()  // your existing screen
    }
  }
}
