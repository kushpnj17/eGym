import SwiftUI
import FirebaseFirestore

// MARK: - Model

struct ExerciseInterest: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let systemImage: String
    var isSelected: Bool = false
}

// MARK: - View

struct ExerciseInterestsView: View {
    @EnvironmentObject var auth: AuthViewModel
    let onFinished: () -> Void
    init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    @State private var interests: [ExerciseInterest] = [
        .init(title: "Running",       systemImage: "figure.run"),
        .init(title: "Strength / Weights", systemImage: "dumbbell"),
        .init(title: "Cycling",       systemImage: "bicycle"),
        .init(title: "Yoga",          systemImage: "figure.cooldown"),
        .init(title: "Pilates",       systemImage: "figure.mind.and.body"),
        .init(title: "HIIT",          systemImage: "bolt.circle"),
        .init(title: "Swimming",      systemImage: "figure.pool.swim"),
        .init(title: "Rowing",        systemImage: "figure.rower"),
        .init(title: "Walking",       systemImage: "figure.walk"),
        .init(title: "Stretching",    systemImage: "figure.flexibility"),
        .init(title: "Crossfit",      systemImage: "flame"),
        .init(title: "Mindfulness",   systemImage: "brain.head.profile")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // Call this from the Next button
    private func onNextTapped(selected: [String]) {
        Task { await saveSelections(selected) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose your\nexercise interests")
                        .font(.system(size: 34, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)

                    Text("Select a few to help personalize your workout recommendations.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(interests.indices, id: \.self) { i in
                            InterestChip(
                                title: interests[i].title,
                                systemImage: interests[i].systemImage,
                                isSelected: interests[i].isSelected
                            ) {
                                interests[i].isSelected.toggle()
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            // Bottom bar (sticky)
            Divider()
            HStack(spacing: 12) {
                Button("Skip") {
                    Task { await saveSelections([]) }
                }
                .buttonStyle(OutlineBarButtonStyle())

                Button("Next") {
                    let selected = interests.filter { $0.isSelected }.map(\.title)
                    Task { await saveSelections(selected) }
                }
                .buttonStyle(FilledBarButtonStyle())
                .disabled(!interests.contains(where: { $0.isSelected }))
                .opacity(interests.contains(where: { $0.isSelected }) ? 1 : 0.6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Firestore write
    @MainActor
    private func saveSelections(_ selected: [String]) async {
        guard let uid = auth.user?.uid else {
            await MainActor.run { onFinished() }
            return
        }
        let db = Firestore.firestore()

        let payload: [String: Any] = [
            "interests": selected,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        do {
            try await db.collection("users").document(uid).setData(payload, merge: true)
        } catch {
            // You can surface this in UI later if you want
            print("Failed to save interests: \(error)")
        }

        await MainActor.run { onFinished() }
    }
}

// MARK: - Components

struct InterestChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.25) : Color(.systemGray6))
                        .frame(width: 26, height: 26)
                    Image(systemName: isSelected ? "checkmark" : systemImage)
                        .font(.system(size: isSelected ? 12 : 13, weight: .semibold))
                }
                
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? Color.pink : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Button Styles

struct FilledBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.pink))
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct OutlineBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pink, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12).fill(Color.clear)
                    )
            )
            .foregroundStyle(Color.pink)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct ExerciseInterestsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExerciseInterestsView()
                .environmentObject(AuthViewModel())
                .preferredColorScheme(.light)
            ExerciseInterestsView()
                .environmentObject(AuthViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
