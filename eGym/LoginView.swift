import SwiftUI
import AuthenticationServices

struct LoginView: View {
  @EnvironmentObject var auth: AuthViewModel
  @State private var showPwd = false

  // Explicit bindings so Swift never tries dynamicMember on EnvironmentObject
  private var emailBinding: Binding<String> {
    Binding(get: { auth.email }, set: { auth.email = $0 })
  }
  private var passwordBinding: Binding<String> {
    Binding(get: { auth.password }, set: { auth.password = $0 })
  }

  var body: some View {
    VStack(spacing: 18) {
      Text("Welcome to eGym").font(.title).bold()

      // Email
      TextField("Email", text: emailBinding)
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding().background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))

      // Password
      HStack {
        if showPwd {
          TextField("Password", text: passwordBinding)
        } else {
          SecureField("Password", text: passwordBinding)
        }
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
        auth.startSignInWithApple()   // NOTE: no "$auth" here
      } onCompletion: { _ in }
      .signInWithAppleButtonStyle(.black)
      .frame(height: 44)
      .clipShape(RoundedRectangle(cornerRadius: 10))

      // Google
      Button("Continue with Google") {
        auth.signInWithGoogle()       // NOTE: no "$auth" here
      }
      .buttonStyle(.bordered)

      // Status/debug
      Text(auth.status).font(.footnote).foregroundStyle(.secondary)
    }
    .padding()
  }
}
