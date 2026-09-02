//
//  ProfileView.swift
//  eGym
//
//  Created by Kush Patel on 12/5/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
  @EnvironmentObject var auth: AuthViewModel
  @Binding var didFinishQuestionnaire: Bool

  private var displayName: String {
    let u = auth.user
    return u?.displayName ?? u?.email ?? "friend"
  }

  var body: some View {
    VStack(spacing: 24) {
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

      VStack(spacing: 12) {
        NavigationLink {
          QuestionnaireView {
            didFinishQuestionnaire = true
          }
        } label: {
          menuRow(
            title: "Set Preferences",
            subtitle: "Update your fitness goals and setup questionnaire."
          )
        }
        .buttonStyle(.plain)

        NavigationLink {
          EditProfileView()
        } label: {
          menuRow(
            title: "Edit Profile",
            subtitle: "Update your name and profile details."
          )
        }
        .buttonStyle(.plain)

        NavigationLink {
          NotificationSettingsView()
        } label: {
          menuRow(
            title: "Notification Settings",
            subtitle: "Choose when and how we notify you."
          )
        }
        .buttonStyle(.plain)

        // NEW: Customize Home Page
        NavigationLink {
          CustomizeHomeView()
        } label: {
          menuRow(
            title: "Customize Home",
            subtitle: "Choose which cards appear on your home screen."
          )
        }
        .buttonStyle(.plain)

        NavigationLink {
          ConnectedAppsView()
        } label: {
          menuRow(
            title: "Connected Apps",
            subtitle: "Manage integrations with other services."
          )
        }
        .buttonStyle(.plain)

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
