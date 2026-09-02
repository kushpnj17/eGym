//
//  ConnectedAppsView.swift
//  eGym
//
//  Created by Kush Patel on 12/5/25.
//

import SwiftUI

struct ConnectedAppsView: View {
  var body: some View {
    VStack(spacing: 20) {
      Text("Connected Apps")
        .font(.largeTitle).bold()
        .foregroundColor(Palette.textPrimary)
        .padding(.top, 16)

      Text("Support for wearable integrations is coming soon.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      VStack(spacing: 12) {
        appRow(name: "Apple Watch")
        appRow(name: "Fitbit")
        appRow(name: "WHOOP")
        appRow(name: "Garmin")
      }
      .padding(.horizontal, 24)

      Spacer()
    }
    .background(Palette.bg.ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
  }

  private func appRow(name: String) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(name)
          .font(.headline)
          .foregroundColor(Palette.textPrimary)

        Text("Coming soon")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }

      Spacer()

      Image(systemName: "icloud")
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
    ConnectedAppsView()
  }
}

