//
//  Backgrounds.swift
//  eGym
//
//  Created by Aditya Patel on 10/30/25.
//

import SwiftUI

// MARK: - Option A: Soft radial washes (recommended)
struct BackgroundGradient: View {
    var body: some View {
        ZStack {
            // Neutral base
            Palette.bg
                .ignoresSafeArea()

            // Warm focus from top-right (primary orange)
            RadialGradient(
                colors: [
                    Palette.accentPrimary.opacity(0.18),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 500
            )
            .blur(radius: 60)
            .ignoresSafeArea()

            // Cool counterbalance from bottom-left (rare teal) — very subtle
            RadialGradient(
                colors: [
                    Palette.accentRare.opacity(0.10),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 420
            )
            .blur(radius: 80)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Option B: Ultra-minimal linear tint
struct SubtleLinearBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Palette.bg,
                Palette.accentPrimary.opacity(0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Convenience modifier
extension View {
    /// Apply eGym’s brand background (Option A). Swap to SubtleLinearBackground() if you prefer Option B.
    func egymBackground() -> some View {
        background(BackgroundGradient())
    }
}
