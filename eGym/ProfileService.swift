//
//  ProfileService.swift
//  eGym
//
//  Created by Aditya Patel on 10/30/25.
//

import FirebaseFirestore

final class ProfileService {
  private let db = Firestore.firestore()
  private func doc(_ uid: String) -> DocumentReference { db.collection("users").document(uid) }

  /// Returns existing profile or creates a minimal one.
  func getOrCreate(uid: String) async throws -> UserProfile {
    let ref = doc(uid)
    if let snap = try? await ref.getDocument(),
       let existing = try? snap.data(as: UserProfile.self) {
      return existing
    }
    // Create minimal doc
    try await ref.setData([
      "onboardingCompleted": false,
      "createdAt": FieldValue.serverTimestamp()
    ], merge: false)
    return UserProfile(onboardingCompleted: false, createdAt: nil)
  }

  /// Marks onboarding completed (idempotent).
  func setOnboardingCompleted(uid: String, _ value: Bool) async throws {
    try await doc(uid).setData([
      "onboardingCompleted": value
    ], merge: true)
  }
}
