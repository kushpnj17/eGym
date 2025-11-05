import SwiftUI

struct WeeklyPlanView: View {
  let plan: WorkoutPlan

  private let dayOrder: [String] = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
  private var days: [DayPlan] {
    plan.week.sorted { (a, b) in
      (dayOrder.firstIndex(of: a.day) ?? 0) < (dayOrder.firstIndex(of: b.day) ?? 0)
    }
  }

  var body: some View {
    List {
      // Header
      Section {
        VStack(alignment: .leading, spacing: 6) {
          Text(plan.name).font(.headline)
          Text("\(plan.profile.goal.capitalized) • \(plan.profile.skillLevel.capitalized) • \(plan.profile.timePerDayMinutes) min/day")
            .font(.footnote).foregroundColor(.secondary)
          HStack(spacing: 6) {
            ForEach(plan.profile.equipment.prefix(4), id: \.self) { eq in
              Text(eq.replacingOccurrences(of: "-", with: " "))
                .font(.caption2)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.gray.opacity(0.12))
                .clipShape(Capsule())
            }
            if plan.profile.equipment.count > 4 {
              Text("+\(plan.profile.equipment.count - 4)")
                .font(.caption2).foregroundColor(.secondary)
            }
          }
        }
        .padding(.vertical, 4)
      }

      // Days (tap to open SessionView)
      ForEach(days) { day in
        Section {
          NavigationLink {
            SessionView(day: day, planName: plan.name)
          } label: {
            DayRow(day: day)
          }
        } header: {
          HStack {
            Text("\(day.day) • \(day.target_focus)")
            Spacer()
            Text("\(day.estimated_minutes) min").foregroundColor(.secondary)
          }
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Current Plan")
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
            Text("Warm-up • \(w.minutes) min").font(.subheadline).bold()
            ForEach(w.drills.indices, id: \.self) { i in
              let d = w.drills[i]
              Text("• \(d.name): \(d.details)").font(.footnote).foregroundColor(.secondary)
            }
          }
        }

        if let ex = day.exercises, !ex.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("Exercises").font(.subheadline).bold()
            ForEach(ex) { e in
              VStack(alignment: .leading, spacing: 2) {
                Text(e.name).font(.subheadline)
                Text("\(e.sets) × \(e.reps_or_time) • \(e.modality.capitalized)")
                  .font(.footnote).foregroundColor(.secondary)
                Text("Intensity: \(e.intensity) • Tempo: \(e.tempo)")
                  .font(.footnote).foregroundColor(.secondary)
              }
              .padding(.vertical, 3)
            }
          }
        }

        if let c = day.cooldown, !c.drills.isEmpty {
          VStack(alignment: .leading, spacing: 6) {
            Text("Cooldown • \(c.minutes) min").font(.subheadline).bold()
            ForEach(c.drills.indices, id: \.self) { i in
              let d = c.drills[i]
              Text("• \(d.name): \(d.details)").font(.footnote).foregroundColor(.secondary)
            }
          }
        }

        if let notes = day.notes, !notes.isEmpty {
          VStack(alignment: .leading, spacing: 4) {
            Text("Notes").font(.subheadline).bold()
            Text(notes).font(.footnote).foregroundColor(.secondary)
          }
        }
      }
      .padding(.vertical, 2)
    }
  }
}
