//
//  HomeView.swift
//  eGym
//
//  Created by Kush Patel on 10/22/25.
//
import SwiftUI
import FirebaseAuth

struct HomeView: View {
  @EnvironmentObject var auth: AuthViewModel

  private var displayName: String {
    let u = auth.user
    return u?.displayName ?? u?.email ?? "friend"
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        // Header
        VStack(spacing: 8) {
          Text("Welcome back, \(displayName) 👋")
            .font(.largeTitle).bold()
            .foregroundColor(Palette.textPrimary)
            .multilineTextAlignment(.center)

          Text("What should we work on today?")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)

        // Primary action area (placeholder card)
        VStack(spacing: 12) {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.72))
            .overlay(
              RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
            .frame(maxWidth: .infinity, minHeight: 120)
            .overlay(
              VStack(spacing: 6) {
                Text("Today’s Plan")
                  .font(.headline)
                  .foregroundColor(Palette.textPrimary)
                Text("Tap to start your session")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }
            )
        }
        .padding(.horizontal, 24)

        Spacer(minLength: 16)

        // Sign out
        Button {
          auth.signOut()
        } label: {
          Text("Sign out")
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Palette.accentPrimary)
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
      }
      .navigationBarTitleDisplayMode(.inline)
    }
    .egymBackground() // uses Backgrounds.swift
  }
}

#Preview {
  HomeView()
    .environmentObject(AuthViewModel()) // Ensure this exists in your project
}
