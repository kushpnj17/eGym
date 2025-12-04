//
//  WorkoutPlanModels.swift
//  eGym
//
//  Created by Aditya Patel on 11/5/25.
//

import FirebaseFirestore

struct WorkoutPlan: Codable, Identifiable {
  @DocumentID var id: String?
  var name: String
  var version: Int
  var status: String
  var profile: Profile
  var week: [DayPlan]  // single-doc layout
  @ServerTimestamp var createdAt: Timestamp?
  @ServerTimestamp var updatedAt: Timestamp?
}

struct Profile: Codable {
  var goal: String
  var skillLevel: String
  var injuries: [String]
  var mobilityLevel: String
  var equipment: [String]
  var timePerDayMinutes: Int
}

struct DayPlan: Codable, Identifiable {
  var id: String { day }
  var day: String  // "Mon"..."Sun"
  var day_type: String  // "workout" | "rest"
  var target_focus: String?
  var estimated_minutes: Int?
  var warmup: Block?
  var exercises: [Exercise]?
  var cooldown: Block?
  var notes: String?
}

struct Block: Codable {
  var minutes: Int
  var drills: [Drill]
}
struct Drill: Codable {
  var name: String
  var details: String
}

struct Exercise: Codable, Identifiable {
  var id: String { name }
  var name: String
  var modality: String
  var equipment: [String]
  var muscle_groups: [String]
  var sets: Int
  var reps_or_time: String
  var intensity: String
  var tempo: String
  var rest_seconds: Int?
  var substitutions: [String]?
  var form_tips: [String]
}

struct LLMWeeklyPlan: Codable {
  let caution: String
  let profile: Profile
  let week: [DayPlan]
}

extension WorkoutPlan {
  /// Convenience init to build a Firestore WorkoutPlan from the LLM JSON (Don't have to change WorkoutPlan struct this way).
  init(from llm: LLMWeeklyPlan, name: String, version: Int = 1, status: String = "active") {
    self.id = nil
    self.name = name
    self.version = version
    self.status = status
    self.profile = llm.profile
    self.week = llm.week
    self.createdAt = nil
    self.updatedAt = nil
  }
}
