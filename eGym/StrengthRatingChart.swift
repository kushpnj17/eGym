//
//  StrengthRatingChart.swift
//  eGym
//
//  Created by Aditya Patel on 11/5/25.
//

import SwiftUI
import Charts

struct StrengthPoint: Identifiable {
  let id = UUID()
  let date: Date
  let score: Int
}

struct StrengthRatingCard: View {
  // TODO: replace with real data later
  private let data: [StrengthPoint] = [
    (-13,62), (-12,61), (-11,63), (-10,64), (-9,63),
    (-8,65), (-7,66), (-6,64), (-5,67), (-4,68),
    (-3,69), (-2,70), (-1,71), (0,72)
  ].map { (offset, score) in
    StrengthPoint(date: Calendar.current.date(byAdding: .day, value: offset, to: Date())!, score: score)
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 14, style: .continuous)
      .fill(Color.white.opacity(0.92))
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
      )
      .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
      .frame(maxWidth: .infinity)
      .frame(height: 160)
      .overlay(
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Strength rating")
              .font(.headline)
              .foregroundColor(Palette.textPrimary)
            Spacer()
            let latest = data.last?.score ?? 0
            let prev   = data.dropLast().last?.score ?? latest
            let delta  = latest - prev
            Text("\(latest)")
              .font(.headline).foregroundColor(Palette.textPrimary)
            Text(delta >= 0 ? "▲ \(delta)" : "▼ \(-delta)")
              .font(.footnote.weight(.semibold))
              .foregroundColor(delta >= 0 ? .green : .red)
          }

          if #available(iOS 16.0, *) {
            Chart {
              ForEach(data) { pt in
                AreaMark(
                  x: .value("Date", pt.date),
                  y: .value("Score", pt.score)
                )
                .interpolationMethod(.catmullRom)
                .opacity(0.18)

                LineMark(
                  x: .value("Date", pt.date),
                  y: .value("Score", pt.score)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.0))
              }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 100)
          } else {
            // Fallback if Charts not available
            Text("Chart requires iOS 16+").font(.caption).foregroundColor(.secondary)
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
      )
  }
}
