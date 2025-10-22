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
    VStack(spacing: 20) {
      Text("Greetings, \(displayName), what should we work on today!")
        .font(.title2)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      Button("Sign out") {
        auth.signOut()
      }
      .buttonStyle(.bordered)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
  }
}
