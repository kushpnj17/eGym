//
//  EditProfileView.swift
//  eGym
//
//  Created by Kush Patel on 12/5/25.
//

import SwiftUI
import FirebaseAuth

// Common gym options for selection
enum GymOption: String, CaseIterable, Identifiable {
  case none = "none"
  case planetFitness = "planet_fitness"
  case laFitness = "la_fitness"
  case crunch = "crunch"
  case anytimeFitness = "anytime_fitness"
  case ymca = "ymca"
  case goldsGym = "golds_gym"
  case orangeTheory = "orange_theory"
  case universityGym = "university_gym"
  case home = "home"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .none: return "No Preference"
    case .planetFitness: return "Planet Fitness"
    case .laFitness: return "LA Fitness"
    case .crunch: return "Crunch Fitness"
    case .anytimeFitness: return "Anytime Fitness"
    case .ymca: return "YMCA"
    case .goldsGym: return "Gold's Gym"
    case .orangeTheory: return "OrangeTheory"
    case .universityGym: return "University/Rec Center"
    case .home: return "Home"
    }
  }
}

struct EditProfileView: View {
  @EnvironmentObject var auth: AuthViewModel
  @StateObject private var vm = EditProfileVM()
  @Environment(\.dismiss) private var dismiss

  private func gymOption(for raw: String) -> GymOption {
    GymOption(rawValue: raw) ?? .none
  }

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(spacing: 20) {

          if vm.isLoading {
            ProgressView("Loading profile…")
              .padding(.top, 16)
          }

          if let error = vm.errorMessage {
            Text(error)
              .font(.footnote)
              .foregroundColor(.red)
          }

          // Name
          groupField(
            title: "Full Name",
            text: $vm.fullName,
            placeholder: "Your name"
          )

          // Email
          groupField(
            title: "Email",
            text: $vm.email,
            placeholder: "you@example.com",
            keyboard: .emailAddress
          )

          // Phone (phone keyboard: digits + phone chars)
          groupField(
            title: "Phone Number",
            text: $vm.phone,
            placeholder: "e.g. +1 555 555 5555",
            keyboard: .phonePad
          )

          // Units preference (Metric vs US)
          VStack(alignment: .leading, spacing: 6) {
            Text("Units")
              .font(.subheadline.weight(.semibold))
              .foregroundColor(Palette.textPrimary)

            Picker("Units", selection: $vm.unitsSystem) {
              Text("Metric").tag("metric")
              Text("US").tag("us")
            }
            .pickerStyle(.segmented)
          }

          // Preferred Gym – styled like the other boxes with key/value layout
          VStack(alignment: .leading, spacing: 6) {
            Text("Preferred Gym")
              .font(.subheadline.weight(.semibold))
              .foregroundColor(Palette.textPrimary)

            Menu {
              ForEach(GymOption.allCases) { option in
                Button(option.displayName) {
                  vm.preferredGym = option.rawValue
                }
              }
            } label: {
              HStack {
                // Left half: key label
                Text("Preferred Gym")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
                  .frame(maxWidth: .infinity, alignment: .leading)

                // Right half: selected value in blue + chevron
                HStack(spacing: 4) {
                  Text(gymOption(for: vm.preferredGym).displayName)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .truncationMode(.tail)

                  Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
              }
              .padding(12)
              .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                  .fill(Color.white.opacity(0.95))
                  .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 2)
              )
            }
            .buttonStyle(.plain)
          }

          // Age – whole number
          groupField(
            title: "Age",
            text: $vm.age,
            placeholder: "21",
            keyboard: .numberPad
          )

          // Height + Weight inputs adapt to units
          if vm.unitsSystem == "metric" {
            HStack(spacing: 12) {
              groupField(
                title: "Height (cm)",
                text: $vm.heightCm,
                placeholder: "170",
                keyboard: .decimalPad
              )

              groupField(
                title: "Weight (kg)",
                text: $vm.weightKg,
                placeholder: "65",
                keyboard: .decimalPad
              )
            }
          } else {
            VStack(spacing: 12) {
              HStack(spacing: 12) {
                groupField(
                  title: "Height (ft)",
                  text: $vm.heightFeet,
                  placeholder: "5",
                  keyboard: .numberPad
                )

                groupField(
                  title: "Height (in)",
                  text: $vm.heightInches,
                  placeholder: "10",
                  keyboard: .numberPad
                )
              }

              groupField(
                title: "Weight (lb)",
                text: $vm.weightLbs,
                placeholder: "150",
                keyboard: .decimalPad
              )
            }
          }

          Spacer(minLength: 12)
        }
        .padding(24)
      }

      // Bottom action bar
      VStack {
        Button {
          vm.saveProfile()
        } label: {
          HStack {
            if vm.isSaving {
              ProgressView()
                .scaleEffect(0.8)
            }
            Text(vm.isSaving ? "Saving…" : "Save Changes")
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
    .navigationTitle("Edit Profile")
    .navigationBarTitleDisplayMode(.inline)
    .background(Palette.bg.ignoresSafeArea())
    .onAppear {
      if let user = auth.user {
        vm.configure(with: user)
      }
    }
  }

  // MARK: - Field helper

  private func groupField(
    title: String,
    text: Binding<String>,
    placeholder: String,
    keyboard: UIKeyboardType = .default
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.subheadline.weight(.semibold))
        .foregroundColor(Palette.textPrimary)

      TextField(placeholder, text: text)
        .keyboardType(keyboard)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .padding(12)
        .background(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.95))
            .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 2)
        )
    }
  }
}

#Preview {
  NavigationStack {
    EditProfileView()
      .environmentObject(AuthViewModel())
  }
}
