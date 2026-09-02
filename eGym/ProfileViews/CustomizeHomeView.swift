//
//  CustomizeHomeVM.swift
//  eGym
//
//  Created by Kush Patel on 12/5/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class CustomizeHomeVM: ObservableObject {
  @Published var showWeightJourney: Bool = true
  @Published var showConsistencyGrid: Bool = true
  @Published var showWeeklyOverview: Bool = true
  @Published var showNextWorkoutPreview: Bool = true
  @Published var showStrengthRatingCard: Bool = true

  @Published var isLoading: Bool = false
  @Published var isSaving: Bool = false
  @Published var errorMessage: String?

  private let db = Firestore.firestore()
  private var uid: String?

  func configure(with user: User) {
    uid = user.uid
    loadSettings()
  }

  private func loadSettings() {
    guard let uid else { return }
    isLoading = true
    errorMessage = nil

    db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
      guard let self = self else { return }
      self.isLoading = false

      if let error = error {
        self.errorMessage = "Failed to load home settings: \(error.localizedDescription)"
        return
      }

      guard let data = snapshot?.data(),
            let home = data["homeCustomization"] as? [String: Any] else {
        // No customization yet; keep defaults
        return
      }

      if let v = home["showWeightJourney"] as? Bool {
        self.showWeightJourney = v
      }
      if let v = home["showConsistencyGrid"] as? Bool {
        self.showConsistencyGrid = v
      }
      if let v = home["showWeeklyOverview"] as? Bool {
        self.showWeeklyOverview = v
      }
      if let v = home["showNextWorkoutPreview"] as? Bool {
        self.showNextWorkoutPreview = v
      }
      if let v = home["showStrengthRatingCard"] as? Bool {
        self.showStrengthRatingCard = v
      }
    }
  }

  func saveSettings() {
    guard let uid else { return }
    isSaving = true
    errorMessage = nil

    let home: [String: Any] = [
      "showWeightJourney": showWeightJourney,
      "showConsistencyGrid": showConsistencyGrid,
      "showWeeklyOverview": showWeeklyOverview,
      "showNextWorkoutPreview": showNextWorkoutPreview,
      "showStrengthRatingCard": showStrengthRatingCard
    ]

    db.collection("users").document(uid)
      .setData(["homeCustomization": home], merge: true) { [weak self] error in
        guard let self = self else { return }
        self.isSaving = false

        if let error = error {
          self.errorMessage = "Failed to save home settings: \(error.localizedDescription)"
        }
      }
  }
}

struct CustomizeHomeView: View {
  @EnvironmentObject var auth: AuthViewModel
  @StateObject private var vm = CustomizeHomeVM()

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(spacing: 20) {

          if vm.isLoading {
            ProgressView("Loading settings…")
              .padding(.top, 16)
          }

          if let error = vm.errorMessage {
            Text(error)
              .font(.footnote)
              .foregroundColor(.red)
          }

          sectionHeader("Home Cards")

          cardToggleRow(
            title: "Weight Journey",
            subtitle: "Show your weight trend over time on the home screen.",
            isOn: $vm.showWeightJourney
          )

          cardToggleRow(
            title: "Consistency Squares",
            subtitle: "A grid showing how consistently you've checked in.",
            isOn: $vm.showConsistencyGrid
          )

          cardToggleRow(
            title: "Weekly Overview",
            subtitle: "Quick snapshot of this week’s sessions and focus areas.",
            isOn: $vm.showWeeklyOverview
          )

          cardToggleRow(
            title: "Next Workout Preview",
            subtitle: "See your next session at a glance.",
            isOn: $vm.showNextWorkoutPreview
          )

          cardToggleRow(
            title: "Strength Rating Card",
            subtitle: "Keep your strength feedback front and center.",
            isOn: $vm.showStrengthRatingCard
          )

          Spacer(minLength: 12)
        }
        .padding(24)
      }

      // Bottom save bar
      VStack {
        Button {
          vm.saveSettings()
        } label: {
          HStack {
            if vm.isSaving {
              ProgressView()
                .scaleEffect(0.8)
            }
            Text(vm.isSaving ? "Saving…" : "Save Preferences")
              .fontWeight(.semibold)
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Palette.accentPrimary)
          .foregroundColor(.white)
          .cornerRadius(16)
          .shadow(color: Palette.accentPrimary.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .disabled(vm.isSaving)
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
      .background(
        Palette.bg
          .ignoresSafeArea(edges: .bottom)
      )
    }
    .navigationTitle("Customize Home")
    .navigationBarTitleDisplayMode(.inline)
    .background(Palette.bg.ignoresSafeArea())
    .onAppear {
      if let user = auth.user {
        vm.configure(with: user)
      }
    }
  }

  // MARK: - Helpers

  private func sectionHeader(_ text: String) -> some View {
    HStack {
      Text(text)
        .font(.subheadline.weight(.semibold))
        .foregroundColor(.secondary)
      Spacer()
    }
  }

  private func cardToggleRow(
    title: String,
    subtitle: String,
    isOn: Binding<Bool>
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
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
        Toggle("", isOn: isOn)
          .labelsHidden()
          .tint(Palette.accentPrimary)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(Color.white.opacity(0.9))
          .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
      )
    }
  }
}

#Preview {
  NavigationStack {
    CustomizeHomeView()
      .environmentObject(AuthViewModel())
  }
}
