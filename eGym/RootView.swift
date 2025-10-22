// RootView.swift
import SwiftUI

struct RootView: View {
  @EnvironmentObject var auth: AuthViewModel

  var body: some View {
    Group {
      if auth.user == nil {
        LoginView()
      } else {
        NavigationStack {
          // Replace with your actual post-login view
          ExerciseInterestsView()
            .navigationTitle("eGym")
            .toolbar {
              ToolbarItem(placement: .topBarTrailing) {
                Menu {
                  Button(role: .destructive) {
                    auth.signOut()
                  } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                  }
                } label: {
                  Image(systemName: "ellipsis.circle")
                }
              }
            }
        }
      }
    }
  }
}
