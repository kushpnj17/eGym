import SwiftUI
import SwiftfulLoadingIndicators

struct LLMGeneratingView: View {
  var title: String = "Generating…"
  var subtitle: String = "This could take up to a minute."

  var body: some View {
    ZStack {
      // Same card style as TodayCard
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Palette.accentPrimary.opacity(0.18),
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
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)

      // Centered stack with extra space above
      VStack(spacing: 20) {
        Spacer(minLength: 12)   // more top space before spinner

        LoadingIndicator(
          animation: .threeBallsTriangle,
          color: Palette.accentPrimary,
          size: .medium,
          speed: .normal
        )

        VStack(spacing: 6) {
          Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(Palette.textPrimary)

          Text(subtitle)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }

        Spacer(minLength: 24)   // a bit more space below text
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    // Fill the slot from HomeView
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
