//
//  HomeVM.swift
//  eGym
//
//  Created by Aditya Patel on 11/5/25.
//

import FirebaseFirestore
import FirebaseFunctions
import Foundation

private let dayOrder: [String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
private func ordered(_ days: [DayPlan]) -> [DayPlan] {
  days.sorted { (a, b) in
    (dayOrder.firstIndex(of: a.day) ?? 0) < (dayOrder.firstIndex(of: b.day) ?? 0)
  }
}

final class HomeVM: ObservableObject {
  @Published var plan: WorkoutPlan?
  @Published var today: DayPlan?
  @Published var loading = false
  @Published var error: String?

  // all workout plans for this user (for dropdown)
  @Published var allPlans: [WorkoutPlan] = []

  // Track which user this VM is currently loaded for
  @Published private(set) var loadedUid: String?

  // MARK: - Auth / user change handling

  @MainActor
  func reset() {
    plan = nil
    today = nil
    allPlans = []
    error = nil
    loading = false
    loadedUid = nil
  }

  /// Central entry point to react to auth user changes.
  /// - If uid == nil → signed out → clear all state.
  /// - If uid == same as loadedUid → no-op.
  /// - If uid changes → reset and load for new user.
  @MainActor
  func handleAuthChange(_ uid: String?) {
    guard let uid = uid else {
      reset()
      return
    }

    if loadedUid == uid {
      return
    }

    reset()
    loadedUid = uid
    load(uid: uid)
  }

  // MARK: - Load current active plan (and all plans)

  func load(uid: String) {
    // 🔐 Don't stomp an in-flight generatePlan
    if loading {
      return
    }

    // When we start a fresh load, clear old UI so we don't show another user's data
    loading = true
    error = nil
    plan = nil
    today = nil
    allPlans = []

    let db = Firestore.firestore()
    let userRef = db.collection("users").document(uid)

    userRef.getDocument { snap, err in
      if let err = err {
        DispatchQueue.main.async {
          self.error = err.localizedDescription
          self.loading = false
        }
        return
      }
      guard let data = snap?.data(),
            let activeId = data["activePlanId"] as? String, !activeId.isEmpty
      else {
        DispatchQueue.main.async {
          self.loading = false
        }
        return
      }

      db.collection("users").document(uid)
        .collection("workoutPlans").document(activeId)
        .getDocument(as: WorkoutPlan.self) { result in
          DispatchQueue.main.async {
            switch result {
            case .failure(let e):
              self.error = e.localizedDescription
            case .success(let plan):
              self.plan = plan
              self.today = self.pickToday(from: plan, userData: data)
              // also load all plans for this user
              self.loadAllPlans(uid: uid)
            }
            self.loading = false
          }
        }
    }
  }

  // load every plan in users/{uid}/workoutPlans
  private func loadAllPlans(uid: String) {
    let db = Firestore.firestore()
    db.collection("users")
      .document(uid)
      .collection("workoutPlans")
      .getDocuments { snapshot, error in
        if let error = error {
          print("❌ Failed to load all plans:", error)
          return
        }
        guard let docs = snapshot?.documents else {
          print("⚠️ No workoutPlans docs found")
          return
        }

        do {
          let decoded = try docs.map { doc in
            try doc.data(as: WorkoutPlan.self)
          }

          // 🔤 sort by base name, then numeric suffix (no suffix = 1)
          let sorted = decoded.sorted { a, b in
            let pa = self.parsedName(a.name)
            let pb = self.parsedName(b.name)

            let baseCompare = pa.base.localizedCaseInsensitiveCompare(pb.base)
            if baseCompare == .orderedSame {
              if pa.index != pb.index {
                return pa.index < pb.index
              } else {
                // fallback to full name for stability
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
              }
            } else {
              return baseCompare == .orderedAscending
            }
          }

          DispatchQueue.main.async {
            self.allPlans = sorted
            print("✅ Loaded \(self.allPlans.count) plans for dropdown")
            self.allPlans.forEach { p in
              print("   • plan id=\(p.id ?? "<no id>"), name=\(p.name)")
            }
          }
        } catch {
          print("❌ Decoding all plans failed:", error)
        }
      }
  }

  // MARK: - Generate a plan on demand (called from HomeView button)

  @MainActor
  func generatePlan(uid: String) async {
    loadedUid = uid
    loading = true
    error = nil

    let functions = Functions.functions()
    let db = Firestore.firestore()
    let userRef = db.collection("users").document(uid)

    do {
      // 1) Call the Cloud Function: generateWorkoutPlan
      let callable = functions.httpsCallable("generateWorkoutPlan")
      callable.timeoutInterval = 90    // timeout overridden to 90 seconds
      let result = try await callable.call([:])

      // 2) Extract workoutPlanId from the response
      guard let dict = result.data as? [String: Any],
            let planId = dict["workoutPlanId"] as? String
      else {
        throw NSError(
          domain: "HomeVM",
          code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Invalid response from generateWorkoutPlan."]
        )
      }

      // 3) Set this plan as active on the user doc
      try await userRef.setData(
        [
          "activePlanId": planId,
          "planStartWeekday": "Mon",
          "updatedAt": FieldValue.serverTimestamp(),
        ],
        merge: true
      )

      // 4) Fetch the plan document we just created
      let planSnap =
        try await userRef
          .collection("workoutPlans")
          .document(planId)
          .getDocument()

      guard planSnap.exists else {
        throw NSError(
          domain: "HomeVM",
          code: 2,
          userInfo: [NSLocalizedDescriptionKey: "Workout plan document not found."]
        )
      }

      let plan = try planSnap.data(as: WorkoutPlan.self)

      // 5) Compute "today"
      self.plan = plan
      self.today = self.pickToday(
        from: plan,
        userData: ["planStartWeekday": "Mon"]
      )

      // refresh full list including this new plan
      self.loadAllPlans(uid: uid)

      self.loading = false
    } catch {
      if let err = error as NSError?,
         err.domain == FunctionsErrorDomain,
         FunctionsErrorCode(rawValue: err.code) == .deadlineExceeded
      {
        // Cloud Function took too long, but it may still have created a plan.
        print("Deadline exceeded – trying to reload any active plan from Firestore.")

        // keep loading while we recover
        self.error = nil

        // try to pull whatever is now active on the user doc
        self.load(uid: uid)
        return
      }

      // For real errors, surface them in the UI
      if let err = error as NSError? {
        print("Functions error:", err.domain, err.code, err.userInfo)
      } else {
        print("Functions error (non-NS):", error)
      }

      self.error = error.localizedDescription
      self.loading = false
    }
  }

  // allow switching which plan is active from the dropdown
  @MainActor
  func setActivePlan(_ plan: WorkoutPlan, uid: String) async {
    guard let planId = plan.id else { return }

    let db = Firestore.firestore()
    let userRef = db.collection("users").document(uid)

    do {
      try await userRef.setData(
        [
          "activePlanId": planId,
          "planStartWeekday": "Mon",
          "updatedAt": FieldValue.serverTimestamp(),
        ],
        merge: true
      )

      self.plan = plan
      self.today = self.pickToday(
        from: plan,
        userData: ["planStartWeekday": "Mon"]
      )
    } catch {
      print("Failed to set active plan:", error)
      self.error = error.localizedDescription
    }
  }

  // MARK: - Helper

  // Parse names like "Weekly Mobility Plan 3" into ("Weekly Mobility Plan", 3).
  // If there is no trailing number, we treat it as 1.
  private func parsedName(_ name: String) -> (base: String, index: Int) {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

    // Walk backwards to grab trailing digits
    var digits = ""
    for char in trimmed.reversed() {
      if char.isNumber {
        digits.insert(char, at: digits.startIndex)
      } else if char == " " && digits.isEmpty {
        // still skipping whitespace before digits
        continue
      } else {
        break
      }
    }

    if let num = Int(digits), !digits.isEmpty {
      // Base is the string without the space + digits at the end
      let endIndex = trimmed.index(trimmed.endIndex, offsetBy: -(digits.count))
      let base = trimmed[..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
      return (String(base), num)
    } else {
      // No trailing number -> treat as 1
      return (trimmed, 1)
    }
  }

  private func pickToday(from plan: WorkoutPlan, userData: [String: Any]) -> DayPlan? {
    let calendar = Calendar.current
    let dowSymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let todaySymbol = dowSymbols[calendar.component(.weekday, from: Date()) - 1]
    let start = (userData["planStartWeekday"] as? String) ?? "Mon"
    let order: [String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let offset = (order.firstIndex(of: todaySymbol) ?? 0) - (order.firstIndex(of: start) ?? 0)
    let idx = (offset % 7 + 7) % 7
    let todayKey = order[idx]
    return plan.week.first { $0.day == todayKey } ?? plan.week.first
  }
}
