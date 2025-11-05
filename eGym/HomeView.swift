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
  @StateObject private var vm = HomeVM()

  private var displayName: String {
    let u = auth.user
    return u?.displayName ?? u?.email ?? "friend"
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
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

        // Today card
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

        Spacer(minLength: 16)

        Button { auth.signOut() } label: {
          Text("Sign out").fontWeight(.semibold).frame(maxWidth: .infinity)
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

private struct TodayCard: View {
  let day: DayPlan
  let planName: String

  var body: some View {
    NavigationLink {
      SessionView(day: day, planName: planName)
    } label: {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(Color.white.opacity(0.92))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.6), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
        .frame(maxWidth: .infinity, minHeight: 140)
        .overlay(
          VStack(spacing: 8) {
            HStack {
              Text("Today’s Plan • \(day.day)")
                .font(.headline).foregroundColor(Palette.textPrimary)
              Spacer()
              Text("\(day.estimated_minutes) min")
                .font(.subheadline).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            Text(day.target_focus)
              .font(.subheadline)
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 16)

            if day.day_type == "rest" {
              Text(day.notes ?? "Rest day.")
                .font(.footnote).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            } else {
              // Peek at first 2 exercises
              if let ex = day.exercises {
                VStack(alignment: .leading, spacing: 6) {
                  ForEach(ex.prefix(2)) { e in
                    HStack {
                      Text(e.name).font(.subheadline).foregroundColor(Palette.textPrimary)
                      Spacer()
                      Text("\(e.sets) × \(e.reps_or_time)").font(.footnote).foregroundColor(.secondary)
                    }
                  }
                  if ex.count > 2 {
                    Text("…and \(ex.count - 2) more").font(.footnote).foregroundColor(.secondary)
                  }
                }
                .padding(.horizontal, 16)
              }
            }
          }
          .padding(.vertical, 14)
        )
    }
    .buttonStyle(.plain)
  }
}

private struct ErrorCard: View {
  let text: String
  var body: some View {
    RoundedRectangle(cornerRadius: 16).fill(Color.red.opacity(0.09))
      .overlay(Text(text).font(.subheadline).foregroundColor(.red).padding())
      .frame(maxWidth: .infinity, minHeight: 100)
  }
}

private struct EmptyCard: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.72))
      .overlay(
        VStack(spacing: 6) {
          Text("No active plan").font(.headline).foregroundColor(Palette.textPrimary)
          Text("Create or activate a plan to get started").font(.subheadline).foregroundColor(.secondary)
        }
      )
      .frame(maxWidth: .infinity, minHeight: 120)
  }
}
