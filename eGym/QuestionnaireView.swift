// QuestionnaireView.swift
import SwiftUI
import FirebaseFirestore

// MARK: - Main Container

struct QuestionnaireView: View {
    @EnvironmentObject var auth: AuthViewModel
    let onFinished: () -> Void
    init(onFinished: @escaping () -> Void = {}) { self.onFinished = onFinished }

    @State private var step: Step = .goal
    @State private var answers = Answers()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(step.title)
                        .font(.system(size: 34, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)

                    Text(step.subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)

                    stepView
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            Divider()

            HStack(spacing: 12) {
                // Back or Skip on first step
                if step == .goal {
                    Button("Skip") {
                        Task { await saveAndFinish() }
                    }
                    .buttonStyle(OutlineBarButtonStyle())
                } else {
                    Button("Back") { step = step.previous() }
                        .buttonStyle(OutlineBarButtonStyle())
                }

                Button(step.isLast ? "Finish" : "Next") {
                    if step.isLast {
                        Task { await saveAndFinish() }
                    } else {
                        step = step.next()
                    }
                }
                .buttonStyle(FilledBarButtonStyle())
                .disabled(!isStepComplete(step))
                .opacity(isStepComplete(step) ? 1 : 0.6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case .goal:
            GoalStepView(selection: $answers.goal)
        case .skill:
            SkillStepView(selection: $answers.skillLevel)
        case .injuries:
            InjuriesStepView(
                selections: $answers.injuries,
                otherText: $answers.injuryOther
            )
        case .mobility:
            MobilityStepView(selection: $answers.mobilityLevel)
        case .equipment:
            EquipmentStepView(
                selections: $answers.equipment,
                otherText: $answers.equipmentOther
            )
        case .time:
            TimeCommitmentStepView(minutes: $answers.timePerDayMinutes)
        }
    }

    // MARK: - Validation

    private func isStepComplete(_ step: Step) -> Bool {
        switch step {
        case .goal:      return answers.goal != nil
        case .skill:     return answers.skillLevel != nil
        case .injuries:
            // At least one option (including "None") OR custom text filled
            return !answers.injuries.isEmpty || !answers.injuryOther.trimmingCharacters(in: .whitespaces).isEmpty
        case .mobility:  return answers.mobilityLevel != nil
        case .equipment:
            return !answers.equipment.isEmpty || !answers.equipmentOther.trimmingCharacters(in: .whitespaces).isEmpty
        case .time:      return answers.timePerDayMinutes >= 5
        }
    }

    // MARK: - Firestore write (same auth pattern, just more fields)

    @MainActor
    private func saveAndFinish() async {
        guard let uid = auth.user?.uid else {
            await MainActor.run { onFinished() }
            return
        }

        // Normalize "other" entries into arrays if provided
        var injuries = Array(answers.injuries)
        if !answers.injuryOther.trimmingCharacters(in: .whitespaces).isEmpty {
            injuries.append(answers.injuryOther.trimmingCharacters(in: .whitespaces))
        }

        var equipment = Array(answers.equipment)
        if !answers.equipmentOther.trimmingCharacters(in: .whitespaces).isEmpty {
            equipment.append(answers.equipmentOther.trimmingCharacters(in: .whitespaces))
        }

        let payload: [String: Any] = [
            "goal": answers.goal ?? "",
            "skillLevel": answers.skillLevel ?? "",
            "injuries": injuries.map { $0 },
            "mobilityLevel": answers.mobilityLevel ?? "",
            "equipment": equipment.map { $0 },
            "timePerDayMinutes": answers.timePerDayMinutes,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        do {
            try await Firestore.firestore()
                .collection("users").document(uid)
                .setData(payload, merge: true)
        } catch {
            print("Failed to save questionnaire: \(error)")
        }

        await MainActor.run { onFinished() }
    }
}

// MARK: - Step Enum & Text

extension QuestionnaireView {
    enum Step: Int, CaseIterable {
        case goal, skill, injuries, mobility, equipment, time

        var isLast: Bool { self == .time }

        func next() -> Step { Step(rawValue: rawValue + 1) ?? self }
        func previous() -> Step { Step(rawValue: rawValue - 1) ?? self }

        var title: String {
            switch self {
            case .goal:      return "Fitness goal"
            case .skill:     return "Skill level"
            case .injuries:  return "Injuries or limitations"
            case .mobility:  return "Mobility / accessibility"
            case .equipment: return "Equipment availability"
            case .time:      return "Time commitment"
            }
        }

        var subtitle: String {
            switch self {
            case .goal:
                return "What is your primary fitness goal?"
            case .skill:
                return "How would you describe your current fitness experience?"
            case .injuries:
                return "Do you have any injuries or conditions we should account for?"
            case .mobility:
                return "Which best describes your current mobility?"
            case .equipment:
                return "What equipment do you have access to for workouts?"
            case .time:
                return "How much time can you dedicate each day?"
            }
        }
    }

    struct Answers {
        // 1) goal: single
        var goal: String? = nil            // "strength", "endurance", etc.
        // 2) skillLevel: single
        var skillLevel: String? = nil      // "beginner", "intermediate", "advanced"
        // 3) injuries: multi + other
        var injuries: Set<String> = []     // ["knee", "shoulder", ...] or ["none"]
        var injuryOther: String = ""
        // 4) mobilityLevel: single
        var mobilityLevel: String? = nil   // "seated-only", "low-impact", "full-mobility"
        // 5) equipment: multi + other
        var equipment: Set<String> = []    // ["chair", "dumbbells", ...] or ["none"]
        var equipmentOther: String = ""
        // 6) timePerDayMinutes: int
        var timePerDayMinutes: Int = 30
    }
}

// MARK: - Shared Chip

struct PillChip: View {
    let title: String
    let isSelected: Bool
    let leadingSystemImage: String?   // nil to hide, "checkmark" when selected or custom icon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let sys = leadingSystemImage {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.25) : Color(.systemGray6))
                            .frame(width: 26, height: 26)
                        Image(systemName: sys)
                            .font(.system(size: sys == "checkmark" ? 12 : 13, weight: .semibold))
                    }
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

// MARK: - Grid Helper

struct ChipGrid<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) { content }
    }
}

// MARK: - Step 1: Goal (single)

struct GoalStepView: View {
    @Binding var selection: String?

    private struct Option: Identifiable { let id = UUID(); let label: String; let key: String; let icon: String }
    private let options: [Option] = [
        .init(label: "🏋️ Build strength",               key: "strength",  icon: "dumbbell"),
        .init(label: "❤️ Improve endurance",             key: "endurance", icon: "heart"),
        .init(label: "🧘 Increase mobility/flexibility", key: "mobility",  icon: "figure.flexibility"),
        .init(label: "⚖️ Manage weight",                 key: "weight",    icon: "scalemass"),
        .init(label: "💪 Tone & general fitness",        key: "tone",      icon: "figure.strengthtraining.traditional")
    ]

    var body: some View {
        ChipGrid {
            ForEach(options) { opt in
                PillChip(
                    title: opt.label,
                    isSelected: selection == opt.key,
                    leadingSystemImage: selection == opt.key ? "checkmark" : opt.icon
                ) { selection = opt.key }
            }
        }
    }
}

// MARK: - Step 2: Skill (single)

struct SkillStepView: View {
    @Binding var selection: String?
    private struct Option: Identifiable { let id = UUID(); let label: String; let key: String; let icon: String }
    private let options: [Option] = [
        .init(label: "Beginner",     key: "beginner",     icon: "leaf"),
        .init(label: "Intermediate", key: "intermediate", icon: "circle.lefthalf.filled"),
        .init(label: "Advanced",     key: "advanced",     icon: "star.fill")
    ]

    var body: some View {
        ChipGrid {
            ForEach(options) { opt in
                PillChip(
                    title: opt.label,
                    isSelected: selection == opt.key,
                    leadingSystemImage: selection == opt.key ? "checkmark" : opt.icon
                ) { selection = opt.key }
            }
        }
    }
}

// MARK: - Step 3: Injuries (multi + other)

struct InjuriesStepView: View {
    @Binding var selections: Set<String>
    @Binding var otherText: String

    private struct Option: Identifiable { let id = UUID(); let label: String; let key: String; let icon: String }
    private let options: [Option] = [
        .init(label: "None",    key: "none",    icon: "nosign"),
        .init(label: "Knee",    key: "knee",    icon: "figure.run"),
        .init(label: "Shoulder",key: "shoulder",icon: "hand.raised"),
        .init(label: "Back",    key: "back",    icon: "rectangle.stack.person.crop"),
        .init(label: "Wrist",   key: "wrist",   icon: "hand.wave"),
        .init(label: "Hip",     key: "hip",     icon: "figure.walk")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ChipGrid {
                ForEach(options) { opt in
                    let selected = selections.contains(opt.key)
                    PillChip(
                        title: opt.label,
                        isSelected: selected,
                        leadingSystemImage: selected ? "checkmark" : opt.icon
                    ) {
                        toggle(opt.key)
                    }
                }
            }

            // Other text
            VStack(alignment: .leading, spacing: 6) {
                Text("Other (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Type any other limitations…", text: $otherText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.top, 4)
        }
    }

    private func toggle(_ key: String) {
        if key == "none" {
            // "None" is exclusive
            if selections.contains("none") {
                selections.remove("none")
            } else {
                selections = ["none"]
            }
        } else {
            selections.remove("none")
            if selections.contains(key) { selections.remove(key) }
            else { selections.insert(key) }
        }
    }
}

// MARK: - Step 4: Mobility (single)

struct MobilityStepView: View {
    @Binding var selection: String?
    private struct Option: Identifiable { let id = UUID(); let label: String; let key: String; let icon: String }
    private let options: [Option] = [
        .init(label: "Seated-only (low mobility)",              key: "seated-only", icon: "chair"),
        .init(label: "Low-impact (standing, light movement)",   key: "low-impact",  icon: "figure.stand"),
        .init(label: "Full mobility (able-bodied)",             key: "full-mobility", icon: "figure.walk")
    ]

    var body: some View {
        ChipGrid {
            ForEach(options) { opt in
                PillChip(
                    title: opt.label,
                    isSelected: selection == opt.key,
                    leadingSystemImage: selection == opt.key ? "checkmark" : opt.icon
                ) { selection = opt.key }
            }
        }
    }
}

// MARK: - Step 5: Equipment (multi + other)

struct EquipmentStepView: View {
    @Binding var selections: Set<String>
    @Binding var otherText: String

    private struct Option: Identifiable { let id = UUID(); let label: String; let key: String; let icon: String }
    private let options: [Option] = [
        .init(label: "Chair",            key: "chair",            icon: "chair"),
        .init(label: "Dumbbells",        key: "dumbbells",        icon: "dumbbell"),
        .init(label: "Resistance bands", key: "resistance-band",  icon: "bandage"),
        .init(label: "Yoga mat",         key: "yoga-mat",         icon: "rectangle.portrait"),
        .init(label: "None",             key: "none",             icon: "nosign")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ChipGrid {
                ForEach(options) { opt in
                    let selected = selections.contains(opt.key)
                    PillChip(
                        title: opt.label,
                        isSelected: selected,
                        leadingSystemImage: selected ? "checkmark" : opt.icon
                    ) {
                        toggle(opt.key)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Other equipment (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("E.g., kettlebell, barbell…", text: $otherText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.top, 4)
        }
    }

    private func toggle(_ key: String) {
        if key == "none" {
            if selections.contains("none") {
                selections.remove("none")
            } else {
                selections = ["none"]
            }
        } else {
            selections.remove("none")
            if selections.contains(key) { selections.remove(key) }
            else { selections.insert(key) }
        }
    }
}

// MARK: - Step 6: Time (slider)

struct TimeCommitmentStepView: View {
    @Binding var minutes: Int
    @State private var internalValue: Double = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily time: ")
                    .font(.headline)
                Text("\(minutes) min")
                    .font(.headline.weight(.semibold))
            }

            Slider(
                value: Binding<Double>(
                    get: { Double(minutes) },
                    set: { minutes = Int($0.rounded(.toNearestOrAwayFromZero)) }
                ),
                in: 5...180,
                step: 5
            )

            HStack {
                Text("5 min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("180 min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { internalValue = Double(minutes) }
    }
}

// MARK: - Button Styles (reuse from your file if already defined)

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

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QuestionnaireView()
                .environmentObject(AuthViewModel())
                .preferredColorScheme(.light)
            QuestionnaireView()
                .environmentObject(AuthViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
