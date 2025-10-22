import SwiftUI

struct RootView: View {
  @EnvironmentObject var auth: AuthViewModel

  var body: some View {
    if auth.user == nil {
      // 👉 Pass the VM in directly
      LoginView(auth: auth)
    } else {
      ExerciseInterestsView()
    }
  }
}
