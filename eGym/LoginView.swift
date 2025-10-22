//
//  LoginView.swift
//  eGym
//
//  Created by Kush Patel on 10/22/25.
//

import SwiftUI

private enum AuthMode: String, CaseIterable { case login = "Login", register = "Create Account" }
private enum Route: Hashable { case questionnaire, landing }

struct LoginView: View {
    @State private var mode: AuthMode = .login
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var fullName: String = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 16) {
                        modePicker

                        if mode == .register {
                            EGTextField("Full name", text: $fullName, systemImage: "person")
                        }

                        EGTextField("Email", text: $email, keyboard: .emailAddress, systemImage: "envelope")
                        EGSecureField("Password", text: $password, systemImage: "lock")

                        if mode == .register {
                            EGSecureField("Confirm password", text: $confirmPassword, systemImage: "lock.rotation")
                        }

                        if let error { EGErrorLabel(error) }

                        EGPrimaryButton(title: mode == .login ? "Login" : "Create account", isLoading: isLoading) {
                            submit()
                        }
                        .disabled(!formIsValid || isLoading)

                        Button(mode == .login ? "Need an account? Sign up" : "Already have an account? Log in") {
                            withAnimation(.spring) {
                                error = nil
                                mode = (mode == .login) ? .register : .login
                            }
                        }
                        .font(.footnote.weight(.semibold))
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .questionnaire:
                    ExerciseInterestsView() // QuestionnaireView
                        .navigationBarBackButtonHidden(true)
                case .landing:
                    // TODO: Replace with your real landing/home view
                    Text("Landing Page Placeholder")
                        .font(.title.bold())
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }

    // MARK: - Submit

    private func submit() {
        error = nil
        guard formIsValid else { return }

        isLoading = true

        // Simulate async auth call (replace with Firebase later).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false

            switch mode {
            case .register:
                // TODO: Hook up to Firebase Auth createUser(withEmail:password:)
                // On success, route to questionnaire
                path.append(Route.questionnaire)
            case .login:
                // TODO: Hook up to Firebase Auth signIn(withEmail:password:)
                // On success, route to landing (placeholder)
                path.append(Route.landing)
            }
        }
    }

    // MARK: - Validation

    private var formIsValid: Bool {
        switch mode {
        case .login:
            return email.isValidEmail && password.count >= 6
        case .register:
            guard email.isValidEmail,
                  password.count >= 6,
                  fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
            else { return false }
            return password == confirmPassword
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to eGym")
                .font(.system(size: 34, weight: .bold))
            Text(mode == .login
                 ? "Log in to continue your training."
                 : "Create an account to personalize your workouts.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(AuthMode.allCases, id: \.self) { m in
                Button {
                    withAnimation(.spring) {
                        mode = m
                        error = nil
                    }
                } label: {
                    Text(m == .login ? "Login" : "Register")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(m == mode ? Color.pink : Color(.systemGray6))
                        )
                        .foregroundStyle(m == mode ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Reusable Components

private struct EGTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var systemImage: String? = nil

    init(_ title: String, text: Binding<String>, keyboard: UIKeyboardType = .default, systemImage: String? = nil) {
        self.title = title
        self._text = text
        self.keyboard = keyboard
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage).imageScale(.medium)
                    .foregroundStyle(.secondary)
            }
            TextField(title, text: $text)
                .textInputAutocapitalization(.never)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
}

private struct EGSecureField: View {
    let title: String
    @Binding var text: String
    var systemImage: String? = nil
    @State private var show = false

    init(_ title: String, text: Binding<String>, systemImage: String? = nil) {
        self.title = title
        self._text = text
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage).imageScale(.medium)
                    .foregroundStyle(.secondary)
            }
            Group {
                if show {
                    TextField(title, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(title, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            Button(action: { show.toggle() }) {
                Image(systemName: show ? "eye.slash" : "eye")
                    .imageScale(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
}

private struct EGPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: isLoading ? {} : action) {
            HStack {
                if isLoading { ProgressView().progressViewStyle(.circular) }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.pink))
            .foregroundStyle(.white)
            .scaleEffect(isLoading ? 0.98 : 1)
        }
        .buttonStyle(.plain)
    }
}

private struct EGErrorLabel: View {
    let message: String
    init(_ message: String) { self.message = message }
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }
}

// MARK: - Helpers

private extension String {
    var isValidEmail: Bool {
        // Simple local check; replace with stricter one if needed
        let pattern = #"^\S+@\S+\.\S+$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Preview

#Preview {
    LoginView()
}
