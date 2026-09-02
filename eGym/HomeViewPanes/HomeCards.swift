//
//  HomeCards.swift
//  eGym
//
//  Created by Kush Patel on 12/5/25.
//

import SwiftUI

struct TodayCard: View {
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

// MARK: - Error Card

struct ErrorCard: View {
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

// MARK: - Empty Card

struct EmptyCard: View {
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
