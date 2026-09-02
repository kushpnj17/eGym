//
//  NotificationSettingsVM.swift
//  eGym
//
//  Created by Kush Patel on 12/5/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class NotificationSettingsVM: ObservableObject {
  @Published var notificationsEnabled: Bool = true
  @Published var workoutRemindersEnabled: Bool = true
  @Published var reminderTime: Date = Calendar.current.date(
    bySettingHour: 18,
    minute: 0,
    second: 0,
    of: Date()
  ) ?? Date()
  @Published var reminderDays: Set<String> = ["Mon", "Tue", "Wed", "Thu", "Fri"]
  @Published var progressSummaryFrequency: String = "weekly" // "none", "daily", "weekly"

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
    guard let uid = uid else { return }
    isLoading = true
    errorMessage = nil

    db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
      guard let self = self else { return }
      self.isLoading = false

      if let error = error {
        self.errorMessage = "Failed to load notification settings: \(error.localizedDescription)"
        return
      }

      guard let data = snapshot?.data(),
            let notif = data["notificationSettings"] as? [String: Any] else {
        // No settings yet; keep defaults
        return
      }

      if let enabled = notif["notificationsEnabled"] as? Bool {
        self.notificationsEnabled = enabled
      }
      if let workoutEnabled = notif["workoutRemindersEnabled"] as? Bool {
        self.workoutRemindersEnabled = workoutEnabled
      }
      if let timeString = notif["reminderTime"] as? String,
         let date = Self.date(fromTimeString: timeString) {
        self.reminderTime = date
      }
      if let days = notif["reminderDays"] as? [String] {
        self.reminderDays = Set(days)
      }
      if let freq = notif["progressSummaryFrequency"] as? String {
        self.progressSummaryFrequency = freq
      }
    }
  }

  func saveSettings() {
    guard let uid = uid else { return }
    isSaving = true
    errorMessage = nil

    let timeString = Self.timeString(from: reminderTime)
    let daysArray = Array(reminderDays).sorted()

    let notif: [String: Any] = [
      "notificationsEnabled": notificationsEnabled,
      "workoutRemindersEnabled": workoutRemindersEnabled,
      "reminderTime": timeString,
      "reminderDays": daysArray,
      "progressSummaryFrequency": progressSummaryFrequency
    ]

    db.collection("users").document(uid)
      .setData(["notificationSettings": notif], merge: true) { [weak self] error in
        guard let self = self else { return }
        self.isSaving = false

        if let error = error {
          self.errorMessage = "Failed to save notification settings: \(error.localizedDescription)"
        }
      }
  }

  // MARK: - Time helpers

  private static func timeString(from date: Date) -> String {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    let hour = comps.hour ?? 0
    let minute = comps.minute ?? 0
    // "HH:mm"
    return String(format: "%02d:%02d", hour, minute)
  }

  private static func date(fromTimeString string: String) -> Date? {
    let parts = string.split(separator: ":")
    guard parts.count == 2,
          let hour = Int(parts[0]),
          let minute = Int(parts[1]) else {
      return nil
    }

    var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    comps.hour = hour
    comps.minute = minute
    comps.second = 0
    return Calendar.current.date(from: comps)
  }
}

struct NotificationSettingsView: View {
  @EnvironmentObject var auth: AuthViewModel
  @StateObject private var vm = NotificationSettingsVM()

  private let weekdayShort = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

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

          // Global toggle
          Toggle("Enable Notifications", isOn: $vm.notificationsEnabled)
            .tint(Palette.accentPrimary)

          // Workout reminders
          VStack(alignment: .leading, spacing: 12) {
            Toggle("Workout Reminders", isOn: $vm.workoutRemindersEnabled)
              .tint(Palette.accentPrimary)
              .disabled(!vm.notificationsEnabled)
              .opacity(vm.notificationsEnabled ? 1.0 : 0.4)

            if vm.notificationsEnabled && vm.workoutRemindersEnabled {
              VStack(alignment: .leading, spacing: 8) {
                Text("Reminder Time")
                  .font(.subheadline.weight(.semibold))
                  .foregroundColor(Palette.textPrimary)

                DatePicker(
                  "Reminder Time",
                  selection: $vm.reminderTime,
                  displayedComponents: .hourAndMinute
                )
                .labelsHidden()

                Text("Reminder Days")
                  .font(.subheadline.weight(.semibold))
                  .foregroundColor(Palette.textPrimary)
                  .padding(.top, 4)

                WrapDaysView(
                  days: weekdayShort,
                  selectedDays: $vm.reminderDays
                )
              }
            }
          }

          // Progress summary
          VStack(alignment: .leading, spacing: 8) {
            Text("Progress Summary")
              .font(.subheadline.weight(.semibold))
              .foregroundColor(Palette.textPrimary)

            Picker("Progress Summary", selection: $vm.progressSummaryFrequency) {
              Text("Off").tag("none")
              Text("Daily").tag("daily")
              Text("Weekly").tag("weekly")
            }
            .pickerStyle(.segmented)
          }

          Spacer(minLength: 12)
        }
        .padding(24)
      }

      // Bottom action bar
      VStack {
        Button {
          vm.saveSettings()
        } label: {
          HStack {
            if vm.isSaving {
              ProgressView()
                .scaleEffect(0.8)
            }
            Text(vm.isSaving ? "Saving…" : "Save Settings")
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
    .navigationTitle("Notification Settings")
    .navigationBarTitleDisplayMode(.inline)
    .background(Palette.bg.ignoresSafeArea())
    .onAppear {
      if let user = auth.user {
        vm.configure(with: user)
      }
    }
  }
}

// A small helper view to render day "chips" for reminderDays
private struct WrapDaysView: View {
  let days: [String]
  @Binding var selectedDays: Set<String>

  var body: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
      alignment: .leading,
      spacing: 8
    ) {
      ForEach(days, id: \.self) { day in
        let isSelected = selectedDays.contains(day)
        Button {
          if isSelected {
            selectedDays.remove(day)
          } else {
            selectedDays.insert(day)
          }
        } label: {
          Text(day)
            .font(.caption.weight(.semibold))
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Palette.accentPrimary : Color.white.opacity(0.95))
            )
            .foregroundColor(isSelected ? .white : Palette.textPrimary)
            .shadow(
              color: Color.black.opacity(isSelected ? 0.1 : 0.03),
              radius: isSelected ? 4 : 2, x: 0, y: 2
            )
        }
        .buttonStyle(.plain)
      }
    }
  }
}

#Preview {
  NavigationStack {
    NotificationSettingsView()
      .environmentObject(AuthViewModel())
  }
}
