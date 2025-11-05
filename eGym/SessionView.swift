//
//  SessionView.swift
//  eGym
//
//  Created by Aditya Patel on 11/5/25.
//

import SwiftUI

struct SessionView: View {
  let day: DayPlan
  let planName: String

  var body: some View {
    List {
      Section(header: Text(planName)) {
        HStack {
          Text("\(day.day) • \(day.target_focus)")
          Spacer()
          Text("\(day.estimated_minutes) min").foregroundColor(.secondary)
        }
      }

      if day.day_type == "rest" {
        Section { Text(day.notes ?? "Rest day.") }
      } else {
        if let w = day.warmup {
          Section(header: Text("Warm-up • \(w.minutes) min")) {
            ForEach(w.drills.indices, id: \.self) { i in
              let d = w.drills[i]
              VStack(alignment: .leading) {
                Text(d.name).font(.subheadline).bold()
                Text(d.details).font(.footnote).foregroundColor(.secondary)
              }
            }
          }
        }
        if let ex = day.exercises {
          Section(header: Text("Exercises")) {
            ForEach(ex) { e in
              VStack(alignment: .leading, spacing: 4) {
                Text(e.name).font(.subheadline).bold()
                Text("\(e.sets) × \(e.reps_or_time) • \(e.modality.capitalized)")
                  .font(.footnote).foregroundColor(.secondary)
                Text("Intensity: \(e.intensity) • Tempo: \(e.tempo)")
                  .font(.footnote).foregroundColor(.secondary)
                if !e.form_tips.isEmpty {
                  Text("Tips: " + e.form_tips.prefix(2).joined(separator: " • "))
                    .font(.footnote).foregroundColor(.secondary)
                }
              }.padding(.vertical, 4)
            }
          }
        }
        if let c = day.cooldown {
          Section(header: Text("Cooldown • \(c.minutes) min")) {
            ForEach(c.drills.indices, id: \.self) { i in
              let d = c.drills[i]
              VStack(alignment: .leading) {
                Text(d.name).font(.subheadline).bold()
                Text(d.details).font(.footnote).foregroundColor(.secondary)
              }
            }
          }
        }
        if let notes = day.notes, !notes.isEmpty {
          Section(header: Text("Notes")) { Text(notes) }
        }
      }
    }
    .navigationTitle("Today")
  }
}
