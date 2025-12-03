import FirebaseFirestore
// QuestionnaireView.swift
import SwiftUI

// MARK: - Color Helpers & Palette

extension Color {
  init(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)

    let r = Double((rgb >> 16) & 0xFF) / 255.0
    let g = Double((rgb >> 8) & 0xFF) / 255.0
    let b = Double(rgb & 0xFF) / 255.0
    self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
  }
}

enum Palette {
  static let bg = Color(hex: "#F0F0F0")
  static let accentPrimary = Color(hex: "#FE691E")
  static let textPrimary = Color(hex: "#434040")
  static let accentRare = Color(hex: "#077997")  // use sparingly
  static let chipBase = Color.white
  static let chipStroke = Color.black.opacity(0.08)
}

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
        GeometryReader { geo in
          // Centered column that is 90% of the screen width.
          VStack(alignment: .leading, spacing: 12) {
            Text(step.title)
              .font(.system(size: 34, weight: .bold))
              .foregroundStyle(Palette.textPrimary)
              .fixedSize(horizontal: false, vertical: true)
              .padding(.top, 8)

            Text(step.subtitle)
              .font(.callout)
              .foregroundStyle(Palette.textPrimary.opacity(0.7))
              .padding(.bottom, 8)

            stepView
              .padding(.top, 4)
          }
          .frame(width: geo.size.width * 0.9)  // << constrained column
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.bottom, 24)
        }
        .frame(minHeight: 0)  // let scroll view size naturally
      }

      Divider()

      HStack(spacing: 12) {
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
      .background(Palette.bg)  // flat footer to match theme
    }
    .background(Palette.bg)
    .tint(Palette.accentPrimary)
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
    case .goal: return answers.goal != nil
    case .skill: return answers.skillLevel != nil
    case .injuries:
      return !answers.injuries.isEmpty
        || !answers.injuryOther.trimmingCharacters(in: .whitespaces).isEmpty
    case .mobility: return answers.mobilityLevel != nil
    case .equipment:
      return !answers.equipment.isEmpty
        || !answers.equipmentOther.trimmingCharacters(in: .whitespaces).isEmpty
    case .time: return answers.timePerDayMinutes >= 5
    }
  }

  // MARK: - Firestore write (same auth pattern, just more fields)

  @MainActor
  private func saveAndFinish() async {
    guard let uid = auth.user?.uid else {
      await MainActor.run { onFinished() }
      return
    }

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
      "updatedAt": FieldValue.serverTimestamp(),
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
      case .goal: return "Fitness goal"
      case .skill: return "Skill level"
      case .injuries: return "Injuries or limitations"
      case .mobility: return "Mobility / accessibility"
      case .equipment: return "Equipment availability"
      case .time: return "Time commitment"
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
    var goal: String? = nil
    var skillLevel: String? = nil
    var injuries: Set<String> = []
    var injuryOther: String = ""
    var mobilityLevel: String? = nil
    var equipment: Set<String> = []
    var equipmentOther: String = ""
    var timePerDayMinutes: Int = 30
  }
}

// MARK: - Shared Chip (themed)

struct PillChip: View {
  let title: String
  let isSelected: Bool
  let leadingSystemImage: String?
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        if let sys = leadingSystemImage {
          ZStack {
            Circle()
              .fill(isSelected ? Color.white.opacity(0.25) : Palette.bg)
              .frame(width: 26, height: 26)
            Image(systemName: sys)
              .font(.system(size: sys == "checkmark" ? 12 : 13, weight: .semibold))
              .foregroundStyle(isSelected ? .white : Palette.textPrimary)
          }
        }
        Text(title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
          .multilineTextAlignment(.leading)
          .foregroundStyle(isSelected ? .white : Palette.textPrimary)

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
          .fill(isSelected ? Palette.accentPrimary : Palette.chipBase)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
          .stroke(isSelected ? Color.clear : Palette.chipStroke, lineWidth: 1)
      )
      .shadow(
        color: isSelected ? Palette.accentPrimary.opacity(0.15) : Color.black.opacity(0.04),
        radius: isSelected ? 8 : 6, x: 0, y: isSelected ? 4 : 3)
    }
    .buttonStyle(.plain)
    .contentShape(Rectangle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

// MARK: - Step 1: Goal (single) — 90% width column via parent

struct GoalStepView: View {
  @Binding var selection: String?

  private struct Option: Identifiable {
    let id = UUID()
    let label: String
    let key: String
    let icon: String
  }
  private let options: [Option] = [
    .init(label: "🏋️ Build strength", key: "strength", icon: "dumbbell"),
    .init(label: "❤️ Improve endurance", key: "endurance", icon: "heart"),
    .init(label: "🧘 Increase mobility/flexibility", key: "mobility", icon: "figure.flexibility"),
    .init(label: "⚖️ Manage weight", key: "weight", icon: "scalemass"),
    .init(
      label: "💪 Tone & general fitness", key: "tone", icon: "figure.strengthtraining.traditional"),
  ]

  var body: some View {
    VStack(spacing: 12) {
      ForEach(options) { opt in
        PillChip(
          title: opt.label,
          isSelected: selection == opt.key,
          leadingSystemImage: selection == opt.key ? "checkmark" : opt.icon
        ) { selection = opt.key }
        .frame(maxWidth: .infinity)  // fills the 90% parent column
      }
    }
  }
}

// MARK: - Step 2: Skill (single)

struct SkillStepView: View {
  @Binding var selection: String?
  private struct Option: Identifiable {
    let id = UUID()
    let label: String
    let key: String
    let icon: String
  }
  private let options: [Option] = [
    .init(label: "Beginner", key: "beginner", icon: "leaf"),
    .init(label: "Intermediate", key: "intermediate", icon: "circle.lefthalf.filled"),
    .init(label: "Advanced", key: "advanced", icon: "star.fill"),
  ]

  var body: some View {
    VStack(spacing: 12) {
      ForEach(options) { opt in
        PillChip(
          title: opt.label,
          isSelected: selection == opt.key,
          leadingSystemImage: selection == opt.key ? "checkmark" : opt.icon
        ) { selection = opt.key }
        .frame(maxWidth: .infinity)
      }
    }
  }
}

// MARK: - Step 3: Injuries (multi + other)

struct InjuriesStepView: View {
  @Binding var selections: Set<String>
  @Binding var otherText: String

  private struct Option: Identifiable {
    let id = UUID()
    let label: String
    let key: String
    let icon: String
  }
  private let options: [Option] = [
    .init(label: "None", key: "none", icon: "nosign"),
    .init(label: "Knee", key: "knee", icon: "figure.run"),
    .init(label: "Shoulder", key: "shoulder", icon: "hand.raised"),
    .init(label: "Back", key: "back", icon: "rectangle.stack.person.crop"),
    .init(label: "Wrist", key: "wrist", icon: "hand.wave"),
    .init(label: "Hip", key: "hip", icon: "figure.walk"),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(options) { opt in
        let selected = selections.contains(opt.key)
        PillChip(
          title: opt.label,
          isSelected: selected,
          leadingSystemImage: selected ? "checkmark" : opt.icon
        ) { toggle(opt.key) }
        .frame(maxWidth: .infinity)
      }

      VStack(alignment: .leading, spacing: 6) {
        Text("Other (optional)")
          .font(.caption)
          .foregroundStyle(Palette.textPrimary.opacity(0.7))
        TextField("Type any other limitations…", text: $otherText)
          .textFieldStyle(.roundedBorder)
      }
      .padding(.top, 4)
    }
  }

  private func toggle(_ key: String) {
    if key == "none" {
      if selections.contains("none") { selections.remove("none") } else { selections = ["none"] }
    } else {
      selections.remove("none")
      if selections.contains(key) { selections.remove(key) } else { selections.insert(key) }
    }
  }
}

// MARK: - Step 4: Mobility (single)

struct MobilityStepView: View {
  @Binding var selection: String?
  private struct Option: Identifiable {
    let id = UUID()
    let label: String
    let key: String
    let icon: String
  }
  private let options: [Option] = [
    .init(label: "Seated-only (low mobility)", key: "seated-only", icon: "chair"),
    .init(label: "Low-impact (standing, light movement)", key: "low-impact", icon: "figure.stand"),
    .init(label: "Full mobility (able-bodied)", key: "full-mobility", icon: "figure.walk"),
  ]

  var body: some View {
    VStack(spacing: 12) {
      ForEach(options) { opt in
        PillChip(
          title: opt.label,
          isSelected: selection == opt.key,
          leadingSystemImage: selection == opt.key ? "checkmark" : opt.icon
        ) { selection = opt.key }
        .frame(maxWidth: .infinity)
      }
    }
  }
}

// MARK: - Step 5: Equipment (multi + other)

struct EquipmentStepView: View {
  @Binding var selections: Set<String>
  @Binding var otherText: String

  private struct Option: Identifiable {
    let id = UUID()
    let label: String
    let key: String
    let icon: String
  }
  private let options: [Option] = [
    .init(label: "Chair", key: "chair", icon: "chair"),
    .init(label: "Dumbbells", key: "dumbbells", icon: "dumbbell"),
    .init(label: "Weight Rack", key: "weight-rack", icon: "chair"),
    .init(label: "Resistance bands", key: "resistance-band", icon: "bandage"),
    .init(label: "Yoga mat", key: "yoga-mat", icon: "rectangle.portrait"),
    .init(label: "None", key: "none", icon: "nosign"),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(options) { opt in
        let selected = selections.contains(opt.key)
        PillChip(
          title: opt.label,
          isSelected: selected,
          leadingSystemImage: selected ? "checkmark" : opt.icon
        ) { toggle(opt.key) }
        .frame(maxWidth: .infinity)
      }

      VStack(alignment: .leading, spacing: 6) {
        Text("Other equipment (optional)")
          .font(.caption)
          .foregroundStyle(Palette.textPrimary.opacity(0.7))
        TextField("E.g., kettlebell, barbell…", text: $otherText)
          .textFieldStyle(.roundedBorder)
      }
      .padding(.top, 4)
    }
  }

  private func toggle(_ key: String) {
    if key == "none" {
      if selections.contains("none") { selections.remove("none") } else { selections = ["none"] }
    } else {
      selections.remove("none")
      if selections.contains(key) { selections.remove(key) } else { selections.insert(key) }
    }
  }
}

// MARK: - Step 6: Time (slider) — themed

struct TimeCommitmentStepView: View {
  @Binding var minutes: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Daily time: ").font(.headline).foregroundStyle(Palette.textPrimary)
        Text("\(minutes) min").font(.headline.weight(.semibold)).foregroundStyle(
          Palette.textPrimary)
      }

      Slider(
        value: Binding<Double>(
          get: { Double(minutes) },
          set: { minutes = Int($0.rounded(.toNearestOrAwayFromZero)) }
        ),
        in: 5...180,
        step: 10
      )
      .tint(Palette.accentPrimary)

      HStack {
        Text("10 min").font(.caption).foregroundStyle(Palette.textPrimary.opacity(0.7))
        Spacer()
        Text("180 min").font(.caption).foregroundStyle(Palette.textPrimary.opacity(0.7))
      }
    }
  }
}

// MARK: - Button Styles (themed)

struct FilledBarButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background(
        RoundedRectangle(cornerRadius: 12).fill(Palette.accentPrimary)
      )
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .shadow(color: Palette.accentPrimary.opacity(0.18), radius: 10, x: 0, y: 6)
      .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
  }
}

struct OutlineBarButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(Palette.textPrimary)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Palette.textPrimary.opacity(0.6), lineWidth: 1.5)
          .background(RoundedRectangle(cornerRadius: 12).fill(.white))
      )
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
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
