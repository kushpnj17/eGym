import FirebaseAuth
import FirebaseFirestore
// HomeView.swift
import SwiftUI

struct HomeView: View {
  @EnvironmentObject var auth: AuthViewModel
  @StateObject private var vm = HomeVM()
  @State private var didFinishQuestionnaire = false  // currently unused hook if you want later

  private var displayName: String {
    let u = auth.user
    return u?.displayName ?? u?.email ?? "friend"
  }

  var body: some View {
    NavigationStack {
      ScrollView(showsIndicators: false) {
        VStack(spacing: 16) {

          // ---------- HEADER ----------
          VStack(spacing: 4) {
            Text("Welcome back, \(displayName) 👋")
              .font(.largeTitle).bold()
              .foregroundColor(Palette.textPrimary)
              .multilineTextAlignment(.center)

            Text("What should we work on today?")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding(.top, 4)
          .padding(.horizontal, 24)

          // ---------- TODAY CARD / STATE ----------
          ZStack {
            if vm.loading {
              LLMGeneratingView(
                title: "Generating your weekly plan…",
                subtitle: "This could take up to a minute."
              )
              .frame(maxWidth: .infinity, maxHeight: .infinity)
                

            } else if let day = vm.today, let plan = vm.plan {
              TodayCard(day: day, planName: plan.name)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if vm.error != nil {
              ErrorCard(text: vm.error ?? "Something went wrong")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
              EmptyCard()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
          }
          .frame(maxWidth: .infinity)
          .frame(minHeight: 270)
          .padding(.horizontal, 24)

          // ---------- INLINE PLAN CONTROLS (UNIFORM BUTTONS) ----------
          if let plan = vm.plan {
            HStack(spacing: 12) {

              // Switch plan – white pill, same height/typography
              if !vm.allPlans.isEmpty, let uid = auth.user?.uid {
                Menu {
                  ForEach(vm.allPlans) { p in
                    Button {
                      Task {
                        await vm.setActivePlan(p, uid: uid)
                      }
                    } label: {
                      HStack {
                        Text(p.name)
                        if p.id == vm.plan?.id {
                          Image(systemName: "checkmark")
                        }
                      }
                    }
                  }
                } label: {
                  PlanActionButton(
                    icon: "arrow.triangle.2.circlepath",
                    text: "Switch plan",
                    filled: false
                  )
                }
              }

              // View current plan – filled accent, same style
              NavigationLink {
                WeeklyPlanView(plan: plan)
              } label: {
                PlanActionButton(
                  icon: "calendar",
                  text: "View current plan",
                  filled: true
                )
              }
              .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
          }

          // ---------- GENERATE PLAN BUTTON (same component, full width) ----------
          if let uid = auth.user?.uid {
            Button {
              Task { await vm.generatePlan(uid: uid) }
            } label: {
              PlanActionButton(
                icon: "wand.and.stars",
                text: vm.loading ? "Generating plan..." : "Generate my weekly plan",
                filled: true
              )
            }
            .buttonStyle(.plain)
            .disabled(vm.loading)
            .padding(.horizontal, 24)
          }

          // ---------- STRENGTH RATING ----------
          StrengthRatingCard()
            .padding(.horizontal, 24)

          // (Sign out removed – moved to account page)
        }
        .padding(.bottom, 32)
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          NavigationLink {
            ProfileView(didFinishQuestionnaire: $didFinishQuestionnaire)
          } label: {
            Image(systemName: "person.crop.circle")
              .font(.system(size: 22, weight: .semibold))
              .foregroundColor(Palette.textPrimary)
          }
        }
      }
      .onAppear {
        if let uid = auth.user?.uid { vm.load(uid: uid) }
      }
    }
    .egymBackground()
  }
}

// MARK: - Shared button style for plan actions

private struct PlanActionButton: View {
  let icon: String
  let text: String
  let filled: Bool

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
      Text(text)
        .fontWeight(.semibold)
    }
    .font(.subheadline)  // <-- same text size for all three
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(
      filled ? Palette.accentPrimary : Color.white
    )
    .foregroundColor(filled ? .white : Palette.accentPrimary)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .shadow(
      color: filled
        ? Palette.accentPrimary.opacity(0.25)
        : Color.black.opacity(0.06),
      radius: 4, x: 0, y: 2
    )
  }
}

// MARK: - Supporting Cards for Home

private struct TodayCard: View {
  let day: DayPlan
  let planName: String

  // Show up to the first 3 exercises
  private var topExercises: [Exercise] {
    Array((day.exercises ?? []).prefix(3))
  }

  var body: some View {
    NavigationLink {
      SessionView(day: day, planName: planName)
    } label: {
      ZStack {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(
            LinearGradient(
              colors: [
                Palette.accentPrimary.opacity(0.22),
                Color.white.opacity(0.95),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
              .stroke(Color.white.opacity(0.7), lineWidth: 0.5)
          )
          .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)

        VStack(alignment: .leading, spacing: 10) {
          header
          Divider().opacity(0.25)
          content
          Spacer()
          footer
        }
        .padding(16)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .buttonStyle(.plain)
  }

  private var header: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Today • \(day.day)")
          .font(.subheadline.weight(.semibold))
          .foregroundColor(Palette.textPrimary)

        Text(day.target_focus ?? "Workout session")
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(1)
          .truncationMode(.tail)
      }

      Spacer(minLength: 8)

      Text("\(day.estimated_minutes ?? 30) min")
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.06))
        .clipShape(Capsule())
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var content: some View {
    if day.day_type == "rest" {
      VStack(alignment: .leading, spacing: 4) {
        Text("Rest day 😌")
          .font(.subheadline.weight(.semibold))
          .foregroundColor(Palette.textPrimary)
        Text(day.notes ?? "Take it easy today and recover.")
          .font(.caption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    } else {
      VStack(alignment: .leading, spacing: 6) {
        if !topExercises.isEmpty {
          Text("Today's session")
            .font(.caption.weight(.semibold))
            .foregroundColor(.secondary)

          ForEach(topExercises.indices, id: \.self) { idx in
            let ex = topExercises[idx]
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Circle()
                .frame(width: 6, height: 6)
                .foregroundColor(Palette.accentPrimary.opacity(0.8))

              VStack(alignment: .leading, spacing: 2) {
                Text(ex.name)
                  .font(.subheadline.weight(.semibold))
                  .foregroundColor(Palette.textPrimary)
                  .lineLimit(1)
                  .truncationMode(.tail)

                Text("\(ex.sets) × \(ex.reps_or_time)")
                  .font(.caption2)
                  .foregroundColor(.secondary)
              }

              Spacer()
            }
          }

          if let total = day.exercises?.count,
             total > topExercises.count {
            Text(
              "+ \(total - topExercises.count) more exercise\(total - topExercises.count == 1 ? "" : "s")"
            )
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.top, 2)
          }
        } else {
          Text("No exercises found for today.")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
  }

  private var footer: some View {
    HStack {
      Text(planName)
        .font(.caption2.weight(.semibold))
        .foregroundColor(.secondary)

      Spacer()

      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundColor(.secondary)
    }
    .padding(.top, 4)
  }
}

private struct ErrorCard: View {
  let text: String

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Color.red.opacity(0.10),
              Color.white.opacity(0.97)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.white.opacity(0.7), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

      VStack(alignment: .leading, spacing: 6) {
        Text("Something went wrong")
          .font(.subheadline.weight(.semibold))
          .foregroundColor(Palette.textPrimary)

        Text(text)
          .font(.caption)
          .foregroundColor(.red)
          .fixedSize(horizontal: false, vertical: true)

        Spacer()
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

private struct EmptyCard: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Color.white.opacity(0.96),
              Palette.accentPrimary.opacity(0.10),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.white.opacity(0.7), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)

      VStack(alignment: .leading, spacing: 6) {
        Text("No active plan")
          .font(.headline)
          .foregroundColor(Palette.textPrimary)

        Text("Create or activate a plan to get started.")
          .font(.subheadline)
          .foregroundColor(.secondary)

        Spacer()
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
#Preview {
  HomeView()
    .environmentObject(AuthViewModel())
}
