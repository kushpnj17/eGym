import SwiftUI

struct LoginView: View {
  @EnvironmentObject var auth: AuthViewModel

  @State private var email = ""
  @State private var password = ""
  @State private var showPassword = false
  @FocusState private var focused: Field?

  enum Field { case email, password }

  var body: some View {
    VStack(spacing: 18) {
      Text("Welcome to eGym")
        .font(.title).bold()

      // Email
      TextField("Email", text: $email)
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .textContentType(.username)
        .submitLabel(.next)
        .focused($focused, equals: .email)
        .onSubmit { focused = .password }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

      // Password
      HStack {
        Group {
          if showPassword {
            TextField("Password", text: $password)
          } else {
            SecureField("Password", text: $password)
          }
        }
        .textContentType(.password)
        .submitLabel(.go)
        .focused($focused, equals: .password)
        .onSubmit { login() }

        Button {
          showPassword.toggle()
        } label: {
          Image(systemName: showPassword ? "eye.slash" : "eye")
        }
        .buttonStyle(.plain)
      }
      .padding(12)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

      // Log In button
      Button(action: login) {
        Text("Log In")
          .frame(maxWidth: .infinity, minHeight: 44)
      }
      .buttonStyle(.borderedProminent)
      .disabled(email.isEmpty || password.isEmpty)

      // Forgot password
      Button("Forgot password?") {
        auth.sendPasswordReset(to: email)
      }
      .disabled(email.isEmpty)
      .font(.footnote)

      Divider().padding(.vertical, 6)

      // GOOGLE login (kept from your file)
      Button {
        auth.signInWithGoogle()
      } label: {
        Label("Continue with Google", systemImage: "globe")
          .frame(maxWidth: .infinity, minHeight: 44)
      }
      .buttonStyle(.bordered)

      // Status/debug line
      Text(auth.status)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.top, 4)
    }
    .padding()
  }

  private func login() {
    auth.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password)
  }
}
