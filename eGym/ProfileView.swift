// ProfileView.swift
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
  @EnvironmentObject var auth: AuthViewModel

  // Still here in case you want to react in Home later (e.g., reload plan)
  @Binding var didFinishQuestionnaire: Bool

  private var displayName: String {
    let u = auth.user
    return u?.displayName ?? u?.email ?? "friend"
  }

  var body: some View {
    VStack(spacing: 24) {
      // Header similar to Home
      VStack(spacing: 8) {
        Text("Your profile, \(displayName)")
          .font(.largeTitle).bold()
          .foregroundColor(Palette.textPrimary)
          .multilineTextAlignment(.center)

        Text("Manage your preferences and account.")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .padding(.horizontal, 24)
      .padding(.top, 8)

      // Menu: Set Preferences
      VStack(spacing: 12) {
        NavigationLink {
          QuestionnaireView {
            // Called AFTER saving in QuestionnaireView.
            // We no longer dismiss Profile here; QuestionnaireView pops
            // back to Profile, and we just mark that preferences changed.
            didFinishQuestionnaire = true
          }
        } label: {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Set Preferences")
                .font(.headline)
                .foregroundColor(Palette.textPrimary)

              Text("Update your fitness goals and setup questionnaire.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.secondary)
          }
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(Color.white.opacity(0.9))
              .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
          )
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 24)

      Spacer()
    }
    .navigationBarTitleDisplayMode(.inline)
    .background(Palette.bg.ignoresSafeArea())
    .tint(Palette.accentPrimary)
  }
}

#Preview {
  NavigationStack {
    ProfileView(didFinishQuestionnaire: .constant(false))
      .environmentObject(AuthViewModel())
  }
}
