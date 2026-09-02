//
//  HomePlanButtons.swift
//  eGym
//
//  Created by Kush Patel on 12/5/25.
//

import SwiftUI

struct PlanActionButton: View {
  let icon: String
  let text: String
  let filled: Bool

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
      Text(text)
        .fontWeight(.semibold)
    }
    .font(.subheadline)  // same text size
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

// MARK: - Shake Effect + Shakable Button

struct ShakeEffect: GeometryEffect {
  var shakes: CGFloat = 0
  var amplitude: CGFloat = 8

  var animatableData: CGFloat {
    get { shakes }
    set { shakes = newValue }
  }

  func effectValue(size: CGSize) -> ProjectionTransform {
    let translation = amplitude * sin(shakes * .pi * 2)
    return ProjectionTransform(
      CGAffineTransform(translationX: translation, y: 0)
    )
  }
}

/// Wrapper that shakes when tapped while `disabled == true`.
struct ShakablePlanButton<Label: View>: View {
  let disabled: Bool
  let action: () -> Void
  let label: () -> Label

  @State private var attempts: Int = 0

  var body: some View {
    Button {
      if disabled {
        withAnimation(.easeInOut(duration: 0.25)) {
          attempts += 1
        }
      } else {
        action()
      }
    } label: {
      label()
        .opacity(disabled ? 0.4 : 1.0)
        .modifier(ShakeEffect(shakes: CGFloat(attempts)))
    }
    .buttonStyle(.plain)
  }
}
