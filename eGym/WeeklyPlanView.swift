import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct WeeklyPlanView: View {
  let plan: WorkoutPlan

  // Editable name state
  @State private var editableName: String
  @State private var isEditingName = false
  @FocusState private var nameFieldFocused: Bool

  private let dayOrder: [String] = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
  private var days: [DayPlan] {
    plan.week.sorted { (a, b) in
      (dayOrder.firstIndex(of: a.day) ?? 0) < (dayOrder.firstIndex(of: b.day) ?? 0)
    }
  }

  init(plan: WorkoutPlan) {
    self.plan = plan
    _editableName = State(initialValue: plan.name)   // WorkoutPlan.name is non-optional
  }

  var body: some View {
    ZStack {
      // Gradient background same as Home
      Color.clear.egymBackground()
        .ignoresSafeArea()

      List {
        // Header
        Section {
          VStack(alignment: .leading, spacing: 6) {

            HStack(spacing: 8) {
              if isEditingName {
                TextField("Plan name", text: $editableName)
                  .font(.headline)
                  .focused($nameFieldFocused)
                  .submitLabel(.done)
                  .onSubmit { finishEditing() }
              } else {
                Text(editableName)
                  .font(.headline)
                  .onTapGesture { startEditing() }
              }

              Button {
                isEditingName ? finishEditing() : startEditing()
              } label: {
                Image(systemName: "pencil")
                  .imageScale(.small)
                  .foregroundColor(.black)   // black edit icon
              }
              .buttonStyle(.plain)
            }

            Text("\(plan.profile.goal.capitalized) • \(plan.profile.skillLevel.capitalized) • \(plan.profile.timePerDayMinutes) min/day")
              .font(.footnote)
              .foregroundColor(.secondary)

            HStack(spacing: 6) {
              ForEach(plan.profile.equipment.prefix(4), id: \.self) { eq in
                Text(eq.replacingOccurrences(of: "-", with: " "))
                  .font(.caption2)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(Color.gray.opacity(0.12))
                  .clipShape(Capsule())
              }
              if plan.profile.equipment.count > 4 {
                Text("+\(plan.profile.equipment.count - 4)")
                  .font(.caption2)
                  .foregroundColor(.secondary)
              }
            }
          }
          .padding(.vertical, 4)
        }

        // Days (tap to open SessionView)
        ForEach(days) { day in
          Section {
            NavigationLink {
              // Use updated name
              SessionView(day: day, planName: editableName)
            } label: {
              DayRow(day: day)
            }
          } header: {
            HStack {
              Text("\(day.day) • \(day.target_focus ?? "Workout")")
              Spacer()
              Text("\(day.estimated_minutes ?? 30) min")
                .foregroundColor(.secondary)
            }
          }
        }
      }
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)  // let gradient show behind the list
    }
    .navigationTitle("Current Plan")
  }

  // MARK: - Editing helpers

  private func startEditing() {
    isEditingName = true
    DispatchQueue.main.async {
      nameFieldFocused = true
    }
  }

  private func finishEditing() {
    let trimmed = editableName.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.isEmpty {
      // Revert if user clears text
      editableName = plan.name
    } else {
      editableName = trimmed
      updatePlanNameInFirestore()
    }

    isEditingName = false
    nameFieldFocused = false
  }

  private func updatePlanNameInFirestore() {
    let originalName = plan.name ?? ""
    guard editableName != originalName else { return }
    guard let uid = Auth.auth().currentUser?.uid else {
        print("❌ No authenticated user – cannot update plan name")
        return
    }
    // 🔴 Unwrap the optional id
    guard let planId = plan.id else {
        print("❌ WorkoutPlan has no id – cannot update plan name")
        return
    }

    let db = Firestore.firestore()
    db.collection("users")
      .document(uid)
      .collection("workoutPlans")
      .document(planId)                // use unwrapped id
      .updateData(["name": editableName]) { error in
          if let error = error {
              print("❌ Failed to update plan name: \(error)")
          } else {
              print("✅ Plan name updated to \(editableName)")
          }
      }
  }
}

// MARK: - Rows

private struct DayRow: View {
  let day: DayPlan

  var body: some View {
    if day.day_type == "rest" {
      Text(day.notes ?? "Rest day.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(.vertical, 2)
    } else {
      VStack(alignment: .leading, spacing: 10) {
        if let w = day.warmup, !w.drills.isEmpty {
          VStack(alignment: .leading, spacing: 6) {
            Text("Warm-up • \(w.minutes) min")
              .font(.subheadline)
              .bold()
            ForEach(w.drills.indices, id: \.self) { i in
              let d = w.drills[i]
              Text("• \(d.name): \(d.details)")
                .font(.footnote)
                .foregroundColor(.secondary)
            }
          }
        }

        if let ex = day.exercises, !ex.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("Exercises")
              .font(.subheadline)
              .bold()
            ForEach(ex) { e in
              VStack(alignment: .leading, spacing: 2) {
                Text(e.name)
                  .font(.subheadline)
                Text("\(e.sets) × \(e.reps_or_time) • \(e.modality.capitalized)")
                  .font(.footnote)
                  .foregroundColor(.secondary)
                Text("Intensity: \(e.intensity) • Tempo: \(e.tempo)")
                  .font(.footnote)
                  .foregroundColor(.secondary)
              }
              .padding(.vertical, 3)
            }
          }
        }

        if let c = day.cooldown, !c.drills.isEmpty {
          VStack(alignment: .leading, spacing: 6) {
            Text("Cooldown • \(c.minutes) min")
              .font(.subheadline)
              .bold()
            ForEach(c.drills.indices, id: \.self) { i in
              let d = c.drills[i]
              Text("• \(d.name): \(d.details)")
                .font(.footnote)
                .foregroundColor(.secondary)
            }
          }
        }

        if let notes = day.notes, !notes.isEmpty {
          VStack(alignment: .leading, spacing: 4) {
            Text("Notes")
              .font(.subheadline)
              .bold()
            Text(notes)
              .font(.footnote)
              .foregroundColor(.secondary)
          }
        }
      }
      .padding(.vertical, 2)
    }
  }
}
