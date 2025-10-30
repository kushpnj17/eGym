import SwiftUI

struct LaunchAuthView: View {
  @EnvironmentObject var auth: AuthViewModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  // Row constants
  private let rowHeight: CGFloat = 52
  private let corner: CGFloat = 12
  private let iconBox: CGFloat = 24
  private let gSize: CGFloat = 22
  private let appleSize: CGFloat = 18
  private let phoneSize: CGFloat = 18
  private let labelFont = Font.system(size: 17, weight: .semibold)

  // Intro state
  @State private var showButtons = false
  @State private var buttonsOffset: CGFloat = 32   // start slightly below

  var body: some View {
    ZStack {
      // Always-on gradient background
      Color.clear.egymBackground()   // <- keeps gradient full-screen, no transitions

      VStack(spacing: 28) {
        Spacer(minLength: 12)

        // Logo (fixed size, no scaling)
        VStack(spacing: 10) {
          Image("egymLogo")
            .resizable().scaledToFit()
            .frame(width: 180, height: 180)     // same size before/after
          Text("Train smarter. Move stronger.")
            .font(.subheadline)
            .foregroundColor(Palette.textPrimary.opacity(0.7))
            .opacity(showButtons ? 1 : 0)       // fade in with buttons
            .animation(.easeOut(duration: 0.25), value: showButtons)
        }

        // Providers (slide up from under the logo)
        VStack(spacing: 14) {
          // GOOGLE
          Button { auth.signInWithGoogle() } label: {
            HStack(spacing: 12) {
              ZStack {
                Image("googleG")
                  .renderingMode(.original)
                  .resizable()
                  .interpolation(.high)
                  .antialiased(true)
                  .scaledToFit()
                  .frame(width: gSize, height: gSize)
              }
              .frame(width: iconBox, height: iconBox)

              Text("Continue with Google")
                .font(labelFont)

              Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .foregroundColor(.black)
            .overlay(RoundedRectangle(cornerRadius: corner)
              .stroke(Color(red:0.85, green:0.86, blue:0.88), lineWidth: 1)) // #DADCE0
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
          }
          .buttonStyle(.plain)

          // APPLE (placeholder)
          Button { } label: {
            HStack(spacing: 12) {
              ZStack {
                Image(systemName: "applelogo")
                  .font(.system(size: appleSize, weight: .regular))
              }
              .frame(width: iconBox, height: iconBox)

              Text("Continue with Apple")
                .font(labelFont)

              Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
          }
          .disabled(true).opacity(0.75)

          // PHONE (placeholder)
          Button { } label: {
            HStack(spacing: 12) {
              ZStack {
                Image(systemName: "phone.fill")
                  .font(.system(size: phoneSize, weight: .semibold))
              }
              .frame(width: iconBox, height: iconBox)

              Text("Continue with Phone")
                .font(labelFont)

              Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity)
            .background(Palette.accentPrimary)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
          }
          .disabled(true).opacity(0.75)
        }
        .padding(.horizontal, 24)
        .opacity(showButtons ? 1 : 0)
        .offset(y: buttonsOffset)               // slide from below
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: showButtons)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: buttonsOffset)

        Text("By continuing you agree to eGym’s Terms & Privacy.")
          .font(.caption2)
          .multilineTextAlignment(.center)
          .foregroundColor(Palette.textPrimary.opacity(0.5))
          .padding(.horizontal, 32)
          .opacity(showButtons ? 1 : 0)
          .animation(.easeOut(duration: 0.25), value: showButtons)

        Spacer()

        Text(auth.status).font(.footnote).foregroundStyle(.secondary)
          .opacity(showButtons ? 1 : 0)
          .animation(.easeOut(duration: 0.25), value: showButtons)
      }
      .padding(.vertical, 16)
      .navigationBarHidden(true)
    }
    .onAppear(perform: runIntro)
  }

  // MARK: - Intro
  private func runIntro() {
    if reduceMotion {
      showButtons = true
      buttonsOffset = 0
      return
    }
    // 1 second: logo only
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      showButtons = true
      buttonsOffset = 0
    }
  }
}
