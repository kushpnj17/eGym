import SwiftUI
import AuthenticationServices   // for the Apple button

struct LoginView: View {
  @EnvironmentObject var auth: AuthViewModel
  @State private var showPwd = false

  var body: some View {
    VStack(spacing: 18) {
      Text("Welcome to eGym").font(.title).bold()

      // Email
      TextField("Email", text: $auth.email)
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding().background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))

      // Password
      HStack {
        if showPwd { TextField("Password", text: $auth.password) }
        else { SecureField("Password", text: $auth.password) }
        Button(showPwd ? "Hide" : "Show") { showPwd.toggle() }
      }
      .padding().background(.thinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 12))

      // Email/Password actions
      HStack {
        Button("Sign In") { Task { await auth.signInWithEmail() } }
          .buttonStyle(.borderedProminent)

        Button("Sign Up") { Task { await auth.signUpWithEmail() } }
          .buttonStyle(.bordered)
      }

      // Apple
      SignInWithAppleButton(.signIn) { _ in
        auth.startSignInWithApple()
      } onCompletion: { _ in }
      .signInWithAppleButtonStyle(.black)
      .frame(height: 44)
      .clipShape(RoundedRectangle(cornerRadius: 10))

      // Google
      Button("Continue with Google") {
        auth.signInWithGoogle()
      }
      .buttonStyle(.bordered)

      // Status/debug
      Text(auth.status).font(.footnote).foregroundStyle(.secondary)
    }
    .padding()
  }
}
