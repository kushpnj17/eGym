//
//  EditProfileVM.swift
//  eGym
//
//  Created by Kush Patel on 12/5/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class EditProfileVM: ObservableObject {
  @Published var fullName: String = ""
  @Published var email: String = ""
  @Published var phone: String = ""

  @Published var age: String = ""

  // Metric fields (canonical for Firestore)
  @Published var heightCm: String = ""
  @Published var weightKg: String = ""

  // US fields (for UI when user prefers US)
  @Published var heightFeet: String = ""
  @Published var heightInches: String = ""
  @Published var weightLbs: String = ""

  // Units preference
  @Published var unitsSystem: String = "metric"   // "metric" or "us"

  @Published var preferredGym: String = "none"

  @Published var isLoading = false
  @Published var isSaving = false
  @Published var errorMessage: String?

  private let db = Firestore.firestore()
  private var uid: String?

  // MARK: - Configure

  func configure(with user: User) {
    uid = user.uid

    // Seed from Auth user so you see something even if Firestore doc doesn’t exist yet
    fullName = user.displayName ?? fullName
    email = user.email ?? email

    loadProfile()
    loadLatestWeightEntry()
  }

  // MARK: - Load profile

  private func loadProfile() {
    guard let uid = uid else { return }
    isLoading = true
    errorMessage = nil

    db.collection("users").document(uid).getDocument { [weak self] snap, error in
      guard let self = self else { return }
      self.isLoading = false

      if let error = error {
        self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
        return
      }

      guard let data = snap?.data() else { return }

      if let name = data["displayName"] as? String {
        self.fullName = name
      }
      if let email = data["email"] as? String {
        self.email = email
      }
      if let phone = data["phone"] as? String {
        self.phone = phone
      }
      if let age = data["age"] as? Int {
        self.age = String(age)
      }
      if let height = data["heightCm"] as? Double {
        self.heightCm = String(height)
      }
      if let latest = data["latestWeightKg"] as? Double {
        self.weightKg = String(latest)
      }
      if let gym = data["preferredGym"] as? String {
        self.preferredGym = gym
      }
      if let units = data["unitsSystem"] as? String {
        self.unitsSystem = units
      }

      // Derive US units from metric, if available
      self.updateDerivedFromMetric()
    }
  }

  // MARK: - Load latest weight entry (time series)

  private func loadLatestWeightEntry() {
    guard let uid = uid else { return }

    db.collection("users")
      .document(uid)
      .collection("weightEntries")
      .order(by: "createdAt", descending: true)
      .limit(to: 1)
      .getDocuments { [weak self] snapshot, error in
        guard let self = self else { return }

        if let error = error {
          print("Failed to load latest weight entry: \(error.localizedDescription)")
          return
        }

        guard let doc = snapshot?.documents.first,
              let value = doc.data()["valueKg"] as? Double else {
          return
        }

        self.weightKg = String(value)
        self.updateDerivedFromMetric()
      }
  }

  // MARK: - Save profile

  func saveProfile() {
    guard let uid = uid else { return }
    isSaving = true
    errorMessage = nil

    // Canonical values to save
    var heightCmValue: Double?
    var weightKgValue: Double?

    // Convert from whichever system the user is using
    if unitsSystem == "metric" {
      if let h = Double(heightCm) {
        heightCmValue = h
      }
      if let k = Double(weightKg) {
        weightKgValue = k
      }
    } else { // "us"
      if let ft = Double(heightFeet),
         let inch = Double(heightInches) {
        let totalInches = ft * 12.0 + inch
        heightCmValue = totalInches * 2.54
      }
      if let lbs = Double(weightLbs) {
        weightKgValue = lbs * 0.45359237
      }
    }

    // Build data payload for Firestore
    var data: [String: Any] = [
      "displayName": fullName,
      "email": email,
      "phone": phone,
      "preferredGym": preferredGym,
      "unitsSystem": unitsSystem
    ]

    if let ageInt = Int(age) {
      data["age"] = ageInt
    }
    if let hCm = heightCmValue {
      data["heightCm"] = hCm
      // Keep metric text in sync for future sessions
      heightCm = String(hCm)
    }
    var weightValueToLog: Double? = nil
    if let wKg = weightKgValue {
      data["latestWeightKg"] = wKg
      weightValueToLog = wKg
      weightKg = String(wKg)
    }

    let userRef = db.collection("users").document(uid)

    userRef.setData(data, merge: true) { [weak self] error in
      guard let self = self else { return }

      if let error = error {
        self.isSaving = false
        self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
        return
      }

      // If we have a weight, append a time-series entry
      if let wKg = weightValueToLog {
        let entryData: [String: Any] = [
          "valueKg": wKg,
          "createdAt": Timestamp(date: Date()),
          "source": "manual"
        ]

        userRef.collection("weightEntries")
          .addDocument(data: entryData) { [weak self] err in
            guard let self = self else { return }
            self.isSaving = false

            if let err = err {
              self.errorMessage =
                "Profile saved, but failed to log weight entry: \(err.localizedDescription)"
            }
          }
      } else {
        self.isSaving = false
      }
    }
  }

  // MARK: - Derived unit helpers

  private func updateDerivedFromMetric() {
    // Height -> ft + in
    if let hCm = Double(heightCm), hCm > 0 {
      let totalInches = hCm / 2.54
      let feet = Int(totalInches / 12.0)
      let inches = totalInches - Double(feet) * 12.0
      heightFeet = String(feet)
      heightInches = String(Int(round(inches)))
    }

    // Weight -> lbs
    if let kg = Double(weightKg), kg > 0 {
      let lbs = kg * 2.20462
      weightLbs = String(Int(round(lbs)))
    }
  }
}
