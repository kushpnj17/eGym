//
//  SpashView.swift
//  eGym
//
//  Created by Aditya Patel on 10/30/25.
//

import SwiftUI

struct EgymSpinnerRing: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var rotate = false

  var size: CGFloat = 48
  var line: CGFloat = 6

  var body: some View {
    ZStack {
      Circle()
        .stroke(Palette.bg.opacity(0.4), lineWidth: line)

      Circle()
        .trim(from: 0.15, to: 0.95)
        .stroke(
          AngularGradient(
            gradient: Gradient(colors: [
              Palette.accentPrimary,
              Palette.accentPrimary.opacity(0.7),
              Palette.accentRare.opacity(0.75),
              Palette.accentPrimary
            ]),
            center: .center
          ),
          style: StrokeStyle(lineWidth: line, lineCap: .round)
        )
        .rotationEffect(.degrees(rotate ? 360 : 0))
        .animation(reduceMotion ? nil :
          .linear(duration: 0.9).repeatForever(autoreverses: false),
          value: rotate
        )
    }
    .frame(width: size, height: size)
    .onAppear { rotate = true }
  }
}

// Simple splash you can customize
struct SplashView: View {
  var body: some View {
    ZStack {
      Color.clear.egymBackground()     // your subtle gradient, full screen

      VStack(spacing: 16) {
        Image("egymLogo")
          .resizable().scaledToFit()
          .frame(width: 140, height: 140)

        EgymSpinnerRing(size: 44, line: 6)
          .padding(.top, 4)

        // optional caption
        Text("Warming up…")
          .font(.footnote)
          .foregroundColor(Palette.textPrimary.opacity(0.6))
      }
      .padding(.horizontal, 24)
    }
  }
}

