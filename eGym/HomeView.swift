import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
  @EnvironmentObject var auth: AuthViewModel
  @StateObject private var vm = HomeVM()

  private var displayName: String {
    let u = auth.user
    return u?.displayName ?? u?.email ?? "friend"
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
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

        // Today card (from HomeVM)
        Group {
          if vm.loading {
            ProgressView().padding()
          } else if let day = vm.today, let plan = vm.plan {
            TodayCard(day: day, planName: plan.name)
          } else if vm.error != nil {
            ErrorCard(text: vm.error ?? "Something went wrong")
          } else {
            EmptyCard()
          }
        }
        .padding(.horizontal, 24)

        // 🔽 Current plan / generate plan button
        if let plan = vm.plan {
          // If a plan exists, let them view it
          NavigationLink {
            WeeklyPlanView(plan: plan)
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "calendar")
              Text("View current plan")
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .tint(Palette.accentPrimary)
          .padding(.horizontal, 24)
        } else if let uid = auth.user?.uid {
          // If no plan yet, let them generate one
          Button {
            Task { await vm.generatePlan(uid: uid) }
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "wand.and.stars")
              Text(vm.loading ? "Generating plan..." : "Generate my weekly plan")
                .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .tint(Palette.accentPrimary)
          .padding(.horizontal, 24)
          .disabled(vm.loading)
        }
        
        StrengthRatingCard()
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
      .onAppear {
        if let uid = auth.user?.uid { vm.load(uid: uid) }
      }
    }
    .egymBackground()
  }
}

// MARK: - Supporting Cards for Home

private struct TodayCard: View {
  let day: DayPlan
  let planName: String

  var body: some View {
    NavigationLink {
      SessionView(day: day, planName: planName)
    } label: {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Color.white.opacity(0.9))
        .overlay(
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .frame(maxWidth: .infinity)
        .frame(height: 100) // ↓ was 140; feels much tighter
        .overlay(
          HStack(spacing: 12) {
            // left rail (day + minutes)
            VStack(alignment: .leading, spacing: 4) {
              Text("Today • \(day.day)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Palette.textPrimary)

              Text(day.target_focus)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)

              if day.day_type == "rest" {
                Text(day.notes ?? "Rest day.")
                  .font(.caption2)
                  .foregroundColor(.secondary)
                  .lineLimit(1)
              } else if let ex = day.exercises?.first {
                // show only first exercise inline
                Text("\(ex.name): \(ex.sets)×\(ex.reps_or_time)")
                  .font(.caption2)
                  .foregroundColor(.secondary)
                  .lineLimit(1)
                  .truncationMode(.tail)
              }
            }

            Spacer(minLength: 8)

            // right tag (minutes)
            Text("\(day.estimated_minutes) min")
              .font(.caption.weight(.semibold))
              .padding(.horizontal, 10)
              .padding(.vertical, 6)
              .background(Color.gray.opacity(0.12))
              .clipShape(Capsule())
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 14)
        )
    }
    .buttonStyle(.plain)
  }
}

private struct ErrorCard: View {
  let text: String
  var body: some View {
    RoundedRectangle(cornerRadius: 16)
      .fill(Color.red.opacity(0.09))
      .overlay(
        Text(text)
          .font(.subheadline)
          .foregroundColor(.red)
          .padding()
      )
      .frame(maxWidth: .infinity, minHeight: 100)
  }
}

private struct EmptyCard: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 16)
      .fill(Color.white.opacity(0.72))
      .overlay(
        VStack(spacing: 6) {
          Text("No active plan")
            .font(.headline)
            .foregroundColor(Palette.textPrimary)
          Text("Create or activate a plan to get started")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      )
      .frame(maxWidth: .infinity, minHeight: 120)
  }
}


#Preview {
  HomeView()
    .environmentObject(AuthViewModel())
}
