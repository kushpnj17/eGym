import SwiftUI

struct LoginView: View {
  @EnvironmentObject var auth: AuthViewModel   // fine to keep as EnvironmentObject now
  var body: some View {
    VStack(spacing: 18) {
      Text("Welcome to eGym").font(.title).bold()

      // GOOGLE ONLY
      Button {
        auth.signInWithGoogle()
      } label: {
        Label("Continue with Google", systemImage: "globe")
          .frame(maxWidth: .infinity, minHeight: 44)
      }
      .buttonStyle(.borderedProminent)

      Text(auth.status).font(.footnote).foregroundStyle(.secondary)
    }
    .padding()
  }
}
