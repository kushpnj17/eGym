import SwiftUI

struct LoginView: View {
  // 👉 Use ObservedObject, not EnvironmentObject
  @ObservedObject var auth: AuthViewModel

  @State private var email: String = ""
  @State private var password: String = ""
  @State private var showPwd = false

  var body: some View {
    VStack(spacing: 18) {
      Text("Welcome to eGym").font(.title).bold()

      // Email
      TextField("Email", text: $email)
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding().background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))

      // Password
      HStack {
        if showPwd {
          TextField("Password", text: $password)
        } else {
          SecureField("Password", text: $password)
        }
        Button(showPwd ? "Hide" : "Show") { showPwd.toggle() }
      }
      .textContentType(.password)
      .padding().background(.thinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 12))

      // Email/Password actions
      HStack {
        Button("Sign In") {
          Task {
            auth.email = email
            auth.password = password
            await auth.signInWithEmail()
          }
        }
        .buttonStyle(.borderedProminent)

        Button("Sign Up") {
          Task {
            auth.email = email
            auth.password = password
            await auth.signUpWithEmail()
          }
        }
        .buttonStyle(.bordered)
      }

      // Apple
      Button {
        auth.startSignInWithApple()
      } label: {
        Label("Continue with Apple", systemImage: "apple.logo")
          .frame(maxWidth: .infinity, minHeight: 44)
      }
      .buttonStyle(.bordered)

      // Google
      Button {
        auth.signInWithGoogle()
      } label: {
        Label("Continue with Google", systemImage: "globe")
          .frame(maxWidth: .infinity, minHeight: 44)
      }
      .buttonStyle(.bordered)

      // Status/debug
      Text(auth.status).font(.footnote).foregroundStyle(.secondary)
    }
    .padding()
  }
}
