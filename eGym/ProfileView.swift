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

      // Menu
      VStack(spacing: 12) {
        // Preferences
        NavigationLink {
          QuestionnaireView {
            // Called AFTER saving in QuestionnaireView.
            // We no longer dismiss Profile here; QuestionnaireView pops
            // back to Profile, and we just mark that preferences changed.
            didFinishQuestionnaire = true
          }
        } label: {
          menuRow(
            title: "Set Preferences",
            subtitle: "Update your fitness goals and setup questionnaire."
          )
        }
        .buttonStyle(.plain)

        // --- Dummy rows (not wired up yet) ---

        Button {
          // TODO: Edit profile (name, photo, etc.)
        } label: {
          menuRow(
            title: "Edit Profile",
            subtitle: "Update your name and profile details."
          )
        }
        .buttonStyle(.plain)

        Button {
          // TODO: Notification settings
        } label: {
          menuRow(
            title: "Notification Settings",
            subtitle: "Choose when and how we notify you."
          )
        }
        .buttonStyle(.plain)

        Button {
          // TODO: Connected apps / integrations
        } label: {
          menuRow(
            title: "Connected Apps",
            subtitle: "Manage integrations with other services."
          )
        }
        .buttonStyle(.plain)

        // --- Sign Out ---

        Button {
          auth.signOut()
        } label: {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Sign Out")
                .font(.headline)
                .foregroundColor(.red)

              Text("Log out of your eGym account.")
                .font(.subheadline)
                .foregroundColor(.red.opacity(0.8))
            }

            Spacer()

            Image(systemName: "rectangle.portrait.and.arrow.right")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.red.opacity(0.9))
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

  // MARK: - Helpers

  @ViewBuilder
  private func menuRow(title: String, subtitle: String) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
          .foregroundColor(Palette.textPrimary)

        Text(subtitle)
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
}

#Preview {
  NavigationStack {
    ProfileView(didFinishQuestionnaire: .constant(false))
      .environmentObject(AuthViewModel())
  }
}
