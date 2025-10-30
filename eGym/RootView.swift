// RootView.swift
import SwiftUI

struct RootView: View {
  @EnvironmentObject var auth: AuthViewModel
  @State private var showOnboarding = true

  var body: some View {
    if auth.user == nil {
      LaunchAuthView()
    } else {
      NavigationStack {
        if showOnboarding {
          QuestionnaireView(onFinished: {      // <-- no `auth:` here
            showOnboarding = false                 // go to Home after save/skip
          })
          .navigationBarBackButtonHidden(true)
        } else {
          HomeView()
        }
      }
    }
  }
}

#Preview {
    RootView().environmentObject(AuthViewModel())
}
