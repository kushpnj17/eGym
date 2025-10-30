// RootView.swift
import SwiftUI

struct RootView: View {
  @EnvironmentObject var auth: AuthViewModel

  var body: some View {
    Group {
      // Not signed in → show launch/auth
      if auth.user == nil {
        LaunchAuthView()

      // Signed in and profile loaded
      } else if let profile = auth.profile {
        NavigationStack {
          if profile.onboardingCompleted {
            HomeView()
          } else {
            QuestionnaireView(onFinished: completeOnboarding)
              .navigationBarBackButtonHidden(true)
          }
        }

      // Signed in but still loading profile → quick splash
      } else {
        SplashView()
      }
    }
  }

  private func completeOnboarding() {
    Task {
      guard let uid = auth.user?.uid else { return }
      do {
        try await ProfileService().setOnboardingCompleted(uid: uid, true)
        // reflect immediately in UI
        await MainActor.run {
          auth.profile?.onboardingCompleted = true
          auth.status = "Onboarding complete"
        }
      } catch {
        await MainActor.run {
          auth.status = "Could not save onboarding: \(error.localizedDescription)"
        }
      }
    }
  }
}


#Preview {
  RootView().environmentObject(AuthViewModel())
}
